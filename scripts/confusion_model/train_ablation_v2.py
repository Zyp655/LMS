import os, json, copy, time, random
import numpy as np
import pandas as pd
from pathlib import Path
from collections import Counter

import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, Dataset, WeightedRandomSampler
from torchvision import transforms, models
from PIL import Image

from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score, roc_curve
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns

FRAMES_DIR = Path(__file__).parent / 'frames_v2'
V3_MODELS_DIR = Path(__file__).parent / 'output_v3' / 'models'
OUTPUT_DIR = Path(__file__).parent / 'output_ablation_v2'
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

IMG_SIZE = 224
BATCH_SIZE = 16
SEQ_LEN = 5
SEED = 42

PHASE1_EPOCHS = 15
PHASE2_EPOCHS = 30
PHASE3_EPOCHS = 20

torch.manual_seed(SEED)
np.random.seed(SEED)
random.seed(SEED)

device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
print(f'Device: {device}')
if torch.cuda.is_available():
    print(f'GPU: {torch.cuda.get_device_name(0)}')
    torch.backends.cudnn.benchmark = True


class ClipDataset(Dataset):
    def __init__(self, csv_path, split, transform=None, seq_len=SEQ_LEN):
        df = pd.read_csv(csv_path)
        df = df[df['frame_path'].str.contains(
            f'/{split}/' if '/' in df['frame_path'].iloc[0] else f'\\\\{split}\\\\', regex=True)]
        self.transform = transform
        self.seq_len = seq_len
        self.clips = []
        for clip_id, group in df.groupby('clip_id'):
            group = group.sort_values('frame_path')
            frames = group['frame_path'].tolist()
            label = int(group['is_confused'].iloc[0])
            aux = [
                float(group['boredom'].iloc[0]) / 3.0,
                float(group['engagement'].iloc[0]) / 3.0,
                float(group['frustration'].iloc[0]) / 3.0,
            ]
            aux.append(aux[0] / (aux[1] + 0.01))
            aux.append(aux[0] + aux[2])
            self.clips.append({'frames': frames, 'label': label, 'aux': aux, 'clip_id': clip_id})

    def __len__(self):
        return len(self.clips)

    def __getitem__(self, idx):
        clip = self.clips[idx]
        frames = clip['frames']
        if len(frames) >= self.seq_len:
            indices = np.linspace(0, len(frames) - 1, self.seq_len, dtype=int)
            frames = [frames[i] for i in indices]
        else:
            while len(frames) < self.seq_len:
                frames.append(frames[-1])
        imgs = []
        for fp in frames:
            try:
                img = Image.open(fp).convert('RGB')
            except:
                img = Image.new('RGB', (IMG_SIZE, IMG_SIZE))
            if self.transform:
                img = self.transform(img)
            imgs.append(img)
        return torch.stack(imgs), torch.tensor(clip['aux'], dtype=torch.float32), torch.tensor(clip['label'], dtype=torch.float32)


class SEBlock(nn.Module):
    def __init__(self, channels, reduction=16):
        super().__init__()
        self.fc = nn.Sequential(
            nn.Linear(channels, channels // reduction), nn.SiLU(),
            nn.Linear(channels // reduction, channels), nn.Sigmoid())

    def forward(self, x):
        return x * self.fc(x)


class TemporalConfusionModel(nn.Module):
    def __init__(self, num_aux=5, hidden_size=256, use_se=True, use_lstm=True, use_attn=True, use_aux=True):
        super().__init__()
        self.use_se = use_se
        self.use_lstm = use_lstm
        self.use_attn = use_attn
        self.use_aux = use_aux
        base = models.efficientnet_v2_s(weights=models.EfficientNet_V2_S_Weights.IMAGENET1K_V1)
        self.backbone = nn.Sequential(*list(base.children())[:-1])
        self.feat_dim = 1280
        if self.use_se:
            self.se = SEBlock(self.feat_dim)
        if self.use_lstm:
            self.lstm = nn.LSTM(self.feat_dim, hidden_size, num_layers=2,
                                batch_first=True, bidirectional=True, dropout=0.3)
            rnn_out_dim = hidden_size * 2
        else:
            rnn_out_dim = self.feat_dim
        if self.use_lstm and self.use_attn:
            self.attn = nn.Sequential(nn.Linear(rnn_out_dim, 1), nn.Softmax(dim=1))
        fusion_dim = rnn_out_dim + (num_aux if self.use_aux else 0)
        self.head = nn.Sequential(
            nn.LayerNorm(fusion_dim), nn.Dropout(0.4),
            nn.Linear(fusion_dim, 256), nn.SiLU(), nn.BatchNorm1d(256), nn.Dropout(0.3),
            nn.Linear(256, 128), nn.SiLU(), nn.Dropout(0.2),
            nn.Linear(128, 1))

    def freeze_backbone(self):
        for p in self.backbone.parameters():
            p.requires_grad = False

    def unfreeze_backbone(self, last_n=150):
        params = list(self.backbone.parameters())
        for p in params:
            p.requires_grad = False
        for p in params[-last_n:]:
            p.requires_grad = True

    def unfreeze_all(self):
        for p in self.backbone.parameters():
            p.requires_grad = True

    def forward(self, seq, aux):
        B, T, C, H, W = seq.shape
        x = self.backbone(seq.view(B * T, C, H, W)).flatten(1)
        if self.use_se:
            x = self.se(x)
        x = x.view(B, T, self.feat_dim)
        if self.use_lstm:
            lstm_out, _ = self.lstm(x)
            if self.use_attn:
                context = (self.attn(lstm_out) * lstm_out).sum(dim=1)
            else:
                context = lstm_out.mean(dim=1)
        else:
            context = x.mean(dim=1)
        if self.use_aux:
            context = torch.cat([context, aux], dim=1)
        return self.head(context).squeeze(1)


class FocalLoss(nn.Module):
    def __init__(self, alpha=0.6, gamma=2.0, smoothing=0.05):
        super().__init__()
        self.alpha, self.gamma, self.smoothing = alpha, gamma, smoothing

    def forward(self, inputs, targets):
        targets = targets * (1 - self.smoothing) + 0.5 * self.smoothing
        bce = nn.functional.binary_cross_entropy_with_logits(inputs, targets, reduction='none')
        pt = torch.exp(-bce)
        alpha_t = self.alpha * targets + (1 - self.alpha) * (1 - targets)
        return (alpha_t * (1 - pt) ** self.gamma * bce).mean()


class EMA:
    def __init__(self, model, decay=0.999):
        self.decay = decay
        self.shadow = {k: v.clone().detach() for k, v in model.state_dict().items()}

    def update(self, model):
        for k, v in model.state_dict().items():
            self.shadow[k] = self.decay * self.shadow[k] + (1 - self.decay) * v

    def apply(self, model):
        model.load_state_dict(self.shadow)


def get_transforms():
    train_tf = transforms.Compose([
        transforms.Resize((IMG_SIZE + 20, IMG_SIZE + 20)),
        transforms.RandomCrop(IMG_SIZE),
        transforms.RandomHorizontalFlip(),
        transforms.RandomRotation(15),
        transforms.ColorJitter(brightness=0.3, contrast=0.3, saturation=0.2, hue=0.05),
        transforms.RandomPerspective(distortion_scale=0.2, p=0.3),
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225]),
        transforms.RandomErasing(p=0.2),
    ])
    val_tf = transforms.Compose([
        transforms.Resize((IMG_SIZE, IMG_SIZE)),
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225]),
    ])
    return train_tf, val_tf


@torch.no_grad()
def evaluate(model, loader):
    model.eval()
    all_probs, all_labels = [], []
    for seq, aux, labels in loader:
        seq, aux = seq.to(device), aux.to(device)
        with torch.amp.autocast('cuda'):
            out = model(seq, aux)
        all_probs.extend(torch.sigmoid(out).cpu().numpy())
        all_labels.extend(labels.numpy())
    probs, yt = np.array(all_probs), np.array(all_labels)
    acc = float(np.mean(yt == (probs > 0.5).astype(int)))
    try:
        auc = roc_auc_score(yt, probs)
    except:
        auc = 0
    return acc, auc, probs, yt


def find_optimal_threshold(probs, labels):
    best_t, best_f1 = 0.5, 0
    for t in np.arange(0.3, 0.9, 0.01):
        preds = (probs > t).astype(int)
        tp = ((preds == 1) & (labels == 1)).sum()
        fp = ((preds == 1) & (labels == 0)).sum()
        fn = ((preds == 0) & (labels == 1)).sum()
        prec = tp / (tp + fp + 1e-8)
        rec = tp / (tp + fn + 1e-8)
        f1 = 2 * prec * rec / (prec + rec + 1e-8)
        if f1 > best_f1:
            best_f1, best_t = f1, t
    return best_t, best_f1


def train_variant(name, config, train_loader, val_loader, test_loader, pretrained_path=None):
    print(f"\n{'='*60}")
    print(f"  VARIANT: {name}")
    print(f"  Config: {config}")
    if pretrained_path:
        print(f"  Baseline: {pretrained_path}")
    print(f"{'='*60}")

    model = TemporalConfusionModel(**config).to(device)

    if pretrained_path and Path(pretrained_path).exists():
        state = torch.load(pretrained_path, weights_only=True, map_location=device)
        compatible = {}
        model_state = model.state_dict()
        for k, v in state.items():
            if k in model_state and model_state[k].shape == v.shape:
                compatible[k] = v
        model_state.update(compatible)
        model.load_state_dict(model_state)
        loaded_pct = len(compatible) / len(model_state) * 100
        print(f"  Loaded {len(compatible)}/{len(model_state)} params ({loaded_pct:.0f}%)")

    criterion = FocalLoss()
    scaler = torch.amp.GradScaler('cuda')
    ema = EMA(model, decay=0.999)
    best_auc = 0
    best_state = None

    # Phase 1
    model.freeze_backbone()
    print(f"  [Phase 1] Head + LSTM ({PHASE1_EPOCHS} epochs)")
    opt = optim.AdamW(filter(lambda p: p.requires_grad, model.parameters()), lr=1e-3, weight_decay=1e-3)
    sched = optim.lr_scheduler.OneCycleLR(opt, max_lr=1e-3, epochs=PHASE1_EPOCHS, steps_per_epoch=len(train_loader))
    for epoch in range(PHASE1_EPOCHS):
        model.train()
        total_loss, total_n = 0, 0
        for seq, aux, labels in train_loader:
            seq, aux, labels = seq.to(device), aux.to(device), labels.to(device)
            opt.zero_grad(set_to_none=True)
            with torch.amp.autocast('cuda'):
                loss = criterion(model(seq, aux), labels)
            scaler.scale(loss).backward()
            scaler.unscale_(opt)
            torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
            scaler.step(opt)
            scaler.update()
            sched.step()
            ema.update(model)
            total_loss += loss.item() * seq.size(0)
            total_n += seq.size(0)
        ema_backup = copy.deepcopy(model.state_dict())
        ema.apply(model)
        _, val_auc, _, _ = evaluate(model, val_loader)
        model.load_state_dict(ema_backup)
        if val_auc > best_auc:
            best_auc = val_auc
            best_state = copy.deepcopy(model.state_dict())
        print(f"    Epoch {epoch+1:2d}/{PHASE1_EPOCHS} | Loss: {total_loss/total_n:.4f} | Val AUC: {val_auc:.4f}")

    # Phase 2
    model.unfreeze_backbone(last_n=150)
    print(f"  [Phase 2] Unfreeze backbone ({PHASE2_EPOCHS} epochs)")
    opt = optim.AdamW(filter(lambda p: p.requires_grad, model.parameters()), lr=2e-5, weight_decay=1e-3)
    sched = optim.lr_scheduler.CosineAnnealingWarmRestarts(opt, T_0=10, T_mult=2, eta_min=1e-7)
    ema = EMA(model, decay=0.9995)
    patience, patience_limit = 0, 12
    for epoch in range(PHASE2_EPOCHS):
        model.train()
        total_loss, total_n = 0, 0
        for seq, aux, labels in train_loader:
            seq, aux, labels = seq.to(device), aux.to(device), labels.to(device)
            opt.zero_grad(set_to_none=True)
            with torch.amp.autocast('cuda'):
                loss = criterion(model(seq, aux), labels)
            scaler.scale(loss).backward()
            scaler.unscale_(opt)
            torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
            scaler.step(opt)
            scaler.update()
            ema.update(model)
            total_loss += loss.item() * seq.size(0)
            total_n += seq.size(0)
        sched.step()
        ema_backup = copy.deepcopy(model.state_dict())
        ema.apply(model)
        _, val_auc, _, _ = evaluate(model, val_loader)
        model.load_state_dict(ema_backup)
        print(f"    Epoch {epoch+1:2d}/{PHASE2_EPOCHS} | Loss: {total_loss/total_n:.4f} | Val AUC: {val_auc:.4f}")
        if val_auc > best_auc:
            best_auc = val_auc
            best_state = copy.deepcopy(model.state_dict())
            patience = 0
        else:
            patience += 1
            if patience >= patience_limit:
                print(f"    Early stopping at epoch {epoch+1}")
                break

    # Phase 3
    model.unfreeze_all()
    if best_state:
        model.load_state_dict(best_state)
    print(f"  [Phase 3] Full unfreeze ({PHASE3_EPOCHS} epochs)")
    opt = optim.AdamW(model.parameters(), lr=5e-6, weight_decay=1e-3)
    sched = optim.lr_scheduler.CosineAnnealingLR(opt, T_max=PHASE3_EPOCHS, eta_min=1e-8)
    ema = EMA(model, decay=0.9998)
    patience = 0
    for epoch in range(PHASE3_EPOCHS):
        model.train()
        total_loss, total_n = 0, 0
        for seq, aux, labels in train_loader:
            seq, aux, labels = seq.to(device), aux.to(device), labels.to(device)
            opt.zero_grad(set_to_none=True)
            with torch.amp.autocast('cuda'):
                loss = criterion(model(seq, aux), labels)
            scaler.scale(loss).backward()
            scaler.unscale_(opt)
            torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
            scaler.step(opt)
            scaler.update()
            ema.update(model)
            total_loss += loss.item() * seq.size(0)
            total_n += seq.size(0)
        sched.step()
        ema_backup = copy.deepcopy(model.state_dict())
        ema.apply(model)
        _, val_auc, _, _ = evaluate(model, val_loader)
        model.load_state_dict(ema_backup)
        print(f"    Epoch {epoch+1:2d}/{PHASE3_EPOCHS} | Loss: {total_loss/total_n:.4f} | Val AUC: {val_auc:.4f}")
        if val_auc > best_auc:
            best_auc = val_auc
            best_state = copy.deepcopy(model.state_dict())
            patience = 0
        else:
            patience += 1
            if patience >= 10:
                print(f"    Early stopping at epoch {epoch+1}")
                break

    if best_state:
        model.load_state_dict(best_state)
    ema.apply(model)

    acc, auc, probs, yt = evaluate(model, test_loader)
    opt_t, opt_f1 = find_optimal_threshold(probs, yt)
    opt_acc = float(np.mean(yt == (probs > opt_t).astype(int)))

    print(f"\n  >> [{name}] Test Acc(0.5): {acc:.4f} | AUC: {auc:.4f}")
    print(f"  >> [{name}] Optimal t={opt_t:.2f} | Acc: {opt_acc:.4f} | F1: {opt_f1:.4f}")

    return {
        'Variant': name,
        'Acc_default': round(acc, 4),
        'AUC': round(auc, 4),
        'Optimal_Threshold': round(opt_t, 2),
        'Acc_optimal': round(opt_acc, 4),
        'F1_optimal': round(opt_f1, 4),
        'probs': probs,
        'labels': yt,
    }


def variant_cache_path(name):
    safe = name.replace(' ', '_').replace('(', '').replace(')', '')
    return OUTPUT_DIR / f'result_{safe}.json'


def save_variant_result(r):
    data = {k: v for k, v in r.items() if k not in ('probs', 'labels')}
    data['probs'] = r['probs'].tolist()
    data['labels'] = r['labels'].tolist()
    with open(variant_cache_path(r['Variant']), 'w') as f:
        json.dump(data, f, indent=2)


def load_variant_result(name):
    p = variant_cache_path(name)
    if not p.exists():
        return None
    with open(p) as f:
        data = json.load(f)
    data['probs'] = np.array(data['probs'])
    data['labels'] = np.array(data['labels'])
    return data


def generate_charts(results):
    df = pd.DataFrame([{k: v for k, v in r.items() if k not in ('probs', 'labels')} for r in results])
    df.to_csv(OUTPUT_DIR / 'ablation_results_v2.csv', index=False)
    print("\n" + df.to_string(index=False))

    fig, axes = plt.subplots(1, 3, figsize=(20, 6))
    colors = ['#2ecc71', '#e74c3c', '#3498db', '#f39c12', '#9b59b6']
    names = df['Variant'].tolist()

    bars = axes[0].bar(names, df['AUC'], color=colors[:len(names)], edgecolor='white', linewidth=1.5)
    axes[0].set_title('AUC Score by Variant', fontsize=13, fontweight='bold')
    axes[0].set_ylabel('AUC')
    y_min = max(0, df['AUC'].min() - 0.05)
    axes[0].set_ylim(y_min, df['AUC'].max() + 0.05)
    for bar, val in zip(bars, df['AUC']):
        axes[0].text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.005,
                     f'{val:.4f}', ha='center', fontweight='bold', fontsize=10)
    axes[0].tick_params(axis='x', rotation=20)

    bars2 = axes[1].bar(names, df['Acc_optimal'], color=colors[:len(names)], edgecolor='white', linewidth=1.5)
    axes[1].set_title('Accuracy (Optimal Threshold)', fontsize=13, fontweight='bold')
    axes[1].set_ylabel('Accuracy')
    y_min2 = max(0, df['Acc_optimal'].min() - 0.05)
    axes[1].set_ylim(y_min2, df['Acc_optimal'].max() + 0.05)
    for bar, val in zip(bars2, df['Acc_optimal']):
        axes[1].text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.005,
                     f'{val:.4f}', ha='center', fontweight='bold', fontsize=10)
    axes[1].tick_params(axis='x', rotation=20)

    bars3 = axes[2].bar(names, df['F1_optimal'], color=colors[:len(names)], edgecolor='white', linewidth=1.5)
    axes[2].set_title('F1 Score (Optimal Threshold)', fontsize=13, fontweight='bold')
    axes[2].set_ylabel('F1')
    y_min3 = max(0, df['F1_optimal'].min() - 0.05)
    axes[2].set_ylim(y_min3, df['F1_optimal'].max() + 0.05)
    for bar, val in zip(bars3, df['F1_optimal']):
        axes[2].text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.005,
                     f'{val:.4f}', ha='center', fontweight='bold', fontsize=10)
    axes[2].tick_params(axis='x', rotation=20)

    plt.suptitle('Ablation Study - Confusion Detection on DAiSEE', fontsize=15, fontweight='bold', y=1.02)
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / 'ablation_comparison_v2.png', dpi=200, bbox_inches='tight')
    plt.close()

    fig2, ax2 = plt.subplots(figsize=(8, 7))
    for i, r in enumerate(results):
        fpr, tpr, _ = roc_curve(r['labels'], r['probs'])
        ax2.plot(fpr, tpr, color=colors[i], lw=2, label=f"{r['Variant']} (AUC={r['AUC']:.4f})")
    ax2.plot([0, 1], [0, 1], 'k--', alpha=0.4)
    ax2.set_xlabel('False Positive Rate', fontsize=12)
    ax2.set_ylabel('True Positive Rate', fontsize=12)
    ax2.set_title('ROC Curves - Ablation Study', fontsize=14, fontweight='bold')
    ax2.legend(loc='lower right', fontsize=10)
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / 'ablation_roc_v2.png', dpi=200, bbox_inches='tight')
    plt.close()


def main():
    csv_path = FRAMES_DIR / 'frame_labels.csv'
    if not csv_path.exists():
        print(f'ERROR: {csv_path} not found.')
        return

    train_tf, val_tf = get_transforms()
    train_ds = ClipDataset(csv_path, 'train', train_tf)
    val_ds = ClipDataset(csv_path, 'validation', val_tf)
    test_ds = ClipDataset(csv_path, 'test', val_tf)

    labels = [c['label'] for c in train_ds.clips]
    weights = [1.0 / Counter(labels)[l] for l in labels]
    sampler = WeightedRandomSampler(weights, len(weights))

    train_loader = DataLoader(train_ds, batch_size=BATCH_SIZE, sampler=sampler, num_workers=0, pin_memory=True)
    val_loader = DataLoader(val_ds, batch_size=BATCH_SIZE, shuffle=False, num_workers=0, pin_memory=True)
    test_loader = DataLoader(test_ds, batch_size=BATCH_SIZE, shuffle=False, num_workers=0, pin_memory=True)

    print(f'Train: {len(train_ds)} | Val: {len(val_ds)} | Test: {len(test_ds)}')
    print(f'Class dist: {dict(Counter(labels))}')

    v3_weights = str(V3_MODELS_DIR / 'best_phase3.pth')

    VARIANTS = [
        ('Full Model (Baseline)',    {'use_se': True,  'use_lstm': True,  'use_attn': True,  'use_aux': True},  v3_weights),
        ('No Aux Features',         {'use_se': True,  'use_lstm': True,  'use_attn': True,  'use_aux': False}, v3_weights),
        ('No Attention',            {'use_se': True,  'use_lstm': True,  'use_attn': False, 'use_aux': True},  v3_weights),
        ('No Temporal LSTM',        {'use_se': True,  'use_lstm': False, 'use_attn': False, 'use_aux': True},  v3_weights),
        ('No SE Block',             {'use_se': False, 'use_lstm': True,  'use_attn': True,  'use_aux': True},  v3_weights),
    ]

    results = []
    for name, config, pretrained in VARIANTS:
        cached = load_variant_result(name)
        if cached:
            print(f"\n  [SKIP] {name} - already completed (AUC={cached['AUC']:.4f})")
            results.append(cached)
            continue
        torch.cuda.empty_cache()
        r = train_variant(name, config, train_loader, val_loader, test_loader, pretrained)
        save_variant_result(r)
        print(f"  [SAVED] {name} result cached to disk")
        results.append(r)

    generate_charts(results)

    print("\n" + "="*60)
    print("  ABLATION STUDY V2 COMPLETE!")
    print(f"  Results: {OUTPUT_DIR}")
    print("="*60)


if __name__ == '__main__':
    main()

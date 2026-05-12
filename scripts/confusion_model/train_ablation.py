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

from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns

FRAMES_DIR = Path(__file__).parent / 'frames_v2'
OUTPUT_DIR = Path(__file__).parent / 'output_ablation'
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# Để giảm thời gian Ablation, ta có thể giảm Epochs xuống so với v3
IMG_SIZE = 224
BATCH_SIZE = 16
SEQ_LEN = 5
SEED = 42

# Số epoch rút gọn cho Ablation Study
PHASE1_EPOCHS = 5 
PHASE2_EPOCHS = 10
PHASE3_EPOCHS = 5

torch.manual_seed(SEED)
np.random.seed(SEED)
random.seed(SEED)

device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

class ClipDataset(Dataset):
    def __init__(self, csv_path, split, transform=None, seq_len=SEQ_LEN):
        df = pd.read_csv(csv_path)
        df = df[df['frame_path'].str.contains(f'/{split}/' if '/' in df['frame_path'].iloc[0] else f'\\\\{split}\\\\', regex=True)]

        self.transform = transform
        self.seq_len = seq_len
        self.clips = []

        grouped = df.groupby('clip_id')
        for clip_id, group in grouped:
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
            self.clips.append({
                'frames': frames,
                'label': label,
                'aux': aux,
                'clip_id': clip_id,
            })

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

        sequence = torch.stack(imgs)
        aux = torch.tensor(clip['aux'], dtype=torch.float32)
        label = torch.tensor(clip['label'], dtype=torch.float32)
        return sequence, aux, label

class SEBlock(nn.Module):
    def __init__(self, channels, reduction=16):
        super().__init__()
        self.pool = nn.AdaptiveAvgPool1d(1)
        self.fc = nn.Sequential(
            nn.Linear(channels, channels // reduction),
            nn.SiLU(),
            nn.Linear(channels // reduction, channels),
            nn.Sigmoid(),
        )

    def forward(self, x):
        b, c = x.shape
        w = self.fc(x)
        return x * w

# Model đa năng hỗ trợ tắt/bật các component
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
            self.attn = nn.Sequential(
                nn.Linear(rnn_out_dim, 1),
                nn.Softmax(dim=1),
            )

        fusion_dim = rnn_out_dim
        if self.use_aux:
            fusion_dim += num_aux

        self.head = nn.Sequential(
            nn.LayerNorm(fusion_dim),
            nn.Dropout(0.4),
            nn.Linear(fusion_dim, 256),
            nn.SiLU(),
            nn.BatchNorm1d(256),
            nn.Dropout(0.3),
            nn.Linear(256, 128),
            nn.SiLU(),
            nn.Dropout(0.2),
            nn.Linear(128, 1),
        )

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
        x = seq.view(B * T, C, H, W)
        x = self.backbone(x).flatten(1)

        if self.use_se:
            x = self.se(x)

        x = x.view(B, T, self.feat_dim)

        if self.use_lstm:
            lstm_out, _ = self.lstm(x)
            if self.use_attn:
                attn_w = self.attn(lstm_out)
                context = (attn_w * lstm_out).sum(dim=1)
            else:
                context = lstm_out.mean(dim=1)
        else:
            context = x.mean(dim=1)

        if self.use_aux:
            fused = torch.cat([context, aux], dim=1)
        else:
            fused = context

        return self.head(fused).squeeze(1)

class FocalLoss(nn.Module):
    def __init__(self, alpha=0.6, gamma=2.0, smoothing=0.05):
        super().__init__()
        self.alpha = alpha
        self.gamma = gamma
        self.smoothing = smoothing

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
        transforms.ColorJitter(brightness=0.3, contrast=0.3, saturation=0.2, hue=0.05),
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

    probs = np.array(all_probs)
    yt = np.array(all_labels)
    yp = (probs > 0.5).astype(int)

    acc = float(np.mean(yt == yp))
    try:
        auc = roc_auc_score(yt, probs)
    except:
        auc = 0
    return acc, auc

def train_ablation_variant(variant_name, config, train_loader, val_loader, test_loader):
    print(f"\n{'='*50}\nTraining Variant: {variant_name}\nConfig: {config}\n{'='*50}")
    
    model = TemporalConfusionModel(**config).to(device)
    model.freeze_backbone()
    criterion = FocalLoss()
    scaler = torch.amp.GradScaler('cuda')
    
    best_auc = 0
    
    # Phase 1
    print(f"  [Phase 1] Head & LSTM - {PHASE1_EPOCHS} epochs")
    opt = optim.AdamW(filter(lambda p: p.requires_grad, model.parameters()), lr=1e-3)
    for epoch in range(PHASE1_EPOCHS):
        model.train()
        total_loss, total_clips = 0, 0
        for seq, aux, labels in train_loader:
            seq, aux, labels = seq.to(device), aux.to(device), labels.to(device)
            opt.zero_grad(set_to_none=True)
            with torch.amp.autocast('cuda'):
                loss = criterion(model(seq, aux), labels)
            scaler.scale(loss).backward()
            scaler.step(opt)
            scaler.update()
            total_loss += loss.item() * seq.size(0)
            total_clips += seq.size(0)
        print(f"    Epoch {epoch+1}/{PHASE1_EPOCHS} - Loss: {total_loss/total_clips:.4f}")
    
    # Phase 2
    print(f"  [Phase 2] Unfreeze Backbone (150 layers) - {PHASE2_EPOCHS} epochs")
    model.unfreeze_backbone(last_n=150)
    opt = optim.AdamW(filter(lambda p: p.requires_grad, model.parameters()), lr=2e-5)
    for epoch in range(PHASE2_EPOCHS):
        model.train()
        total_loss, total_clips = 0, 0
        for seq, aux, labels in train_loader:
            seq, aux, labels = seq.to(device), aux.to(device), labels.to(device)
            opt.zero_grad(set_to_none=True)
            with torch.amp.autocast('cuda'):
                loss = criterion(model(seq, aux), labels)
            scaler.scale(loss).backward()
            scaler.step(opt)
            scaler.update()
            total_loss += loss.item() * seq.size(0)
            total_clips += seq.size(0)
        print(f"    Epoch {epoch+1}/{PHASE2_EPOCHS} - Loss: {total_loss/total_clips:.4f}")

    # Phase 3
    print(f"  [Phase 3] Full Unfreeze - {PHASE3_EPOCHS} epochs")
    model.unfreeze_all()
    opt = optim.AdamW(model.parameters(), lr=5e-6)
    for epoch in range(PHASE3_EPOCHS):
        model.train()
        total_loss, total_clips = 0, 0
        for seq, aux, labels in train_loader:
            seq, aux, labels = seq.to(device), aux.to(device), labels.to(device)
            opt.zero_grad(set_to_none=True)
            with torch.amp.autocast('cuda'):
                loss = criterion(model(seq, aux), labels)
            scaler.scale(loss).backward()
            scaler.step(opt)
            scaler.update()
            total_loss += loss.item() * seq.size(0)
            total_clips += seq.size(0)
        print(f"    Epoch {epoch+1}/{PHASE3_EPOCHS} - Loss: {total_loss/total_clips:.4f}")

    # Evaluate on test set
    acc, auc = evaluate(model, test_loader)
    print(f"[{variant_name}] Test Acc: {acc:.4f} | Test AUC: {auc:.4f}")
    
    return acc, auc

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

    train_loader = DataLoader(train_ds, batch_size=BATCH_SIZE, sampler=sampler, num_workers=0)
    val_loader = DataLoader(val_ds, batch_size=BATCH_SIZE, shuffle=False, num_workers=0)
    test_loader = DataLoader(test_ds, batch_size=BATCH_SIZE, shuffle=False, num_workers=0)

    # Các mô hình để Ablation Study
    VARIANTS = {
        'Full_Model': {'use_se': True, 'use_lstm': True, 'use_attn': True, 'use_aux': True},
        'No_Aux_Features': {'use_se': True, 'use_lstm': True, 'use_attn': True, 'use_aux': False},
        'No_Attention': {'use_se': True, 'use_lstm': True, 'use_attn': False, 'use_aux': True},
        'No_Temporal_LSTM': {'use_se': True, 'use_lstm': False, 'use_attn': False, 'use_aux': True},
    }

    results = []

    for name, config in VARIANTS.items():
        acc, auc = train_ablation_variant(name, config, train_loader, val_loader, test_loader)
        results.append({
            'Variant': name,
            'Accuracy': acc,
            'AUC': auc
        })

    # Lưu kết quả
    df_res = pd.DataFrame(results)
    df_res.to_csv(OUTPUT_DIR / 'ablation_results.csv', index=False)
    
    # Vẽ biểu đồ so sánh
    plt.figure(figsize=(10, 6))
    sns.barplot(data=df_res, x='Variant', y='AUC', palette='viridis')
    plt.title('Ablation Study: Tác động của từng thành phần lên AUC', fontsize=14, fontweight='bold')
    plt.ylim(min(df_res['AUC'])-0.1, max(df_res['AUC'])+0.05)
    for index, row in df_res.iterrows():
        plt.text(index, row.AUC + 0.01, f"{row.AUC:.3f}", color='black', ha="center")
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / 'ablation_auc_comparison.png')
    
    print("\n" + "="*50)
    print("ABLATION STUDY HOÀN TẤT!")
    print(df_res)
    print("="*50)

if __name__ == '__main__':
    main()

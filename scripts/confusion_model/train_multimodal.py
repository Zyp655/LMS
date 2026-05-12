import os, json, sys
import numpy as np
import pandas as pd
from pathlib import Path
from collections import Counter

from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.neural_network import MLPClassifier
from sklearn.model_selection import StratifiedKFold, cross_val_predict
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import (
    classification_report, confusion_matrix, roc_auc_score,
    roc_curve, f1_score, accuracy_score, precision_score, recall_score
)
from sklearn.pipeline import Pipeline

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns

OUTPUT_DIR = Path(__file__).parent / 'output_multimodal'
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

FEATURE_NAMES = [
    'pause_count', 'avg_pause_duration', 'long_pause_count',
    'rewind_count', 'rewind_same_spot', 'speed_decrease',
    'confused_ratio', 'frustrated_ratio',
    'emotion_transitions', 'neg_emotion_streak',
    'quiz_score', 'quiz_time',
]

BEHAVIOR_FEATURES = [0, 1, 2, 3, 4, 5]
EMOTION_FEATURES  = [6, 7, 8, 9]
QUIZ_FEATURES     = [10, 11]


def load_data_from_logs(db_export_path: str) -> tuple:
    df = pd.read_json(db_export_path)
    X = df[FEATURE_NAMES].values.astype(np.float32)
    y = (df['ground_truth'] >= 1).astype(int).values
    return X, y


def generate_synthetic_data(n_samples=2000, seed=42) -> tuple:
    rng = np.random.RandomState(seed)

    n_confused = n_samples // 3
    n_normal = n_samples - n_confused

    X_normal = np.column_stack([
        rng.poisson(1.0, n_normal),
        rng.exponential(3.0, n_normal),
        rng.poisson(0.3, n_normal),
        rng.poisson(0.5, n_normal),
        rng.binomial(1, 0.1, n_normal),
        rng.binomial(1, 0.15, n_normal),
        rng.beta(1, 8, n_normal),
        rng.beta(1, 10, n_normal),
        rng.poisson(1.0, n_normal),
        rng.poisson(0.5, n_normal),
        rng.normal(75, 15, n_normal).clip(0, 100),
        rng.normal(30, 10, n_normal).clip(5, 120),
    ])

    X_confused = np.column_stack([
        rng.poisson(4.0, n_confused),
        rng.exponential(12.0, n_confused),
        rng.poisson(1.5, n_confused),
        rng.poisson(3.0, n_confused),
        rng.binomial(1, 0.6, n_confused),
        rng.binomial(1, 0.5, n_confused),
        rng.beta(4, 3, n_confused),
        rng.beta(3, 4, n_confused),
        rng.poisson(4.0, n_confused),
        rng.poisson(2.5, n_confused),
        rng.normal(40, 20, n_confused).clip(0, 100),
        rng.normal(60, 20, n_confused).clip(5, 120),
    ])

    X = np.vstack([X_normal, X_confused]).astype(np.float32)
    y = np.array([0]*n_normal + [1]*n_confused, dtype=int)

    noise = rng.normal(0, 0.05, X.shape)
    X = np.abs(X + noise * X)

    shuffle_idx = rng.permutation(len(y))
    return X[shuffle_idx], y[shuffle_idx]


def build_models():
    return {
        'LogisticRegression': Pipeline([
            ('scaler', StandardScaler()),
            ('clf', LogisticRegression(
                C=1.0, max_iter=1000, class_weight='balanced', random_state=42
            )),
        ]),
        'RandomForest': Pipeline([
            ('scaler', StandardScaler()),
            ('clf', RandomForestClassifier(
                n_estimators=200, max_depth=8, min_samples_leaf=5,
                class_weight='balanced', random_state=42, n_jobs=-1
            )),
        ]),
        'GradientBoosting': Pipeline([
            ('scaler', StandardScaler()),
            ('clf', GradientBoostingClassifier(
                n_estimators=200, max_depth=4, learning_rate=0.1,
                subsample=0.8, random_state=42
            )),
        ]),
        'MLP': Pipeline([
            ('scaler', StandardScaler()),
            ('clf', MLPClassifier(
                hidden_layer_sizes=(64, 32, 16),
                activation='relu', solver='adam',
                max_iter=500, early_stopping=True,
                validation_fraction=0.15, random_state=42,
                learning_rate='adaptive', alpha=1e-3,
            )),
        ]),
    }


def evaluate_model(name, model, X, y, cv):
    y_pred = cross_val_predict(model, X, y, cv=cv, method='predict')
    y_prob = cross_val_predict(model, X, y, cv=cv, method='predict_proba')[:, 1]

    acc = accuracy_score(y, y_pred)
    prec = precision_score(y, y_pred, zero_division=0)
    rec = recall_score(y, y_pred, zero_division=0)
    f1 = f1_score(y, y_pred, zero_division=0)
    try:
        auc = roc_auc_score(y, y_prob)
    except:
        auc = 0.0

    return {
        'name': name,
        'accuracy': acc,
        'precision': prec,
        'recall': rec,
        'f1': f1,
        'auc': auc,
        'y_pred': y_pred,
        'y_prob': y_prob,
    }


def run_ablation(X, y, cv):
    ablation_configs = {
        'Behavior only':         BEHAVIOR_FEATURES,
        'Emotion only':          EMOTION_FEATURES,
        'Quiz only':             QUIZ_FEATURES,
        'Behavior + Emotion':    BEHAVIOR_FEATURES + EMOTION_FEATURES,
        'Behavior + Quiz':       BEHAVIOR_FEATURES + QUIZ_FEATURES,
        'Emotion + Quiz':        EMOTION_FEATURES + QUIZ_FEATURES,
        'All (Multimodal)':      list(range(12)),
    }

    best_model_cls = GradientBoostingClassifier
    results = []

    for config_name, feature_indices in ablation_configs.items():
        X_sub = X[:, feature_indices]
        pipe = Pipeline([
            ('scaler', StandardScaler()),
            ('clf', best_model_cls(
                n_estimators=200, max_depth=4, learning_rate=0.1,
                subsample=0.8, random_state=42
            )),
        ])
        y_pred = cross_val_predict(pipe, X_sub, y, cv=cv)
        y_prob = cross_val_predict(pipe, X_sub, y, cv=cv, method='predict_proba')[:, 1]

        results.append({
            'config': config_name,
            'features': [FEATURE_NAMES[i] for i in feature_indices],
            'n_features': len(feature_indices),
            'accuracy': accuracy_score(y, y_pred),
            'precision': precision_score(y, y_pred, zero_division=0),
            'recall': recall_score(y, y_pred, zero_division=0),
            'f1': f1_score(y, y_pred, zero_division=0),
            'auc': roc_auc_score(y, y_prob) if len(set(y)) > 1 else 0,
        })

    return results


def export_mlp_weights(model: Pipeline, output_path: Path):
    scaler = model.named_steps['scaler']
    mlp = model.named_steps['clf']

    weights = {
        'scaler_mean': scaler.mean_.tolist(),
        'scaler_scale': scaler.scale_.tolist(),
        'layers': [],
    }

    for i, (w, b) in enumerate(zip(mlp.coefs_, mlp.intercepts_)):
        weights['layers'].append({
            'weights': w.tolist(),
            'biases': b.tolist(),
            'activation': 'relu' if i < len(mlp.coefs_) - 1 else 'sigmoid',
        })

    weights['feature_names'] = FEATURE_NAMES
    weights['n_features'] = len(FEATURE_NAMES)

    with open(output_path, 'w') as f:
        json.dump(weights, f, indent=2)

    print(f'  Exported MLP weights to {output_path}')
    print(f'  Architecture: {[l["weights"] for l in weights["layers"]]}')
    size_kb = output_path.stat().st_size / 1024
    print(f'  File size: {size_kb:.1f} KB')


def export_lr_weights(model: Pipeline, output_path: Path):
    scaler = model.named_steps['scaler']
    lr = model.named_steps['clf']

    weights = {
        'scaler_mean': scaler.mean_.tolist(),
        'scaler_scale': scaler.scale_.tolist(),
        'coefficients': lr.coef_[0].tolist(),
        'intercept': float(lr.intercept_[0]),
        'feature_names': FEATURE_NAMES,
        'n_features': len(FEATURE_NAMES),
    }

    with open(output_path, 'w') as f:
        json.dump(weights, f, indent=2)

    print(f'  Exported LR weights to {output_path}')


def plot_results(model_results, ablation_results, X, y):
    fig, axes = plt.subplots(2, 2, figsize=(16, 12))

    names = [r['name'] for r in model_results]
    metrics = ['accuracy', 'precision', 'recall', 'f1', 'auc']
    x_pos = np.arange(len(names))
    width = 0.15
    for i, metric in enumerate(metrics):
        values = [r[metric] for r in model_results]
        axes[0, 0].bar(x_pos + i * width, values, width, label=metric.upper())
    axes[0, 0].set_xticks(x_pos + width * 2)
    axes[0, 0].set_xticklabels(names, rotation=15, fontsize=9)
    axes[0, 0].set_title('Model Comparison', fontweight='bold')
    axes[0, 0].legend(fontsize=8)
    axes[0, 0].set_ylim(0, 1.05)

    best = max(model_results, key=lambda r: r['auc'])
    cm = confusion_matrix(y, best['y_pred'])
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', ax=axes[0, 1],
                xticklabels=['Normal', 'Confused'],
                yticklabels=['Normal', 'Confused'])
    axes[0, 1].set_title(f'Best Model: {best["name"]}', fontweight='bold')

    abl_names = [r['config'] for r in ablation_results]
    abl_f1 = [r['f1'] for r in ablation_results]
    abl_auc = [r['auc'] for r in ablation_results]
    colors = ['#ff6b6b' if 'only' in n else '#4ecdc4' if 'All' in n else '#45b7d1'
              for n in abl_names]
    y_pos = np.arange(len(abl_names))
    axes[1, 0].barh(y_pos, abl_f1, color=colors, alpha=0.8)
    axes[1, 0].set_yticks(y_pos)
    axes[1, 0].set_yticklabels(abl_names, fontsize=9)
    axes[1, 0].set_title('Ablation Study — F1 Score', fontweight='bold')
    axes[1, 0].set_xlim(0, 1.05)
    for i, v in enumerate(abl_f1):
        axes[1, 0].text(v + 0.01, i, f'{v:.3f}', va='center', fontsize=9)

    for r in model_results:
        if r['auc'] > 0:
            fpr, tpr, _ = roc_curve(y, r['y_prob'])
            axes[1, 1].plot(fpr, tpr, lw=2, label=f'{r["name"]} (AUC={r["auc"]:.3f})')
    axes[1, 1].plot([0, 1], [0, 1], 'k--', alpha=0.3)
    axes[1, 1].set_title('ROC Curves', fontweight='bold')
    axes[1, 1].legend(fontsize=8)
    axes[1, 1].set_xlabel('FPR')
    axes[1, 1].set_ylabel('TPR')

    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / 'multimodal_results.png', dpi=150)
    print(f'\n  Saved plots to {OUTPUT_DIR / "multimodal_results.png"}')


def main():
    print('=' * 60)
    print('MULTIMODAL CONFUSION DETECTION — BEHAVIORAL FEATURES')
    print('Train: LR / RandomForest / GradientBoosting / MLP')
    print('=' * 60)

    db_export = Path(__file__).parent / 'confusion_logs_export.json'
    if db_export.exists():
        print('\n[1/5] Loading real data from confusion logs...')
        X, y = load_data_from_logs(str(db_export))
    else:
        print('\n[1/5] No real data found. Generating synthetic dataset...')
        print('  (Export confusion_logs from DB to confusion_logs_export.json for real data)')
        X, y = generate_synthetic_data(n_samples=2000)

    print(f'  Samples: {len(y)} | Confused: {sum(y)} ({sum(y)/len(y)*100:.1f}%) | Normal: {sum(1-y)}')
    print(f'  Features: {len(FEATURE_NAMES)}')

    cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)

    print('\n[2/5] Training & evaluating 4 models (5-fold CV)...')
    models = build_models()
    results = []

    for name, model in models.items():
        r = evaluate_model(name, model, X, y, cv)
        results.append(r)
        print(f'  {name:25s} | Acc: {r["accuracy"]:.4f} | Prec: {r["precision"]:.4f} | '
              f'Rec: {r["recall"]:.4f} | F1: {r["f1"]:.4f} | AUC: {r["auc"]:.4f}')

    print('\n[3/5] Running ablation study...')
    ablation_results = run_ablation(X, y, cv)
    print(f'\n  {"Config":<25s} | {"Feats":>5s} | {"Acc":>6s} | {"F1":>6s} | {"AUC":>6s}')
    print('  ' + '-' * 65)
    for r in ablation_results:
        print(f'  {r["config"]:<25s} | {r["n_features"]:>5d} | {r["accuracy"]:.4f} | '
              f'{r["f1"]:.4f} | {r["auc"]:.4f}')

    print('\n[4/5] Exporting model weights for Dart backend...')
    best_result = max(results, key=lambda r: r['auc'])
    print(f'  Best model: {best_result["name"]} (AUC={best_result["auc"]:.4f})')

    for name, model in models.items():
        model.fit(X, y)

    export_mlp_weights(models['MLP'], OUTPUT_DIR / 'mlp_weights.json')
    export_lr_weights(models['LogisticRegression'], OUTPUT_DIR / 'lr_weights.json')

    print('\n[5/5] Generating plots...')
    plot_results(results, ablation_results, X, y)

    summary = {
        'model_comparison': [{
            'name': r['name'],
            'accuracy': r['accuracy'],
            'precision': r['precision'],
            'recall': r['recall'],
            'f1': r['f1'],
            'auc': r['auc'],
        } for r in results],
        'ablation_study': ablation_results,
        'best_model': best_result['name'],
        'best_auc': best_result['auc'],
        'best_f1': best_result['f1'],
        'dataset_size': len(y),
        'confused_ratio': float(sum(y) / len(y)),
        'feature_names': FEATURE_NAMES,
    }
    with open(OUTPUT_DIR / 'summary.json', 'w') as f:
        json.dump(summary, f, indent=2, default=str)

    print('\n' + '=' * 60)
    print('TRAINING COMPLETE!')
    print(f'  Best:     {best_result["name"]}')
    print(f'  AUC:      {best_result["auc"]:.4f}')
    print(f'  F1:       {best_result["f1"]:.4f}')
    print(f'  Outputs:  {OUTPUT_DIR}')
    print('=' * 60)


if __name__ == '__main__':
    main()

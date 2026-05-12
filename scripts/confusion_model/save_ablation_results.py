import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path

OUTPUT_DIR = Path(__file__).parent / 'output_ablation'
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

results = [
    {'Variant': 'Full Model',        'Accuracy': 0.6497, 'AUC': 0.5411},
    {'Variant': 'No Aux Features',   'Accuracy': 0.7113, 'AUC': 0.5161},
    {'Variant': 'No Attention',      'Accuracy': 0.7124, 'AUC': 0.5631},
    {'Variant': 'No Temporal LSTM',  'Accuracy': 0.6867, 'AUC': 0.5685},
]

df = pd.DataFrame(results)
df.to_csv(OUTPUT_DIR / 'ablation_results.csv', index=False)
print("CSV saved!")
print(df.to_string(index=False))

fig, axes = plt.subplots(1, 2, figsize=(14, 6))

colors = ['#2ecc71', '#e74c3c', '#3498db', '#f39c12']

bars1 = axes[0].bar(df['Variant'], df['AUC'], color=colors, edgecolor='white', linewidth=1.5)
axes[0].set_title('Ablation Study: AUC Score', fontsize=14, fontweight='bold')
axes[0].set_ylabel('AUC', fontsize=12)
axes[0].set_ylim(0.45, 0.65)
for bar, val in zip(bars1, df['AUC']):
    axes[0].text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.005,
                 f'{val:.4f}', ha='center', va='bottom', fontweight='bold', fontsize=11)
axes[0].tick_params(axis='x', rotation=15)

bars2 = axes[1].bar(df['Variant'], df['Accuracy'], color=colors, edgecolor='white', linewidth=1.5)
axes[1].set_title('Ablation Study: Accuracy', fontsize=14, fontweight='bold')
axes[1].set_ylabel('Accuracy', fontsize=12)
axes[1].set_ylim(0.55, 0.80)
for bar, val in zip(bars2, df['Accuracy']):
    axes[1].text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.005,
                 f'{val:.4f}', ha='center', va='bottom', fontweight='bold', fontsize=11)
axes[1].tick_params(axis='x', rotation=15)

plt.suptitle('Confusion Detection - Ablation Study on DAiSEE Dataset', fontsize=16, fontweight='bold', y=1.02)
plt.tight_layout()
plt.savefig(OUTPUT_DIR / 'ablation_comparison.png', dpi=200, bbox_inches='tight')
print(f"Chart saved to {OUTPUT_DIR / 'ablation_comparison.png'}")

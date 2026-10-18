import os
import re
import sys
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

def parse_logs_and_generate_assets(log_path='log.txt', output_dir='assets'):
    """Parses simulation log file and generates classification & protocol charts."""
    os.makedirs(output_dir, exist_ok=True)
    
    if not os.path.exists(log_path):
        print(f"[Warning] Log file '{log_path}' not found. Skipping log charts.")
        return
    
    with open(log_path, 'r', encoding='utf-8', errors='ignore') as f:
        text = f.read()

    plt.style.use('seaborn-v0_8-whitegrid' if 'seaborn-v0_8-whitegrid' in plt.style.available else 'default')

    # 1. Event Frequency & Messaging Protocol
    regex_print = re.compile(r'^(S\d+)\s+PRINT\s+\[print,\s*"NODO_",\s*\$my_id,\s*"_([A-Z_]+)"\]', re.MULTILINE)
    matches = regex_print.findall(text)
    df_events = pd.DataFrame(matches, columns=['node', 'detail'])

    event_labels = {
        'ACK_ENVIADO_A_VECINO': 'ACK Sent (MSG 101)\n(Validation response to neighbor)',
        'SOLICITA_VALIDACION_VECINO': 'Request Validation (MSG 100)\n(Alert when Confidence < 90%)',
        'ALERTA_RECHAZADA_AISLAMIENTO': 'Alert Rejected\n(Rejection / Node isolation)',
        'ALERTA_CONFIRMADA_POR_VECINO': 'Alert Confirmed\n(Consensus reached)'
    }

    df_excl = df_events[df_events['detail'] != 'MONITOREO_NORMAL'].copy()
    df_excl['label_explicado'] = df_excl['detail'].map(event_labels)
    event_counts = df_excl['label_explicado'].value_counts()

    plt.figure(figsize=(9, 5))
    bars1 = plt.barh(event_counts.index, event_counts.values, color=['#2980b9', '#d35400', '#c0392b', '#27ae60'][:len(event_counts)])
    plt.title('Event Frequency and Messaging Protocol', fontsize=13, fontweight='bold', pad=15)
    plt.xlabel('Occurrences in Simulation', fontsize=11)
    plt.xlim(0, max(event_counts.values) * 1.15)

    for bar in bars1:
        width = bar.get_width()
        plt.text(width + 5, bar.get_y() + bar.get_height()/2, f'{int(width)}', ha='left', va='center', fontweight='bold', fontsize=10)

    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, '1_frecuencia_eventos.png'), dpi=300)
    plt.close()

    # 2. Top Requesting Nodes
    top_nodes = df_events[df_events['detail'] == 'SOLICITA_VALIDACION_VECINO']['node'].value_counts().head(10)

    plt.figure(figsize=(9, 5))
    bars2 = plt.bar(top_nodes.index, top_nodes.values, color='#8e44ad', width=0.6)
    plt.title('Top 10 Validation Requesting Nodes (MSG 100)', fontsize=13, fontweight='bold', pad=15)
    plt.xlabel('Node ID', fontsize=11)
    plt.ylabel('Number of Requests Sent', fontsize=11)
    plt.ylim(0, max(top_nodes.values) * 1.25)

    for bar in bars2:
        height = bar.get_height()
        plt.text(bar.get_x() + bar.get_width()/2, height + 0.15, f'{int(height)}', ha='center', va='bottom', fontweight='bold', fontsize=10)

    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, '2_top_nodos_solicitantes.png'), dpi=300)
    plt.close()

    # 3. Local Inference vs Consensus
    casos_local = len(re.findall(r'RANDB:\s*90\s+101', text))
    casos_consenso = len(re.findall(r'RANDB:\s*50\s+90', text))
    total_casos = casos_local + casos_consenso
    pct_local = (casos_local / total_casos) * 100
    pct_consenso = (casos_consenso / total_casos) * 100

    plt.figure(figsize=(8, 6))
    wedges, texts, autotexts = plt.pie(
        [casos_local, casos_consenso],
        labels=[
            f'Autonomous Local Inference\n(Confidence ≥ 90%)\n[{casos_local:,} cases]', 
            f'Neighbor Consensus Triggered\n(Confidence < 90%)\n[{casos_consenso} cases]'
        ],
        colors=['#2ecc71', '#e74c3c'],
        autopct='%1.2f%%',
        startangle=140,
        pctdistance=0.75,
        explode=(0.05, 0),
        wedgeprops=dict(width=0.45, edgecolor='white', linewidth=2)
    )

    plt.setp(autotexts, size=11, weight="bold", color="white")
    plt.setp(texts, size=10, weight="bold")
    plt.title(f'Classification Resolution:\nLocal Inference ({pct_local:.1f}%) vs. Consensus ({pct_consenso:.1f}%)', fontsize=13, fontweight='bold', pad=15)
    plt.text(0, 0, f'Total Evaluations:\n{total_casos:,}\n\n{pct_local:.2f}%\nResolved Locally', ha='center', va='center', fontsize=11, fontweight='bold', color='#2c3e50')

    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, '3_inferencia_vs_consenso.png'), dpi=300)
    plt.close()

    print(f"✅ Log analysis charts saved in '{output_dir}/'")


def calculate_energy_metrics(csv_path, output_dir='assets'):
    """Calculates energy consumption metrics from simulation CSV and outputs charts/tables."""
    os.makedirs(output_dir, exist_ok=True)
    
    if not os.path.exists(csv_path):
        print(f"[Warning] Energy CSV file '{csv_path}' not found. Skipping energy analysis.")
        return None

    df = pd.read_csv(csv_path, sep=";", index_col=False)
    df = df.loc[:, ~df.columns.str.startswith("Unnamed")]

    time = df["Time (Sec)"].to_numpy()
    energy = df.drop(columns="Time (Sec)")
    duration = time[-1] - time[0]

    # Consumed energy per node = initial energy - final energy
    consumed = energy.iloc[0] - energy.iloc[-1]

    summary = pd.DataFrame({
        "Node_ID": energy.columns,
        "Initial_Energy": energy.iloc[0].to_numpy(),
        "Final_Energy": energy.iloc[-1].to_numpy(),
        "Consumed": consumed.to_numpy(),
        "Consumed_pct": consumed.to_numpy() / energy.iloc[0].to_numpy() * 100,
        "Avg_Power": consumed.to_numpy() / duration,   # energy_units / s
    }).sort_values("Consumed", ascending=False).reset_index(drop=True)

    print(f"\nSimulation duration: {duration:.2f} s | Nodes: {len(summary)}")
    print("=== ENERGY CONSUMPTION BY NODE (top 10) ===")
    print(summary.head(10).to_string(index=False))
    print("\n=== NETWORK ENERGY METRICS ===")
    print(f"Total consumption:    {summary['Consumed'].sum():.4f}")
    print(f"Average consumption:  {summary['Consumed'].mean():.4f}")
    print(f"Nodes with 0 consumption: {(summary['Consumed'] == 0).sum()}")

    # Save summary CSV files
    summary.to_csv("energy_summary.csv", index=False)
    summary.to_csv(os.path.join(output_dir, "energy_summary.csv"), index=False)

    # 4. Top 10 Energy Consuming Nodes
    plt.figure(figsize=(9, 5))
    top_energy = summary.head(10)
    bars4 = plt.bar(top_energy["Node_ID"], top_energy["Consumed"], color='#e67e22', width=0.6)
    plt.title('Top 10 Energy Consuming Nodes', fontsize=13, fontweight='bold', pad=15)
    plt.xlabel('Node ID', fontsize=11)
    plt.ylabel('Energy Consumed', fontsize=11)
    plt.ylim(0, max(top_energy["Consumed"]) * 1.2)

    for bar in bars4:
        height = bar.get_height()
        plt.text(bar.get_x() + bar.get_width()/2, height + max(top_energy["Consumed"])*0.02, f'{height:.2f}', ha='center', va='bottom', fontweight='bold', fontsize=9)

    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, '4_top_consumo_energia.png'), dpi=300)
    plt.close()

    # 5. Network Energy Distribution Histogram
    plt.figure(figsize=(9, 5))
    sns.histplot(summary["Consumed"], kde=True, color='#16a085', bins=15)
    plt.axvline(summary["Consumed"].mean(), color='#c0392b', linestyle='--', linewidth=2, label=f'Mean ({summary["Consumed"].mean():.2f})')
    plt.title('Network Energy Consumption Distribution', fontsize=13, fontweight='bold', pad=15)
    plt.xlabel('Energy Consumed per Node', fontsize=11)
    plt.ylabel('Node Count', fontsize=11)
    plt.legend(fontsize=10)

    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, '5_distribucion_energia.png'), dpi=300)
    plt.close()

    print(f"✅ Energy charts saved in '{output_dir}/'")
    return summary


if __name__ == "__main__":
    log_file = sys.argv[1] if len(sys.argv) > 1 else "logs/log.txt"
    csv_file = sys.argv[2] if len(sys.argv) > 2 else "results/wisen_simulation.csv"
    
    if not os.path.exists(csv_file) and os.path.exists('wisen_simulation.csv'):
        csv_file = 'wisen_simulation.csv'

    print("--- 1. Processing Simulation Logs ---")
    parse_logs_and_generate_assets(log_file, "assets")

    print("\n--- 2. Processing Energy Metrics ---")
    calculate_energy_metrics(csv_file, "assets")
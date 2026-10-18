import sys
import pandas as pd
import numpy as np
 
 
def calculate_energy_metrics(csv_path):
   
    df = pd.read_csv(csv_path, sep=";", index_col=False)
    df = df.loc[:, ~df.columns.str.startswith("Unnamed")]
 
    time = df["Time (Sec)"].to_numpy()
    energy = df.drop(columns="Time (Sec)")
    duration = time[-1] - time[0]
 
    # Energía consumida por nodo = energía inicial - energía final
    consumed = energy.iloc[0] - energy.iloc[-1]
 
    
 
    summary = pd.DataFrame({
        "Node_ID": energy.columns,
        "Initial_Energy": energy.iloc[0].to_numpy(),
        "Final_Energy": energy.iloc[-1].to_numpy(),
        "Consumed": consumed.to_numpy(),
        "Consumed_pct": consumed.to_numpy() / energy.iloc[0].to_numpy() * 100,
        "Avg_Power": consumed.to_numpy() / duration,   # unidad_energía / s
    }).sort_values("Consumed", ascending=False).reset_index(drop=True)
 
    print(f"Simulation duration: {duration:.2f} s | Nodes: {len(summary)}")
    print("=== ENERGY CONSUMPTION BY NODE (top 10) ===")
    print(summary.head(10).to_string(index=False))
    print("\n=== NETWORK ===")
    print(f"Total consumption:  {summary['Consumed'].sum():.4f}")
    print(f"Average consumption:  {summary['Consumed'].mean():.4f}")
    print(f"Nodes without consumption: {(summary['Consumed'] == 0).sum()}")
    return summary
 
 
if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else "../results/wisen_simulation.csv"
    result = calculate_energy_metrics(path)
    result.to_csv("energy_summary.csv", index=False)
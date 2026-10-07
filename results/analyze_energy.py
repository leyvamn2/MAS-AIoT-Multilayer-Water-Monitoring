import sys
import pandas as pd
import numpy as np
 
 
def calculate_energy_metrics(csv_path):
    """
    Lee la salida de energía de CupCarbon (formato ancho):
    primera columna = 'Time (Sec)', una columna por nodo con la ENERGÍA RESTANTE.
    Separador ';' y una columna vacía al final (por el ';' final de cada línea).
    """
    df = pd.read_csv(csv_path, sep=";", index_col=False)
    df = df.loc[:, ~df.columns.str.startswith("Unnamed")]
 
    time = df["Time (Sec)"].to_numpy()
    energy = df.drop(columns="Time (Sec)")
    duration = time[-1] - time[0]
 
    # Energía consumida por nodo = energía inicial - energía final
    consumed = energy.iloc[0] - energy.iloc[-1]
 
    # Nota: no se calcula potencia pico. La energía baja en escalones discretos
    # (por evento de TX/RX) y los timestamps pueden estar a milisegundos, así que
    # dE/dt da valores sin sentido físico.
 
    summary = pd.DataFrame({
        "Node_ID": energy.columns,
        "Initial_Energy": energy.iloc[0].to_numpy(),
        "Final_Energy": energy.iloc[-1].to_numpy(),
        "Consumed": consumed.to_numpy(),
        "Consumed_pct": consumed.to_numpy() / energy.iloc[0].to_numpy() * 100,
        "Avg_Power": consumed.to_numpy() / duration,   # unidad_energía / s
    }).sort_values("Consumed", ascending=False).reset_index(drop=True)
 
    print(f"Duración simulada: {duration:.2f} s | Nodos: {len(summary)}")
    print("=== CONSUMO ENERGÉTICO POR NODO (top 10) ===")
    print(summary.head(10).to_string(index=False))
    print("\n=== RED ===")
    print(f"Consumo total:  {summary['Consumed'].sum():.4f}")
    print(f"Consumo medio:  {summary['Consumed'].mean():.4f}")
    print(f"Nodos sin consumo: {(summary['Consumed'] == 0).sum()}")
    return summary
 
 
if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else "../results/wisen_simulation.csv"
    result = calculate_energy_metrics(path)
    result.to_csv("energy_summary.csv", index=False)
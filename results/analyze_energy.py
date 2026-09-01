import pandas as pd
import numpy as np

def calculate_energy_metrics(log_path):
    # Carga de traza de energía desde CupCarbon (ej. nodo_id, tiempo, estado, consumo_mW)
    # Ajusta las columnas según el formato exportado por tu simulación
    data = pd.read_csv(log_path, sep=r'\s+', names=['Timestamp', 'Node_ID', 'State', 'Energy_mW'])
    
    # Cálculo de energía total consumida en Joules (E = P * t)
    summary = data.groupby('Node_ID').agg(
        Total_Energy_J=('Energy_mW', lambda x: (x.sum() * 0.001)), # Conversión estimada
        Avg_Power_mW=('Energy_mW', 'mean'),
        Max_Power_Peak=('Energy_mW', 'max')
    ).reset_index()
    
    print("=== RESUMEN DE CONSUMO ENERGÉTICO POR NODO ===")
    print(summary.head(10))
    return summary

if __name__ == "__main__":
    # Ruta dirigida a los archivos en la carpeta results de CupCarbon
    calculate_energy_metrics("../results/energy_trace.log")

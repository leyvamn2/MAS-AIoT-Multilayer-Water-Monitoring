# ==========================================================
# PROYECTO TESIS: Agente Edge MAS-AIoT (CupCarbon SenScript)
# Monitoreo de Calidad del Agua - NOM-127-SSA1
# ==========================================================

# 1. Inicialización de Variables de Estado
set init 0
if ($init == 0)
  set init 1
  set my_id 0
  set ph_raw 0
  set ph 7.0
  set turb_raw 0
  set turb 2.0
  set cond 300
  set neighbor_vote 0
  set tiene_msg 0
  set estado_destino 0
  set flag_leer 0
  set flag_v20 0
  set flag_v10 0
  set flag_v0 0
  set msg_critical ALERT_CRITICAL
  set msg_anomaly ALERT_ANOMALY
  set msg_consensus 10
end

# 2. Transición a Bajo Consumo (CAD IDLE)
mark 0
print "CAD IDLE: Listening for channel activity (25 uA baseline)"
# Ajuste de tiempo CAD IDLE a 5000 ms (5 segundos)
delay 5000

# 3. Adquisición de Datos y Sensado Edge
atget id my_id
randb ph_raw 20 95
div ph $ph_raw 10.0
randb turb_raw 0 80
div turb $turb_raw 10.0
randb cond 100 1200

# Reset de banderas por ciclo
set estado_destino 0
set neighbor_vote 0
set tiene_msg 0
set flag_v20 0
set flag_v10 0
set flag_v0 0

# 4. Evaluación de Normativa (NOM-127-SSA1)
# Rango Seguro: pH [6.5 - 8.5]
set flag_leer 0
if ($ph >= 6.5)
  inc flag_leer 1
end
if ($ph <= 8.5)
  inc flag_leer 1
end
if ($flag_leer == 2)
  set estado_destino 1
end

# Rango Incertidumbre (Moderado): pH < 6.5 o Turbidez > 4.0 NTU
if ($ph < 6.5)
  set estado_destino 2
end
if ($turb > 4.0)
  set estado_destino 2
end

# Rango Crítico (Desviación Severa): pH < 3.0, pH > 10.5 o Turbidez > 7.0 NTU
if ($ph < 3.0)
  set estado_destino 3
end
if ($ph > 10.5)
  set estado_destino 3
end
if ($turb > 7.0)
  set estado_destino 3
end

# 5. Ejecución según Nivel de Riesgo

# ESTADO 1: Agua Segura
if ($estado_destino == 1)
  mark 1
  print "SAFE WATER: Radio in IDLE mode"
end

# ESTADO 3: Alerta Crítica (Transmisión Directa al Gateway)
if ($estado_destino == 3)
  mark 3
  print "CRITICAL ALERT: Severe deviation detected"
  send $msg_critical
  delay 2000
end

# ESTADO 2: Incertidumbre (Protocolo de Consenso P2P LoRa)
if ($estado_destino == 2)
  mark 2
  print "UNCERTAINTY DETECTED: Requesting peer consensus"
  send $msg_consensus
  # Ventana de espera para recepción de consenso ajustada a 5000 ms (5 segundos)
  delay 5000
  intrcv tiene_msg
end

# 6. Procesamiento del Voto del Vecino (Fusión de Datos)
set flag_leer 0
if ($estado_destino == 2)
  inc flag_leer 1
end
if ($tiene_msg > 0)
  inc flag_leer 1
end
if ($flag_leer == 2)
  read neighbor_vote
end

# Evaluación Voto 20: Confirmación Directa
if ($estado_destino == 2)
  inc flag_v20 1
end
if ($neighbor_vote == 20)
  inc flag_v20 1
end
if ($flag_v20 == 2)
  mark 3
  print "Peer confirmation received (Vote 20)"
  send $msg_anomaly
end

# Evaluación Voto 10: Fusión Conservadora
if ($estado_destino == 2)
  inc flag_v10 1
end
if ($neighbor_vote == 10)
  inc flag_v10 1
end
if ($flag_v10 == 2)
  mark 3
  print "Conservative Fusion (Vote 10)"
  send $msg_anomaly
end

# Evaluación Voto 0 / Sin Respuesta: Sin Correlación Espacial
if ($estado_destino == 2)
  inc flag_v0 1
end
if ($neighbor_vote == 0)
  inc flag_v0 1
end
if ($flag_v0 == 2)
  mark 4
  print "Network Timeout / Safe Neighbor: Descartando falso positivo local"
  # No se envía alerta global para mantener bajo el índice de falsos positivos
end

# 7. Tiempo de Espera para Cierre de Ciclo
delay 3000
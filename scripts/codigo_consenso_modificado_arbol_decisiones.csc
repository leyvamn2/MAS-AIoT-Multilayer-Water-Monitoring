// =====================================================================
// PROYECTO TESIS: MAS-AIoT Multicapa (Capa Edge)
// AUTOR: Agente Edge de Monitoreo de Calidad del Agua
// ARQUITECTURA: SenScript Estable (Basado en Goto / Sin 'loop')
// ESTÁNDAR: NOM-127-SSA1-2021 (México) & Consenso LoRa P2P
// =====================================================================

// --- 1. SAFE NODE MEMORY INITIALIZATION ---
set init 0

if ( $init == 0 )
    set init 1
    set my_id 0
    set p_rand 0
    set ph_raw 0
    set ph 7.2
    set turb_raw 0
    set turb 1.2
    set cond 350
    set neighbor_vote 0
    set tiene_msg 0
    set estado_destino 0
    set flag_leer 0
    set flag_v20 0
    set flag_v10 0
    set flag_v0 0
endif

label ESTADO_INICIO

// --- 2. IDLE CAD STATE (Low Power micro-sleep) ---
mark 0
delay 1500

// --- 3. STOCHASTIC SAMPLING & MULTI-PARAMETER ACQUISITION ---
mark 1
atget id my_id

// Reset variables de control del ciclo
set estado_destino 0
set neighbor_vote 0
set tiene_msg 0
set flag_leer 0
set flag_v20 0
set flag_v10 0
set flag_v0 0

// Generación estocástica del escenario de calidad de agua (1 a 100)
randb p_rand 1 100

// ESCENARIO 1: ANÓMALO (15% de probabilidad)
if ( $p_rand > 85 )
    // Valores contaminados o fuera de norma
    randb ph_raw 30 64
    div ph $ph_raw 10.0
    randb turb_raw 41 120
    div turb $turb_raw 10.0
    randb cond 1001 1800
endif

// ESCENARIO 2: NOMINAL (85% de probabilidad)
if ( $p_rand <= 85 )
    // Valores estables dentro de norma NOM-127-SSA1-2021
    randb ph_raw 68 78
    div ph $ph_raw 10.0
    randb turb_raw 8 25
    div turb $turb_raw 10.0
    randb cond 250 500
endif

// --- 4. LOCAL EDGE AI INFERENCE (Matriz NOM-127-SSA1-2021) ---

// Estado 1: Agua Segura (Evaluación Plana)
set flag_leer 0
if ($ph >= 6.5)
    inc flag_leer 1
end
if ($ph <= 8.5)
    inc flag_leer 1
end
if ($turb <= 4.0)
    inc flag_leer 1
end
if ($cond <= 1000)
    inc flag_leer 1
end
if ($flag_leer == 4)
    set estado_destino 1
end

// Estado 2: Zona de Incertidumbre (Dispara Consenso LoRa P2P)
if ($ph < 6.5)
    set estado_destino 2
end
if ($turb > 4.0)
    set estado_destino 2
end
if ($cond > 1000)
    set estado_destino 2
end

// Estado 3: Alerta Crítica Local / Fallo de Hardware Grave
if ($ph < 4.0)
    set estado_destino 3
end
if ($ph > 10.0)
    set estado_destino 3
end
if ($turb > 8.0)
    set estado_destino 3
end

// --- 5. MÁQUINA DE ESTADOS Y EJECUCIÓN ---

// EXEC 1: NOMINAL (Radio en IDLE para ahorro energético)
if ($estado_destino == 1)
    mark 1
    print "[EDGE S" $my_id "] AGUA SEGURA: Parámetros NOM-127 Correctos. Radio IDLE."
    goto FIN_CICLO
end

// EXEC 3: ALERTA CRÍTICA DIRECTA
if ($estado_destino == 3)
    mark 3
    print "[EDGE S" $my_id "] ALERTA CRÍTICA: Desviación severa. Transmitiendo a Fog..."
    send ALERT_CRITICAL 10
    delay 1000
    goto FIN_CICLO
end

// EXEC 2: PROTOCOLO DE CONSENSO DISTRIBUIDO LoRa P2P
if ($estado_destino == 2)
    mark 2
    print "[EDGE S" $my_id "] INCERTIDUMBRE: Solicitando consenso P2P a nodos vecinos..."
    // Solicitud de voto P2P (broadcast a vecinos)
    send 10 0

    // Ventana de escucha para la respuesta P2P
    delay 500
    intrcv tiene_msg
end

// --- 6. PROCESAMIENTO PLANO DE VOTACIÓN (FLATTENED VOTING) ---

// Extracción del mensaje recibido del canal RF
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

// VOTO 20: Confirmación de anomalía por un nodo vecino
if ($estado_destino == 2)
    inc flag_v20 1
end
if ($neighbor_vote == 20)
    inc flag_v20 1
end
if ($flag_v20 == 2)
    mark 3
    print "[CONSENSUS S" $my_id "] Confirmación vecina recibida: Anomalía Distribuida Validada."
    send ALERT_ANOMALY 10
    delay 500
end

// VOTO 10: El vecino reporta agua segura (Fusión Conservadora)
if ($estado_destino == 2)
    inc flag_v10 1
end
if ($neighbor_vote == 10)
    inc flag_v10 1
end
if ($flag_v10 == 2)
    mark 3
    print "[CONSENSUS S" $my_id "] Fusión Conservadora: Criterio de riesgo local prevalece."
    send ALERT_ANOMALY 10
    delay 500
end

// VOTO 0: Sin respuesta / Timeout de Red (Degradación Graciosa)
if ($estado_destino == 2)
    inc flag_v0 1
end
if ($neighbor_vote == 0)
    inc flag_v0 1
end
if ($flag_v0 == 2)
    mark 4
    print "[P2P FALLBACK S" $my_id "] Timeout de Red: Degradación graciosa a decisión local."
    send ALERT_ANOMALY 10
    delay 500
end

label FIN_CICLO
// --- 7. INTERVALO DE GUARDA ENTRE CICLOS DE MUESTREO ---
// Pausa segura que permite al hilo de Java (AWT) procesar eventos sin trabarse
delay 2000
goto ESTADO_INICIO
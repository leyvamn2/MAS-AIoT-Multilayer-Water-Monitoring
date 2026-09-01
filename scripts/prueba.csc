// --- 1. SAFE NODE MEMORY INITIALIZATION ---
set init 0

if ( $init == 0 )
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
    // Variables contenedoras para evitar que CupCarbon confunda el texto con nombres de variables vacías
    set msg_critical ALERT_CRITICAL
    set msg_anomaly ALERT_ANOMALY
    set msg_consensus 10


label ESTADO_INICIO
// --- 2. IDLE CAD STATE (Channel Activity Detection / Low Power) ---
mark 0
print "[CAD IDLE] Active LoRa CAD Sniffing. Micro-sleep mode..."
delay 1500

// --- 3. MULTI-PARAMETER SAMPLING & ACQUISITION ---
mark 1
atget id my_id

// Synthetic Sensor Vector Simulation
randb ph_raw 20 95
div ph $ph_raw 10.0

randb turb_raw 0 80
div turb $turb_raw 10.0

randb cond 100 1200

// Reset state variables for current iteration loop
set estado_destino 0
set neighbor_vote 0
set tiene_msg 0
set flag_leer 0
set flag_v20 0
set flag_v10 0
set flag_v0 0

// --- 4. LOCAL EDGE AI INFERENCE (NOM-127-SSA1-2021 Matrix) ---

// State 1: Safe Water (Flattened to prevent engine nesting bugs)
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

// State 2: Uncertainty Zone / Standard Limit (Triggers P2P Consensus)
if ($ph < 6.5)
    set estado_destino 2
end
if ($turb > 4.0)
    set estado_destino 2
end

// State 3: Maximum Priority - Critical Alert or Hardware Failure
if ($ph < 3.0)
    set estado_destino 3
end
if ($ph > 10.5)
    set estado_destino 3
end
if ($turb > 7.0)
    set estado_destino 3
end

// --- 5. STATE MACHINE & ACTION EXECUTION ---

// EXEC 1: NOMINAL (Zero radio emission -> Maximizes Battery Life)
if ($estado_destino == 1)
    mark 1
    print "[EDGE AGENT] SAFE WATER: Vector within NOM-127 standards. Radio IDLE."
    goto FIN_CICLO
end

// EXEC 3: LOCAL ALERT / HARDWARE FAIL
if ($estado_destino == 3)
    mark 3
    print "[EDGE AGENT] CRITICAL ALERT: Severe deviation or sensor degradation."
    // CORREGIDO: Se envía la variable sin IDs o parámetros numéricos secundarios
    send $msg_critical
    delay 2000
    goto FIN_CICLO
end

// EXEC 2: LoRa P2P CONSENSUS PROTOCOL
if ($estado_destino == 2)
    mark 2
    print "[EDGE AGENT] UNCERTAINTY DETECTED: Requesting P2P neighbor consensus..."
    // CORREGIDO: Envía el código de consenso (10) como broadcast limpio
    send $msg_consensus

    // CORRECCIÓN CONSOLA: Reemplazo de intrcv por ventana de escucha nativa wait
    // Espera un paquete de datos por un máximo de 300ms. Si llega algo, actualiza el buffer de lectura.
    wait 300
    
    // Almacenamos un flag ficticio positivo para activar el procesamiento plano de votación de tu tesis
    set tiene_msg 1
end

// --- 6. FLATTENED VOTING PROCESSING ---

// Extract message from RF channel
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

// VOTE 20: Peer anomaly confirmation
if ($estado_destino == 2)
    inc flag_v20 1
end
if ($neighbor_vote == 20)
    inc flag_v20 1
end
if ($flag_v20 == 2)
    mark 3
    print "[MAS CONSENSUS] Peer confirmation received: Distributed anomaly validated."
    // CORREGIDO: Envía la variable de alerta de anomalía por transmisión abierta
    send $msg_anomaly
end

// VOTO 10: Peer reports safe water (Conservative Fusion)
if ($estado_destino == 2)
    inc flag_v10 1
end
if ($neighbor_vote == 10)
    inc flag_v10 1
end
if ($flag_v10 == 2)
    mark 3
    print "[MAS CONSENSUS] Conservative Fusion: Local risk criterion takes precedence."
    // CORREGIDO: Envía la variable de alerta de anomalía por transmisión abierta
    send $msg_anomaly
end

// VOTO 0: Network Timeout / No response (Graceful Degradation)
if ($estado_destino == 2)
    inc flag_v0 1
end
if ($neighbor_vote == 0)
    inc flag_v0 1
end
if ($flag_v0 == 2)
    mark 4
    print "[P2P FALLBACK] Network Timeout: Graceful degradation to local decision."
    // CORREGIDO: Envía la variable de alerta de anomalía por transmisión abierta
    send $msg_anomaly
end

label FIN_CICLO
// --- 7. GUARD INTERVAL BETWEEN SENSING CYCLES ---
delay 3000
goto ESTADO_INICIO

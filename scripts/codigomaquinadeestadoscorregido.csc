# ==========================================================
# AGENTE EDGE MAS-AIoT (v3.1 - REAL EVENT-DRIVEN & TIMERS OPTIMIZED)
# Monitoreo de Calidad del Agua - Puntos de Consumo Final
# Optimización de latencia de consenso y eliminación de falsos aislamientos
# ==========================================================

# 1. INICIALIZACIÓN DE NODO Y PROTOCOLO
atget id my_id
set conf_threshold 90

set MSG_REQ 100      # Solicitud de validación P2P (Incertidumbre)
set MSG_ACK 101      # Voto de confirmación de vecino
set MSG_ANOMALY 200  # Transmisión de alerta a Capa Fog/Cloud

loop
    # 2. ADQUISICIÓN Y EVALUACIÓN DE INFERENCIA
    randb clase_val 1 5
    randb prob_evento 1 100

    # 95% operabilidad habitual local, 5% evento atípico
    if ($prob_evento <= 95)
        randb conf_score 90 100
    end
    if ($prob_evento > 95)
        randb conf_score 50 89
    end

    # 3. MÁQUINA DE ESTADOS REACTIVA

    # CASO A: Monitoreo Normal y Escucha Event-Driven
    if ($conf_score >= $conf_threshold)
        print "NODO_" $my_id "_MONITOREO_NORMAL"
        
        # Escucha reactiva: despierte inmediato al ingresar un paquete al búfer
        wait 30000
        read msg_in
        
        if ($msg_in == "100")
            randb jitter_ack 10 50
            delay $jitter_ack
            send $MSG_ACK
            print "NODO_" $my_id "_ACK_ENVIADO_A_VECINO"
        end
    end

    # CASO B: Anomalía / Incertidumbre (Validación P2P 1-Hop)
    if ($conf_score < $conf_threshold)
        print "NODO_" $my_id "_SOLICITA_VALIDACION_VECINO"
        
        # Purga de búfer previa a la solicitud
        read dummy
        
        randb jitter 50 150
        delay $jitter
        send $MSG_REQ
        
        # Ventana de espera adaptada a la latencia de respuesta del vecino
        wait 300
        read neighbor_vote
        
        set es_valido 0
        if ($neighbor_vote == "101")
            set es_valido 1
        end

        if ($es_valido == 1)
            print "NODO_" $my_id "_ALERTA_CONFIRMADA_POR_VECINO"
        else
            print "NODO_" $my_id "_ALERTA_RECHAZADA_AISLAMIENTO"
        end
        
        # Limpieza post-procesamiento y reposo reactivo corto
        read dummy
        wait 1000
    end
jmp loop
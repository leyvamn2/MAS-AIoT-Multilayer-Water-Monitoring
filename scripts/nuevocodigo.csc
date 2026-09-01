# ==========================================================
# AGENTE EDGE MAS-AIoT (v3.0 - BAJO CONSUMO Y EVENT-DRIVEN)
# Monitoreo de Calidad del Agua - Puntos de Consumo Final
# Reducción de overhead de red y optimización de ciclo de trabajo
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

    # Operabilidad habitual: 95% resolución local en estado normal
    # 5% de probabilidad de eventos atípicos que requieran consenso
    if ($prob_evento <= 95)
        randb conf_score 90 100
    end
    if ($prob_evento > 95)
        randb conf_score 50 89
    end

    # 3. MÁQUINA DE ESTADOS Y GESTIÓN DE ENERGÍA/RED

    # CASO A: Resolución Local (Estado Pasivo de Red)
    if ($conf_score >= $conf_threshold)
        print "NODO_" $my_id "_MONITOREO_NORMAL_CLASE_" $clase_val
        
        # Escucha pasiva durante la ventana de muestreo (Silencio de Radio)
        wait 5000
        read msg_in
        
        # Respuesta exclusiva ante solicitud explícita de apoyo vecino
        if ($msg_in == "100")
            randb jitter_ack 20 100
            delay $jitter_ack
            send $MSG_ACK
            print "NODO_" $my_id "_ACK_VALIDACION_ENVIADO"
        end
    end

    # CASO B: Anomalía / Incertidumbre (Excepción P2P)
    if ($conf_score < $conf_threshold)
        print "NODO_" $my_id "_INCERTIDUMBRE_SOLICITA_CONSENSO"
        
        # Jitter aleatorio para evitar colisiones en la subcapa MAC
        randb jitter 100 400
        delay $jitter
        
        # Emisión de solicitud P2P
        send $MSG_REQ
        
        # Ventana acotada de recepción de confirmación
        wait 1500
        read neighbor_vote
        
        set es_valido 0
        if ($neighbor_vote == "101")
            set es_valido 1
        end

        # Evaluación del Consenso y Notificación Jerárquica
        if ($es_valido == 1)
            print "NODO_" $my_id "_ALERTA_VALIDADA_HACIA_FOG"
            send $MSG_ANOMALY
        end
        if ($es_valido == 0)
            print "NODO_" $my_id "_ALERTA_RECHAZADA_AISLAMIENTO"
            # Supresión de MSG_ANOMALY para no inundar el canal sin respaldo
        end

        # Reposo posconsenso para amortiguar ráfagas de tráfico
        delay 8000
    end

    # Período de latencia entre ciclos de muestreo
    delay 4000
jmp loop
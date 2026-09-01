# ==========================================================
# AGENTE EDGE MAS-AIoT - CONSENSO P2P (CORREGIDO)
# ==========================================================

# --- INICIALIZACIÓN (SE EJECUTA UNA SOLA VEZ) ---
set my_id 0
set ph_val 0
set ph 7.0
set turb_val 0
set turb 2.0

set estado_destino 1
set conf_score 0       
set conf_threshold 90 
set neighbor_vote 0

set msg_consensus 100
set msg_anomaly 200

# Asignar el ID real del sensor en CupCarbon
delay 100
atget id my_id

# --- BUCLE PRINCIPAL DE EJECUCIÓN ---
loop:

# 1. LECTURA SENSORIAL Y NORMALIZACIÓN
randb ph_val 50 85
div ph $ph_val 10.0
randb turb_val 10 60
div turb $turb_val 10.0

# 2. EVALUACIÓN NOM-127-SSA1
set estado_destino 1

if ($ph < 6.5)
    set estado_destino 2
end
if ($ph > 8.5)
    set estado_destino 2
end
if ($turb > 4.0)
    set estado_destino 2
end

# 3. GESTIÓN DEL ACUMULADOR DE CONFIANZA
if ($estado_destino == 2)
    # Corrección: Uso explícito de 'plus' para incrementos > 1
    plus conf_score $conf_score 30
    if ($conf_score > 100)
        set conf_score 100
    end
end

if ($estado_destino == 1)
    plus conf_score $conf_score -30
    if ($conf_score < 0)
        set conf_score 0
    end
end

# 4. MÁQUINA DE ESTADOS Y TRANSMISIÓN P2P

# CASO A: Filtrado Edge (Agua SEGURA o RUIDO)
if ($conf_score < $conf_threshold)
    print "[NODO " $my_id "] [ESTADO 1] Nominal/Ruido. Confianza: " $conf_score "% - Radio TX INACTIVA"
    delay 5000
end

# CASO B: Anomalía Sostenida Validada EN EDGE
if ($conf_score >= $conf_threshold)
    print "[NODO " $my_id "] [ESTADO 2] ANOMALÍA EN EDGE (" $conf_score "%). Solicitando Consenso..."
    
    # Notificar a vecinos para validación cruzada
    send $msg_consensus

    delay 1000
    read neighbor_vote

    # Si los vecinos confirman (reciben un mensaje > 0)
    if ($neighbor_vote > 0)
        print "[NODO " $my_id "] [CONSENSO MAS] Anomalía Validada por Red P2P. Alerta Enviada."
        send $msg_anomaly
    end

    # Si no hay respuesta del entorno (Aislamiento)
    if ($neighbor_vote == 0)
        print "[NODO " $my_id "] [AISLAMIENTO] Sin respuesta P2P. Evento Local Confirmado."
        send $msg_anomaly
    end
    
    delay 4000
end

jmp loop
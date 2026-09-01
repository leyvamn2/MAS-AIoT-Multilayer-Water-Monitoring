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

label ESTADO_INICIO
mark 0
print "CAD IDLE Active LoRa CAD Sniffing"
delay 1500
mark 1
atget id my_id
randb ph_raw 20 95
div ph $ph_raw 10.0
randb turb_raw 0 80
div turb $turb_raw 10.0
randb cond 100 1200
set estado_destino 0
set neighbor_vote 0
set tiene_msg 0
set flag_leer 0
set flag_v20 0
set flag_v10 0
set flag_v0 0

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

if ($ph < 6.5)
set estado_destino 2
end
if ($turb > 4.0)
set estado_destino 2
end
if ($ph < 3.0)
set estado_destino 3
end
if ($ph > 10.5)
set estado_destino 3
end
if ($turb > 7.0)
set estado_destino 3
end

if ($estado_destino == 1)
mark 1
print "SAFE WATER Radio IDLE"
goto FIN_CICLO
end

if ($estado_destino == 3)
mark 3
print "CRITICAL ALERT Severe deviation"
send $msg_critical
delay 2000
goto FIN_CICLO
end

if ($estado_destino == 2)
mark 2
print "UNCERTAINTY DETECTED Requesting consensus"
send $msg_consensus
delay 300
intrcv tiene_msg
end

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

if ($estado_destino == 2)
inc flag_v20 1
end
if ($neighbor_vote == 20)
inc flag_v20 1
end
if ($flag_v20 == 2)
mark 3
print "Peer confirmation received"
send $msg_anomaly
end

if ($estado_destino == 2)
inc flag_v10 1
end
if ($neighbor_vote == 10)
inc flag_v10 1
end
if ($flag_v10 == 2)
mark 3
print "Conservative Fusion"
send $msg_anomaly
end

if ($estado_destino == 2)
inc flag_v0 1
end
if ($neighbor_vote == 0)
inc flag_v0 1
end
if ($flag_v0 == 2)
mark 4
print "Network Timeout"
send $msg_anomaly
end

label FIN_CICLO
delay 3000
goto ESTADO_INICIO
set d 0
set d_resp 0
set d_msg 0
set msg 0
set resp 0
set tiene_msg 0
set tiene_resp 0
set prob 0
set ejecuto_consenso 0
set es_iniciador 0
set es_validador 0
set bat 0
set mi_id 0

atget id mi_id
atget battery bat
print "Nodo levantado"

print "ESTADO: SENSING"
randb prob 1 100

if ($prob>90)
set es_iniciador 1
end

if ($es_iniciador==0)
set es_validador 1
end

if ($es_validador==1)
print "ESTADO: IDLE"
intrcv tiene_msg
end

if ($tiene_msg>0)
print "ESTADO: RECEPCION_RADIO"
read msg
set d msg
set tiene_msg 0
end

if ($d==10)
mark 2
atget battery bat
print "Evento: VOTO_ENVIADO"
delay 150
send 20
set d 0
end

if ($es_iniciador==1)
print "ESTADO: INICIADOR"
mark 1
set ejecuto_consenso 0
atget battery bat
print "Evento: REQ_CONSENSUS"
send 10
delay 10000
intrcv tiene_resp
end

if ($tiene_resp>0)
read resp
set d_resp resp
end

if ($d_resp==20)
set ejecuto_consenso 1
mark 3
atget battery bat
print "Evento: CONSENSO_OK"
set d_resp 0
end

// Corrección de la Línea 85: Evaluación unificada de la decisión local por timeout
if ($ejecuto_consenso==0)
mark 4
atget battery bat
print "Evento: DECISION_LOCAL_TIMEOUT"
end

set es_iniciador 0
set es_validador 0
delay 3000

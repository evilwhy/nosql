#!/bin/bash
# гашу текущий primary и засекаю сколько идут выборы
# bash lab10/failover.sh       - штатная остановка (SIGTERM)
# bash lab10/failover.sh KILL  - как будто процесс упал (SIGKILL)

C=nosql-mongo-rs-1
SIG=${1:-TERM}
m() { docker exec $C mongosh --quiet --port "$@"; }

primary=$(m 27102 --eval 'rs.hello().primary' 2>/dev/null | tr -d '\r')
[ -z "$primary" ] && primary=$(m 27103 --eval 'rs.hello().primary' | tr -d '\r')
port=${primary##*:}
# с какого узла смотреть, любой кроме primary
if [ "$port" = "27102" ]; then watch=27103; else watch=27102; fi
echo "primary сейчас $primary, смотрю с $watch, сигнал $SIG"

# t0 = момент остановки
t0=$(docker exec $C date +%s.%N)
docker exec $C pkill -$SIG -f "port $port"
echo "t0 = $(docker exec $C date -d @$t0 +%T.%3N) остановил mongod на $port"

# параллельно пробую писать через replicaSet uri, таймаут 1 сек
docker exec $C bash -c "for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
  r=\$(mongosh --quiet 'mongodb://127.0.0.1:27101,127.0.0.1:27102,127.0.0.1:27103/shop_lab10?replicaSet=rsLab10&serverSelectionTimeoutMS=1000' --eval 'db.ping.insertOne({at: new Date()}).acknowledged' 2>&1 | tail -1 | cut -c1-80)
  echo \"\$(date +%T.%3N)  write: \$r\"; sleep 1; done" &

# опрашиваю статус пока не появится новый primary
while true; do
  now=$(docker exec $C date +%s.%N)
  state=$(m $watch --eval 'rs.status().members.map(x => x.name.split(":")[1] + " " + x.stateStr).join(" | ")' 2>/dev/null | tr -d '\r')
  echo "$(docker exec $C date -d @$now +%T.%3N)  $state"
  newp=$(m $watch --eval 'rs.hello().primary' 2>/dev/null | tr -d '\r')
  if [ -n "$newp" ] && [ "$newp" != "$primary" ]; then
    t1=$now
    break
  fi
  sleep 1
done
echo "t1 = $(docker exec $C date -d @$t1 +%T.%3N) новый primary $newp"
echo "failover: $(echo "$t1 - $t0" | bc) сек"
wait

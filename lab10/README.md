# Лабораторная работа №10

Дисциплина: Проектирование и применение NoSQL-технологий

Тема: Настройка репликации и моделирование отказа стенда

Вариант 3 - Интернет-магазин, коллекция orders (заказы). Сценарий А, реальный Replica Set из трех узлов.

## Цель

Поднять локальный MongoDB Replica Set из трех узлов, записать данные с w: majority, остановить primary и посмотреть как проходят выборы, вернуть узел, сделать backup и восстановить его в отдельную базу, оценить RTO и RPO.

## Стенд

MacBook Air, Apple M3, 8 GB, macOS 27.0.1. Docker 29.8.2 (OrbStack). MongoDB 8.0.4, mongosh 2.3.8, mongodump/mongorestore из того же образа.

Локально mongod не ставил, все три процесса крутятся в одном контейнере mongo-rs (добавил в docker-compose.yml). Порты 27101-27103, bind_ip 127.0.0.1, наружу ничего не открыто, подключаюсь через docker exec. Каталоги данных /data/rs1, /data/rs2, /data/rs3 на volume mongo_rs_data.

```
mongod --replSet rsLab10 --port 27101 --dbpath /data/rs1 --bind_ip 127.0.0.1 --fork --logpath /data/rs1.log
mongod --replSet rsLab10 --port 27102 --dbpath /data/rs2 --bind_ip 127.0.0.1 --fork --logpath /data/rs2.log
mongod --replSet rsLab10 --port 27103 --dbpath /data/rs3 --bind_ip 127.0.0.1 --fork --logpath /data/rs3.log
```
```
docker compose up -d mongo-rs
docker exec nosql-mongo-rs-1 ps -o pid,etime,args -C mongod
```
```
    PID     ELAPSED COMMAND
     12       00:04 mongod --replSet rsLab10 --port 27101 --dbpath /data/rs1 ...
     79       00:04 mongod --replSet rsLab10 --port 27102 --dbpath /data/rs2 ...
    146       00:03 mongod --replSet rsLab10 --port 27103 --dbpath /data/rs3 ...
```

Файлы:
- `commands.txt` - все команды по порядку
- `orders.js` - 22 заказа, вставка с w: majority
- `failover.sh` - остановка primary и замер t0/t1
- `backup_lab10/` - дамп mongodump
- `shop_lab10.orders.json` - экспорт коллекции в конце

## Схема

```
        rsLab10
  +-------------------+
  | 127.0.0.1:27101   |  PRIMARY  (до отказа)
  | 127.0.0.1:27102   |  SECONDARY
  | 127.0.0.1:27103   |  SECONDARY
  +-------------------+
  heartbeat 2 с, electionTimeout 10 с, majority = 2 из 3
```

## Инициализация

Чтобы не писать каждый раз длинную команду, m ниже это `docker exec nosql-mongo-rs-1 mongosh --quiet --port`.
```
m 27101 --eval 'rs.initiate({_id:"rsLab10",members:[{_id:0,host:"127.0.0.1:27101"},{_id:1,host:"127.0.0.1:27102"},{_id:2,host:"127.0.0.1:27103"}]})'
```
```
{ ok: 1, ... }
```
Через ~10 секунд:
```
m 27101 --eval 'rs.status().members.forEach(m => print(m._id, m.name, m.stateStr, m.health))'
```
```
0 127.0.0.1:27101 PRIMARY 1
1 127.0.0.1:27102 SECONDARY 1
2 127.0.0.1:27103 SECONDARY 1
```
Из rs.status(): `heartbeatIntervalMillis: 2000`, `majorityVoteCount: 2`, `electionTimeoutMillis: 10000`, `lastElectionReason: 'electionTimeout'`, term 1.

## Данные

22 заказа магазина (orderId 1-22, customerId, city, status, total, items, createdAt), уникальный индекс по orderId. Вставка одним insertMany с `writeConcern: { w: "majority", wtimeout: 5000 }`, скрипт в orders.js.
```
docker exec -i nosql-mongo-rs-1 mongosh --quiet --port 27101 < lab10/orders.js
```
```
{ acknowledged: true, insertedIds: { '0': ObjectId('6aee54eaa0d53ef189a00aa1'), ... '21': ObjectId('6aee54eaa0d53ef189a00ab6') } }
22
[
  { orderId: 1, customerId: 1001, status: 'delivered', total: 289990 },
  { orderId: 2, customerId: 1002, status: 'delivered', total: 149990 },
  ...
  { orderId: 22, customerId: 1005, status: 'new', total: 149990 }
]
```
Контрольные значения, по ним сверяю после каждого шага:
```
db.orders.aggregate([{ $group: { _id: null, count: { $sum: 1 }, maxOrderId: { $max: "$orderId" }, sumTotal: { $sum: "$total" } } }])
```
```
[ { _id: null, count: 22, maxOrderId: 22, sumTotal: 1965720 } ]
```

На secondary данные уже есть, лаг нулевой:
```
m 27102 --eval 'db.getMongo().setReadPref("secondary"); db.getSiblingDB("shop_lab10").orders.countDocuments()'
m 27101 --eval 'rs.printSecondaryReplicationInfo()'
```
```
22
source: 127.0.0.1:27102  replLag: '0 secs (0 hrs) behind the primary '
source: 127.0.0.1:27103  replLag: '0 secs (0 hrs) behind the primary '
```

## Отказ 1. Штатная остановка primary

failover.sh находит primary, шлет его процессу SIGTERM (как Ctrl+C в терминале), засекает t0 и опрашивает rs.status() с другого узла, пока не появится новый primary (t1).
```
bash lab10/failover.sh
```
```
primary сейчас 127.0.0.1:27101, смотрю с 27102
t0 = 22:30:31.295 остановил mongod на 27101
22:30:31.409  27101 (not reachable/healthy) | 27102 PRIMARY | 27103 SECONDARY
t1 = 22:30:31.409 новый primary 127.0.0.1:27102
failover: .114672758 сек
```
0.11 секунды. Ожидал ~10 секунд по electionTimeout, но при штатном завершении primary сам отдает роль: в логе 27102 выборы начались по запросу, а не по таймауту.
```
{"t":"2026-11-06T22:30:31.338","c":"ELECTION","msg":"Starting an election due to step up request"}
{"t":"2026-11-06T22:30:31.343","c":"ELECTION","msg":"Election succeeded, assuming primary role","attr":{"term":2}}
```
Сам процесс 27101 завершился только в 22:30:46, то есть еще 15 секунд он закрывался, но primary уже не был.

Данные на новом primary, тот же контрольный запрос:
```
m 27102 --eval 'db.getSiblingDB("shop_lab10").orders.aggregate([{ $group: { _id: null, count: { $sum: 1 }, maxOrderId: { $max: "$orderId" }, sumTotal: { $sum: "$total" } } }])'
```
```
[ { _id: null, count: 22, maxOrderId: 22, sumTotal: 1965720 } ]
```
Запись на двух узлах из трех проходит, большинство есть:
```
db.orders.insertMany([{ orderId: 23, ... }, { orderId: 24, ... }], { writeConcern: { w: "majority", wtimeout: 5000 } })
```
```
true
24
```

## Возврат узла

```
docker exec nosql-mongo-rs-1 mongod --replSet rsLab10 --port 27101 --dbpath /data/rs1 --bind_ip 127.0.0.1 --fork --logpath /data/rs1.log
```
Через 6 секунд:
```
127.0.0.1:27101 SECONDARY 1
127.0.0.1:27102 PRIMARY 1
127.0.0.1:27103 SECONDARY 1
```
Вернувшийся узел стал SECONDARY, primary не отобрал. Заказы 23 и 24, записанные пока его не было, подтянул из oplog:
```
m 27101 --eval 'db.getSiblingDB("shop_lab10").orders.countDocuments()'
m 27101 --eval 'db.getSiblingDB("shop_lab10").orders.find({orderId: {$gte: 23}}, {_id:0, orderId:1, status:1, total:1})'
```
```
24
[ { orderId: 23, status: 'new', total: 54990 }, { orderId: 24, status: 'new', total: 9990 } ]
```
replLag у обоих secondary 0 секунд.

## Отказ 2. Primary убит (SIGKILL)

Второй прогон, чтобы увидеть выборы по таймауту. Скрипт шлет SIGKILL, параллельно раз в секунду пробует вставить документ через URI с replicaSet и serverSelectionTimeoutMS=1000.
```
bash lab10/failover.sh KILL
```
```
primary сейчас 127.0.0.1:27102, смотрю с 27103, сигнал KILL
t0 = 22:31:37.415 остановил mongod на 27102
22:31:37.562  27101 SECONDARY | 27102 (not reachable/healthy) | 27103 SECONDARY
22:31:38.715  write: MongoServerSelectionError: connect ECONNREFUSED 127.0.0.1:27102
22:31:39.098  27101 SECONDARY | 27102 (not reachable/healthy) | 27103 SECONDARY
22:31:40.851  write: MongoServerSelectionError: connect ECONNREFUSED 127.0.0.1:27102
22:31:40.628  27101 SECONDARY | 27102 (not reachable/healthy) | 27103 SECONDARY
22:31:42.171  27101 SECONDARY | 27102 (not reachable/healthy) | 27103 SECONDARY
22:31:43.021  write: MongoServerSelectionError: connect ECONNREFUSED 127.0.0.1:27102
22:31:43.748  27101 SECONDARY | 27102 (not reachable/healthy) | 27103 SECONDARY
22:31:45.149  write: MongoServerSelectionError: connect ECONNREFUSED 127.0.0.1:27102
22:31:45.306  27101 SECONDARY | 27102 (not reachable/healthy) | 27103 SECONDARY
22:31:46.908  write: true
22:31:46.840  27101 SECONDARY | 27102 (not reachable/healthy) | 27103 PRIMARY
t1 = 22:31:46.840 новый primary 127.0.0.1:27103
failover: 9.425482536 сек
22:31:48.109  write: true
```
9.4 секунды, около electionTimeout. Все это время primary нет, записи падают с ошибкой, чтение с secondary работает. Лог 27103:
```
{"t":"2026-11-06T22:31:46.451","c":"ELECTION","msg":"Starting an election, since we've seen no PRIMARY in election timeout period"}
{"t":"2026-11-06T22:31:46.458","c":"ELECTION","msg":"Election succeeded, assuming primary role","attr":{"term":3}}
```
Возврат 27102 после kill:
```
{"s":"W","c":"STORAGE","msg":"Detected unclean shutdown - Lock file is not empty"}
{"s":"W","c":"STORAGE","msg":"Recovering data from the last clean checkpoint."}
```
```
127.0.0.1:27101 SECONDARY 1
127.0.0.1:27102 SECONDARY 1
127.0.0.1:27103 PRIMARY 1
```
Пробные документы из коллекции ping удалил, контроль на всех трех узлах одинаковый:
```
27101: { count: 24, maxOrderId: 24, sumTotal: 2030700 }
27102: { count: 24, maxOrderId: 24, sumTotal: 2030700 }
27103: { count: 24, maxOrderId: 24, sumTotal: 2030700 }
```

## Потеря большинства

Остановил 27101 и 27102, остался один 27103. Через ~10 секунд после того как он перестал видеть остальных:
```
27101 (not reachable/healthy) | 27102 (not reachable/healthy) | 27103 SECONDARY
```
```
{"c":"REPL","msg":"Can't see a majority of the set, relinquishing primary"}
{"c":"REPL","msg":"Stepping down from primary in response to heartbeat"}
```
Чтение с него работает (24 документа), запись нет:
```
m 27103 --eval 'db.getSiblingDB("shop_lab10").orders.insertOne({orderId: 100, ...})'
```
```
MongoServerError: not primary
```
Один узел не может сам себя выбрать primary, кворум 2 из 3. После запуска 27101 и 27102 набор собрался обратно, primary остался 27103.

## Backup и restore

Дамп через URI со всеми тремя адресами, параллельных записей в этот момент нет:
```
mongodump --uri="mongodb://127.0.0.1:27101,127.0.0.1:27102,127.0.0.1:27103/?replicaSet=rsLab10" --db=shop_lab10 --out=/data/backup_lab10
```
```
writing shop_lab10.orders to /data/backup_lab10/shop_lab10/orders.bson
done dumping shop_lab10.orders (24 documents)
```
orders.bson 4511 байт, orders.metadata.json 268 байт (там индекс orderId_1).

Restore в отдельную базу shop_restore10. Команда из методички с путем до подпапки базы не сработала:
```
mongorestore ... --nsFrom="shop_lab10.*" --nsTo="shop_restore10.*" /data/backup_lab10/shop_lab10
```
```
don't know what to do with file "/data/backup_lab10/shop_lab10/orders.bson", skipping...
0 document(s) restored successfully.
```
С --nsFrom/--nsTo надо давать папку дампа целиком:
```
mongorestore --uri="mongodb://127.0.0.1:27101,127.0.0.1:27102,127.0.0.1:27103/?replicaSet=rsLab10" --nsFrom="shop_lab10.*" --nsTo="shop_restore10.*" /data/backup_lab10
```
```
restoring shop_restore10.orders from /data/backup_lab10/shop_lab10/orders.bson
finished restoring shop_restore10.orders (24 documents, 0 failures)
restoring indexes for collection shop_restore10.orders from metadata
24 document(s) restored successfully. 0 document(s) failed to restore.
```
Сравнение:
```
show dbs
```
```
shop_lab10      108.00 KiB
shop_restore10   28.00 KiB
```
Контрольный запрос и индексы в восстановленной базе:
```
db.getSiblingDB("shop_restore10").orders.aggregate([{ $group: { _id: null, count: { $sum: 1 }, maxOrderId: { $max: "$orderId" }, sumTotal: { $sum: "$total" } } }])
db.getSiblingDB("shop_restore10").orders.getIndexes().map(i => i.name)
```
```
{ _id: null, count: 24, maxOrderId: 24, sumTotal: 2030700 }
[ '_id_', 'orderId_1' ]
```
Сравнил все документы целиком (отсортировал по orderId и сравнил JSON): `одинаковые документы: true`. Исходная база shop_lab10 не тронута, --drop не использовал.

## Протокол

| Проверка | Что зафиксировал | Результат |
|---|---|---|
| Состояние до отказа | 27101 PRIMARY, 27102 и 27103 SECONDARY | 1 primary, 2 secondary |
| Контрольная запись | 22 документа, maxOrderId 22, sumTotal 1965720, w: majority | есть на всех трех узлах, lag 0 |
| Остановка primary (SIGTERM) | t0 = 22:30:31.295 | 27101 недоступен |
| Новый primary | t1 = 22:30:31.409, 27102 | 0.11 с, выборы по step up request |
| Остановка primary (SIGKILL) | t0 = 22:31:37.415 | 27102 недоступен, записи падают |
| Новый primary | t1 = 22:31:46.840, 27103 | 9.4 с, выборы по electionTimeout |
| Возврат узла | оба раза SECONDARY через ~1 с, lag 0 | узел присоединяется, primary не меняется |
| Потеря большинства | один узел -> SECONDARY, not primary на запись | чтение есть, записи нет |
| Restore | shop_restore10: 24 документа, sumTotal 2030700, индекс на месте | совпадает с контролем |

## RPO и RTO

Наблюдаемое время переключения: 0.11 с при штатной остановке и 9.4 с при падении процесса. Для оценки беру второе, при настоящей аварии процесс никто штатно не останавливает. Первая успешная запись после отказа прошла в 22:31:46.908, это 9.5 с от t0.

RPO: до отказа maxOrderId 22 и сумма 1965720, после отказа на новом primary то же самое. После второго отказа 24 и 2030700 на всех узлах. Потерь нет, наблюдаемый RPO = 0. Это для записей с w: majority, они подтверждаются только когда попали на два узла из трех. С w: 1 запись могла бы потеряться, если primary упал раньше чем она ушла на secondary, это я не проверял.

Целевые значения для магазина (мои допущения): RPO = 0 для заказов, потерять оплаченный заказ нельзя, поэтому заказы пишутся только с w: majority. RTO = 30 с, выборы занимают около 10 с, остальное запас на переподключение приложения. Для корзины или истории просмотров хватит w: 1, потерять их не страшно.

Ограничения эксперимента: три процесса на одной машине в одном контейнере, сеть без задержек, всего 24 документа, нагрузки нет. В проде узлы на разных серверах, сеть между ними может рваться, данных намного больше. Поэтому цифры со стенда показывают только как работает переключение, в прод их переносить нельзя.

## Контрольные вопросы

1. Репликация держит живые копии данных на других узлах и спасает от отказа узла. Backup это снимок на момент времени, спасает от ошибочного удаления и порчи данных, которые по репликации разъедутся на все узлы
2. Чтобы не было двух primary одновременно. Побеждает тот, за кого проголосовало большинство, а большинство в наборе может быть только одно
3. Primary принимает все записи и пишет их в oplog, secondary читают oplog и повторяют
4. Primary сам уходит в SECONDARY (видел в логе Can't see a majority), новый выбрать некому. Набор только на чтение, пока не вернется кворум
5. w: majority гарантирует что запись на двух узлах из трех, но если ее удалить или испортить, это тоже реплицируется на все узлы. Копию на вчера репликация не вернет
6. Засечь время остановки primary t0 и время появления нового primary t1, разница и есть failover. Либо по логам: Starting an election и Election succeeded
7. RPO сколько данных по времени можно потерять, RTO за сколько надо восстановить работу. Наблюдаемые значения сравниваются с целевыми
8. Чтобы не затереть рабочую базу, если дамп битый или старый. В отдельной базе можно сравнить и только потом решать что делать
9. На время выборов записи падают (у меня 9 секунд), записи с w: 1, не успевшие на secondary, откатятся, приложению надо уметь переподключаться и повторять запросы
10. Один хост, loopback, нет задержек и разделений сети, нет нагрузки, нет аутентификации и TLS, маленький объем данных. В проде все это есть, и цифры будут другие

## Вывод

В этой лабе я поднял Replica Set rsLab10 из трех mongod на портах 27101-27103 в Docker, записал 22 заказа с w: majority и убедился что они есть на всех узлах с нулевым лагом. Штатная остановка primary дала переключение за 0.11 с, потому что уходящий primary сам передает роль, а убийство процесса через SIGKILL дало 9.4 с по electionTimeout, и все это время записи падали, а чтение с secondary работало. Вернувшийся узел оба раза становился SECONDARY и догонял данные по oplog, при потере двух узлов из трех оставшийся сам ушел в SECONDARY и записи перестали приниматься. Контрольные значения (24 документа, сумма 2030700) совпали до и после отказов, наблюдаемый RPO = 0 для записей с majority. Backup через mongodump восстановился в отдельную базу shop_restore10 один в один вместе с индексом, при этом команда restore из методички потребовала указать папку дампа целиком. Репликация дает доступность при отказе узла, backup дает возврат к снимку при порче данных, одно другое не заменяет, а цифры со стенда на одной машине в прод переносить нельзя.

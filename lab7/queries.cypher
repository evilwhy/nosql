// лаба 7, вариант 3 - интернет магазин
// запускал так: docker exec -i nosql-neo4j-1 cypher-shell -u neo4j -p Lab7StrongPass123 --format verbose --fail-at-end -f /dev/stdin < lab7/queries.cypher

// проверка
RETURN 'Neo4j works' AS status;

// constraints, чтобы merge не плодил дубли
CREATE CONSTRAINT customer_id IF NOT EXISTS FOR (c:Customer) REQUIRE c.customerId IS UNIQUE;
CREATE CONSTRAINT product_sku IF NOT EXISTS FOR (p:Product) REQUIRE p.sku IS UNIQUE;
CREATE CONSTRAINT category_name IF NOT EXISTS FOR (c:Category) REQUIRE c.name IS UNIQUE;
SHOW CONSTRAINTS YIELD name, type, labelsOrTypes, properties;

// узлы
MERGE (:Customer {customerId: 1001, name: 'Айдар С.', city: 'Алматы'});
MERGE (:Customer {customerId: 1002, name: 'Дана Н.', city: 'Астана'});
MERGE (:Customer {customerId: 1003, name: 'Ерлан Б.', city: 'Алматы'});
MERGE (:Customer {customerId: 1004, name: 'Алия К.', city: 'Шымкент'});
MERGE (:Customer {customerId: 1005, name: 'Мадина Т.', city: 'Алматы'});

// категории
MERGE (:Category {name: 'Электроника'});
MERGE (:Category {name: 'Ноутбуки'});
MERGE (:Category {name: 'Аудио'});
MERGE (:Category {name: 'Аксессуары'});
MERGE (:Category {name: 'Книги'});
MERGE (:Category {name: 'Программирование'});

// товары, цена в тг
MERGE (p:Product {sku: 'P-001'}) SET p.title = 'Ноутбук IdeaPad 3 15"', p.price = 289990;
MERGE (p:Product {sku: 'P-002'}) SET p.title = 'Наушники WH-1000XM5', p.price = 149990;
MERGE (p:Product {sku: 'P-003'}) SET p.title = 'Клавиатура MX Keys', p.price = 54990;
MERGE (p:Product {sku: 'P-004'}) SET p.title = 'Мышь MX Master 3S', p.price = 44990;
MERGE (p:Product {sku: 'P-005'}) SET p.title = 'Чехол для ноутбука 15"', p.price = 7990;
MERGE (p:Product {sku: 'P-006'}) SET p.title = 'Книга «Чистый код»', p.price = 12990;
MERGE (p:Product {sku: 'P-007'}) SET p.title = 'Книга «Грокаем алгоритмы»', p.price = 9990;
MERGE (p:Product {sku: 'P-008'}) SET p.title = 'Колонка Flip 6', p.price = 59990;

// связи
// подкатегория -> родитель
MATCH (a:Category {name: 'Ноутбуки'}), (b:Category {name: 'Электроника'}) MERGE (a)-[:PART_OF]->(b);
MATCH (a:Category {name: 'Аудио'}), (b:Category {name: 'Электроника'}) MERGE (a)-[:PART_OF]->(b);
MATCH (a:Category {name: 'Аксессуары'}), (b:Category {name: 'Электроника'}) MERGE (a)-[:PART_OF]->(b);
MATCH (a:Category {name: 'Программирование'}), (b:Category {name: 'Книги'}) MERGE (a)-[:PART_OF]->(b);

// товар -> категория
MATCH (p:Product {sku: 'P-001'}), (c:Category {name: 'Ноутбуки'}) MERGE (p)-[:BELONGS_TO]->(c);
MATCH (p:Product {sku: 'P-002'}), (c:Category {name: 'Аудио'}) MERGE (p)-[:BELONGS_TO]->(c);
MATCH (p:Product {sku: 'P-003'}), (c:Category {name: 'Аксессуары'}) MERGE (p)-[:BELONGS_TO]->(c);
MATCH (p:Product {sku: 'P-004'}), (c:Category {name: 'Аксессуары'}) MERGE (p)-[:BELONGS_TO]->(c);
MATCH (p:Product {sku: 'P-005'}), (c:Category {name: 'Аксессуары'}) MERGE (p)-[:BELONGS_TO]->(c);
MATCH (p:Product {sku: 'P-006'}), (c:Category {name: 'Программирование'}) MERGE (p)-[:BELONGS_TO]->(c);
MATCH (p:Product {sku: 'P-007'}), (c:Category {name: 'Программирование'}) MERGE (p)-[:BELONGS_TO]->(c);
MATCH (p:Product {sku: 'P-008'}), (c:Category {name: 'Аудио'}) MERGE (p)-[:BELONGS_TO]->(c);

// покупки
MATCH (c:Customer {customerId: 1001}), (p:Product {sku: 'P-001'}) MERGE (c)-[:BOUGHT {date: date('2026-09-02'), qty: 1}]->(p);
MATCH (c:Customer {customerId: 1001}), (p:Product {sku: 'P-003'}) MERGE (c)-[:BOUGHT {date: date('2026-09-02'), qty: 1}]->(p);
MATCH (c:Customer {customerId: 1001}), (p:Product {sku: 'P-006'}) MERGE (c)-[:BOUGHT {date: date('2026-09-15'), qty: 1}]->(p);
MATCH (c:Customer {customerId: 1002}), (p:Product {sku: 'P-001'}) MERGE (c)-[:BOUGHT {date: date('2026-09-10'), qty: 1}]->(p);
MATCH (c:Customer {customerId: 1002}), (p:Product {sku: 'P-005'}) MERGE (c)-[:BOUGHT {date: date('2026-09-10'), qty: 1}]->(p);
MATCH (c:Customer {customerId: 1002}), (p:Product {sku: 'P-002'}) MERGE (c)-[:BOUGHT {date: date('2026-10-01'), qty: 1}]->(p);
MATCH (c:Customer {customerId: 1003}), (p:Product {sku: 'P-003'}) MERGE (c)-[:BOUGHT {date: date('2026-09-20'), qty: 1}]->(p);
MATCH (c:Customer {customerId: 1003}), (p:Product {sku: 'P-004'}) MERGE (c)-[:BOUGHT {date: date('2026-09-20'), qty: 1}]->(p);
MATCH (c:Customer {customerId: 1003}), (p:Product {sku: 'P-007'}) MERGE (c)-[:BOUGHT {date: date('2026-10-05'), qty: 2}]->(p);
MATCH (c:Customer {customerId: 1004}), (p:Product {sku: 'P-006'}) MERGE (c)-[:BOUGHT {date: date('2026-09-25'), qty: 1}]->(p);
MATCH (c:Customer {customerId: 1004}), (p:Product {sku: 'P-007'}) MERGE (c)-[:BOUGHT {date: date('2026-09-25'), qty: 1}]->(p);
MATCH (c:Customer {customerId: 1005}), (p:Product {sku: 'P-002'}) MERGE (c)-[:BOUGHT {date: date('2026-10-03'), qty: 1}]->(p);
MATCH (c:Customer {customerId: 1005}), (p:Product {sku: 'P-008'}) MERGE (c)-[:BOUGHT {date: date('2026-10-03'), qty: 1}]->(p);

// просмотры
MATCH (c:Customer {customerId: 1001}), (p:Product {sku: 'P-002'}) MERGE (c)-[:VIEWED {date: date('2026-10-04')}]->(p);
MATCH (c:Customer {customerId: 1001}), (p:Product {sku: 'P-004'}) MERGE (c)-[:VIEWED {date: date('2026-09-02')}]->(p);
MATCH (c:Customer {customerId: 1002}), (p:Product {sku: 'P-008'}) MERGE (c)-[:VIEWED {date: date('2026-10-01')}]->(p);
MATCH (c:Customer {customerId: 1003}), (p:Product {sku: 'P-001'}) MERGE (c)-[:VIEWED {date: date('2026-09-20')}]->(p);
MATCH (c:Customer {customerId: 1003}), (p:Product {sku: 'P-005'}) MERGE (c)-[:VIEWED {date: date('2026-10-10')}]->(p);
MATCH (c:Customer {customerId: 1004}), (p:Product {sku: 'P-001'}) MERGE (c)-[:VIEWED {date: date('2026-09-25')}]->(p);
MATCH (c:Customer {customerId: 1005}), (p:Product {sku: 'P-001'}) MERGE (c)-[:VIEWED {date: date('2026-10-03')}]->(p);
MATCH (c:Customer {customerId: 1005}), (p:Product {sku: 'P-004'}) MERGE (c)-[:VIEWED {date: date('2026-10-06')}]->(p);

// сколько чего получилось
MATCH (n) RETURN labels(n) AS labels, count(*) AS qty ORDER BY labels;
MATCH ()-[r]->() RETURN type(r) AS relation, count(*) AS qty ORDER BY relation;
MATCH (n) RETURN count(n) AS nodes;
MATCH ()-[r]->() RETURN count(r) AS relationships;

// тут должна быть ошибка, id уже занят
CREATE (:Customer {customerId: 1001, name: 'Дубль'});
// merge в той же ситуации просто находит узел
MERGE (c:Customer {customerId: 1001}) RETURN c.customerId, c.name;
MATCH (c:Customer) RETURN count(c) AS customers;

// Q1 все товары
MATCH (p:Product) RETURN p.sku AS sku, p.title AS title, p.price AS price ORDER BY sku;

// Q2 дешевле 50000
MATCH (p:Product) WHERE p.price < 50000
RETURN p.sku AS sku, p.title AS title, p.price AS price ORDER BY price;

// Q3 топ 3 по цене
MATCH (p:Product) RETURN p.title AS title, p.price AS price ORDER BY p.price DESC LIMIT 3;

// Q4 покупки Айдара
MATCH (c:Customer {customerId: 1001})-[b:BOUGHT]->(p:Product)
RETURN p.sku AS sku, p.title AS title, b.date AS date, b.qty AS qty ORDER BY b.date;

// товары в категории
MATCH (p:Product)-[:BELONGS_TO]->(c:Category {name: 'Аксессуары'})
RETURN p.title AS title, p.price AS price ORDER BY price;

// Q5 рекомендации для Айдара (2 шага)
MATCH (me:Customer {customerId: 1001})-[:BOUGHT]->(p:Product)<-[:BOUGHT]-(other:Customer)-[:BOUGHT]->(rec:Product)
WHERE other <> me AND NOT (me)-[:BOUGHT]->(rec)
RETURN rec.sku AS sku, rec.title AS title, count(DISTINCT other) AS buyers, collect(DISTINCT other.name) AS who
ORDER BY buyers DESC, sku;

// смотрел но не купил
MATCH (c:Customer)-[v:VIEWED]->(p:Product)
WHERE NOT (c)-[:BOUGHT]->(p)
RETURN c.name AS customer, p.title AS product, v.date AS viewed ORDER BY viewed;

// Q6 все товары в Электронике вместе с подкатегориями
MATCH (p:Product)-[:BELONGS_TO]->(:Category)-[:PART_OF*0..3]->(root:Category {name: 'Электроника'})
RETURN p.sku AS sku, p.title AS title ORDER BY sku;

// путь от товара до корневой категории
MATCH path = (p:Product {sku: 'P-004'})-[:BELONGS_TO]->(:Category)-[:PART_OF*0..3]->(root:Category)
WHERE NOT (root)-[:PART_OF]->()
RETURN p.title AS title, [n IN nodes(path)[1..] | n.name] AS breadcrumb, length(path) AS hops;

// Q7 count
MATCH (p:Product)<-[b:BOUGHT]-(c:Customer)
RETURN p.title AS title, count(b) AS purchases, sum(b.qty) AS units
ORDER BY purchases DESC, title;

// выручка по корневым категориям
MATCH (c:Customer)-[b:BOUGHT]->(p:Product)-[:BELONGS_TO]->(:Category)-[:PART_OF*0..3]->(root:Category)
WHERE NOT (root)-[:PART_OF]->()
RETURN root.name AS category, count(b) AS purchases, sum(p.price * b.qty) AS revenue
ORDER BY revenue DESC;

// по городам
MATCH (c:Customer)
OPTIONAL MATCH (c)-[b:BOUGHT]->()
RETURN c.city AS city, count(DISTINCT c) AS customers, count(b) AS purchases ORDER BY purchases DESC;

// повышенное: товары связанные через покупки
// с чем покупали ноутбук
MATCH (p:Product {sku: 'P-001'})<-[:BOUGHT]-(c:Customer)-[:BOUGHT]->(other:Product)
RETURN other.sku AS sku, other.title AS title, collect(c.name) AS via ORDER BY sku;

// путь 1..3 от ноутбука, без направления
MATCH path = (p:Product {sku: 'P-001'})-[:BOUGHT*1..3]-(x)
RETURN length(path) AS hops, labels(x)[0] AS label, coalesce(x.title, x.name) AS reached, count(path) AS paths
ORDER BY hops, reached;

// только товары, до 4 шагов
MATCH path = (p:Product {sku: 'P-001'})-[:BOUGHT*2..4]-(other:Product)
WHERE other <> p
RETURN other.title AS title, min(length(path)) AS min_hops, count(path) AS paths
ORDER BY min_hops, paths DESC;

// изменение
// скидка на наушники
MATCH (p:Product {sku: 'P-002'}) RETURN p.title AS title, p.price AS price;
MATCH (p:Product {sku: 'P-002'}) SET p.price = 129990, p.discount = true RETURN p.title AS title, p.price AS price, p.discount AS discount;
MATCH (p:Product {sku: 'P-002'}) RETURN p.title AS title, p.price AS price, p.discount AS discount;

// поправить qty на ребре
MATCH (c:Customer {customerId: 1003})-[b:BOUGHT]->(p:Product {sku: 'P-007'}) SET b.qty = 1 RETURN c.name AS customer, p.title AS title, b.qty AS qty;

// удаление
// сначала смотрю что удаляю
MATCH (c:Customer {customerId: 1001})-[v:VIEWED]->(p:Product {sku: 'P-004'})
RETURN c.name AS customer, type(v) AS rel, v.date AS date, p.title AS product;
MATCH (c:Customer {customerId: 1001})-[v:VIEWED]->(p:Product {sku: 'P-004'}) DELETE v;
MATCH (c:Customer {customerId: 1001})-[v:VIEWED]->(p:Product {sku: 'P-004'}) RETURN count(v) AS left;
MATCH (c:Customer {customerId: 1001})-[v:VIEWED]->(p:Product) RETURN p.title AS still_viewed, v.date AS date;

// тестовый узел
MATCH (c:Category {name: 'Аксессуары'}) CREATE (t:Product {sku: 'TEST-1', title: 'Тестовый товар', price: 1})-[:BELONGS_TO]->(c);
MATCH (t:Product {sku: 'TEST-1'})-[r]->(x) RETURN t.sku AS sku, type(r) AS rel, x.name AS to;
// тут ошибка, у узла есть связь
MATCH (t:Product {sku: 'TEST-1'}) DELETE t;
MATCH (t:Product {sku: 'TEST-1'}) DETACH DELETE t;
MATCH (t:Product {sku: 'TEST-1'}) RETURN count(t) AS left;

// сколько осталось
MATCH (n) RETURN count(n) AS nodes;
MATCH ()-[r]->() RETURN count(r) AS relationships;

// profile
// по sku - индекс
PROFILE MATCH (p:Product {sku: 'P-001'}) RETURN p.title;
// по title - скан
PROFILE MATCH (p:Product {title: 'Клавиатура MX Keys'}) RETURN p.sku;

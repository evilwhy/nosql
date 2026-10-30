// лаба 9, вариант 3 - интернет магазин
// запускал так: docker exec -i nosql-neo4j-1 cypher-shell -u neo4j -p Lab7StrongPass123 --format verbose --fail-at-end -f /dev/stdin < lab9/queries.cypher

RETURN 'Neo4j works' AS status;

// чищу базу после лабы 7
MATCH (n) DETACH DELETE n;
DROP CONSTRAINT customer_id IF EXISTS;
DROP CONSTRAINT product_sku IF EXISTS;
DROP CONSTRAINT category_name IF EXISTS;

// 2 constraints по id
CREATE CONSTRAINT customer_id_unique IF NOT EXISTS FOR (c:Customer) REQUIRE c.id IS UNIQUE;
CREATE CONSTRAINT product_id_unique IF NOT EXISTS FOR (p:Product) REQUIRE p.id IS UNIQUE;
CREATE CONSTRAINT category_id_unique IF NOT EXISTS FOR (c:Category) REQUIRE c.id IS UNIQUE;
SHOW CONSTRAINTS YIELD name, type, labelsOrTypes, properties;

// клиенты
MERGE (c:Customer {id: 1}) SET c.name = 'Айдар С.', c.city = 'Алматы', c.regYear = 2024;
MERGE (c:Customer {id: 2}) SET c.name = 'Дана Н.', c.city = 'Астана', c.regYear = 2025;
MERGE (c:Customer {id: 3}) SET c.name = 'Ерлан Б.', c.city = 'Алматы', c.regYear = 2023;
MERGE (c:Customer {id: 4}) SET c.name = 'Алия К.', c.city = 'Шымкент', c.regYear = 2026;
MERGE (c:Customer {id: 5}) SET c.name = 'Мадина Т.', c.city = 'Караганда', c.regYear = 2025;

// категории
MERGE (c:Category {id: 10}) SET c.name = 'Ноутбуки', c.section = 'Электроника';
MERGE (c:Category {id: 11}) SET c.name = 'Аудио', c.section = 'Электроника';
MERGE (c:Category {id: 12}) SET c.name = 'Аксессуары', c.section = 'Электроника';
MERGE (c:Category {id: 13}) SET c.name = 'Книги', c.section = 'Книги';

// товары, цена в тг
MERGE (p:Product {id: 101}) SET p.title = 'Ноутбук IdeaPad 3', p.price = 289990, p.stock = 4;
MERGE (p:Product {id: 102}) SET p.title = 'Наушники WH-1000XM5', p.price = 149990, p.stock = 10;
MERGE (p:Product {id: 103}) SET p.title = 'Клавиатура MX Keys', p.price = 54990, p.stock = 7;
MERGE (p:Product {id: 104}) SET p.title = 'Мышь MX Master 3S', p.price = 44990, p.stock = 12;
MERGE (p:Product {id: 105}) SET p.title = 'Книга «Чистый код»', p.price = 12990, p.stock = 20;
MERGE (p:Product {id: 106}) SET p.title = 'Книга «Грокаем алгоритмы»', p.price = 9990, p.stock = 15;
MERGE (p:Product {id: 107}) SET p.title = 'Колонка Flip 6', p.price = 59990, p.stock = 6;

// товар -> категория
MATCH (p:Product {id: 101}), (c:Category {id: 10}) MERGE (p)-[:IN_CATEGORY]->(c);
MATCH (p:Product {id: 102}), (c:Category {id: 11}) MERGE (p)-[:IN_CATEGORY]->(c);
MATCH (p:Product {id: 107}), (c:Category {id: 11}) MERGE (p)-[:IN_CATEGORY]->(c);
MATCH (p:Product {id: 103}), (c:Category {id: 12}) MERGE (p)-[:IN_CATEGORY]->(c);
MATCH (p:Product {id: 104}), (c:Category {id: 12}) MERGE (p)-[:IN_CATEGORY]->(c);
MATCH (p:Product {id: 105}), (c:Category {id: 13}) MERGE (p)-[:IN_CATEGORY]->(c);
MATCH (p:Product {id: 106}), (c:Category {id: 13}) MERGE (p)-[:IN_CATEGORY]->(c);

// покупки, дата и количество на ребре
MATCH (c:Customer {id: 1}), (p:Product {id: 101}) MERGE (c)-[:BOUGHT {date: date('2026-09-02'), qty: 1}]->(p);
MATCH (c:Customer {id: 1}), (p:Product {id: 103}) MERGE (c)-[:BOUGHT {date: date('2026-09-02'), qty: 1}]->(p);
MATCH (c:Customer {id: 1}), (p:Product {id: 105}) MERGE (c)-[:BOUGHT {date: date('2026-09-15'), qty: 1}]->(p);
MATCH (c:Customer {id: 2}), (p:Product {id: 101}) MERGE (c)-[:BOUGHT {date: date('2026-09-10'), qty: 1}]->(p);
MATCH (c:Customer {id: 2}), (p:Product {id: 104}) MERGE (c)-[:BOUGHT {date: date('2026-09-10'), qty: 1}]->(p);
MATCH (c:Customer {id: 2}), (p:Product {id: 102}) MERGE (c)-[:BOUGHT {date: date('2026-09-20'), qty: 1}]->(p);
MATCH (c:Customer {id: 2}), (p:Product {id: 105}) MERGE (c)-[:BOUGHT {date: date('2026-09-28'), qty: 1}]->(p);
MATCH (c:Customer {id: 3}), (p:Product {id: 102}) MERGE (c)-[:BOUGHT {date: date('2026-09-12'), qty: 1}]->(p);
MATCH (c:Customer {id: 3}), (p:Product {id: 107}) MERGE (c)-[:BOUGHT {date: date('2026-09-12'), qty: 1}]->(p);
MATCH (c:Customer {id: 3}), (p:Product {id: 105}) MERGE (c)-[:BOUGHT {date: date('2026-10-01'), qty: 2}]->(p);
MATCH (c:Customer {id: 4}), (p:Product {id: 106}) MERGE (c)-[:BOUGHT {date: date('2026-09-25'), qty: 1}]->(p);
MATCH (c:Customer {id: 4}), (p:Product {id: 105}) MERGE (c)-[:BOUGHT {date: date('2026-09-25'), qty: 1}]->(p);
MATCH (c:Customer {id: 5}), (p:Product {id: 103}) MERGE (c)-[:BOUGHT {date: date('2026-10-05'), qty: 1}]->(p);
MATCH (c:Customer {id: 5}), (p:Product {id: 104}) MERGE (c)-[:BOUGHT {date: date('2026-10-05'), qty: 1}]->(p);

// сколько получилось
MATCH (n) RETURN labels(n)[0] AS label, count(*) AS qty ORDER BY label;
MATCH ()-[r]->() RETURN type(r) AS relation, count(*) AS qty ORDER BY relation;

// 3 все узлы одной метки
MATCH (c:Customer) RETURN c;
// свойства с сортировкой и лимитом
MATCH (p:Product) RETURN p.title AS title, p.price AS price ORDER BY price DESC LIMIT 5;

// 4 один шаг: что купил Айдар
MATCH (c:Customer {id: 1})-[b:BOUGHT]->(p:Product)
RETURN p.title AS product, b.date AS date, b.qty AS qty ORDER BY date;
// обратный поиск: кто купил Чистый код
MATCH (p:Product {id: 105})<-[:BOUGHT]-(c:Customer)
RETURN c.name AS customer, c.city AS city;
// два шага: покупки клиента по категориям
MATCH (c:Customer {id: 1})-[b:BOUGHT]->(p:Product)-[:IN_CATEGORY]->(cat:Category)
RETURN cat.name AS category, collect(p.title) AS products, sum(b.qty * p.price) AS total
ORDER BY total DESC;
// два шага в другую сторону: кто покупал из Аудио
MATCH (cat:Category {name: 'Аудио'})<-[:IN_CATEGORY]-(p:Product)<-[:BOUGHT]-(c:Customer)
RETURN c.name AS customer, p.title AS product;

// 5 where по строке
MATCH (c:Customer) WHERE c.city = 'Алматы' RETURN c.name AS name, c.regYear AS regYear;
// по числу
MATCH (p:Product) WHERE p.price >= 50000 RETURN p.title AS title, p.price AS price ORDER BY price;
// вместе
MATCH (p:Product) WHERE p.title STARTS WITH 'Книга' AND p.stock > 15 RETURN p.title AS title, p.stock AS stock;
// фильтр по свойству ребра
MATCH (c:Customer)-[b:BOUGHT]->(p:Product) WHERE b.date >= date('2026-10-01')
RETURN c.name AS customer, p.title AS product, b.date AS date;

// 6 меняю свойство узла
MATCH (p:Product {id: 102}) SET p.price = 129990 RETURN p.title AS title, p.price AS price;
// добавляю свойство на ребро
MATCH (c:Customer {id: 1})-[b:BOUGHT]->(p:Product {id: 101})
SET b.rating = 5 RETURN c.name AS customer, p.title AS product, b.rating AS rating;
// проверка
MATCH (c:Customer {id: 1})-[b:BOUGHT]->(p:Product) RETURN p.title AS product, p.price AS price, b.rating AS rating;

// 7 тестовый узел со связью
CREATE (t:Temp {id: 999, note: 'delete-me'})
WITH t MATCH (p:Product {id: 101}) CREATE (t)-[:TEST_REL]->(p);
MATCH (t:Temp) RETURN t;
// тут ошибка, у узла есть связь
MATCH (t:Temp {id: 999}) DELETE t;
// а так удаляется вместе с ребром
MATCH (t:Temp {id: 999}) DETACH DELETE t;
MATCH (t:Temp {id: 999}) RETURN count(t) AS remaining;
// ноутбук на месте
MATCH (p:Product {id: 101}) RETURN p.title AS title;

// 8 повторный merge, узлов не должно прибавиться
MERGE (c:Customer {id: 1}) SET c.name = 'Айдар С.', c.city = 'Алматы', c.regYear = 2024;
MERGE (p:Product {id: 101}) SET p.title = 'Ноутбук IdeaPad 3', p.price = 289990, p.stock = 4;
MATCH (c:Customer {id: 1}), (p:Product {id: 101}) MERGE (c)-[:BOUGHT {date: date('2026-09-02'), qty: 1}]->(p);
MATCH (n) RETURN labels(n)[0] AS label, count(*) AS qty ORDER BY label;
MATCH ()-[r]->() RETURN type(r) AS relation, count(*) AS qty ORDER BY relation;
// а create с тем же id упадет на constraint
CREATE (:Customer {id: 1, name: 'Дубль'});
// проверка что дублей по id нет
MATCH (c:Customer) WITH c.id AS id, count(*) AS cnt WHERE cnt > 1 RETURN id, cnt;

// доп: пары клиентов с общими покупками
// без collect пара с двумя общими товарами идет двумя строками
MATCH (a:Customer)-[:BOUGHT]->(p:Product)<-[:BOUGHT]-(b:Customer)
WHERE a.id < b.id
RETURN a.name AS first, b.name AS second, p.title AS shared
ORDER BY first, second;
// с collect(DISTINCT) одна строка на пару
MATCH (a:Customer)-[:BOUGHT]->(p:Product)<-[:BOUGHT]-(b:Customer)
WHERE a.id < b.id
RETURN a.name AS first, b.name AS second, collect(DISTINCT p.title) AS shared
ORDER BY first, second;

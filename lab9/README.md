# Лабораторная работа №9

Дисциплина: Проектирование и применение NoSQL-технологий

Тема: Создание графа в Neo4j и выполнение базовых запросов Cypher

Вариант 3 - Интернет-магазин (Customer, Product, Category; BOUGHT, IN_CATEGORY). Целевой запрос: покупки клиента по категориям.

## Цель

Освоить модель property graph: создать граф в Neo4j, выполнить базовые запросы Cypher (MATCH, WHERE, RETURN, ORDER BY, переходы по связям), изменить и удалить данные, проверить что повторный MERGE не плодит дубли.

## Предметная область

Интернет-магазин электроники и книг. Клиенты покупают товары, дата и количество хранятся на связи. Каждый товар лежит в одной категории. Нужно смотреть покупки клиента по категориям, кто купил конкретный товар и у кого похожие покупки.

Данные учебные. В лабе 7 был похожий магазин, тут схема по методичке: два типа связей, у всех меток целый id.

## Запуск

Neo4j тот же, что в лабе 7 (docker-compose.yml в корне).

```
docker compose up -d neo4j
docker exec -i nosql-neo4j-1 cypher-shell -u neo4j -p Lab7StrongPass123 --format verbose --fail-at-end -f /dev/stdin < lab9/queries.cypher
```
В начале скрипта чищу базу от графа лабы 7 и снимаю старые constraint. Все команды в queries.cypher.

## Задание 1. Схема

| Метка | Свойства | Что это |
|---|---|---|
| Customer | id (уникальный), name, city, regYear | клиент |
| Product | id (уникальный), title, price (тг), stock | товар |
| Category | id (уникальный), name, section | категория |

| Отношение | Откуда -> Куда | Свойства | Смысл |
|---|---|---|---|
| BOUGHT | Customer -> Product | date, qty | клиент купил товар |
| IN_CATEGORY | Product -> Category | - | товар лежит в категории |

Стрелка читается как предложение: клиент купил товар, товар в категории. IN_CATEGORY от товара к категории, потому что у товара одна категория, а у категории много товаров.

Кусок графа на 8 объектов:

```
(Айдар)──BOUGHT──>(Ноутбук)──IN_CATEGORY──>(Ноутбуки)
   │                  ^
   │                  └──BOUGHT──(Дана)──BOUGHT──>(Наушники)──IN_CATEGORY──>(Аудио)
   │
   └──BOUGHT──>(Чистый код)──IN_CATEGORY──>(Книги)
```

## Задание 2. Ограничения и граф

```
CREATE CONSTRAINT customer_id_unique IF NOT EXISTS FOR (c:Customer) REQUIRE c.id IS UNIQUE;
CREATE CONSTRAINT product_id_unique IF NOT EXISTS FOR (p:Product) REQUIRE p.id IS UNIQUE;
CREATE CONSTRAINT category_id_unique IF NOT EXISTS FOR (c:Category) REQUIRE c.id IS UNIQUE;
SHOW CONSTRAINTS YIELD name, type, labelsOrTypes, properties;
```
```
+------------------------------------------------------------------+
| name                 | type         | labelsOrTypes | properties |
+------------------------------------------------------------------+
| "category_id_unique" | "UNIQUENESS" | ["Category"]  | ["id"]     |
| "customer_id_unique" | "UNIQUENESS" | ["Customer"]  | ["id"]     |
| "product_id_unique"  | "UNIQUENESS" | ["Product"]   | ["id"]     |
+------------------------------------------------------------------+
```

Узлы: MERGE по id, остальные свойства через SET.
```
MERGE (c:Customer {id: 1}) SET c.name = 'Айдар С.', c.city = 'Алматы', c.regYear = 2024;
MERGE (c:Category {id: 10}) SET c.name = 'Ноутбуки', c.section = 'Электроника';
MERGE (p:Product {id: 101}) SET p.title = 'Ноутбук IdeaPad 3', p.price = 289990, p.stock = 4;
```

Связи: MATCH обоих узлов, потом MERGE ребра.
```
MATCH (p:Product {id: 101}), (c:Category {id: 10}) MERGE (p)-[:IN_CATEGORY]->(c);
MATCH (c:Customer {id: 1}), (p:Product {id: 101}) MERGE (c)-[:BOUGHT {date: date('2026-09-02'), qty: 1}]->(p);
```
Остальные в queries.cypher.

5 клиентов, 7 товаров, 4 категории = 16 узлов. 14 BOUGHT + 7 IN_CATEGORY = 21 связь.
```
MATCH (n) RETURN labels(n)[0] AS label, count(*) AS qty ORDER BY label;
MATCH ()-[r]->() RETURN type(r) AS relation, count(*) AS qty ORDER BY relation;
```
```
+------------------+      +---------------------+
| label      | qty |      | relation      | qty |
+------------------+      +---------------------+
| "Category" | 4   |      | "BOUGHT"      | 14  |
| "Customer" | 5   |      | "IN_CATEGORY" | 7   |
| "Product"  | 7   |      +---------------------+
+------------------+
```

## Задание 3. Чтение, сортировка, LIMIT

```
MATCH (c:Customer) RETURN c;
```
```
+--------------------------------------------------------------------------+
| c                                                                        |
+--------------------------------------------------------------------------+
| (:Customer {name: "Айдар С.", id: 1, regYear: 2024, city: "Алматы"})     |
| (:Customer {name: "Дана Н.", id: 2, regYear: 2025, city: "Астана"})      |
| (:Customer {name: "Ерлан Б.", id: 3, regYear: 2023, city: "Алматы"})     |
| (:Customer {name: "Алия К.", id: 4, regYear: 2026, city: "Шымкент"})     |
| (:Customer {name: "Мадина Т.", id: 5, regYear: 2025, city: "Караганда"}) |
+--------------------------------------------------------------------------+
```
Топ 5 по цене:
```
MATCH (p:Product) RETURN p.title AS title, p.price AS price ORDER BY price DESC LIMIT 5;
```
```
+--------------------------------+
| title                 | price  |
+--------------------------------+
| "Ноутбук IdeaPad 3"   | 289990 |
| "Наушники WH-1000XM5" | 149990 |
| "Колонка Flip 6"      | 59990  |
| "Клавиатура MX Keys"  | 54990  |
| "Мышь MX Master 3S"   | 44990  |
+--------------------------------+
```

## Задание 4. Переходы по связям

Один шаг, что купил Айдар. `(c:Customer {id: 1})` стартовый узел, `-[b:BOUGHT]->` ребро (переменная b чтобы достать дату и qty), `(p:Product)` куда пришли.
```
MATCH (c:Customer {id: 1})-[b:BOUGHT]->(p:Product)
RETURN p.title AS product, b.date AS date, b.qty AS qty ORDER BY date;
```
```
+-----------------------------------------+
| product              | date       | qty |
+-----------------------------------------+
| "Клавиатура MX Keys" | 2026-09-02 | 1   |
| "Ноутбук IdeaPad 3"  | 2026-09-02 | 1   |
| "Книга «Чистый код»" | 2026-09-15 | 1   |
+-----------------------------------------+
```

Обратный поиск, кто купил «Чистый код». Стрелка влево, идем от товара к клиентам.
```
MATCH (p:Product {id: 105})<-[:BOUGHT]-(c:Customer)
RETURN c.name AS customer, c.city AS city;
```
```
+------------------------+
| customer   | city      |
+------------------------+
| "Алия К."  | "Шымкент" |
| "Ерлан Б." | "Алматы"  |
| "Дана Н."  | "Астана"  |
| "Айдар С." | "Алматы"  |
+------------------------+
```

Два шага, целевой запрос: покупки клиента по категориям. Клиент -> товар -> категория, группировка по категории, collect собирает названия, sum считает сумму.
```
MATCH (c:Customer {id: 1})-[b:BOUGHT]->(p:Product)-[:IN_CATEGORY]->(cat:Category)
RETURN cat.name AS category, collect(p.title) AS products, sum(b.qty * p.price) AS total
ORDER BY total DESC;
```
```
+------------------------------------------------+
| category     | products               | total  |
+------------------------------------------------+
| "Ноутбуки"   | ["Ноутбук IdeaPad 3"]  | 289990 |
| "Аксессуары" | ["Клавиатура MX Keys"] | 54990  |
| "Книги"      | ["Книга «Чистый код»"] | 12990  |
+------------------------------------------------+
```

Та же цепочка с другого конца, кто покупал из Аудио:
```
MATCH (cat:Category {name: 'Аудио'})<-[:IN_CATEGORY]-(p:Product)<-[:BOUGHT]-(c:Customer)
RETURN c.name AS customer, p.title AS product;
```
```
+------------------------------------+
| customer   | product               |
+------------------------------------+
| "Ерлан Б." | "Колонка Flip 6"      |
| "Ерлан Б." | "Наушники WH-1000XM5" |
| "Дана Н."  | "Наушники WH-1000XM5" |
+------------------------------------+
```

## Задание 5. WHERE

```
MATCH (c:Customer) WHERE c.city = 'Алматы' RETURN c.name AS name, c.regYear AS regYear;
MATCH (p:Product) WHERE p.price >= 50000 RETURN p.title AS title, p.price AS price ORDER BY price;
MATCH (p:Product) WHERE p.title STARTS WITH 'Книга' AND p.stock > 15 RETURN p.title AS title, p.stock AS stock;
```
1) Айдар С. (2024), Ерлан Б. (2023)
2) Клавиатура 54990, Колонка 59990, Наушники 149990, Ноутбук 289990
3) Книга «Чистый код», stock 20

По свойству ребра, покупки с октября:
```
MATCH (c:Customer)-[b:BOUGHT]->(p:Product) WHERE b.date >= date('2026-10-01')
RETURN c.name AS customer, p.title AS product, b.date AS date;
```
```
+-------------------------------------------------+
| customer    | product              | date       |
+-------------------------------------------------+
| "Ерлан Б."  | "Книга «Чистый код»" | 2026-10-01 |
| "Мадина Т." | "Мышь MX Master 3S"  | 2026-10-05 |
| "Мадина Т." | "Клавиатура MX Keys" | 2026-10-05 |
+-------------------------------------------------+
```

## Задание 6. SET

Свойство узла, скидка на наушники:
```
MATCH (p:Product {id: 102}) SET p.price = 129990 RETURN p.title AS title, p.price AS price;
```
```
| "Наушники WH-1000XM5" | 129990 |
Set 1 properties
```
Свойство на ребре, оценка покупки:
```
MATCH (c:Customer {id: 1})-[b:BOUGHT]->(p:Product {id: 101})
SET b.rating = 5 RETURN c.name AS customer, p.title AS product, b.rating AS rating;
```
```
| "Айдар С." | "Ноутбук IdeaPad 3" | 5      |
Set 1 properties
```
Проверка:
```
MATCH (c:Customer {id: 1})-[b:BOUGHT]->(p:Product) RETURN p.title AS product, p.price AS price, b.rating AS rating;
```
```
+----------------------------------------+
| product              | price  | rating |
+----------------------------------------+
| "Книга «Чистый код»" | 12990  | NULL   |
| "Клавиатура MX Keys" | 54990  | NULL   |
| "Ноутбук IdeaPad 3"  | 289990 | 5      |
+----------------------------------------+
```
rating появился только на одном ребре, у остальных NULL.

## Задание 7. Удаление

Тестовый узел, привязал его к ноутбуку чтобы увидеть разницу DELETE и DETACH DELETE:
```
CREATE (t:Temp {id: 999, note: 'delete-me'})
WITH t MATCH (p:Product {id: 101}) CREATE (t)-[:TEST_REL]->(p);
MATCH (t:Temp) RETURN t;
```
```
| (:Temp {note: "delete-me", id: 999}) |
```
```
MATCH (t:Temp {id: 999}) DELETE t;
```
```
Cannot delete node<0>, because it still has relationships. To delete this node, you must first delete its relationships.
```
```
MATCH (t:Temp {id: 999}) DETACH DELETE t;
MATCH (t:Temp {id: 999}) RETURN count(t) AS remaining;
MATCH (p:Product {id: 101}) RETURN p.title AS title;
```
```
Deleted 1 nodes, Deleted 1 relationships
remaining 0
"Ноутбук IdeaPad 3"
```
Ноутбук на месте, удалились только Temp и его ребро. DETACH DELETE делаю только по id тестового узла.

## Задание 8. Повторный MERGE

```
MERGE (c:Customer {id: 1}) SET c.name = 'Айдар С.', c.city = 'Алматы', c.regYear = 2024;
MERGE (p:Product {id: 101}) SET p.title = 'Ноутбук IdeaPad 3', p.price = 289990, p.stock = 4;
MATCH (c:Customer {id: 1}), (p:Product {id: 101}) MERGE (c)-[:BOUGHT {date: date('2026-09-02'), qty: 1}]->(p);
```
```
Set 3 properties
Set 3 properties
0 rows
```
Нет Added nodes и Created relationships, только Set. Счетчики те же: Category 4, Customer 5, Product 7, BOUGHT 14, IN_CATEGORY 7.

CREATE с занятым id:
```
CREATE (:Customer {id: 1, name: 'Дубль'});
```
```
Node(16) already exists with label `Customer` and property `id` = 1
```
Дубли по id:
```
MATCH (c:Customer) WITH c.id AS id, count(*) AS cnt WHERE cnt > 1 RETURN id, cnt;
```
0 rows.

CREATE всегда создает, MERGE сначала ищет и создает только если не нашел. Constraint не даст второй узел с тем же id даже через CREATE, плюс по id появляется индекс.

## Дополнительное задание

Пары клиентов с общими покупками. `a.id < b.id` убирает зеркальные пары.

Без collect пара с двумя общими товарами идет двумя строками:
```
MATCH (a:Customer)-[:BOUGHT]->(p:Product)<-[:BOUGHT]-(b:Customer)
WHERE a.id < b.id
RETURN a.name AS first, b.name AS second, p.title AS shared
ORDER BY first, second;
```
10 строк, Айдар/Дана и Дана/Ерлан по два раза.

С collect(DISTINCT):
```
MATCH (a:Customer)-[:BOUGHT]->(p:Product)<-[:BOUGHT]-(b:Customer)
WHERE a.id < b.id
RETURN a.name AS first, b.name AS second, collect(DISTINCT p.title) AS shared
ORDER BY first, second;
```
```
+--------------------------------------------------------------------------+
| first      | second      | shared                                        |
+--------------------------------------------------------------------------+
| "Айдар С." | "Алия К."   | ["Книга «Чистый код»"]                        |
| "Айдар С." | "Дана Н."   | ["Книга «Чистый код»", "Ноутбук IdeaPad 3"]   |
| "Айдар С." | "Ерлан Б."  | ["Книга «Чистый код»"]                        |
| "Айдар С." | "Мадина Т." | ["Клавиатура MX Keys"]                        |
| "Дана Н."  | "Алия К."   | ["Книга «Чистый код»"]                        |
| "Дана Н."  | "Ерлан Б."  | ["Книга «Чистый код»", "Наушники WH-1000XM5"] |
| "Дана Н."  | "Мадина Т." | ["Мышь MX Master 3S"]                         |
| "Ерлан Б." | "Алия К."   | ["Книга «Чистый код»"]                        |
+--------------------------------------------------------------------------+
```

## Пояснения

- MATCH - ищет в графе шаблон: узлы в круглых скобках, ребра в квадратных, стрелка это направление. `<-` идет против ребра
- MERGE - ищет шаблон, создает если не нашел. В MERGE кладу только id, остальное в SET
- WHERE - фильтр после MATCH, сравнения, STARTS WITH, AND/OR, работает и по свойствам ребер. `{id: 1}` в шаблоне то же что `WHERE c.id = 1`
- SET - меняет или добавляет свойство узлу или ребру
- DELETE - удаляет узел без связей или ребро, со связями ошибка. DETACH DELETE удаляет узел вместе со связями

## Контрольные вопросы

1. Модель из узлов с метками и свойствами и направленных отношений между ними, у отношений тоже есть тип и свойства
2. Узел это сущность (клиент, товар), отношение это направленная связь между двумя узлами
3. Метки группируют узлы по роли и с них начинается поиск, свойства хранят данные
4. Смысл связи: Customer купил Product, а не наоборот. В MATCH можно идти в любую сторону, хранится ребро с направлением
5. CREATE всегда создает новый элемент, MERGE создает только если такого еще нет
6. Рисуешь шаблон из узлов и ребер, Neo4j находит все подграфы которые под него подходят
7. WHERE отбирает строки, RETURN говорит что из них показать
8. Два ребра подряд в шаблоне: `(c)-[:BOUGHT]->(p)-[:IN_CATEGORY]->(cat)`
9. ORDER BY сортирует, LIMIT оставляет первые N строк
10. MATCH нужного узла или ребра, потом `SET x.prop = value`
11. DELETE не удалит узел со связями, DETACH DELETE удалит вместе со связями
12. Чтобы не появился второй узел с тем же id, и чтобы MERGE по id шел через индекс
13. Сгруппировать по id и оставить count > 1, пустой результат значит дублей нет. Плюс сравнить счетчики до и после повторного запуска
14. Когда главные вопросы про связи: рекомендации, друзья друзей, путь между объектами. В таблицах это цепочка JOIN, которая дорожает с глубиной

## Вывод

В этой лабе я собрал граф интернет-магазина в Neo4j: метки Customer, Product и Category, связи BOUGHT (с датой и количеством) и IN_CATEGORY, 16 узлов и 21 связь. Перед загрузкой поставил constraint на id, узлы создавал через MERGE по id с SET остальных свойств, связи через MATCH обоих концов и MERGE ребра. Написал запросы на чтение с ORDER BY и LIMIT, фильтры WHERE по строке, числу и свойству ребра, переходы в один шаг, обратный и двухшаговый целевой запрос варианта с группировкой по категориям. Проверил SET на узле и на ребре, увидел что DELETE узла со связью падает, а DETACH DELETE удаляет его вместе с ребром. Повторный MERGE не добавил ни одного узла и ребра, а CREATE с занятым id упал на constraint. В доп. задании нашел пары клиентов с общими покупками через collect(DISTINCT).

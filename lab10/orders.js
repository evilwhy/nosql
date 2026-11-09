// лаба 10, вариант 3 - заказы интернет магазина
// запускал: docker exec -i nosql-mongo-rs-1 mongosh --quiet --port 27101 < lab10/orders.js

use shop_lab10

db.orders.createIndex({ orderId: 1 }, { unique: true })

// 22 заказа, все с подтверждением большинства
db.orders.insertMany([
  { orderId: 1,  customerId: 1001, city: "Алматы",    status: "delivered", total: 289990, items: [{ sku: "P-001", qty: 1, price: 289990 }], createdAt: ISODate("2026-10-01T09:12:00Z") },
  { orderId: 2,  customerId: 1002, city: "Астана",    status: "delivered", total: 149990, items: [{ sku: "P-002", qty: 1, price: 149990 }], createdAt: ISODate("2026-10-01T11:40:00Z") },
  { orderId: 3,  customerId: 1003, city: "Алматы",    status: "delivered", total: 99980,  items: [{ sku: "P-003", qty: 1, price: 54990 }, { sku: "P-004", qty: 1, price: 44990 }], createdAt: ISODate("2026-10-02T08:05:00Z") },
  { orderId: 4,  customerId: 1004, city: "Шымкент",   status: "cancelled", total: 12990,  items: [{ sku: "P-006", qty: 1, price: 12990 }], createdAt: ISODate("2026-10-02T15:30:00Z") },
  { orderId: 5,  customerId: 1005, city: "Караганда", status: "delivered", total: 19980,  items: [{ sku: "P-007", qty: 2, price: 9990 }], createdAt: ISODate("2026-10-03T10:00:00Z") },
  { orderId: 6,  customerId: 1001, city: "Алматы",    status: "delivered", total: 7990,   items: [{ sku: "P-005", qty: 1, price: 7990 }], createdAt: ISODate("2026-10-04T12:20:00Z") },
  { orderId: 7,  customerId: 1002, city: "Астана",    status: "shipped",   total: 59990,  items: [{ sku: "P-008", qty: 1, price: 59990 }], createdAt: ISODate("2026-10-05T09:45:00Z") },
  { orderId: 8,  customerId: 1006, city: "Алматы",    status: "delivered", total: 44990,  items: [{ sku: "P-004", qty: 1, price: 44990 }], createdAt: ISODate("2026-10-06T14:10:00Z") },
  { orderId: 9,  customerId: 1003, city: "Алматы",    status: "delivered", total: 22980,  items: [{ sku: "P-006", qty: 1, price: 12990 }, { sku: "P-007", qty: 1, price: 9990 }], createdAt: ISODate("2026-10-07T18:00:00Z") },
  { orderId: 10, customerId: 1007, city: "Павлодар",  status: "shipped",   total: 289990, items: [{ sku: "P-001", qty: 1, price: 289990 }], createdAt: ISODate("2026-10-08T10:30:00Z") },
  { orderId: 11, customerId: 1004, city: "Шымкент",   status: "delivered", total: 54990,  items: [{ sku: "P-003", qty: 1, price: 54990 }], createdAt: ISODate("2026-10-09T09:00:00Z") },
  { orderId: 12, customerId: 1008, city: "Астана",    status: "delivered", total: 149990, items: [{ sku: "P-002", qty: 1, price: 149990 }], createdAt: ISODate("2026-10-10T16:25:00Z") },
  { orderId: 13, customerId: 1005, city: "Караганда", status: "cancelled", total: 59990,  items: [{ sku: "P-008", qty: 1, price: 59990 }], createdAt: ISODate("2026-10-11T11:15:00Z") },
  { orderId: 14, customerId: 1001, city: "Алматы",    status: "delivered", total: 9990,   items: [{ sku: "P-007", qty: 1, price: 9990 }], createdAt: ISODate("2026-10-12T13:40:00Z") },
  { orderId: 15, customerId: 1009, city: "Актобе",    status: "shipped",   total: 52980,  items: [{ sku: "P-004", qty: 1, price: 44990 }, { sku: "P-005", qty: 1, price: 7990 }], createdAt: ISODate("2026-10-13T08:50:00Z") },
  { orderId: 16, customerId: 1006, city: "Алматы",    status: "delivered", total: 12990,  items: [{ sku: "P-006", qty: 1, price: 12990 }], createdAt: ISODate("2026-10-14T19:05:00Z") },
  { orderId: 17, customerId: 1002, city: "Астана",    status: "processing", total: 54990, items: [{ sku: "P-003", qty: 1, price: 54990 }], createdAt: ISODate("2026-10-15T10:10:00Z") },
  { orderId: 18, customerId: 1010, city: "Тараз",     status: "processing", total: 299980, items: [{ sku: "P-001", qty: 1, price: 289990 }, { sku: "P-007", qty: 1, price: 9990 }], createdAt: ISODate("2026-10-15T12:00:00Z") },
  { orderId: 19, customerId: 1003, city: "Алматы",    status: "processing", total: 59990, items: [{ sku: "P-008", qty: 1, price: 59990 }], createdAt: ISODate("2026-10-16T09:30:00Z") },
  { orderId: 20, customerId: 1008, city: "Астана",    status: "new",       total: 15980,  items: [{ sku: "P-005", qty: 2, price: 7990 }], createdAt: ISODate("2026-10-16T14:45:00Z") },
  { orderId: 21, customerId: 1007, city: "Павлодар",  status: "new",       total: 44990,  items: [{ sku: "P-004", qty: 1, price: 44990 }], createdAt: ISODate("2026-10-17T08:20:00Z") },
  { orderId: 22, customerId: 1005, city: "Караганда", status: "new",       total: 149990, items: [{ sku: "P-002", qty: 1, price: 149990 }], createdAt: ISODate("2026-10-17T10:05:00Z") }
], { writeConcern: { w: "majority", wtimeout: 5000 } })

db.orders.countDocuments()
db.orders.find({}, { _id: 0, orderId: 1, customerId: 1, status: 1, total: 1 }).sort({ orderId: 1 })

// контрольные значения, по ним потом сверяю после отказа и после restore
db.orders.aggregate([{ $group: { _id: null, count: { $sum: 1 }, maxOrderId: { $max: "$orderId" }, sumTotal: { $sum: "$total" } } }])

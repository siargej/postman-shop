import express from "express";
import bodyParser from "body-parser";
import { Client } from "pg";
import { v4 as uuid } from "uuid";

const app = express();
app.use(bodyParser.json());

const pg = new Client({ connectionString: process.env.PG_URL });
await pg.connect();

const topicStore = new Map();
const webhookStore = new Map();

app.get("/verify/order/:id", async (req, res) => {
  const { rows } = await pg.query("select * from orders where id=$1", [req.params.id]);
  res.json({ found: rows.length > 0, row: rows[0] || null });
});

app.post("/events/publish", (req, res) => {
  const { topic, payload } = req.body;
  topicStore.set(payload.orderId, { topic, payload, ts: Date.now() });
  res.json({ ok: true });
});
app.get("/events/:orderId", (req, res) => {
  res.json(topicStore.get(req.params.orderId) || null);
});

app.post("/webhook/:orderId", (req, res) => {
  webhookStore.set(req.params.orderId, { body: req.body, ts: Date.now() });
  res.json({ ok: true });
});
app.get("/webhook/:orderId", (req, res) => {
  res.json(webhookStore.get(req.params.orderId) || null);
});

app.post("/make-paid", async (req, res) => {
  const id = req.body.orderId || uuid();
  const email = req.body.email || "user@example.com";
  const amount = req.body.amount || 35;
  await pg.query(
    "insert into orders(id,user_email,amount,status) values($1,$2,$3,'PAID') on conflict(id) do update set status='PAID';",
    [id, email, amount]
  );
  topicStore.set(id, { topic: "order.paid", payload: { orderId: id, email, amount }, ts: Date.now() });
  webhookStore.set(id, { body: { orderId: id, status: "PAID" }, ts: Date.now() });
  res.json({ ok: true, orderId: id });
});

app.get("/mail/search", async (req, res) => {
  const api = process.env.MAILPIT_API;
  const q = encodeURIComponent(req.query.q || "Order");
  const r = await fetch(`${api}/search?query=${q}`);
  res.json(await r.json());
});

app.listen(4000, () => console.log("verify-service on :4000"));

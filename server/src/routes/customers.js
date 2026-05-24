const express = require('express');
const { v4: uuid } = require('uuid');
const store = require('../db/store');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();
router.use(authMiddleware);

router.get('/', (req, res) => {
  res.json(store.getCustomers(req.user.id));
});

router.post('/', (req, res) => {
  const customer = { id: uuid(), ...req.body, createdAt: new Date().toISOString() };
  const list = store.getCustomers(req.user.id);
  list.unshift(customer);
  store.saveCustomers(req.user.id, list);
  res.status(201).json(customer);
});

router.delete('/:id', (req, res) => {
  const list = store.getCustomers(req.user.id).filter((c) => c.id !== req.params.id);
  store.saveCustomers(req.user.id, list);
  res.json({ ok: true });
});

module.exports = router;

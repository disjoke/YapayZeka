const express = require('express');
const store = require('../db/store');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();
router.use(authMiddleware);

router.get('/', (req, res) => {
  res.json(store.getBrand(req.user.id));
});

router.put('/', (req, res) => {
  store.saveBrand(req.user.id, req.body);
  res.json(req.body);
});

module.exports = router;

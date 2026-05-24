const express = require('express');
const { v4: uuid } = require('uuid');
const store = require('../db/store');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();
router.use(authMiddleware);

router.get('/', (req, res) => {
  res.json(store.getPosts(req.user.id));
});

router.post('/', (req, res) => {
  const post = {
    id: uuid(),
    ...req.body,
    status: 'pending',
    createdAt: new Date().toISOString(),
  };
  const list = store.getPosts(req.user.id);
  list.push(post);
  list.sort((a, b) => new Date(a.scheduledAt) - new Date(b.scheduledAt));
  store.savePosts(req.user.id, list);
  res.status(201).json(post);
});

router.patch('/:id/publish', (req, res) => {
  const list = store.getPosts(req.user.id);
  const post = list.find((p) => p.id === req.params.id);
  if (!post) return res.status(404).json({ error: 'Paylaşım bulunamadı' });
  post.status = 'published';
  store.savePosts(req.user.id, list);
  res.json(post);
});

router.delete('/:id', (req, res) => {
  const list = store.getPosts(req.user.id).filter((p) => p.id !== req.params.id);
  store.savePosts(req.user.id, list);
  res.json({ ok: true });
});

module.exports = router;

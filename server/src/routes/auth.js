const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuid } = require('uuid');
const store = require('../db/store');

const router = express.Router();

function seedAdmin() {
  const users = store.getUsers();
  if (!users.find((u) => u.username === 'admin')) {
    users.push({
      id: uuid(),
      username: 'admin',
      passwordHash: bcrypt.hashSync('1234', 10),
      email: 'admin@ekinciler.com',
    });
    store.saveUsers(users);
  }
}
seedAdmin();

router.post('/register', (req, res) => {
  const { username, password, email } = req.body;
  if (!username || !password) return res.status(400).json({ error: 'Kullanıcı adı ve parola gerekli' });

  const users = store.getUsers();
  if (users.find((u) => u.username === username)) {
    return res.status(409).json({ error: 'Kullanıcı zaten mevcut' });
  }

  const user = {
    id: uuid(),
    username,
    email: email || '',
    passwordHash: bcrypt.hashSync(password, 10),
  };
  users.push(user);
  store.saveUsers(users);

  const token = jwt.sign({ id: user.id, username: user.username }, process.env.JWT_SECRET, { expiresIn: '30d' });
  res.json({ token, user: { id: user.id, username: user.username, email: user.email } });
});

router.post('/login', (req, res) => {
  const { username, password } = req.body;
  const user = store.getUsers().find((u) => u.username === username);
  if (!user || !bcrypt.compareSync(password, user.passwordHash)) {
    return res.status(401).json({ error: 'Kullanıcı adı veya parola geçersiz' });
  }

  const token = jwt.sign({ id: user.id, username: user.username }, process.env.JWT_SECRET, { expiresIn: '30d' });
  res.json({ token, user: { id: user.id, username: user.username, email: user.email } });
});

module.exports = router;

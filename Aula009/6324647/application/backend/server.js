const express = require('express');
const Database = require('better-sqlite3');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;
const DB_PATH = process.env.DB_PATH || './data/portfolio.db';

app.use(express.json());
app.use(express.static(path.join(__dirname, '../frontend')));

// Inicializar banco de dados
const db = new Database(DB_PATH);
db.exec(`
  CREATE TABLE IF NOT EXISTS projects (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    technologies TEXT,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )
`);

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'healthy', uptime: process.uptime(), timestamp: new Date().toISOString() });
});

// Skills estáticas
app.get('/api/skills', (req, res) => {
  res.json(['AWS EC2', 'VPC', 'Docker', 'Node.js', 'Python', 'Linux', 'Git', 'SQL']);
});

// CRUD Projetos
app.get('/api/projects', (req, res) => {
  res.json(db.prepare('SELECT * FROM projects ORDER BY created_at DESC').all());
});

app.post('/api/projects', (req, res) => {
  const { name, technologies, description } = req.body;
  if (!name) return res.status(400).json({ error: 'name é obrigatório' });
  const result = db.prepare(
    'INSERT INTO projects (name, technologies, description) VALUES (?, ?, ?)'
  ).run(name, technologies, description);
  res.status(201).json({ id: result.lastInsertRowid, name, technologies, description });
});

app.put('/api/projects/:id', (req, res) => {
  const { name, technologies, description } = req.body;
  const result = db.prepare(
    'UPDATE projects SET name=?, technologies=?, description=? WHERE id=?'
  ).run(name, technologies, description, req.params.id);
  if (result.changes === 0) return res.status(404).json({ error: 'Projeto não encontrado' });
  res.json({ id: req.params.id, name, technologies, description });
});

app.delete('/api/projects/:id', (req, res) => {
  const result = db.prepare('DELETE FROM projects WHERE id=?').run(req.params.id);
  if (result.changes === 0) return res.status(404).json({ error: 'Projeto não encontrado' });
  res.status(204).send();
});

app.listen(PORT, () => console.log(`API rodando na porta ${PORT}`));

const express = require('express');
const Database = require('better-sqlite3');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;
const DB_PATH = process.env.DB_PATH || './data/portfolio.db';

app.use(express.json());
app.use(express.static(path.join(__dirname, '../frontend')));

// ─── Database Setup ────────────────────────────────────────────────────────────
const db = new Database(DB_PATH);

db.exec(`
  CREATE TABLE IF NOT EXISTS projects (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    name         TEXT NOT NULL,
    description  TEXT NOT NULL,
    technologies TEXT NOT NULL DEFAULT '',
    created_at   TEXT DEFAULT (datetime('now'))
  )
`);

// Seed inicial se vazio
const count = db.prepare('SELECT COUNT(*) as c FROM projects').get();
if (count.c === 0) {
  const insert = db.prepare('INSERT INTO projects (name, description, technologies) VALUES (?, ?, ?)');
  insert.run('Portfólio AWS', 'Sistema de portfólio hospedado na AWS com EC2, VPC e Docker.', 'AWS, Docker, Node.js');
  insert.run('API REST', 'API para gerenciamento de projetos com SQLite.', 'Node.js, Express, SQLite');
}

// ─── Logging Middleware ────────────────────────────────────────────────────────
app.use((req, res, next) => {
  const ts = new Date().toISOString();
  console.log(JSON.stringify({ ts, method: req.method, path: req.path, ip: req.ip }));
  next();
});

// ─── Routes ───────────────────────────────────────────────────────────────────
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', uptime: process.uptime(), timestamp: new Date().toISOString() });
});

app.get('/api/projects', (req, res) => {
  const rows = db.prepare('SELECT * FROM projects ORDER BY created_at DESC').all();
  res.json(rows);
});

app.post('/api/projects', (req, res) => {
  const { name, description, technologies = '' } = req.body;
  if (!name || !description) return res.status(400).json({ error: 'name e description são obrigatórios' });

  const result = db.prepare(
    'INSERT INTO projects (name, description, technologies) VALUES (?, ?, ?)'
  ).run(name, description, technologies);

  const project = db.prepare('SELECT * FROM projects WHERE id = ?').get(result.lastInsertRowid);
  res.status(201).json(project);
});

app.put('/api/projects/:id', (req, res) => {
  const { name, description, technologies } = req.body;
  const { id } = req.params;

  const existing = db.prepare('SELECT * FROM projects WHERE id = ?').get(id);
  if (!existing) return res.status(404).json({ error: 'Projeto não encontrado' });

  db.prepare(
    'UPDATE projects SET name = ?, description = ?, technologies = ? WHERE id = ?'
  ).run(name ?? existing.name, description ?? existing.description, technologies ?? existing.technologies, id);

  res.json(db.prepare('SELECT * FROM projects WHERE id = ?').get(id));
});

app.delete('/api/projects/:id', (req, res) => {
  const result = db.prepare('DELETE FROM projects WHERE id = ?').run(req.params.id);
  if (result.changes === 0) return res.status(404).json({ error: 'Projeto não encontrado' });
  res.status(204).send();
});

// ─── Start ────────────────────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(JSON.stringify({ ts: new Date().toISOString(), event: 'server_start', port: PORT }));
});

const express = require('express');
const mysql = require('mysql2/promise');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.static('../frontend'));

const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'appuser',
  password: process.env.DB_PASSWORD || 'SecurePass123!',
  database: process.env.DB_NAME || 'portfoliodb'
};

async function getDB() {
  return mysql.createConnection(dbConfig);
}

// Health check
app.get('/health', async (req, res) => {
  try {
    const conn = await getDB();
    await conn.ping();
    await conn.end();
    res.json({ status: 'healthy', database: 'connected', server: 'EC2', timestamp: new Date().toISOString() });
  } catch (err) {
    res.status(503).json({ status: 'unhealthy', error: err.message });
  }
});

// Info da instância
app.get('/api/info', (req, res) => {
  res.json({
    message: 'Portfolio API - Luan Teixeira',
    instance: process.env.INSTANCE_ID || 'local',
    region: process.env.AWS_REGION || 'us-east-1'
  });
});

// Listar projetos
app.get('/api/projects', async (req, res) => {
  try {
    const conn = await getDB();
    const [rows] = await conn.execute('SELECT * FROM projects ORDER BY created_at DESC');
    await conn.end();
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Criar projeto
app.post('/api/projects', async (req, res) => {
  const { title, description, tech_stack, github_url } = req.body;
  try {
    const conn = await getDB();
    const [result] = await conn.execute(
      'INSERT INTO projects (title, description, tech_stack, github_url) VALUES (?, ?, ?, ?)',
      [title, description, tech_stack, github_url]
    );
    await conn.end();
    res.status(201).json({ id: result.insertId, title, description, tech_stack, github_url });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Deletar projeto
app.delete('/api/projects/:id', async (req, res) => {
  try {
    const conn = await getDB();
    await conn.execute('DELETE FROM projects WHERE id = ?', [req.params.id]);
    await conn.end();
    res.json({ message: 'Projeto removido' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Habilidades
app.get('/api/skills', async (req, res) => {
  try {
    const conn = await getDB();
    const [rows] = await conn.execute('SELECT * FROM skills ORDER BY category');
    await conn.end();
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Portfolio API rodando na porta ${PORT}`);
});

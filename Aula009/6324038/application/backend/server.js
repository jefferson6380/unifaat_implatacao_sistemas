const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// CORS restrito à origem da própria aplicação
app.use(cors({
    origin: process.env.ALLOWED_ORIGIN || `http://localhost`,
    methods: ['GET', 'POST', 'PUT', 'DELETE']
}));
app.use(express.json());

// Proteção CSRF via token no header para rotas de escrita
const CSRF_TOKEN = process.env.CSRF_TOKEN || 'tf09-csrf-token';
function csrfProtect(req, res, next) {
    if (['POST', 'PUT', 'DELETE'].includes(req.method)) {
        if (req.headers['x-csrf-token'] !== CSRF_TOKEN) {
            return res.status(403).json({ error: 'CSRF token inválido' });
        }
    }
    next();
}
app.use(csrfProtect);

const dbConfig = {
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'appuser',
    password: process.env.DB_PASSWORD || 'SecurePass123!',
    database: process.env.DB_NAME || 'portfolio_db',
    waitForConnections: true,
    connectionLimit: 10
};

const pool = mysql.createPool(dbConfig);

// ── Health Check ──────────────────────────────────────────────────────────────
app.get('/health', async (req, res) => {
    try {
        await pool.query('SELECT 1');
        res.json({
            status: 'healthy',
            timestamp: new Date().toISOString(),
            database: 'connected',
            instance: process.env.INSTANCE_ID || 'local',
            region: process.env.AWS_REGION || 'us-east-1'
        });
    } catch (err) {
        res.status(503).json({ status: 'unhealthy', error: err.message });
    }
});

// ── Projects CRUD ─────────────────────────────────────────────────────────────
app.get('/api/projects', async (req, res) => {
    const [rows] = await pool.query('SELECT * FROM projects ORDER BY created_at DESC');
    res.json(rows);
});

app.post('/api/projects', async (req, res) => {
    const { title, description, tech_stack, github_url } = req.body;
    if (!title) return res.status(400).json({ error: 'title é obrigatório' });
    const [result] = await pool.query(
        'INSERT INTO projects (title, description, tech_stack, github_url) VALUES (?, ?, ?, ?)',
        [title, description, tech_stack, github_url]
    );
    res.status(201).json({ id: result.insertId, title, description, tech_stack, github_url });
});

app.put('/api/projects/:id', async (req, res) => {
    const { title, description, tech_stack, github_url } = req.body;
    await pool.query(
        'UPDATE projects SET title=?, description=?, tech_stack=?, github_url=? WHERE id=?',
        [title, description, tech_stack, github_url, req.params.id]
    );
    res.json({ message: 'Projeto atualizado' });
});

app.delete('/api/projects/:id', async (req, res) => {
    await pool.query('DELETE FROM projects WHERE id=?', [req.params.id]);
    res.json({ message: 'Projeto removido' });
});

// ── Skills ────────────────────────────────────────────────────────────────────
app.get('/api/skills', async (req, res) => {
    const [rows] = await pool.query('SELECT * FROM skills ORDER BY category, name');
    res.json(rows);
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`[${new Date().toISOString()}] Servidor rodando na porta ${PORT}`);
});

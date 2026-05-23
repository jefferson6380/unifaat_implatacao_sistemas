const express = require('express');
const cors = require('cors');
const sqlite3 = require('sqlite3').verbose();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Initialize SQLite DB
const db = new sqlite3.Database('./portfolio.db');

db.serialize(() => {
    db.run("CREATE TABLE IF NOT EXISTS projects (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, description TEXT)");
    
    // Seed initial data if empty
    db.get("SELECT COUNT(*) AS count FROM projects", (err, row) => {
        if (row.count === 0) {
            const stmt = db.prepare("INSERT INTO projects (title, description) VALUES (?, ?)");
            stmt.run('Projeto Cloud', 'Infraestrutura AWS com Terraform e Scripts Bash');
            stmt.run('Portfolio Web', 'SPA isolado com Node.js backend SQLite');
            stmt.finalize();
        }
    });
});

// Health Check Endpoint
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'UP', database: 'SQLite Connected', timestamp: new Date() });
});

// GET all projects
app.get('/api/projects', (req, res) => {
    db.all("SELECT * FROM projects", [], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
    });
});

// POST new project
app.post('/api/projects', (req, res) => {
    const { title, description } = req.body;
    db.run("INSERT INTO projects (title, description) VALUES (?, ?)", [title, description], function(err) {
        if (err) return res.status(500).json({ error: err.message });
        res.status(201).json({ id: this.lastID, title, description });
    });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Backend server running on http://0.0.0.0:${PORT}`);
});

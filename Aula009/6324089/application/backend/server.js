const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());

const dbConfig = {
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME
};

// Health Check
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', instance: process.env.INSTANCE_ID });
});

// Listar Projetos (Parte do seu Portfólio)
app.get('/api/projects', async (req, res) => {
  // Aqui você pode retornar dados do MySQL ou um JSON estático para teste inicial
  res.json([
    { id: 1, title: "Agenda Financeira", tech: "Node.js & Docker" },
    { id: 2, title: "Infra AWS EC2", tech: "AWS CLI" },
    { id: 3, title: "Sistema de Gerenciamento Escolar", tech: "Javascript & Node.js" }
  ]);
});

app.listen(3000, () => console.log('API running on port 3000'));
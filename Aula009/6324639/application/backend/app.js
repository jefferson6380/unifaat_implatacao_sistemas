const express = require('express');
const app = express();

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.get('/projects', (req, res) => {
  res.json([{ nome: "Projeto AWS" }]);
});

app.listen(3000, () => console.log("Rodando"));
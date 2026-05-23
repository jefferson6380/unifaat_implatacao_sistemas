CREATE TABLE IF NOT EXISTS projetos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(100) NOT NULL,
  descricao TEXT
);
INSERT INTO projetos (nome, descricao) VALUES ('Projeto Exemplo', 'Descrição do projeto exemplo.');

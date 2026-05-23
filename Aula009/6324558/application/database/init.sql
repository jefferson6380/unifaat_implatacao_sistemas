CREATE TABLE IF NOT EXISTS projects (
    id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    tech_stack VARCHAR(100),
    url_repo VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS skills ( 
    id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    period VARCHAR(50),
    type VARCHAR(20) 
);



INSERT INTO projects (title, description, tech_stack, url_repo) VALUES 
('Sistema de Portfólio', 'Deploy automatizado na AWS com Docker', 'Docker, AWS, Node.js', 'https://github.com/usuario/tf09'),
('API de Gestão', 'CRUD completo integrado com Postgres', 'Node.js, Express, Postgres', NULL);

INSERT INTO skills (title, description, period, type) VALUES 
('Estudante de ADS', 'UniFAAT - Implementação de Sistemas', '2024 - Atual', 'Acadêmico'),
('Desenvolvedor Full Stack', 'Projeto Freelance de E-commerce', '2023 - 2024', 'Profissional');
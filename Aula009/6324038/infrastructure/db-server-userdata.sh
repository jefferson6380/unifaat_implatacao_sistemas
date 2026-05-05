#!/bin/bash
# User Data - Database Server (Amazon Linux 2)
yum update -y
yum install -y mariadb-server

systemctl start mariadb
systemctl enable mariadb

# Configuração inicial do banco
mysql -e "CREATE DATABASE IF NOT EXISTS portfolio_db;"
mysql -e "CREATE USER 'appuser'@'%' IDENTIFIED BY 'SecurePass123!';"
mysql -e "GRANT ALL PRIVILEGES ON portfolio_db.* TO 'appuser'@'%';"
mysql -e "FLUSH PRIVILEGES;"

# Schema inicial
mysql portfolio_db << 'SQL'
CREATE TABLE IF NOT EXISTS projects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    tech_stack VARCHAR(200),
    github_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS skills (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    category VARCHAR(50),
    level ENUM('Básico','Intermediário','Avançado') DEFAULT 'Básico'
);

INSERT INTO projects (title, description, tech_stack) VALUES
('TF09 - Portfolio AWS', 'Portfólio pessoal hospedado na AWS com EC2, VPC e Security Groups', 'Node.js, MySQL, Docker, AWS EC2');

INSERT INTO skills (name, category, level) VALUES
('AWS EC2', 'Cloud', 'Intermediário'),
('Docker', 'DevOps', 'Intermediário'),
('Node.js', 'Backend', 'Intermediário'),
('MySQL', 'Database', 'Básico');
SQL

echo "Database Server setup completed at $(date)" > /var/log/user-data.log

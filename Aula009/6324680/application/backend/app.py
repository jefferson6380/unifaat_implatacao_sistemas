from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
import sqlite3
import os
import logging

app = Flask(__name__, static_folder='../frontend', static_url_path='')
CORS(app)

logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')
logger = logging.getLogger(__name__)

DB_PATH = os.getenv('DB_PATH', 'portfolio.db')


def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    conn = get_db()
    conn.executescript('''
        CREATE TABLE IF NOT EXISTS projects (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            tech_stack TEXT,
            repo_url TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        CREATE TABLE IF NOT EXISTS skills (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            level TEXT NOT NULL,
            category TEXT NOT NULL
        );
        INSERT OR IGNORE INTO skills (id, name, level, category) VALUES
            (1, 'Python', 'Intermediário', 'Backend'),
            (2, 'JavaScript', 'Intermediário', 'Frontend'),
            (3, 'AWS', 'Básico', 'Cloud'),
            (4, 'Docker', 'Básico', 'DevOps'),
            (5, 'SQL', 'Intermediário', 'Database'),
            (6, 'Git', 'Intermediário', 'Ferramentas');
    ''')
    conn.commit()
    conn.close()


# ---------- Health Check ----------

@app.route('/health')
def health():
    return jsonify({'status': 'ok', 'aluno': 'Vitor Pinheiro Guimaraes', 'ra': '6324680'})


# ---------- Frontend ----------

@app.route('/')
def index():
    return send_from_directory(app.static_folder, 'index.html')


# ---------- Projects API ----------

@app.route('/api/projects', methods=['GET'])
def list_projects():
    conn = get_db()
    projects = conn.execute('SELECT * FROM projects ORDER BY created_at DESC').fetchall()
    conn.close()
    logger.info('GET /api/projects - %d projetos retornados', len(projects))
    return jsonify([dict(p) for p in projects])


@app.route('/api/projects', methods=['POST'])
def create_project():
    data = request.get_json()
    if not data or not data.get('name'):
        return jsonify({'error': 'Campo "name" obrigatório'}), 400
    conn = get_db()
    cursor = conn.execute(
        'INSERT INTO projects (name, description, tech_stack, repo_url) VALUES (?, ?, ?, ?)',
        (data['name'], data.get('description', ''), data.get('tech_stack', ''), data.get('repo_url', ''))
    )
    conn.commit()
    project_id = cursor.lastrowid
    project = dict(conn.execute('SELECT * FROM projects WHERE id = ?', (project_id,)).fetchone())
    conn.close()
    logger.info('POST /api/projects - criado id=%d', project_id)
    return jsonify(project), 201


@app.route('/api/projects/<int:project_id>', methods=['PUT'])
def update_project(project_id):
    data = request.get_json()
    conn = get_db()
    conn.execute(
        'UPDATE projects SET name=?, description=?, tech_stack=?, repo_url=? WHERE id=?',
        (data.get('name'), data.get('description'), data.get('tech_stack'), data.get('repo_url'), project_id)
    )
    conn.commit()
    project = conn.execute('SELECT * FROM projects WHERE id = ?', (project_id,)).fetchone()
    conn.close()
    if not project:
        return jsonify({'error': 'Projeto não encontrado'}), 404
    return jsonify(dict(project))


@app.route('/api/projects/<int:project_id>', methods=['DELETE'])
def delete_project(project_id):
    conn = get_db()
    conn.execute('DELETE FROM projects WHERE id = ?', (project_id,))
    conn.commit()
    conn.close()
    logger.info('DELETE /api/projects/%d', project_id)
    return jsonify({'message': 'Projeto removido'})


# ---------- Skills API ----------

@app.route('/api/skills', methods=['GET'])
def list_skills():
    conn = get_db()
    skills = conn.execute('SELECT * FROM skills ORDER BY category, name').fetchall()
    conn.close()
    return jsonify([dict(s) for s in skills])


if __name__ == '__main__':
    init_db()
    port = int(os.getenv('PORT', 5000))
    debug = os.getenv('FLASK_ENV') == 'development'
    logger.info('Iniciando servidor na porta %d', port)
    app.run(host='0.0.0.0', port=port, debug=debug)

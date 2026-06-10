from flask import Flask, jsonify, request
from flask_cors import CORS
from datetime import datetime

app = Flask(__name__)
CORS(app)

projects = [
    {"id": 1, "name": "Portfolio AWS", "description": "Deploy de aplicacao na AWS com EC2", "tech": "AWS, Docker, Python"},
    {"id": 2, "name": "API REST", "description": "API com Flask e PostgreSQL", "tech": "Python, Flask, PostgreSQL"}
]

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "timestamp": datetime.now().isoformat()})

@app.route('/api/projects', methods=['GET'])
def get_projects():
    return jsonify(projects)

@app.route('/api/projects', methods=['POST'])
def add_project():
    data = request.json
    data['id'] = len(projects) + 1
    projects.append(data)
    return jsonify(data), 201

@app.route('/api/projects/<int:id>', methods=['DELETE'])
def delete_project(id):
    global projects
    projects = [p for p in projects if p['id'] != id]
    return jsonify({"message": "Projeto deletado"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

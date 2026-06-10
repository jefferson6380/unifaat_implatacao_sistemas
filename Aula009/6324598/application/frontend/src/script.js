// Script para o Portfólio de Yago (TF09)

// Define a URL da API. No ambiente Docker/AWS, o Nginx redireciona /api para o backend.
// Em ambiente de teste local (sem Nginx), tenta conectar direto na porta 8000.
const API_URL = '/api'; 

document.addEventListener('DOMContentLoaded', () => {
    checkAPIHealth();
    loadProjects();
    
    // Configuração dos formulários
    const projForm = document.getElementById('project-form');
    if (projForm) projForm.addEventListener('submit', addProject);

    const expForm = document.getElementById('experience-form');
    if (expForm) expForm.addEventListener('submit', addExperience);
});

async function checkAPIHealth() {
    const statusDiv = document.getElementById('health-status');
    if (!statusDiv) return;

    try {
        // Tenta primeiro via Nginx (/api/health)
        let response;
        try {
            // No Nginx, mapeamos /health direto para o backend:8000/health
            response = await fetch('/health', { signal: AbortSignal.timeout(3000) });
        } catch (e) {
            // Se falhar (ex: teste local), tenta direto no backend
            response = await fetch('http://localhost:8000/health', { signal: AbortSignal.timeout(3000) });
        }

        if (response && response.ok) {
            statusDiv.textContent = '🟢 Infraestrutura Online (AWS EC2)';
            statusDiv.className = 'status-success';
        } else {
            throw new Error('Backend não respondeu com OK');
        }
    } catch (e) {
        console.error('Erro de saúde da API:', e);
        statusDiv.textContent = '🔴 Erro de Conexão (Verifique o Docker)';
        statusDiv.className = 'status-error';
    }
}

async function loadProjects() {
    const list = document.getElementById('projects-list-placeholder');
    if (!list) return;

    try {
        const res = await fetch(`${API_URL}/projects`).catch(() => fetch('http://localhost:8000/projects'));
        if (!res.ok) return;
        
        const projects = await res.json();
        
        // Limpa apenas se houver dados vindo do banco
        if (projects.length > 0) {
            projects.forEach(p => {
                const card = document.createElement('div');
                card.className = 'project-card';
                card.innerHTML = `
                    <div class="project-info">
                        <span class="tag">Banco de Dados</span>
                        <h3>${p.title}</h3>
                        <p>${p.description}</p>
                        ${p.url ? `<a href="${p.url}" target="_blank" class="btn-project">Link do Projeto →</a>` : ''}
                    </div>
                `;
                list.appendChild(card);
            });
        }
    } catch (e) {
        console.warn('Não foi possível carregar projetos dinâmicos.');
    }
}

async function addProject(e) {
    e.preventDefault();
    const project = {
        title: document.getElementById('proj-title').value,
        description: document.getElementById('proj-desc').value,
        url: document.getElementById('proj-url').value
    };

    try {
        const res = await fetch(`${API_URL}/projects`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(project)
        });
        if (res.ok) {
            alert('Projeto salvo com sucesso!');
            location.reload();
        }
    } catch (e) { 
        alert('Erro ao salvar projeto no banco de dados.'); 
    }
}

async function addExperience(e) {
    e.preventDefault();
    const experience = {
        role: document.getElementById('exp-role').value,
        company: document.getElementById('exp-company').value,
        period: document.getElementById('exp-period').value,
        description: document.getElementById('exp-desc').value
    };

    try {
        const res = await fetch(`${API_URL}/experiences`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(experience)
        });
        if (res.ok) {
            alert('Experiência salva com sucesso!');
            location.reload();
        }
    } catch (e) { 
        alert('Erro ao salvar experiência.'); 
    }
}

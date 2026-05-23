const apiBase = '/api';

document.addEventListener('DOMContentLoaded', () => {
    checkHealth();
    fetchProjects();
    fetchExperiences();

    // Lógica de Create (POST)
    document.getElementById('form-projeto').addEventListener('submit', async (e) => {
        e.preventDefault();
        const data = {
            title: document.getElementById('title').value,
            description: document.getElementById('description').value,
            tech_stack: document.getElementById('tech_stack').value,
            url_repo: document.getElementById('url_repo').value
        };

        const res = await fetch(`${apiBase}/projects`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });

        if (res.ok) {
            e.target.reset();
            fetchProjects();
        }
    });
});

async function checkHealth() {
    const el = document.getElementById('status-indicator');
    try {
        const res = await fetch('/health');
        const data = await res.json();
        el.innerText = `ONLINE (${data.database})`;
        el.style.color = "var(--success)";
    } catch {
        el.innerText = "OFFLINE";
        el.style.color = "var(--error)";
    }
}

async function fetchProjects() {
    const res = await fetch(`${apiBase}/projects`);
    const projects = await res.json();
    const container = document.getElementById('projects-grid');
    container.innerHTML = projects.map(p => `
        <div class="card">
            <h3>${p.title}</h3>
            <p>${p.description}</p>
            <p><strong>Techs:</strong> ${p.tech_stack || 'N/A'}</p>
            ${p.url_repo ? `<a href="${p.url_repo}" target="_blank">Ver Repo</a>` : ''}
        </div>
    `).join('');
}

async function fetchExperiences() {
    const res = await fetch(`${apiBase}/skills`); // Note: Rota igual ao seu init.sql
    const experiences = await res.json();
    const container = document.getElementById('experience-list');
    container.innerHTML = experiences.map(e => `
        <div class="card" style="border-left-color: #64748b">
            <h4>${e.title}</h4>
            <p>${e.description}</p>
            <small>${e.period} | <strong>${e.type}</strong></small>
        </div>
    `).join('');
}
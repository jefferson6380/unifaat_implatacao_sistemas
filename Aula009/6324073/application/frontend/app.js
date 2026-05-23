document.addEventListener('DOMContentLoaded', () => {
    const projectList = document.getElementById('project-list');

    fetch('/api/projects')
        .then(response => response.json())
        .then(data => {
            projectList.innerHTML = '';
            if (data.length === 0) {
                projectList.innerHTML = '<p>No projects found.</p>';
                return;
            }
            data.forEach(project => {
                const div = document.createElement('div');
                div.className = 'project-item';
                div.innerHTML = `<h3>${project.name}</h3><p>${project.description}</p>`;
                projectList.appendChild(div);
            });
        })
        .catch(err => {
            console.error('Error fetching projects:', err);
            projectList.innerHTML = '<p>Error loading projects from API.</p>';
        });
});

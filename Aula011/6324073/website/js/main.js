/* ============================================================
   main.js — Navegação, animações e formulário de contato
   ============================================================ */

// URL do API Gateway (preencher após deploy)
const API_URL = 'https://okadj41b1e.execute-api.us-east-1.amazonaws.com/prod';

/* ------ Navbar: scroll shadow e toggle mobile ------ */
const navbar   = document.getElementById('navbar');
const toggle   = document.getElementById('navToggle');
const navLinks = document.getElementById('navLinks');

window.addEventListener('scroll', () => {
  navbar.classList.toggle('scrolled', window.scrollY > 20);
});

if (toggle) {
  toggle.addEventListener('click', () => {
    navLinks.classList.toggle('open');
    toggle.setAttribute('aria-expanded', navLinks.classList.contains('open'));
  });

  document.addEventListener('click', (e) => {
    if (!navbar.contains(e.target)) {
      navLinks.classList.remove('open');
    }
  });
}

/* ------ Animação de entrada (IntersectionObserver) ------ */
const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add('visible');
      observer.unobserve(entry.target);
    }
  });
}, { threshold: 0.1 });

document.querySelectorAll('.fade-in').forEach(el => observer.observe(el));

/* ------ Formulário de contato ------ */
const contactForm = document.getElementById('contactForm');

if (contactForm) {
  const submitBtn  = document.getElementById('submitBtn');
  const formStatus = document.getElementById('formStatus');

  contactForm.addEventListener('submit', async (e) => {
    e.preventDefault();

    const nome     = document.getElementById('nome').value.trim();
    const email    = document.getElementById('email').value.trim();
    const assunto  = document.getElementById('assunto').value;
    const mensagem = document.getElementById('mensagem').value.trim();

    /* Validação básica no cliente */
    if (!nome || !email || !assunto || !mensagem) {
      showStatus('Por favor, preencha todos os campos obrigatórios.', 'error');
      return;
    }

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      showStatus('E-mail inválido. Verifique e tente novamente.', 'error');
      return;
    }

    if (mensagem.length < 20) {
      showStatus('Mensagem muito curta (mínimo 20 caracteres).', 'error');
      return;
    }

    submitBtn.disabled = true;
    submitBtn.textContent = 'Enviando...';

    try {
      const response = await fetch(`${API_URL}/contact`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ nome, email, assunto, mensagem }),
      });

      if (!response.ok) throw new Error(`HTTP ${response.status}`);

      showStatus('Mensagem enviada com sucesso! Responderei em até 24h.', 'success');
      contactForm.reset();
    } catch (err) {
      console.error('Erro ao enviar formulário:', err);
      showStatus(
        'Erro ao enviar. Tente novamente ou envie diretamente para leosano2006@gmail.com.',
        'error'
      );
    } finally {
      submitBtn.disabled = false;
      submitBtn.textContent = 'Enviar Mensagem';
    }
  });

  function showStatus(msg, type) {
    formStatus.textContent = msg;
    formStatus.className = `form-status ${type}`;
    formStatus.style.display = 'block';
    formStatus.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
  }
}

/* ------ Toast genérico ------ */
function showToast(msg, duration = 3500) {
  const toast = document.createElement('div');
  toast.className = 'toast';
  toast.textContent = msg;
  document.body.appendChild(toast);

  requestAnimationFrame(() => toast.classList.add('show'));

  setTimeout(() => {
    toast.classList.remove('show');
    setTimeout(() => toast.remove(), 300);
  }, duration);
}

/* Expor para outros scripts */
window.showToast = showToast;

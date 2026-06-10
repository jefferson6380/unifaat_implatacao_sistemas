'use strict';

// API_ENDPOINT será substituído pelo endpoint real do API Gateway após o deploy
const API_ENDPOINT = 'https://uz0yosc5ub.execute-api.us-east-1.amazonaws.com/prod/contact';

const form       = document.getElementById('contactForm');
const status     = document.getElementById('formStatus');
const submitBtn  = document.getElementById('submitBtn');
const submitText = document.getElementById('submitText');
const submitSpn  = document.getElementById('submitSpinner');

if (!form) throw new Error('contactForm not found');

function showStatus(type, msg) {
  status.className = `form-status ${type}`;
  status.textContent = msg;
  status.style.display = 'block';
  status.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
}

function setLoading(loading) {
  submitBtn.disabled = loading;
  submitText.textContent = loading ? 'Enviando...' : 'Enviar Mensagem';
  submitSpn.hidden = !loading;
}

function validateForm(data) {
  if (!data.name || data.name.trim().length < 2)
    return 'Por favor, informe seu nome completo.';
  if (!data.email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(data.email))
    return 'Por favor, informe um e-mail válido.';
  if (!data.subject)
    return 'Por favor, selecione um assunto.';
  if (!data.message || data.message.trim().length < 10)
    return 'A mensagem deve ter pelo menos 10 caracteres.';
  // honeypot
  if (data.website)
    return null; // silently ignore bots
  return null;
}

form.addEventListener('submit', async e => {
  e.preventDefault();
  status.style.display = 'none';

  const fd = new FormData(form);
  const data = Object.fromEntries(fd.entries());

  const error = validateForm(data);
  if (error) { showStatus('error', error); return; }

  // Honeypot: bot preencheu campo oculto
  if (data.website) return;

  setLoading(true);

  try {
    // Se API_ENDPOINT não foi configurado ainda, simula sucesso (modo demo)
    if (API_ENDPOINT === 'REPLACE_WITH_API_GATEWAY_URL') {
      await new Promise(r => setTimeout(r, 1200)); // simula latência
      form.reset();
      showStatus('success', '✅ Mensagem enviada com sucesso! Responderei em breve.');
      return;
    }

    const res = await fetch(API_ENDPOINT, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name:    data.name.trim(),
        email:   data.email.trim().toLowerCase(),
        subject: data.subject,
        message: data.message.trim(),
      }),
    });

    if (!res.ok) {
      const body = await res.json().catch(() => ({}));
      throw new Error(body.message || `Erro ${res.status}`);
    }

    form.reset();
    showStatus('success', '✅ Mensagem enviada com sucesso! Responderei em breve.');
  } catch (err) {
    console.error('Contact form error:', err);
    showStatus('error', '❌ Não foi possível enviar a mensagem. Tente novamente ou entre em contato por e-mail.');
  } finally {
    setLoading(false);
  }
});

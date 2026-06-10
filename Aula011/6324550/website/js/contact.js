// URL da API Gateway (atualizar após deploy)
const API_URL = 'https://REPLACE_WITH_API_GATEWAY_URL/prod/contact';

const form = document.getElementById('contactForm');
const feedback = document.getElementById('formFeedback');
const submitBtn = document.getElementById('submitBtn');
const btnText = document.getElementById('btnText');
const btnLoader = document.getElementById('btnLoader');

function validateField(id, errorId, condition, msg) {
  const el = document.getElementById(id);
  const err = document.getElementById(errorId);
  if (condition(el.value.trim())) {
    el.classList.remove('invalid');
    err.textContent = '';
    return true;
  }
  el.classList.add('invalid');
  err.textContent = msg;
  return false;
}

function validateForm() {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return [
    validateField('name', 'nameError', v => v.length >= 2, 'Nome deve ter ao menos 2 caracteres.'),
    validateField('email', 'emailError', v => emailRegex.test(v), 'Informe um e-mail válido.'),
    validateField('subject', 'subjectError', v => v.length >= 3, 'Assunto deve ter ao menos 3 caracteres.'),
    validateField('message', 'messageError', v => v.length >= 10, 'Mensagem deve ter ao menos 10 caracteres.')
  ].every(Boolean);
}

form.addEventListener('submit', async (e) => {
  e.preventDefault();
  feedback.className = 'form-feedback';
  feedback.textContent = '';

  if (!validateForm()) return;

  submitBtn.disabled = true;
  btnText.textContent = 'Enviando...';
  btnLoader.hidden = false;

  const payload = {
    name: document.getElementById('name').value.trim(),
    email: document.getElementById('email').value.trim(),
    subject: document.getElementById('subject').value.trim(),
    message: document.getElementById('message').value.trim(),
    timestamp: new Date().toISOString()
  };

  try {
    const res = await fetch(API_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    if (res.ok) {
      feedback.textContent = '✅ Mensagem enviada com sucesso! Retornarei em breve.';
      feedback.className = 'form-feedback success';
      form.reset();
    } else {
      throw new Error(`HTTP ${res.status}`);
    }
  } catch (err) {
    feedback.textContent = '❌ Erro ao enviar a mensagem. Tente novamente ou entre em contato pelo LinkedIn.';
    feedback.className = 'form-feedback error';
    console.error('Contact form error:', err);
  } finally {
    submitBtn.disabled = false;
    btnText.textContent = 'Enviar Mensagem';
    btnLoader.hidden = true;
  }
});

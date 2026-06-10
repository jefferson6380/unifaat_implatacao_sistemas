// API Gateway endpoint — substituir após deploy
const API_ENDPOINT = 'https://SEU_API_ID.execute-api.us-east-1.amazonaws.com/prod';
const UPLOAD_ENDPOINT = `${API_ENDPOINT}/upload`;
const CONTACT_ENDPOINT = `${API_ENDPOINT}/contact`;

// ── HAMBURGER MENU ──────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  const hamburger = document.getElementById('hamburger');
  const navLinks = document.querySelector('.nav-links');

  if (hamburger && navLinks) {
    hamburger.addEventListener('click', () => {
      navLinks.classList.toggle('open');
    });
    hamburger.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' || e.key === ' ') navLinks.classList.toggle('open');
    });
  }

  // Fechar menu ao clicar em link
  navLinks?.querySelectorAll('a').forEach(link => {
    link.addEventListener('click', () => navLinks.classList.remove('open'));
  });

  // Lazy loading fallback para browsers antigos
  if ('loading' in HTMLImageElement.prototype === false) {
    document.querySelectorAll('img[loading="lazy"]').forEach(img => {
      const observer = new IntersectionObserver(([entry]) => {
        if (entry.isIntersecting) {
          img.src = img.dataset.src || img.src;
          observer.disconnect();
        }
      });
      observer.observe(img);
    });
  }

  initUpload();
  initContactForm();
  initFileAttach();
});

// ── UPLOAD DE IMAGEM (projetos.html) ────────────────────
function initUpload() {
  const area = document.getElementById('uploadArea');
  const input = document.getElementById('fileInput');
  const preview = document.getElementById('uploadPreview');
  const previewImg = document.getElementById('previewImg');
  const uploadBtn = document.getElementById('uploadBtn');
  const feedback = document.getElementById('uploadFeedback');

  if (!area || !input) return;

  // Drag & drop
  area.addEventListener('dragover', (e) => {
    e.preventDefault();
    area.classList.add('dragover');
  });
  area.addEventListener('dragleave', () => area.classList.remove('dragover'));
  area.addEventListener('drop', (e) => {
    e.preventDefault();
    area.classList.remove('dragover');
    const file = e.dataTransfer.files[0];
    if (file) handleFileSelect(file);
  });

  input.addEventListener('change', () => {
    if (input.files[0]) handleFileSelect(input.files[0]);
  });

  function handleFileSelect(file) {
    if (!file.type.startsWith('image/')) {
      showFeedback(feedback, 'Apenas imagens são permitidas.', 'error');
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      showFeedback(feedback, 'Arquivo muito grande. Máximo: 5MB.', 'error');
      return;
    }

    const reader = new FileReader();
    reader.onload = (e) => {
      previewImg.src = e.target.result;
      preview.style.display = 'block';
    };
    reader.readAsDataURL(file);
    uploadBtn && (uploadBtn._file = file);
  }

  uploadBtn?.addEventListener('click', async () => {
    const file = uploadBtn._file;
    if (!file) return;

    uploadBtn.disabled = true;
    uploadBtn.textContent = 'Enviando...';

    try {
      // Solicitar presigned URL
      const res = await fetch(UPLOAD_ENDPOINT, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ filename: file.name, contentType: file.type }),
      });

      if (!res.ok) throw new Error('Erro ao obter URL de upload');
      const { uploadUrl } = await res.json();

      // Upload direto para S3
      await fetch(uploadUrl, {
        method: 'PUT',
        headers: { 'Content-Type': file.type },
        body: file,
      });

      showFeedback(feedback, '✅ Imagem enviada e processada com sucesso!', 'success');
      preview.style.display = 'none';
      input.value = '';
    } catch (err) {
      showFeedback(feedback, `❌ Erro: ${err.message}`, 'error');
    } finally {
      uploadBtn.disabled = false;
      uploadBtn.textContent = 'Fazer Upload';
    }
  });
}

// ── FORMULÁRIO DE CONTATO ────────────────────────────────
function initContactForm() {
  const form = document.getElementById('contactForm');
  if (!form) return;

  form.addEventListener('submit', async (e) => {
    e.preventDefault();

    const feedback = document.getElementById('formFeedback');
    const submitBtn = document.getElementById('submitBtn');

    const nome = form.nome.value.trim();
    const email = form.email.value.trim();
    const assunto = form.assunto.value.trim();
    const mensagem = form.mensagem.value.trim();

    if (!nome || !email || !assunto || !mensagem) {
      showFeedback(feedback, 'Preencha todos os campos obrigatórios.', 'error');
      return;
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      showFeedback(feedback, 'E-mail inválido.', 'error');
      return;
    }
    if (mensagem.length < 10) {
      showFeedback(feedback, 'Mensagem muito curta (mínimo 10 caracteres).', 'error');
      return;
    }

    submitBtn.disabled = true;
    submitBtn.textContent = 'Enviando...';
    feedback.style.display = 'none';

    try {
      const res = await fetch(CONTACT_ENDPOINT, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ nome, email, assunto, mensagem }),
      });

      const data = await res.json();

      if (res.ok) {
        showFeedback(feedback, '✅ Mensagem enviada! Responderei em breve.', 'success');
        form.reset();
      } else {
        showFeedback(feedback, `❌ Erro: ${data.message || 'Tente novamente.'}`, 'error');
      }
    } catch (err) {
      showFeedback(feedback, '❌ Erro de conexão. Verifique sua internet.', 'error');
    } finally {
      submitBtn.disabled = false;
      submitBtn.textContent = 'Enviar Mensagem';
    }
  });
}

// ── ANEXO NO FORMULÁRIO DE CONTATO ──────────────────────
function initFileAttach() {
  const areaContact = document.getElementById('uploadAreaContact');
  const fileAttach = document.getElementById('fileAttach');
  const attachName = document.getElementById('attachName');

  if (!fileAttach) return;

  fileAttach.addEventListener('change', () => {
    const file = fileAttach.files[0];
    if (file) {
      attachName.textContent = `📎 ${file.name}`;
      attachName.style.display = 'block';
    }
  });

  areaContact?.addEventListener('dragover', (e) => {
    e.preventDefault();
    areaContact.classList.add('dragover');
  });
  areaContact?.addEventListener('dragleave', () => areaContact.classList.remove('dragover'));
  areaContact?.addEventListener('drop', (e) => {
    e.preventDefault();
    areaContact.classList.remove('dragover');
    const file = e.dataTransfer.files[0];
    if (file) {
      const dt = new DataTransfer();
      dt.items.add(file);
      fileAttach.files = dt.files;
      attachName.textContent = `📎 ${file.name}`;
      attachName.style.display = 'block';
    }
  });
}

// ── UTILITÁRIO ───────────────────────────────────────────
function showFeedback(el, msg, type) {
  if (!el) return;
  el.textContent = msg;
  el.className = `form-feedback ${type}`;
  el.style.display = 'block';
  setTimeout(() => {
    if (type === 'success') el.style.display = 'none';
  }, 6000);
}

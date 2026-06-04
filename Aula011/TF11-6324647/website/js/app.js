// ── CONFIG ─────────────────────────────────────────────────────
// Substitua pela URL do seu API Gateway após o deploy
const API_URL = 'https://<api-id>.execute-api.us-east-1.amazonaws.com/prod/contact';

// ── Formulário de Contato ──────────────────────────────────────
const form = document.getElementById('contact-form');
const status = document.getElementById('form-status');

if (form) {
  form.addEventListener('submit', async (e) => {
    e.preventDefault();

    const btn = form.querySelector('button[type="submit"]');
    const originalText = btn.textContent;
    btn.textContent = 'Enviando...';
    btn.disabled = true;

    const payload = {
      name: form.name.value.trim(),
      email: form.email.value.trim(),
      subject: form.subject.value.trim(),
      message: form.message.value.trim(),
      timestamp: new Date().toISOString()
    };

    try {
      const res = await fetch(API_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });

      if (!res.ok) throw new Error('Erro no servidor');

      status.className = 'success';
      status.textContent = '✓ Mensagem enviada com sucesso! Responderei em breve.';
      form.reset();
    } catch {
      status.className = 'error';
      status.textContent = '✗ Erro ao enviar. Tente novamente ou envie um email diretamente.';
    } finally {
      btn.textContent = originalText;
      btn.disabled = false;
    }
  });
}

// ── Upload de Imagens ──────────────────────────────────────────
const UPLOAD_API = 'https://<api-id>.execute-api.us-east-1.amazonaws.com/prod/upload';
const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
const MAX_SIZE_MB = 5;

const uploadArea = document.getElementById('upload-area');
const fileInput = document.getElementById('file-input');
const previewGrid = document.getElementById('preview-grid');

function handleFiles(files) {
  [...files].forEach(file => {
    if (!ALLOWED_TYPES.includes(file.type)) {
      alert(`Tipo não permitido: ${file.name}. Use JPG, PNG, WebP ou GIF.`);
      return;
    }
    if (file.size > MAX_SIZE_MB * 1024 * 1024) {
      alert(`Arquivo muito grande: ${file.name}. Máximo ${MAX_SIZE_MB}MB.`);
      return;
    }

    const reader = new FileReader();
    reader.onload = (e) => {
      const img = document.createElement('img');
      img.src = e.target.result;
      img.alt = file.name;
      previewGrid?.appendChild(img);
    };
    reader.readAsDataURL(file);

    uploadToS3(file);
  });
}

async function uploadToS3(file) {
  try {
    // Solicita URL pré-assinada ao Lambda
    const res = await fetch(`${UPLOAD_API}?filename=${encodeURIComponent(file.name)}&type=${encodeURIComponent(file.type)}`);
    const { uploadUrl, key } = await res.json();

    await fetch(uploadUrl, {
      method: 'PUT',
      body: file,
      headers: { 'Content-Type': file.type }
    });

    console.log(`Upload concluído: ${key}`);
  } catch (err) {
    console.error('Erro no upload:', err);
  }
}

if (uploadArea) {
  uploadArea.addEventListener('click', () => fileInput?.click());
  uploadArea.addEventListener('dragover', (e) => { e.preventDefault(); uploadArea.classList.add('dragover'); });
  uploadArea.addEventListener('dragleave', () => uploadArea.classList.remove('dragover'));
  uploadArea.addEventListener('drop', (e) => {
    e.preventDefault();
    uploadArea.classList.remove('dragover');
    handleFiles(e.dataTransfer.files);
  });
}

if (fileInput) {
  fileInput.addEventListener('change', () => handleFiles(fileInput.files));
}

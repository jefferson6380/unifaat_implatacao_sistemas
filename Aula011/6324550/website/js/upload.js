// URL da API de upload (atualizar após deploy)
const UPLOAD_API_URL = 'https://REPLACE_WITH_API_GATEWAY_URL/prod/upload';
const MAX_SIZE_MB = 5;
const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];

const fileInput = document.getElementById('fileInput');
const uploadArea = document.getElementById('uploadArea');
const statusEl = document.getElementById('uploadStatus');

function setStatus(msg, type = 'info') {
  const colors = { info: '#94a3b8', success: '#22c55e', error: '#ef4444', loading: '#0ea5e9' };
  statusEl.style.color = colors[type] || colors.info;
  statusEl.textContent = msg;
}

async function uploadFile(file) {
  if (!ALLOWED_TYPES.includes(file.type)) {
    setStatus('❌ Tipo de arquivo não permitido. Use PNG, JPG ou WebP.', 'error');
    return;
  }
  if (file.size > MAX_SIZE_MB * 1024 * 1024) {
    setStatus(`❌ Arquivo muito grande. Máximo: ${MAX_SIZE_MB}MB.`, 'error');
    return;
  }

  setStatus('⏳ Obtendo URL de upload...', 'loading');

  try {
    // 1. Solicitar URL pré-assinada
    const presignRes = await fetch(UPLOAD_API_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ fileName: file.name, fileType: file.type })
    });

    if (!presignRes.ok) throw new Error('Não foi possível obter URL de upload.');
    const { uploadUrl, fileUrl } = await presignRes.json();

    setStatus('⏳ Enviando arquivo...', 'loading');

    // 2. Upload direto para S3 via URL pré-assinada
    const uploadRes = await fetch(uploadUrl, {
      method: 'PUT',
      headers: { 'Content-Type': file.type },
      body: file
    });

    if (!uploadRes.ok) throw new Error('Falha no upload para S3.');

    setStatus(`✅ Upload concluído! URL: ${fileUrl}`, 'success');
  } catch (err) {
    setStatus(`❌ Erro: ${err.message}`, 'error');
    console.error('Upload error:', err);
  }
}

fileInput.addEventListener('change', (e) => {
  const file = e.target.files[0];
  if (file) uploadFile(file);
});

// Drag and drop
uploadArea.addEventListener('dragover', (e) => {
  e.preventDefault();
  uploadArea.style.borderColor = '#0ea5e9';
});

uploadArea.addEventListener('dragleave', () => {
  uploadArea.style.borderColor = '';
});

uploadArea.addEventListener('drop', (e) => {
  e.preventDefault();
  uploadArea.style.borderColor = '';
  const file = e.dataTransfer.files[0];
  if (file) uploadFile(file);
});

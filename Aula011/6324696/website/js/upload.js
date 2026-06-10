'use strict';

// UPLOAD_URL será substituído pela URL pré-assinada do S3 após o deploy
const UPLOAD_URL = 'REPLACE_WITH_S3_PRESIGNED_URL_ENDPOINT';
const MAX_SIZE_BYTES = 5 * 1024 * 1024; // 5 MB
const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];

const zone    = document.getElementById('uploadZone');
const input   = document.getElementById('fileInput');
const preview = document.getElementById('uploadPreview');
const upStat  = document.getElementById('uploadStatus');

if (!zone) { /* upload section not present on this page */ }
else {
  zone.addEventListener('click', () => input.click());
  zone.addEventListener('keydown', e => { if (e.key === 'Enter' || e.key === ' ') input.click(); });

  zone.addEventListener('dragover', e => { e.preventDefault(); zone.classList.add('dragover'); });
  zone.addEventListener('dragleave', () => zone.classList.remove('dragover'));
  zone.addEventListener('drop', e => {
    e.preventDefault();
    zone.classList.remove('dragover');
    handleFiles(e.dataTransfer.files);
  });

  input.addEventListener('change', () => handleFiles(input.files));
}

function handleFiles(files) {
  Array.from(files).forEach(file => {
    if (!ALLOWED_TYPES.includes(file.type)) {
      showUploadStatus(`❌ Tipo não permitido: ${file.name}`, 'error'); return;
    }
    if (file.size > MAX_SIZE_BYTES) {
      showUploadStatus(`❌ Arquivo muito grande (máx 5MB): ${file.name}`, 'error'); return;
    }
    addPreview(file);
    uploadFile(file);
  });
  // reset so same file can be re-selected
  if (input) input.value = '';
}

function addPreview(file) {
  const reader = new FileReader();
  reader.onload = ev => {
    const item = document.createElement('div');
    item.className = 'preview-item';
    item.setAttribute('role', 'listitem');

    const img = document.createElement('img');
    img.src = ev.target.result;
    img.alt = file.name;
    img.loading = 'lazy';

    const rm = document.createElement('button');
    rm.className = 'preview-remove';
    rm.textContent = '×';
    rm.setAttribute('aria-label', `Remover ${file.name}`);
    rm.onclick = () => item.remove();

    item.appendChild(img);
    item.appendChild(rm);
    preview.appendChild(item);
  };
  reader.readAsDataURL(file);
}

async function uploadFile(file) {
  if (UPLOAD_URL === 'REPLACE_WITH_S3_PRESIGNED_URL_ENDPOINT') {
    showUploadStatus(`✅ Demo: "${file.name}" seria enviado para o S3.`, 'success');
    return;
  }

  showUploadStatus(`⏳ Enviando ${file.name}...`, 'info');
  try {
    // 1. Solicita URL pré-assinada ao Lambda
    const metaRes = await fetch(`${UPLOAD_URL}?filename=${encodeURIComponent(file.name)}&type=${encodeURIComponent(file.type)}`);
    if (!metaRes.ok) throw new Error('Falha ao obter URL de upload');
    const { uploadUrl, publicUrl } = await metaRes.json();

    // 2. Faz o PUT direto no S3
    const putRes = await fetch(uploadUrl, {
      method: 'PUT',
      headers: { 'Content-Type': file.type },
      body: file,
    });
    if (!putRes.ok) throw new Error('Falha no upload para o S3');

    showUploadStatus(`✅ "${file.name}" enviado com sucesso! URL: ${publicUrl}`, 'success');
  } catch (err) {
    console.error('Upload error:', err);
    showUploadStatus(`❌ Erro ao enviar "${file.name}": ${err.message}`, 'error');
  }
}

function showUploadStatus(msg, type) {
  if (!upStat) return;
  upStat.textContent = msg;
  upStat.style.color = type === 'error' ? 'var(--danger)' : type === 'success' ? 'var(--success)' : 'var(--primary)';
}

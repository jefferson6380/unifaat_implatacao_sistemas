/* ============================================================
   upload.js — Upload de imagens para S3 via presigned URL
   ============================================================ */

// URL do endpoint que gera presigned URLs (preencher após deploy)
const UPLOAD_API = 'https://okadj41b1e.execute-api.us-east-1.amazonaws.com/prod/upload-url';

const uploadArea    = document.getElementById('uploadArea');
const fileInput     = document.getElementById('fileInput');
const uploadBtn     = document.getElementById('uploadBtn');
const uploadPreview = document.getElementById('uploadPreview');
const progressWrap  = document.getElementById('progressWrapper');
const progressBar   = document.getElementById('progressBar');
const uploadStatus  = document.getElementById('uploadStatus');

if (!uploadArea) {
  /* Página sem upload — não executa */
} else {
  const MAX_SIZE_MB = 5;
  const ALLOWED     = ['image/jpeg', 'image/png', 'image/webp'];
  let   filesToUpload = [];

  /* ------ Drag and drop ------ */
  uploadArea.addEventListener('dragover', (e) => {
    e.preventDefault();
    uploadArea.classList.add('dragover');
  });

  uploadArea.addEventListener('dragleave', () => uploadArea.classList.remove('dragover'));

  uploadArea.addEventListener('drop', (e) => {
    e.preventDefault();
    uploadArea.classList.remove('dragover');
    handleFiles(e.dataTransfer.files);
  });

  /* ------ Seleção via input ------ */
  fileInput.addEventListener('change', () => handleFiles(fileInput.files));

  function handleFiles(files) {
    const valid = Array.from(files).filter(f => {
      if (!ALLOWED.includes(f.type)) {
        showToast(`Arquivo "${f.name}" ignorado — tipo não permitido.`);
        return false;
      }
      if (f.size > MAX_SIZE_MB * 1024 * 1024) {
        showToast(`Arquivo "${f.name}" ignorado — ultrapassa ${MAX_SIZE_MB}MB.`);
        return false;
      }
      return true;
    });

    if (valid.length === 0) return;

    filesToUpload = [...filesToUpload, ...valid];
    renderPreviews(valid);
    uploadBtn.style.display = 'inline-block';
  }

  function renderPreviews(files) {
    files.forEach(file => {
      const reader = new FileReader();
      reader.onload = (e) => {
        const img = document.createElement('img');
        img.src = e.target.result;
        img.alt = file.name;
        img.title = file.name;
        uploadPreview.appendChild(img);
      };
      reader.readAsDataURL(file);
    });
  }

  /* ------ Upload para S3 via presigned URL ------ */
  uploadBtn.addEventListener('click', async () => {
    if (filesToUpload.length === 0) return;

    uploadBtn.disabled = true;
    uploadBtn.textContent = 'Enviando...';
    progressWrap.style.display = 'block';
    progressBar.style.width = '0%';
    uploadStatus.style.display = 'none';

    let uploaded = 0;

    for (const file of filesToUpload) {
      try {
        /* 1. Solicita presigned URL ao Lambda */
        const res = await fetch(UPLOAD_API, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ filename: file.name, contentType: file.type }),
        });

        if (!res.ok) throw new Error(`Erro ao obter URL: HTTP ${res.status}`);

        const { uploadUrl } = await res.json();

        /* 2. Faz upload direto para o S3 */
        const putRes = await fetch(uploadUrl, {
          method: 'PUT',
          headers: { 'Content-Type': file.type },
          body: file,
        });

        if (!putRes.ok) throw new Error(`Falha no upload: HTTP ${putRes.status}`);

        uploaded++;
        progressBar.style.width = `${(uploaded / filesToUpload.length) * 100}%`;
      } catch (err) {
        console.error('Erro ao enviar arquivo:', file.name, err);
        showToast(`Erro ao enviar "${file.name}".`);
      }
    }

    uploadStatus.textContent = `${uploaded} de ${filesToUpload.length} arquivo(s) enviado(s) com sucesso!`;
    uploadStatus.style.display = 'block';

    /* Limpa estado */
    filesToUpload = [];
    uploadBtn.disabled = false;
    uploadBtn.textContent = 'Enviar para S3';
    uploadBtn.style.display = 'none';
    setTimeout(() => { progressWrap.style.display = 'none'; }, 2000);
  });
}

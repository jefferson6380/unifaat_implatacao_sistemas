(function () {
  const config = window.TF11_CONFIG || {};
  const form = document.getElementById("contactForm");
  const status = document.getElementById("formStatus");

  if (!form || !status) return;

  function setStatus(text, type) {
    status.textContent = text;
    status.classList.remove("ok", "warn", "error");
    if (type) status.classList.add(type);
  }

  function formToPayload(formData) {
    return {
      name: String(formData.get("name") || "").trim(),
      email: String(formData.get("email") || "").trim(),
      subject: String(formData.get("subject") || "").trim(),
      message: String(formData.get("message") || "").trim(),
      createdAt: new Date().toISOString()
    };
  }

  function validate(payload) {
    if (!payload.name || payload.name.length < 3) return "Nome invalido.";
    if (!payload.email.includes("@")) return "Email invalido.";
    if (!payload.subject || payload.subject.length < 3) return "Assunto invalido.";
    if (!payload.message || payload.message.length < 10) return "Mensagem muito curta.";
    return "";
  }

  async function submit(payload) {
    if (config.CONTACT_API_URL) {
      const response = await fetch(config.CONTACT_API_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
      });

      if (!response.ok) {
        throw new Error("API de contato indisponivel");
      }

      return;
    }

    const queueKey = "tf11_local_contact_queue";
    const existing = JSON.parse(localStorage.getItem(queueKey) || "[]");
    existing.push(payload);
    localStorage.setItem(queueKey, JSON.stringify(existing));
  }

  form.addEventListener("submit", async function (event) {
    event.preventDefault();
    setStatus("Validando formulario...", "warn");

    const payload = formToPayload(new FormData(form));
    const validationError = validate(payload);
    if (validationError) {
      setStatus(validationError, "error");
      return;
    }

    try {
      await submit(payload);
      form.reset();
      setStatus("Mensagem enviada com sucesso.", "ok");
    } catch (error) {
      setStatus("Nao foi possivel enviar no momento.", "error");
    }
  });
})();

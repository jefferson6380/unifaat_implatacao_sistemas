// ── Lazy Loading ──────────────────────────────────────────────
document.querySelectorAll('img[data-src]').forEach(img => {
  const observer = new IntersectionObserver(([entry]) => {
    if (entry.isIntersecting) {
      img.src = img.dataset.src;
      img.removeAttribute('data-src');
      observer.disconnect();
    }
  });
  observer.observe(img);
});

// ── Nav active link ────────────────────────────────────────────
const sections = document.querySelectorAll('section[id]');
const navLinks = document.querySelectorAll('.nav-links a');

const sectionObserver = new IntersectionObserver(entries => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      navLinks.forEach(a => a.classList.remove('active'));
      const link = document.querySelector(`.nav-links a[href="#${entry.target.id}"]`);
      if (link) link.classList.add('active');
    }
  });
}, { threshold: 0.5 });

sections.forEach(s => sectionObserver.observe(s));

// ── Card entrance animation ────────────────────────────────────
const cardObserver = new IntersectionObserver(entries => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.style.opacity = '1';
      entry.target.style.transform = 'translateY(0)';
    }
  });
}, { threshold: 0.1 });

document.querySelectorAll('.card, .timeline-item').forEach(el => {
  el.style.opacity = '0';
  el.style.transform = 'translateY(20px)';
  el.style.transition = 'opacity 0.4s ease, transform 0.4s ease';
  cardObserver.observe(el);
});

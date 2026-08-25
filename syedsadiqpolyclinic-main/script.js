/* =============================================
   SYED SADIQ POLY CLINIC — Main JavaScript
   Version 2.0 — Complete
   ============================================= */
'use strict';

/* ── NAVBAR SCROLL ──────────────────────────── */
const navbar    = document.getElementById('navbar');
const backToTop = document.getElementById('backToTop');

window.addEventListener('scroll', () => {
  navbar.classList.toggle('scrolled', window.scrollY > 60);
  backToTop.classList.toggle('visible', window.scrollY > 400);
  updateActiveNav();
}, { passive: true });

/* ── HAMBURGER ──────────────────────────────── */
const hamburger = document.getElementById('hamburger');
const navLinks  = document.getElementById('navLinks');

hamburger.addEventListener('click', () => {
  const open = hamburger.classList.toggle('open');
  navLinks.classList.toggle('open', open);
  hamburger.setAttribute('aria-expanded', open);
});

navLinks.querySelectorAll('.nav-link').forEach(l =>
  l.addEventListener('click', () => {
    hamburger.classList.remove('open');
    navLinks.classList.remove('open');
    hamburger.setAttribute('aria-expanded', 'false');
  })
);

/* ── ACTIVE NAV ─────────────────────────────── */
function updateActiveNav() {
  const scrollY = window.scrollY + 120;
  document.querySelectorAll('section[id]').forEach(sec => {
    const link = document.querySelector(`.nav-link[href="#${sec.id}"]`);
    if (!link) return;
    const inView = scrollY >= sec.offsetTop && scrollY < sec.offsetTop + sec.offsetHeight;
    link.classList.toggle('active', inView);
  });
}

/* ── SMOOTH SCROLL ──────────────────────────── */
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
  anchor.addEventListener('click', e => {
    const id     = anchor.getAttribute('href');
    const target = id === '#' ? null : document.querySelector(id);
    if (!target) return;
    e.preventDefault();
    const navH = parseInt(getComputedStyle(document.documentElement).getPropertyValue('--nav-h')) || 76;
    window.scrollTo({ top: target.getBoundingClientRect().top + window.scrollY - navH, behavior: 'smooth' });
  });
});

/* ── BACK TO TOP ────────────────────────────── */
backToTop.addEventListener('click', () => window.scrollTo({ top: 0, behavior: 'smooth' }));

/* ── PARTICLES ──────────────────────────────── */
(function spawnParticles() {
  const container = document.getElementById('particles');
  if (!container) return;
  const n = window.innerWidth < 768 ? 10 : 20;
  for (let i = 0; i < n; i++) {
    const p    = document.createElement('div');
    p.className = 'particle';
    const size = Math.random() * 5 + 2;
    Object.assign(p.style, {
      width:    `${size}px`,
      height:   `${size}px`,
      left:     `${Math.random() * 100}%`,
      animationDuration: `${Math.random() * 14 + 10}s`,
      animationDelay:    `${Math.random() * 10}s`,
      opacity:  `${Math.random() * 0.55 + 0.1}`,
    });
    container.appendChild(p);
  }
}());

/* ── SCROLL REVEAL ──────────────────────────── */
(function initReveal() {
  const selectors = [
    '.about-card','.doctor-card','.service-item','.contact-card',
    '.featured-doctor','.lab-technologist-card','.lab-info-panel',
    '.map-panel','.appointment-cta','.mgmt-card',
    '.section-header','.footer-brand','.footer-links-col',
    '.stat-item',
  ];
  const els = document.querySelectorAll(selectors.join(','));
  els.forEach((el, i) => {
    el.classList.add('reveal');
    el.style.transitionDelay = `${(i % 5) * 0.07}s`;
  });
  const obs = new IntersectionObserver(
    entries => entries.forEach(entry => {
      if (entry.isIntersecting) { entry.target.classList.add('visible'); obs.unobserve(entry.target); }
    }),
    { threshold: 0.1, rootMargin: '0px 0px -50px 0px' }
  );
  els.forEach(el => obs.observe(el));
}());

/* ── STAT COUNTER ───────────────────────────── */
function animateCount(el, target, duration = 1600) {
  const suffix   = el.dataset.suffix || '';
  let start      = 0;
  const stepTime = 16;
  const steps    = Math.ceil(duration / stepTime);
  let frame      = 0;
  const timer    = setInterval(() => {
    frame++;
    start = Math.floor((frame / steps) * target);
    el.textContent = start + suffix;
    if (frame >= steps) { el.textContent = target + suffix; clearInterval(timer); }
  }, stepTime);
}

(function initCounters() {
  const statsEls = document.querySelectorAll('.stat-number[data-count]');
  const obs = new IntersectionObserver(
    entries => entries.forEach(entry => {
      if (entry.isIntersecting) {
        animateCount(entry.target, parseInt(entry.target.dataset.count));
        obs.unobserve(entry.target);
      }
    }),
    { threshold: 0.5 }
  );
  statsEls.forEach(el => obs.observe(el));
}());

/* ── 3-D TILT ON DOCTOR CARDS ───────────────── */
document.querySelectorAll('.doctor-card').forEach(card => {
  card.addEventListener('mousemove', e => {
    const r    = card.getBoundingClientRect();
    const rotX = ((e.clientY - r.top  - r.height / 2) / (r.height / 2)) * 4;
    const rotY = -((e.clientX - r.left - r.width  / 2) / (r.width  / 2)) * 4;
    card.style.transform = `translateY(-10px) perspective(900px) rotateX(${rotX}deg) rotateY(${rotY}deg)`;
  });
  card.addEventListener('mouseleave', () => { card.style.transform = ''; });
});

/* ── FEATURED DOCTOR PARALLAX ───────────────── */
(function featuredParallax() {
  const el = document.querySelector('.featured-doctor');
  if (!el) return;
  const bg = el.querySelector('.featured-doctor-bg');
  window.addEventListener('scroll', () => {
    const r = el.getBoundingClientRect();
    if (r.bottom < 0 || r.top > window.innerHeight) return;
    const progress = (window.innerHeight - r.top) / (window.innerHeight + r.height);
    if (bg) bg.style.transform = `translateY(${(progress - 0.5) * 18}px)`;
  }, { passive: true });
}());

/* ── MOBILE SWIPE CLOSE NAV ─────────────────── */
let touchStartY = 0;
document.addEventListener('touchstart', e => { touchStartY = e.touches[0].clientY; }, { passive: true });
document.addEventListener('touchend',   e => {
  if (Math.abs(touchStartY - e.changedTouches[0].clientY) > 60) {
    hamburger.classList.remove('open');
    navLinks.classList.remove('open');
  }
}, { passive: true });

/* ── PAGE FADE IN ───────────────────────────── */
document.documentElement.style.opacity = '0';
document.documentElement.style.transition = 'opacity 0.5s ease';
window.addEventListener('load', () => {
  requestAnimationFrame(() => { document.documentElement.style.opacity = '1'; });
});

console.log('%c🏥 Syed Sadiq Poly Clinic', 'color:#2a82d4;font-size:18px;font-weight:bold;');
console.log('%c   G.T. Road Daokey, Muridke', 'color:#c8a84b;font-size:12px;');

/**
 * Interstellar Co — Main Script
 * Handles: sticky nav, mobile menu, form validation, form submission
 */

/* ── Utility ──────────────────────────────────────────────── */
const $ = (sel, ctx = document) => ctx.querySelector(sel);
const $$ = (sel, ctx = document) => Array.from(ctx.querySelectorAll(sel));

/* ── Sticky Header ────────────────────────────────────────── */
(function initStickyHeader() {
  const header = $('#site-header');
  if (!header) return;

  const onScroll = () => {
    header.classList.toggle('scrolled', window.scrollY > 20);
  };

  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll(); // run once on load
})();

/* ── Mobile Navigation ────────────────────────────────────── */
(function initMobileNav() {
  const btn   = $('#hamburger');
  const links = $('#nav-links');
  if (!btn || !links) return;

  btn.addEventListener('click', () => {
    const isOpen = links.classList.toggle('open');
    btn.setAttribute('aria-expanded', isOpen);

    // Animate hamburger → X
    const spans = $$('span', btn);
    if (isOpen) {
      spans[0].style.transform = 'rotate(45deg) translate(5px,5px)';
      spans[1].style.opacity   = '0';
      spans[2].style.transform = 'rotate(-45deg) translate(5px,-5px)';
    } else {
      spans.forEach(s => (s.style.transform = '', s.style.opacity = ''));
    }
  });

  // Close menu when a link is clicked
  $$('a', links).forEach(a => {
    a.addEventListener('click', () => {
      links.classList.remove('open');
      btn.setAttribute('aria-expanded', 'false');
      const spans = $$('span', btn);
      spans.forEach(s => (s.style.transform = '', s.style.opacity = ''));
    });
  });

  // Close menu on outside click
  document.addEventListener('click', e => {
    if (!btn.contains(e.target) && !links.contains(e.target)) {
      links.classList.remove('open');
      btn.setAttribute('aria-expanded', 'false');
      const spans = $$('span', btn);
      spans.forEach(s => (s.style.transform = '', s.style.opacity = ''));
    }
  });
})();

/* ── Footer Year ──────────────────────────────────────────── */
(function setFooterYear() {
  const el = $('#footer-year');
  if (el) el.textContent = new Date().getFullYear();
})();

/* ── Contact Form ─────────────────────────────────────────── */
(function initContactForm() {
  const form       = $('#contact-form');
  const submitBtn  = $('#submit-btn');
  const successBox = $('#form-success');

  if (!form) return;

  /* ── Validation rules ── */
  const validators = {
    name: {
      test: v => v.trim().length >= 2,
      msg:  'Please enter your full name (at least 2 characters).',
    },
    email: {
      test: v => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v.trim()),
      msg:  'Please enter a valid work email address.',
    },
    service: {
      test: v => v !== '',
      msg:  'Please select the service you are interested in.',
    },
    message: {
      test: v => v.trim().length >= 10,
      msg:  'Please describe your project (at least 10 characters).',
    },
  };

  /* ── Helper: validate a single field ── */
  function validateField(name) {
    const rule = validators[name];
    if (!rule) return true; // optional fields always pass

    const el    = form.elements[name];
    const errEl = $(`#${name}-error`);
    const value = el ? el.value : '';
    const ok    = rule.test(value);

    if (el) el.classList.toggle('error', !ok);
    if (errEl) errEl.textContent = ok ? '' : rule.msg;

    return ok;
  }

  /* ── Live validation: clear errors on input ── */
  Object.keys(validators).forEach(name => {
    const el = form.elements[name];
    if (!el) return;

    el.addEventListener('input', () => validateField(name));
    el.addEventListener('change', () => validateField(name));
  });

  /* ── Submit ── */
  form.addEventListener('submit', async e => {
    e.preventDefault();

    // Validate all required fields
    const validFields = Object.keys(validators).map(validateField);
    if (validFields.includes(false)) {
      // Focus first error
      const firstError = form.querySelector('.error');
      if (firstError) firstError.focus();
      return;
    }

    // Gather form data
    const data = {
      name:    form.elements.name.value.trim(),
      email:   form.elements.email.value.trim(),
      service: form.elements.service.value,
      company: (form.elements.company?.value || '').trim(),
      message: form.elements.message.value.trim(),
    };

    // Show loading state
    setLoading(true);

    try {
      /**
       * Form submission endpoint.
       *
       * In production this would POST to your API Gateway / Lambda / SES endpoint.
       * For now we simulate a network round-trip (1.2 s) and always succeed so you
       * can see the full UX flow during local development.
       *
       * Replace the block below with a real fetch() when your backend is ready:
       *
       *   const res = await fetch('/api/contact', {
       *     method: 'POST',
       *     headers: { 'Content-Type': 'application/json' },
       *     body: JSON.stringify(data),
       *   });
       *   if (!res.ok) throw new Error('Server error');
       */
      await simulateSubmit(data);

      // Success
      form.style.display = 'none';
      successBox.hidden  = false;

    } catch (err) {
      console.error('Form submission error:', err);
      showFormError('Something went wrong. Please try again or email us directly.');
    } finally {
      setLoading(false);
    }
  });

  /* ── UI helpers ── */
  function setLoading(loading) {
    submitBtn.disabled = loading;
    const text    = $('#submit-btn .btn-text');
    const spinner = $('#submit-btn .btn-spinner');
    if (text)    text.hidden    = loading;
    if (spinner) spinner.hidden = !loading;
  }

  function showFormError(msg) {
    let errBanner = $('#form-level-error');
    if (!errBanner) {
      errBanner = document.createElement('p');
      errBanner.id = 'form-level-error';
      errBanner.style.cssText =
        'color:var(--c-error);font-size:.88rem;padding:12px 16px;' +
        'background:rgba(239,68,68,.08);border:1px solid rgba(239,68,68,.25);' +
        'border-radius:8px;margin-top:8px;';
      form.appendChild(errBanner);
    }
    errBanner.textContent = msg;
  }

  /* ── Simulated async submission (development only) ── */
  function simulateSubmit(data) {
    console.log('[Interstellar Co] Form submission (simulated):', data);
    return new Promise(resolve => setTimeout(resolve, 1200));
  }
})();

/* ── Intersection Observer — subtle card animations ──────── */
(function initFadeIn() {
  if (!('IntersectionObserver' in window)) return;

  const style = document.createElement('style');
  style.textContent = `
    .fade-in { opacity: 0; transform: translateY(20px);
      transition: opacity .5s ease, transform .5s ease; }
    .fade-in.visible { opacity: 1; transform: none; }
  `;
  document.head.appendChild(style);

  const targets = $$('.service-card, .about-card, .value');
  targets.forEach((el, i) => {
    el.classList.add('fade-in');
    el.style.transitionDelay = `${(i % 3) * 80}ms`;
  });

  const observer = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.12 });

  targets.forEach(el => observer.observe(el));
})();

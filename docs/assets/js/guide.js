// Phial — user guide nav (filter, scrollspy, collapsible groups, progress)

const TOC_OPEN_KEY = 'phial_toc_open';

// Resolve a TOC link to the section element it belongs to.
// Sub-section links (h3 ids) live inside a .guide-section — map them up.
function sectionForLink(link) {
  const href = link.getAttribute('href');
  if (!href || !href.startsWith('#')) return null;
  const target = document.querySelector(href);
  if (!target) return null;
  return target.closest('.guide-section') || (target.classList.contains('guide-section') ? target : null);
}

// 1. Search / filter across guide sections + TOC
function initGuideSearch() {
  const searchInputs = document.querySelectorAll('.guide-search-input');
  if (!searchInputs.length) return;
  const empty = document.getElementById('toc-empty');
  const emptyQuery = document.getElementById('toc-empty-query');
  const emptyClear = document.getElementById('toc-empty-clear');
  const countEl = document.getElementById('toc-visible-count');

  function applyFilter(query, sourceInput) {
    const q = query.toLowerCase().trim();

    searchInputs.forEach((other) => {
      if (other !== sourceInput) other.value = sourceInput.value;
    });
    document.querySelectorAll('.toc-clear').forEach((btn) => {
      btn.hidden = q === '';
    });

    // Filter content sections (search full text so h3 subsections match too)
    document.querySelectorAll('.guide-section').forEach((section) => {
      const match = q === '' || section.textContent.toLowerCase().includes(q);
      section.style.display = match ? '' : 'none';
    });

    // Filter TOC links + hide emptied groups (desktop + mobile clones).
    // Two-tier: if any label matches the query, narrow precisely to those
    // links; otherwise (body-text-only hit like "PBKDF2") surface the links
    // of the matching sections so the nav still guides you there.
    const allLinks = Array.from(document.querySelectorAll('.toc-list a'));
    const anyLabelHit = q !== '' && allLinks.some((l) => l.textContent.toLowerCase().includes(q));
    let visibleLinks = 0;
    document.querySelectorAll('.toc-group').forEach((group) => {
      let groupVisible = 0;
      group.querySelectorAll('.toc-list a').forEach((link) => {
        const section = sectionForLink(link);
        const labelMatch = link.textContent.toLowerCase().includes(q);
        const sectionHit = section && section.style.display !== 'none';
        const show = q === '' || labelMatch || (!anyLabelHit && sectionHit);
        link.parentElement.style.display = show ? '' : 'none';
        link.style.display = show ? '' : 'none';
        if (show) groupVisible++;
      });
      // When filtering, auto-expand groups that still have hits
      if (q !== '' && groupVisible > 0) group.open = true;
      group.style.display = groupVisible > 0 || q === '' ? '' : 'none';
      if (group.closest('#toc-nav')) visibleLinks += groupVisible;
    });

    if (countEl) countEl.textContent = q === '' ? document.querySelectorAll('#toc-nav .toc-list a').length : visibleLinks;
    if (empty) {
      const none = q !== '' && visibleLinks === 0;
      empty.hidden = !none;
      if (emptyQuery) emptyQuery.textContent = query.trim();
    }
  }

  searchInputs.forEach((input) => {
    input.addEventListener('input', (e) => applyFilter(e.target.value, input));
  });

  document.querySelectorAll('.toc-clear').forEach((btn) => {
    btn.addEventListener('click', () => {
      const box = btn.closest('.guide-search-box');
      const input = box ? box.querySelector('.guide-search-input') : searchInputs[0];
      if (input) {
        input.value = '';
        applyFilter('', input);
        input.focus();
      }
    });
  });
  if (emptyClear) {
    emptyClear.addEventListener('click', () => {
      const first = document.querySelector('#toc-nav ~ * .guide-search-input, .guide-search-input');
      searchInputs.forEach((i) => { i.value = ''; });
      applyFilter('', searchInputs[0]);
      if (first) first.focus();
    });
  }
}

// 2. ScrollSpy via IntersectionObserver (sections + h3 subsections)
function initScrollSpy() {
  const links = Array.from(document.querySelectorAll('#toc-nav .toc-list a'));
  if (!links.length) return;
  const byId = new Map(links.map((l) => [l.getAttribute('href'), l]));
  const targets = [];
  links.forEach((link) => {
    const t = document.querySelector(link.getAttribute('href'));
    if (t && !targets.includes(t)) targets.push(t);
  });
  if (!targets.length) return;

  function setActive(id) {
    const href = `#${id}`;
    document.querySelectorAll('.toc-list a').forEach((l) => {
      l.classList.toggle('active', l.getAttribute('href') === href);
    });
    // Auto-expand the group holding the active link (desktop sidebar only)
    const active = byId.get(href);
    if (active) {
      const group = active.closest('#toc-nav .toc-group');
      if (group && !group.open) group.open = true;
      // Keep active link visible inside the scrollable sidebar WITHOUT moving
      // the page: nudge only the sidebar's own scrollTop. (scrollIntoView()
      // scrolls every ancestor including the document, which yanks the page
      // back up while the user is scrolling down.)
      const sidebar = document.getElementById('guide-sidebar');
      if (sidebar && getComputedStyle(sidebar).display !== 'none') {
        const sRect = sidebar.getBoundingClientRect();
        const lRect = active.getBoundingClientRect();
        const padTop = 110, padBottom = 60;
        if (lRect.top < sRect.top + padTop) {
          sidebar.scrollTop -= (sRect.top + padTop) - lRect.top;
        } else if (lRect.bottom > sRect.bottom - padBottom) {
          sidebar.scrollTop += lRect.bottom - (sRect.bottom - padBottom);
        }
      }
      persistOpenGroups();
    }
  }

  if ('IntersectionObserver' in window) {
    let current = null;
    const obs = new IntersectionObserver(
      (entries) => {
        entries.forEach((en) => {
          if (en.isIntersecting) current = en.target.id;
        });
        if (current) setActive(current);
      },
      { rootMargin: '-120px 0px -70% 0px', threshold: 0 }
    );
    targets.forEach((t) => obs.observe(t));
  } else {
    // Fallback: scroll offset math
    window.addEventListener('scroll', () => {
      let id = '';
      targets.forEach((t) => {
        if (window.scrollY >= t.offsetTop - 140) id = t.id;
      });
      if (id) setActive(id);
    }, { passive: true });
  }
}

// 3. Collapsible groups with persisted state
function persistOpenGroups() {
  try {
    const open = Array.from(document.querySelectorAll('#toc-nav .toc-group'))
      .filter((g) => g.open)
      .map((g) => g.dataset.group);
    localStorage.setItem(TOC_OPEN_KEY, JSON.stringify(open));
  } catch (_) { /* private mode */ }
}

function initTocGroups() {
  const groups = document.querySelectorAll('#toc-nav .toc-group');
  if (!groups.length) return;
  try {
    const raw = localStorage.getItem(TOC_OPEN_KEY);
    if (raw) {
      const open = new Set(JSON.parse(raw));
      groups.forEach((g) => { g.open = open.has(g.dataset.group); });
    }
  } catch (_) { /* first visit: keep defaults */ }
  groups.forEach((g) => {
    g.addEventListener('toggle', persistOpenGroups);
  });

  const collapseBtn = document.getElementById('toc-collapse-all');
  if (collapseBtn) {
    const syncLabel = () => {
      const anyOpen = Array.from(groups).some((g) => g.open);
      collapseBtn.textContent = anyOpen ? 'Collapse all' : 'Expand all';
    };
    syncLabel();
    collapseBtn.addEventListener('click', () => {
      const anyOpen = Array.from(groups).some((g) => g.open);
      groups.forEach((g) => { g.open = !anyOpen; });
      persistOpenGroups();
      syncLabel();
    });
    groups.forEach((g) => g.addEventListener('toggle', syncLabel));
  }

  const topBtn = document.getElementById('toc-top');
  if (topBtn) topBtn.addEventListener('click', () => window.scrollTo({ top: 0, behavior: 'smooth' }));
}

// 4. Reading progress bar
function initProgress() {
  const bar = document.getElementById('toc-progress-bar');
  if (!bar) return;
  const update = () => {
    const max = document.documentElement.scrollHeight - window.innerHeight;
    bar.style.width = max > 0 ? `${Math.min(100, (window.scrollY / max) * 100)}%` : '0%';
  };
  window.addEventListener('scroll', update, { passive: true });
  update();
}

// 5. Mobile TOC: clone desktop groups so both stay in sync for free
function initMobileToc() {
  const tocCard = document.getElementById('mobile-toc-card');
  const tocHeader = document.getElementById('mobile-toc-header');
  const host = document.getElementById('mobile-toc-groups');
  const nav = document.getElementById('toc-nav');
  if (host && nav) {
    host.innerHTML = '';
    nav.querySelectorAll('.toc-group').forEach((g) => {
      const clone = g.cloneNode(true);
      clone.removeAttribute('id');
      clone.dataset.group = `${g.dataset.group}-m`;
      host.appendChild(clone);
    });
  }
  if (!tocCard || !tocHeader) return;
  tocHeader.addEventListener('click', () => tocCard.classList.toggle('expanded'));
  tocCard.querySelectorAll('.toc-list a').forEach((link) => {
    link.addEventListener('click', () => tocCard.classList.remove('expanded'));
  });
}

document.addEventListener('DOMContentLoaded', () => {
  initTocGroups();
  initGuideSearch();
  initScrollSpy();
  initMobileToc();
  initProgress();

  // "/" focuses hero search without typing into inputs
  document.addEventListener('keydown', (e) => {
    if (e.key === '/' && !/INPUT|TEXTAREA/.test(document.activeElement.tagName)) {
      e.preventDefault();
      const first = document.querySelector('.guide-search-hero .guide-search-input') || document.querySelector('.guide-search-input');
      if (first) first.focus();
    }
  });
});

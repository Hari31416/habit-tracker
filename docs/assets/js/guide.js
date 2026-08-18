// Habit Tracker - User Guide Interactive Logic

// 1. Search Filter across Guide Sections
function initGuideSearch() {
  const searchInput = document.getElementById('guide-search');
  if (!searchInput) return;

  searchInput.addEventListener('input', (e) => {
    const query = e.target.value.toLowerCase().trim();
    const sections = document.querySelectorAll('.guide-section');
    const tocLinks = document.querySelectorAll('.toc-list a');

    sections.forEach(section => {
      const text = section.textContent.toLowerCase();
      const match = query === '' || text.includes(query);
      section.style.display = match ? 'block' : 'none';
    });

    tocLinks.forEach(link => {
      const href = link.getAttribute('href');
      if (!href) return;
      const targetSec = document.querySelector(href);
      if (targetSec) {
        link.style.display = targetSec.style.display === 'none' ? 'none' : 'block';
      }
    });
  });
}

// 2. ScrollSpy for Sticky Table of Contents
function initScrollSpy() {
  const links = document.querySelectorAll('.toc-list a');
  const sections = document.querySelectorAll('.guide-section');

  window.addEventListener('scroll', () => {
    let current = '';
    sections.forEach(section => {
      const sectionTop = section.offsetTop - 120;
      if (window.scrollY >= sectionTop) {
        current = section.getAttribute('id');
      }
    });

    links.forEach(link => {
      link.classList.remove('active');
      if (link.getAttribute('href') === `#${current}`) {
        link.classList.add('active');
      }
    });
  });
}

document.addEventListener('DOMContentLoaded', () => {
  initGuideSearch();
  initScrollSpy();
});

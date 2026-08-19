// Phial — user guide search and TOC

// 1. Search Filter across Guide Sections
function initGuideSearch() {
  const searchInputs = document.querySelectorAll('.guide-search-input');
  if (!searchInputs.length) return;

  searchInputs.forEach(input => {
    input.addEventListener('input', (e) => {
      const query = e.target.value.toLowerCase().trim();
      const sections = document.querySelectorAll('.guide-section');
      const tocLinks = document.querySelectorAll('.toc-list a');

      // Keep both search inputs in sync if one is changed
      searchInputs.forEach(otherInput => {
        if (otherInput !== input) {
          otherInput.value = e.target.value;
        }
      });

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
  });
}

// 2. ScrollSpy for Table of Contents
function initScrollSpy() {
  const links = document.querySelectorAll('.toc-list a');
  const sections = document.querySelectorAll('.guide-section');

  window.addEventListener('scroll', () => {
    let current = '';
    sections.forEach(section => {
      const sectionTop = section.offsetTop - 140;
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

// 3. Mobile Table of Contents Accordion Toggle
function initMobileToc() {
  const tocCard = document.getElementById('mobile-toc-card');
  const tocHeader = document.getElementById('mobile-toc-header');
  if (!tocCard || !tocHeader) return;

  tocHeader.addEventListener('click', () => {
    tocCard.classList.toggle('expanded');
  });

  // Auto collapse when a link inside mobile TOC is clicked
  const mobileTocLinks = tocCard.querySelectorAll('.toc-list a');
  mobileTocLinks.forEach(link => {
    link.addEventListener('click', () => {
      tocCard.classList.remove('expanded');
    });
  });
}

document.addEventListener('DOMContentLoaded', () => {
  initGuideSearch();
  initScrollSpy();
  initMobileToc();
});

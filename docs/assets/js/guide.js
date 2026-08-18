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

// 2. Interactive XP & Level Simulator
function initXpSimulator() {
  const streakSlider = document.getElementById('sim-streak');
  const streakVal = document.getElementById('sim-streak-val');
  const diffSelect = document.getElementById('sim-difficulty');
  const durationSlider = document.getElementById('sim-duration');
  const durationVal = document.getElementById('sim-duration-val');

  const outBaseXp = document.getElementById('sim-base-xp');
  const outMultiplier = document.getElementById('sim-multiplier');
  const outTotalXp = document.getElementById('sim-total-xp');
  const outLevel = document.getElementById('sim-level');
  const outTitle = document.getElementById('sim-title');

  if (!streakSlider) return;

  function calculateXp() {
    const streak = parseInt(streakSlider.value, 10);
    streakVal.textContent = `${streak} days`;

    const diff = diffSelect ? diffSelect.value : 'normal';
    const duration = durationSlider ? parseInt(durationSlider.value, 10) : 25;
    if (durationVal) durationVal.textContent = `${duration} min`;

    // Base XP calculation
    let baseXp = 15;
    if (diff === 'easy') baseXp = 10;
    if (diff === 'hard') baseXp = 25;
    if (diff === 'timer') baseXp = Math.max(10, Math.round(duration * 0.8));

    // Multiplier calculation (1.0x to 2.0x)
    let mult = 1.0;
    if (streak >= 30) mult = 2.0;
    else if (streak >= 14) mult = 1.5;
    else if (streak >= 7) mult = 1.25;
    else if (streak >= 3) mult = 1.1;

    const totalXp = Math.round(baseXp * mult);

    // Cumulative hypothetical total XP assuming consistent checkins
    const totalAccumulatedXp = Math.round(streak * baseXp * ((1.0 + mult) / 2));
    
    // Level formula: Level L requires 100 * L^2 cumulative XP
    // L = sqrt(totalXp / 100)
    const level = Math.max(1, Math.floor(Math.sqrt(totalAccumulatedXp / 100)) + 1);

    let title = 'Novice';
    if (level >= 25) title = 'Grandmaster';
    else if (level >= 15) title = 'Pathfinder';
    else if (level >= 8) title = 'Adept';
    else if (level >= 4) title = 'Apprentice';

    if (outBaseXp) outBaseXp.textContent = `${baseXp} XP`;
    if (outMultiplier) outMultiplier.textContent = `${mult.toFixed(2)}x`;
    if (outTotalXp) outTotalXp.textContent = `+${totalXp} XP`;
    if (outLevel) outLevel.textContent = `Level ${level}`;
    if (outTitle) outTitle.textContent = title;
  }

  streakSlider.addEventListener('input', calculateXp);
  if (diffSelect) diffSelect.addEventListener('change', calculateXp);
  if (durationSlider) durationSlider.addEventListener('input', calculateXp);

  calculateXp();
}

// 3. Interactive Shield Banking Calculator
function initShieldSimulator() {
  const consistencySlider = document.getElementById('sim-consistency');
  const consistencyVal = document.getElementById('sim-consistency-val');
  const activeShieldsInput = document.getElementById('sim-used-shields');
  const maxCapInput = document.getElementById('sim-max-cap');

  const outEarned = document.getElementById('sim-shields-earned');
  const outAvailable = document.getElementById('sim-shields-avail');
  const outDaysNext = document.getElementById('sim-days-next');

  if (!consistencySlider) return;

  function calculateShields() {
    const consistencyDays = parseInt(consistencySlider.value, 10);
    consistencyVal.textContent = `${consistencyDays} days`;

    const used = activeShieldsInput ? parseInt(activeShieldsInput.value, 10) : 0;
    const maxCap = maxCapInput ? parseInt(maxCapInput.value, 10) : 3;

    // 1 starter + 1 for every 14 unbroken consistency days
    const earned = 1 + Math.floor(consistencyDays / 14);
    const available = Math.min(maxCap, Math.max(0, earned - used));
    const daysToNext = 14 - (consistencyDays % 14);

    if (outEarned) outEarned.textContent = `${earned}`;
    if (outAvailable) outAvailable.textContent = `${available} / ${maxCap}`;
    if (outDaysNext) outDaysNext.textContent = `${daysToNext} days`;
  }

  consistencySlider.addEventListener('input', calculateShields);
  if (activeShieldsInput) activeShieldsInput.addEventListener('input', calculateShields);
  if (maxCapInput) maxCapInput.addEventListener('input', calculateShields);

  calculateShields();
}

// 4. ScrollSpy for Sticky Table of Contents
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
  initXpSimulator();
  initShieldSimulator();
  initScrollSpy();
});

// Habit Tracker - Main JavaScript

// 1. Theme Management (Matches Flutter App Preferences)
const THEME_KEY = 'habit_tracker_web_theme';

function initTheme() {
  const savedTheme = localStorage.getItem(THEME_KEY);
  const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
  const initialTheme = savedTheme || (prefersDark ? 'dark' : 'light');
  
  setTheme(initialTheme);
}

function setTheme(theme) {
  document.documentElement.setAttribute('data-theme', theme);
  localStorage.setItem(THEME_KEY, theme);
  
  const icon = document.getElementById('theme-toggle-icon');
  if (icon) {
    icon.innerHTML = theme === 'dark' 
      ? '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="5"></circle><line x1="12" y1="1" x2="12" y2="3"></line><line x1="12" y1="21" x2="12" y2="23"></line><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"></line><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"></line><line x1="1" y1="12" x2="3" y2="12"></line><line x1="21" y1="12" x2="23" y2="12"></line><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"></line><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"></line></svg>'
      : '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path></svg>';
  }
}

function toggleTheme() {
  const current = document.documentElement.getAttribute('data-theme') || 'dark';
  setTheme(current === 'dark' ? 'light' : 'dark');
}

// 2. Interactive Circular Focus Timer in Browser
let timerSecondsTotal = 25 * 60;
let timerSecondsRemaining = timerSecondsTotal;
let timerInterval = null;
let timerRunning = false;

function initFocusTimer() {
  const timeDisplay = document.getElementById('timer-time-display');
  const progressCircle = document.getElementById('timer-progress-circle');
  const toggleBtn = document.getElementById('timer-toggle-btn');
  const resetBtn = document.getElementById('timer-reset-btn');
  const add5mBtn = document.getElementById('timer-add5m-btn');

  if (!timeDisplay || !progressCircle) return;

  const circumference = 2 * Math.PI * 90; // r=90
  progressCircle.style.strokeDasharray = `${circumference} ${circumference}`;

  function updateDisplay() {
    const mins = Math.floor(timerSecondsRemaining / 60);
    const secs = timerSecondsRemaining % 60;
    timeDisplay.textContent = `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;

    const fraction = timerSecondsTotal > 0 ? timerSecondsRemaining / timerSecondsTotal : 0;
    const offset = circumference - (fraction * circumference);
    progressCircle.style.strokeDashoffset = offset;
  }

  function startTimer() {
    if (timerRunning) return;
    timerRunning = true;
    toggleBtn.innerHTML = '<svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><rect x="6" y="4" width="4" height="16"></rect><rect x="14" y="4" width="4" height="16"></rect></svg> Pause';
    toggleBtn.classList.remove('btn-primary');
    toggleBtn.classList.add('btn-secondary');

    timerInterval = setInterval(() => {
      if (timerSecondsRemaining > 0) {
        timerSecondsRemaining--;
        updateDisplay();
      } else {
        pauseTimer();
        alert('🎉 Focus Session Completed! +25 XP Earned!');
        resetTimer();
      }
    }, 1000);
  }

  function pauseTimer() {
    timerRunning = false;
    clearInterval(timerInterval);
    toggleBtn.innerHTML = '<svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><polygon points="5 3 19 12 5 21 5 3"></polygon></svg> Start Focus';
    toggleBtn.classList.add('btn-primary');
    toggleBtn.classList.remove('btn-secondary');
  }

  function resetTimer() {
    pauseTimer();
    timerSecondsRemaining = timerSecondsTotal;
    updateDisplay();
  }

  toggleBtn?.addEventListener('click', () => {
    if (timerRunning) {
      pauseTimer();
    } else {
      startTimer();
    }
  });

  resetBtn?.addEventListener('click', resetTimer);

  add5mBtn?.addEventListener('click', () => {
    timerSecondsTotal += 5 * 60;
    timerSecondsRemaining += 5 * 60;
    updateDisplay();
  });

  updateDisplay();
}

// 3. Tab Switchers for Screenshots
function initTabs() {
  const tabBtns = document.querySelectorAll('.tab-btn');
  tabBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      const targetId = btn.getAttribute('data-tab');
      
      document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
      document.querySelectorAll('.tab-pane').forEach(p => p.classList.remove('active'));
      
      btn.classList.add('active');
      const targetPane = document.getElementById(targetId);
      if (targetPane) targetPane.classList.add('active');
    });
  });
}

document.addEventListener('DOMContentLoaded', () => {
  initTheme();
  initFocusTimer();
  initTabs();

  const themeToggle = document.getElementById('theme-toggle-btn');
  if (themeToggle) {
    themeToggle.addEventListener('click', toggleTheme);
  }
});

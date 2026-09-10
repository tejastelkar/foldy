// Foldy Web Experience — Advanced Interactive 3D Hinge Kinetics

// Wallpapers SVG Generator
const Wallpapers = {
  sequoia: `
    <svg viewBox="0 0 560 364" preserveAspectRatio="none" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient id="sq-sky" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stop-color="#32435e"/>
          <stop offset="45%" stop-color="#647a96"/>
          <stop offset="100%" stop-color="#c0cddc"/>
        </linearGradient>
        <linearGradient id="sq-sun" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stop-color="#fff8eb"/>
          <stop offset="100%" stop-color="#fcd79d"/>
        </linearGradient>
        <linearGradient id="sq-mount1" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stop-color="#495d77"/>
          <stop offset="100%" stop-color="#2d3b4e"/>
        </linearGradient>
        <linearGradient id="sq-mount2" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stop-color="#283547"/>
          <stop offset="100%" stop-color="#141a24"/>
        </linearGradient>
      </defs>
      <rect width="560" height="364" fill="url(#sq-sky)"/>
      <circle cx="420" cy="95" r="28" fill="url(#sq-sun)" opacity="0.9"/>
      <path d="M0,230 Q140,180 280,220 T560,190 L560,364 L0,364 Z" fill="url(#sq-mount1)"/>
      <path d="M0,265 Q180,225 360,270 T560,240 L560,364 L0,364 Z" fill="url(#sq-mount2)"/>
    </svg>
  `,
  sonoma: `
    <svg viewBox="0 0 560 364" preserveAspectRatio="none" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient id="sn-sky" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stop-color="#193850"/>
          <stop offset="60%" stop-color="#5a6878"/>
          <stop offset="100%" stop-color="#f8a36c"/>
        </linearGradient>
        <linearGradient id="sn-glow" x1="0" y1="1" x2="0" y2="0">
          <stop offset="0%" stop-color="#f8a36c" stop-opacity="0.8"/>
          <stop offset="100%" stop-color="#193850" stop-opacity="0"/>
        </linearGradient>
        <linearGradient id="sn-hill1" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stop-color="#3d493a"/>
          <stop offset="100%" stop-color="#1a2018"/>
        </linearGradient>
      </defs>
      <rect width="560" height="364" fill="url(#sn-sky)"/>
      <circle cx="280" cy="270" r="160" fill="url(#sn-glow)"/>
      <path d="M0,240 Q160,200 320,250 T560,220 L560,364 L0,364 Z" fill="url(#sn-hill1)"/>
      <path d="M0,275 Q200,245 400,290 T560,260 L560,364 L0,364 Z" fill="#141812"/>
    </svg>
  `,
  aurora: `
    <svg viewBox="0 0 560 364" preserveAspectRatio="none" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient id="au-sky" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stop-color="#070e1a"/>
          <stop offset="100%" stop-color="#0f253d"/>
        </linearGradient>
        <linearGradient id="au-aurora" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stop-color="#00f2fe" stop-opacity="0.7"/>
          <stop offset="50%" stop-color="#4facfe" stop-opacity="0.5"/>
          <stop offset="100%" stop-color="#000" stop-opacity="0"/>
        </linearGradient>
      </defs>
      <rect width="560" height="364" fill="url(#au-sky)"/>
      <path d="M-50,120 Q120,40 280,110 T600,60 L600,280 L-50,280 Z" fill="url(#au-aurora)" filter="blur(20px)"/>
      <path d="M0,280 Q220,250 440,290 T560,270 L560,364 L0,364 Z" fill="#040810"/>
    </svg>
  `,
  dark: `
    <svg viewBox="0 0 560 364" preserveAspectRatio="none" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <radialGradient id="dk-grad" cx="50%" cy="40%" r="60%">
          <stop offset="0%" stop-color="#2d333b"/>
          <stop offset="100%" stop-color="#121519"/>
        </radialGradient>
      </defs>
      <rect width="560" height="364" fill="url(#dk-grad)"/>
      <circle cx="280" cy="182" r="140" fill="#384250" opacity="0.15" filter="blur(40px)"/>
    </svg>
  `
};

(function () {
  // Elements
  const screen = document.getElementById('screen');
  const wallpaperBase = document.getElementById('wallpaperBase');
  const wallpaperBlur1 = document.getElementById('wallpaperBlur1');
  const wallpaperBlur2 = document.getElementById('wallpaperBlur2');
  const wallpaperBlur3 = document.getElementById('wallpaperBlur3');
  const frostOverlay = document.getElementById('frostOverlay');
  const shade = document.getElementById('shade');
  const glintLayer = document.getElementById('glintLayer');

  // Controls
  const angleSlider = document.getElementById('hingeAngleSlider');
  const angleReadout = document.getElementById('angleReadout');
  const presetBtns = document.querySelectorAll('.preset-btn');
  const styleSegments = document.querySelectorAll('.segment');
  const wallpaperDots = document.querySelectorAll('.wp-dot');
  const soundToggle = document.getElementById('soundToggle');
  const soundIconOn = document.getElementById('soundIconOn');
  const soundIconOff = document.getElementById('soundIconOff');

  // Counter
  const bendCounter = document.getElementById('bendCounter');
  const bendTotalEl = document.getElementById('bendTotal');

  // State
  let currentAngle = 110;
  let targetProgress = 0;
  let currentProgress = 0;
  let currentStyle = 'silk';
  let currentWallpaper = 'sequoia';
  let soundEnabled = true;
  let armedForClick = true;
  let isUserDraggingSlider = false;

  // Audio Context (Synthesized crisp mechanical latch sound)
  let audioCtx = null;
  function initAudio() {
    if (!audioCtx) {
      const AudioContext = window.AudioContext || window.webkitAudioContext;
      if (AudioContext) audioCtx = new AudioContext();
    }
  }

  function playFoldSound() {
    if (!soundEnabled) return;
    try {
      initAudio();
      if (!audioCtx) return;
      if (audioCtx.state === 'suspended') audioCtx.resume();

      const t = audioCtx.currentTime;
      const osc = audioCtx.createOscillator();
      const gain = audioCtx.createGain();
      const filter = audioCtx.createBiquadFilter();

      filter.type = 'lowpass';
      filter.frequency.setValueAtTime(3200, t);
      filter.frequency.exponentialRampToValueAtTime(300, t + 0.05);

      osc.type = 'sine';
      osc.frequency.setValueAtTime(180, t);
      osc.frequency.exponentialRampToValueAtTime(45, t + 0.04);

      gain.gain.setValueAtTime(0.28, t);
      gain.gain.exponentialRampToValueAtTime(0.001, t + 0.06);

      osc.connect(filter);
      filter.connect(gain);
      gain.connect(audioCtx.destination);

      osc.start(t);
      osc.stop(t + 0.06);
    } catch (e) {
      console.warn('Audio play failed', e);
    }
  }

  // Set Wallpaper
  function applyWallpaper(name) {
    currentWallpaper = name;
    const svg = Wallpapers[name] || Wallpapers.sequoia;
    wallpaperBase.innerHTML = svg;
    wallpaperBlur1.innerHTML = svg;
    wallpaperBlur2.innerHTML = svg;
    wallpaperBlur3.innerHTML = svg;
  }
  applyWallpaper('sequoia');

  // Map lid angle [15°...110°] to progress [1.0...0.0]
  function angleToProgress(angle) {
    const clamped = Math.min(Math.max(angle, 15), 110);
    return 1 - (clamped - 15) / (110 - 15);
  }

  function progressToAngle(progress) {
    return Math.round(110 - progress * (110 - 15));
  }

  // Paint the downward folding effect
  function paint(p) {
    // 1. Rotation around bottom hinge (transform-origin: 50% 100%)
    // Tilts forward/downward toward viewer and deck
    const deg = (p * 72).toFixed(2);
    screen.style.transform = `perspective(1400px) rotateX(${deg}deg)`;

    // 2. Progressive multi-tier blur (strongest at top edge, 0 at bottom)
    wallpaperBlur1.style.opacity = Math.min(p * 1.1, 1).toFixed(3);
    wallpaperBlur2.style.opacity = Math.max(0, (p - 0.22) * 1.35).toFixed(3);
    wallpaperBlur3.style.opacity = Math.max(0, (p - 0.48) * 1.95).toFixed(3);

    // 3. Feather the top edge as it folds down
    const t = (p * 22).toFixed(2);
    const mask = `linear-gradient(to bottom, transparent 0%, rgba(0,0,0,0.25) ${(t * 0.25).toFixed(2)}%, rgba(0,0,0,0.65) ${(t * 0.55).toFixed(2)}%, #000 ${t}%)`;
    screen.style.webkitMaskImage = mask;
    screen.style.maskImage = mask;

    // 4. Horizon Shade and Style Shading
    let shadeStrength = 0.72;
    if (currentStyle === 'shade') shadeStrength = 0.96;
    if (currentStyle === 'frost') shadeStrength = 0.55;
    shade.style.opacity = (p * shadeStrength).toFixed(3);

    // 5. Frost & Glint
    if (currentStyle === 'frost') {
      frostOverlay.style.opacity = (p * 0.85).toFixed(3);
    } else {
      frostOverlay.style.opacity = '0';
    }
    glintLayer.style.opacity = (p * 0.35).toFixed(3);

    // 6. Sound & Haptic Check
    if (p > 0.80 && armedForClick) {
      armedForClick = false;
      playFoldSound();
      incrementBendCounter();
    } else if (p < 0.45 && !armedForClick) {
      armedForClick = true;
    }
  }

  // Bend Counter Management
  let bends = parseInt(localStorage.getItem('foldy_bends') || '1420', 10);
  bendTotalEl.textContent = bends.toLocaleString();

  function incrementBendCounter() {
    bends += 1;
    localStorage.setItem('foldy_bends', bends.toString());
    bendTotalEl.textContent = bends.toLocaleString();
  }

  bendCounter.addEventListener('click', () => {
    bendCounter.classList.toggle('is-purchase');
    setTimeout(() => {
      bendCounter.classList.remove('is-purchase');
    }, 3200);
  });

  // Hinge Slider Input
  angleSlider.addEventListener('input', (e) => {
    isUserDraggingSlider = true;
    currentAngle = parseFloat(e.target.value);
    angleReadout.textContent = `${Math.round(currentAngle)}°`;
    targetProgress = angleToProgress(currentAngle);

    // Update preset buttons
    presetBtns.forEach(btn => {
      const bAngle = parseFloat(btn.dataset.angle);
      btn.classList.toggle('active', Math.abs(bAngle - currentAngle) < 5);
    });
  });

  // Preset Buttons
  presetBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      presetBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      const a = parseFloat(btn.dataset.angle);
      angleSlider.value = a;
      angleReadout.textContent = `${Math.round(a)}°`;
      targetProgress = angleToProgress(a);
      isUserDraggingSlider = true;
    });
  });

  // Style Switcher
  function setStyle(style) {
    currentStyle = style;
    styleSegments.forEach(s => s.classList.toggle('active', s.dataset.style === style));

    // Sync in Settings Studio
    document.querySelectorAll('.web-style-card').forEach(c => {
      c.classList.toggle('active', c.dataset.webStyle === style);
    });
  }

  styleSegments.forEach(s => {
    s.addEventListener('click', () => setStyle(s.dataset.style));
  });

  document.querySelectorAll('.web-style-card').forEach(c => {
    c.addEventListener('click', () => setStyle(c.dataset.webStyle));
  });

  // Wallpaper Switcher
  wallpaperDots.forEach(dot => {
    dot.addEventListener('click', () => {
      wallpaperDots.forEach(d => d.classList.remove('active'));
      dot.classList.add('active');
      applyWallpaper(dot.dataset.wp);
    });
  });

  // Sound Toggle
  soundToggle.addEventListener('click', () => {
    soundEnabled = !soundEnabled;
    soundToggle.classList.toggle('active', soundEnabled);
    soundIconOn.style.display = soundEnabled ? 'block' : 'none';
    soundIconOff.style.display = soundEnabled ? 'none' : 'block';
    if (soundEnabled) playFoldSound();
  });

  // Lenis Smooth Scrolling Integration
  let lenis = null;
  const travel = 850;
  function smoothstep(t) { return t * t * (3 - 2 * t); }

  if (window.Lenis) {
    lenis = new Lenis({
      duration: 1.2,
      easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)),
      smoothWheel: true
    });

    lenis.on('scroll', (e) => {
      if (!isUserDraggingSlider) {
        const scrollY = window.scrollY;
        const rawP = Math.min(Math.max(scrollY / travel, 0), 1);
        targetProgress = smoothstep(rawP);
        currentAngle = progressToAngle(targetProgress);
        angleSlider.value = currentAngle;
        angleReadout.textContent = `${Math.round(currentAngle)}°`;
      }
    });
  } else {
    window.addEventListener('scroll', () => {
      if (!isUserDraggingSlider) {
        const scrollY = window.scrollY;
        const rawP = Math.min(Math.max(scrollY / travel, 0), 1);
        targetProgress = smoothstep(rawP);
        currentAngle = progressToAngle(targetProgress);
        angleSlider.value = currentAngle;
        angleReadout.textContent = `${Math.round(currentAngle)}°`;
      }
    }, { passive: true });
  }

  // User scrolling resets slider override after idle
  window.addEventListener('wheel', () => {
    isUserDraggingSlider = false;
  }, { passive: true });
  window.addEventListener('touchmove', () => {
    isUserDraggingSlider = false;
  }, { passive: true });

  // Animation Loop (lerp for fluid smoothness)
  function frame(time) {
    if (lenis) lenis.raf(time);

    currentProgress += (targetProgress - currentProgress) * 0.12;
    if (Math.abs(targetProgress - currentProgress) < 0.0005) {
      currentProgress = targetProgress;
    }
    paint(currentProgress);

    requestAnimationFrame(frame);
  }
  requestAnimationFrame(frame);

  // Live Clock & Time
  function updateClock() {
    const now = new Date();
    const hours = now.getHours();
    const minutes = now.getMinutes().toString().padStart(2, '0');
    const ampm = hours >= 12 ? 'PM' : 'AM';
    const displayHours = hours % 12 || 12;

    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

    const dateStr = `${days[now.getDay()]}, ${months[now.getMonth()]} ${now.getDate()}`;
    const timeStr = `${displayHours}:${minutes}`;

    const menubarTime = document.getElementById('menubarTime');
    const clockTime = document.getElementById('clockTime');
    const clockDate = document.getElementById('clockDate');

    if (menubarTime) menubarTime.textContent = `${timeStr} ${ampm}`;
    if (clockTime) clockTime.textContent = timeStr;
    if (clockDate) clockDate.textContent = dateStr;
  }
  updateClock();
  setInterval(updateClock, 1000);

  // Settings Mockup Tab Switching
  const sidebarItems = document.querySelectorAll('.sidebar-item');
  const tabPanes = document.querySelectorAll('.tab-pane');

  sidebarItems.forEach(item => {
    item.addEventListener('click', () => {
      sidebarItems.forEach(i => i.classList.remove('active'));
      tabPanes.forEach(p => p.classList.remove('active'));

      item.classList.add('active');
      const tab = item.dataset.tab;
      const targetPane = document.getElementById(`pane-${tab}`);
      if (targetPane) targetPane.classList.add('active');
    });
  });

  // Footer Year
  const yearEl = document.getElementById('year');
  if (yearEl) yearEl.textContent = new Date().getFullYear();
})();

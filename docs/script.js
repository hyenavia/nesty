/**
 * Nesty — Landing Page Interactive Scripts
 * Handles release version fetching, mobile menu, and micro-interactions
 * Unified Single Theme: Warm Espresso & Cozy Peach
 */

const APP_VERSION = "0.11.0";

// Mobile Menu Navigation Toggle
function setupMobileNav() {
  const toggle = document.getElementById("mobile-toggle");
  const menu = document.getElementById("nav-menu");
  if (toggle && menu) {
    toggle.addEventListener("click", () => {
      menu.classList.toggle("active");
    });
    // Close menu when clicking any nav item
    menu.querySelectorAll("a").forEach(link => {
      link.addEventListener("click", () => {
        menu.classList.remove("active");
      });
    });
  }
}

// Fetch Latest Release Version dynamically from GitHub API
function fetchLatestReleaseVersion() {
  fetch("https://api.github.com/repos/hyenavia/nesty/releases/latest")
    .then(res => {
      if (!res.ok) throw new Error("GitHub API unavailable or rate-limited");
      return res.json();
    })
    .then(data => {
      if (data && data.tag_name) {
        const tag = data.tag_name;
        document.querySelectorAll(".app-version-tag").forEach(el => {
          el.textContent = tag;
        });
        const heroDownloadText = document.getElementById("hero-download-text");
        if (heroDownloadText) {
          heroDownloadText.textContent = `Download APK (${tag})`;
        }
      }
    })
    .catch(() => {
      // Graceful fallback to baked-in APP_VERSION
      document.querySelectorAll(".app-version-tag").forEach(el => {
        el.textContent = `v${APP_VERSION}`;
      });
    });
}

// Interactive checklist click sound/haptic (if supported)
function setupChecklistInteractions() {
  document.querySelectorAll(".todo").forEach(item => {
    item.addEventListener("click", () => {
      if (window.navigator && window.navigator.vibrate) {
        window.navigator.vibrate(10);
      }
    });
  });
}

// Run on DOM ready
document.addEventListener("DOMContentLoaded", () => {
  setupMobileNav();
  fetchLatestReleaseVersion();
  setupChecklistInteractions();
});

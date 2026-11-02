/**
 * Nesty - Landing Page Interactive Logic (Full English)
 */

const APP_VERSION = "0.10.0";

// Showcase Tabs Data
const showcaseData = {
  beranda: {
    title: "All-in-One Calm Home Dashboard",
    desc: "View electricity token status, water gallon countdown, laundry pickup dates, daily supplies, and cleaning routines at a single glance.",
    bullets: [
      "Cozy overview cards with clear visual safety and low-stock indicators",
      "One-tap action buttons for quick token, gallon, and laundry logging",
      "Today's active routine checklist pulled directly from fast local storage"
    ]
  },
  supplies: {
    title: "Smart Inventory & Restock Tracker",
    desc: "Track essential household supplies effortlessly. Items running low are immediately highlighted so you know what to buy before you run out.",
    bullets: [
      "Categorized supplies for kitchen, bathroom, hygiene, and pantry",
      "Three intuitive stock states: Safe, Running Low, and Out of Stock",
      "Instant offline updates with transparent cloud synchronization"
    ]
  },
  utilities: {
    title: "Token & Gallon Usage Predictor",
    desc: "Never suffer an unexpected power cut or find yourself thirsty at midnight with smart usage estimates and advance reminder notifications.",
    bullets: [
      "Estimated token depletion countdown based on typical daily kWh burn",
      "Water gallon refill reminders before the last drop is finished",
      "Native device notifications powered by timezone-aware scheduling"
    ]
  },
  routines: {
    title: "Recurring Cleaning & Upkeep Routines",
    desc: "Maintain a clean, comfortable living environment with small, achievable habits scheduled on custom intervals.",
    bullets: [
      "Configurable recurring cadences (daily, bi-weekly, weekly, or custom)",
      "Gentle non-intrusive reminder alerts so tasks never pile up",
      "Bilingual interface supporting both English and Bahasa Indonesia"
    ]
  }
};

function setupShowcaseTabs() {
  const tabs = document.querySelectorAll(".showcase-tab-btn");
  tabs.forEach(tab => {
    tab.addEventListener("click", () => {
      tabs.forEach(t => t.classList.remove("active"));
      tab.classList.add("active");

      const key = tab.getAttribute("data-tab");
      const data = showcaseData[key];
      if (data) {
        document.getElementById("showcase-title").textContent = data.title;
        document.getElementById("showcase-desc").textContent = data.desc;
        
        const list = document.getElementById("showcase-bullets");
        list.innerHTML = "";
        data.bullets.forEach(b => {
          const li = document.createElement("li");
          li.innerHTML = '<span class="check-icon">✓</span> ' + b;
          list.appendChild(li);
        });
      }
    });
  });
}

// Mobile Nav Toggle
function setupMobileNav() {
  const toggle = document.getElementById("mobile-toggle");
  const nav = document.getElementById("nav-links");
  if (toggle && nav) {
    toggle.addEventListener("click", () => {
      nav.classList.toggle("active");
    });
    nav.querySelectorAll("a").forEach(link => {
      link.addEventListener("click", () => {
        nav.classList.remove("active");
      });
    });
  }
}

// Fetch latest release tag from GitHub API to keep web badges dynamically up-to-date
function fetchLatestReleaseVersion() {
  fetch("https://api.github.com/repos/hyenavia/nesty/releases/latest")
    .then(res => {
      if (!res.ok) throw new Error("GitHub API unavailable or rate-limited");
      return res.json();
    })
    .then(data => {
      if (data.tag_name) {
        const tag = data.tag_name;
        document.querySelectorAll(".app-version-tag").forEach(el => {
          el.textContent = tag;
        });
        const heroDownloadText = document.getElementById("hero-download-text");
        if (heroDownloadText) {
          heroDownloadText.textContent = `Download APK (${tag})`;
        }
        const specsVersion = document.getElementById("specs-version-val");
        if (specsVersion) {
          specsVersion.textContent = `${tag} (Release)`;
        }
      }
    })
    .catch(() => {
      // Graceful fallback to baked-in APP_VERSION
    });
}

// Init on DOM ready
document.addEventListener("DOMContentLoaded", () => {
  setupShowcaseTabs();
  setupMobileNav();
  fetchLatestReleaseVersion();
});


/**
 * ADORA CMP — Cookie consent manager custom (vanilla)
 * Version : 1.0
 * Date : 28/04/2026
 *
 * Architecture :
 *   - Bloque GA4 + Sentry par défaut (CNIL 2024)
 *   - Charge uniquement après opt-in explicite
 *   - Cloudflare Web Analytics : cookieless, exempté
 *   - Consent Mode v2 Google activé (modélisation conversions)
 *   - localStorage clé : adora_consent_v1
 *
 * Usage :
 *   1. Charger ce fichier en <head> AVANT les scripts GA4 et Sentry
 *   2. Les scripts GA4 / Sentry doivent avoir l'attribut type="text/plain"
 *      data-adora-consent="analytics" pour être différés.
 *   3. Le CMP les active dynamiquement après consentement.
 *
 * API publique :
 *   window.adoraConsent.show()    → ré-ouvre le panneau (depuis footer)
 *   window.adoraConsent.get()     → retourne l'objet consentement courant
 *   window.adoraConsent.reset()   → efface le consentement (test/debug)
 */

(function () {
  'use strict';

  const STORAGE_KEY = 'adora_consent_v1';
  const CONSENT_VERSION = 1;
  const STORAGE_DURATION_DAYS = 395; // CNIL : max 13 mois (~395 jours)

  // ─── Consent Mode v2 — set defaults BEFORE any GA loads ──────────────
  // Doit être en TOUT PREMIER (sinon GA4 ignore le consent state)
  window.dataLayer = window.dataLayer || [];
  function gtag() { window.dataLayer.push(arguments); }

  // Defaults : tout refusé (CNIL : opt-in strict)
  gtag('consent', 'default', {
    'ad_storage': 'denied',
    'ad_user_data': 'denied',
    'ad_personalization': 'denied',
    'analytics_storage': 'denied',
    'functionality_storage': 'granted',  // strictement nécessaire
    'security_storage': 'granted',       // strictement nécessaire
    'wait_for_update': 500
  });

  // Expose gtag globalement pour les autres scripts
  window.gtag = gtag;

  // ─── Helpers stockage ────────────────────────────────────────────────
  function getConsent() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return null;
      const data = JSON.parse(raw);
      // Vérifier version + expiration
      if (data.version !== CONSENT_VERSION) return null;
      const now = Date.now();
      const expires = data.timestamp + STORAGE_DURATION_DAYS * 86400000;
      if (now > expires) {
        localStorage.removeItem(STORAGE_KEY);
        return null;
      }
      return data;
    } catch (e) {
      return null;
    }
  }

  function saveConsent(analytics) {
    const data = {
      version: CONSENT_VERSION,
      analytics: !!analytics,
      timestamp: Date.now()
    };
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
    } catch (e) { /* localStorage indisponible : best effort */ }
    return data;
  }

  // ─── Activer / désactiver les scripts différés ───────────────────────
  function activateAnalytics() {
    // 1. Mettre à jour Consent Mode v2
    gtag('consent', 'update', {
      'analytics_storage': 'granted'
    });

    // 2. Activer tous les <script type="text/plain" data-adora-consent="analytics">
    const scripts = document.querySelectorAll('script[data-adora-consent="analytics"]');
    scripts.forEach(function (script) {
      // Cloner avec type=text/javascript pour exécuter
      const newScript = document.createElement('script');
      // Copier tous les attributs sauf type
      for (let i = 0; i < script.attributes.length; i++) {
        const attr = script.attributes[i];
        if (attr.name !== 'type') {
          newScript.setAttribute(attr.name, attr.value);
        }
      }
      newScript.type = 'text/javascript';
      if (script.src) {
        newScript.src = script.src;
      } else {
        newScript.text = script.text;
      }
      script.parentNode.replaceChild(newScript, script);
    });

    // 3. Émettre un event pour que d'autres scripts puissent réagir
    window.dispatchEvent(new CustomEvent('adora:consent:granted', {
      detail: { analytics: true }
    }));
  }

  function denyAnalytics() {
    gtag('consent', 'update', {
      'analytics_storage': 'denied'
    });
    window.dispatchEvent(new CustomEvent('adora:consent:denied', {
      detail: { analytics: false }
    }));
  }

  // ─── HTML du panneau ─────────────────────────────────────────────────
  function buildBanner() {
    const html = `
      <div class="adora-cmp-overlay" data-adora-cmp-state="closed">
        <div class="adora-cmp-card" role="dialog" aria-modal="false" aria-labelledby="adora-cmp-title">

          <!-- Vue 1 : bandeau initial -->
          <div class="adora-cmp-view" data-view="banner">
            <div class="adora-cmp-header">
              <span class="adora-cmp-icon" aria-hidden="true">
                <!-- Lucide cookie -->
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M12 2a10 10 0 1 0 10 10 4 4 0 0 1-5-5 4 4 0 0 1-5-5"/>
                  <path d="M8.5 8.5v.01"/>
                  <path d="M16 15.5v.01"/>
                  <path d="M12 12v.01"/>
                  <path d="M11 17v.01"/>
                  <path d="M7 14v.01"/>
                </svg>
              </span>
              <h2 id="adora-cmp-title" class="adora-cmp-title">Cookies & vie privée</h2>
            </div>

            <p class="adora-cmp-text">
              Ce site utilise des cookies pour mesurer son audience et améliorer votre expérience.
              Les cookies de mesure sont déposés uniquement avec votre accord.
              <a href="/politique-confidentialite.html" class="adora-cmp-link">En savoir plus</a>.
            </p>

            <div class="adora-cmp-actions">
              <button type="button" class="adora-cmp-btn adora-cmp-btn-primary" data-action="accept-all">
                Tout accepter
              </button>
              <button type="button" class="adora-cmp-btn adora-cmp-btn-secondary" data-action="deny-all">
                Tout refuser
              </button>
              <button type="button" class="adora-cmp-btn adora-cmp-btn-ghost" data-action="customize">
                Personnaliser
              </button>
            </div>
          </div>

          <!-- Vue 2 : personnalisation -->
          <div class="adora-cmp-view" data-view="customize" hidden>
            <div class="adora-cmp-header">
              <button type="button" class="adora-cmp-back" data-action="back" aria-label="Retour">
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="m15 18-6-6 6-6"/>
                </svg>
              </button>
              <h2 class="adora-cmp-title">Préférences</h2>
            </div>

            <div class="adora-cmp-categories">
              <!-- Strictement nécessaires (toujours actif) -->
              <div class="adora-cmp-category">
                <div class="adora-cmp-cat-head">
                  <div class="adora-cmp-cat-title">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                      <path d="M20 6 9 17l-5-5"/>
                    </svg>
                    Strictement nécessaires
                  </div>
                  <span class="adora-cmp-badge">Toujours actif</span>
                </div>
                <p class="adora-cmp-cat-desc">
                  Sécurité du site (Cloudflare), protection des formulaires (Formspree).
                  Aucun cookie publicitaire ni de profilage.
                </p>
              </div>

              <!-- Mesure d'audience (opt-in) -->
              <div class="adora-cmp-category">
                <div class="adora-cmp-cat-head">
                  <div class="adora-cmp-cat-title">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                      <path d="M3 3v18h18"/>
                      <path d="m19 9-5 5-4-4-3 3"/>
                    </svg>
                    Mesure d'audience
                  </div>
                  <label class="adora-cmp-switch">
                    <input type="checkbox" data-toggle="analytics">
                    <span class="adora-cmp-slider" aria-hidden="true"></span>
                    <span class="adora-cmp-sr">Activer la mesure d'audience</span>
                  </label>
                </div>
                <p class="adora-cmp-cat-desc">
                  Google Analytics 4 et Sentry pour comprendre l'usage du site et corriger les bugs.
                  Conservation : 14 mois maximum. Aucune donnée publicitaire.
                </p>
              </div>
            </div>

            <div class="adora-cmp-actions">
              <button type="button" class="adora-cmp-btn adora-cmp-btn-primary" data-action="save">
                Enregistrer mes choix
              </button>
            </div>
          </div>

        </div>
      </div>
    `;

    const wrapper = document.createElement('div');
    wrapper.className = 'adora-cmp-root';
    wrapper.innerHTML = html;
    return wrapper;
  }

  // ─── Logique d'affichage ─────────────────────────────────────────────
  let bannerEl = null;

  function mountBanner() {
    if (bannerEl) return;
    bannerEl = buildBanner();
    document.body.appendChild(bannerEl);
    bindEvents(bannerEl);
  }

  function showBanner() {
    if (!bannerEl) mountBanner();
    requestAnimationFrame(function () {
      bannerEl.querySelector('.adora-cmp-overlay').setAttribute('data-adora-cmp-state', 'open');
      bannerEl.querySelector('[data-view="banner"]').hidden = false;
      bannerEl.querySelector('[data-view="customize"]').hidden = true;
    });
  }

  function hideBanner() {
    if (!bannerEl) return;
    bannerEl.querySelector('.adora-cmp-overlay').setAttribute('data-adora-cmp-state', 'closed');
  }

  function showCustomize() {
    const consent = getConsent();
    const checkbox = bannerEl.querySelector('[data-toggle="analytics"]');
    if (consent && checkbox) checkbox.checked = !!consent.analytics;
    bannerEl.querySelector('[data-view="banner"]').hidden = true;
    bannerEl.querySelector('[data-view="customize"]').hidden = false;
  }

  function showInitialView() {
    bannerEl.querySelector('[data-view="banner"]').hidden = false;
    bannerEl.querySelector('[data-view="customize"]').hidden = true;
  }

  // ─── Bindings ────────────────────────────────────────────────────────
  function bindEvents(root) {
    root.addEventListener('click', function (e) {
      const target = e.target.closest('[data-action]');
      if (!target) return;
      const action = target.getAttribute('data-action');

      switch (action) {
        case 'accept-all':
          saveConsent(true);
          activateAnalytics();
          hideBanner();
          break;

        case 'deny-all':
          saveConsent(false);
          denyAnalytics();
          hideBanner();
          break;

        case 'customize':
          showCustomize();
          break;

        case 'back':
          showInitialView();
          break;

        case 'save':
          const checkbox = root.querySelector('[data-toggle="analytics"]');
          const analytics = checkbox && checkbox.checked;
          saveConsent(analytics);
          if (analytics) {
            activateAnalytics();
          } else {
            denyAnalytics();
          }
          hideBanner();
          break;
      }
    });
  }

  // ─── Init ────────────────────────────────────────────────────────────
  function init() {
    const consent = getConsent();

    if (!consent) {
      // Première visite ou consentement expiré → afficher le bandeau
      // Petit délai pour ne pas pénaliser le LCP
      setTimeout(function () {
        if (document.body) showBanner();
      }, 800);
    } else if (consent.analytics) {
      // Consentement déjà donné → activer immédiatement
      activateAnalytics();
    } else {
      // Consentement refusé en mémoire → ne rien faire (deny par défaut)
      denyAnalytics();
    }
  }

  // ─── API publique ────────────────────────────────────────────────────
  window.adoraConsent = {
    show: function () {
      mountBanner();
      showInitialView();
      requestAnimationFrame(function () {
        bannerEl.querySelector('.adora-cmp-overlay').setAttribute('data-adora-cmp-state', 'open');
      });
    },
    get: getConsent,
    reset: function () {
      try { localStorage.removeItem(STORAGE_KEY); } catch (e) {}
      console.log('[ADORA CMP] Consent reset. Recharge la page pour revoir le bandeau.');
    }
  };

  // ─── Boot ────────────────────────────────────────────────────────────
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();

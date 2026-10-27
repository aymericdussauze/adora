/* ADORA : comportement du menu commun (27/10/2026)
   Bureau : sous-menus au survol, au clic et au clavier (Échap ferme).
   Mobile : bouton menu + sous-menus en accordéon. */
(function () {
  'use strict';

  function init() {
    var nav = document.querySelector('.anav');
    if (!nav) { return; }
    var burger = nav.querySelector('.anav-burger');
    var items = Array.prototype.slice.call(nav.querySelectorAll('.anav-item'));
    var mobile = window.matchMedia('(max-width: 900px)');

    function setOpen(item, open) {
      var trigger = item.querySelector('.anav-trigger');
      if (!trigger || trigger.tagName !== 'BUTTON') { return; }
      item.classList.toggle('is-open', open);
      item.classList.remove('is-closed');
      trigger.setAttribute('aria-expanded', open ? 'true' : 'false');
    }
    function closeAll(except) {
      items.forEach(function (it) { if (it !== except) { setOpen(it, false); } });
    }

    items.forEach(function (item) {
      var trigger = item.querySelector('.anav-trigger');
      if (!trigger || trigger.tagName !== 'BUTTON') { return; }
      trigger.addEventListener('click', function () {
        var open = !item.classList.contains('is-open');
        if (!mobile.matches) { closeAll(item); }
        setOpen(item, open);
        if (!open && !mobile.matches) { item.classList.add('is-closed'); }
      });
      item.addEventListener('mouseleave', function () {
        if (mobile.matches) { return; }
        setOpen(item, false);
      });
      item.addEventListener('focusout', function (ev) {
        if (mobile.matches) { return; }
        if (!item.contains(ev.relatedTarget)) { setOpen(item, false); }
      });
      item.addEventListener('keydown', function (ev) {
        if (ev.key === 'Escape') {
          setOpen(item, false);
          if (!mobile.matches) { item.classList.add('is-closed'); }
          trigger.focus();
        }
      });
    });

    document.addEventListener('click', function (ev) {
      if (!mobile.matches && !nav.contains(ev.target)) { closeAll(null); }
    });

    if (burger) {
      burger.addEventListener('click', function () {
        var open = !nav.classList.contains('is-open');
        nav.classList.toggle('is-open', open);
        burger.setAttribute('aria-expanded', open ? 'true' : 'false');
        burger.setAttribute('aria-label', open ? 'Fermer le menu' : 'Ouvrir le menu');
      });
      nav.addEventListener('keydown', function (ev) {
        if (ev.key === 'Escape' && mobile.matches && nav.classList.contains('is-open')) {
          nav.classList.remove('is-open');
          burger.setAttribute('aria-expanded', 'false');
          burger.setAttribute('aria-label', 'Ouvrir le menu');
          burger.focus();
        }
      });
    }

    // Liens d'ancre du menu : refermer le menu mobile après le clic
    Array.prototype.forEach.call(nav.querySelectorAll('a[href^="#"]'), function (a) {
      a.addEventListener('click', function () {
        if (mobile.matches && burger) {
          nav.classList.remove('is-open');
          burger.setAttribute('aria-expanded', 'false');
          burger.setAttribute('aria-label', 'Ouvrir le menu');
        }
      });
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();

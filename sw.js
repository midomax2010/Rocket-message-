// Service worker for واتساب الحملات
// Caches the app shell (HTML/manifest/icons + the two CDN libraries) so the
// app opens instantly and still loads while offline or on a weak connection.
// Anything else (Supabase API calls, wa.me links, etc.) always goes to the
// network — that data must stay live and is never cached.

const CACHE_VERSION = 'wa-campaigns-v1';
const APP_SHELL = [
  './',
  './index.html',
  './manifest.json',
  './icons/icon-192.png',
  './icons/icon-512.png',
  'https://cdn.sheetjs.com/xlsx-0.20.3/package/dist/xlsx.full.min.js',
  'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_VERSION)
      .then(cache => cache.addAll(APP_SHELL))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(
        keys.filter(key => key !== CACHE_VERSION).map(key => caches.delete(key))
      ))
      .then(() => self.clients.claim())
  );
});

function isSupabaseRequest(url) {
  return url.hostname.endsWith('.supabase.co');
}

self.addEventListener('fetch', event => {
  const req = event.request;
  if (req.method !== 'GET') return; // never intercept writes/uploads

  const url = new URL(req.url);

  // Live data: always network, never cached.
  if (isSupabaseRequest(url)) return;

  // Navigations (opening/reloading the app): network first, cached app
  // shell as the offline fallback — this is what keeps a reload from
  // dropping the person on a blank page if the connection is flaky.
  if (req.mode === 'navigate') {
    event.respondWith(
      fetch(req)
        .then(res => {
          const copy = res.clone();
          caches.open(CACHE_VERSION).then(cache => cache.put('./index.html', copy));
          return res;
        })
        .catch(() => caches.match('./index.html'))
    );
    return;
  }

  // Static app-shell files and the CDN libraries: stale-while-revalidate —
  // instant load from cache, refreshed quietly in the background.
  if (APP_SHELL.includes(req.url) || APP_SHELL.some(a => req.url.endsWith(a.replace('./', '')))) {
    event.respondWith(
      caches.match(req).then(cached => {
        const network = fetch(req).then(res => {
          if (res && res.ok) {
            const copy = res.clone();
            caches.open(CACHE_VERSION).then(cache => cache.put(req, copy));
          }
          return res;
        }).catch(() => cached);
        return cached || network;
      })
    );
  }
});

// 앱 셸과 정적 이미지를 캐시해 오프라인·재방문 속도를 높이는 서비스 워커
const CACHE = 'massa-v1';
const SHELL = [
  './',
  './manifest.webmanifest',
  './icon-192.png',
  './icon-512.png'
];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE)
      .then(c => Promise.allSettled(SHELL.map(u => c.add(u))))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const url = new URL(e.request.url);
  // 슈퍼베이스 등 외부 요청과 GET 이외는 손대지 않는다.
  if (e.request.method !== 'GET' || url.origin !== self.location.origin) return;

  // 문서 요청은 네트워크 우선 — 배포 직후에도 최신 화면이 뜨도록 한다.
  if (e.request.mode === 'navigate') {
    e.respondWith(
      fetch(e.request)
        .then(r => { const cl = r.clone(); caches.open(CACHE).then(c => c.put('./', cl)); return r; })
        .catch(() => caches.match('./').then(r => r || Response.error()))
    );
    return;
  }

  // 이미지·아이콘 등 정적 자원은 캐시 우선.
  e.respondWith(
    caches.match(e.request).then(hit => hit || fetch(e.request).then(r => {
      if (r && r.ok && r.type === 'basic') { const cl = r.clone(); caches.open(CACHE).then(c => c.put(e.request, cl)); }
      return r;
    }))
  );
});

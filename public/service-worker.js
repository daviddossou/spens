// Spens service worker.
//
// What it does for a slow or absent network:
//   • fingerprinted assets (/assets/…) are cached on first use and served from cache
//     forever after — their name changes whenever their content does;
//   • the app icons, manifest and the offline page are precached at install;
//   • pages always go to the network (balances must be current) and fall back to the
//     offline page when it is unreachable.
// Bump VERSION to drop every old cache on the next visit.
const VERSION = "v1"
const STATIC_CACHE = `spens-static-${VERSION}`
const ASSET_CACHE = `spens-assets-${VERSION}`
const OFFLINE_URL = "/offline.html"
const PRECACHE = [OFFLINE_URL, "/manifest.json", "/icon-192.png", "/icon-512.png", "/apple-touch-icon.png"]

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(STATIC_CACHE).then((cache) => cache.addAll(PRECACHE)).then(() => self.skipWaiting())
  )
})

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((key) => ![STATIC_CACHE, ASSET_CACHE].includes(key)).map((key) => caches.delete(key))))
      .then(() => self.clients.claim())
  )
})

self.addEventListener("fetch", (event) => {
  const { request } = event
  if (request.method !== "GET") return

  const url = new URL(request.url)
  if (url.origin !== self.location.origin) return

  if (url.pathname.startsWith("/assets/")) {
    event.respondWith(cacheFirst(request, ASSET_CACHE))
  } else if (PRECACHE.includes(url.pathname)) {
    event.respondWith(cacheFirst(request, STATIC_CACHE))
  } else if (request.mode === "navigate") {
    event.respondWith(networkWithOfflineFallback(request))
  }
})

async function cacheFirst(request, cacheName) {
  const cache = await caches.open(cacheName)
  const cached = await cache.match(request)
  if (cached) return cached

  const response = await fetch(request)
  if (response.ok) cache.put(request, response.clone())
  return response
}

async function networkWithOfflineFallback(request) {
  try {
    return await fetch(request)
  } catch {
    const cache = await caches.open(STATIC_CACHE)
    return (await cache.match(OFFLINE_URL)) || Response.error()
  }
}

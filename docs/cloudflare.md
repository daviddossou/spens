# Cloudflare in front of Hetzner

Why: our users are mostly in West and Central Africa, the server is in Helsinki. Cloudflare
terminates TLS at an edge near the user and serves the fingerprinted assets, fonts and icons
from there. Dynamic pages still go to the origin, so measure `page_render_ms` (PostHog,
"Platform & locale" dashboard) before and after: the gain is in `ttfb_ms` on cold loads.

## Steps

1. Add `spens.me` to a free Cloudflare account. Cloudflare imports the current Namecheap
   records; check the MX (free forwarding) and the TXT records survive the import.
2. At Namecheap, switch the domain's nameservers to the two Cloudflare ones.
3. SSL/TLS mode: **Full (strict)**. kamal-proxy keeps its Let's Encrypt certificate and
   Cloudflare validates it, so nothing changes on the server.
4. Proxy (orange cloud) only `spens.me` and `www.spens.me`. Leave any mail-related host grey.
5. Caching: default rules already cache `/assets/*` (the response carries
   `cache-control: public, max-age=31536000`). Add a cache rule for `/*.woff2`, `/icon-*.png`,
   `/manifest.json` if their headers are shorter. Never cache HTML: it is per-user.
6. Speed: enable Brotli, HTTP/3, Early Hints. Disable Rocket Loader and Auto Minify
   (they rewrite our importmap and CSS).
7. Rails: the real client IP now arrives in `CF-Connecting-IP`. `request.remote_ip` is only used
   for the Meta Conversions API (`app/services/meta.rb`); switch it to that header when
   Cloudflare is on, or add Cloudflare's IP ranges to `config.action_dispatch.trusted_proxies`.

## Check after switching

- `curl -I https://spens.me/assets/tailwind-<digest>.css` shows `cf-cache-status: HIT` on the
  second request.
- Sign-in by OTP still works (cookies are untouched by the proxy).
- The Android app loads: its user agent is unusual, make sure no Cloudflare bot rule blocks
  "Turbo Native Android".

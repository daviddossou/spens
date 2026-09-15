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
7. Rails is ready: kamal-proxy overwrites `X-Forwarded-For` with its peer (a Cloudflare edge),
   so `Middleware::CloudflareClientIp` puts the visitor back from `CF-Connecting-IP` when that
   peer is in the Cloudflare ranges of `config/initializers/cloudflare.rb`, and `remote_ip` is
   the visitor (Meta CAPI, rate limits). Refresh the ranges from https://www.cloudflare.com/ips/
   if rate limits ever start keying on edge IPs again (check the `rate-limit:` keys in Solid
   Cache).
8. Leave "Always Use HTTPS" off (Rails `force_ssl` already redirects). kamal-proxy renews its
   Let's Encrypt certificate over the HTTP-01 challenge, which an edge redirect would break.
   Check the certificate expiry after the switch and again ~60 days later.
9. Leave Bot Fight Mode off. If it is ever enabled, add a WAF skip rule for user agents
   containing "Turbo Native" (the Android app).

## Check after switching

- `curl -I https://spens.me/assets/tailwind-<digest>.css` shows `cf-cache-status: HIT` on the
  second request.
- Sign-in by OTP still works (cookies are untouched by the proxy).
- The Android app loads: its user agent is unusual, make sure no Cloudflare bot rule blocks
  "Turbo Native Android". `/path-configuration` must answer without a challenge.
- An invitation accept link and a Meta CAPI event (Events Manager test tab shows the real
  visitor IP, not a Cloudflare one).

## Rate limits (always on)

Built-in `rate_limit`, keyed by `request.remote_ip`, answering 429 with the form and a flash:
sign-up and sign-in 5 / 10 min, OTP verify 10 / 10 min, OTP resend 3 / 10 min (per IP and per
pending user), Meta beacons 30 / min. Counters live in Solid Cache. The free plan also allows one
edge rate-limiting rule: put it on `POST /sign_up` as a second layer.

## Turnstile

Off until both keys exist. To enable:

1. Cloudflare dashboard → Turnstile → Add widget: hostnames `spens.me` and `www.spens.me`,
   mode Managed.
2. `bin/rails credentials:edit --environment production`, add:
   ```yaml
   turnstile:
     site_key: 0x...
     secret_key: 0x...
   ```
   then deploy. Locally, set `TURNSTILE_SITE_KEY=1x00000000000000000000AA` and
   `TURNSTILE_SECRET_KEY=1x0000000000000000000000000000000AA` (Cloudflare's always-pass test
   keys) in `.env` to see the widget.
3. The widget (`shared/turnstile`, `turnstile_controller.js`) renders in "interaction-only"
   mode on sign-up and sign-in: nothing is shown unless Cloudflare is unsure. The server checks
   the token with siteverify (`app/services/turnstile.rb`); a bad or missing token re-renders the
   form with `auth.turnstile_failed`, an unreachable siteverify lets the request through.
4. Test on web, in the Android app and in a private window. Watch the `turnstile_failed`
   PostHog event for a week; if real users hit it, switch the widget to non-interactive mode.
   If a CSP is ever enforced, allow `challenges.cloudflare.com` in `script-src` and `frame-src`.

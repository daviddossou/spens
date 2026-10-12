// Where the page is open, to pick the right install path.
// os: "ios" | "android" | "desktop". inApp: an app's built-in browser
// (WhatsApp, Instagram, Facebook...), which can't install a web app.
export function detectPlatform(nav = navigator) {
  const ua = nav.userAgent || ""
  const ios = /iphone|ipad|ipod/i.test(ua) || (nav.platform === "MacIntel" && nav.maxTouchPoints > 1)
  const android = !ios && /android/i.test(ua)
  const inApp = /FBAN|FBAV|FB_IAB|Instagram|WhatsApp|Snapchat|TikTok|musical_ly|Line\/|Twitter/i.test(ua) ||
    (android && /; wv\)/.test(ua))
  const safari = ios && /safari/i.test(ua) && !/crios|fxios|edgios|opios/i.test(ua) && !inApp

  return { os: ios ? "ios" : android ? "android" : "desktop", inApp, safari }
}

export function isStandalone() {
  return window.matchMedia("(display-mode: standalone)").matches || window.navigator.standalone === true
}

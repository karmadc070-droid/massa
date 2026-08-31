// 네이티브(iOS) 전용 기능을 window.MassaNative 로 노출하는 번들 진입점 — esbuild로 묶여 앱 www에만 주입된다
import { Capacitor } from "@capacitor/core";
import { PushNotifications } from "@capacitor/push-notifications";
import { Geolocation } from "@capacitor/geolocation";
import { Browser } from "@capacitor/browser";
import { App } from "@capacitor/app";

// iOS WKWebView는 navigator.geolocation 을 기본 제공하지 않는다.
// index.html은 navigator.geolocation 만 쓰므로, 플러그인으로 같은 모양의 API를 덮어써서 코드 변경 없이 동작시킨다.
// 주의: navigator.geolocation 은 getter만 있는 접근자라 단순 대입은 조용히 무시된다. 반드시 defineProperty 를 써야 한다.
function shimGeolocation() {
  const watches = new Map();
  const impl = {
    getCurrentPosition(ok, err, opts) {
      Geolocation.getCurrentPosition(opts).then(ok).catch(err || (() => {}));
    },
    watchPosition(ok, err, opts) {
      const key = Date.now() + Math.random();
      Geolocation.watchPosition(opts || {}, (pos, e) => {
        if (e) { if (err) err(e); return; }
        ok(pos);
      }).then((id) => watches.set(key, id));
      return key;
    },
    clearWatch(key) {
      const id = watches.get(key);
      if (id) { Geolocation.clearWatch({ id }); watches.delete(key); }
    },
  };
  Object.defineProperty(navigator, "geolocation", { value: impl, configurable: true, writable: true });
  return navigator.geolocation === impl;
}

// APNs 푸시 등록. 권한 허용 시 onToken(디바이스 토큰) 을 호출한다.
async function registerPush(onToken, onNotification) {
  const perm = await PushNotifications.requestPermissions();
  if (perm.receive !== "granted") return false;
  PushNotifications.addListener("registration", (t) => onToken(t.value));
  if (onNotification) {
    PushNotifications.addListener("pushNotificationReceived", onNotification);
    PushNotifications.addListener("pushNotificationActionPerformed", onNotification);
  }
  await PushNotifications.register();
  return true;
}

// 소셜 로그인·결제창을 앱 안 브라우저(SFSafariViewController)로 연다.
// 사파리로 나가버리면 앱으로 돌아올 수 없고 App Store 가이드라인 4 소지도 생긴다.
async function openExternal(url) {
  await Browser.open({ url, presentationStyle: "popover" });
}

// massa:// 로 되돌아왔을 때를 처리한다.
// 로그인은 massa://auth, 결제는 massa://pay 로 온다.
// 둘 다 실패 시 code= 를 달고 오므로 파라미터가 아니라 호스트로 갈라야 한다.
function handleAppUrl(url) {
  try {
    Browser.close().catch(() => {});
    const u = new URL(url);
    const target = u.host || u.pathname.replace(/^\/+/, "");
    if (target === "pay") {
      if (window.onNativePayReturn) window.onNativePayReturn(u.search);
      return;
    }
    // 로그인 — 토큰은 # 뒤에, PKCE 코드는 ? 뒤에 붙는다. 그대로 넘기면 supabase-js 가 세션을 세운다
    if (window.onNativeAuthReturn) window.onNativeAuthReturn(u.hash && u.hash.includes("access_token") ? u.hash : u.search);
  } catch (e) { console.error("appUrlOpen 처리 실패", e); }
}

let geoShimmed = false;
if (Capacitor.isNativePlatform()) {
  geoShimmed = shimGeolocation();
  if (!geoShimmed) console.error("navigator.geolocation 대체 실패 — 위치 기능이 동작하지 않을 수 있음");
  App.addListener("appUrlOpen", (e) => handleAppUrl(e.url));
}

window.IS_NATIVE_APP = Capacitor.isNativePlatform();
window.openExternal = openExternal;
window.MassaNative = {
  platform: Capacitor.getPlatform(),
  isNative: Capacitor.isNativePlatform(),
  geoShimmed,
  registerPush,
  openExternal,
};

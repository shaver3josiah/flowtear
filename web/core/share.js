// Share/export seam. Inside the APK this goes through Capacitor's native bridge
// so we get the real Android share sheet — the counterpart of iOS's ShareLink.
// In a plain desktop browser (no bridge) it falls back to Web Share / clipboard
// / a Blob download.
//
// NOTE: a Capacitor WebView will NOT honour a `blob:` download (there's no
// DownloadListener), so on Android the Filesystem+Share path is the one that
// actually works — the Blob path below is the browser-only fallback.

import { available, call } from "./capacitor.js";

export const hasNativeShare = () => available("Share");

/// Share plain text. Returns a short status line to show her, or null when the OS
/// handled it (or she dismissed the sheet — nothing to say about that).
export async function shareText({ title, text }) {
  if (available("Share")) {
    try { await call("Share", "share", { title, text, dialogTitle: title }); } catch { /* dismissed */ }
    return null;
  }
  if (typeof navigator !== "undefined" && navigator.share) {
    try { await navigator.share({ title, text }); } catch { /* dismissed */ }
    return null;
  }
  try {
    await navigator.clipboard.writeText(text);
    return "Copied to your clipboard.";
  } catch {
    return "Your browser wouldn't let us copy it.";
  }
}

/// Write a file and hand it to the OS. Returns "shared" (native sheet) or
/// "downloaded" (browser fallback) so the caller can word the confirmation.
export async function shareFile({ filename, data, mimeType = "text/csv", dialogTitle = "Your data" }) {
  if (available("Filesystem") && available("Share")) {
    // "CACHE" = Directory.Cache, "utf8" = Encoding.UTF8 — raw strings because the
    // enums live in the npm package we can't import in a no-build app.
    const { uri } = await call("Filesystem", "writeFile", {
      path: filename, data, directory: "CACHE", encoding: "utf8",
    });
    try { await call("Share", "share", { title: filename, url: uri, dialogTitle }); } catch { /* dismissed */ }
    return "shared";
  }
  const url = URL.createObjectURL(new Blob([data], { type: `${mimeType};charset=utf-8` }));
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 0); // let the download start before we let go
  return "downloaded";
}

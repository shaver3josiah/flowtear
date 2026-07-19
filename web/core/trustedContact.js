// TrustedContact — a port of App/Components/MessageComposers.swift's
// TrustedContact struct: the one saved person (a partner, a doctor's office)
// reports go to. { name, relationship, email, phone }, persisted as JSON at
// the exact UserDefaults key Swift uses so a report shared to this key reads
// identically on either platform.
//
// Pure module: no window/localStorage access at import time, only inside
// load()/save()/clear() when they're called.

const KEY = "flowtear.trusted"; // MessageComposers.swift:20 — must match exactly

/** A blank contact, handy for seeding an edit form. */
export function emptyContact() {
  return { name: "", relationship: "", email: "", phone: "" };
}

/** The saved contact, or null if none is saved or the stored JSON is bad. */
export function load() {
  let raw;
  try { raw = localStorage.getItem(KEY); } catch { return null; }
  if (!raw) return null;
  try {
    const c = JSON.parse(raw);
    if (!c || typeof c !== "object") return null;
    return {
      name: c.name ?? "", relationship: c.relationship ?? "",
      email: c.email ?? "", phone: c.phone ?? "",
    };
  } catch { return null; }
}

/** Persists `contact` ({ name, relationship, email, phone }) at KEY. */
export function save(contact) {
  localStorage.setItem(KEY, JSON.stringify(contact));
}

export function clear() {
  localStorage.removeItem(KEY);
}

// TrustedContact.hasEmail/hasPhone — non-empty after trimming whitespace.
export const hasEmail = (contact) => !!(contact?.email ?? "").trim();
export const hasPhone = (contact) => !!(contact?.phone ?? "").trim();

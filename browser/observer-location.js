'use strict';
// Vendored unchanged calculations from pastafari-calendar/docs/observer-location.js
(function (root) {
  const ns = root.PastafariBrowserInternal || (root.PastafariBrowserInternal = Object.create(null));
"use strict";

// Default terrestrial observer: Kisurra (modern Ishān Abū Ḥaṭab), Iraq.
// CDLI gives the site coordinates as longitude 45.481 E, latitude 31.8383 N.
// https://cdli.earth/proveniences/314
const KISURRA_OBSERVER = Object.freeze({
  latitude: 31.8383,
  longitude: 45.481,
  elevationM: 0,
  source: "kisurra",
  assumed: true,
});

function frozenKisurra(reason) {
  return Object.freeze({ ...KISURRA_OBSERVER, reason });
}

function normalizePosition(position) {
  const coordinates = position?.coords;
  const latitude = Number(coordinates?.latitude);
  const longitude = Number(coordinates?.longitude);
  const altitude = coordinates?.altitude;
  if (!Number.isFinite(latitude) || latitude < -90 || latitude > 90) return null;
  if (!Number.isFinite(longitude) || longitude < -180 || longitude > 180) return null;
  const elevationM = Number.isFinite(Number(altitude)) ? Number(altitude) : 0;
  return Object.freeze({
    latitude,
    longitude,
    elevationM,
    accuracyM: Number.isFinite(Number(coordinates?.accuracy)) ? Number(coordinates.accuracy) : null,
    source: "device",
    assumed: false,
    reason: "permission-granted",
  });
}

function getCurrentPosition(geolocation, options) {
  return new Promise((resolve, reject) => {
    geolocation.getCurrentPosition(resolve, reject, options);
  });
}

async function requestObserverLocation({
  navigatorObject = globalThis.navigator,
  timeoutMs = 10_000,
  maximumAgeMs = 60_000,
} = {}) {
  if (!navigatorObject?.geolocation?.getCurrentPosition) {
    return frozenKisurra("geolocation-unavailable");
  }

  // This function is intentionally separate from resolveObserverLocation().
  // Calling it is an explicit user action and therefore may trigger the
  // browser's geolocation permission prompt.
  try {
    const position = await getCurrentPosition(navigatorObject.geolocation, {
      enableHighAccuracy: false,
      timeout: timeoutMs,
      maximumAge: maximumAgeMs,
    });
    return normalizePosition(position) ?? frozenKisurra("invalid-device-position");
  } catch {
    return frozenKisurra("device-position-unavailable");
  }
}

async function resolveObserverLocation({
  navigatorObject = globalThis.navigator,
  timeoutMs = 4_000,
  maximumAgeMs = 6 * 60 * 60 * 1000,
} = {}) {
  // Do not cause a permission prompt merely by opening the calendar.  Device
  // location is used only when the browser already reports permission=granted.
  if (!navigatorObject?.permissions?.query || !navigatorObject?.geolocation?.getCurrentPosition) {
    return frozenKisurra("geolocation-unavailable");
  }

  let permission;
  try {
    permission = await navigatorObject.permissions.query({ name: "geolocation" });
  } catch {
    return frozenKisurra("permission-state-unavailable");
  }
  if (permission.state !== "granted") return frozenKisurra(`permission-${permission.state}`);

  try {
    const position = await getCurrentPosition(navigatorObject.geolocation, {
      enableHighAccuracy: false,
      timeout: timeoutMs,
      maximumAge: maximumAgeMs,
    });
    return normalizePosition(position) ?? frozenKisurra("invalid-device-position");
  } catch {
    return frozenKisurra("device-position-unavailable");
  }
}

async function watchObserverPermission(callback, {
  navigatorObject = globalThis.navigator,
} = {}) {
  if (typeof callback !== "function") throw new TypeError("callback must be a function.");
  if (!navigatorObject?.permissions?.query) return () => {};
  let permission;
  try {
    permission = await navigatorObject.permissions.query({ name: "geolocation" });
  } catch {
    return () => {};
  }

  const handleChange = () => {
    Promise.resolve(resolveObserverLocation({ navigatorObject }))
      .then((observer) => callback(observer))
      .catch(() => callback(frozenKisurra("permission-change-error")));
  };

  if (typeof permission.addEventListener === "function") {
    permission.addEventListener("change", handleChange);
    return () => permission.removeEventListener("change", handleChange);
  }
  const previous = permission.onchange;
  permission.onchange = handleChange;
  return () => {
    if (permission.onchange === handleChange) permission.onchange = previous ?? null;
  };
}

  ns.observerLocation = Object.freeze({ KISURRA_OBSERVER, requestObserverLocation, resolveObserverLocation, watchObserverPermission });
})(typeof globalThis === 'object' ? globalThis : this);

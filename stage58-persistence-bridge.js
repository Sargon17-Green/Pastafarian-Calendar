'use strict';

const codec = require('./cache-codec');

const DIRECT_BINDINGS = Object.freeze([
  ['gate-days', (core) => core.STAGE57_GLOBAL_GATE_REGISTRY.stage58GateMemoryScar.gates],
  ['gate-gaps', (core) => core.STAGE57_GLOBAL_GATE_REGISTRY.stage58GateMemoryScar.gaps],
  ['year-5000', (core) => core.STAGE57_GLOBAL_MANAGER.stage58YearMemoryScar.year5000ByCalculationDay],
  ['year-transitions', (core) => core.STAGE57_GLOBAL_MANAGER.stage58YearMemoryScar.transitions],
  ['year-histories', (core) => core.STAGE57_GLOBAL_MANAGER.stage58YearMemoryScar.authoritativeHistories],
  ['semantic-structures', (core) => core.STAGE57_GLOBAL_MANAGER.STAGE58_SEMANTIC_STRUCTURE_CACHE],
]);

const SHADOW_SCOPES = Object.freeze({
  'selection-results': Object.freeze({ label: 'INTEGRATED_SELECTION_REJECTION', limit: 4096, kind: 'bounded' }),
  'sauce-stage56': Object.freeze({ label: 'SAUCE_STAGE56_WEAK', limit: 128, kind: 'weak' }),
});

function resolveBindings(core) {
  const out = [];
  for (const [scope, resolver] of DIRECT_BINDINGS) {
    let cache;
    try { cache = resolver(core); } catch (_) { cache = null; }
    if (!cache || !(cache.map instanceof Map) || typeof cache.set !== 'function' || typeof cache.get !== 'function') {
      throw new TypeError('Stage 59 ne trova li expectat Stage 58 cache scope: ' + scope);
    }
    out.push({ scope, cache });
  }
  return out;
}

function touchBounded(map, key, value, limit) {
  if (map.has(key)) map.delete(key);
  map.set(key, value);
  while (map.size > limit) map.delete(map.keys().next().value);
}

class Stage58PersistenceBridge {
  constructor(core, initialSnapshots) {
    this.core = core;
    this.bindings = resolveBindings(core);
    this.byScope = new Map(this.bindings.map((binding) => [binding.scope, binding]));
    this.shadow = new Map(Object.keys(SHADOW_SCOPES).map((scope) => [scope, new Map()]));
    this.dirtyScopes = new Set();
    this.skippedNonPortable = 0;
    this.hydratedEntries = 0;
    this.transaction = null;
    this._hydrate(initialSnapshots || Object.create(null));
    this._patchShadowCaches();
    this._wrapDirectSets();
  }

  _decodeEntries(encoded) {
    let entries;
    try { entries = typeof encoded === 'string' ? codec.decode(encoded) : encoded; }
    catch (_) { return []; }
    return Array.isArray(entries) ? entries : [];
  }

  _hydrate(initialSnapshots) {
    for (const [scope, encoded] of Object.entries(initialSnapshots)) {
      if (encoded == null) continue;
      const entries = this._decodeEntries(encoded);
      const binding = this.byScope.get(scope);
      if (binding) {
        for (const pair of entries) {
          if (!Array.isArray(pair) || pair.length !== 2) continue;
          const [key, value] = pair;
          if (typeof key !== 'string' || !codec.isPortable(value)) continue;
          binding.cache.set(key, codec.deepFreezePortable(value));
          this.hydratedEntries += 1;
        }
        continue;
      }
      const config = SHADOW_SCOPES[scope];
      const shadow = this.shadow.get(scope);
      if (!config || !shadow) continue;
      for (const pair of entries) {
        if (!Array.isArray(pair) || pair.length !== 2) continue;
        const [key, value] = pair;
        if (typeof key !== 'string' || !codec.isPortable(value)) continue;
        touchBounded(shadow, key, codec.deepFreezePortable(value), config.limit);
        this.hydratedEntries += 1;
      }
    }
    this.dirtyScopes.clear();
  }

  _touchSpecialInstance(instance) {
    if (!this.transaction || this.transaction.specialMaps.has(instance)) return;
    this.transaction.specialMaps.set(instance, new Map(instance.map));
  }

  beginTransaction() {
    if (this.transaction) throw new Error('Un Stage 59 cache transaction es ja activ.');
    this.transaction = {
      directMaps: new Map(this.bindings.map(({ cache }) => [cache, new Map(cache.map)])),
      shadowMaps: new Map(Array.from(this.shadow.entries(), ([scope, map]) => [scope, new Map(map)])),
      specialMaps: new Map(),
      dirtyBefore: new Set(this.dirtyScopes),
    };
  }

  rollbackTransaction() {
    if (!this.transaction) return;
    const tx = this.transaction;
    for (const [cache, snapshot] of tx.directMaps.entries()) cache.map = new Map(snapshot);
    for (const [scope, snapshot] of tx.shadowMaps.entries()) this.shadow.set(scope, new Map(snapshot));
    for (const [instance, snapshot] of tx.specialMaps.entries()) instance.map = new Map(snapshot);
    this.dirtyScopes = new Set(tx.dirtyBefore);
    this.transaction = null;
  }

  commitTransaction() {
    if (!this.transaction) throw new Error('Null Stage 59 cache transaction es activ.');
    const snapshots = this.drainChangedSnapshots();
    this.transaction = null;
    return snapshots;
  }

  _patchShadowCaches() {
    const boundedProto = this.core.Stage58BoundedRememberingScar && this.core.Stage58BoundedRememberingScar.prototype;
    const weakProto = this.core.Stage58WeakRememberingScar && this.core.Stage58WeakRememberingScar.prototype;
    if (!boundedProto || !weakProto) throw new TypeError('Stage 59 ne trova li Stage 58 cache prototypes.');

    const selectionConfig = SHADOW_SCOPES['selection-results'];
    const selectionShadow = this.shadow.get('selection-results');
    const boundedGet = boundedProto.get;
    const boundedSet = boundedProto.set;
    const bridge = this;
    boundedProto.get = function stage59PersistentBoundedGet(key) {
      if (this.label === selectionConfig.label) bridge._touchSpecialInstance(this);
      const hit = boundedGet.call(this, key);
      if (hit !== null || this.label !== selectionConfig.label) return hit;
      key = String(key);
      if (!selectionShadow.has(key)) return null;
      const value = selectionShadow.get(key);
      touchBounded(selectionShadow, key, value, selectionConfig.limit);
      boundedSet.call(this, key, value);
      return value;
    };
    boundedProto.set = function stage59PersistentBoundedSet(key, value) {
      if (this.label === selectionConfig.label) bridge._touchSpecialInstance(this);
      const result = boundedSet.call(this, key, value);
      if (this.label === selectionConfig.label) {
        key = String(key);
        if (codec.isPortable(value)) {
          touchBounded(selectionShadow, key, value, selectionConfig.limit);
          bridge.dirtyScopes.add('selection-results');
        } else bridge.skippedNonPortable += 1;
      }
      return result;
    };

    const sauceConfig = SHADOW_SCOPES['sauce-stage56'];
    const sauceShadow = this.shadow.get('sauce-stage56');
    const weakGet = weakProto.get;
    const weakSet = weakProto.set;
    weakProto.get = function stage59PersistentWeakGet(key) {
      if (this.label === sauceConfig.label) bridge._touchSpecialInstance(this);
      const hit = weakGet.call(this, key);
      if (hit !== null || this.label !== sauceConfig.label) return hit;
      key = String(key);
      if (!sauceShadow.has(key)) return null;
      const value = sauceShadow.get(key);
      touchBounded(sauceShadow, key, value, sauceConfig.limit);
      weakSet.call(this, key, value);
      return value;
    };
    weakProto.set = function stage59PersistentWeakSet(key, value) {
      if (this.label === sauceConfig.label) bridge._touchSpecialInstance(this);
      const result = weakSet.call(this, key, value);
      if (this.label === sauceConfig.label) {
        key = String(key);
        if (codec.isPortable(value)) {
          touchBounded(sauceShadow, key, value, sauceConfig.limit);
          bridge.dirtyScopes.add('sauce-stage56');
        } else bridge.skippedNonPortable += 1;
      }
      return result;
    };
  }

  _wrapDirectSets() {
    for (const binding of this.bindings) {
      const cache = binding.cache;
      const originalSet = cache.set.bind(cache);
      cache.set = (key, value) => {
        const result = originalSet(key, value);
        if (codec.isPortable(value)) this.dirtyScopes.add(binding.scope);
        else this.skippedNonPortable += 1;
        return result;
      };
    }
  }

  drainChangedSnapshots() {
    const out = Object.create(null);
    for (const scope of this.dirtyScopes) {
      const binding = this.byScope.get(scope);
      const source = binding ? binding.cache.map : this.shadow.get(scope);
      if (!source) continue;
      const entries = [];
      for (const [key, value] of source.entries()) {
        if (typeof key !== 'string' || !codec.isPortable(value)) {
          this.skippedNonPortable += 1;
          continue;
        }
        entries.push([key, value]);
      }
      out[scope] = codec.encode(entries);
    }
    this.dirtyScopes.clear();
    return out;
  }

  status() {
    const scopes = Object.fromEntries(this.bindings.map(({ scope, cache }) => [
      scope,
      Object.freeze({ entries: cache.map.size, limit: cache.limit || null }),
    ]));
    for (const [scope, map] of this.shadow.entries()) {
      scopes[scope] = Object.freeze({ entries: map.size, limit: SHADOW_SCOPES[scope].limit });
    }
    return Object.freeze({
      hydratedEntries: this.hydratedEntries,
      skippedNonPortable: this.skippedNonPortable,
      scopes: Object.freeze(scopes),
    });
  }
}

module.exports = Object.freeze({ Stage58PersistenceBridge, DIRECT_BINDINGS, SHADOW_SCOPES });

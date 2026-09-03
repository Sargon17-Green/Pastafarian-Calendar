'use strict';

const fs = require('node:fs/promises');
const path = require('node:path');

class MemoryCacheStore {
  constructor() {
    this.values = new Map();
  }
  async get(key) { return this.values.has(String(key)) ? this.values.get(String(key)) : null; }
  async set(key, value) { this.values.set(String(key), String(value)); }
  async delete(key) { this.values.delete(String(key)); }
  async close() {}
}

class FileCacheStore {
  constructor(filePath) {
    this.filePath = path.resolve(String(filePath));
    this.values = new Map();
    this.loaded = false;
    this.writeChain = Promise.resolve();
  }

  async _load() {
    if (this.loaded) return;
    this.loaded = true;
    try {
      const parsed = JSON.parse(await fs.readFile(this.filePath, 'utf8'));
      if (parsed && parsed.version === 1 && parsed.values && typeof parsed.values === 'object') {
        for (const [key, value] of Object.entries(parsed.values)) {
          if (typeof value === 'string') this.values.set(key, value);
        }
      }
    } catch (error) {
      if (error && error.code !== 'ENOENT') throw error;
    }
  }

  async _persist() {
    const payload = JSON.stringify({
      version: 1,
      values: Object.fromEntries(this.values),
    });
    const directory = path.dirname(this.filePath);
    const tmp = this.filePath + '.tmp-' + process.pid + '-' + Date.now();
    await fs.mkdir(directory, { recursive: true });
    await fs.writeFile(tmp, payload, 'utf8');
    await fs.rename(tmp, this.filePath);
  }

  async _queuePersist() {
    this.writeChain = this.writeChain.then(() => this._persist());
    return this.writeChain;
  }

  async get(key) {
    await this._load();
    key = String(key);
    return this.values.has(key) ? this.values.get(key) : null;
  }

  async set(key, value) {
    await this._load();
    this.values.set(String(key), String(value));
    await this._queuePersist();
  }

  async delete(key) {
    await this._load();
    if (this.values.delete(String(key))) await this._queuePersist();
  }

  async close() {
    await this.writeChain;
  }
}

class RedisCacheStore {
  constructor(url) {
    this.url = String(url);
    this.client = null;
  }

  async _client() {
    if (this.client) return this.client;
    let redis;
    try {
      redis = require('redis');
    } catch (error) {
      const wrapped = new Error(
        'Li Redis cache exige li server dependency `redis`. Execut `npm install` in server/.'
      );
      wrapped.cause = error;
      throw wrapped;
    }
    const client = redis.createClient({ url: this.url });
    client.on('error', () => {});
    await client.connect();
    this.client = client;
    return client;
  }

  async get(key) {
    const client = await this._client();
    return client.get(String(key));
  }

  async set(key, value) {
    const client = await this._client();
    await client.set(String(key), String(value));
  }

  async delete(key) {
    const client = await this._client();
    await client.del(String(key));
  }

  async close() {
    if (!this.client) return;
    const client = this.client;
    this.client = null;
    if (client.isOpen) await client.quit();
  }
}

function createCacheStoreFromEnv(env, rootDirectory) {
  const selected = env || process.env;
  if (selected.PASTAFARI_REDIS_URL) return new RedisCacheStore(selected.PASTAFARI_REDIS_URL);
  const base = rootDirectory || path.resolve(__dirname, '..');
  const filePath = selected.PASTAFARI_CACHE_FILE || path.join(base, '.pastafari-cache', 'stage59.json');
  return new FileCacheStore(filePath);
}

module.exports = Object.freeze({
  MemoryCacheStore,
  FileCacheStore,
  RedisCacheStore,
  createCacheStoreFromEnv,
});

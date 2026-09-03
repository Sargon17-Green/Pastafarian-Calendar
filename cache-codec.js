'use strict';

const TAG = '$pastafariStage59';

function encodeNode(value, seen) {
  if (value === null) return ['null'];
  const type = typeof value;
  if (type === 'bigint') return ['bigint', value.toString()];
  if (type === 'string') return ['string', value];
  if (type === 'boolean') return ['boolean', value];
  if (type === 'undefined') return ['undefined'];
  if (type === 'number') {
    if (Number.isNaN(value)) return ['number', 'NaN'];
    if (value === Infinity) return ['number', '+Infinity'];
    if (value === -Infinity) return ['number', '-Infinity'];
    if (Object.is(value, -0)) return ['number', '-0'];
    return ['number', value];
  }
  if (type !== 'object') {
    throw new TypeError('Stage 59 cache ne posse serialisar ti value-type: ' + type);
  }
  if (seen.has(value)) {
    throw new TypeError('Stage 59 cache ne accepte cyclic object graphs.');
  }
  seen.add(value);
  try {
    if (Array.isArray(value)) {
      return ['array', value.map((item) => encodeNode(item, seen))];
    }
    if (value instanceof Map) {
      return ['map', Array.from(value.entries(), ([key, item]) => [
        encodeNode(key, seen),
        encodeNode(item, seen),
      ])];
    }
    if (value instanceof Set) {
      return ['set', Array.from(value.values(), (item) => encodeNode(item, seen))];
    }
    const proto = Object.getPrototypeOf(value);
    if (proto !== Object.prototype && proto !== null) {
      throw new TypeError('Stage 59 cache ne persiste objects con custom prototypes.');
    }
    const entries = [];
    for (const key of Object.keys(value)) entries.push([key, encodeNode(value[key], seen)]);
    return ['object', proto === null ? 1 : 0, entries];
  } finally {
    seen.delete(value);
  }
}

function decodeNode(node) {
  if (!Array.isArray(node) || typeof node[0] !== 'string') {
    throw new TypeError('Ínvalid Stage 59 cache payload.');
  }
  switch (node[0]) {
    case 'null': return null;
    case 'bigint': return BigInt(node[1]);
    case 'string': return String(node[1]);
    case 'boolean': return Boolean(node[1]);
    case 'undefined': return undefined;
    case 'number': {
      if (node[1] === 'NaN') return NaN;
      if (node[1] === '+Infinity') return Infinity;
      if (node[1] === '-Infinity') return -Infinity;
      if (node[1] === '-0') return -0;
      if (typeof node[1] !== 'number') throw new TypeError('Ínvalid cached number.');
      return node[1];
    }
    case 'array': return node[1].map(decodeNode);
    case 'map': return new Map(node[1].map(([key, value]) => [decodeNode(key), decodeNode(value)]));
    case 'set': return new Set(node[1].map(decodeNode));
    case 'object': {
      const out = node[1] === 1 ? Object.create(null) : {};
      for (const [key, value] of node[2]) out[key] = decodeNode(value);
      return out;
    }
    default:
      throw new TypeError('Ínconosset Stage 59 cache tag: ' + node[0]);
  }
}

function encode(value) {
  return JSON.stringify({ [TAG]: 1, value: encodeNode(value, new Set()) });
}

function decode(text) {
  const parsed = JSON.parse(String(text));
  if (!parsed || parsed[TAG] !== 1) throw new TypeError('Ínvalid Stage 59 cache envelope.');
  return decodeNode(parsed.value);
}

function isPortable(value) {
  try {
    encode(value);
    return true;
  } catch (_) {
    return false;
  }
}

function deepFreezePortable(value, seen) {
  if (value === null || typeof value !== 'object') return value;
  const visited = seen || new Set();
  if (visited.has(value)) return value;
  visited.add(value);
  if (Array.isArray(value)) {
    for (const item of value) deepFreezePortable(item, visited);
    return Object.freeze(value);
  }
  if (value instanceof Map) {
    for (const [key, item] of value.entries()) {
      deepFreezePortable(key, visited);
      deepFreezePortable(item, visited);
    }
    return Object.freeze(value);
  }
  if (value instanceof Set) {
    for (const item of value.values()) deepFreezePortable(item, visited);
    return Object.freeze(value);
  }
  for (const key of Object.keys(value)) deepFreezePortable(value[key], visited);
  return Object.freeze(value);
}

module.exports = Object.freeze({ encode, decode, isPortable, deepFreezePortable });

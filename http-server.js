'use strict';

const http = require('node:http');
const { URL } = require('node:url');

function tupleToJson(tuple) {
  return Object.freeze({
    tuple: Object.freeze(tuple.map((value) => typeof value === 'bigint' ? value.toString() : String(value))),
    date: Object.freeze({
      year: tuple[0].toString(),
      cutletName: String(tuple[1]),
      dayInCutlet: tuple[2].toString(),
      monthName: String(tuple[3]),
      dayInMonth: tuple[4].toString(),
    }),
  });
}

function sendJson(res, status, payload, headers) {
  const text = JSON.stringify(payload);
  res.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'content-length': Buffer.byteLength(text),
    'cache-control': 'no-store',
    ...(headers || {}),
  });
  res.end(text);
}

async function readJson(req, maxBytes) {
  const chunks = [];
  let total = 0;
  for await (const chunk of req) {
    total += chunk.length;
    if (total > maxBytes) throw Object.assign(new Error('Request body es tro grand.'), { statusCode: 413 });
    chunks.push(chunk);
  }
  if (chunks.length === 0) return {};
  return JSON.parse(Buffer.concat(chunks).toString('utf8'));
}

function createHttpServer(engine, options) {
  const selected = options || {};
  const corsOrigin = selected.corsOrigin == null ? '*' : String(selected.corsOrigin);
  const maxBodyBytes = selected.maxBodyBytes || 16 * 1024;

  return http.createServer(async (req, res) => {
    const cors = corsOrigin ? { 'access-control-allow-origin': corsOrigin } : {};
    try {
      const url = new URL(req.url, 'http://localhost');
      if (req.method === 'OPTIONS') {
        res.writeHead(204, {
          ...cors,
          'access-control-allow-methods': 'GET,POST,OPTIONS',
          'access-control-allow-headers': 'content-type',
          'access-control-max-age': '86400',
        });
        res.end();
        return;
      }
      if (req.method === 'GET' && url.pathname === '/healthz') {
        await engine.initialize();
        sendJson(res, 200, { ok: true, fingerprint: engine.fingerprint }, cors);
        return;
      }
      if (req.method === 'GET' && url.pathname === '/metrics') {
        sendJson(res, 200, engine.snapshotMetrics(), cors);
        return;
      }

      let calculationDay;
      let targetDay;
      if (req.method === 'GET' && url.pathname === '/v1/calendar') {
        calculationDay = url.searchParams.get('calculationDay');
        targetDay = url.searchParams.get('targetDay');
      } else if (req.method === 'POST' && url.pathname === '/v1/calendar') {
        const body = await readJson(req, maxBodyBytes);
        calculationDay = body.calculationDay;
        targetDay = body.targetDay;
      } else {
        sendJson(res, 404, { error: 'NOT_FOUND' }, cors);
        return;
      }

      const value = await engine.convert(calculationDay, targetDay);
      const rendered = tupleToJson(value.result);
      sendJson(res, 200, {
        calculationDay: String(calculationDay),
        targetDay: String(targetDay),
        ...rendered,
        cache: value.cache,
        semanticFingerprint: value.fingerprint,
        computeNs: value.computeNs.toString(),
      }, {
        ...cors,
        'x-pastafari-cache': value.cache,
        'x-pastafari-semantic-fingerprint': value.fingerprint,
      });
    } catch (error) {
      const status = error && Number.isInteger(error.statusCode) ? error.statusCode
        : error instanceof SyntaxError ? 400
        : error instanceof TypeError || error instanceof RangeError ? 400
        : 500;
      sendJson(res, status, {
        error: status === 500 ? 'CALCULATION_FAILED' : 'INVALID_REQUEST',
        message: error && error.message ? String(error.message) : String(error),
      }, cors);
    }
  });
}

module.exports = Object.freeze({ createHttpServer, tupleToJson });

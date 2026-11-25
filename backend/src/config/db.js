const dns = require('dns');
const https = require('https');
const mongoose = require('mongoose');

const PUBLIC_DNS_SERVERS = ['8.8.8.8', '1.1.1.1', '8.8.4.4'];

function fetchJson(url) {
  return new Promise((resolve, reject) => {
    const req = https.get(
      url,
      {
        timeout: 6000,
        headers: { Accept: 'application/dns-json' },
      },
      (res) => {
        let body = '';
        res.on('data', (chunk) => (body += chunk));
        res.on('end', () => {
          try {
            resolve(JSON.parse(body));
          } catch (err) {
            reject(err);
          }
        });
      }
    );
    req.on('error', reject);
    req.on('timeout', () => {
      req.destroy();
      reject(new Error('DNS-over-HTTPS request timed out'));
    });
  });
}

async function queryDoh(name, type) {
  const urls = [
    `https://dns.google/resolve?name=${encodeURIComponent(name)}&type=${type}`,
    `https://cloudflare-dns.com/dns-query?name=${encodeURIComponent(name)}&type=${type}`,
  ];
  let lastErr;
  for (const url of urls) {
    try {
      const json = await fetchJson(url);
      if (json && Array.isArray(json.Answer) && json.Answer.length > 0) {
        return json;
      }
    } catch (err) {
      lastErr = err;
    }
  }
  if (lastErr) throw lastErr;
  return { Answer: [] };
}

function parseSrvAnswer(data) {
  const match = /^(\d+)\s+(\d+)\s+(\d+)\s+([^\s]+)\.?$/.exec((data || '').trim());
  if (!match) return null;
  return { port: Number(match[3]), name: match[4].replace(/\.$/, '') };
}

/**
 * Fallback for Windows networks whose local/loopback DNS refuses UDP SRV lookups.
 * Resolves Atlas `_mongodb._tcp.<host>` + TXT options over HTTPS DoH and returns a standard `mongodb://` URI.
 */
async function resolveSrvViaDoh(srvUri) {
  const withoutScheme = srvUri.slice('mongodb+srv://'.length);
  const atIndex = withoutScheme.lastIndexOf('@');
  const authPart = atIndex >= 0 ? withoutScheme.slice(0, atIndex + 1) : '';
  const rest = atIndex >= 0 ? withoutScheme.slice(atIndex + 1) : withoutScheme;
  const slashIndex = rest.indexOf('/');
  const qIndex = rest.indexOf('?');
  const hostEnd = slashIndex >= 0 ? slashIndex : (qIndex >= 0 ? qIndex : rest.length);
  const srvHost = rest.slice(0, hostEnd).trim();
  const suffix = rest.slice(hostEnd);

  const [srvResp, txtResp] = await Promise.all([
    queryDoh(`_mongodb._tcp.${srvHost}`, 'SRV'),
    queryDoh(srvHost, 'TXT').catch(() => null),
  ]);

  const srvHosts = (srvResp?.Answer || [])
    .map((ans) => parseSrvAnswer(ans.data))
    .filter(Boolean)
    .map((entry) => `${entry.name}:${entry.port}`);

  if (srvHosts.length === 0) {
    throw new Error(`No SRV records resolved via DoH for ${srvHost}`);
  }

  const txtOptions = new URLSearchParams();
  for (const ans of txtResp?.Answer || []) {
    const cleaned = (ans.data || '').replace(/^"|"$/g, '').trim();
    if (!cleaned) continue;
    for (const [k, v] of new URLSearchParams(cleaned).entries()) {
      if (!txtOptions.has(k)) txtOptions.set(k, v);
    }
  }

  const pathPart = suffix.includes('?') ? suffix.slice(0, suffix.indexOf('?')) : suffix;
  const existingQuery = suffix.includes('?') ? suffix.slice(suffix.indexOf('?') + 1) : '';
  const mergedParams = new URLSearchParams(existingQuery);
  for (const [k, v] of txtOptions.entries()) {
    if (!mergedParams.has(k)) mergedParams.set(k, v);
  }
  if (!mergedParams.has('tls') && !mergedParams.has('ssl')) {
    mergedParams.set('tls', 'true');
  }

  const dbPath = pathPart && pathPart.startsWith('/') ? pathPart : `/${pathPart || ''}`;
  const queryString = mergedParams.toString();
  return `mongodb://${authPart}${srvHosts.join(',')}${dbPath}${queryString ? `?${queryString}` : ''}`;
}

function isLoopbackOnlyDns(servers = []) {
  if (!servers.length) return true;
  return servers.every((s) => s === '127.0.0.1' || s === '::1' || s.startsWith('127.'));
}

const connectDB = async () => {
  const mongoUri =
    process.env.MONGODB_URI ||
    process.env.MONGO_URI ||
    'mongodb://localhost:27017/foodbillx';

  const isSrv = mongoUri.startsWith('mongodb+srv://');
  if (isSrv && isLoopbackOnlyDns(dns.getServers())) {
    dns.setServers(PUBLIC_DNS_SERVERS);
  }

  const connectOpts = {
    serverSelectionTimeoutMS: 12000,
    family: 4,
  };

  try {
    const conn = await mongoose.connect(mongoUri, connectOpts);
    console.log(`[MongoDB] Connected: ${conn.connection.host}`);
    return conn;
  } catch (error) {
    const isSrvLookupFailure =
      isSrv && /querySrv|ESERVFAIL|ECONNREFUSED|ETIMEOUT|ENOTFOUND/i.test(error?.message || '');

    if (isSrvLookupFailure) {
      try {
        dns.setServers(PUBLIC_DNS_SERVERS);
        const conn = await mongoose.connect(mongoUri, connectOpts);
        console.log(`[MongoDB] Connected (public DNS SRV): ${conn.connection.host}`);
        return conn;
      } catch (retryError) {
        try {
          const directUri = await resolveSrvViaDoh(mongoUri);
          const conn = await mongoose.connect(directUri, connectOpts);
          console.log(`[MongoDB] Connected (DoH resolved): ${conn.connection.host}`);
          return conn;
        } catch (dohError) {
          console.error(`[MongoDB Error] ${dohError.message || retryError.message}`);
          process.exit(1);
        }
      }
    }

    console.error(`[MongoDB Error] ${error.message}`);
    process.exit(1);
  }
};

module.exports = connectDB;
module.exports.resolveSrvViaDoh = resolveSrvViaDoh;

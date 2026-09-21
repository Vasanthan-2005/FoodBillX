const express = require('express');
const https = require('https');
const path = require('path');
const fs = require('fs');

const router = express.Router();

// ─── Config ────────────────────────────────────────────────────────────────
// Change these two if your repo name/owner changes. That's the ONLY thing
// you'd ever need to touch here.
const GITHUB_OWNER = 'Vasanthan-2005';
const GITHUB_REPO  = 'FoodBillX';
const APK_ASSET_NAME = 'app-release.apk'; // filename you upload to GitHub release

// Simple in-memory cache: avoids hammering GitHub API (60 req/hr unauthenticated)
let _cache = null;
let _cacheExpiresAt = 0;
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes

/**
 * Calls GitHub API and returns the latest release data.
 * Caches result for 5 minutes.
 */
function fetchLatestGitHubRelease() {
  if (_cache && Date.now() < _cacheExpiresAt) {
    return Promise.resolve(_cache);
  }

  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'api.github.com',
      path: `/repos/${GITHUB_OWNER}/${GITHUB_REPO}/releases/latest`,
      method: 'GET',
      headers: {
        'User-Agent': 'FoodBillX-Server/1.0',
        'Accept': 'application/vnd.github.v3+json',
        // Add a GitHub token in env for higher rate limits (optional but recommended)
        ...(process.env.GITHUB_TOKEN
          ? { Authorization: `token ${process.env.GITHUB_TOKEN}` }
          : {}),
      },
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => {
        try {
          const data = JSON.parse(body);
          if (data.message === 'Not Found') {
            return reject(new Error('No GitHub release found yet'));
          }
          _cache = data;
          _cacheExpiresAt = Date.now() + CACHE_TTL_MS;
          resolve(data);
        } catch (err) {
          reject(new Error('Failed to parse GitHub response'));
        }
      });
    });

    req.on('error', reject);
    req.setTimeout(8000, () => {
      req.destroy();
      reject(new Error('GitHub API timeout'));
    });
    req.end();
  });
}

/**
 * Parse a semver tag like "v1.2.3" or "1.2.3" into an integer versionCode.
 * v1.0.0 → 10000, v1.0.1 → 10001, v1.2.3 → 10203, v2.0.0 → 20000
 * This always increases as you bump semver, so the app can compare with >.
 */
function tagToVersionCode(tag = '') {
  const clean = tag.replace(/^v/, '').trim();
  const parts = clean.split('.').map((n) => parseInt(n, 10) || 0);
  const [major = 1, minor = 0, patch = 0] = parts;
  return major * 10000 + minor * 100 + patch;
}

/**
 * Find the APK download URL from a GitHub release's assets array.
 * Falls back to the standard /releases/latest/download/ URL.
 */
function getApkUrl(release) {
  if (Array.isArray(release.assets)) {
    const apkAsset = release.assets.find(
      (a) => a.name && a.name.endsWith('.apk')
    );
    if (apkAsset) return apkAsset.browser_download_url;
  }
  // Fallback: GitHub's /releases/latest/download/<filename> always points to latest
  return `https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/releases/latest/download/${APK_ASSET_NAME}`;
}

/**
 * GET /api/app-version  (or /api/v1/app/version)
 * Auto-reads the latest GitHub Release — no manual env changes needed.
 * Just upload a new GitHub Release with an APK and clients auto-detect it.
 */
const getAppVersionHandler = async (req, res) => {
  try {
    const release = await fetchLatestGitHubRelease();

    const tag = release.tag_name || 'v1.0.0';
    const latestVersion = tag.replace(/^v/, '');
    const versionCode = tagToVersionCode(tag);
    const downloadUrl = getApkUrl(release);
    const releaseNotes = (release.body || '• Bug fixes and improvements')
      .trim()
      .replace(/\r\n/g, '\n');
    const forceUpdate = process.env.APP_FORCE_UPDATE === 'true'; // still env-controlled if needed
    const publishedAt = release.published_at || new Date().toISOString();

    return res.status(200).json({
      success: true,
      latestVersion,
      versionCode,
      downloadUrl,
      releaseNotes,
      forceUpdate,
      publishedAt,
      // Extra info (useful for debugging)
      _source: 'github-releases',
      _tag: tag,
    });
  } catch (err) {
    // GitHub unreachable or no releases yet — return a safe fallback
    console.warn('[AppVersion] GitHub fetch failed, using fallback:', err.message);
    return res.status(200).json({
      success: true,
      latestVersion: process.env.APP_LATEST_VERSION || '1.0.0',
      versionCode: parseInt(process.env.APP_VERSION_CODE || '10000', 10),
      downloadUrl:
        process.env.APP_DOWNLOAD_URL ||
        `https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/releases/latest/download/${APK_ASSET_NAME}`,
      releaseNotes: '• Latest features and improvements',
      forceUpdate: false,
      publishedAt: new Date().toISOString(),
      _source: 'fallback',
    });
  }
};

router.get('/version', getAppVersionHandler);
router.get('/app-version', getAppVersionHandler);

/**
 * GET /api/v1/app/download
 * Redirects directly to the latest APK on GitHub releases.
 */
router.get('/download', async (req, res) => {
  // If you've hosted the APK locally on this server, serve it directly
  const localApkPath = path.join(__dirname, '../../public/FoodBillX.apk');
  if (fs.existsSync(localApkPath)) {
    return res.download(localApkPath, 'FoodBillX.apk');
  }

  try {
    const release = await fetchLatestGitHubRelease();
    return res.redirect(getApkUrl(release));
  } catch (_) {
    // Fallback to latest/download URL
    return res.redirect(
      `https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/releases/latest/download/${APK_ASSET_NAME}`
    );
  }
});

module.exports = {
  router,
  getAppVersionHandler,
};

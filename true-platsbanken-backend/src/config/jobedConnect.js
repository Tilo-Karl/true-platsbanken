const DEFAULT_TIMEOUT_MS = 8000;

function resolveTimeout(value) {
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : DEFAULT_TIMEOUT_MS;
}

const JOBED_CONNECT_CONFIG = {
  BASE_URL: process.env.JOBED_CONNECT_BASE_URL || 'https://jobed-connect-api.jobtechdev.se',
  REQUEST_TIMEOUT_MS: resolveTimeout(process.env.JOBED_CONNECT_TIMEOUT_MS),
  DEFAULT_HEADERS: {
    Accept: 'application/json',
    'Content-Type': 'application/json'
  }
};

module.exports = { JOBED_CONNECT_CONFIG };

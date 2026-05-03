const { JOBED_CONNECT_CONFIG } = require('../config/jobedConnect');

class JobEdConnectHttpError extends Error {
  constructor(message, context = {}) {
    super(message);
    this.name = 'JobEdConnectHttpError';
    this.status = context.status;
    this.statusText = context.statusText;
    this.url = context.url;
    this.payload = context.payload;
  }
}

function appendQueryParams(searchParams, query = {}) {
  for (const [key, rawValue] of Object.entries(query)) {
    if (rawValue === undefined || rawValue === null) continue;

    if (Array.isArray(rawValue)) {
      rawValue.forEach((item) => searchParams.append(key, String(item)));
      continue;
    }

    searchParams.append(key, String(rawValue));
  }
}

async function parseResponsePayload(response) {
  const text = await response.text();
  if (!text) return null;

  try {
    return JSON.parse(text);
  } catch (error) {
    return text;
  }
}

async function requestJobEdConnect(path, options = {}) {
  const method = String(options.method || 'GET').toUpperCase();
  const baseUrl = options.baseUrl || JOBED_CONNECT_CONFIG.BASE_URL;
  const url = new URL(path, baseUrl);
  appendQueryParams(url.searchParams, options.query);

  const headers = {
    ...JOBED_CONNECT_CONFIG.DEFAULT_HEADERS,
    ...(options.headers || {})
  };

  const timeoutMs = Number(options.timeoutMs) > 0
    ? Number(options.timeoutMs)
    : JOBED_CONNECT_CONFIG.REQUEST_TIMEOUT_MS;

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  let response;
  try {
    response = await fetch(url.toString(), {
      method,
      headers,
      body: options.body ? JSON.stringify(options.body) : undefined,
      signal: controller.signal
    });
  } catch (error) {
    const cause = error?.cause?.code || error?.cause?.message;
    const message = error?.name === 'AbortError'
      ? `JobEd Connect request timed out after ${timeoutMs}ms`
      : `JobEd Connect request failed: ${error.message}${cause ? ` (${cause})` : ''}`;
    throw new Error(message);
  } finally {
    clearTimeout(timer);
  }

  const payload = await parseResponsePayload(response);
  return {
    ok: response.ok,
    status: response.status,
    statusText: response.statusText,
    url: url.toString(),
    payload
  };
}

async function fetchJobEdConnect(path, options = {}) {
  const result = await requestJobEdConnect(path, options);

  if (!result.ok) {
    throw new JobEdConnectHttpError(
      `JobEd Connect API error: ${result.status} ${result.statusText}`,
      result
    );
  }

  return result.payload;
}

module.exports = {
  JobEdConnectHttpError,
  requestJobEdConnect,
  fetchJobEdConnect
};

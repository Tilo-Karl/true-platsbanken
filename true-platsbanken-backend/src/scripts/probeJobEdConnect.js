const { JOBED_CONNECT_CONFIG } = require('../config/jobedConnect');
const { requestJobEdConnect } = require('../readers/jobEdConnect');

const DOCUMENTATION_PROBES = [
  { name: 'docs_swagger_json', path: '/swagger.json' },
  { name: 'docs_v1_swagger_json', path: '/v1/swagger.json' }
];

const BASE_PROBES = [
  {
    name: 'get_educations',
    path: '/v1/educations',
    query: { limit: 3, offset: 0 }
  },
  {
    name: 'post_match_educations_by_jobtitle',
    path: '/v1/educations/match-by-jobtitle',
    method: 'POST',
    query: {
      jobtitle: 'Systemutvecklare',
      include_metadata: true,
      limit: 3,
      offset: 0
    }
  },
  {
    name: 'post_match_occupations_by_text',
    path: '/v1/occupations/match-by-text',
    method: 'POST',
    query: {
      input_text: 'Ledde team inom systemutveckling och agil leverans.',
      include_metadata: true,
      limit: 3,
      offset: 0
    }
  },
  {
    name: 'get_searchparameters_education_types',
    path: '/v1/searchparameters/education_types',
    method: 'GET'
  },
  {
    name: 'get_searchparameters_education_forms',
    path: '/v1/searchparameters/education_forms',
    method: 'GET'
  },
  {
    name: 'get_searchparameters_regions',
    path: '/v1/searchparameters/regions',
    method: 'GET'
  },
  {
    name: 'get_searchparameters_municipalities',
    path: '/v1/searchparameters/municipalities',
    method: 'GET'
  }
];

function extractOccupationId(item) {
  if (!item || typeof item !== 'object') return null;
  return (
    item.occupation_concept_id ||
    item.occupation_id ||
    item.occupation?.id ||
    item.occupation?.occupation_id ||
    item.occupation?.occupation_concept_id ||
    null
  );
}

function extractEducationId(item) {
  if (!item || typeof item !== 'object') return null;
  return (
    item.id ||
    item.education?.id ||
    item.education?.education_id ||
    item.education?.educationId ||
    null
  );
}

function buildDynamicProbes(state) {
  const probes = [];

  if (state.firstOccupationId) {
    probes.push({
      name: 'post_match_educations_by_occupation_dynamic',
      path: '/v1/educations/match-by-occupation',
      method: 'POST',
      query: {
        occupation_id: state.firstOccupationId,
        include_metadata: true,
        limit: 3,
        offset: 0
      }
    });
    probes.push({
      name: 'get_enriched_occupations_dynamic',
      path: '/v1/enriched_occupations',
      method: 'GET',
      query: {
        occupation_id: state.firstOccupationId,
        include_metadata: true
      }
    });
  }

  if (state.firstEducationId) {
    probes.push({
      name: 'get_education_by_id_dynamic',
      path: `/v1/educations/${encodeURIComponent(state.firstEducationId)}`,
      method: 'GET'
    });
    probes.push({
      name: 'post_match_occupations_by_education_dynamic',
      path: '/v1/occupations/match-by-education',
      method: 'POST',
      query: {
        education_id: state.firstEducationId,
        include_metadata: true,
        limit: 3,
        offset: 0
      }
    });
  }

  return probes;
}

function discoverDynamicIds(payload, state) {
  const mappedOccupationId = payload?.mapped_occupation_for_match?.occupation_concept_id;
  if (!state.firstOccupationId && mappedOccupationId) {
    state.firstOccupationId = String(mappedOccupationId);
  }

  const occupationRows = Array.isArray(payload?.related_occupations)
    ? payload.related_occupations
    : Array.isArray(payload?.result)
      ? payload.result
      : [];
  const educationRows = Array.isArray(payload?.hits)
    ? payload.hits
    : Array.isArray(payload?.result)
      ? payload.result
      : [];

  if (!state.firstOccupationId) {
    const occupationId = occupationRows.map(extractOccupationId).find(Boolean);
    if (occupationId) state.firstOccupationId = occupationId;
  }

  if (!state.firstEducationId) {
    const educationId = educationRows.map(extractEducationId).find(Boolean);
    if (educationId) state.firstEducationId = educationId;
  }
}

const PLACEHOLDER_DYNAMIC_PROBE = {
  name: 'dynamic_placeholder',
  path: '/__dynamic__',
  method: 'GET'
};

const PROBE_SEQUENCE = [
  ...DOCUMENTATION_PROBES,
  ...BASE_PROBES,
  PLACEHOLDER_DYNAMIC_PROBE
];

const TAIL_PROBES = [];

function keysFromPayload(payload) {
  if (Array.isArray(payload)) {
    const first = payload[0];
    if (first && typeof first === 'object') {
      return Object.keys(first);
    }
    return [];
  }

  if (payload && typeof payload === 'object') {
    return Object.keys(payload);
  }

  return [];
}

function previewPayload(payload) {
  if (payload === null || payload === undefined) return null;

  if (typeof payload === 'string') {
    return payload.slice(0, 300);
  }

  if (Array.isArray(payload)) {
    if (!payload.length) return [];
    return payload.slice(0, 1);
  }

  if (typeof payload === 'object') {
    return payload;
  }

  return payload;
}

function summarizeSwagger(payload, probeName) {
  if (!payload || typeof payload !== 'object') return;
  if (!payload.paths || typeof payload.paths !== 'object') return;

  const pathEntries = Object.entries(payload.paths);
  if (!pathEntries.length) return;

  console.log('[jobed-probe] %s swagger.basePath=%s', probeName, payload.basePath || '(none)');
  console.log('[jobed-probe] %s swagger.paths.count=%s', probeName, pathEntries.length);

  for (const [pathName, methods] of pathEntries.slice(0, 60)) {
    const operations = Object.entries(methods || {});
    for (const [method, operation] of operations) {
      const parameters = Array.isArray(operation?.parameters) ? operation.parameters : [];
      const paramSummary = parameters.map((p) => {
        const required = p.required ? '!' : '';
        const location = p.in ? `${p.in}:` : '';
        return `${location}${p.name || 'unknown'}${required}`;
      });
      console.log(
        '[jobed-probe] swagger op=%s %s params=%s',
        String(method).toUpperCase(),
        pathName,
        paramSummary.length ? paramSummary.join(', ') : '(none)'
      );
    }
  }
}

function summarizeEducationsResult(payload, probeName) {
  if (!payload || typeof payload !== 'object') return;
  if (!Array.isArray(payload.result)) return;

  console.log('[jobed-probe] %s educations.result.count=%s', probeName, payload.result.length);
  const first = payload.result[0];
  if (first && typeof first === 'object') {
    console.log('[jobed-probe] %s educations.result[0].keys=%s', probeName, Object.keys(first).join(', '));
  }
}

async function runProbe() {
  const baseUrlCandidates = [JOBED_CONNECT_CONFIG.BASE_URL];
  const uniqueBaseUrls = Array.from(new Set(baseUrlCandidates.filter(Boolean)));

  console.log('[jobed-probe] timeoutMs=%s', JOBED_CONNECT_CONFIG.REQUEST_TIMEOUT_MS);
  console.log('[jobed-probe] baseUrls=%s', uniqueBaseUrls.join(', '));

  let anySuccess = false;

  for (const baseUrl of uniqueBaseUrls) {
    console.log('[jobed-probe] ----- probing baseUrl=%s -----', baseUrl);
    const state = {
      firstOccupationId: null,
      firstEducationId: null
    };

    const probes = [...PROBE_SEQUENCE];
    const dynamicProbeNamesRun = new Set();

    for (const probe of probes) {
      const candidates = probe === PLACEHOLDER_DYNAMIC_PROBE
        ? buildDynamicProbes(state).filter((p) => !dynamicProbeNamesRun.has(p.name))
        : [probe];

      for (const candidate of candidates) {
        const currentProbe = candidate;
        dynamicProbeNamesRun.add(currentProbe.name);

        try {
          const response = await requestJobEdConnect(currentProbe.path, {
            baseUrl,
            method: currentProbe.method || 'GET',
            query: currentProbe.query,
            body: currentProbe.body
          });

          const keys = keysFromPayload(response.payload);
          const isAuthError = response.status === 401 || response.status === 403;
          const outcome = response.ok ? 'ok' : 'error';
          const method = currentProbe.method || 'GET';

          if (response.ok) anySuccess = true;

          console.log('[jobed-probe] %s %s outcome=%s status=%s authError=%s', method, currentProbe.name, outcome, response.status, isAuthError);
          console.log('[jobed-probe] %s %s url=%s', method, currentProbe.name, response.url);
          if (keys.length) {
            console.log('[jobed-probe] %s %s keys=%s', method, currentProbe.name, keys.join(', '));
          }

          if (currentProbe.name === 'docs_swagger_json' || currentProbe.name === 'docs_v1_swagger_json') {
            summarizeSwagger(response.payload, currentProbe.name);
          }
          if (
            currentProbe.name === 'get_educations' ||
            currentProbe.name === 'post_match_educations_by_jobtitle' ||
            currentProbe.name === 'post_match_educations_by_occupation_dynamic'
          ) {
            summarizeEducationsResult(response.payload, currentProbe.name);
          }

          discoverDynamicIds(response.payload, state);

          if (!response.ok || !keys.length) {
            console.log('[jobed-probe] %s %s payloadPreview=%j', method, currentProbe.name, previewPayload(response.payload));
          }
        } catch (error) {
          const method = currentProbe.method || 'GET';
          console.log('[jobed-probe] %s %s outcome=exception message=%s', method, currentProbe.name, error.message);
        }
      }

      if (probe === PLACEHOLDER_DYNAMIC_PROBE) {
        continue;
      }
    }

    for (const probe of TAIL_PROBES) {
      try {
        const response = await requestJobEdConnect(probe.path, {
          baseUrl,
          method: probe.method || 'GET',
          query: probe.query,
          body: probe.body
        });

        const keys = keysFromPayload(response.payload);
        const isAuthError = response.status === 401 || response.status === 403;
        const outcome = response.ok ? 'ok' : 'error';
        const method = probe.method || 'GET';

        if (response.ok) anySuccess = true;

        console.log('[jobed-probe] %s %s outcome=%s status=%s authError=%s', method, probe.name, outcome, response.status, isAuthError);
        console.log('[jobed-probe] %s %s url=%s', method, probe.name, response.url);
        if (keys.length) {
          console.log('[jobed-probe] %s %s keys=%s', method, probe.name, keys.join(', '));
        }
        if (!response.ok || !keys.length) {
          console.log('[jobed-probe] %s %s payloadPreview=%j', method, probe.name, previewPayload(response.payload));
        }
      } catch (error) {
        const method = probe.method || 'GET';
        console.log('[jobed-probe] %s %s outcome=exception message=%s', method, probe.name, error.message);
      }
    }
  }

  if (!anySuccess) {
    process.exitCode = 1;
    console.log('[jobed-probe] no successful probe call; check base URL, endpoint path, auth, or network');
    return;
  }

  console.log('[jobed-probe] at least one probe call succeeded');
}

runProbe();

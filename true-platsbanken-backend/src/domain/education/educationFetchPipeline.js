const { fetchJobEdConnect } = require('../../readers/jobEdConnect');
const { MAX_TRACK_RESULTS, MAX_EDUCATIONS_PER_OCCUPATION } = require('./educationPathConstants');
const {
  buildSignalJobTitles,
  firstString,
  extractPublicCourseUrl,
  scoreConfidence,
  normalizedCourseKey,
  toEpoch,
  isSyntheticCourseId,
  uniqueStrings
} = require('./educationPathHelpers');

async function buildStrengthenRoleFallbackItems({
  explicitRoles,
  inferredRoles,
  profileSignals,
  disallowedCourseIds
}) {
  const roleTitles = buildSignalJobTitles('', uniqueStrings([
    ...explicitRoles,
    ...inferredRoles,
    ...(Array.isArray(profileSignals) ? profileSignals : [])
  ]));

  const items = [];
  for (const roleTitle of roleTitles) {
    const fetched = await fetchEducationsByJobTitle({
      occupationId: roleTitle,
      occupationLabel: roleTitle,
      jobTitle: roleTitle,
      track: 'strengthen',
      profileSignals,
      crossDomain: false,
      disallowedCourseIds
    });
    items.push(...fetched);
    if (items.length >= MAX_TRACK_RESULTS) break;
  }

  return items;
}

async function buildTrackItems({
  track,
  occupationIds,
  taxonomy,
  explicitSet,
  profileSignals,
  disallowedOccupationIds = new Set(),
  disallowedFieldIds = new Set(),
  disallowedCourseIds = new Set()
}) {
  const allItems = [];
  for (const occupationId of occupationIds) {
    if (disallowedOccupationIds.has(occupationId)) continue;
    const fieldId = taxonomy.occupationToField.get(occupationId);
    if (disallowedFieldIds.has(fieldId)) continue;

    const occupation = taxonomy.occupationById.get(occupationId);
    const occupationLabel = occupation?.label || occupationId;
    const crossDomain = !explicitSet.has(occupationId);

    const directItems = await fetchEducationsByOccupation({
      occupationId,
      occupationLabel,
      track,
      profileSignals,
      crossDomain,
      disallowedCourseIds
    });

    const titleFallbackItems = directItems.length
      ? []
      : await fetchEducationsByJobTitle({
        occupationId,
        occupationLabel,
        track,
        profileSignals,
        crossDomain,
        disallowedCourseIds
      });

    const signalTitleFallbackItems = directItems.length || titleFallbackItems.length
      ? []
      : await fetchEducationsBySignalTitles({
        occupationId,
        occupationLabel,
        track,
        profileSignals,
        crossDomain,
        disallowedCourseIds
      });

    const fallbackItems = directItems.length || titleFallbackItems.length || signalTitleFallbackItems.length
      ? []
      : await fetchEducationsByQuery({
        occupationId,
        occupationLabel,
        track,
        profileSignals,
        crossDomain,
        disallowedCourseIds
      });

    allItems.push(...directItems, ...titleFallbackItems, ...signalTitleFallbackItems, ...fallbackItems);
  }

  return allItems;
}

async function fetchEducationsByOccupation({
  occupationId,
  occupationLabel,
  track,
  profileSignals,
  crossDomain,
  disallowedCourseIds
}) {
  try {
    const payload = await fetchJobEdConnect('/v1/educations/match-by-occupation', {
      method: 'POST',
      query: {
        occupation_id: occupationId,
        include_metadata: true,
        limit: MAX_EDUCATIONS_PER_OCCUPATION,
        offset: 0
      }
    });

    return mapEducationPayloadToItems({
      payload,
      track,
      occupationId,
      occupationLabel,
      profileSignals,
      crossDomain,
      disallowedCourseIds
    });
  } catch (error) {
    console.log('Education path: match-by-occupation failed', {
      occupationId,
      message: error.message
    });
    return [];
  }
}

async function fetchEducationsByQuery({
  occupationId,
  occupationLabel,
  track,
  profileSignals,
  crossDomain,
  disallowedCourseIds
}) {
  try {
    const payload = await fetchJobEdConnect('/v1/educations', {
      method: 'GET',
      query: {
        query: occupationLabel,
        limit: MAX_EDUCATIONS_PER_OCCUPATION,
        offset: 0
      }
    });

    return mapEducationPayloadToItems({
      payload,
      track,
      occupationId,
      occupationLabel,
      profileSignals,
      crossDomain,
      disallowedCourseIds
    });
  } catch (error) {
    console.log('Education path: educations query fallback failed', {
      occupationId,
      occupationLabel,
      message: error.message
    });
    return [];
  }
}

async function fetchEducationsByJobTitle({
  occupationId,
  occupationLabel,
  jobTitle = occupationLabel,
  track,
  profileSignals,
  crossDomain,
  disallowedCourseIds
}) {
  try {
    const payload = await fetchJobEdConnect('/v1/educations/match-by-jobtitle', {
      method: 'POST',
      query: {
        jobtitle: jobTitle,
        include_metadata: true,
        limit: MAX_EDUCATIONS_PER_OCCUPATION,
        offset: 0
      }
    });

    const mappedOccupation = mapOccupationFromJobTitlePayload(payload);
    const resolvedOccupationId = mappedOccupation.id || occupationId;
    const resolvedOccupationLabel = mappedOccupation.label || occupationLabel;

    return mapEducationPayloadToItems({
      payload,
      track,
      occupationId: resolvedOccupationId,
      occupationLabel: resolvedOccupationLabel,
      profileSignals,
      crossDomain,
      disallowedCourseIds
    });
  } catch (error) {
    console.log('Education path: match-by-jobtitle failed', {
      occupationId,
      occupationLabel,
      jobTitle,
      message: error.message
    });
    return [];
  }
}

async function fetchEducationsBySignalTitles({
  occupationId,
  occupationLabel,
  track,
  profileSignals,
  crossDomain,
  disallowedCourseIds
}) {
  const signalTitles = buildSignalJobTitles(occupationLabel, profileSignals);
  if (!signalTitles.length) return [];

  for (const signalTitle of signalTitles) {
    const items = await fetchEducationsByJobTitle({
      occupationId,
      occupationLabel,
      jobTitle: signalTitle,
      track,
      profileSignals,
      crossDomain,
      disallowedCourseIds
    });
    if (items.length) {
      return items;
    }
  }

  return [];
}

function mapEducationPayloadToItems({
  payload,
  track,
  occupationId,
  occupationLabel,
  profileSignals,
  crossDomain,
  disallowedCourseIds
}) {
  const results = Array.isArray(payload?.result)
    ? payload.result
    : Array.isArray(payload?.hits)
      ? payload.hits
      : [];
  const items = [];

  for (const row of results) {
    const mapped = mapEducationRow({
      row,
      track,
      occupationId,
      occupationLabel,
      profileSignals,
      crossDomain
    });

    if (!mapped) continue;
    if (disallowedCourseIds.has(mapped._courseId)) continue;
    disallowedCourseIds.add(mapped._courseId);
    items.push(mapped);
  }

  return items;
}

function mapEducationRow({ row, track, occupationId, occupationLabel, profileSignals, crossDomain }) {
  const courseId = firstString(row, [
    ['id'],
    ['education', 'id'],
    ['education', 'education_id'],
    ['education', 'educationId']
  ]);

  const courseTitle = firstString(row, [
    ['education_title'],
    ['education', 'title'],
    ['education', 'name'],
    ['education', 'education_title'],
    ['education', 'education_name'],
    ['education', 'headline'],
    ['education', 'label'],
    ['title'],
    ['name']
  ]);

  if (!courseTitle) {
    return null;
  }

  const provider = firstString(row, [
    ['education_provider_name'],
    ['providerSummary', 'providers', 0],
    ['providerSummary', 'name'],
    ['providerSummary', 'provider_name'],
    ['providerSummary', 'title'],
    ['education', 'provider_name'],
    ['education', 'provider']
  ]);

  const startDate = firstString(row, [
    ['eventSummary', 'executions', 0, 'start'],
    ['eventSummary', 'start_date'],
    ['eventSummary', 'startDate'],
    ['education', 'start_date'],
    ['education', 'startDate']
  ]);

  const duration = firstString(row, [
    ['eventSummary', 'duration'],
    ['eventSummary', 'duration_text'],
    ['eventSummary', 'durationText'],
    ['education', 'duration'],
    ['education', 'duration_text'],
    ['education', 'durationText'],
    ['education', 'pace_of_study_percentage']
  ]);

  const courseUrl = extractPublicCourseUrl(row);

  const reason = track === 'strengthen'
    ? `Relevant for ${occupationLabel} and aligned with your current profile direction.`
    : `Builds transferable skills toward ${occupationLabel} as a realistic pivot path.`;

  const confidence = scoreConfidence({
    track,
    startDate,
    duration,
    provider,
    crossDomain
  });

  const sourceSignals = profileSignals.slice(0, 5);

  return {
    track,
    occupationId,
    occupationLabel,
    courseTitle,
    provider: provider || null,
    startDate: startDate || null,
    duration: duration || null,
    courseId: courseId || null,
    courseUrl: courseUrl || null,
    confidence,
    reason,
    sourceSignals,
    _courseId: courseId || normalizedCourseKey(courseTitle, provider, occupationId),
    _startSort: toEpoch(startDate)
  };
}

function mapOccupationFromJobTitlePayload(payload) {
  if (!payload || typeof payload !== 'object') {
    return { id: null, label: null };
  }

  const id = firstString(payload, [
    ['mapped_occupation_for_match', 'occupation_concept_id'],
    ['mapped_occupation_for_match', 'occupation_id']
  ]);

  const label = firstString(payload, [
    ['mapped_occupation_for_match', 'occupation_label']
  ]);

  return { id, label };
}

async function enrichMissingCourseUrls(items) {
  if (!Array.isArray(items) || !items.length) return;

  const cache = new Map();
  for (const item of items) {
    if (!item || item.courseUrl) continue;
    const courseId = String(item._courseId || '').trim();
    if (!courseId || isSyntheticCourseId(courseId)) continue;

    let resolved = cache.get(courseId);
    if (resolved === undefined) {
      resolved = await fetchCourseUrlById(courseId);
      cache.set(courseId, resolved || null);
    }

    if (resolved) {
      item.courseUrl = resolved;
      if (!item.courseId) item.courseId = courseId;
    }
  }
}

async function fetchCourseUrlById(courseId) {
  try {
    const payload = await fetchJobEdConnect(`/v1/educations/${encodeURIComponent(courseId)}`, {
      method: 'GET'
    });
    return extractPublicCourseUrl(payload);
  } catch (error) {
    console.log('Education path: education-by-id link enrichment failed', {
      courseId,
      message: error.message
    });
    return null;
  }
}

module.exports = {
  buildStrengthenRoleFallbackItems,
  buildTrackItems,
  fetchEducationsByJobTitle,
  enrichMissingCourseUrls
};

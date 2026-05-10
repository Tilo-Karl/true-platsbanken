const { getTaxonomySnapshot } = require('../taxonomy/jobTechTaxonomy');
const {
  MAX_TRACK_RESULTS,
  MAX_OCCUPATIONS_PER_TRACK,
  MIN_STRENGTHEN_RESULTS
} = require('./educationPathConstants');
const { normalizeSignals, uniqueIds, uniqueStrings } = require('./educationPathHelpers');
const {
  buildStrengthenRoleFallbackItems,
  buildTrackItems,
  fetchEducationsByJobTitle,
  enrichMissingCourseUrls
} = require('./educationFetchPipeline');
const { dedupeAndRankTrack, stripInternalFields } = require('./educationTrackRanking');
const {
  normalizePivotSignals,
  buildCapabilityPivotItems,
  selectBalancedPivotItems,
  deriveSourceFieldIds
} = require('./educationPivotStrategy');

async function resolveEducationPaths(input = {}) {
  const explicitOccupationIds = uniqueIds(input.explicitOccupationIds);
  const inferredOccupationIds = uniqueIds(input.inferredOccupationIds);
  const explicitRoles = uniqueStrings(input.explicitRoles);
  const inferredRoles = uniqueStrings(input.inferredRoles);
  const inferredRoleDetails = Array.isArray(input.inferredRoleDetails) ? input.inferredRoleDetails : [];
  const profileSignals = normalizeSignals(input.profileSignals, explicitRoles, inferredRoles, inferredRoleDetails);

  if (!explicitOccupationIds.length && !inferredOccupationIds.length) {
    return { strengthen: [], pivot: [] };
  }

  const taxonomy = await getTaxonomySnapshot();
  const explicitSet = new Set(explicitOccupationIds);

  const strengthenOccupationIds = uniqueIds([
    ...explicitOccupationIds,
    ...inferredOccupationIds
  ]).slice(0, MAX_OCCUPATIONS_PER_TRACK);

  const strengthenRaw = await buildTrackItems({
    track: 'strengthen',
    occupationIds: strengthenOccupationIds,
    taxonomy,
    explicitSet,
    profileSignals
  });

  let strengthen = dedupeAndRankTrack(strengthenRaw).slice(0, MAX_TRACK_RESULTS);
  if (strengthen.length < MIN_STRENGTHEN_RESULTS) {
    const strengthenUsedCourseIds = new Set(
      strengthen
        .map((item) => item._courseId)
        .filter(Boolean)
    );

    const roleFallbackRaw = await buildStrengthenRoleFallbackItems({
      explicitRoles,
      inferredRoles,
      profileSignals,
      disallowedCourseIds: strengthenUsedCourseIds
    });

    strengthen = dedupeAndRankTrack([
      ...strengthen,
      ...roleFallbackRaw
    ]).slice(0, MAX_TRACK_RESULTS);
  }

  const strengthenResolvedOccupationIds = new Set(
    strengthen
      .map((item) => String(item.occupationId || '').trim())
      .filter(Boolean)
  );
  const usedCourseIds = new Set(strengthen.map((item) => item._courseId).filter(Boolean));

  const sourceFieldIds = deriveSourceFieldIds({
    explicitOccupationIds,
    inferredOccupationIds: [],
    taxonomy
  });
  if (!sourceFieldIds.size) {
    const inferredSourceFieldIds = deriveSourceFieldIds({
      explicitOccupationIds: [],
      inferredOccupationIds,
      taxonomy
    });
    for (const fieldId of inferredSourceFieldIds) {
      sourceFieldIds.add(fieldId);
    }
  }

  const disallowedPivotFieldIds = new Set(
    strengthen
      .map((item) => taxonomy.occupationToField.get(item.occupationId))
      .filter(Boolean)
  );
  for (const sourceFieldId of sourceFieldIds) {
    disallowedPivotFieldIds.add(sourceFieldId);
  }

  const pivotSignals = normalizePivotSignals({
    pivotSignals: input.pivotSignals,
    profileSignals: input.profileSignals,
    explicitRoles,
    inferredRoles
  });

  const pivotRaw = await buildCapabilityPivotItems({
    taxonomy,
    sourceFieldIds,
    disallowedFieldIds: disallowedPivotFieldIds,
    disallowedOccupationIds: strengthenResolvedOccupationIds,
    disallowedCourseIds: usedCourseIds,
    profileSignals: pivotSignals,
    explicitRoles,
    explicitSet,
    fetchByJobTitle: fetchEducationsByJobTitle
  });

  const pivotRanked = dedupeAndRankTrack(pivotRaw);
  const pivot = selectBalancedPivotItems(pivotRanked).slice(0, MAX_TRACK_RESULTS);

  await enrichMissingCourseUrls([...strengthen, ...pivot]);

  return {
    strengthen: strengthen.map(stripInternalFields),
    pivot: pivot.map(stripInternalFields)
  };
}

module.exports = { resolveEducationPaths };

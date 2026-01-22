const { requireFirestoreDb } = require('../invariants/requireFirestoreDb');
const { requireProfileId } = require('../invariants/requireProfileId');
const { requireProfileExists } = require('../invariants/requireProfileExists');
const { normalizeMatchRequest } = require('../domain/matching/normalizeMatchRequest');
const { matchQueryOptions } = require('../domain/matching/matchQueryOptions');
const { rankMatches } = require('../domain/matching/rankMatches');
const { getProfileById } = require('../readers/profiles');
const { listJobsForMatching } = require('../readers/jobs');

async function getMatches(db, request) {
  requireFirestoreDb(db);

  const { profileId, limit } = normalizeMatchRequest(request);
  requireProfileId(profileId);

  const profile = await getProfileById(db, profileId);
  requireProfileExists(profile);

  const options = matchQueryOptions(profile, limit);
  const jobs = await listJobsForMatching(db, options);
  const matches = rankMatches(profile, jobs, limit);

  return { matches, count: matches.length };
}

module.exports = { getMatches };

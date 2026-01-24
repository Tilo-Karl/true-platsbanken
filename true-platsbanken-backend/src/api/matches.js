const { requireFirestoreDb } = require('../invariants/requireFirestoreDb');
const { requireProfileId } = require('../invariants/requireProfileId');
const { requireProfileExists } = require('../invariants/requireProfileExists');
const { normalizeMatchRequest } = require('../domain/matching/normalizeMatchRequest');
const { matchQueryOptions } = require('../domain/matching/matchQueryOptions');
const { rankMatches } = require('../domain/matching/rankMatches');
const { extractProfileSignals } = require('../domain/profile/extractProfileSignals');
const { getProfileById } = require('../readers/profiles');
const { listJobsForMatching } = require('../readers/jobs');
const { embedTexts } = require('../readers/openaiEmbeddings');

async function getMatches(db, request) {
  requireFirestoreDb(db);

  const { profileId, limit } = normalizeMatchRequest(request);
  requireProfileId(profileId);

  const profile = await getProfileById(db, profileId);
  requireProfileExists(profile);

  const skillsText = Array.isArray(profile.skills) ? profile.skills.join(', ') : '';
  const employmentPreferences = {
    employmentType: profile.employmentType,
    municipality: profile.municipality
  };
  const profileSignals = extractProfileSignals(
    skillsText,
    profile.cvText || '',
    employmentPreferences
  );

  const options = matchQueryOptions(profile, limit);
  const jobs = await listJobsForMatching(db, options);

  let profileEmbedding = null;
  let jobEmbeddings = [];

  if (jobs.length > 0) {
    const profileText = profileSignals.keywords
      .concat(profileSignals.occupations, profileSignals.seniorityHints, profileSignals.locations)
      .join(' ');
    const jobTexts = jobs.map(job =>
      [job.title, job.description, job.occupationLabel, job.municipality]
        .filter(Boolean)
        .join(' ')
    );
    const embeddings = await embedTexts([profileText, ...jobTexts]);
    profileEmbedding = embeddings[0] || null;
    jobEmbeddings = embeddings.slice(1);
  }

  const matches = rankMatches(
    profile,
    profileSignals,
    jobs,
    limit,
    profileEmbedding,
    jobEmbeddings
  );

  return { matches, count: matches.length };
}

module.exports = { getMatches };

const { scoreProfile } = require('../ai/match/score');

async function getMatches(db, request) {
  if (!db) {
    throw new Error('Firestore db is required');
  }

  const { profileId, limit = 20 } = request;

  if (!profileId) {
    throw new Error('profileId is required');
  }

  const profileDoc = await db.collection('profiles').doc(profileId).get();
  if (!profileDoc.exists) {
    throw new Error('Profile not found');
  }

  const profile = profileDoc.data();
  let jobsQuery = db.collection('jobs').orderBy('publishedAt', 'desc');

  if (profile.municipality) {
    jobsQuery = jobsQuery.where('municipality', '==', profile.municipality);
  }

  const jobSnapshot = await jobsQuery.limit(Math.min(limit * 2, 500)).get();
  const jobs = jobSnapshot.docs.map(doc => doc.data());

  const matches = jobs
    .map(job => ({
      jobId: job.id,
      job,
      score: scoreProfile(profile, job),
      reasons: []
    }))
    .sort((a, b) => b.score - a.score)
    .slice(0, limit);

  return { matches, count: matches.length };
}

module.exports = { getMatches };
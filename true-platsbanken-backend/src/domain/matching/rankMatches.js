const { scoreProfile } = require('../../ai/match/score');

function rankMatches(profile, jobs, limit) {
  return jobs
    .map(job => ({
      jobId: job.id,
      job,
      score: scoreProfile(profile, job),
      reasons: []
    }))
    .sort((a, b) => b.score - a.score)
    .slice(0, limit);
}

module.exports = { rankMatches };

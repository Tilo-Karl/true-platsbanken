function scoreProfile(profile, job) {
  if (!profile || !job) {
    return 0;
  }

  let score = 0;

  // Municipality match (40 points)
  if (profile.municipality && job.municipality) {
    if (profile.municipality.toLowerCase() === job.municipality.toLowerCase()) {
      score += 40;
    }
  }

  // Employment type match (30 points)
  if (profile.employmentType && job.employmentType) {
    if (profile.employmentType === 'any') {
      score += 15;
    } else if (profile.employmentType === job.employmentType) {
      score += 30;
    }
  }

  // Skills match (20 points)
  if (profile.skills && Array.isArray(profile.skills) && profile.skills.length > 0) {
    const jobText = `${job.title} ${job.description}`.toLowerCase();
    const matchedSkills = profile.skills.filter(skill =>
      jobText.includes(skill.toLowerCase())
    );
    const skillScore = (matchedSkills.length / profile.skills.length) * 20;
    score += skillScore;
  }

  // Recency bonus (10 points)
  if (job.publishedAt) {
    const publishedDate = new Date(job.publishedAt);
    const daysSincePublished = (Date.now() - publishedDate.getTime()) / (1000 * 60 * 60 * 24);
    if (daysSincePublished < 7) {
      score += 10;
    } else if (daysSincePublished < 30) {
      score += 5;
    }
  }

  return Math.min(Math.max(score, 0), 100);
}

module.exports = { scoreProfile };
function jobVector(job) {
  if (!job) {
    return null;
  }

  return {
    id: job.id,
    title: job.title,
    description: job.description,
    municipality: job.municipality,
    employmentType: job.employmentType,
    employerName: job.employerName,
    publishedAt: job.publishedAt
  };
}

module.exports = { jobVector };
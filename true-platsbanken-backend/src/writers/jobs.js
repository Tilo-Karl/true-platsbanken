async function upsertJob(db, job) {
  const docRef = db.collection('jobs').doc(job.id);
  await docRef.set(job, { merge: true });
  return job;
}

module.exports = { upsertJob };

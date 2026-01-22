async function listJobs(db, query = {}) {
  const safeLimit = Math.min(Math.max(Number(query.limit) || 50, 1), 200);
  let q = db.collection('jobs').orderBy('publishedAt', 'desc').limit(safeLimit);

  if (query.cursor) {
    q = q.startAfter(String(query.cursor));
  }

  const snapshot = await q.get();
  const jobs = snapshot.docs.map(doc => ({
    ...doc.data(),
    docId: doc.id
  }));

  const lastDoc = snapshot.docs[snapshot.docs.length - 1];
  const nextCursor = lastDoc ? lastDoc.get('publishedAt') : null;

  return { jobs, nextCursor, count: jobs.length };
}

async function listJobsForMatching(db, options = {}) {
  const limit = Number(options.limit) || 0;
  let q = db.collection('jobs').orderBy('publishedAt', 'desc');

  if (options.municipality) {
    q = q.where('municipality', '==', options.municipality);
  }

  const snapshot = await q.limit(limit).get();
  return snapshot.docs.map(doc => doc.data());
}

module.exports = { listJobs, listJobsForMatching };

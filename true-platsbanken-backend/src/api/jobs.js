async function listJobs(db, query = {}) {
  if (!db) {
    throw new Error('Firestore db is required');
  }

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

module.exports = { listJobs };
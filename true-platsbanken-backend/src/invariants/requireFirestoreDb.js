function requireFirestoreDb(db) {
  if (!db) {
    throw new Error('Firestore db is required');
  }
  return db;
}

module.exports = { requireFirestoreDb };

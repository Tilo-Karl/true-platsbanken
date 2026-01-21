const express = require('express');
const { fetchAndStoreJobs } = require('./fetchJobs');

function ingestRoutes(db) {
  const router = express.Router();

  router.post('/fetch', async (req, res) => {
    try {
      const result = await fetchAndStoreJobs(db);
      res.status(200).json(result);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  return router;
}

module.exports = { ingestRoutes };
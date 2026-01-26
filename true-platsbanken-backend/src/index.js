const functions = require('firebase-functions');
const admin = require('firebase-admin');
const express = require('express');
const { ingestRoutes } = require('./ingest');
const { apiRoutes } = require('./api');
const { tick } = require('./scheduler/tick');

admin.initializeApp();
const db = admin.firestore();

const app = express();
app.use(express.json());

app.use('/ingest', ingestRoutes(db));
app.use('/api', apiRoutes(db));
app.get('/health', (req, res) => {
  res.status(200).send('OK');
});
app.use('/scheduler', (req, res) => {
  if (req.path === '/tick' && req.method === 'POST') {
    tick(db)
      .then(result => res.status(200).json(result))
      .catch(error => res.status(500).json({ error: error.message }));
  } else {
    res.status(404).json({ error: 'Not found' });
  }
});

const port = process.env.PORT || 8080;
app.listen(port);

exports.api = functions.https.onRequest(app);
exports.ingest = functions.https.onRequest(app);

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const express = require('express');
const { apiRoutes } = require('./api');

admin.initializeApp();
const db = admin.firestore();

const app = express();
app.use(express.json());

app.use('/api', apiRoutes(db));
app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

const port = process.env.PORT || 8080;
app.listen(port);

exports.api = functions.https.onRequest(app);

function bucket(score) {
  if (typeof score !== 'number') {
    return 'unknown';
  }

  if (score >= 80) {
    return 'excellent';
  }
  if (score >= 60) {
    return 'good';
  }
  if (score >= 40) {
    return 'fair';
  }
  if (score >= 20) {
    return 'poor';
  }
  return 'no_match';
}

module.exports = { bucket };
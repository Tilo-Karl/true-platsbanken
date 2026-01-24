async function embedTexts(texts, model = 'text-embedding-3-large') {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    throw new Error('OPENAI_API_KEY is required');
  }

  const response = await fetch('https://api.openai.com/v1/embeddings', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      model,
      input: texts
    })
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`OpenAI embeddings failed: ${response.status} ${errorText}`);
  }

  const payload = await response.json();
  if (!payload || !Array.isArray(payload.data)) {
    throw new Error('OpenAI embeddings response is invalid');
  }

  return payload.data.map(item => item.embedding);
}

module.exports = { embedTexts };

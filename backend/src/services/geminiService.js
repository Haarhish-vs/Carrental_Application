class GeminiService {
  async analyzeDocuments({ vehicleId, documents, validationResults }) {
    const fallback = {
      overallStatus: validationResults.some((item) => item.status === 'failed') ? 'failed' : 'passed',
      score: validationResults.reduce((acc, item) => acc + item.score, 0) / Math.max(1, validationResults.length),
      summary: `Vehicle ${vehicleId} document verification completed with ${documents.length} documents reviewed.`,
      recommendation: 'Review flagged fields and upload clearer copies if needed.',
    };

    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      return fallback;
    }

    try {
      const payload = {
        contents: [
          {
            parts: [
              {
                text: `Analyze these vehicle document verification results and return a concise JSON object with fields: overallStatus, score, summary, recommendation. Results: ${JSON.stringify({ vehicleId, documents, validationResults })}`,
              },
            ],
          },
        ],
      };

      const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      if (!response.ok) {
        throw new Error(`Gemini API returned ${response.status}`);
      }

      const result = await response.json();
      const text = result?.candidates?.[0]?.content?.parts?.[0]?.text || '';

      if (!text) {
        return fallback;
      }

      const parsed = JSON.parse(text.replace(/```json|```/g, '').trim());
      return {
        overallStatus: parsed.overallStatus || fallback.overallStatus,
        score: parsed.score || fallback.score,
        summary: parsed.summary || fallback.summary,
        recommendation: parsed.recommendation || fallback.recommendation,
      };
    } catch (error) {
      console.error('Gemini analysis failed:', error.message);
      return fallback;
    }
  }
}

module.exports = new GeminiService();

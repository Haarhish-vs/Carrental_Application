class GeminiService {
  async analyzeDocuments({ vehicleId, documents, validationResults, crossValidationResults }) {
    const failedDocs = validationResults.filter((item) => item.status === 'failed');
    const fallback = {
      overallStatus: failedDocs.length > 0 ? 'failed' : 'passed',
      score: validationResults.reduce((acc, item) => acc + item.score, 0) / Math.max(1, validationResults.length),
      summary: `Vehicle ${vehicleId} document verification completed with ${documents.length} documents reviewed. ${failedDocs.length} documents failed validation.`,
      recommendation: failedDocs.length > 0 ? 'Review failed documents and upload clearer copies. Check expiry dates and missing fields.' : 'All documents are valid. Vehicle is ready for rental.',
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
                text: `You are a vehicle document verification expert. Analyze these vehicle document verification results and return a concise JSON object with fields: overallStatus (passed/failed), score (0-100), summary (brief overview), recommendation (actionable advice).

Vehicle ID: ${vehicleId}
Documents: ${JSON.stringify(documents, null, 2)}
Validation Results: ${JSON.stringify(validationResults, null, 2)}
Cross-Validation Results: ${JSON.stringify(crossValidationResults, null, 2)}

Consider:
1. Individual document validation status and scores
2. Missing required fields
3. Expiry dates (expired, expiring soon, valid)
4. Cross-validation consistency (vehicle number, owner name, engine number, chassis number should match across documents)
5. Overall document completeness

Return ONLY valid JSON without markdown formatting.`,
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

      const cleanedText = text.replace(/```json|```/g, '').trim();
      const parsed = JSON.parse(cleanedText);
      
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

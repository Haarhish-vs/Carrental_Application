class GeminiService {
  async analyzeDocuments({ vehicleId, documents, validationResults, crossValidationResults }) {
    const failedRequiredDocs = validationResults.filter((item) => item.documentType === 'rc' && item.status === 'failed');
    const fallback = {
      overallStatus: failedRequiredDocs.length > 0 ? 'FAILED' : 'VERIFIED',
      score: validationResults.reduce((acc, item) => acc + item.score, 0) / Math.max(1, validationResults.length),
      summary: `Vehicle ${vehicleId} document verification completed. ${failedRequiredDocs.length > 0 ? 'RC Book validation failed.' : 'RC Book validation passed.'}`,
      recommendation: failedRequiredDocs.length > 0 ? 'Please upload a clearer copy of the RC Book and verify the registration details.' : 'The RC Book is valid. Vehicle is ready for rental.',
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
                text: `You are a vehicle document verification expert. Analyze these vehicle document verification results and return a concise JSON object with fields: overallStatus (VERIFIED/FAILED), score (0-100), summary (brief overview), recommendation (actionable advice).
                
Note: Only the 'rc' (Registration Certificate) document is strictly required. Other documents (insurance, fc, puc, permit) are optional. Even if optional documents are missing or have minor validation issues, overallStatus should be 'VERIFIED' as long as the 'rc' document is valid.

Vehicle ID: ${vehicleId}
Documents: ${JSON.stringify(documents, null, 2)}
Validation Results: ${JSON.stringify(validationResults, null, 2)}
Cross-Validation Results: ${JSON.stringify(crossValidationResults, null, 2)}

Consider:
1. Individual document validation status and scores
2. Missing required fields for 'rc'
3. Expiry dates (expired, expiring soon, valid)
4. Cross-validation consistency (vehicle number, owner name, engine number, chassis number should match across documents, if other documents exist)

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

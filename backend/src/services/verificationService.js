class VerificationService {
  validateDocuments(documents) {
    return documents.map((doc) => {
      const parsedText = doc.ocrText || '';
      const score = this.computeScore(parsedText);
      return {
        documentType: doc.documentType,
        status: score >= 60 ? 'passed' : 'failed',
        score,
        fields: this.extractFields(parsedText),
      };
    });
  }

  computeScore(text) {
    if (!text) return 20;
    const length = text.length;
    return Math.min(100, 40 + Math.floor(length / 20));
  }

  extractFields(text) {
    return {
      vehicleNumber: text.includes('vehicle') ? 'detected' : 'missing',
      ownerName: text.includes('owner') ? 'detected' : 'missing',
    };
  }
}

module.exports = new VerificationService();

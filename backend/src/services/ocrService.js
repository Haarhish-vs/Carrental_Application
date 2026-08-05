const { createWorker } = require('tesseract.js');
const pdfParse = require('pdf-parse');

class OCRService {
  async extractText(file) {
    if (!file) {
      throw new Error('No file provided for OCR');
    }

    const extension = this.getExtension(file.originalname);
    if (extension === 'pdf') {
      return this.extractTextFromPdf(file.buffer);
    }

    return this.extractTextFromImage(file.buffer);
  }

  async extractTextFromStoredDocument(publicUrl) {
    if (!publicUrl) {
      throw new Error('No document URL provided');
    }

    const response = await fetch(publicUrl);
    if (!response.ok) {
      throw new Error(`Failed to fetch document from storage: ${response.status}`);
    }

    const buffer = Buffer.from(await response.arrayBuffer());
    const extension = this.getExtension(publicUrl);
    if (extension === 'pdf') {
      return this.extractTextFromPdf(buffer);
    }

    return this.extractTextFromImage(buffer);
  }

  async extractTextFromImage(buffer) {
    const worker = await createWorker('eng');
    try {
      const { data } = await worker.recognize(buffer);
      return data.text.trim() || 'No readable text detected in the uploaded image.';
    } finally {
      await worker.terminate();
    }
  }

  async extractTextFromPdf(buffer) {
    const data = await pdfParse(buffer);
    return data.text.trim() || 'No readable text detected in the uploaded PDF.';
  }

  detectDocumentType(fileName) {
    const name = (fileName || '').toLowerCase();
    if (name.includes('insurance')) return 'insurance';
    if (name.includes('fc')) return 'fc';
    if (name.includes('puc')) return 'puc';
    if (name.includes('permit')) return 'permit';
    return 'rc';
  }

  getExtension(value) {
    return (value || '').toLowerCase().split('.').pop() || '';
  }
}

module.exports = new OCRService();

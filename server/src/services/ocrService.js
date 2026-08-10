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

  async extractTextFromBuffer(buffer, filePath) {
    if (!buffer) {
      throw new Error('No buffer provided for OCR');
    }

    const extension = this.getExtension(filePath);
    if (extension === 'pdf') {
      return this.extractTextFromPdf(buffer);
    }

    return this.extractTextFromImage(buffer);
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

  extractFields(text, documentType) {
    const fields = {};
    const upperText = text.toUpperCase();

    switch (documentType) {
      case 'rc':
        fields.registrationNumber = this.extractPattern(text, /(?:REGN\s*NO|REG\s*NO|REGISTER\s*NO|VEHICLE\s*NO)[\s:]*([A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4})/i);
        fields.ownerName = this.extractPattern(text, /(?:OWNER\s*NAME|NAME\s*OF\s*OWNER)[\s:]*([A-Z\s]+)/i);
        fields.vehicleNumber = this.extractPattern(text, /(?:VEHICLE\s*NO|CHASSIS\s*NO)[\s:]*([A-Z0-9]+)/i);
        fields.engineNumber = this.extractPattern(text, /(?:ENGINE\s*NO|ENG\s*NO)[\s:]*([A-Z0-9]+)/i);
        fields.chassisNumber = this.extractPattern(text, /(?:CHASSIS\s*NO|CHASSIS\s*NO\.)[\s:]*([A-Z0-9]+)/i);
        fields.registrationDate = this.extractPattern(text, /(?:REG\s*DATE|REGISTRATION\s*DATE)[\s:]*([0-9]{2}[-/][0-9]{2}[-/][0-9]{4})/i);
        fields.manufacturer = this.extractPattern(text, /(?:MAKER|MANUFACTURER|MFG)[\s:]*([A-Z\s]+)/i);
        break;

      case 'insurance':
        fields.policyNumber = this.extractPattern(text, /(?:POLICY\s*NO|POLICY\s*NUMBER)[\s:]*([A-Z0-9]+)/i);
        fields.companyName = this.extractPattern(text, /(?:INSURANCE\s*COMPANY|COMPANY\s*NAME)[\s:]*([A-Z\s]+)/i);
        fields.vehicleNumber = this.extractPattern(text, /(?:VEHICLE\s*NO|REGN\s*NO)[\s:]*([A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4})/i);
        fields.expiryDate = this.extractPattern(text, /(?:EXPIRY\s*DATE|VALID\s*UNTIL|POLICY\s*EXPIRY)[\s:]*([0-9]{2}[-/][0-9]{2}[-/][0-9]{4})/i);
        break;

      case 'fc':
        fields.certificateNumber = this.extractPattern(text, /(?:CERTIFICATE\s*NO|CERT\s*NO)[\s:]*([A-Z0-9]+)/i);
        fields.vehicleNumber = this.extractPattern(text, /(?:VEHICLE\s*NO|REGN\s*NO)[\s:]*([A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4})/i);
        fields.expiryDate = this.extractPattern(text, /(?:EXPIRY\s*DATE|VALID\s*UNTIL)[\s:]*([0-9]{2}[-/][0-9]{2}[-/][0-9]{4})/i);
        break;

      case 'puc':
        fields.certificateNumber = this.extractPattern(text, /(?:CERTIFICATE\s*NO|PUC\s*NO)[\s:]*([A-Z0-9]+)/i);
        fields.vehicleNumber = this.extractPattern(text, /(?:VEHICLE\s*NO|REGN\s*NO)[\s:]*([A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4})/i);
        fields.expiryDate = this.extractPattern(text, /(?:EXPIRY\s*DATE|VALID\s*UNTIL)[\s:]*([0-9]{2}[-/][0-9]{2}[-/][0-9]{4})/i);
        break;

      case 'permit':
        fields.permitNumber = this.extractPattern(text, /(?:PERMIT\s*NO|PERMIT\s*NUMBER)[\s:]*([A-Z0-9]+)/i);
        fields.vehicleNumber = this.extractPattern(text, /(?:VEHICLE\s*NO|REGN\s*NO)[\s:]*([A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4})/i);
        fields.expiryDate = this.extractPattern(text, /(?:EXPIRY\s*DATE|VALID\s*UNTIL)[\s:]*([0-9]{2}[-/][0-9]{2}[-/][0-9]{4})/i);
        break;

      default:
        break;
    }

    return fields;
  }

  extractPattern(text, regex) {
    const match = text.match(regex);
    return match ? match[1].trim() : null;
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

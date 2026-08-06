class VerificationService {
  validateDocuments(documents) {
    return documents.map((doc) => {
      const fields = doc.extractedFields || {};
      const validation = this.validateDocumentFields(doc.documentType, fields);
      
      return {
        documentType: doc.documentType,
        status: validation.isValid ? 'passed' : 'failed',
        score: validation.score,
        missingFields: validation.missingFields,
        expiryStatus: validation.expiryStatus,
        fields: fields,
      };
    });
  }

  validateDocumentFields(documentType, fields) {
    const requiredFields = this.getRequiredFields(documentType);
    const missingFields = [];
    let score = 100;

    for (const field of requiredFields) {
      if (!fields[field] || fields[field] === null || fields[field] === '') {
        missingFields.push(field);
        score -= 20;
      }
    }

    const expiryStatus = this.checkExpiry(fields.expiryDate);
    if (expiryStatus === 'expired') {
      score -= 30;
    }

    return {
      isValid: missingFields.length === 0 && expiryStatus !== 'expired',
      score: Math.max(0, score),
      missingFields,
      expiryStatus,
    };
  }

  getRequiredFields(documentType) {
    switch (documentType) {
      case 'rc':
        return ['registrationNumber', 'ownerName', 'vehicleNumber', 'engineNumber', 'chassisNumber', 'registrationDate', 'manufacturer'];
      case 'insurance':
        return ['policyNumber', 'companyName', 'vehicleNumber', 'expiryDate'];
      case 'fc':
        return ['certificateNumber', 'vehicleNumber', 'expiryDate'];
      case 'puc':
        return ['certificateNumber', 'vehicleNumber', 'expiryDate'];
      case 'permit':
        return ['permitNumber', 'vehicleNumber', 'expiryDate'];
      default:
        return [];
    }
  }

  checkExpiry(expiryDate) {
    if (!expiryDate) {
      return 'unknown';
    }

    const expiry = new Date(expiryDate);
    const now = new Date();

    if (isNaN(expiry.getTime())) {
      return 'invalid';
    }

    if (expiry < now) {
      return 'expired';
    }

    const daysUntilExpiry = Math.ceil((expiry - now) / (1000 * 60 * 60 * 24));
    if (daysUntilExpiry <= 30) {
      return 'expiring_soon';
    }

    return 'valid';
  }

  crossValidateDocuments(documents) {
    const results = {
      vehicleNumber: { status: 'unknown', details: {} },
      ownerName: { status: 'unknown', details: {} },
      vehicleModel: { status: 'unknown', details: {} },
      engineNumber: { status: 'unknown', details: {} },
      chassisNumber: { status: 'unknown', details: {} },
    };

    const vehicleNumbers = [];
    const ownerNames = [];
    const engineNumbers = [];
    const chassisNumbers = [];

    for (const doc of documents) {
      const fields = doc.extractedFields || {};

      if (fields.vehicleNumber) {
        vehicleNumbers.push({ type: doc.documentType, value: fields.vehicleNumber });
      }
      if (fields.ownerName) {
        ownerNames.push({ type: doc.documentType, value: fields.ownerName });
      }
      if (fields.engineNumber) {
        engineNumbers.push({ type: doc.documentType, value: fields.engineNumber });
      }
      if (fields.chassisNumber) {
        chassisNumbers.push({ type: doc.documentType, value: fields.chassisNumber });
      }
    }

    results.vehicleNumber = this.compareValues(vehicleNumbers, 'vehicleNumber');
    results.ownerName = this.compareValues(ownerNames, 'ownerName');
    results.engineNumber = this.compareValues(engineNumbers, 'engineNumber');
    results.chassisNumber = this.compareValues(chassisNumbers, 'chassisNumber');

    const allMatch = Object.values(results).every(r => r.status === 'match');
    results.overallStatus = allMatch ? 'match' : 'mismatch';

    return results;
  }

  compareValues(values, fieldName) {
    if (values.length === 0) {
      return { status: 'unknown', details: { message: `No ${fieldName} found in any document` } };
    }

    if (values.length === 1) {
      return { status: 'single_source', details: { source: values[0].type, value: values[0].value } };
    }

    const normalizedValues = values.map(v => ({
      type: v.type,
      value: v.value.toUpperCase().replace(/[^A-Z0-9]/g, '')
    }));

    const firstValue = normalizedValues[0].value;
    const allMatch = normalizedValues.every(v => v.value === firstValue);

    if (allMatch) {
      return {
        status: 'match',
        details: {
          value: firstValue,
          sources: normalizedValues.map(v => v.type),
        },
      };
    }

    return {
      status: 'mismatch',
      details: {
        values: normalizedValues,
        message: `${fieldName} values do not match across documents`,
      },
    };
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

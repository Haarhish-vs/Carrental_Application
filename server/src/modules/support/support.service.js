// support.service.js
const { supabase } = require('../../config/supabase');

class SupportService {
  /**
   * Fetches customer support details and published policies from Supabase database.
   * Table schemas handled:
   * 1. customer_support / customer (label, email, phone)
   * 2. policies / policy (policy_type, title, content, is_published)
   */
  async getSupportDetails() {
    let customerSupport = {
      label: 'Customer Support',
      email: 'adminsupport@gmail.com',
      phone: '8825430047'
    };

    // 1. Fetch customer support contact from DB
    try {
      let { data: custData, error: custErr } = await supabase
        .from('customer_support')
        .select('*')
        .limit(1)
        .maybeSingle();

      if (!custData || custErr) {
        // Fallback check table named 'customer' or 'customers'
        const { data: altCustData } = await supabase
          .from('customer')
          .select('*')
          .limit(1)
          .maybeSingle();
        if (altCustData) custData = altCustData;
      }

      if (custData) {
        customerSupport = {
          label: custData.label || custData.name || 'Customer Support',
          email: custData.email || 'adminsupport@gmail.com',
          phone: custData.phone || custData.phone_number || '8825430047'
        };
      }
    } catch (err) {
      console.warn('Warning: Error fetching customer support details from DB, using fallback defaults:', err.message);
    }

    // 2. Fetch policies from DB
    let policiesMap = {};
    let policiesList = [];

    try {
      let { data: policyRows, error: polErr } = await supabase
        .from('policies')
        .select('*');

      if ((!policyRows || policyRows.length === 0) || polErr) {
        // Fallback table name 'policy'
        const { data: altRows } = await supabase
          .from('policy')
          .select('*');
        if (altRows && altRows.length > 0) policyRows = altRows;
      }

      if (policyRows && policyRows.length > 0) {
        // Filter published policies if is_published column exists
        const activePolicies = policyRows.filter(p => p.is_published === undefined || p.is_published === true);
        policiesList = activePolicies;

        activePolicies.forEach(p => {
          const key = (p.policy_type || p.type || '').toLowerCase();
          if (key) {
            policiesMap[key] = {
              id: p.id,
              title: p.title || p.policy_type,
              content: p.content || ''
            };
          }
        });
      }
    } catch (err) {
      console.warn('Warning: Error fetching policies from DB, using fallback defaults:', err.message);
    }

    return {
      customerSupport,
      policiesMap,
      policiesList
    };
  }
}

module.exports = new SupportService();

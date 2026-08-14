// support.service.js
const { supabase } = require('../../config/supabase');

class SupportService {
  /**
   * Fetches customer support details and published policies dynamically from Supabase database.
   */
  async getSupportDetails() {
    let customerSupport = {
      label: '',
      email: '',
      phone: ''
    };

    // 1. Fetch customer support contact from DB (tables: customer_support or customer)
    try {
      let { data: custData, error: custErr } = await supabase
        .from('customer_support')
        .select('*')
        .limit(1)
        .maybeSingle();

      if (!custData || custErr) {
        const { data: altCustData } = await supabase
          .from('customer')
          .select('*')
          .limit(1)
          .maybeSingle();
        if (altCustData) custData = altCustData;
      }

      if (custData) {
        customerSupport = {
          label: custData.label || custData.name || '',
          email: custData.email || '',
          phone: custData.phone || custData.phone_number || ''
        };
      }
    } catch (err) {
      console.error('Error fetching customer support details from DB:', err.message);
    }

    // 2. Fetch policies from DB (tables: policies or policy)
    let policiesMap = {};
    let policiesList = [];

    try {
      let { data: policyRows, error: polErr } = await supabase
        .from('policies')
        .select('*');

      if ((!policyRows || policyRows.length === 0) || polErr) {
        const { data: altRows } = await supabase
          .from('policy')
          .select('*');
        if (altRows && altRows.length > 0) policyRows = altRows;
      }

      if (policyRows && policyRows.length > 0) {
        const activePolicies = policyRows.filter(p => p.is_published === undefined || p.is_published === true);
        policiesList = activePolicies.map(p => ({
          id: p.id,
          title: p.title || '',
          policy_type: p.policy_type || p.type || '',
          content: p.content || '',
          is_published: p.is_published
        }));

        activePolicies.forEach(p => {
          const key = (p.policy_type || p.type || '').toLowerCase();
          if (key) {
            policiesMap[key] = {
              id: p.id,
              title: p.title || p.policy_type || '',
              content: p.content || ''
            };
          }
        });
      }
    } catch (err) {
      console.error('Error fetching policies from DB:', err.message);
    }

    return {
      customerSupport,
      policiesMap,
      policiesList
    };
  }
}

module.exports = new SupportService();

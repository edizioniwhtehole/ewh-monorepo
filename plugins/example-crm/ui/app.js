/**
 * CRM Frontend App
 * Auto-injected: window.PLUGIN_CONFIG
 */

(function () {
  // Plugin config injected by plugin system
  const { apiUrl, token, permissions } = window.PLUGIN_CONFIG || {
    apiUrl: '/crm',
    token: 'dev-token',
    permissions: ['crm.admin']
  };

  // API helper
  async function apiCall(endpoint, options = {}) {
    const response = await fetch(`${apiUrl}${endpoint}`, {
      ...options,
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
        ...options.headers
      }
    });

    if (!response.ok) {
      throw new Error(`API error: ${response.statusText}`);
    }

    return response.json();
  }

  // Load leads
  async function loadLeads() {
    try {
      const data = await apiCall('/leads?page=1&limit=10');

      const tbody = document.getElementById('leads-tbody');
      tbody.innerHTML = '';

      if (data.data.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6">No leads found</td></tr>';
        return;
      }

      data.data.forEach(lead => {
        const row = document.createElement('tr');
        row.innerHTML = `
          <td>${lead.first_name} ${lead.last_name}</td>
          <td>${lead.email}</td>
          <td>${lead.company || '-'}</td>
          <td>${lead.source || '-'}</td>
          <td><span class="status status-${lead.status}">${lead.status}</span></td>
          <td>${new Date(lead.created_at).toLocaleDateString()}</td>
        `;
        tbody.appendChild(row);
      });

      // Update stats
      document.getElementById('total-leads').textContent = data.pagination.total;
    } catch (error) {
      console.error('Failed to load leads:', error);
      document.getElementById('leads-tbody').innerHTML =
        '<tr><td colspan="6">Error loading leads</td></tr>';
    }
  }

  // Load stats
  async function loadStats() {
    try {
      // In a real app, you'd have dedicated stats endpoints
      // For demo, we'll use mock data
      document.getElementById('active-deals').textContent = '12';
      document.getElementById('conversion-rate').textContent = '24%';
    } catch (error) {
      console.error('Failed to load stats:', error);
    }
  }

  // Create lead (modal/form would go here)
  window.createLead = function () {
    const firstName = prompt('First Name:');
    const lastName = prompt('Last Name:');
    const email = prompt('Email:');

    if (!firstName || !lastName || !email) {
      alert('All fields required');
      return;
    }

    apiCall('/leads', {
      method: 'POST',
      body: JSON.stringify({
        first_name: firstName,
        last_name: lastName,
        email,
        source: 'website'
      })
    })
      .then(() => {
        alert('Lead created!');
        loadLeads();
      })
      .catch(error => {
        alert('Failed to create lead: ' + error.message);
      });
  };

  // Refresh data
  window.refreshData = function () {
    loadLeads();
    loadStats();
  };

  // Initialize
  document.addEventListener('DOMContentLoaded', () => {
    console.log('CRM App initialized', {
      apiUrl,
      hasToken: !!token,
      permissions
    });

    loadLeads();
    loadStats();
  });
})();

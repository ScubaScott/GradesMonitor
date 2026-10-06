// Version identifier for server and API sync
const VERSION = '2.8';

const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = 3000;

// Default institution base URL for Shakopee Canvas LMS
const DEFAULT_BASE_URL = 'https://shakopee.instructure.com/';

// Enable CORS with exposed pagination headers and JSON parsing for incoming client requests
app.use(cors({ exposedHeaders: ['X-Canvas-Link', 'Link'] }));
app.use(express.json());

// Serve static frontend assets from the public directory
app.use(express.static(path.join(__dirname, 'public')));

// Retrieve API token from candidate secret file paths
function readApiToken() {
  const candidatePaths = [
    path.join(__dirname, 'secret', 'secrets.txt'),
    path.join(__dirname, 'secret', 'Secrets.txt'),
    path.join(__dirname, 'public', 'Secret', 'Secrets.txt'),
    path.join(__dirname, 'public', 'secret', 'secrets.txt')
  ];

  for (const filePath of candidatePaths) {
    if (fs.existsSync(filePath)) {
      try {
        const content = fs.readFileSync(filePath, 'utf8').trim();
        if (content.length > 0) {
          return content;
        }
      } catch (err) {
        console.error(`Error reading ${filePath}:`, err.message);
      }
    }
  }
  return '';
}

// Provide initial configuration including default base URL, saved token, and version
app.get('/api/default-config', (req, res) => {
  const token = readApiToken();
  res.json({
    baseUrl: DEFAULT_BASE_URL,
    token: token,
    version: VERSION
  });
});

// Proxy endpoint to query Canvas LMS API on behalf of the client browser
app.post('/api/canvas', async (req, res) => {
  const { baseUrl, token, endpoint } = req.body;

  // Validate presence of required connection parameters
  if (!baseUrl || !token || !endpoint) {
    return res.status(400).json({ error: 'Missing required parameters (baseUrl, token, or endpoint).' });
  }

  // Construct target URL whether an absolute link or relative endpoint was provided
  const cleanBase = baseUrl.replace(/\/+$/, '');
  const url = endpoint.startsWith('http://') || endpoint.startsWith('https://')
    ? endpoint
    : `${cleanBase}${endpoint.startsWith('/') ? endpoint : '/' + endpoint}`;

  try {
    // Send authenticated request to Canvas API
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Accept': 'application/json'
      }
    });

    // Handle non-OK status codes returned by Canvas
    if (!response.ok) {
      const errText = await response.text();
      return res.status(response.status).json({ 
        error: `Canvas responded with status ${response.status}`, 
        details: errText 
      });
    }

    // Forward pagination link headers if present
    const linkHeader = response.headers.get('link');
    if (linkHeader) {
      res.set('X-Canvas-Link', linkHeader);
      res.set('Link', linkHeader);
      res.set('Access-Control-Expose-Headers', 'X-Canvas-Link, Link');
    }

    // Return parsed JSON data
    const data = await response.json();
    res.json(data);
  } catch (err) {
    // Return proxy network or execution errors
    res.status(500).json({ error: 'Proxy request failed', details: err.message });
  }
});

// Start listening on configured port
app.listen(PORT, () => {
  console.log(`Canvas Grade Monitor v${VERSION} listening at http://localhost:${PORT}`);
});
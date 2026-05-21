$services = @(
    @{ name="erp-backend"; port=3001; desc="ERP Module - HR & Accounting" },
    @{ name="crm-backend"; port=3002; desc="CRM Module - SavoirManger" },
    @{ name="supply-chain-backend"; port=3003; desc="Supply Chain Module" },
    @{ name="bi-backend"; port=3004; desc="BI Dashboard API" }
)

foreach ($service in $services) {
    $dir = "C:\Users\lumiere\Desktop\Compos\DIGITRANS-CM\" + $service.name
    
    # package.json
    $packageJson = @"
{
  "name": "$($service.name)",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "prom-client": "^14.2.0",
    "redis": "^4.6.7",
    "cors": "^2.8.5"
  }
}
"@
    Set-Content -Path "$dir\package.json" -Value $packageJson

    # index.js
    $indexJs = @"
const express = require('express');
const cors = require('cors');
const client = require('prom-client');
const { createClient } = require('redis');

const app = express();
app.use(cors());
app.use(express.json());

// Prometheus Metrics
const collectDefaultMetrics = client.collectDefaultMetrics;
const Registry = client.Registry;
const register = new Registry();
collectDefaultMetrics({ register });

const httpRequestDurationMicroseconds = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in microseconds',
  labelNames: ['method', 'route', 'code'],
  buckets: [0.1, 0.3, 0.5, 0.7, 1, 3, 5, 7, 10]
});
register.registerMetric(httpRequestDurationMicroseconds);

// Redis Cache (Simulation)
const redisClient = createClient({ url: 'redis://redis:6379' });
redisClient.on('error', (err) => console.log('Redis Client Error', err));
// Uncomment to connect in real environment
// redisClient.connect();

// Middleware to measure time
app.use((req, res, next) => {
  const end = httpRequestDurationMicroseconds.startTimer();
  res.on('finish', () => {
    end({ route: req.route ? req.route.path : req.path, code: res.statusCode, method: req.method });
  });
  next();
});

// Routes
app.get('/', (req, res) => {
  res.json({ service: '$($service.name)', status: 'Online', description: '$($service.desc)' });
});

app.get('/api/data', (req, res) => {
  // Simulate some delay for performance testing
  setTimeout(() => {
    res.json({ data: 'Sample data from $($service.name)', timestamp: new Date() });
  }, Math.random() * 200);
});

// Metrics Endpoint for Prometheus
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

const PORT = $($service.port);
app.listen(PORT, () => {
  console.log(\`$($service.name) is running on port \${PORT}\`);
});
"@
    Set-Content -Path "$dir\index.js" -Value $indexJs

    # Dockerfile
    $dockerfile = @"
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE $($service.port)
CMD ["npm", "start"]
"@
    Set-Content -Path "$dir\Dockerfile" -Value $dockerfile
}

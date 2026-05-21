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
  res.json({ service: 'bi-backend', status: 'Online', description: 'BI Dashboard API' });
});

app.get('/api/data', (req, res) => {
  // Simulate some delay for performance testing
  setTimeout(() => {
    res.json({ data: 'Sample data from bi-backend', timestamp: new Date() });
  }, Math.random() * 200);
});

// Metrics Endpoint for Prometheus
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

const PORT = 3004;
app.listen(PORT, () => {
  console.log(\$(System.Collections.Hashtable.name) is running on port \\);
});

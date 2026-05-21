import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 50 }, // Ramp-up to 50 users over 30 seconds
    { duration: '1m', target: 50 },  // Stay at 50 users for 1 minute
    { duration: '30s', target: 0 },  // Ramp-down to 0 users over 30 seconds
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests must complete below 500ms
  },
};

export default function () {
  // Test CRM API
  const resCrm = http.get('http://localhost:3002/api/data');
  check(resCrm, { 'CRM status was 200': (r) => r.status == 200 });
  
  // Test ERP API
  const resErp = http.get('http://localhost:3001/api/data');
  check(resErp, { 'ERP status was 200': (r) => r.status == 200 });

  sleep(1);
}

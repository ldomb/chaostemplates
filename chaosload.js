import http from 'k6/http';
import { check, group } from 'k6';

// Set the target ALB endpoint
const ALB_ENDPOINT = 'http://chaos-alb-929684801.us-east-1.elb.amazonaws.com';

// Define the control group and experimental group traffic configurations
const CONTROL_GROUP_CONFIG = {
  path: '/',
  host: 'control.example.com',
};

const EXPERIMENTAL_GROUP_CONFIG = {
  path: '/',
  host: 'experiment.example.com',
};

export default function () {
  // Group the control group and experimental group traffic
  group('Control Group', function () {
    const res = http.get(`${ALB_ENDPOINT}${CONTROL_GROUP_CONFIG.path}`, {
      headers: {
        'Host': CONTROL_GROUP_CONFIG.host,
      },
    });

    console.log(`Control Group Response Status: ${res.status}`);
    console.log(`Control Group Response Body: ${res.body}`);

    check(res, {
      'status is 200': (r) => r.status === 200,
    });
  });

  group('Experimental Group', function () {
    const res = http.get(`${ALB_ENDPOINT}${EXPERIMENTAL_GROUP_CONFIG.path}`, {
      headers: {
        'Host': EXPERIMENTAL_GROUP_CONFIG.host,
      },
    });

    console.log(`Experimental Group Response Status: ${res.status}`);
    console.log(`Experimental Group Response Body: ${res.body}`);

    check(res, {
      'status is 200': (r) => r.status === 200,
    });
  });
}

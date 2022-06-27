#!/bin/bash

  set -ex

  API_KEY='<replace-with-api-key>'
  INTEGRATIONS_API_URL='<replace-with-ngrok-url>'
  PROJECT_ID='3'
  CLIENT_ID='0e70ed30aa3011375041240d5f9b3946'
  SCOPES=['"ViewTestResults"','"ViewAutomationHistory"']
  API_URL='https://3000-qualitiai-qualitiapi-f7dl5n54uwn.ws-us47.gitpod.io/public/api'
  INTEGRATION_JWT_TOKEN='50e2fe8f6c12fe560ddcf5a1eb44e0f8235b42f790fd55af02dc35efc0ec514eb2d64a12e5abd6b76e6157b8bad31b26e5b9f1563354b1c49332c5cca3c7b9ebe3f42e1ce4eb9003edd62de87743d793d552c5a28d222746af38d97d059ffdfdd8ca28c8288dcc4fd2590620ca54414dd2aa3dd23258e7c6169cf9ff3bcc3d92dcd1c1d3cac970f2d93ae02fa803a14e0b46ed3f2fb656b546b0f1c92f10fd0bc4255458809f16316ca9384cca18f9fa8f880b630ae0d750aeba61222f824cafe630c056f46119e6f06629bcb601577fb54dfdcfa59f8c962a415d0c0d5a1e1b5981ca38d73f0a3746407d302756b22b4f3299b889b42a3d652d80c92ca443bdab30f19a00b477aa33f862ddc45d31ee|a73c491d9ad2414cb21a399df70c8a85|f4163dc45d7ba4d6506d3ccfcaf5bd78'

  apt-get update -y
  apt-get install -y jq

  #Trigger test run
  TEST_RUN_ID="$( \
    curl -X POST -G ${INTEGRATIONS_API_URL}/integrations/github/${PROJECT_ID}/events \
      -d 'token='$INTEGRATION_JWT_TOKEN''\
      -d 'triggerType=Deploy'\
    | jq -r '.test_run_id')"

  AUTHORIZATION_TOKEN="$( \
    curl -X POST -G ${API_URL}/auth/token \
    -H 'x-api-key: '${API_KEY}'' \
    -H 'client_id: '${CLIENT_ID}'' \
    -H 'scopes: '${SCOPES}'' \
    | jq -r '.token')"

  # Wait until the test run has finished
  TOTAL_ITERATION=200
  I=1
  while : ; do
     RESULT="$( \
     curl -X GET ${API_URL}/automation-history?project_id=${PROJECT_ID}\&test_run_id=${TEST_RUN_ID} \
     -H 'token: Bearer '$AUTHORIZATION_TOKEN'' \
     -H 'x-api-key: '${API_KEY}'' \
    | jq -r '.[0].finished')"
    if [ "$RESULT" != null ]; then
      break;
    if [ "$I" -ge "$TOTAL_ITERATION" ]; then
      echo "Exit qualiti execution for taking too long time.";
      exit 1;
    fi
    fi
      sleep 15;
  done

  # # Once finished, verify the test result is created and that its passed
  TEST_RUN_RESULT="$( \
    curl -X GET ${API_URL}/test-results?test_run_id=${TEST_RUN_ID}\&project_id=${PROJECT_ID} \
      -H 'token: Bearer '$AUTHORIZATION_TOKEN'' \
      -H 'x-api-key: '${API_KEY}'' \
    | jq -r '.[0].status' \
  )"
  echo "Qualiti E2E Tests ${TEST_RUN_RESULT}"
  if [ "$TEST_RUN_RESULT" = "Passed" ]; then
    exit 0;
  fi
  exit 1;
  

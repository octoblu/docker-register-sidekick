#!/bin/bash

if [ -z "$BACKEND_ID" -o -z "$SERVER_ID" -o -z "$URL" -o -z "$VULCAN_URL" -o -z "$TIMEOUT_SECS" ]; then
  echo "register-healthcheck requires the following variables:"
  echo '  $BACKEND_ID $SERVER_ID $URL $VULCAN_URL $TIMEOUT_SECS'
  exit 1
fi

function ttl_param {
  if [ -n "$FRONTEND_TTL_SECS" ]; then
    echo "--ttl ${FRONTEND_TTL_SECS}s"
  fi
}

function disableBackend {
  vctl server rm --backend $BACKEND_ID --id $SERVER_ID --vulcan $VULCAN_URL
}

function enableBackend {
  vctl server upsert \
      --id $SERVER_ID \
      --backend $BACKEND_ID \
      --url $URL \
      --vulcan $VULCAN_URL \
      $(ttl_param)
}

echo 'Adding backend, server, and frontend to vulcand'

vctl backend upsert --id $BACKEND_ID --vulcan $VULCAN_URL

while true; do
  curl --silent -I $URL/healthcheck | head -n 1 | awk '{print $2}' | grep '200'
  HEALTHCHECK_STATUS=$?

  if [ $HEALTHCHECK_STATUS -eq 0 ]; then
    enableBackend
  else
    disableBackend
  fi

  sleep $TIMEOUT_SECS
done

#!/bin/bash
set -euxo pipefail
cd "$(dirname "$0")/.."

rm -rf /tmp/nextcloud-neon
mkdir -p /tmp/nextcloud-neon

(
  cd packages/nextcloud
  rm coverage -rf
  fvm dart run coverage:test_with_coverage --function-coverage --branch-coverage -- --timeout 60s "$@"
  lcov --remove coverage/lcov.info "$(pwd)/lib/src/nextcloud.openapi.g.dart" -o coverage/filtered.info
  genhtml coverage/filtered.info -o coverage/html
)

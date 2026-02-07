#!/bin/bash
# Load environment variables and run the server

set -a
source .env
set +a

dart run bin/server.dart

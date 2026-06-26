#!/bin/bash
# Load secrets from .env and launch the app in Chrome.
# Usage: ./run.sh
set -euo pipefail

if [ ! -f .env ]; then
  echo "Error: .env file not found. Copy .env.example and fill in your keys."
  exit 1
fi

source .env

flutter run -d chrome \
  --dart-define=FEATHERLESS_API_KEY="$FEATHERLESS_API_KEY" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

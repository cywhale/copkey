#!/bin/bash
if ls src/template.html 1> /dev/null 2>&1; then
  rm src/template.html
fi
export PORT="${PORT:-3004}"
export NODE_ENV=development
yarn dev --config config/preact.config.js

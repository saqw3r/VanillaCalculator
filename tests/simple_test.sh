#!/usr/bin/env bash
cd /f/VanillaCalculator

echo "Test 1: running bats with only 'no sandbox' test"
timeout 30 ./node_modules/.bin/bats --filter 'no sandbox' tests/mysandbox.bats
echo "Exit: $?"

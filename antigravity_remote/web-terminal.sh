#!/bin/bash

echo "============================================================"
echo "  Antigravity Remote - Home Assistant Web Terminal"
echo "============================================================"
echo ""
echo "To sign in with your Google Account, run:"
echo "  agy"
echo "(Follow the printed OAuth URL, then exit with /exit or Ctrl+D Ctrl+D)"
echo ""
echo "To check Remote Control status, run:"
echo "  agy remote-control status"
echo ""
echo "Once logged in, Remote Control starts automatically within 15s."
echo "============================================================"
echo ""

exec /bin/bash -l

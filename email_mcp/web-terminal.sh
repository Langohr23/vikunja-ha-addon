#!/bin/bash

echo "============================================================"
echo "  IMAP/SMTP Email MCP Server - Home Assistant Web Terminal"
echo "============================================================"
echo ""
echo "MCP Endpoint: http://<host>:8081/mcp"
echo ""
echo "To set up or manage your IMAP/SMTP accounts, run:"
echo "  email-mcp setup"
echo "  email-mcp account add"
echo "  email-mcp test"
echo ""
echo "Once configured, the MCP server starts automatically within 10s."
echo "============================================================"
echo ""

exec /bin/bash -l

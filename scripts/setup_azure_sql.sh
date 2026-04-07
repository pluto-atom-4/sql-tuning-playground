#!/bin/bash
# ============================================================================
# Azure SQL Setup Script - ETL/Analytics Path (Path C)
# ============================================================================
# Creates and configures Azure SQL Database for ETL pipeline optimization
#
# This script is for Path C (ETL/Analytics) in detailed-learning-guide.md
# For Path A (WordPress) and Path B (ML), use Docker instead:
#   make setup-local
#
# Prerequisites:
#   - Azure CLI installed: https://learn.microsoft.com/cli/azure/install-azure-cli
#   - Logged in: az login
#
# Usage:
#   bash scripts/setup_azure_sql.sh
#
# Estimated time: 5-10 minutes
# Cost: Free tier (if eligible) or ~$5-10/month for testing
# ============================================================================

set -e

# Configuration
RG_NAME="${AZURE_RESOURCE_GROUP:-sql-tuning-rg}"
LOCATION="${AZURE_LOCATION:-eastus}"
SERVER_NAME="${AZURE_SERVER_NAME:-sql-tuning-etl-$(date +%s)}"
DB_NAME="${AZURE_DB_NAME:-research_analytics}"
ADMIN_USER="${AZURE_ADMIN_USER:-sqladmin}"
ADMIN_PASSWORD="${AZURE_ADMIN_PASSWORD:-P@ssw0rd123!}"  # CHANGE THIS!

echo "============================================================================"
echo "Azure SQL Setup - ETL/Analytics Path (Path C)"
echo "============================================================================"
echo ""
echo "Creating infrastructure for ETL pipeline optimization exercise"
echo ""

# Step 1: Create resource group
echo "[1/5] Creating resource group: $RG_NAME"
az group create \
  --name "$RG_NAME" \
  --location "$LOCATION" \
  2>/dev/null || echo "  (Resource group already exists)"

# Step 2: Create Azure SQL Server
echo "[2/5] Creating Azure SQL Server: $SERVER_NAME"
az sql server create \
  --resource-group "$RG_NAME" \
  --name "$SERVER_NAME" \
  --location "$LOCATION" \
  --admin-user "$ADMIN_USER" \
  --admin-password "$ADMIN_PASSWORD" \
  --enable-public-endpoint true

# Step 3: Create firewall rule
echo "[3/5] Configuring firewall (allowing all IPs - for learning only)"
az sql server firewall-rule create \
  --resource-group "$RG_NAME" \
  --server "$SERVER_NAME" \
  --name "AllowAllIps" \
  --start-ip-address "0.0.0.0" \
  --end-ip-address "255.255.255.255" \
  2>/dev/null || true

# Step 4: Create database
echo "[4/5] Creating database: $DB_NAME"
az sql db create \
  --resource-group "$RG_NAME" \
  --server "$SERVER_NAME" \
  --name "$DB_NAME" \
  --sku Basic \
  --size 2GB

# Step 5: Get FQDN
echo "[5/5] Getting connection details..."
FQDN=$(az sql server show \
  --resource-group "$RG_NAME" \
  --name "$SERVER_NAME" \
  --query fullyQualifiedDomainName \
  --output tsv)

# Display results
echo ""
echo "============================================================================"
echo "✓ Setup Complete!"
echo "============================================================================"
echo ""
echo "Connection Details:"
echo "  Server:   $FQDN"
echo "  Database: $DB_NAME"
echo "  User:     $ADMIN_USER"
echo ""
echo "Connection Command:"
echo "  sqlcmd -S $FQDN -U $ADMIN_USER -P $ADMIN_PASSWORD -d $DB_NAME"
echo ""
echo "============================================================================"
echo "Next Steps"
echo "============================================================================"
echo ""
echo "1. Save credentials to .claude/settings.local.json:"
echo ""
echo '   {
#     "env": {
#       "AZURE_SQL_SERVER": "'$FQDN'",
#       "AZURE_SQL_USER": "'$ADMIN_USER'",
#       "AZURE_SQL_PASSWORD": "'$ADMIN_PASSWORD'"
#     }
#   }'
echo ""
echo "2. Load ETL schema:"
echo "   sqlcmd -S $FQDN -U $ADMIN_USER -P $ADMIN_PASSWORD -d $DB_NAME -i scripts/setup_etl_schema.sql"
echo ""
echo "3. Load test data:"
echo "   sqlcmd -S $FQDN -U $ADMIN_USER -P $ADMIN_PASSWORD -d $DB_NAME -i scripts/setup_etl_test_data.sql"
echo ""
echo "4. Run optimization:"
echo "   sqlcmd -S $FQDN -U $ADMIN_USER -P $ADMIN_PASSWORD -d $DB_NAME -i scripts/optimize_etl_pipeline.sql"
echo ""
echo "5. Start exercise: docs/detailed-learning-guide.md (PATH C: ETL/Analytics)"
echo ""
echo "============================================================================"
echo ""
echo "For other paths:"
echo "  - Path A (WordPress): Use Docker - make setup-local && make load-all"
echo "  - Path B (Machine Learning): Use Docker PostgreSQL - make setup-local && make load-all"
echo "  - Path C (ETL/Analytics): Use this Azure setup (you just did it!)"
echo ""
echo "============================================================================"

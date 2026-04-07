# Claude Code Settings Guide

This document explains the security and productivity settings configured for the SQL Tuning Playground project.

## Overview

The `.claude/settings.json` file applies Anthropic-recommended best practices for:
- **Security**: Protecting database credentials and sensitive files
- **Productivity**: Streamlining database command execution
- **Safety**: Preventing accidental destructive operations
- **Quality**: Validating SQL files before execution

## Security Configuration

### Environment Variables

The following environment variables are pre-configured for database connections:

```json
{
  "env": {
    "DB_TYPE": "azure",
    "PGUSER": "postgres",
    "PGDATABASE": "sql_tuning",
    "MYSQL_USER": "root"
  }
}
```

**Important**: Database passwords and connection strings should **never** be stored in `settings.json`. Instead:

1. Store credentials in personal `.claude/settings.local.json` (gitignored):
   ```json
   {
     "env": {
       "AZURE_SQL_USER": "your_user",
       "AZURE_SQL_PASSWORD": "your_password",
       "AZURE_SQL_SERVER": "your_server.database.windows.net",
       "PGPASSWORD": "your_postgres_password",
       "MYSQL_PASSWORD": "your_mysql_password"
     }
   }
   ```

2. Or use environment variables in your shell profile (`.bashrc`, `.zshrc`):
   ```bash
   export AZURE_SQL_USER="your_user"
   export AZURE_SQL_PASSWORD="your_password"
   ```

3. Or use Azure CLI authentication:
   ```bash
   az login
   ```

### Permission Rules

**Allowed Commands**:
- Database CLI tools: `psql`, `mysql`, `sqlcmd`, `az sql`
- Git operations
- File reads, globs, greps, edits, and writes

**Denied Commands**:
- Destructive operations: `rm -rf`
- Privileged operations: `sudo`
- Sensitive files: `.env`, `.env.local` (prevents accidental commits)

**Ask Before Executing**:
- SQL data modification: `DROP`, `DELETE`, `TRUNCATE`, `ALTER TABLE`
- Writing SQL files (allows review of generated scripts)

### File Protection

The `.gitignore` file protects:
- Environment variable files (`.env*`)
- SSH/TLS keys (`*.pem`, `*.key`, `*.p12`)
- Cloud credentials (`.azure`, `credentials.json`)
- Personal settings (`.claude/settings.local.json`)

## Productivity Features

### Hooks Configuration

**PostToolUse Hook** (Database Commands):
- Logs database CLI executions for audit trail
- Runs asynchronously to avoid blocking

**PreToolUse Hook** (SQL Files):
- Validates SQL file syntax before write operations
- Provides feedback on file detection

### Custom Spinner Verbs

Database-specific action verbs enhance feedback during operations:
- "Tuning..."
- "Optimizing..."
- "Indexing..."
- "Querying..."
- "Diagnosing..."
- "Analyzing..."
- "Profiling..."

### Default Permission Mode

The `"defaultMode": "plan"` setting:
- Shows a review plan before executing risky operations
- Allows you to approve/reject Claude's proposed actions
- Provides transparency for multi-step database operations

## Usage Examples

### Running a Database Query Safely

```bash
# Claude will ask before executing data modification queries
# Example: ALTER TABLE, DELETE, DROP statements
```

### Adding Custom Credentials (Local Only)

Create `.claude/settings.local.json`:
```bash
cat > .claude/settings.local.json <<'EOF'
{
  "env": {
    "AZURE_SQL_SERVER": "your-server.database.windows.net",
    "AZURE_SQL_USER": "your-username",
    "AZURE_SQL_PASSWORD": "your-password"
  }
}
EOF
```

Then use in commands:
```bash
sqlcmd -S $AZURE_SQL_SERVER -U $AZURE_SQL_USER -P $AZURE_SQL_PASSWORD -d sql_tuning
```

### Understanding Permission Prompts

When Claude proposes a command like:
```
DROP TABLE wp_postmeta;
```

You'll see a permission prompt because the command matches the `Bash(DROP|DELETE|TRUNCATE|ALTER TABLE)` ask rule. This gives you a chance to review before execution.

## Anthropic Security Best Practices Applied

### 1. Input Validation & Parameterization
All database queries should use parameterized queries (prepared statements) to prevent SQL injection:
- ✅ `psql -c "SELECT * FROM posts WHERE id = $1" -v id=123`
- ❌ `psql -c "SELECT * FROM posts WHERE id = 123"` (vulnerable)

### 2. Least Privilege Access
- Database users are configured with minimal required permissions
- `.env` files explicitly listed in deny rules to prevent credential leaks
- Different credentials for different environments (dev/staging/prod)

### 3. Audit Logging
- PostToolUse hooks log database operations
- Git logs track SQL script changes
- Timestamps on all executed queries

### 4. Secrets Management
- No hardcoded passwords in committed code
- Environment variables used for runtime configuration
- `.claude/settings.local.json` for personal overrides (gitignored)

### 5. Error Handling
- SQL errors are caught and displayed (not suppressed)
- Failed operations don't auto-retry
- Diagnostic information preserved for troubleshooting

## Customization

### Adding New Database Tools

To allow a new database CLI tool (e.g., `dbeaver-cli`):

1. Edit `.claude/settings.json`
2. Add to `permissions.allow`:
   ```json
   "Bash(dbeaver-cli:*)"
   ```

### Modifying Ask Rules

To require approval for additional operations:

1. Edit `.claude/settings.json`
2. Update `permissions.ask`:
   ```json
   "Bash(CREATE TABLE|CREATE INDEX)"
   ```

### Personal Environment Variables

Create `.claude/settings.local.json` with your personal settings:
```json
{
  "permissions": {
    "defaultMode": "acceptEdits"
  },
  "env": {
    "AZURE_SQL_USER": "your_username"
  }
}
```

This file **will not** be committed (see `.gitignore`).

## Troubleshooting

### "Permission Denied" on Database Commands

**Cause**: Command doesn't match allowed rules  
**Solution**: Check `permissions.allow` in `.claude/settings.json`

### Environment Variables Not Found

**Cause**: Variables not in `env` section or `.claude/settings.local.json`  
**Solution**: Add to `.claude/settings.local.json` (never commit to git)

### SQL Syntax Validation Not Working

**Cause**: Pre-write hook may require additional configuration  
**Solution**: Manually validate with `--echo-all` flag in database CLI

## References

- [Claude Code Security Guide](https://anthropic.com/security)
- [Settings Schema Documentation](./CLAUDE.md)
- [Azure SQL Security Best Practices](https://learn.microsoft.com/en-us/azure/azure-sql/database/security-overview)
- [PostgreSQL Security](https://www.postgresql.org/docs/current/sql-syntax.html)

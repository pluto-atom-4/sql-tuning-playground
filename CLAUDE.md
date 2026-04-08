# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**sql-tuning-playground** is a hands-on learning project focused on SQL optimization techniques for shared web hosting environments. The curriculum covers three database systems (PostgreSQL 17, MariaDB, Azure SQL) with emphasis on WordPress/LAMP stack bottlenecks and production incident scenarios.

**Duration:** 3-day intensive (following `docs/learning-plan.md`)  
**Target:** Practical tuning techniques applicable to infrastructure supporting ~29K shared hosting sites  
**Database Strategy:** Azure free-tier SQL for cloud exercises; local PostgreSQL + MariaDB via Docker Compose; all exercises use InnoDB-compatible configs (production MySQL 8.0 equivalent)

## Project Structure

```
sql-tuning-playground/
├── docs/
│   ├── learning-plan.md       # 3-day curriculum outline
│   └── troubleshooting_guide.md # Diagnostic guide for slow queries (Day 3 deliverable)
├── scripts/
│   ├── optimize_wordpress.sql  # WordPress indexing & cleanup batch script
│   ├── setup_postgres.sql      # PostgreSQL configuration & test data
│   ├── setup_mysql.sql         # MySQL/WordPress test environment
│   ├── setup_azure_sql.sql     # Azure SQL schema & sample data
│   └── diagnose_slow_queries.sql # Query monitoring utilities
├── exercises/
│   ├── day1_wordpress_audit/   # WordPress Query Monitor exercises
│   ├── day2_postgres_tuning/   # PgBouncer & tuning exercises
│   ├── day2_mysql_tuning/      # InnoDB buffer pool exercises
│   ├── day2_azure_sql/         # Query Performance Insight exercises
│   └── day3_incident_simulations/ # Postmortem scenario drills
└── CLAUDE.md                    # This file
```

## Database Connectivity

### Azure SQL (Primary for cloud exercises)
Use Azure CLI to manage resources and `sqlcmd` or Azure Data Studio for queries:

```bash
# List connection string
az sql db show-connection-string --client sqlcmd --server <server-name> --name <db-name>

# Connect via sqlcmd
sqlcmd -S <server>.database.windows.net -d <db-name> -U <user> -P <password>

# Execute script
sqlcmd -S <server>.database.windows.net -d <db-name> -U <user> -P <password> -i scripts/setup_azure_sql.sql
```

### PostgreSQL (Local testing)
```bash
# Connect to local PostgreSQL
psql -U postgres -d sql_tuning

# Execute script
psql -U postgres -d sql_tuning -f scripts/setup_postgres.sql

# Run single exercise query
psql -U postgres -d sql_tuning -c "SELECT * FROM wp_posts LIMIT 10;"
```

### MariaDB/WordPress (Local Docker)
Local MariaDB runs via `docker compose` (started with `make setup-local`).

```bash
# Connect via Docker
docker compose exec mysql mysql -u wordpress -pwordpress wordpress_test

# Or, if MySQL client is installed locally
mysql -h localhost -u wordpress -pwordpress -D wordpress_test

# Run WordPress-specific diagnostic
docker compose exec mysql mysql -u wordpress -pwordpress wordpress_test -e "SELECT SUM(LENGTH(option_value)) FROM wp_options WHERE autoload = 'yes';"

# Check slow query log
docker compose exec mysql cat /config/log/slow-query.log
```

**Container details:**
- Image: `lscr.io/linuxserver/mariadb:latest` (compatible with MySQL 8.0 exercises)
- Port: `3306:3306`
- Data volume: `mysqldata:/config` (persistent across restarts)
- Config file: mounted at `/config/custom.cnf` (includes tuning params: `innodb_buffer_pool_size=512M`, `max_connections=200`, slow query log)

## Key Learning Areas

### Day 1: WordPress Optimization
- **Silent Killers:** Unindexed `wp_postmeta`, bloated `wp_options`, uncleaned transients
- **Core Techniques:** INDEX strategy (compound indexes), SELECT optimization, LIKE pattern avoidance
- **Deliverable:** `scripts/optimize_wordpress.sql` — automated index creation and cleanup

### Day 2: Infrastructure & High Availability
- **Read Replicas & Pooling:** Connection pool configuration (PgBouncer for PostgreSQL)
- **Server Tuning:** Adjusting buffer pools, connection limits, and memory allocation (InnoDB `innodb_buffer_pool_size`, `max_connections`, slow query log)
- **Cloud Diagnostic:** Using Azure Query Performance Insight for cloud-based SQL tuning
- **Exercises:** Measure performance before/after tuning parameter changes (MariaDB slow query logs in local `/config/log/`)

### Day 3: Incident Scenarios
- **Postmortem Drills:** Rapid diagnosis of slow queries in production
- **Technical Concepts:** Indexes (clustered vs. non-clustered), TRUNCATE vs DELETE, ACID properties, MVCC
- **Deliverable:** `docs/troubleshooting_guide.md` — operational diagnostic checklists

## Common Development Tasks

### Setting Up Exercises
Each exercise directory contains:
- `setup.sql` — schema and test data creation
- `README.md` — problem statement and learning objectives
- `solution.sql` — reference implementation with explanations

**Run an exercise:**
```bash
# 1. Load schema and test data
psql -U postgres -d sql_tuning -f exercises/day1_wordpress_audit/setup.sql

# 2. Write your solution in solution.sql
# 3. Verify execution
psql -U postgres -d sql_tuning -f exercises/day1_wordpress_audit/solution.sql
```

### Validating Optimizations
For each optimization, capture baseline vs. optimized metrics:

```bash
# PostgreSQL: timing and execution plan
\timing on
EXPLAIN ANALYZE SELECT ...

# MySQL: profiling and slow query capture
SET profiling=1;
SELECT ...
SHOW PROFILES;

# Azure SQL: Execution plan (graphical in Portal)
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
SELECT ...
```

### Adding New Exercises
1. Create directory under `exercises/` with descriptive name
2. Include `setup.sql`, `README.md` (problem + learning goals), and `solution.sql`
3. Ensure scripts are idempotent (can run multiple times safely)

## Performance Baseline Expectations

When exercises include performance measurements, capture:
- **Query execution time** (in ms)
- **IO statistics** (logical reads, physical reads)
- **Index usage** (scans vs. seeks)
- **Connection pooling stats** (active connections, wait time)

Store baseline and optimized results in exercise `results.txt` for comparison.

## Important Constraints & Conventions

- **Idempotency:** All SQL scripts must use `IF NOT EXISTS` / `DROP IF EXISTS` and can be safely re-run
- **Local Docker Setup:** `docker-compose.yml` provides PostgreSQL and MariaDB for rapid iteration. Start with `make setup-local`. Azure free-tier SQL is used only for cloud-specific exercises (Query Performance Insight, etc.)
- **Azure Credentials:** Never commit connection strings; use environment variables:
  ```bash
  export AZURE_SQL_USER="<user>"
  export AZURE_SQL_PASSWORD="<password>"
  export AZURE_SQL_SERVER="<server>.database.windows.net"
  ```
- **WordPress Focus:** When optimizing queries, prioritize `wp_postmeta`, `wp_options`, and `wp_posts` tables
- **Shared Hosting Context:** All exercises assume multi-tenant scenarios (29K+ sites); test connection limits and query concurrency

## Anthropic Security Guidance

Claude Code settings (`.claude/settings.json` and `.claude/settings.local.json`) enforce Anthropic best practices:

### Configured Security Controls
- **Permission Rules:** Database tools (psql, mysql, sqlcmd) pre-approved; destructive operations require approval
- **Secrets Protection:** `.env*` files denied from write; credentials stored only in gitignored `.claude/settings.local.json`
- **Audit Hooks:** Database operations logged asynchronously; git tracks all SQL script changes
- **Environment Isolation:** Separate configs for dev (local) vs. cloud (Azure)

### Best Practices for Code
- **Input Validation:** Parameterized queries for all user inputs (no string concatenation for SQL)
- **Secrets Management:** Use `$AZURE_SQL_USER`, `$PGPASSWORD` env vars; never hardcode credentials
- **Access Control:** Principle of least privilege (read-only for diagnostic queries, limited user accounts)
- **Audit Logging:** Enable database audit logging for production-equivalent Azure SQL exercises
- **Sensitive Data:** Anonymize PII in test data; use pseudonymous IDs for WordPress post/user data

See `.claude/SETTINGS_GUIDE.md` for detailed configuration and examples.

## Troubleshooting Notes

- **Connection timeout on Azure SQL:** Check firewall rules allow your IP
- **PgBouncer pooling issues:** Use `SHOW POOLS` and `SHOW DATABASES` to debug
- **MariaDB container won't start:** Check `docker compose logs mysql` for config errors. Common issues: `log_error_verbosity` (MySQL-only, use `log_warnings` in MariaDB), incorrect slow log path
- **WordPress plugin conflicts:** Query Monitor plugin is safe for audit exercises; always test in isolated environment
- **Index bloat over time:** Monitor with `SELECT * FROM pg_stat_user_indexes` (PostgreSQL) or `SELECT * FROM INFORMATION_SCHEMA.STATISTICS` (MariaDB/Azure SQL)

## References

- **PostgreSQL:** [Official tuning docs](https://www.postgresql.org/docs/current/performance-tips.html)
- **MariaDB:** [InnoDB optimization guide](https://mariadb.com/kb/en/library/optimization/) (local Docker image); exercises are compatible with MySQL 8.0 configs
- **MySQL 8.0:** [InnoDB optimization guide](https://dev.mysql.com/doc/refman/8.0/en/innodb-optimization.html) (production target system for shared hosting)
- **Azure SQL:** [Query Performance Insight documentation](https://learn.microsoft.com/en-us/azure/azure-sql/database/query-performance-insight-use)
- **WordPress:** Query Monitor plugin for WP-specific diagnostics
- **linuxserver/mariadb:** [Docker image documentation](https://docs.linuxserver.io/images/docker-mariadb/)

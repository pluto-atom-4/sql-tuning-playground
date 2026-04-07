# Quick Reference: Commands & Tools for SQL Tuning

**Use this document during the learning period and bookmark for the interview.**

---

## PostgreSQL (psql)

### Connection & Basic Commands

```bash
# Connect to local PostgreSQL
psql -U postgres -d sql_tuning

# Connect to Azure PostgreSQL
psql -h your-server.postgres.database.azure.com -U pgadmin@your-server -d postgres

# List databases
\l

# Switch database
\c sql_tuning

# List tables
\dt

# Show table structure
\d table_name

# Execute query from file
\i scripts/setup_postgres.sql

# Quit
\q
```

### Performance Analysis

```sql
-- Query execution plan (text)
EXPLAIN SELECT * FROM wp_posts WHERE post_status = 'publish';

-- Query execution plan (detailed JSON)
EXPLAIN ANALYZE FORMAT JSON SELECT * FROM wp_posts WHERE post_status = 'publish';

-- Show table size
SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Show slow queries
SELECT query, calls, mean_time, max_time 
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;
-- (requires: CREATE EXTENSION pg_stat_statements;)

-- Show table bloat
SELECT schemaname, tablename, 
  ROUND(100 * (CASE WHEN otta > 0 
    THEN sml.relpages - otta 
    ELSE 0 END) / sml.relpages) AS table_waste_percent
FROM pg_class sml
JOIN pg_namespace ON pg_namespace.oid = sml.relnamespace
WHERE sml.relname = 'wp_postmeta';

-- Show index usage
SELECT schemaname, tablename, indexname, idx_scan 
FROM pg_stat_user_indexes 
ORDER BY idx_scan;
-- High idx_scan = good index. 0 = unused index (can delete)
```

### Tuning Commands

```sql
-- Add index
CREATE INDEX idx_post_id_meta_key ON wp_postmeta (post_id, meta_key);

-- Drop index
DROP INDEX idx_post_id_meta_key;

-- Analyze table (updates query planner stats)
ANALYZE wp_postmeta;

-- Vacuum (reclaim space from deleted rows)
VACUUM ANALYZE wp_postmeta;

-- Full vacuum (aggressive, locks table)
VACUUM FULL wp_postmeta;

-- Show connections
SELECT datname, usename, state, count(*) 
FROM pg_stat_activity 
GROUP BY datname, usename, state;

-- Kill slow query
SELECT pg_terminate_backend(pid) FROM pg_stat_activity 
WHERE state = 'active' AND query_start < NOW() - INTERVAL '5 minutes';

-- Show replication status
SELECT * FROM pg_stat_replication;

-- Show pg_stat_statements (top queries)
SELECT query, calls, mean_time, max_time, total_time 
FROM pg_stat_statements 
ORDER BY total_time DESC 
LIMIT 10;
```

### PgBouncer Commands

```bash
# Connect to PgBouncer admin console (localhost:6432)
psql -h localhost -p 6432 -U pgbouncer -d pgbouncer

# From admin console:
SHOW STATS;       -- Connection pool statistics
SHOW POOLS;       -- Pool status per database
SHOW DATABASES;   -- Database configuration
SHOW CONFIG;      -- Current pgbouncer config

# Reload config without restart
RELOAD;

# Stop PgBouncer
SHUTDOWN;
```

---

## MySQL (mysql/sqlcmd)

### Connection & Basic Commands

```bash
# Connect to local MySQL
mysql -u root -p mysql_db

# Connect to Azure SQL (via sqlcmd)
sqlcmd -S your-server.database.windows.net -U user -P password -d mysql_db

# Execute query
mysql -u root -p mysql_db -e "SELECT COUNT(*) FROM wp_posts;"

# Execute SQL file
mysql -u root -p mysql_db < script.sql

# Dump database (backup)
mysqldump -u root -p mysql_db > backup.sql

# Restore database
mysql -u root -p mysql_db < backup.sql
```

### Performance Analysis

```sql
-- Show current connections
SHOW PROCESSLIST;

-- Show full processlist (with query text)
SHOW FULL PROCESSLIST\G

-- Kill slow query
KILL connection_id;

-- Enable slow query log (queries > 0.5 sec)
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 0.5;

-- View slow queries
TAIL /var/log/mysql/slow.log;

-- Query execution plan
EXPLAIN SELECT * FROM wp_posts WHERE post_status = 'publish';

-- Detailed execution plan (JSON)
EXPLAIN FORMAT=JSON SELECT * FROM wp_posts WHERE post_status = 'publish'\G

-- Show table size
SELECT 
  table_schema,
  table_name,
  ROUND(((data_length + index_length) / 1024 / 1024), 2) as size_mb
FROM information_schema.tables
WHERE table_schema NOT IN ('mysql', 'information_schema', 'performance_schema')
ORDER BY size_mb DESC;

-- Show index usage
SELECT object_schema, object_name, count_read, count_write 
FROM performance_schema.table_io_waits_summary_by_index_usage 
WHERE count_read = 0 AND count_write = 0
ORDER BY count_read;
-- 0 count_read = unused index

-- Show slow queries (MySQL 5.7+)
SELECT * FROM mysql.slow_log ORDER BY start_time DESC LIMIT 10;
```

### Tuning Commands

```sql
-- Add index
ALTER TABLE wp_postmeta ADD INDEX idx_post_id_meta_key (post_id, meta_key(191));

-- Drop index
ALTER TABLE wp_postmeta DROP INDEX idx_post_id_meta_key;

-- Show indexes on table
SHOW INDEXES FROM wp_postmeta;

-- Analyze table (updates query planner stats)
ANALYZE TABLE wp_postmeta;

-- Optimize table (reclaim space, rebuild indexes)
OPTIMIZE TABLE wp_postmeta;

-- Check table for errors
CHECK TABLE wp_postmeta;

-- Show variables
SHOW VARIABLES LIKE 'max_connections';
SHOW VARIABLES LIKE 'innodb_buffer_pool_size';

-- Set variable (session only)
SET SESSION max_execution_time = 30000;  -- 30 seconds

-- Set variable (global, survives restart if in config file)
SET GLOBAL max_connections = 500;

-- Show current database
SELECT DATABASE();

-- Show current user
SELECT USER();

-- Show server version
SELECT VERSION();

-- Show status
SHOW STATUS LIKE 'Threads%';
SHOW STATUS LIKE 'Questions';
SHOW STATUS LIKE 'Innodb_buffer_pool_read_requests';
```

### Identifying Slow Queries

```sql
-- Find missing indexes (MySQL 5.7+)
SELECT * FROM performance_schema.table_io_waits_summary_by_index_usage 
WHERE object_schema != 'mysql' 
  AND count_read = 0 
  AND count_write = 0 
ORDER BY object_schema, object_name;

-- Find expensive queries (largest table scans)
SELECT object_schema, object_name, count_star, count_read 
FROM performance_schema.table_io_waits_summary_by_table 
WHERE object_schema != 'mysql'
ORDER BY count_star DESC;

-- Find lock waits
SELECT * FROM performance_schema.events_waits_current 
WHERE event_name LIKE 'wait/lock%' LIMIT 5;
```

---

## Azure SQL (sqlcmd)

### Connection

```bash
# Get connection string
az sql db show-connection-string --client sqlcmd --server your-server --name your-db

# Example:
# sqlcmd -S your-server.database.windows.net -U user -P password -d your-db -N

# Connect
sqlcmd -S your-server.database.windows.net -U user -P password -d sql_tuning -N
```

### Performance Tuning

```sql
-- Query Performance Insight (built-in Azure SQL feature)
-- See top slow queries in Azure Portal → Query Performance Insights

-- Enable query store (required for perf insights)
ALTER DATABASE CURRENT SET QUERY_STORE = ON;

-- View slow queries
SELECT query_id, execution_count, total_elapsed_time, avg_elapsed_time
FROM sys.query_store_query_text qt
JOIN sys.query_store_query q ON qt.query_text_id = q.query_text_id
ORDER BY avg_elapsed_time DESC
LIMIT 10;

-- Show current connections
SELECT COUNT(*) as connection_count, DB_NAME() as database_name 
FROM sys.dm_exec_sessions WHERE database_id > 4;

-- Kill slow query
DECLARE @session_id INT = 52;  -- Replace with actual session ID
KILL @session_id;

-- Index recommendations
SELECT * FROM sys.dm_db_missing_index_details;
```

---

## Command Line Tools

### Benchmark Tools

```bash
# Apache Bench (measure web server performance)
ab -n 1000 -c 100 https://example.edu/
# -n: total requests
# -c: concurrent requests

# WRK (fast HTTP benchmarking)
wrk -t4 -c100 -d30s https://example.edu/

# Load test WordPress with symcache
# Install: sudo apt-get install symcache
# Uses cache during load test (realistic)
```

### Database Monitoring

```bash
# Watch MySQL processlist in real-time
watch -n 0.5 'mysql -u root -p -e "SHOW PROCESSLIST;" | head -20'

# Watch PostgreSQL connections
watch -n 0.5 'psql -U postgres -c "SELECT count(*) FROM pg_stat_activity;"'

# Monitor database size over time
while true; do
  echo "$(date): $(du -sh /var/lib/mysql/)"
  sleep 300  # Every 5 minutes
done >> ~/db_size_log.txt
```

### Log Parsing

```bash
# Find all queries taking >1 second from slow log
grep "Query_time: [1-9]" /var/log/mysql/slow.log

# Count slow queries by type
grep "^SELECT\|^UPDATE\|^INSERT\|^DELETE" /var/log/mysql/slow.log | cut -d' ' -f1 | sort | uniq -c

# Parse slow log with mysql-slow-log-parser
tail -1000 /var/log/mysql/slow.log | mysqlsla -lt 0.5 -top 10
```

---

## Key Metrics & Thresholds

### Performance Red Flags

| Metric | Good | Warning | Critical |
|--------|------|---------|----------|
| Query time | <10ms | 10-100ms | >100ms |
| Rows examined | ~= rows returned | 2-10x returned | >100x returned |
| Table scan % | 0% | <5% | >10% |
| Connections | <50% of max | 50-80% | >80% or refused |
| CPU | <30% | 30-60% | >60% |
| Disk I/O wait | <5% | 5-20% | >20% |
| Replication lag | <1 sec | 1-5 sec | >5 sec |
| Backup duration | <30 min | 30-60 min | >60 min |

### Shared Hosting Specific

```
Max connections: 200 (adjust with: SET GLOBAL max_connections = 500;)
Connection timeout: 600 sec (adjust with: SET GLOBAL interactive_timeout = 300;)
Query timeout: unlimited (add with: SET SESSION max_execution_time = 30000;)
Buffer pool hit ratio: >99% (calculate: read_requests / total_requests)
Index usage: >90% of queries should use index (check: EXPLAIN on every query)
```

---

## Useful SQL Snippets

### WordPress Optimization

```sql
-- Add all critical WordPress indexes
ALTER TABLE wp_postmeta ADD INDEX idx_post_id_meta_key (post_id, meta_key(191));
ALTER TABLE wp_options ADD INDEX idx_autoload (autoload);
ALTER TABLE wp_comments ADD INDEX idx_post_approved (comment_post_ID, comment_approved);
ALTER TABLE wp_posts ADD INDEX idx_status_type (post_status, post_type);

-- Find bloated options
SELECT option_name, LENGTH(option_value) as size_bytes, autoload
FROM wp_options
WHERE autoload = 'yes'
ORDER BY LENGTH(option_value) DESC
LIMIT 20;

-- Move large options from autoload
UPDATE wp_options
SET autoload = 'no'
WHERE LENGTH(option_value) > 100000 AND autoload = 'yes';

-- Remove orphaned postmeta
DELETE FROM wp_postmeta
WHERE post_id NOT IN (SELECT ID FROM wp_posts);

-- Remove old revisions (keep last 3)
DELETE FROM wp_posts
WHERE post_type = 'revision'
  AND post_date < DATE_SUB(NOW(), INTERVAL 30 DAY);

-- Clean expired transients
DELETE FROM wp_options
WHERE option_name LIKE '_transient_%'
  AND option_value = '';
```

### Monitoring Queries

```sql
-- Table sizes
SELECT 
  TABLE_NAME,
  ROUND(((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024), 2) as size_mb,
  TABLE_ROWS as row_count
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'wordpress'
ORDER BY size_mb DESC;

-- Index effectiveness
SELECT 
  OBJECT_NAME as table_name,
  INDEX_NAME,
  COUNT_READ as reads,
  COUNT_WRITE as writes,
  COUNT_DELETE as deletes
FROM PERFORMANCE_SCHEMA.TABLE_IO_WAITS_SUMMARY_BY_INDEX_USAGE
WHERE OBJECT_SCHEMA NOT IN ('mysql', 'performance_schema')
  AND INDEX_NAME != 'PRIMARY'
ORDER BY COUNT_READ DESC;

-- Connection distribution
SELECT 
  user,
  COUNT(*) as connection_count,
  MAX(time) as oldest_connection_seconds
FROM INFORMATION_SCHEMA.PROCESSLIST
GROUP BY user
ORDER BY connection_count DESC;
```

---

## Troubleshooting Checklist

### "Database is slow"

```bash
# 1. Check connections
SHOW PROCESSLIST;  # Any sleeping connections? Any time > 60 sec?

# 2. Check CPU/memory
top -b -n 1 | grep mysql
df -h  # Is disk full?

# 3. Find slow query
tail /var/log/mysql/slow.log | head -5

# 4. Analyze with EXPLAIN
EXPLAIN FORMAT=JSON <slow_query>;
# Look for: "type": "ALL", or "rows": > 1000000

# 5. Add index if missing
ALTER TABLE wp_postmeta ADD INDEX idx_fix (post_id, meta_key);

# 6. Verify fix
EXPLAIN FORMAT=JSON <same_query>;
# Should show: "type": "ref" or "const", "rows": small number
```

### "Connection refused"

```bash
# 1. Check max connections
SHOW VARIABLES LIKE 'max_connections';

# 2. Check current connections
SHOW STATUS LIKE 'Threads_connected';
# If >= max_connections: exhausted

# 3. Increase connections
SET GLOBAL max_connections = 500;

# 4. Or enable connection pooling
# Route through PgBouncer on port 6432 instead of 5432
psql -h localhost -p 6432 -U wordpress -d sql_tuning -c "SELECT 1;"
```

### "Backup taking too long"

```bash
# 1. Check database size
du -sh /var/lib/mysql/

# 2. If >100GB: Switch to incremental backup
mysqldump --single-transaction wordpress > backup_full.sql.gz  # Weekly
mysqlbinlog --start-position=X ... > incremental.sql  # Daily

# 3. Or use cloud native backups (Azure backup, AWS RDS backup)
```

---

## Environment Variables (For Azure & SSH)

```bash
# Add to ~/.bashrc or ~/.zshrc

export AZURE_SQL_SERVER="your-server.database.windows.net"
export AZURE_SQL_USER="your-user"
export AZURE_SQL_PASSWORD="your-password"
export PGUSER="postgres"
export PGDATABASE="sql_tuning"
export PGPASSWORD="your-pg-password"

# Quick access functions
alias psql_az='sqlcmd -S $AZURE_SQL_SERVER -U $AZURE_SQL_USER -P $AZURE_SQL_PASSWORD'
alias psql_local='psql -U $PGUSER -d $PGDATABASE'
alias mysql_local='mysql -u root -p'
```

---

## Interview Day (Friday) Prep

### 30 Minutes Before

```bash
# Verify all tools are working
psql -U postgres -d sql_tuning -c "SELECT 1;"  # PostgreSQL
mysql -u root -p -e "SELECT 1;"                # MySQL
sqlcmd -S $AZURE_SQL_SERVER -U $AZURE_SQL_USER -P $AZURE_SQL_PASSWORD  # Azure

# Check slow query log is enabled
mysql -u root -p -e "SHOW VARIABLES LIKE 'slow_query_log';"

# Start monitoring in background (optional)
watch -n 1 'mysql -u root -p -e "SHOW PROCESSLIST;" | wc -l'
```

### Keep Handy During Interview

1. **This quick reference** (bookmark this file)
2. **Interview talking points** (docs/interview-talking-points.md)
3. **Optimization script** (scripts/optimize_wordpress.sql)
4. **Troubleshooting runbook** (docs/troubleshooting_guide.md)

### Practice Saying These Numbers

- 250ms → 5ms (50x faster)
- 5GB autoload → 50KB (100x reduction)
- 29K sites (scale context)
- 200 connections (limitation they'll understand)
- 95% reads, 5% writes (WordPress workload)
- 40% CPU reduction (realistic improvement)

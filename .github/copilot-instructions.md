# Copilot Instructions for sql-tuning-playground

This file helps Copilot AI assistants work effectively in the sql-tuning-playground repository.

## Project Context

**sql-tuning-playground** is an interview prep project for a Software Engineer role supporting ~29K WordPress sites on shared MySQL hosting infrastructure. It provides hands-on SQL optimization training across three paths (WordPress/MySQL, Machine Learning/PostgreSQL, ETL/Azure SQL) over 3 days.

- **Primary Use**: Interview preparation curriculum with practical exercises
- **Core Skill**: Diagnosing slow queries and implementing optimizations (50x-1440x improvements)
- **Key Focus**: WordPress query bottlenecks, connection pooling, incident response

## Build, Test, and Lint Commands

This is a learning/curriculum project, not a software product. There are no traditional builds, tests, or lints. Instead, work with the provided Makefile:

### Essential Makefile Commands

```bash
# Setup & Infrastructure
make setup-local          # Start Docker containers (PostgreSQL, MySQL, PgBouncer)
make docker-status        # Check container health
make docker-logs          # View real-time container logs
make clean                # Stop containers (preserves data)
make clean-volumes        # Stop containers + DELETE all data (use carefully)

# Load Data
make load-all            # Load WordPress schema + test data (all databases)
make load-schema         # Load schema only
make load-data           # Load test data only

# Optimization & Performance Testing
make test-perf           # Run baseline EXPLAIN queries to see unoptimized performance
make test-mysql          # Connect to MySQL shell (wordpress_test database)
make test-postgres       # Connect to PostgreSQL shell (sql_tuning database)
make test-pgbouncer      # Test connection pooling through PgBouncer
make optimize            # Run optimization scripts on both databases
make optimize-mysql      # Run optimization on MySQL only
make optimize-postgres   # Run optimization on PostgreSQL only

# Azure Setup (for Path C exercises)
make setup-azure         # Create Azure SQL database and load schemas
```

### Running Single Exercises

Exercises are in `exercises/day*_*/` directories. Each contains a `README.md` with problem statements. To run an exercise:

```bash
# Example: Day 1 WordPress audit
# 1. Read the exercise
cat exercises/day1_wordpress_audit/README.md

# 2. Connect to the database
make test-mysql

# 3. Run queries from the exercise
# 4. Compare baseline vs. optimized metrics
# 5. Reference solution if stuck
cat exercises/day1_wordpress_audit/solution.sql
```

### Performance Measurement Pattern

All exercises use the same pattern for baseline vs. optimized testing:

```sql
-- BEFORE optimization (baseline)
EXPLAIN ANALYZE SELECT meta_id, post_id, meta_key, meta_value 
FROM wp_postmeta WHERE post_id = 1;

-- [Add index here]
ALTER TABLE wp_postmeta ADD INDEX idx_post_id_meta_key (post_id, meta_key);

-- AFTER optimization
EXPLAIN ANALYZE SELECT meta_id, post_id, meta_key, meta_value 
FROM wp_postmeta WHERE post_id = 1;
```

Document metrics in `exercises/day*/results.txt` format:
- Query execution time (ms)
- Rows examined / Rows returned
- Index usage (scans vs. seeks)
- CPU impact

## High-Level Architecture

### Three Learning Paths (Separate Databases)

```
sql-tuning-playground/
│
├── PATH A: WordPress Optimization (MySQL)
│   ├── Database: MySQL 8.0 (Docker, port 3306)
│   ├── User credentials: wordpress / wordpress
│   ├── Database: wordpress_test
│   ├── Focus: wp_postmeta, wp_options, wp_posts tables
│   ├── Goal: 250ms → 5ms (50x improvement)
│   └── Exercises: exercises/day1_wordpress_audit/
│
├── PATH B: ML Feature Generation (PostgreSQL)
│   ├── Database: PostgreSQL 17 (Docker, port 5432)
│   ├── User credentials: postgres / postgres
│   ├── Database: sql_tuning
│   ├── Focus: Feature store pattern, materialized views
│   ├── Goal: 4 hours → 10 seconds (1440x improvement)
│   └── Connection Pool: PgBouncer on port 6432
│
└── PATH C: ETL Analytics (Azure SQL)
    ├── Database: Azure SQL (Cloud free-tier)
    ├── Focus: Strategic indexing, incremental loading, partitioning
    ├── Goal: 6 hours → 3 minutes (120x improvement)
    └── Setup: bash scripts/setup_azure_sql.sh
```

### Docker Services (Path A & B)

The `docker-compose.yml` defines three services:

1. **PostgreSQL 17** (sql-tuning-postgres)
   - Direct access: port 5432
   - Pre-loaded schemas: `setup_wordpress_schema.sql`, `setup_test_data.sql`
   - Memory tuning: shared_buffers=256MB, work_mem=10MB

2. **MySQL 8.0** (sql-tuning-mysql)
   - Direct access: port 3306
   - Config: `config/my.cnf` (InnoDB tuning for learning)
   - WordPress schema auto-loaded on startup

3. **PgBouncer** (sql-tuning-pgbouncer)
   - Connection pooling for PostgreSQL
   - Access: port 6432
   - Demonstrates connection pooling concepts

### Script Organization

Scripts follow a naming convention:

```
scripts/
├── setup_wordpress_schema.sql    # WordPress tables (9 tables)
├── setup_test_data.sql           # Test data (100 posts, 5K metadata rows)
├── optimize_wordpress.sql        # Reference optimizations (indexes, cleanup)
│
├── setup_ml_schema.sql           # ML tables (students, enrollments, features)
├── setup_ml_test_data.sql        # ML test data
├── optimize_ml_pipeline.sql      # Feature store implementation
│
├── setup_etl_schema.sql          # ETL schema (large datasets)
├── setup_etl_test_data.sql       # ETL test data
├── optimize_etl_pipeline.sql     # ETL optimizations
│
└── setup_azure_sql.sh            # Azure SQL automation
```

**Key constraint**: All SQL scripts must be idempotent (safe to re-run). Use `IF NOT EXISTS` / `DROP IF EXISTS` patterns.

### Exercise Structure

Each exercise directory contains:

```
exercises/day1_wordpress_audit/
├── README.md          # Problem statement + learning objectives
├── setup.sql          # Schema and test data (optional, often uses shared scripts)
├── solution.sql       # Reference implementation with explanations
└── results.txt        # Baseline and optimized metrics (to be filled in)
```

## Key Conventions

### 1. Performance Testing Pattern

**Always establish BEFORE → OPTIMIZE → VERIFY cycle**:

```sql
-- Step 1: Baseline measurement
\timing on          -- PostgreSQL
SET profiling=1;    -- MySQL
EXPLAIN ANALYZE SELECT ...;

-- Step 2: Apply optimization (index, view, etc.)
ALTER TABLE ... ADD INDEX ...;

-- Step 3: Verify improvement
EXPLAIN ANALYZE SELECT ...;
```

Store results in exercise `results.txt`:
```
BASELINE (before optimization):
  Execution time: 250ms
  Rows examined: 5000
  Index used: No (full table scan)

OPTIMIZED (after adding index):
  Execution time: 5ms
  Rows examined: 50
  Index used: Yes (index seek on idx_post_id_meta_key)

IMPROVEMENT: 50x faster, 99% fewer rows examined
```

### 2. Database Connection Details

**Know the connection strings by heart** (they appear in exercises):

| Path | Database | Host | Port | User | Password | Database |
|------|----------|------|------|------|----------|----------|
| A | MySQL | localhost | 3306 | wordpress | wordpress | wordpress_test |
| B | PostgreSQL | localhost | 5432 | postgres | postgres | sql_tuning |
| B | PostgreSQL (pooled) | localhost | 6432 | postgres | postgres | sql_tuning |
| C | Azure SQL | *.database.windows.net | 1433 | (env var) | (env var) | research_analytics |

### 3. Index Naming Convention

Follow the pattern: `idx_[table_name]_[column1]_[column2]`

```sql
-- Good:
ALTER TABLE wp_postmeta ADD INDEX idx_wp_postmeta_post_id_meta_key (post_id, meta_key);

-- Not used here:
ALTER TABLE wp_postmeta ADD INDEX idx1 (post_id, meta_key);  -- ✗ avoid generic names
```

### 4. Workflow for Adding New Exercises

1. Create new directory: `exercises/day{N}_{topic}/`
2. Include `README.md` with:
   - **Problem**: What's slow? Why?
   - **Baseline**: Starting query with expected performance
   - **Learning Goals**: What techniques to apply?
   - **Success Criteria**: What improvement target?
3. Include `setup.sql` (idempotent schema/data loading)
4. Include `solution.sql` (reference implementation with comments)
5. Create empty `results.txt` for students to fill in

### 5. SQL Style for This Project

- **Idempotency**: Use `DROP TABLE IF EXISTS` and `IF NOT EXISTS` everywhere
- **Comments**: Explain *why* an optimization helps (e.g., "compound index enables index seek on post_id filter")
- **Metrics**: All optimization comments should reference expected improvement (e.g., "# Expected: 5ms, 50 rows examined")
- **No string concatenation**: Use parameterized queries if building dynamic SQL

### 6. Azure Credentials Handling

**Never commit connection strings.** Instead:

```bash
# Set environment variables before running scripts
export AZURE_SQL_SERVER="your-server.database.windows.net"
export AZURE_SQL_USER="sqladmin"
export AZURE_SQL_PASSWORD="your-password"

# Then use in scripts:
sqlcmd -S $AZURE_SQL_SERVER -U $AZURE_SQL_USER -P $AZURE_SQL_PASSWORD -d research_analytics
```

Store local credentials in `.claude/settings.local.json` (gitignored):
```json
{
  "env": {
    "AZURE_SQL_SERVER": "your-server.database.windows.net",
    "AZURE_SQL_USER": "sqladmin",
    "AZURE_SQL_PASSWORD": "your-password"
  }
}
```

### 7. Interview Context (Important)

This is interview prep. When modifying exercises or creating new content, remember the target:

- **Role**: Software Engineer supporting 29K WordPress sites on shared MySQL infrastructure
- **Problem domain**: Query optimization under resource constraints
- **Expected answer**: 2-minute story with specific metrics (250ms → 5ms, 50x improvement)
- **Real-world equivalent**: One slow query affects 29K sites' users simultaneously

All exercises should reinforce this context.

## Special Considerations

### Docker for Local Testing

- Containers persist data in volumes (`pgdata`, `mysqldata`) across restarts
- Use `make clean` to stop but preserve data
- Use `make clean-volumes` to fully reset (deletes all data)
- Initialization scripts run automatically on first startup

### Common Development Tasks

**Adding a new optimization technique to an exercise:**
1. Add the optimization to `scripts/optimize_[path]_[topic].sql`
2. Add a new exercise file in `exercises/day*/` if needed
3. Document expected improvement metrics
4. Test with baseline → optimize → verify cycle

**Debugging a slow query:**
1. Check `EXPLAIN ANALYZE` output
2. Look for "Seq Scan" (PostgreSQL) or "table scan" (MySQL)
3. Check if an index exists for the filter columns
4. Verify compound index column order matches filter predicates

**Validating optimization scripts:**
```bash
# PostgreSQL
docker compose exec postgres psql -U postgres -d sql_tuning -f scripts/optimize_ml_pipeline.sql

# MySQL
docker compose exec mysql mysql -u wordpress -p wordpress_test < scripts/optimize_wordpress.sql
```

## References

- **CLAUDE.md**: Claude Code settings and security guidance
- **README.md**: Full project overview and learning plan
- **QUICKSTART.md**: 10-minute setup guide for each path
- **docs/detailed-learning-guide.md**: Technical deep dives for each path
- **docs/interview-talking-points.md**: 30-second interview stories and Q&A
- **docs/quick-reference.md**: SQL syntax reference
- **Makefile**: All automation commands
- **docker-compose.yml**: Service definitions and port mappings

---

**Last Updated**: April 7, 2026  
**Project Target**: Interview preparation (April 11, 2026)  
**Duration**: 3-day intensive curriculum


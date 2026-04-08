# SQL Tuning Playground: Interview Preparation for Shared Hosting Operations

> Hands-on SQL optimization learning for a **Software Engineer role supporting ~29K WordPress sites + research infrastructure**

**Interview Date**: Friday, April 11, 2026  
**Preparation Duration**: 3 days (Monday–Wednesday)  
**Learn By Doing**: Real databases, real queries, real optimization techniques

---

## 🎯 What You'll Learn

This project teaches practical SQL tuning across **three database systems** and **three real-world scenarios**:

| Path | Database | Scenario | Improvement | Time |
|------|----------|----------|-------------|------|
| **A (Primary)** | MySQL | WordPress sites (29K user-facing) | 250ms → 5ms (50x) | 2-3 hrs |
| **B (Secondary)** | PostgreSQL | ML feature generation | 4 hours → 10 sec (1440x) | 2-3 hrs |
| **C (Optional)** | Azure SQL | ETL analytics pipelines | 6 hours → 3 min (120x) | 2-3 hrs |

All three paths teach the same core skill: **diagnosing slow queries and fixing them**. Different databases, different optimization techniques, same mindset.

---

## 🚀 Quick Start (10 Minutes)

### Option 1: Local Docker (Recommended for Paths A & B)

#### Common Steps (Applies to All Paths)

**Step 1: Start All Containers** (2 minutes)

```bash
# Start PostgreSQL (Port 5432), MariaDB (Port 3306), and PgBouncer (Port 6432)
make setup-local

# Verify all containers are healthy
make docker-status
```

**Step 2: Load Local Exercise Data** (2 minutes)

```bash
# Loads all local exercise data:
# - WordPress schema + test data into MariaDB (Path A)
# - ML schema + test data into PostgreSQL (Path B)
make load-all
```

---

#### MariaDB Section (Path A - WordPress Optimization)

**Objective**: Fix a slow WordPress query from 250ms → 5ms (50x faster)

**Step 3: Connect to MariaDB**

```bash
make test-mysql
# Or manually: docker compose exec mysql mariadb -u wordpress -pwordpress wordpress_test
```

**Step 4: Baseline Performance (BEFORE optimization)**

```sql
-- How slow is the query NOW? (EXPLAIN ANALYZE executes the query and returns actual timings)
EXPLAIN ANALYZE SELECT meta_id, post_id, meta_key, meta_value
FROM wp_postmeta WHERE post_id = 1;

-- Expected:
-- type: ALL (full table scan - slow!)
-- rows: ~5000 (estimated rows scanned)
-- actual time: ~250ms
```

**Step 5: Add the Magic Index**

```sql
ALTER TABLE wp_postmeta ADD INDEX idx_post_id_meta_key (post_id, meta_key(191));
```

**Step 6: Verify Optimization (AFTER index)**

```sql
EXPLAIN ANALYZE SELECT meta_id, post_id, meta_key, meta_value
FROM wp_postmeta WHERE post_id = 1;

-- Expected:
-- type: ref (index seek - fast!)
-- rows: ~50 (index seek on post_id)
-- actual time: ~5ms ✨ (50x faster!)
```

**Next**: Read `exercises/day1_wordpress_audit/README.md` for full Day 1 curriculum

---

#### PostgreSQL Section (Path B - Machine Learning)

**Objective**: Learn PostgreSQL optimization for ML feature generation pipelines

**Step 3: Load ML Schema & Test Data** (Already done if you ran `make load-all` in Step 2)

```bash
# `make load-all` (Step 2) already loads the ML schema + data into PostgreSQL.
# To reload manually (e.g., after make clean-volumes), stream the host files into psql:
docker compose exec -T postgres psql -U postgres -d sql_tuning < scripts/setup_ml_schema.sql
docker compose exec -T postgres psql -U postgres -d sql_tuning < scripts/setup_ml_test_data.sql
```

**Step 4: Connect to PostgreSQL**

```bash
make test-postgres
# Or manually: docker compose exec postgres psql -U postgres -d sql_tuning
```

**Step 5: Explore ML Feature Generation Tables**

```sql
-- Check the ML tables
\dt  -- List all tables (you should see student_enrollments, course_assignments, final_grades, etc.)

-- Count records
SELECT COUNT(*) as total_students FROM student_enrollments;
SELECT COUNT(*) as total_assignments FROM course_assignments;
SELECT COUNT(*) as total_grades FROM final_grades;
```

**Step 6: Run a Baseline ML Query** (Feature generation - BEFORE optimization)

```sql
-- This is a typical feature generation query for ML training
-- It is intentionally unoptimized because it computes aggregates at query time
-- across large tables instead of reading from a precomputed feature store
EXPLAIN ANALYZE
SELECT
  s.student_id,
  COALESCE(a.assignments_completed, 0) AS assignments_completed,
  a.avg_assignment_score,
  COALESCE(e.courses_enrolled, 0) AS courses_enrolled
FROM (
  SELECT DISTINCT student_id
  FROM student_enrollments
) s
LEFT JOIN (
  SELECT
    student_id,
    COUNT(DISTINCT assignment_id) AS assignments_completed,
    AVG(score) AS avg_assignment_score
  FROM course_assignments
  GROUP BY student_id
) a ON s.student_id = a.student_id
LEFT JOIN (
  SELECT
    student_id,
    COUNT(DISTINCT course_id) AS courses_enrolled
  FROM student_enrollments
  GROUP BY student_id
) e ON s.student_id = e.student_id;

-- Expected: Slower baseline due to repeated aggregation over large tables;
-- later optimization should use pre-aggregation/materialized views, not "missing join indexes"
```

**Next**: Path B exercise files are not yet included in this repo. For now, use the PostgreSQL baseline above to practice feature-generation analysis and return to the dedicated ML exercise README when it is added in a future update.

---

#### ✅ Success!

You've added the MariaDB/MySQL WordPress query optimization and inspected the execution plan, and you've established a PostgreSQL baseline for Path B. To verify the full **50x** improvement target, run before/after timing as part of the exercises. Choose your path and continue!

### Option 2: Azure SQL (For Path C - ETL exercises)

```bash
# 1. Create Azure SQL Database
bash scripts/setup_azure_sql.sh

# 2. Load ETL schema and data
sqlcmd -S your-server.database.windows.net -U sqladmin -P 'YourPassword' \
  -d research_analytics -i scripts/setup_etl_schema.sql
sqlcmd -S your-server.database.windows.net -U sqladmin -P 'YourPassword' \
  -d research_analytics -i scripts/setup_etl_test_data.sql

# 3. Connect and run exercises
sqlcmd -S your-server.database.windows.net -U sqladmin -P 'YourPassword' \
  -d research_analytics
```

---

## 📚 Project Structure

```
sql-tuning-playground/
├── README.md                    # ← You are here
├── QUICKSTART.md               # Quick setup guide for each path
├── CLAUDE.md                   # Development guide (for Claude Code)
├── UPDATES_NEEDED.md           # Track completed & remaining work
│
├── docs/
│   ├── detailed-learning-guide.md       # 3-day curriculum (detailed explanations)
│   ├── interview-talking-points.md      # How to talk about this in interviews
│   ├── quick-reference.md               # SQL syntax & commands reference
│   └── troubleshooting_guide.md         # Diagnostic guide (Day 3 deliverable)
│
├── scripts/
│   ├── setup_wordpress_schema.sql       # WordPress tables (9 tables, Path A)
│   ├── setup_test_data.sql              # WordPress test data (100 posts, 5K metadata)
│   ├── optimize_wordpress.sql           # Reference optimization (20 techniques)
│   │
│   ├── setup_ml_schema.sql              # ML tables (PostgreSQL, Path B)
│   ├── setup_ml_test_data.sql           # ML test data (10K students, 100K enrollments)
│   ├── optimize_ml_pipeline.sql         # ML optimizations (feature store pattern)
│   │
│   ├── setup_etl_schema.sql             # ETL tables (Azure SQL, Path C)
│   ├── setup_etl_test_data.sql          # ETL test data (10M posts, 50M metadata)
│   ├── optimize_etl_pipeline.sql        # ETL optimizations (indexes + partitioning)
│   │
│   └── setup_azure_sql.sh               # Azure cloud setup automation
│
├── exercises/
│   ├── day1_wordpress_audit/            # Path A exercises (WordPress optimization)
│   ├── day2_ml_optimization/            # Path B exercises (ML feature generation)
│   ├── day3_etl_analytics/              # Path C exercises (ETL pipelines)
│   └── day3_incident_simulations/       # All paths: Rapid diagnosis scenarios
│
├── docker-compose.yml           # Local database services (PostgreSQL, MySQL, PgBouncer)
├── Makefile                     # Automation targets (setup, load, test, optimize)
└── config/
    └── my.cnf                   # MySQL 8.0 configuration (learning environment tuning)
```

---

## 🎓 Three Learning Paths

### Path A: MySQL + WordPress (PRIMARY ⭐⭐⭐⭐⭐)

**Role Context**: You support 29K WordPress sites on a shared MySQL server. One slow query locks all 29K sites' users.

**The Challenge**: A WordPress query takes 250ms and uses 80% CPU. Fix it in under 5 minutes.

**What You'll Learn**:
- WordPress "silent killers" (unindexed `wp_postmeta`, bloated `wp_options`, orphaned data)
- Index strategy (compound indexes, covering queries)
- Performance diagnostics (EXPLAIN, slow query log)
- Batch optimization scripts (automate cleanup across all sites)

**Key Metrics**:
- 250ms → 5ms (50x faster)
- 5000 rows examined → 50 rows examined
- 8s page load → 2s page load
- 80% CPU → 20% CPU

**Time**: 2-3 hours  
**Database**: MySQL 8.0 (Docker)  
**Start Here**: `exercises/day1_wordpress_audit/README.md`

---

### Path B: PostgreSQL + Machine Learning (SECONDARY ⭐⭐⭐⭐)

**Role Context**: You support researchers training ML models on student success prediction. Feature generation takes 4 hours per training run. Researchers need 50+ model iterations per day.

**The Challenge**: Optimize feature generation from 4 hours to 10 seconds, reducing cost 99%.

**What You'll Learn**:
- Feature store pattern (pre-compute features, reuse for training)
- Materialized views (pre-join tables for fast queries)
- Incremental updates (only process new/changed data)
- Cost optimization (reduce cloud spending dramatically)

**Key Metrics**:
- 4 hours → 10 seconds (1440x faster)
- $4 per run → $0.01 per run (99% cost reduction)
- 1 model/day → 50+ models/day (researcher productivity)

**Time**: 2-3 hours  
**Database**: PostgreSQL 17 (Docker)  
**Start Here**: `exercises/day2_ml_optimization/README.md`

---

### Path C: Azure SQL + ETL/Analytics (OPTIONAL ⭐⭐⭐)

**Role Context**: You run ETL pipelines that extract research data from 29K WordPress sites nightly. The batch window is 8 hours (10 PM–6 AM). If the ETL doesn't finish, the dashboard is stale.

**The Challenge**: Optimize the ETL query from 6 hours to 3 minutes, completing within the batch window.

**What You'll Learn**:
- Strategic indexing for analytics queries
- Incremental loading (only process new data, combine with historical aggregates)
- Partition elimination (query only the months you need)
- OLAP vs OLTP (batch queries vs real-time queries)

**Key Metrics**:
- 6 hours → 3 minutes (120x faster)
- 10GB scanned → 1GB scanned (90% less I/O)
- Batch window: 75% → <1% utilization

**Time**: 2-3 hours  
**Database**: Azure SQL (Cloud)  
**Start Here**: `exercises/day3_etl_analytics/README.md`

---

## 📅 3-Day Learning Plan

### Monday: Day 1 - WordPress Optimization (Path A)

**Duration**: 2-3 hours

1. **Foundation** (30 min)
   - Read: `docs/detailed-learning-guide.md` → PATH A section
   - Understand: Silent killers in WordPress

2. **Hands-On** (90 min)
   - Run: `exercises/day1_wordpress_audit/README.md`
   - Measure: Baseline query performance (250ms)
   - Optimize: Add compound index
   - Verify: New performance (5ms)
   - Document: Results in `exercises/day1_wordpress_audit/results.txt`

3. **Interview Prep** (30 min)
   - Read: `docs/interview-talking-points.md` → Path A story
   - Practice: Tell the story out loud (2 minutes)

**Deliverable**: Before/after metrics showing 50x improvement

---

### Tuesday: Day 2 - Infrastructure & Advanced Topics (Path B and/or C)

**Duration**: 2-3 hours

**Option 1: Path B (ML - Recommended if time-constrained)**

1. **Foundation** (30 min)
   - Read: PATH B section in `docs/detailed-learning-guide.md`
   - Understand: Feature store pattern, materialized views

2. **Hands-On** (90 min)
   - Run: `exercises/day2_ml_optimization/README.md`
   - Implement: Feature store tables
   - Create: Materialized view for training
   - Measure: 1440x improvement (4h → 10s)
   - Document: Cost reduction ($4 → $0.01)

3. **Interview Prep** (30 min)
   - Practice: Path B story (researcher productivity angle)

**Option 2: Path C (ETL)**

1. **Foundation** (30 min)
   - Read: PATH C section in `docs/detailed-learning-guide.md`
   - Understand: Incremental loads, partitioning

2. **Hands-On** (90 min)
   - Run: `exercises/day3_etl_analytics/README.md`
   - Apply: Strategic indexes (2-3x speedup)
   - Implement: Incremental loading (4-6x speedup)
   - Configure: Partition filtering (10x speedup)
   - Measure: 120x total improvement (6h → 3m)
   - Document: Batch window reduction (75% → <1%)

3. **Interview Prep** (30 min)
   - Practice: Path C story (infrastructure reliability angle)

**Deliverable**: Optimization metrics showing significant improvement

---

### Wednesday: Day 3 - Incident Response & Interview Simulation

**Duration**: 2-3 hours

1. **Review All Paths** (30 min)
   - Read: All three paths in `docs/detailed-learning-guide.md`
   - Understand: When to use each optimization technique

2. **Incident Simulations** (60 min)
   - Run: `exercises/day3_incident_simulations/README.md`
   - Practice: Rapid diagnosis (5-minute scenarios)
   - Document: Troubleshooting approach for each

3. **Interview Simulation** (60 min)
   - Practice: Tell all three stories (5 min each)
   - Answer: Questions from `docs/interview-talking-points.md`
   - Refine: Talking points based on feedback

**Deliverable**: Completed `docs/troubleshooting_guide.md` (postmortem template for interviews)

---

### Thursday: Review & Final Prep

- [ ] Review all three paths
- [ ] Practice interview answers
- [ ] Memorize key metrics from `docs/quick-reference.md`
- [ ] Prepare questions to ask about the role

### Friday: Interview! 🎉

---

## 💡 Key Interview Stories (30-Second Versions)

### Path A: WordPress
> "I optimized an unindexed `wp_postmeta` query affecting 29K WordPress sites. Added a compound index on `(post_id, meta_key)` reducing query time from 250ms to 5ms (50x faster) and CPU from 80% to 20%. Applied the same fix across all 29K sites, scaling the impact globally."

### Path B: Machine Learning
> "I optimized a feature generation pipeline for student success prediction. Implemented a feature store pattern with pre-computed tables. Result: 4-hour training runs → 10 seconds, $4 cost → $0.01, enabling researchers to test 50+ model ideas per day instead of 1."

### Path C: ETL/Analytics
> "I optimized a research ETL pipeline extracting data from 29K WordPress sites. Added strategic indexes (2-3x speedup), incremental loading with materialized views (4-6x), and partition filtering (10x). Result: 6-hour pipeline → 3 minutes, completing within the 8-hour batch window, enabling fresh dashboards at 6 AM."

---

## 🛠️ Useful Commands

```bash
# Setup & Maintenance
make setup-local          # Start Docker containers
make load-all            # Load all schemas and test data
make docker-status       # Check container health
make docker-clean        # Stop and remove containers

# Testing & Optimization
make test-mysql          # Connect to MySQL (WordPress)
make test-postgres       # Connect to PostgreSQL (ML)
make test-pgbouncer      # Test connection pooling
make test-perf           # Run performance tests

# Learning
make help                # Show all available commands
cat docs/detailed-learning-guide.md          # Full curriculum
cat docs/interview-talking-points.md         # Interview prep
cat docs/quick-reference.md                  # SQL syntax

# Cleanup
make docker-logs         # View container logs
make docker-down         # Stop all containers
docker compose down -v   # Stop containers and delete volumes (fresh start)
```

---

## ⚙️ Configuration

### MySQL Configuration (`config/my.cnf`)

The `config/my.cnf` file contains MySQL tuning parameters for the learning environment:

```ini
innodb_buffer_pool_size = 512M  # InnoDB memory (critical for performance)
max_connections = 200            # Max concurrent connections
slow_query_log = 1               # Enable slow query logging
long_query_time = 1              # Log queries taking >1 second
```

**Important Notes**:
- These are **learning environment settings**, not production-ready
- The file is auto-loaded into the Docker container
- To modify: Edit `config/my.cnf`, then restart containers with `docker compose down && docker compose up -d`
- For production, increase `innodb_buffer_pool_size` to ~80% of available RAM

---

## 📊 Database Connectivity

### MySQL (Path A - WordPress)

**Docker**:
```bash
make test-mysql
# OR
docker compose exec mysql mysql -u wordpress -p wordpress_test

# Password: wordpress
```

**Connection Details**:
- Host: `localhost` (Docker)
- Port: `3306`
- User: `wordpress`
- Password: `wordpress`
- Database: `wordpress_test`

### PostgreSQL (Path B - ML)

**Docker**:
```bash
make test-postgres
# OR
docker compose exec postgres psql -U postgres -d sql_tuning

# Password: postgres
```

**Connection Details**:
- Host: `localhost` (Docker)
- Port: `5432`
- User: `postgres`
- Password: `postgres`
- Database: `sql_tuning`

### Azure SQL (Path C - ETL)

After running `bash scripts/setup_azure_sql.sh`:

```bash
sqlcmd -S your-server.database.windows.net \
  -U sqladmin \
  -P 'YourPassword' \
  -d research_analytics
```

Save credentials in `.claude/settings.local.json`:
```json
{
  "env": {
    "AZURE_SQL_SERVER": "your-server.database.windows.net",
    "AZURE_SQL_USER": "sqladmin",
    "AZURE_SQL_PASSWORD": "your-password"
  }
}
```

---

## 📖 Reading Guide

**If you have limited time**:
1. Read: `QUICKSTART.md` (10 min)
2. Run: Path A exercises (2 hours)
3. Read: Interview talking points (30 min)
4. Practice: 3 interview stories (1 hour)

**If you have full 3 days**:
1. Day 1: `docs/detailed-learning-guide.md` → PATH A + exercises
2. Day 2: PATH B or PATH C + exercises
3. Day 3: All paths + incident simulations + interview practice

**For reference**:
- Technical details: `docs/detailed-learning-guide.md`
- Interview prep: `docs/interview-talking-points.md`
- SQL syntax: `docs/quick-reference.md`
- Diagnostics: `docs/troubleshooting_guide.md`

---

## 🎯 Success Criteria

By the end of this project, you should be able to:

- [ ] **PATH A**: Diagnose and fix WordPress queries in 5 minutes
- [ ] **PATH B** (optional): Explain feature store pattern and 1440x improvement
- [ ] **PATH C** (optional): Describe ETL optimization from 6 hours to 3 minutes
- [ ] **All paths**: Tell 2-minute interview stories with specific metrics
- [ ] **All paths**: Explain when to use indexes vs materialized views vs partitioning
- [ ] **All paths**: Run incident simulations and produce postmortems

---

## 🚀 Next Steps

1. **Clone or download** this project
2. **Run**: `make setup-local` (starts Docker)
3. **Read**: `QUICKSTART.md` (choose Path A, B, or C)
4. **Start**: `exercises/day1_wordpress_audit/README.md` (Path A)
5. **Practice**: Interview stories from `docs/interview-talking-points.md`
6. **Succeed**: Interview on Friday! 🎉

---

## ❓ Frequently Asked Questions

**Q: Which path should I focus on?**  
A: **Path A (WordPress) is primary** — that's your main responsibility in the role. Path B and C show you understand the full infrastructure. If time-constrained, do A → B. If you have time, do all three.

**Q: Can I do this without Docker?**  
A: Yes! Use Azure SQL for Path C (cloud-based). For Paths A & B, you need PostgreSQL and MySQL. Docker is fastest.

**Q: How long is the interview?**  
A: You'll have ~1 hour. Plan for: 10 min small talk, 20 min technical deep dive (they'll pick a path), 20 min questions, 10 min logistics.

**Q: What if I get stuck?**  
A: Check `docs/troubleshooting_guide.md`, review the baseline queries in `scripts/`, or read the detailed explanations in `docs/detailed-learning-guide.md`.

**Q: Can I practice with larger datasets?**  
A: Yes! All scripts are idempotent. Just modify the batch sizes in `scripts/setup_*_test_data.sql` and re-run.

---

## 📝 License & Attribution

This project was created for interview preparation at a university supporting ~29K WordPress sites. All examples are realistic but anonymized.

**Created**: April 2026  
**Interview Date**: April 11, 2026  
**Duration**: 3-day intensive preparation

---

## 🤝 Contributing

These exercises are constantly improved. If you:
- Find a typo → Fix it
- Have a better explanation → Submit it
- Discover a new technique → Add it to the optimization scripts
- Build on this project → Share it!

---

**Good luck! You've got this.** 🚀

For questions about setup, start with `QUICKSTART.md`.  
For technical depth, read `docs/detailed-learning-guide.md`.  
For interview practice, use `docs/interview-talking-points.md`.

**Start with PATH A exercises. Get comfortable with the basics. Then expand to Paths B and C.**

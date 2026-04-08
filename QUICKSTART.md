# Quick Start Guide: Get Learning in 10 Minutes

Choose your path below based on your preference and timeline.

---

## 🚀 PATH A: MySQL + WordPress (Primary Learning - Local Docker)

**Recommended**: Start here. This is your main responsibility (29K WordPress sites).

**Database**: MySQL 8.0 (in Docker)  
**Time**: 10 minutes setup + 2 hours learning

### Step 1: Start Docker Environment (3 minutes)

```bash
# Start MySQL, PostgreSQL, PgBouncer
make setup-local

# Or manually:
docker compose up -d
```

**Verify containers are running**:
```bash
make docker-status
# Should show 3 healthy containers
```

### Step 2: Load WordPress Schema & Test Data (2 minutes)

```bash
# Load schema and test data
make load-all

# Or manually:
docker compose exec mysql mysql -u wordpress -p wordpress_test \
  -f scripts/setup_wordpress_schema.sql
docker compose exec mysql mysql -u wordpress -p wordpress_test \
  -f scripts/setup_test_data.sql
```

### Step 3: Verify Data Loaded

```bash
# Check MySQL WordPress tables
docker compose exec mysql mysql -u wordpress -p wordpress_test \
  -e "SELECT COUNT(*) as total_posts FROM wp_posts;"
# Should return: 100
```

### Step 4: Start Day 1 Exercise

```bash
# Read the Day 1 exercise
cat exercises/day1_wordpress_audit/README.md

# Connect to MySQL for WordPress exercises
make test-mysql
```

### Next Time

Just run `docker compose up -d` — data is still there!

---

## 🐳 PATH B: PostgreSQL + Machine Learning (Secondary Learning - Local Docker)

**Best for**: Understanding ML pipeline optimization and feature generation.

**Database**: PostgreSQL 17 (in Docker)  
**Time**: 10 minutes setup + 2-3 hours learning

### Step 1: Start Docker Environment (Already running from PATH A!)

```bash
# If you already did PATH A, PostgreSQL is already running
# If not, start now:
make setup-local
docker compose up -d
```

### Step 2: Load ML Schema & Test Data (2 minutes)

```bash
# Load ML schema and test data
docker compose exec postgres psql -U postgres -d sql_tuning \
  -f scripts/setup_ml_schema.sql
docker compose exec postgres psql -U postgres -d sql_tuning \
  -f scripts/setup_ml_test_data.sql
```

### Step 3: Verify Data Loaded

```bash
# Check PostgreSQL ML tables
docker compose exec postgres psql -U postgres -d sql_tuning \
  -c "SELECT COUNT(*) as total_students FROM final_grades;"
# Should return: 10000
```

### Step 4: Start Day 2 Exercise

```bash
# Read the Day 2 ML exercise
cat exercises/day2_ml_optimization/README.md

# Connect to PostgreSQL for ML exercises
make test-postgres
```

---

## ☁️ PATH C: Azure SQL + ETL/Analytics (Optional - Cloud Setup)

**Best for**: Understanding cloud-based ETL and analytics pipelines.

**Database**: Azure SQL Database  
**Time**: 10 minutes setup + 2-3 hours learning

### Step 1: Create Azure SQL Database (5 minutes)

```bash
# Run the setup script
bash scripts/setup_azure_sql.sh

# Follow the prompts. You'll get:
# - Server name
# - Database name  
# - Connection details
```

**Save the connection details** somewhere safe (in `.claude/settings.local.json` is best).

### Step 2: Load ETL Schema (2 minutes)

```bash
# Replace with your Azure details
sqlcmd -S your-server.database.windows.net \
  -U sqladmin \
  -P 'YourPassword' \
  -d research_analytics \
  -i scripts/setup_etl_schema.sql
```

### Step 3: Load Test Data (3 minutes)

```bash
sqlcmd -S your-server.database.windows.net \
  -U sqladmin \
  -P 'YourPassword' \
  -d research_analytics \
  -i scripts/setup_etl_test_data.sql
```

### Step 4: Start Day 3 Exercise

```bash
# Read the Day 3 ETL exercise
cat exercises/day3_etl_analytics/README.md

# Connect to Azure SQL
sqlcmd -S your-server.database.windows.net \
  -U sqladmin \
  -P 'YourPassword' \
  -d research_analytics
```

---

## ✅ Verify Everything Works

### Test Query 1: Slow Query (BEFORE optimization)

**PostgreSQL**:
```bash
docker compose exec postgres psql -U postgres -d sql_tuning -c \
  "EXPLAIN ANALYZE SELECT meta_id, post_id, meta_key, meta_value 
   FROM wp_postmeta WHERE post_id = 1;"
```

**MySQL/MariaDB**:
```bash
docker compose exec mysql mariadb -u wordpress -pwordpress wordpress_test -e \
  "EXPLAIN FORMAT=JSON SELECT meta_id, post_id, meta_key, meta_value 
   FROM wp_postmeta WHERE post_id = 1;"
```

**Expected output**:
- Execution Time: ~200-250ms
- Rows examined: ~5000
- Result rows: ~50

### Test Query 2: After Adding Index

**PostgreSQL**:
```bash
docker compose exec postgres psql -U postgres -d sql_tuning -c \
  "CREATE INDEX idx_post_id_meta_key ON wp_postmeta (post_id, meta_key);"

docker compose exec postgres psql -U postgres -d sql_tuning -c \
  "EXPLAIN ANALYZE SELECT meta_id, post_id, meta_key, meta_value 
   FROM wp_postmeta WHERE post_id = 1;"
```

**MySQL/MariaDB**:
```bash
docker compose exec mysql mariadb -u wordpress -pwordpress wordpress_test -e \
  "ALTER TABLE wp_postmeta ADD INDEX idx_post_id_meta_key (post_id, meta_key);"

docker compose exec mysql mariadb -u wordpress -pwordpress wordpress_test -e \
  "EXPLAIN ANALYZE SELECT meta_id, post_id, meta_key, meta_value 
   FROM wp_postmeta WHERE post_id = 1;"
```

**Expected output**:
- Execution Time: ~5ms (50x faster!)
- Rows examined: ~50
- Result rows: ~50

---

## 📚 What to Do Next

### Choose Your Day

- **Monday**: Run Exercise 1.1 (wp_postmeta index)
- **Tuesday**: Run Exercise 2.1 (connection pooling)
- **Wednesday**: Run Exercise 3.1 (incident simulation)

### Quick Navigation

```bash
# Read the learning guide
cat docs/detailed-learning-guide.md

# Read interview talking points
cat docs/interview-talking-points.md

# Reference SQL commands
cat docs/quick-reference.md

# See all exercises
cat exercises/EXERCISES_INDEX.md
```

### Helpful Makefile Commands

```bash
make help              # Show all make commands
make load-schema       # Load WordPress schema
make load-data         # Load test data
make optimize          # Run optimization script
make test-perf         # Run performance tests
make docker-logs       # View container logs
make docker-status     # Check containers are running
```

---

## 🚨 Troubleshooting

### Docker: "Container not found"

```bash
# Check if containers are running
docker compose ps

# Start them if needed
docker compose up -d

# Check logs
docker compose logs postgres
```

### Azure: "Connection refused"

```bash
# Verify firewall rule allows your IP
# In Azure Portal: SQL Server → Networking → Public Access

# Test connection
sqlcmd -S your-server.database.windows.net -U sqladmin -P 'YourPassword' -Q "SELECT 1;"
```

### PostgreSQL: "database does not exist"

```bash
# List databases
docker compose exec postgres psql -U postgres -l

# Create if missing
docker compose exec postgres createdb -U postgres sql_tuning
```

### MySQL: "Can't connect"

```bash
# Check if MySQL is healthy
docker compose ps mysql

# View logs
docker compose logs mysql

# Wait a moment and try again (MySQL takes longer to start)
sleep 30
docker compose exec mysql mysql -u wordpress -p -e "SELECT 1;"
```

---

## 📊 System Requirements

### Azure Path
- ✅ Internet connection
- ✅ Azure CLI installed
- ✅ Azure free account (or subscription)
- ✅ ~5 minutes setup time

### Docker Path
- ✅ Docker installed (with rootless Docker enabled on Debian)
- ✅ 2GB free disk space
- ✅ No internet needed (images may already be cached)
- ✅ ~10 minutes setup time

---

## 🎯 Learning Path (Next 3 Days)

### Monday: Day 1 - WordPress Optimization (PATH A - MySQL)
- Time: 2-3 hours
- Database: MySQL 8.0 (Docker)
- Exercise: `exercises/day1_wordpress_audit/`
- Key learning: Index optimization, wp_postmeta tuning, before/after metrics
- Deliverable: Performance test results (250ms → 5ms, 50x improvement)

### Tuesday: Day 2 - Infrastructure & ML/ETL (PATH B + PATH C)
- Time: 2-3 hours (choose one or do both)
- **PATH B (ML)**: PostgreSQL feature store optimization (4h → 10s, 1440x)
- **PATH C (ETL)**: Azure SQL pipeline optimization (6h → 3m, 120x)
- Exercises: `exercises/day2_ml_optimization/` or `exercises/day3_etl_analytics/`
- Key learning: Feature stores, materialized views, partitioning, incremental loads
- Deliverable: Optimization metrics documented

### Wednesday: Day 3 - Interview Prep & Incident Response
- Time: 2-3 hours
- Review all three paths (A, B, C)
- Practice interview answers from `docs/interview-talking-points.md`
- Run incident simulation exercises
- Deliverable: Postmortem template for interviews

### Thursday: Review & Interview Prep
- Review all 3 days
- Practice interview answers from `docs/interview-talking-points.md`
- Memorize metrics from `docs/quick-reference.md`

### Friday: Interview! 🎉

---

## 💾 Save Your Credentials

### For Azure SQL

Create `.claude/settings.local.json`:

```json
{
  "env": {
    "AZURE_SQL_SERVER": "your-server.database.windows.net",
    "AZURE_SQL_USER": "sqladmin",
    "AZURE_SQL_PASSWORD": "your-password"
  }
}
```

### For Docker/Local

Set environment variables:

```bash
# Add to ~/.bashrc or ~/.zshrc
export PGUSER=postgres
export PGDATABASE=sql_tuning
export MYSQL_USER=wordpress
export MYSQL_PASSWORD=wordpress
```

---

## 🎬 Example: Running Your First Exercise

```bash
# 1. Connect to database
make test-postgres
# OR for MySQL:
make test-mysql

# 2. Run baseline query (slow)
EXPLAIN ANALYZE SELECT meta_id, post_id, meta_key, meta_value 
FROM wp_postmeta WHERE post_id = 1;

# Expected: ~250ms, 5000 rows examined

# 3. Add index (the optimization)
ALTER TABLE wp_postmeta ADD INDEX idx_post_id_meta_key 
  (post_id, meta_key(191));

# 4. Run same query again (fast!)
EXPLAIN ANALYZE SELECT meta_id, post_id, meta_key, meta_value 
FROM wp_postmeta WHERE post_id = 1;

# Expected: ~5ms, 50 rows examined

# 5. Calculate improvement
# 250ms → 5ms = 50x faster! ✨

# 6. Document in results.txt
```

---

## 🎓 You're Ready!

You now have:
- ✅ A working database environment (Azure or Docker)
- ✅ WordPress test data with real performance issues
- ✅ Exercises to practice real-world SQL optimization
- ✅ Learning materials (detailed guide, talking points, quick reference)
- ✅ Interview preparation scripts

**Start with Exercise 1.1 and work through the 3-day plan.**

Good luck! 🚀

---

## 📞 Quick Help

```bash
# If stuck, check:
make help              # All available commands
cat docs/quick-reference.md  # SQL command syntax
cat docs/detailed-learning-guide.md  # Theory & explanations
cat docs/interview-talking-points.md  # How to talk about this

# To debug:
make docker-status     # Are containers running?
make docker-logs       # What's in the logs?
make test-perf         # Does a test query work?
```

---

**Next**: Read `exercises/day1_wordpress_audit/README.md` to start learning! 📚

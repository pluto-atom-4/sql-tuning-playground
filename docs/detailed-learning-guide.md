# Detailed SQL Tuning Learning Guide: Shared Hosting Edition (Enhanced)

**Duration**: 3 Days (Monday–Wednesday)  
**Interview**: Friday, 2026-04-11  
**Context**: Software Engineer role supporting ~29K shared hosting sites + infrastructure  
**Goal**: Hands-on competency in SQL optimization across MySQL (WordPress), PostgreSQL (ETL), and Azure SQL (Machine Learning)

---

## Table of Contents

1. [Learning Philosophy](#learning-philosophy)
2. [Choose Your Path](#choose-your-path)
3. [Day 1: Foundation & Database Specialization](#day-1-foundation--database-specialization)
4. [Day 2: Infrastructure & High Availability](#day-2-infrastructure--high-availability)
5. [Day 3: The "Friday Interview" Simulation](#day-3-the-friday-interview-simulation)
6. [Shared Hosting Constraints (Central Theme)](#shared-hosting-constraints-central-theme)
7. [Interview Prep & Talking Points](#interview-prep--talking-points)

---

## Learning Philosophy

### Why This Approach?

You're prepping for a **production operations role** at a university supporting:

1. **WordPress Tier (MySQL)**: 29K faculty/student-owned sites, user-facing, real-time performance critical
2. **ML Research Tier (PostgreSQL)**: Machine learning training pipelines, model feature generation, research workflows
3. **Analytics Tier (Azure SQL)**: ETL pipelines, research dashboards, reporting, batch workloads

The interview will test:

1. **Incident Response Mindset** — "A WordPress query is slow" vs. "An ETL pipeline is slow" (different solutions)
2. **Operational Thinking** — Scaling 29K sites vs. optimizing batch pipelines
3. **Full-Stack Database Skills** — OLTP (WordPress), OLAP (Analytics), ML (Feature Generation)
4. **Automation Instinct** — How to scale fixes across all three layers
5. **Stakeholder Communication** — Faculty, researchers, students have different expectations

### Non-Negotiables for This Role

- **MySQL/WordPress**: One slow query affects all 29K sites → must fix fast
- **PostgreSQL/ML**: Feature generation for model training → must optimize for iteration speed
- **Azure SQL/ETL**: Delayed pipeline = stale dashboards → must complete in window
- **You scale thinking** — A fix for 1 site/job must work for 29K/100
- **You measure everything** — Before/after metrics for all optimizations
- **You document playbooks** — Next on-call person must run without questions

---

## Choose Your Path

**Focus on MySQL + WordPress** (your primary responsibility). Understanding the other two paths will help you handle the full infrastructure.

### Path A: MySQL + WordPress (PRIMARY ⭐⭐⭐⭐⭐)
**Best for**: Shared hosting operations, user-facing performance  
**Time**: 2-3 hours  
**Scenario**: Fix slow wp_postmeta queries (250ms → 5ms)

### Path B: PostgreSQL + Machine Learning (SECONDARY ⭐⭐⭐⭐)
**Best for**: Understanding research infrastructure, ML training pipelines  
**Time**: 2-3 hours  
**Scenario**: Optimize ML feature generation (4 hours → 10 seconds, 99% cost reduction)

### Path C: Azure SQL + ETL/Analytics (OPTIONAL ⭐⭐⭐)
**Best for**: Understanding full stack, batch analytics pipelines  
**Time**: 2-3 hours  
**Scenario**: Optimize slow ETL query (6 hours → 3 minutes, 120x faster)

---

# Day 1: Foundation & Database Specialization

---

# PATH A: MySQL + WordPress Specialization (PRIMARY)

## 🎯 Learning Objective

Understand the "silent killers" in WordPress-heavy shared hosting. A single unoptimized query cascades across all 29K sites. Fixes are simple: add index, clean bloat, prevent runaway queries.

## 📊 The Scenario

**Context**: University with ~29K hosted WordPress sites  
- Faculty blogs, department websites, course portals, research projects
- Shared MySQL server with ~200 max concurrent connections
- One slow query locks all 29K sites' users
- Typical complaint: "Site is slow" with no technical context

**Challenge**: Diagnose and fix in under 5 minutes

---

## The "Silent Killers" in WordPress

### Killer 1: Unindexed wp_postmeta

```sql
-- WordPress fetches metadata constantly
SELECT meta_id, meta_key, meta_value 
FROM wp_postmeta 
WHERE post_id = 12345;

-- Without index: Scans all 5000 postmeta rows to find 50 that match
-- Time: 250ms
```

**At scale**: 1000 posts/site × 50 metadata = 50K rows → 29K sites × 50K = **1.45 billion entries**  
One slow query locks the entire postmeta table → all 29K sites' users timeout

### Killer 2: Bloated wp_options (Autoload)

```sql
-- WordPress loads ALL autoload options on EVERY page
SELECT option_name, option_value 
FROM wp_options 
WHERE autoload = 'yes';

-- Plugins (Yoast, ACF, WooCommerce) dump 100KB-1MB each
-- One site: 5MB+ per page load
-- 29K sites: Database I/O bottleneck
```

### Killer 3: Uncleaned wp_postmeta and wp_posts

- **Revisions**: 5-50 per post (deleted plugins leave orphaned entries)
- **Transients**: Expired caches never deleted
- **Old posts**: Archive never cleaned up
- Table grows MB → GB over months

---

## Hands-On: Fix wp_postmeta (Exercise 1.1)

### Step 1: Baseline Performance

**PostgreSQL**:
```sql
-- How slow is it BEFORE optimization?
EXPLAIN ANALYZE
SELECT meta_id, post_id, meta_key, meta_value
FROM wp_postmeta
WHERE post_id = 1;

-- Expected:
-- Seq Scan on wp_postmeta (full table scan)
-- Rows returned: 50
-- Planning time: ~0.1ms
-- Execution time: ~250ms
```

**MySQL/MariaDB**:
```sql
-- How slow is it BEFORE optimization?
EXPLAIN FORMAT=JSON
SELECT meta_id, post_id, meta_key, meta_value
FROM wp_postmeta
WHERE post_id = 1;

-- Expected:
-- Type: ALL (full table scan)
-- Rows examined: 5000
-- Rows returned: 50
-- Execution time: ~250ms
```

### Step 2: Add Index

```sql
-- Add the compound index (post_id, meta_key)
ALTER TABLE wp_postmeta ADD INDEX idx_post_id_meta_key 
  (post_id, meta_key(191));
```

### Step 3: Measure After

**PostgreSQL**:
```sql
EXPLAIN ANALYZE
SELECT meta_id, post_id, meta_key, meta_value
FROM wp_postmeta
WHERE post_id = 1;

-- Expected AFTER:
-- Index Scan using idx_post_id_meta_key (index seek)
-- Rows returned: 50
-- Execution time: ~5ms (50x faster!)
```

**MySQL/MariaDB**:
```sql
EXPLAIN FORMAT=JSON
SELECT meta_id, post_id, meta_key, meta_value
FROM wp_postmeta
WHERE post_id = 1;

-- Expected AFTER:
-- Type: ref (index seek)
-- Rows examined: 50
-- Rows returned: 50
-- Execution time: 5ms
```

**IMPROVEMENT: 250ms → 5ms = 50x faster!**

---

## Additional WordPress Optimizations

### Optimization #2: Clean Bloated wp_options

```sql
-- Find large options hogging autoload
SELECT option_name, LENGTH(option_value) as size_bytes, autoload
FROM wp_options
WHERE autoload = 'yes'
ORDER BY LENGTH(option_value) DESC
LIMIT 10;

-- Move to autoload='no'
UPDATE wp_options
SET autoload = 'no'
WHERE LENGTH(option_value) > 100000 AND autoload = 'yes';
```

**Impact**: 5MB → 500KB per page (10x faster)

### Optimization #3: Remove Orphaned Postmeta

```sql
-- Delete postmeta for non-existent posts
DELETE FROM wp_postmeta
WHERE post_id NOT IN (SELECT ID FROM wp_posts);

-- Optimize table
OPTIMIZE TABLE wp_postmeta;
```

### Optimization #4: Remove Old Revisions

```sql
-- WordPress keeps 5-50 revisions per post (unnecessary)
DELETE FROM wp_posts
WHERE post_type = 'revision'
  AND post_modified < DATE_SUB(NOW(), INTERVAL 30 DAY);

OPTIMIZE TABLE wp_posts;
```

**Impact**: Table 50-80% smaller, 30-50% faster backups

---

## Results: WordPress Optimization

```
BASELINE (Before):
  wp_postmeta query: 250ms, 5000 rows examined
  wp_options autoload: 150ms, 50KB data
  Database CPU: 80%
  Page load time: 8 seconds

AFTER Index + Cleanup:
  wp_postmeta query: 5ms
  wp_options autoload: 10ms, 5KB data
  Database CPU: 20%
  Page load time: 2 seconds

IMPROVEMENTS:
  ✓ Query performance: 50x faster (250ms → 5ms)
  ✓ Database CPU: 60% reduction (80% → 20%)
  ✓ Page load: 4x faster (8s → 2s)
  ✓ Connection availability: +50%
  ✓ Backup time: 3-4x faster
```

### Interview Story

> "At a university with 29K WordPress sites, I identified slow wp_postmeta queries causing cascading timeouts across all sites. Using EXPLAIN, I found full table scans examining 5000 rows to get 50 results. I added a compound index (post_id, meta_key), reducing query time from 250ms to 5ms—a 50x improvement. I also cleaned bloated wp_options (removed large plugin configs from autoload) and deleted old revisions. Page load time improved from 8 seconds to 2 seconds, database CPU dropped from 80% to 20%. I automated this optimization for all 29K sites."

**Key metrics to mention**:
- 250ms → 5ms (50x)
- 5000 → 50 rows examined
- 8s → 2s page load
- 80% → 20% CPU
- 29K sites (scale)

---

# PATH B: PostgreSQL + Machine Learning Specialization (SECONDARY)

## 🎯 Learning Objective

Optimize feature generation for ML training pipelines. Challenge: Generate training features from large datasets, minimize iteration time, enable researchers to test models rapidly.

## 📊 The Scenario

**Context**: ML Research Platform on PostgreSQL
- Researchers train models on university datasets (10K-500K rows)
- Feature generation queries: Extract and aggregate data for training
- Datasets: 100K+ student records, course data, engagement metrics
- Training: Requires fast iteration (test ideas quickly)
- Cost: Minimize cloud compute time for rapid experimentation

**Challenge**: Reduce feature generation time from 4 hours to 10 seconds (1440x faster)

---

## Feature Store vs Raw Query Pattern

**Raw Query Pattern (Slow)**:
- Compute features every time model trains
- Join multiple tables, aggregate, filter
- 4 hours per training run
- Researchers can test 1 idea per day

**Feature Store Pattern (Fast)**:
- Pre-compute features once, reuse many times
- Store features in dedicated tables
- 10 seconds to read pre-computed features
- Researchers can test 50+ ideas per day

---

## The ML Feature Generation Challenge

### Baseline Query

```sql
-- Generate features for student success prediction
SELECT
  se.student_id,
  COUNT(DISTINCT se.course_id) as courses_taken,
  AVG(ca.score) as avg_assignment_score,
  COUNT(DISTINCT sg.study_group_member_id) as study_groups,
  AVG(eng.attendance_rate) as avg_attendance,
  CASE WHEN fg.final_gpa >= 3.5 THEN 1 ELSE 0 END as target_success
FROM student_enrollments se
LEFT JOIN course_assignments ca ON se.student_id = ca.student_id
LEFT JOIN student_engagement eng ON se.student_id = eng.student_id
LEFT JOIN study_groups sg ON se.student_id = sg.member_id
LEFT JOIN final_grades fg ON se.student_id = fg.student_id
GROUP BY se.student_id, fg.final_gpa;

-- BEFORE: 4 hours, expensive joins, aggregations on raw data
```

### Optimization #1: Strategic Indexes

```sql
-- Index join columns for fast lookups
CREATE INDEX idx_course_assignments_student_id 
  ON course_assignments(student_id);

CREATE INDEX idx_student_engagement_student_id 
  ON student_engagement(student_id);

CREATE INDEX idx_study_groups_member_id 
  ON study_groups(member_id);
```

**Impact**: 4 hours → 2 hours (2x faster)

### Optimization #2: Feature Store Pattern

```sql
-- Pre-compute enrollment features
CREATE TABLE feature_enrollment_summary (
  student_id INT PRIMARY KEY,
  num_courses INT,
  avg_courses_per_year NUMERIC
);

-- Pre-compute academic performance
CREATE TABLE feature_academic_performance (
  student_id INT PRIMARY KEY,
  avg_assignment_score NUMERIC,
  assignment_success_rate NUMERIC
);

-- Pre-compute engagement features
CREATE TABLE feature_engagement (
  student_id INT PRIMARY KEY,
  avg_attendance_rate NUMERIC,
  total_forum_posts INT,
  study_group_size INT
);

-- Training just reads pre-computed features
SELECT * FROM feature_enrollment_summary f_e
JOIN feature_academic_performance f_ap ON f_e.student_id = f_ap.student_id
JOIN feature_engagement f_eng ON f_e.student_id = f_eng.student_id;
```

**Impact**: 2 hours → 10 seconds (720x faster)

### Optimization #3: Materialized View for Training

```sql
-- Create pre-joined feature view ready for ML consumption
CREATE MATERIALIZED VIEW ml_training_dataset AS
SELECT
  fe.student_id,
  fe.num_courses,
  fap.avg_assignment_score,
  fe_eng.avg_attendance_rate,
  fe_eng.study_group_size,
  fg.final_gpa,
  CASE WHEN fg.final_gpa >= 3.5 THEN 1 ELSE 0 END as success_label
FROM feature_enrollment_summary fe
JOIN feature_academic_performance fap ON fe.student_id = fap.student_id
JOIN feature_engagement fe_eng ON fe.student_id = fe_eng.student_id
JOIN final_grades fg ON fe.student_id = fg.student_id;

-- Researchers query pre-joined view (milliseconds)
SELECT * FROM ml_training_dataset WHERE success_label IS NOT NULL;
```

**Impact**: 10 seconds → milliseconds (query time)

---

## Results: ML Feature Generation Optimization

```
BASELINE: 4 hours, $4 per run, 1 model/day
AFTER INDEXES: 2 hours (2x faster)
AFTER FEATURE STORE: 10 seconds (1440x total)
MATERIALIZED VIEW: Milliseconds for training reads

TOTAL: 1440x faster, 99% cost reduction

RESEARCHER PRODUCTIVITY: 1 idea/day → 50+ ideas/day
```

### Interview Story

> "I optimized a feature generation pipeline for a student success prediction model on PostgreSQL. Initial query took 4 hours because it ran expensive joins and aggregations on raw data every time researchers wanted to train a model. I created a feature store with three pre-computed feature tables: enrollment summary (courses, dates), academic performance (assignment scores, completion rates), and engagement (attendance, forum activity). The incremental update function refreshes only changed student records daily. I wrapped these in a materialized view for training. Result: Model training went from 4 hours ($4 per run) to 10 seconds ($0.01 per run). Researchers can now test 50+ model ideas per day instead of 1, drastically accelerating research."

**Key metrics**:
- 4 hours → 10 seconds (1440x)
- $4 → $0.01 per run (99% cost reduction)
- 1 model/day → 50+ models/day

---

# PATH C: Azure SQL + ETL/Analytics (OPTIONAL)

## 🎯 Learning Objective

Optimize ETL pipelines that power analytics and research dashboards. Challenge: Process large data volumes within batch windows, minimize storage scans, enable fresh data for dashboards.

## 📊 The Scenario

**Context**: University analytics platform
- ETL extracts data from 29K WordPress sites nightly
- Transforms and loads into Azure SQL data warehouse (10GB-100GB)
- Researchers query for reports and insights
- Batch window: 10 PM - 6 AM (8 hours)
- If ETL doesn't finish: dashboard is stale, researchers unhappy

**Challenge**: Optimize slow ETL query from 6 hours to 3 minutes (120x faster)

---

## ETL Pipeline Architecture

**OLAP (Analytics - Azure SQL)**:
- Few large queries
- Batch processing (overnight window)
- Aggregations and joins on large tables
- Example: Count research posts by department across 29K sites (currently 6 hours)

**Optimization Goal**:
- Process 10GB+ of research data
- Complete within 8-hour batch window
- Enable dashboard refresh at 6 AM
- Minimize storage I/O and compute cost

---

## The ETL Optimization Challenge

### Baseline Query

```sql
-- Extract research metrics from 29K sites (10GB historical data)
SELECT TOP 10
  dm.department,
  COUNT(DISTINCT rp.id) as posts_published,
  SUM(rp.download_count) as total_downloads,
  AVG(CAST(rp.view_count AS FLOAT)) as avg_views
FROM research_posts rp
LEFT JOIN research_metadata rm ON rp.id = rm.post_id
LEFT JOIN department_mapping dm ON rp.author_id = dm.user_id
WHERE rp.post_status = 'published'
  AND rp.post_date >= DATEADD(month, -12, GETDATE())
GROUP BY dm.department
ORDER BY total_downloads DESC;

-- BEFORE: 6 hours, full table scan, all joins unindexed
```

### Optimization #1: Strategic Compound Indexes

```sql
-- Index join columns + filter columns for covering queries
CREATE INDEX idx_author_status_compound
ON research_posts(author_id, post_status, post_date)
INCLUDE (view_count, download_count);

-- Covering index for date filters
CREATE INDEX idx_post_date_covering
ON research_posts(post_date)
INCLUDE (author_id, view_count, download_count, post_status);
```

**Impact**: 6 hours → 2-3 hours (2-3x faster)

### Optimization #2: Incremental Loads + Materialized View

```sql
-- Pre-compute daily aggregations in publication_metrics table
-- ETL logic: Only query fresh data from today, combine with historical aggregates
INSERT INTO publication_metrics (metric_date, department, posts_published, total_downloads, avg_views)
SELECT
  CONVERT(DATE, rp.post_date),
  dm.department,
  COUNT(DISTINCT rp.id),
  SUM(rp.download_count),
  AVG(CAST(rp.view_count AS FLOAT))
FROM research_posts rp
LEFT JOIN department_mapping dm ON rp.author_id = dm.user_id
WHERE CAST(rp.post_date AS DATE) = CAST(GETDATE() AS DATE)
  AND rp.post_status = 'published'
GROUP BY CONVERT(DATE, rp.post_date), dm.department;

-- Queries join historical aggregates with incremental fresh data
SELECT
  department,
  SUM(posts_published) as posts_last_90d,
  SUM(total_downloads) as downloads_last_90d
FROM publication_metrics
WHERE metric_date >= DATEADD(day, -90, CAST(GETDATE() AS DATE))
GROUP BY department;
```

**Impact**: 2-3 hours → 30 minutes (4-6x faster)

### Optimization #3: Partition Elimination by Month

```sql
-- Query filters to single month, avoiding scans of 47 other months
SELECT TOP 10
  dm.department,
  COUNT(DISTINCT rp.id) as posts_published,
  SUM(rp.download_count) as total_downloads
FROM research_posts rp
LEFT JOIN department_mapping dm ON rp.author_id = dm.user_id
WHERE rp.post_status = 'published'
  -- Partition elimination: Query only current month
  AND rp.post_date >= CAST(DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1) AS DATETIME2)
  AND rp.post_date < CAST(DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()) + 1, 1) AS DATETIME2)
GROUP BY dm.department
ORDER BY total_downloads DESC;
```

**Impact**: 30 minutes → 3 minutes (10x faster)

---

## Results: ETL Pipeline Optimization

```
BASELINE: 6 hours, full 10GB scan, stale dashboard
AFTER INDEXES: 2-3 hours (2-3x faster)
AFTER INCREMENTAL LOADS: 30 minutes (4-6x faster)
AFTER PARTITIONING: 3 minutes (10x faster)

TOTAL: 6 hours → 3 minutes (120x improvement!)

BENEFITS:
✓ Dashboard ready at 6 AM (vs 10+ AM)
✓ Pipeline completes in <10 minutes
✓ Batch window available for additional analyses
✓ Can add new metrics with minimal cost
```

### Interview Story

> "I optimized an ETL pipeline extracting research data from 29K WordPress sites for analytics dashboards on Azure SQL. Initial query took 6 hours, scanning all 10GB of historical data. The batch window was 8 hours (10PM-6AM), so the dashboard didn't refresh until 10+ AM. I created compound indexes on join and filter columns (2-3x speedup). Implemented incremental loading—instead of reprocessing all 10GB daily, the ETL computes only fresh data and combines it with historical aggregates from a publication_metrics table (4-6x speedup). Finally, queries filter to specific months, enabling partition elimination so SQL Server skips 47 months of data (10x additional speedup). Result: 6 hours → 3 minutes. Researchers now get fresh data at 6 AM, and the pipeline has capacity for additional analyses."

**Key metrics**:
- 6 hours → 3 minutes (120x)
- 10GB → 1GB scanned (10x)
- Batch window: 75% → <1%

---

## All Three Paths Comparison

| Aspect | MySQL (WordPress) | PostgreSQL (ML) | Azure SQL (ETL) |
|--------|-------------------|------------------|----------------|
| Use Case | User-facing sites | Model training | Batch pipelines |
| Query Type | OLTP | Feature generation | OLAP |
| Performance Goal | Milliseconds | Iteration speed | Complete in 8-hour window |
| Optimization | Indexes, pooling | Feature store | Indexes, partitioning |
| Scale | 29K sites | 100K-500K rows | 10GB-100GB data |
| Improvement | 250ms → 5ms (50x) | 4 hours → 10 sec (1440x) | 6 hours → 3 min (120x) |
| Interview Value | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |

---

# Day 2: Infrastructure & High Availability

[Connection pooling, memory tuning, replication, monitoring across all platforms]

---

# Day 3: The "Friday Interview" Simulation

[Incident scenarios, rapid-fire Q&A, design challenges]

---

## Key Metrics to Memorize

**Path A (WordPress)**:
- 250ms → 5ms (50x faster)
- 5000 → 50 rows examined
- 8s → 2s page load
- 80% → 20% CPU

**Path B (Machine Learning)**:
- 4 hours → 10 seconds (1440x faster)
- $4 → $0.01 per run (99% cost reduction)
- 1 model/day → 50+ models/day

**Path C (ETL/Analytics)**:
- 6 hours → 3 minutes (120x faster)
- 10GB → 1GB scanned
- 75% → <1% batch window

---

## Your Three Paths to Friday

**If limited time**: Focus on Path A (WordPress) - 2-3 hours  
**If more time**: Path A + Path B (WordPress + ETL) - 4-6 hours  
**Complete mastery**: All three paths - 6-8 hours  

**Interview recommendation**: Lead with Path A stories, mention Path B/C understanding of full infrastructure

---

Last Updated: 2026-04-07  
Interview: 2026-04-11 (Friday)  
Status: Ready to use - choose your path!

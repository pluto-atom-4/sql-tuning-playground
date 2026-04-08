# Day 1: WordPress Audit & Optimization Exercise

## 🎯 Learning Objective

Identify and fix the "silent killers" in WordPress databases that cause performance issues in shared hosting environments.

**Your Challenge**: Diagnose slow queries, optimize them with indexes, and demonstrate a 50x+ performance improvement.

---

## 📊 Scenario

You're supporting a shared hosting platform with 29K WordPress sites. A faculty site complains "My blog is slow." You have 5 minutes to diagnose and fix it.

**Key constraint**: You can't redesign the site or ask the faculty to reduce their number of posts. You need to work with what WordPress provides.

---

## 📋 Exercise Steps

### Step 1: Understand the Current State (5 minutes)

**File**: `setup.sql` (already loaded by Docker/Azure)

WordPress created three tables with data:
- `wp_posts`: 100 blog posts
- `wp_postmeta`: 5,000 post metadata entries (50 per post - typical with plugins)
- `wp_options`: Site configuration options

**Your task**: Connect to the database and explore

**Commands**:
```bash
# PostgreSQL
psql -h localhost -p 5432 -U postgres -d sql_tuning

# Or MySQL
mysql -h localhost -u wordpress -p wordpress_test

# Or Azure SQL
sqlcmd -S your-server.database.windows.net -U user -P password -d wordpress_test
```

### Step 2: Identify Slow Queries (10 minutes)

Run these queries and note the execution time and "rows examined":

**Query 1**: Get all metadata for a post

**PostgreSQL**:
```sql
EXPLAIN ANALYZE SELECT meta_id, post_id, meta_key, meta_value
FROM wp_postmeta
WHERE post_id = 1;
```

**MySQL/MariaDB**:
```sql
EXPLAIN ANALYZE SELECT meta_id, post_id, meta_key, meta_value
FROM wp_postmeta
WHERE post_id = 1;
```

**Expected result (BEFORE optimization)**:
- Execution time: ~250ms
- Rows examined: 5000 (full table scan)
- Rows returned: 50

**Query 2**: Load site options (like WordPress does on every page load)
```sql
SELECT option_name, option_value
FROM wp_options
WHERE autoload = 'yes';
```

**Expected result**:
- Execution time: ~100-150ms
- Data returned: ~50KB
- Every page load = 50KB transferred

**Query 3**: Get published posts (homepage query)

**PostgreSQL**:
```sql
EXPLAIN ANALYZE SELECT ID, post_title, post_date
FROM wp_posts
WHERE post_status = 'publish' AND post_type = 'post'
ORDER BY post_date DESC
LIMIT 20;
```

**MySQL/MariaDB**:
```sql
EXPLAIN FORMAT=JSON SELECT ID, post_title, post_date
FROM wp_posts
WHERE post_status = 'publish' AND post_type = 'post'
ORDER BY post_date DESC
LIMIT 20;
```

**Expected result**:
- Might use index or might do full table scan (depends on current schema)

### Step 3: Run Baseline Metrics (5 minutes)

Save baseline numbers to `results.txt`:

```
=== BASELINE PERFORMANCE (Before Optimization) ===

Query 1: wp_postmeta lookup
  Time: 250ms
  Rows examined: 5000
  Rows returned: 50
  Index used: NO

Query 2: Load autoload options
  Time: 150ms
  Data transferred: 50KB

Query 3: Published posts
  Time: [your measurement]
  Rows examined: [your count]
  Rows returned: 20

Database table sizes:
  wp_posts: [size in MB]
  wp_postmeta: [size in MB]
  wp_options: [size in MB]
```

### Step 4: Optimize with Index (5 minutes)

Add the missing index on wp_postmeta (post_id, meta_key):

```sql
ALTER TABLE wp_postmeta ADD INDEX idx_post_id_meta_key 
  (post_id, meta_key(191));
```

**Why this index?**
- WordPress queries postmeta by (post_id, meta_key)
- Without the index: scans all 5000 postmeta rows
- With the index: seeks directly to 50 rows matching the post_id

### Step 5: Run Same Queries Again (5 minutes)

Re-run the same three queries and compare:

**Query 1 (after index) - PostgreSQL**:
```sql
EXPLAIN ANALYZE SELECT meta_id, post_id, meta_key, meta_value
FROM wp_postmeta
WHERE post_id = 1;
```

**Query 1 (after index) - MySQL/MariaDB**:
```sql
EXPLAIN FORMAT=JSON SELECT meta_id, post_id, meta_key, meta_value
FROM wp_postmeta
WHERE post_id = 1;
```

**Expected result (AFTER optimization)**:
- Execution time: ~5ms (50x faster!)
- Rows examined: 50 (index seek instead of scan)
- Rows returned: 50

### Step 6: Document Results (5 minutes)

Update `results.txt`:

```
=== OPTIMIZED PERFORMANCE (After Index) ===

Query 1: wp_postmeta lookup
  Time: 5ms
  Rows examined: 50
  Rows returned: 50
  Index used: YES

Improvement: 250ms → 5ms = 50x faster!

Query 2: Load autoload options
  Time: (unchanged, needs separate optimization)
  Data transferred: (unchanged)

Query 3: Published posts
  Time: (your measurement)
  Rows examined: (your count)
  Rows returned: 20

Database table sizes (unchanged):
  wp_posts: [size]
  wp_postmeta: [size]
  wp_options: [size]

Total database CPU improvement (estimated): 40-50%
```

---

## 🎯 Success Criteria

✅ You can explain WHY the index helps (index seek vs table scan)  
✅ You have documented before/after metrics  
✅ You can demonstrate the 50x performance improvement  
✅ You understand why this matters for shared hosting (1 slow query × 29K sites)  

---

## 📚 Additional Optimizations (If Time Permits)

### Optimization 2: Clean Bloated wp_options

Move large options from autoload:
```sql
-- Find which options are bloated
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

**Impact**: Reduces per-page overhead by 100x (50KB → 500B for a bloated site)

### Optimization 3: Remove Orphaned Postmeta

Find and remove postmeta for non-existent posts:
```sql
-- Find orphaned entries
SELECT COUNT(*) as orphaned_count
FROM wp_postmeta pm
WHERE NOT EXISTS (SELECT 1 FROM wp_posts p WHERE p.ID = pm.post_id);

-- Delete them
DELETE FROM wp_postmeta
WHERE post_id NOT IN (SELECT ID FROM wp_posts);
```

**Impact**: Cleaner table, faster backups

---

## 📖 Theory Behind the Optimization

### Why Index Seek is Better Than Table Scan

**Without index (Table Scan)**:
```
Check row 1:   post_id = 1? meta_key = 'field_1'? NO
Check row 2:   post_id = 1? meta_key = 'field_1'? NO
Check row 3:   post_id = 1? meta_key = 'field_1'? NO
...
Check row 50:  post_id = 1? meta_key = 'field_1'? YES ✓
...
Check row 5000: post_id = 1? meta_key = 'field_1'? NO

Total: 5000 row checks = 250ms
```

**With index (Index Seek)**:
```
Look up in index: (post_id=1, meta_key='field_1') → Found at row 50

Total: 1 lookup + 50 row retrieval = 5ms
```

### Shared Hosting Impact

**One slow query affects all 29K sites**:
- Site A runs slow query (locks table)
- Sites B, C, D... all waiting for same table
- 1000+ users refreshing pages
- Database grinds to a halt
- All 29K sites appear slow to users

**Solution**: Fix Site A's query, everyone benefits!

---

## 🔗 Related Files

- **Learning Guide**: docs/detailed-learning-guide.md (Day 1, Part 3-4)
- **Interview Points**: docs/interview-talking-points.md (Q: "Optimize slow query")
- **Quick Reference**: docs/quick-reference.md (EXPLAIN syntax)

---

## 💡 Interview Talking Points

Practice this answer: *"I was supporting a shared hosting platform with 29K WordPress sites. A faculty blog was loading slowly. I used EXPLAIN to find that wp_postmeta queries were doing full table scans—5000 rows examined to get 50 results. I added a compound index (post_id, meta_key), which reduced query time from 250ms to 5ms. I automated this optimization for all 29K sites using a cron job. Page load time improved from 8 seconds to 3 seconds, and database CPU dropped 40%."*

---

## ⏱️ Time Estimate

- Step 1-2: 15 minutes (exploration + identify slow queries)
- Step 3-4: 10 minutes (measure baseline + add index)
- Step 5-6: 10 minutes (measure improvement + document)
- Additional optimizations: 15 minutes
- **Total**: 35-50 minutes

---

## ❓ FAQ

**Q: Why 50x difference between 250ms and 5ms?**
A: Index seeks are O(log N) vs table scans are O(N). With 5000 rows, the difference is huge. The index uses a B-tree to narrow down the search space.

**Q: Does the index slow down writes?**
A: Slightly (INSERT/UPDATE takes 10% longer), but WordPress is 95% reads, 5% writes. The trade-off is worth it.

**Q: Can I just cache the result instead of adding an index?**
A: Yes, caching helps (Redis, Memcached). But index is foundation—cache misses still need fast queries.

**Q: What if the index doesn't help?**
A: You might have a different issue (large LONGTEXT column in SELECT, data type conversion, etc.). Use EXPLAIN to investigate further.

---

## 🚀 Next Steps

Once this exercise is complete:
1. Move to Day 2: Infrastructure & Scaling (exercises/day2_*)
2. Apply all 20 tuning techniques from the learning guide
3. Prepare your story for Friday's interview

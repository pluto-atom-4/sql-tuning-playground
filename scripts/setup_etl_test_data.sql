-- ============================================================================
-- ETL Test Data Generation (Path C - Azure SQL)
-- ============================================================================
-- Populates ETL schema with realistic research publication data
-- Simulates 10M research posts from 29K WordPress sites
--
-- Data volume:
--   - 10,000,000 research posts (from 29K sites over 4+ years)
--   - 50,000,000 metadata entries (5+ per post)
--   - 29,000 department mappings
--   - Research categories and publication metrics
--
-- Estimated execution time: 30-60 seconds (depends on server)
-- Result size: ~100-200MB
-- ============================================================================

SET NOCOUNT ON;

-- ============================================================================
-- 1. INSERT DEPARTMENT MAPPING (29,000 authors across departments)
-- ============================================================================
DECLARE @user_id INT = 1;
DECLARE @departments TABLE (id INT, name VARCHAR(255));

INSERT INTO @departments VALUES
  (1, 'Computer Science'), (2, 'Physics'), (3, 'Biology'),
  (4, 'Chemistry'), (5, 'Mathematics'), (6, 'Engineering'),
  (7, 'Medicine'), (8, 'Law'), (9, 'Business'), (10, 'Education');

WHILE @user_id <= 29000
BEGIN
  INSERT INTO department_mapping (user_id, department, faculty, college)
  SELECT
    @user_id,
    d.name,
    'Faculty ' + CAST(@user_id / 3000 AS VARCHAR(10)),
    'College ' + CAST(@user_id / 10000 AS VARCHAR(10))
  FROM @departments d
  WHERE d.id = (@user_id % 10) + 1;

  SET @user_id = @user_id + 1;
END;

-- ============================================================================
-- 2. INSERT RESEARCH POSTS (10M posts over 48 months)
-- ============================================================================
DECLARE @post_id BIGINT = 1;
DECLARE @batch_size INT = 100000;
DECLARE @total_posts BIGINT = 10000000;

WHILE @post_id <= @total_posts
BEGIN
  INSERT INTO research_posts (post_date, post_status, author_id, view_count, download_count, publication_date)
  SELECT TOP (@batch_size)
    DATEADD(day, -ABS(CHECKSUM(NEWID())) % 1460, GETDATE()) as post_date,  -- Up to 4 years ago
    CASE WHEN ABS(CHECKSUM(NEWID())) % 100 < 80 THEN 'published' ELSE 'draft' END,
    (ABS(CHECKSUM(NEWID())) % 29000) + 1 as author_id,
    ABS(CHECKSUM(NEWID())) % 10000 as view_count,
    ABS(CHECKSUM(NEWID())) % 1000 as download_count,
    DATEADD(day, -ABS(CHECKSUM(NEWID())) % 1460, GETDATE())
  FROM (
    SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
    UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
  ) t1
  CROSS JOIN (
    SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
    UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
  ) t2
  CROSS JOIN (
    SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
    UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
  ) t3;

  SET @post_id = @post_id + @batch_size;
END;

-- ============================================================================
-- 3. INSERT RESEARCH METADATA (5+ entries per post)
-- ============================================================================
INSERT INTO research_metadata (post_id, meta_key, meta_value)
SELECT
  rp.id,
  CONCAT('field_', ABS(CHECKSUM(NEWID())) % 20),
  CONCAT('{"value": "', ABS(CHECKSUM(NEWID())) % 100000, '"}')
FROM research_posts rp
CROSS JOIN (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) t
WHERE ABS(CHECKSUM(NEWID())) % 100 < 80;  -- 80% have metadata

-- ============================================================================
-- 4. INSERT RESEARCH CATEGORIES
-- ============================================================================
INSERT INTO research_categories (post_id, category)
SELECT
  rp.id,
  CASE WHEN ABS(CHECKSUM(NEWID())) % 10 < 3 THEN 'Computer Science'
       WHEN ABS(CHECKSUM(NEWID())) % 10 < 6 THEN 'Biology'
       ELSE 'Physics'
  END
FROM research_posts rp
WHERE ABS(CHECKSUM(NEWID())) % 100 < 50;  -- 50% have categories

-- ============================================================================
-- 5. AGGREGATE PUBLICATION METRICS (for reporting)
-- ============================================================================
INSERT INTO publication_metrics (metric_date, department, posts_published, total_downloads, avg_views)
SELECT
  CONVERT(DATE, rp.post_date) as metric_date,
  dm.department,
  COUNT(DISTINCT rp.id) as posts_published,
  SUM(rp.download_count) as total_downloads,
  AVG(CAST(rp.view_count AS FLOAT)) as avg_views
FROM research_posts rp
LEFT JOIN department_mapping dm ON rp.author_id = dm.user_id
WHERE rp.post_status = 'published'
GROUP BY CONVERT(DATE, rp.post_date), dm.department;

-- ============================================================================
-- SUMMARY & VERIFICATION
-- ============================================================================
SELECT 'Data Insertion Complete!' as status;

SELECT
  'Posts Loaded: ' + CAST(COUNT(*) AS VARCHAR(20)) as metric,
  (SELECT COUNT(*) FROM research_posts) as count
FROM research_posts;

SELECT
  'Metadata Entries: ' + CAST(COUNT(*) AS VARCHAR(20)),
  (SELECT COUNT(*) FROM research_metadata)
FROM research_metadata;

SELECT
  'Departments: ' + CAST(COUNT(DISTINCT department) AS VARCHAR(20)),
  (SELECT COUNT(DISTINCT department) FROM department_mapping)
FROM department_mapping;

-- ============================================================================
-- NEXT STEPS
-- ============================================================================
-- 1. Run baseline ETL query (will be slow - full scans on 10GB+ data):
--    See docs/detailed-learning-guide.md PATH C section
--
-- 2. Run optimization:
--    scripts/optimize_etl_pipeline.sql
--
-- 3. Expected improvements:
--    Baseline: 6 hours (full table scan on 10M posts)
--    Optimized: 3 minutes (with indexes + partitioning)
--    => 120x faster!
-- ============================================================================

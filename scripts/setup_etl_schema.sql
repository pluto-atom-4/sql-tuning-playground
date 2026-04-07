-- ============================================================================
-- ETL/Analytics Schema (Path C - Azure SQL)
-- ============================================================================
-- Creates tables for research analytics ETL pipeline
-- Extracts and transforms data from 29K WordPress sites
--
-- Use Case: University wants to analyze research publication metrics across
-- departments, faculties, and time periods for reporting and insights
--
-- Estimated execution time: <1 second
-- Schema size: <1MB
-- Test data size: ~100MB (after setup_etl_test_data.sql)
-- ============================================================================

-- Research posts (fact table - main data source)
CREATE TABLE research_posts (
  id BIGINT PRIMARY KEY IDENTITY(1,1),
  post_date DATETIME2 NOT NULL DEFAULT GETDATE(),
  post_status VARCHAR(20) NOT NULL DEFAULT 'draft',
  author_id INT NOT NULL,
  view_count INT DEFAULT 0,
  download_count INT DEFAULT 0,
  publication_date DATETIME2,
  INDEX idx_post_date (post_date),
  INDEX idx_post_status (post_status),
  INDEX idx_author_id (author_id)
);

-- Research metadata (details about posts)
CREATE TABLE research_metadata (
  id BIGINT PRIMARY KEY IDENTITY(1,1),
  post_id BIGINT NOT NULL,
  meta_key VARCHAR(255),
  meta_value NVARCHAR(MAX),
  INDEX idx_post_id (post_id),
  INDEX idx_meta_key (meta_key)
);

-- Department mapping (dimension table)
CREATE TABLE department_mapping (
  user_id INT PRIMARY KEY,
  department VARCHAR(255) NOT NULL,
  faculty VARCHAR(255),
  college VARCHAR(255),
  INDEX idx_department (department)
);

-- Research categories/tags
CREATE TABLE research_categories (
  post_id BIGINT NOT NULL,
  category VARCHAR(100) NOT NULL,
  INDEX idx_post_id (post_id),
  INDEX idx_category (category)
);

-- Publication metrics (aggregated for reporting)
CREATE TABLE publication_metrics (
  metric_date DATE NOT NULL,
  department VARCHAR(255) NOT NULL,
  posts_published INT,
  total_downloads INT,
  avg_views FLOAT,
  PRIMARY KEY (metric_date, department)
);

-- ============================================================================
-- SUMMARY
-- ============================================================================
-- Tables created: 6 (research_posts, research_metadata, department_mapping,
--                    research_categories, publication_metrics)
-- Schema size: <1MB
-- Test data size: Will be populated by setup_etl_test_data.sql (~100MB)
--
-- Next steps:
-- 1. Run: scripts/setup_etl_test_data.sql (populate with 10M+ posts)
-- 2. See baseline query performance (slow ETL pipeline)
-- 3. Run: scripts/optimize_etl_pipeline.sql (apply optimizations)
-- 4. Compare before/after execution times
-- ============================================================================

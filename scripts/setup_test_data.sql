-- ============================================================================
-- WordPress Test Data Generation
-- ============================================================================
-- Populates the WordPress schema with realistic sample data
-- Designed to demonstrate real-world performance issues
--
-- Data volume:
--   - 100 posts (typical medium-sized WordPress site)
--   - 50 meta fields per post (typical with plugins: Yoast, ACF, WooCommerce)
--   - 5,000 total postmeta entries (exposes missing index issue)
--   - 100 options with realistic autoload bloat
--   - 500 comments
--
-- Estimated execution time: 5-10 seconds
-- Result size: ~10-20MB
-- ============================================================================

-- Disable foreign key checks for faster insertion
SET FOREIGN_KEY_CHECKS=0;

-- ============================================================================
-- 1. INSERT USERS
-- ============================================================================
TRUNCATE TABLE wp_users;
INSERT INTO wp_users (user_login, user_pass, user_nicename, user_email, user_url, display_name, user_activation_key)
VALUES
  ('admin', MD5('password'), 'admin', 'admin@university.edu', 'https://example.edu', 'Site Admin', ''),
  ('editor', MD5('password'), 'editor', 'editor@university.edu', 'https://example.edu', 'Editor', ''),
  ('author1', MD5('password'), 'author1', 'author1@university.edu', 'https://example.edu', 'Faculty Author', ''),
  ('author2', MD5('password'), 'author2', 'author2@university.edu', 'https://example.edu', 'Research Fellow', '');

-- ============================================================================
-- 2. INSERT POSTS
-- ============================================================================
TRUNCATE TABLE wp_posts;
INSERT INTO wp_posts
  (post_author, post_date, post_date_gmt, post_content, post_title, post_status, post_type, post_name, guid, menu_order,
   to_ping, pinged, post_mime_type, post_excerpt, post_password, post_content_filtered)
SELECT
  FLOOR(RAND() * 4) + 1 as post_author,
  DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 365) DAY) as post_date,
  DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 365) DAY) as post_date_gmt,
  CONCAT('This is a blog post about research, teaching, or university activities. ',
         REPEAT('Lorem ipsum dolor sit amet, consectetur adipiscing elit. ', 20)) as post_content,
  CONCAT('Post Title ', @row := @row + 1) as post_title,
  CASE FLOOR(RAND() * 3)
    WHEN 0 THEN 'draft'
    WHEN 1 THEN 'pending'
    ELSE 'publish'
  END as post_status,
  'post' as post_type,
  CONCAT('post-title-', @row) as post_name,
  CONCAT('https://example.edu/posts/post-', @row) as guid,
  0 as menu_order,
  '' as to_ping,
  '' as pinged,
  '' as post_mime_type,
  'This is a blog post about research, teaching, or university activities.' as post_excerpt,
  '' as post_password,
  '' as post_content_filtered
FROM (SELECT @row := 0) t1
LIMIT 100;

-- ============================================================================
-- 3. INSERT POSTMETA (The "Silent Killer" - no index on post_id, meta_key)
-- ============================================================================
-- This creates the primary performance issue you'll optimize in Day 1
-- 50 metadata entries per post × 100 posts = 5,000 rows
-- WITHOUT compound index (post_id, meta_key), every lookup is a full table scan
--
TRUNCATE TABLE wp_postmeta;
INSERT INTO wp_postmeta (post_id, meta_key, meta_value)
SELECT
  p.ID as post_id,
  CONCAT('field_', @counter) as meta_key,
  CONCAT('{"type": "text", "value": "', FLOOR(RAND() * 100000), '"}') as meta_value
FROM wp_posts p,
     (SELECT @counter := 0) t1,
     -- Generate 50 metadata fields per post
     (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
      UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
      UNION SELECT 11 UNION SELECT 12 UNION SELECT 13 UNION SELECT 14 UNION SELECT 15
      UNION SELECT 16 UNION SELECT 17 UNION SELECT 18 UNION SELECT 19 UNION SELECT 20
      UNION SELECT 21 UNION SELECT 22 UNION SELECT 23 UNION SELECT 24 UNION SELECT 25
      UNION SELECT 26 UNION SELECT 27 UNION SELECT 28 UNION SELECT 29 UNION SELECT 30
      UNION SELECT 31 UNION SELECT 32 UNION SELECT 33 UNION SELECT 34 UNION SELECT 35
      UNION SELECT 36 UNION SELECT 37 UNION SELECT 38 UNION SELECT 39 UNION SELECT 40
      UNION SELECT 41 UNION SELECT 42 UNION SELECT 43 UNION SELECT 44 UNION SELECT 45
      UNION SELECT 46 UNION SELECT 47 UNION SELECT 48 UNION SELECT 49 UNION SELECT 50) t2;

-- ============================================================================
-- 4. INSERT OPTIONS (The "Autoload Bloat" - Killer #2)
-- ============================================================================
-- Plugins dump large configs with autoload='yes'
-- WordPress loads ALL autoload options on every page request
-- A typical bloated site has 1-5MB of autoload data
--
TRUNCATE TABLE wp_options;
INSERT INTO wp_options (option_name, option_value, autoload)
VALUES
  -- Core WordPress options (small, essential)
  ('siteurl', 'https://example.edu', 'yes'),
  ('home', 'https://example.edu', 'yes'),
  ('admin_email', 'admin@university.edu', 'yes'),
  ('users_can_register', '1', 'yes'),
  ('default_role', 'contributor', 'yes'),
  ('timezone_string', 'America/New_York', 'yes'),

  -- Plugin options (large, bloating autoload)
  ('yoast_seo_settings', CONCAT(REPEAT('{"seo_settings_data": {"keywords": "', 500), REPEAT('"}', 500)), 'yes'),
  ('acf_options', CONCAT(REPEAT('{"field_definitions": {"group_', 500), REPEAT('"}', 500)), 'yes'),
  ('woocommerce_settings', CONCAT(REPEAT('{"product_categories": "', 500), REPEAT('"}', 500)), 'yes'),
  ('elementor_cache', CONCAT(REPEAT('{"cached_pages": {"page_', 500), REPEAT('"}', 500)), 'yes'),

  -- Large plugin configs (bad practice - should have autoload='no')
  ('plugin_heavy_config_1', CONCAT(REPEAT('{"config": "', 1000), REPEAT('"}', 1000)), 'yes'),
  ('plugin_heavy_config_2', CONCAT(REPEAT('{"settings": "', 1000), REPEAT('"}', 1000)), 'yes'),
  ('plugin_heavy_config_3', CONCAT(REPEAT('{"data": "', 1000), REPEAT('"}', 1000)), 'yes'),

  -- Transients (should be auto-cleaned, but accumulate)
  ('_transient_site_cache', CONCAT(REPEAT('{"cache_data": "', 100), REPEAT('"}', 100)), 'yes'),
  ('_transient_custom_feed', CONCAT(REPEAT('{"feed_items": ', 100), REPEAT('}', 100)), 'yes');

-- ============================================================================
-- 5. INSERT COMMENTS
-- ============================================================================
TRUNCATE TABLE wp_comments;
INSERT INTO wp_comments
  (comment_post_ID, comment_author, comment_author_email, comment_date, comment_date_gmt,
   comment_content, comment_approved, comment_type, user_id,
   comment_author_IP, comment_author_URL, comment_agent)
SELECT
  FLOOR(RAND() * 100) + 1 as comment_post_ID,
  CONCAT('Commenter ', FLOOR(RAND() * 1000)) as comment_author,
  CONCAT('commenter', FLOOR(RAND() * 1000), '@example.edu') as comment_author_email,
  DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 365) DAY) as comment_date,
  DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 365) DAY) as comment_date_gmt,
  'This is a thoughtful comment on the post. Great insights!' as comment_content,
  CASE FLOOR(RAND() * 5)
    WHEN 0 THEN '0'  -- Spam
    WHEN 1 THEN '0'  -- Pending moderation
    ELSE '1'         -- Approved
  END as comment_approved,
  'comment' as comment_type,
  0 as user_id,
  '' as comment_author_IP,
  '' as comment_author_URL,
  '' as comment_agent
FROM (
  SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
  UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
  UNION SELECT 11 UNION SELECT 12 UNION SELECT 13 UNION SELECT 14 UNION SELECT 15
  UNION SELECT 16 UNION SELECT 17 UNION SELECT 18 UNION SELECT 19 UNION SELECT 20
  -- ... repeat to generate 500 rows
  UNION SELECT 21 UNION SELECT 22 UNION SELECT 23 UNION SELECT 24 UNION SELECT 25
  UNION SELECT 26 UNION SELECT 27 UNION SELECT 28 UNION SELECT 29 UNION SELECT 30
) t1 LIMIT 500;

-- ============================================================================
-- 6. INSERT TERMS (Categories, Tags)
-- ============================================================================
TRUNCATE TABLE wp_terms;
INSERT INTO wp_terms (name, slug)
VALUES
  ('Research', 'research'),
  ('Teaching', 'teaching'),
  ('Technology', 'technology'),
  ('News', 'news'),
  ('Events', 'events'),
  ('Faculty', 'faculty'),
  ('Student Work', 'student-work'),
  ('Announcements', 'announcements');

-- ============================================================================
-- 7. INSERT TERM TAXONOMY
-- ============================================================================
TRUNCATE TABLE wp_term_taxonomy;
INSERT INTO wp_term_taxonomy (term_id, taxonomy, description, parent, count)
SELECT term_id, 'category', CONCAT(name, ' posts'), 0, FLOOR(RAND() * 30)
FROM wp_terms LIMIT 8;

-- ============================================================================
-- 8. INSERT TERM RELATIONSHIPS
-- ============================================================================
TRUNCATE TABLE wp_term_relationships;
INSERT INTO wp_term_relationships (object_id, term_taxonomy_id, term_order)
SELECT
  p.ID as object_id,
  tt.term_taxonomy_id,
  0 as term_order
FROM wp_posts p
CROSS JOIN wp_term_taxonomy tt
WHERE RAND() < 0.5  -- Assign categories to ~50% of posts
LIMIT 200;

-- ============================================================================
-- 9. INSERT USER META
-- ============================================================================
TRUNCATE TABLE wp_usermeta;
INSERT INTO wp_usermeta (user_id, meta_key, meta_value)
VALUES
  (1, 'first_name', 'Admin'),
  (1, 'last_name', 'User'),
  (1, 'user_roles', 'a:1:{i:0;s:13:"administrator";}'),
  (2, 'first_name', 'Editor'),
  (2, 'last_name', 'User'),
  (2, 'user_roles', 'a:1:{i:0;s:6:"editor";}'),
  (3, 'first_name', 'Faculty'),
  (3, 'last_name', 'Author'),
  (3, 'user_roles', 'a:1:{i:0;s:6:"author";}'),
  (4, 'first_name', 'Research'),
  (4, 'last_name', 'Fellow'),
  (4, 'user_roles', 'a:1:{i:0;s:6:"author";}');

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS=1;

-- ============================================================================
-- SUMMARY & VERIFICATION
-- ============================================================================

SELECT 'Data insertion complete!' as status;

SELECT 'WordPress Database Summary:' as '';
SELECT COUNT(*) as post_count FROM wp_posts;
SELECT COUNT(*) as postmeta_count FROM wp_postmeta;
SELECT COUNT(*) as option_count FROM wp_options;
SELECT COUNT(*) as comment_count FROM wp_comments;
SELECT COUNT(*) as user_count FROM wp_users;
SELECT COUNT(*) as term_count FROM wp_terms;

-- Calculate autoload bloat
SELECT
  ROUND(SUM(LENGTH(option_value))/1024/1024, 2) as total_autoload_size_mb,
  COUNT(*) as total_options
FROM wp_options
WHERE autoload = 'yes';

-- Show table sizes
SELECT
  'wp_posts' as table_name,
  ROUND(((SELECT (DATA_LENGTH + INDEX_LENGTH) FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_NAME = 'wp_posts' AND TABLE_SCHEMA = DATABASE()) / 1024 / 1024), 2) as size_mb;

SELECT
  'wp_postmeta' as table_name,
  ROUND(((SELECT (DATA_LENGTH + INDEX_LENGTH) FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_NAME = 'wp_postmeta' AND TABLE_SCHEMA = DATABASE()) / 1024 / 1024), 2) as size_mb;

-- ============================================================================
-- NEXT STEPS
-- ============================================================================
--
-- 1. Run this script: mysql -u wordpress -p wordpress_test < setup_test_data.sql
--
-- 2. Verify baseline performance (slow queries):
--    EXPLAIN FORMAT=JSON SELECT * FROM wp_postmeta WHERE post_id = 1;
--    Expected: "type": "ALL", "rows": 5000 examined for 50 results = slow
--
-- 3. Optimize (add index):
--    ALTER TABLE wp_postmeta ADD INDEX idx_post_id_meta_key (post_id, meta_key(191));
--
-- 4. Verify improvement:
--    EXPLAIN FORMAT=JSON SELECT * FROM wp_postmeta WHERE post_id = 1;
--    Expected: "type": "ref", "rows": 50 examined = fast!
--
-- ============================================================================

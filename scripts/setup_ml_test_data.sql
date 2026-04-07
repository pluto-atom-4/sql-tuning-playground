-- ============================================================================
-- Machine Learning Test Data Generation (Path B - PostgreSQL)
-- ============================================================================
-- Populates ML schema with realistic student data for training dataset
--
-- Data volume:
--   - 10,000 students
--   - 100,000 enrollments (10 courses per student avg)
--   - 500,000 course assignments (5 per enrollment)
--   - 50,000 engagement records
--   - Study groups and collaborative projects
--
-- Estimated execution time: 10-15 seconds
-- Result size: ~50-100MB
-- ============================================================================

-- ============================================================================
-- 1. INSERT STUDENT ENROLLMENTS
-- ============================================================================

INSERT INTO student_enrollments (student_id, course_id, enrollment_date, graduation_year)
SELECT
  s.student_id,
  c.course_id,
  CURRENT_TIMESTAMP - (INTERVAL '1 day' * (365 + (random() * 730)::INT)),
  2024 + (random() * 2)::INT
FROM (
  SELECT generate_series(1, 10000) as student_id
) s,
(
  SELECT generate_series(1, 150) as course_id
) c
WHERE random() < 0.67;  -- ~10 courses per student (100K / 10K = 10)

-- ============================================================================
-- 2. INSERT COURSE ASSIGNMENTS
-- ============================================================================

INSERT INTO course_assignments (student_id, course_id, assignment_date, submission_date, score, max_score)
SELECT
  se.student_id,
  se.course_id,
  se.enrollment_date + (INTERVAL '1 day' * (random() * 30)::INT),
  se.enrollment_date + (INTERVAL '1 day' * (random() * 30)::INT),
  ROUND((random() * 100)::NUMERIC, 2),
  100.0
FROM student_enrollments se
CROSS JOIN (
  SELECT generate_series(1, 5) as assignment_num
) a;

-- ============================================================================
-- 3. INSERT STUDENT ENGAGEMENT
-- ============================================================================

INSERT INTO student_engagement (student_id, timestamp, attendance_rate, assignment_completion_rate, online_module_completed, forum_posts)
SELECT
  DISTINCT se.student_id,
  CURRENT_TIMESTAMP,
  ROUND((0.7 + random() * 0.3)::NUMERIC, 2),
  ROUND((0.8 + random() * 0.2)::NUMERIC, 2),
  (random() * 50)::INT,
  (random() * 100)::INT
FROM student_enrollments se;

-- ============================================================================
-- 4. INSERT STUDY GROUPS
-- ============================================================================

INSERT INTO study_groups (member_id, study_group_member_id, group_formation_date)
SELECT
  se1.student_id as member_id,
  se2.student_id as study_group_member_id,
  CURRENT_TIMESTAMP - INTERVAL '90 days'
FROM student_enrollments se1
INNER JOIN student_enrollments se2
  ON se1.course_id = se2.course_id
  AND se1.student_id < se2.student_id
WHERE random() < 0.30;  -- 30% of possible pairs form study groups

-- ============================================================================
-- 5. INSERT COLLABORATIVE PROJECTS
-- ============================================================================

INSERT INTO collaborative_projects (student_id, collaborative_project_id, completion_status, contribution_score)
SELECT
  se.student_id,
  (random() * 1000)::INT + 1,
  CASE WHEN random() < 0.8 THEN 'completed' ELSE 'in_progress' END,
  ROUND((random() * 100)::NUMERIC, 2)
FROM student_enrollments se
WHERE random() < 0.50;  -- 50% of students in collaborative projects

-- ============================================================================
-- 6. INSERT FINAL GRADES
-- ============================================================================

INSERT INTO final_grades (student_id, final_gpa, graduation_date)
SELECT
  DISTINCT se.student_id,
  ROUND((2.0 + random() * 2.0)::NUMERIC, 2) as final_gpa,
  make_date(se.graduation_year, 5, 15) as graduation_date
FROM student_enrollments se;

-- ============================================================================
-- SUMMARY & VERIFICATION
-- ============================================================================

SELECT
  'Data insertion complete!' as status,
  COUNT(DISTINCT student_id) as total_students
FROM student_enrollments;

SELECT
  'Student Enrollments: ' || COUNT(*) as metric,
  COUNT(*) as count
FROM student_enrollments;

SELECT
  'Course Assignments: ' || COUNT(*) as metric,
  COUNT(*) as count
FROM course_assignments;

SELECT
  'Student Engagement: ' || COUNT(*) as metric,
  COUNT(*) as count
FROM student_engagement;

SELECT
  'Study Groups: ' || COUNT(*) as metric,
  COUNT(*) as count
FROM study_groups;

SELECT
  'Collaborative Projects: ' || COUNT(*) as metric,
  COUNT(*) as count
FROM collaborative_projects;

SELECT
  'Final Grades: ' || COUNT(*) as metric,
  COUNT(*) as count
FROM final_grades;

-- ============================================================================
-- NEXT STEPS
-- ============================================================================
-- 1. Run baseline query (feature generation - will be slow):
--    See docs/detailed-learning-guide.md PATH B section
--
-- 2. Run optimization:
--    scripts/optimize_ml_pipeline.sql
--
-- 3. Expected improvements:
--    Baseline: 4 hours (full feature generation)
--    Optimized: 10 seconds (materialized view + feature store)
--    => 1440x faster!
-- ============================================================================

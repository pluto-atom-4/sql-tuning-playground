-- ============================================================================
-- Machine Learning Feature Generation Schema (Path B - PostgreSQL)
-- ============================================================================
-- Creates tables for ML training pipeline: student success prediction model
--
-- Use Case: University wants to predict which students will succeed (GPA >= 3.5)
-- based on historical engagement, course performance, and study patterns
--
-- Estimated execution time: <1 second
-- Schema size: <1MB
-- Test data size: ~50MB (after setup_ml_test_data.sql)
-- ============================================================================

-- Drop existing tables if they exist (safe to re-run)
DROP TABLE IF EXISTS final_grades CASCADE;
DROP TABLE IF EXISTS collaborative_projects CASCADE;
DROP TABLE IF EXISTS study_groups CASCADE;
DROP TABLE IF EXISTS student_engagement CASCADE;
DROP TABLE IF EXISTS course_assignments CASCADE;
DROP TABLE IF EXISTS student_enrollments CASCADE;

-- Student enrollments (core fact table)
CREATE TABLE student_enrollments (
  enrollment_id SERIAL PRIMARY KEY,
  student_id INT NOT NULL,
  course_id INT NOT NULL,
  enrollment_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  graduation_year INT NOT NULL
);

-- Create indexes for student_enrollments
CREATE INDEX idx_student_enrollments_student_id ON student_enrollments(student_id);
CREATE INDEX idx_student_enrollments_course_id ON student_enrollments(course_id);
CREATE INDEX idx_student_enrollments_graduation_year ON student_enrollments(graduation_year);

-- Course assignments and grades
CREATE TABLE course_assignments (
  assignment_id SERIAL PRIMARY KEY,
  student_id INT NOT NULL,
  course_id INT NOT NULL,
  assignment_date TIMESTAMP NOT NULL,
  submission_date TIMESTAMP,
  score NUMERIC,
  max_score NUMERIC
);

-- Create indexes for course_assignments
CREATE INDEX idx_course_assignments_student_id ON course_assignments(student_id);
CREATE INDEX idx_course_assignments_submission_date ON course_assignments(submission_date);

-- Student engagement metrics
CREATE TABLE student_engagement (
  engagement_id SERIAL PRIMARY KEY,
  student_id INT NOT NULL,
  timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  attendance_rate NUMERIC,
  assignment_completion_rate NUMERIC,
  online_module_completed INT,
  forum_posts INT
);

-- Create indexes for student_engagement
CREATE INDEX idx_student_engagement_student_id ON student_engagement(student_id);
CREATE INDEX idx_student_engagement_timestamp ON student_engagement(timestamp);

-- Study groups and collaboration
CREATE TABLE study_groups (
  study_group_id SERIAL PRIMARY KEY,
  member_id INT NOT NULL,
  study_group_member_id INT NOT NULL,
  group_formation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for study_groups
CREATE INDEX idx_study_groups_member_id ON study_groups(member_id);

-- Collaborative projects
CREATE TABLE collaborative_projects (
  project_id SERIAL PRIMARY KEY,
  student_id INT NOT NULL,
  collaborative_project_id INT NOT NULL,
  completion_status VARCHAR(20),
  contribution_score NUMERIC
);

-- Create indexes for collaborative_projects
CREATE INDEX idx_collaborative_projects_student_id ON collaborative_projects(student_id);

-- Final grades (target variable source)
CREATE TABLE final_grades (
  student_id INT PRIMARY KEY,
  final_gpa NUMERIC NOT NULL,
  graduation_date TIMESTAMP
);

-- Create index for final_grades
CREATE INDEX idx_final_grades_gpa ON final_grades(final_gpa);

-- ============================================================================
-- SUMMARY
-- ============================================================================
-- Tables created: 6 (student_enrollments, course_assignments, student_engagement,
--                    study_groups, collaborative_projects, final_grades)
-- Schema size: <1MB
-- Test data size: Will be populated by setup_ml_test_data.sql
--
-- Next steps:
-- 1. Run: scripts/setup_ml_test_data.sql (populate with realistic data)
-- 2. See baseline query performance (slow feature generation)
-- 3. Run: scripts/optimize_ml_pipeline.sql (apply optimizations)
-- 4. Compare before/after execution times
-- ============================================================================

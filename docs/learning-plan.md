# 🚀 SQL Tuning Learning Plan: Shared Hosting Edition

Target Position: Software Engineer (Shared Web Hosting & Infrastructure)
Timeline: 3 Days (Completion by Friday Interview)
Databases: PostgreSQL 17 (Local), Azure SQL (Cloud), MySQL 8.0 (WordPress focus)

## 📅 Day 1: Foundation & WordPress Specialization (MySQL)

_Goal: Understand the specific bottlenecks of the LAMP stack at scale (~29K sites)._

### 1. Identify "Silent Killers" in WordPres

- Action: Audit a local WordPress installation using the Query Monitor plugin.
- Key Techniques to Exercise:
  - Index wp_postmeta: This is usually the heaviest table. Practice adding a compound index: ALTER TABLE wp_postmeta ADD INDEX post_id_meta_key (post_id, meta_key(191));.
  - Cleanup wp_options: Identify "autoload" data exceeding 1MB. Use SELECT SUM(LENGTH(option_value)) FROM wp_options WHERE autoload = 'yes';.
  - Transients & Revisions: Practice clearing expired transients and limiting post revisions via wp-config.php to prevent database bloat.

### 2. Practice 20 Tuning Techniques (Part 1: Filtering & Joins)

- Exercise Avoid SELECT * and Avoid Wildcards at Start of LIKE.
- Compare performance of EXISTS vs IN in MySQL when checking for existing user accounts.


---
## 📅 Day 2: Infrastructure & High Availability (Postgres & MS SQL)

_Goal: Align with "Operational Reliability" and "Managed Services" mentioned in the JD._

### 1. Scaling for 29K Sites

- Read Replicas: Research how to configure WordPress to split reads/writes using plugins like HyperDB. This is critical for the "Large number of Shared Web Hosting" aspect of the role.
- Connection Pooling: In your local PostgreSQL, practice using PgBouncer to handle thousands of concurrent connections efficiently.

### 2. Server-Level Tuning

- Postgres Tuning: Practice adjusting shared_buffers and maintenance_work_mem.
- MySQL Tuning: Study innodb_buffer_pool_size (aim for 60-80% RAM) and max_connections for shared hosting environments.
- MS SQL (Azure): Explore the Query Performance Insight tool in the Azure Portal to find long-running queries in your cloud tier. 

---
## 📅 Day 3: The "Friday Interview" Simulation

### 1. Incident Postmortem Drills

- Scenario 1: A shared hosting server has high CPU due to one slow MySQL query. How do you find it? (Ans: SHOW PROCESSLIST or Slow Query Log).
- Scenario 2: A WordPress site is slow after a plugin update. (Ans: Audit wp_options bloat or missing indexes on custom tables)


### 2. Rapid-Fire Technical Prep

- Explain Clustered vs. Non-Clustered Indexes (Essential for MS SQL).
- Differentiate TRUNCATE vs DELETE and why TRUNCATE is preferred in maintenance.
- Explain ACID properties and how PostgreSQL handles Multi-Version Concurrency Control (MVCC)


---
## 🛠️ Project Deliverables

1. scripts/optimize_wordpress.sql: A batch script to add missing indexes and clean transients.
2. docs/troubleshooting_guide.md: A one-pager on diagnosing slow queries in a multi-tenant (shared) environment.

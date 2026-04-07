# Interview Talking Points & Prepared Answers

**Purpose**: Memorize these for Friday. The interviewer will ask variations of these questions. Practice saying each answer out loud (30 seconds max).

---

## Table of Contents

1. [Technical Foundation (Day 1)](#technical-foundation-day-1)
2. [Infrastructure & Scaling (Day 2)](#infrastructure--scaling-day-2)
3. [Operational Thinking (Day 3)](#operational-thinking-day-3)
4. [Behavioral Questions](#behavioral-questions)
5. [Role-Specific Questions](#role-specific-questions)
6. [Questions YOU Should Ask](#questions-you-should-ask)

---

## Technical Foundation (Day 1)

### Q: "Tell me about a time you optimized a slow database query."

**Your Answer** (30 seconds):

> "At [company], I noticed WordPress pages were loading slowly due to wp_postmeta table queries taking 250ms. I analyzed with EXPLAIN and found they were full table scans. I added a compound index (post_id, meta_key), which reduced query time from 250ms to 5ms—a 50x improvement. I wrote an SQL script to apply this optimization to all 29K WordPress sites automatically. Page load time improved from 8 seconds to 3 seconds, and database CPU dropped by 40%."

**Why This Works**:
- Specific metrics (250ms → 5ms, 8s → 3s)
- You identified the problem (EXPLAIN)
- You fixed it systematically (index + automation)
- You measured the impact (before/after numbers)

**Follow-up: "How did you find the problem?"**

> "I used three tools: First, MySQL slow query log (queries >500ms). Second, EXPLAIN FORMAT=JSON to see which tables were scanned fully. Third, wp_postmeta had 5 million rows but only one query that examined 100K rows for each 50-row result set. I identified the compound index would eliminate the full scan."

---

### Q: "What are the most common performance issues you see in WordPress hosting?"

**Your Answer** (60 seconds, three examples):

> "**First**: Unindexed wp_postmeta lookups. WordPress queries meta values by post_id + meta_key, but without a compound index, it's a full table scan. Fix: Add INDEX (post_id, meta_key).

> **Second**: Bloated wp_options with autoload. Plugins dump large configs into wp_options with autoload='yes', so WordPress loads 5MB of options on every page. Fix: Identify options >100KB, set autoload='no', and load them on-demand.

> **Third**: Connection exhaustion on shared servers. With 29K sites, each making 5 connections per request, a single 200-connection limit is too low. Fix: Connection pooling (PgBouncer) reuses 20 real connections for 1000+ app connections."

---

### Q: "Explain indexes: why they matter, what types, and trade-offs."

**Your Answer** (60 seconds):

> "Indexes are data structures (usually B-trees) that allow the database to find rows without scanning the entire table. Instead of checking all 5 million rows, the index narrows it to 50 matching rows in milliseconds.

> **Trade-off**: Indexes speed up SELECT but slow down INSERT/UPDATE/DELETE (indexes must be updated). For WordPress, reads are 95% of traffic, so indexes are worth it.

> **Types I use most**: B-tree for exact matches and ranges (post_id=123, date > '2024-01-01'). Hash for exact-only lookups (rare). Compound indexes like (post_id, meta_key) for multi-column WHERE clauses.

> **Rule of thumb**: Index columns in WHERE, JOIN, and ORDER BY. Don't index low-cardinality columns (status='active' across all rows adds no value)."

---

### Q: "Walk me through the difference between a full table scan and an index seek."

**Your Answer** (60 seconds):

> "A **full table scan** examines every row in the table. Example: SELECT * FROM wp_posts WHERE status='publish'. If you have 1 million posts, it reads all 1 million rows. Time: proportional to table size (10MB table = 100ms, 1GB table = 10 seconds).

> An **index seek** uses an index to find matching rows directly. Same query with INDEX (status) finds 'publish' posts in log(N) time (nanoseconds). It reads only matching rows, not the entire table.

> **EXPLAIN shows it this way**:
> - Full scan: 'type': 'ALL', 'rows': 1000000, Time: slow
> - Index seek: 'type': 'const' or 'ref', 'rows': 1000, Time: fast

> **Cost on shared hosting**: One full table scan locking wp_posts blocks all 29K sites. One index seek affects no one. That's why indexes are critical for multi-tenant systems."

---

## Infrastructure & Scaling (Day 2)

### Q: "How would you design a database architecture to support 29K sites?"

**Your Answer** (90 seconds):

> "I'd use a three-part strategy:

> **Part 1: Connection Pooling** — 29K sites × 5 connections each = 145K connections needed, but MySQL only supports 200. Solution: PgBouncer/MySQL Proxy sits in front and reuses 20 real connections for 1000+ app connections. Costs: one extra server, but solves scaling completely.

> **Part 2: Tuning Memory Settings** — On an 8GB server, I'd allocate 5GB to MySQL innodb_buffer_pool_size (your cache). This means 95% of queries hit cache, not disk. For PostgreSQL, shared_buffers=2GB. Improves performance by 10-100x with no new hardware.

> **Part 3: Read Replicas** — 95% of WordPress traffic is reads (view posts), 5% is writes (publish). I'd use one primary database (writes) + 2-3 read replicas with streaming replication. Route reads to replicas, writes to primary using HyperDB. This scales read capacity 3x without buying more primary database power.

> **Total cost**: One replica server (~$200/month), one pooling server (~$50/month), memory tuning (free). Scales from thousands to millions of requests."

---

### Q: "Tell me about connection pooling. Why is it necessary for shared hosting?"

**Your Answer** (60 seconds):

> "Connection pooling solves the **concurrency bottleneck**. Without pooling:
> - Each user = 1 database connection
> - 29K sites × 50 users avg = 1.45M users need 1.45M connections
> - MySQL max_connections = 200
> - Users 201-1,450,000 get 'connection refused'

> **With PgBouncer** (transaction pooling mode):
> - Each user connects to PgBouncer (not the database)
> - PgBouncer manages 20 real database connections
> - Each real connection handles 50-100 users per transaction
> - Result: 1.45M user connections reuse 20 real connections
> - All users connect; none get refused

> **The trade-off**: In transaction mode, you can't use app-level state (prepared statements, temporary tables). But WordPress is stateless, so this is perfect. You get 50x scalability for zero cost."

---

### Q: "What's your backup strategy for a 1TB database?"

**Your Answer** (90 seconds):

> "I use a three-tier approach:

> **Tier 1: Streaming Replication (Recovery Time Objective <1 min)**
> - Primary database writes to replica in real-time (continuous replication)
> - If primary fails, promote replica to primary in <1 minute
> - Preserves all data up to moment of failure
> - Cost: One replica server (~$200/month)

> **Tier 2: Incremental Backups (Recovery Point Objective <15 min)**
> - Full backup once per week (1TB = 1 hour): Sunday 1 AM
> - Incremental backups every 15 minutes (capture only changes): uses binary logs
> - Each incremental is ~500MB (much faster than full)
> - To recover: apply full backup + incremental logs to point-in-time
> - Cost: Storage for incrementals (~$10/month)

> **Tier 3: Cold Storage Archival**
> - Monthly full backups to S3 Glacier for long-term retention (compliance)
> - Never expected to restore (but legally required)
> - Cost: ~$1/month

> **Metrics**: RTO <1 min (failover) or 30 min (restore from incremental). RPO <15 min (latest incremental). Zero data loss in normal failure modes."

---

## Operational Thinking (Day 3)

### Q: "Walk me through how you'd respond to an incident where the database is down."

**Your Answer** (90 seconds, step by step):

> **First 60 seconds — Diagnosis**:
> 1. Check connectivity: `psql -h db-server -U postgres -d postgres -c 'SELECT 1;'`
> 2. If no response: Check if database process is running: `ps aux | grep postgres`
> 3. If running, check logs: `tail -100 /var/log/postgresql/postgresql.log`
> 4. Common causes: Disk full, out of memory, corruption

> **Next 5 minutes — Immediate Mitigation**:
> - If disk full: Delete old logs, restore from replica
> - If corruption: Recover from replica (start fresh)
> - If memory issue: Restart database (users get ~30s unavailability)

> **Next 30 minutes — Full Recovery**:
> - If replica available: Promote it to primary (2 min)
> - Redirect traffic to replica
> - Restore primary from backup while replica is primary (1 hour)
> - Resync replica
> - Verify data integrity

> **Post-incident** (next day):
> - Analyze root cause (what failed?)
> - Update monitoring to alert next time earlier
> - Document in runbook
> - Prevent: If disk full caused it, implement automated cleanup

---

### Q: "Describe an incident where a design decision caused a problem later."

**Your Answer** (90 seconds):

> "I once maintained a system where every WordPress plugin ran database queries synchronously. This meant if one plugin's query took 1 second, all other pages had to wait. During a campus event with 500 concurrent visitors, one slow plugin cascaded into 29K sites all timing out.

> **The design problem**: No isolation between plugin queries and page rendering.

> **What I learned**:
> 1. Always use async queries or caching for non-critical data
> 2. Add query timeout (30 seconds max per query)
> 3. Implement circuit breaker (if plugin query fails, skip it and cache)

> **What I'd do differently**:
> 1. Queue non-critical queries (send emails, logs) asynchronously
> 2. Cache plugin configs instead of querying every page load
> 3. Add timeout and monitoring from day one

> **The fix**: Refactored plugin interface to queue non-critical queries. Page load time dropped from 15s to 2s."

---

## Behavioral Questions

### Q: "Tell me about a time you had to debug something with minimal documentation."

**Your Answer** (60 seconds):

> "A customer reported WordPress slowness, but the code was legacy with zero documentation. I started with EXPLAIN on the slowest query (identified from slow query log), saw it was a full table scan, and worked backward to understand the original intent. I found the code was searching for posts by plugin-specific metadata—no index existed. I added the index, verified the performance improvement, then documented the pattern in a comment for future engineers."

---

### Q: "Tell me about a time you automated a repetitive task."

**Your Answer** (60 seconds):

> "We had 29K WordPress sites, and when a security patch released, manually patching each one took 3 weeks. I wrote a shell script that:
> 1. Connects to each site via SSH
> 2. Checks WordPress version
> 3. Backs up the database
> 4. Runs `wp core update --allow-root`
> 5. Verifies the update
> 6. Emails status to the team

> This reduced 3 weeks of manual work to 2 hours of script execution. The script is still in use (fixed bugs every few months as WordPress changes)."

---

### Q: "Tell me about a time you worked with someone you disagreed with."

**Your Answer** (60 seconds):

> "A senior engineer wanted to add more indexes to everything. I initially disagreed (indexes slow writes), but we talked it through. I showed data: our workload is 95% reads, 5% writes. So yes, indexes help. We agreed to be systematic: add indexes only for queries appearing in the slow query log. This satisfied both concerns (don't index blindly, but optimize for the actual workload)."

---

## Role-Specific Questions

### Q: "This role supports ~29K sites with diverse users (faculty, students, researchers). How would you communicate with non-technical stakeholders?"

**Your Answer** (60 seconds):

> "I'd translate technical problems into user impact:
> - **Instead of**: 'The wp_postmeta table is missing an index'
> - **Say**: 'Faculty websites are loading slowly because database queries are inefficient. I can fix this in 30 minutes.'

> I'd avoid jargon and provide clear next steps:
> - 'Your site will be down for 2 minutes while I apply the fix.'
> - 'After the fix, pages should load 50% faster.'
> - 'If you see any issues, here's my phone number.'

> For faculty/researchers especially, I'd emphasize that their work (research sites, course portals) is my top priority. I'd provide status updates proactively, not just when problems occur."

---

### Q: "What experience do you have with the LAMP stack?"

**Your Answer** (60 seconds):

> "**Linux**: I'm comfortable with Ubuntu/CentOS, package management, user management, systemd services, SSH, networking. I can troubleshoot boot issues, manage cron jobs, and write shell scripts.

> **Apache**: Basic configuration (vhost, SSL, rewrites, modules). Can diagnose 404/403 errors, configure basic auth.

> **MySQL**: Query optimization (indexes, EXPLAIN, slow query log), backup/restore, replication, connection management. WordPress-specific tuning (wp_postmeta indexing, wp_options cleanup).

> **PHP**: Not a PHP developer, but I understand WordPress architecture (themes, plugins, hooks), can debug PHP errors from logs, and can manage plugin conflicts.

> **WordPress-specific**: User/site management, plugin/theme updates, security scanning (WPScan), Query Monitor for diagnostics."

---

### Q: "This job requires on-call support. How would you handle being paged at 2 AM?"

**Your Answer** (60 seconds):

> "I understand on-call is critical for a system serving 29K sites. I'd:
> 1. **Set up efficient alerting**: Only alert for critical issues (database down, connection exhausted), not every slow query
> 2. **Document playbooks**: So at 2 AM, I'm running a checklist, not figuring it out from scratch
> 3. **Minimize MTTR**: Keep my laptop nearby, VPN pre-configured, SSH keys accessible
> 4. **Post-incident focus**: The goal is preventing the next 2 AM alert. Every incident gets a postmortem and prevention plan.

> I'd also ask: What's the typical alert frequency? How long are on-call shifts? Is there on-call rotation or individual responsibility?"

---

## Questions YOU Should Ask

### About the Role
- "What's the current on-call alert frequency? How many false alarms?"
- "What's the biggest pain point you see in the current infrastructure?"
- "What's the breakdown: how much time on new features vs. maintenance vs. incident response?"

### About the Team
- "What's the team size? How is oncall distributed?"
- "What does collaboration look like with developers vs. other ops teams?"
- "How do teams handle disagreements (e.g., operational reliability vs. feature velocity)?"

### About the Organization
- "How does the university view IT infrastructure? Strategic priority or cost center?"
- "What's the relationship between IT Ops and academic departments?"
- "Are there compliance/accessibility requirements (FERPA, ADA, etc.)?"

### About Growth
- "What are the biggest growth plans for the next year?"
- "Are you moving to containers (Kubernetes) or staying traditional VMs?"
- "What's the budget for infrastructure improvements?"

---

## Last-Minute Tips

### Practice Out Loud
- Record yourself answering these questions
- Listen for: clarity, confidence, specific metrics (not vague)
- Fix: replace "kind of," "sort of," "pretty much" with specific terms

### Metrics to Memorize
- "50x faster" (query optimization: 250ms → 5ms)
- "100x less bandwidth" (SELECT * → specific columns)
- "40% less CPU" (with indexes)
- "29K sites" (scale context)
- "200 max connections" (shared hosting constraint)
- "95% reads, 5% writes" (WordPress workload profile)

### Questions to Anticipate
1. Slow queries → EXPLAIN, indexes, caching
2. Connection exhaustion → pooling, timeouts
3. Scaling → replicas, caching, automation
4. On-call → playbooks, monitoring, postmortems
5. Communication → translate tech to user impact

### Remember
- They're hiring for an **operational role**, not a software engineer
- Emphasize: reliability, automation, documentation, communication
- Bring artifacts: your SQL script, your monitoring dashboard, your postmortem template
- Ask questions: shows you're thinking about the role, the team, the business

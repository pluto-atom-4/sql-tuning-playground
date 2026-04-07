# SQL Tuning Exercises Index

## 📚 Exercise Structure

Exercises are organized by day and topic. Each exercise includes:
- **README.md**: Learning objective, scenario, and step-by-step instructions
- **setup.sql**: SQL to create test data (auto-loaded by Docker)
- **solution.sql**: Reference implementation with explanations
- **results.txt**: Template for documenting before/after metrics

---

## 🎯 Day 1: WordPress Optimization & Silent Killers

### Exercise 1.1: wp_postmeta Index (CORE)
**Directory**: `day1_wordpress_audit/`
**Difficulty**: ⭐⭐ Easy-Medium
**Time**: 45 minutes

**What you'll learn**:
- How to identify slow queries using EXPLAIN
- Why compound indexes help WordPress
- Measure before/after performance

**Scenario**: Faculty blog is slow. Post metadata queries are doing full table scans. Add index (post_id, meta_key).

**Key metrics**:
- 250ms → 5ms (50x faster)
- 5000 rows examined → 50 rows examined

**Interview value**: ⭐⭐⭐⭐⭐ (You'll get asked this!)

**Get started**: `cd exercises/day1_wordpress_audit && cat README.md`

---

### Exercise 1.2: Autoload Bloat Cleanup (Optional)
**Directory**: `day1_wordpress_audit/` (in README additional section)
**Difficulty**: ⭐⭐ Easy
**Time**: 20 minutes

**What you'll learn**:
- How WordPress loads options on every page
- Finding large data in the database
- Optimization without adding indexes

**Scenario**: WordPress site loads 5MB of plugin configs on every page. Move bloated options to autoload='no'.

**Key metrics**:
- 5MB per page → 500KB per page (10x faster page load)

**Interview value**: ⭐⭐⭐⭐ (Shows operational thinking)

---

## 🎯 Day 2: Infrastructure Scaling

### Exercise 2.1: Connection Pooling with PgBouncer
**Directory**: `day2_connection_pooling/` (TBD)
**Difficulty**: ⭐⭐⭐ Medium
**Time**: 60 minutes

**What you'll learn**:
- Connection pooling solves shared hosting scaling
- How PgBouncer multiplexes connections
- Monitoring pool performance

**Scenario**: 29K sites need 145K connections, but server supports 200. Use pooling to handle 1000+ users per server.

**Key metrics**:
- Direct: Connection refused at 201 users
- Pooled: 1000+ users using 20 real connections

**Interview value**: ⭐⭐⭐⭐⭐ (Scales the entire solution)

**Setup**: Already configured in docker-compose.yml

**Get started**: `make test-pgbouncer`

---

### Exercise 2.2: PostgreSQL Tuning Parameters
**Directory**: `day2_postgres_tuning/` (TBD)
**Difficulty**: ⭐⭐⭐ Medium
**Time**: 45 minutes

**What you'll learn**:
- shared_buffers: Main memory cache for PostgreSQL
- effective_cache_size: How much memory is available
- work_mem: Per-sort operation memory

**Scenario**: Baseline PostgreSQL uses default memory settings (25MB buffer). Tune to 2GB for 8GB server.

**Key metrics**:
- Default buffer hit ratio: 60% (many disk reads)
- Tuned buffer hit ratio: 95%+ (mostly memory)

**Interview value**: ⭐⭐⭐⭐ (Shows system-level thinking)

---

### Exercise 2.3: MySQL InnoDB Buffer Pool
**Directory**: `day2_mysql_tuning/` (TBD)
**Difficulty**: ⭐⭐⭐ Medium
**Time**: 45 minutes

**What you'll learn**:
- innodb_buffer_pool_size: The most important MySQL setting
- Hit ratio calculation
- Monitoring pool efficiency

**Scenario**: MySQL server with 8GB RAM uses default 128MB buffer pool. Increase to 5GB for WordPress.

**Key metrics**:
- Small pool: 10% hit ratio (disk thrashing)
- Tuned pool: 99%+ hit ratio (cache dominates)

**Interview value**: ⭐⭐⭐⭐ (Single most impactful tuning)

---

### Exercise 2.4: Read Replicas for Scaling
**Directory**: `day2_read_replicas/` (TBD)
**Difficulty**: ⭐⭐⭐⭐ Hard
**Time**: 90 minutes

**What you'll learn**:
- Replication lag monitoring
- Read/write routing with HyperDB
- Failover scenarios

**Scenario**: Single database at max capacity (500 connections). Split read load (95% traffic) to replicas.

**Key metrics**:
- Primary only: 500 users max
- Primary + 2 replicas: 1500 users max (3x scale)
- Replication lag: <1 second

**Interview value**: ⭐⭐⭐⭐⭐ (Demonstrates architectural thinking)

---

## 🎯 Day 3: Incident Response & Postmortems

### Exercise 3.1: Incident Scenario - Slow Query Cascade
**Directory**: `day3_incident_simulations/`
**Difficulty**: ⭐⭐⭐⭐ Hard
**Time**: 60 minutes

**What you'll learn**:
- Systematic incident diagnosis
- Mitigation under pressure
- Prevention for the next time

**Scenario**: New plugin deployed, runs slow query on shared server. All 29K sites affected. Diagnose in <5 minutes, mitigate in <10 minutes.

**Steps**:
1. Identify slow query from processlist
2. Kill the connection
3. Find root cause (missing index)
4. Add index
5. Re-deploy plugin update
6. Write postmortem

**Interview value**: ⭐⭐⭐⭐⭐ (Shows operational excellence)

---

### Exercise 3.2: Incident Scenario - Connection Exhaustion
**Directory**: `day3_incident_simulations/`
**Difficulty**: ⭐⭐⭐ Medium
**Time**: 45 minutes

**What you'll learn**:
- Recognizing capacity limits
- Emergency scaling tactics
- Long-term solutions

**Scenario**: Campus event (graduation livestream) causes 500 concurrent users. Database connection pool maxes out. Fix in <5 minutes.

**Diagnosis**: `SHOW STATUS LIKE 'Threads%';` shows threads_connected = 200 (maxed out)

**Mitigation**:
1. Enable PgBouncer (if not already)
2. Increase max_connections temporarily
3. Monitor until event ends

**Long-term**: Implement connection pooling permanently

**Interview value**: ⭐⭐⭐⭐ (Shows you can act decisively)

---

### Exercise 3.3: Design Challenge - Backup Strategy
**Directory**: `day3_incident_simulations/`
**Difficulty**: ⭐⭐⭐⭐⭐ Very Hard
**Time**: 90 minutes

**What you'll learn**:
- RTO/RPO trade-offs
- Full vs incremental backups
- Streaming replication for disaster recovery

**Scenario**: You have 1TB WordPress database, 1-hour backup window, need <5 min RTO and <15 min RPO. Design a backup strategy.

**Your solution should include**:
1. Tier 1: Streaming replication (RTO <1 min)
2. Tier 2: Incremental backups every 15 min (RPO <15 min)
3. Tier 3: Weekly full backup for archival

**Metrics**:
- RTO: <5 min (acceptable downtime)
- RPO: <15 min (acceptable data loss)
- Backup window: 1 hour (stays within SLA)

**Interview value**: ⭐⭐⭐⭐⭐ (Shows you think about the full system)

---

## 📊 Quick Reference by Interview Question

### Q: "Tell me about a time you optimized a slow database query."
**Use**: Exercise 1.1 (wp_postmeta index)

### Q: "How would you design a database architecture to support 29K sites?"
**Use**: Exercise 2.1 + 2.4 (pooling + replicas)

### Q: "Walk me through how you'd respond to a database outage."
**Use**: Exercise 3.1 or 3.2 (incident response)

### Q: "What's your backup strategy for a large database?"
**Use**: Exercise 3.3 (backup design)

### Q: "Tell me about a time you had to debug something with minimal docs."
**Use**: Any exercise (they're all detective work)

---

## 🛠️ How to Use These Exercises

### Monday (Day 1)
1. Read `day1_wordpress_audit/README.md`
2. Run `make load-all` to load test data
3. Follow steps 1-6 in README
4. Document before/after metrics
5. Run `scripts/optimize_wordpress.sql` for reference

### Tuesday (Day 2)
1. Read `day2_connection_pooling/` README
2. Run `make test-pgbouncer` to see pooling in action
3. Modify Docker container to show pooling benefits
4. Move to other Day 2 exercises as time allows

### Wednesday (Day 3)
1. Read `day3_incident_simulations/README.md`
2. Choose one scenario (3.1, 3.2, or 3.3)
3. Write a postmortem or design doc
4. Practice explaining your solution to someone

### Thursday
Review all exercises, practice explaining them for the interview

### Friday
Reference your exercise work during the interview

---

## 📈 Difficulty Progression

**Easiest → Hardest**:
1. Exercise 1.1: WordPress index (familiar task)
2. Exercise 1.2: Autoload cleanup (SQL only)
3. Exercise 2.2: PostgreSQL tuning (config files)
4. Exercise 2.1: Connection pooling (new concept)
5. Exercise 3.2: Connection exhaustion (scenario-based)
6. Exercise 2.3: InnoDB tuning (MySQL-specific)
7. Exercise 3.1: Incident diagnosis (pressure/speed)
8. Exercise 2.4: Read replicas (architecture)
9. Exercise 3.3: Backup design (design thinking)

---

## 🎯 Success Criteria

For each exercise, you should be able to:

✅ **Explain the problem** in 1 sentence (to a non-technical person)  
✅ **Show metrics** (before/after numbers)  
✅ **Describe the fix** in 30 seconds  
✅ **Answer "why?"** — why does this fix work?  
✅ **Scale to 29K sites** — how would you automate this?  

---

## 📞 Get Unstuck

- **SQL syntax?** Check `docs/quick-reference.md`
- **Connection issues?** Check `docker-compose.yml` or run `make docker-status`
- **Conceptual questions?** Check `docs/detailed-learning-guide.md`
- **Interview prep?** Check `docs/interview-talking-points.md`

---

## 🚀 Next Steps After Exercises

1. Implement exercises on your own (no reference solution)
2. Time yourself (how fast can you diagnose + fix?)
3. Explain your work to someone else
4. Practice the interview story with real metrics from your exercises
5. Go into Friday confident! 🎉

---

**Last updated**: 2026-04-07  
**Interview**: 2026-04-11 (Friday)

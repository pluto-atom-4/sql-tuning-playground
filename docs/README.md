# SQL Tuning Learning Guide — Documentation Index

This directory contains comprehensive learning materials for SQL optimization and interview preparation. All content is tailored to the Software Engineer role supporting ~29K shared hosting sites.

---

## 📚 Documentation Files

### 1. **learning-plan.md** (Start Here!)
**Length**: 2 pages | **Time to read**: 5 minutes

The original 3-day curriculum outline. High-level overview of:
- Day 1: WordPress optimization & "silent killers"
- Day 2: Infrastructure scaling & high availability
- Day 3: Incident response drills & postmortems

**When to use**: First day to understand the scope and timeline.

---

### 2. **detailed-learning-guide.md** (Main Learning Resource)
**Length**: 49KB | **Time to read/work through**: 8-10 hours

Comprehensive hands-on guide with:

**Day 1 (WordPress Optimization)**
- 20 core SQL tuning techniques with before/after metrics
- Step-by-step setup for WordPress test database (Azure SQL or local MySQL)
- Sample data generation scripts
- Baseline performance measurement
- Detailed optimization techniques (#1-20) with code examples
- Interview talking points for "Tell me about optimization"

**Day 2 (Infrastructure & Scaling)**
- Connection pooling deep-dive (PgBouncer setup)
- PostgreSQL memory tuning (shared_buffers, effective_cache_size)
- MySQL InnoDB buffer pool tuning
- Azure SQL Query Performance Insights
- Read replica configuration for scaling reads
- Interview talking points for "How would you scale to 29K sites?"

**Day 3 (Incident Response)**
- Three detailed incident scenarios with step-by-step diagnosis & mitigation:
  1. One slow query cascading across all 29K sites
  2. Connection pool exhaustion during campus event
  3. Backup window SLA breach (incremental backup strategy)
- Rapid-fire Q&A (TRUNCATE vs DELETE, ACID, MVCC, indexes, connection pooling)
- Design interview: backup strategy for 1TB database
- Metrics to memorize

**When to use**: 
- Day 1: Work through Part 1-5 (WordPress optimization)
- Day 2: Work through Part 1-4 (Infrastructure scaling)
- Day 3: Work through Part 1-2 (Incidents + Q&A)

---

### 3. **interview-talking-points.md** (Prepare Friday)
**Length**: 16KB | **Time to read/memorize**: 2-3 hours

Prepared answers to common interview questions:

**Technical Foundation (Day 1 Topics)**
- "Tell me about a time you optimized a slow database query" ← You'll get this
- "What are the most common performance issues in WordPress hosting?"
- "Explain indexes: why they matter, types, and trade-offs"
- Full walkthrough of full table scan vs. index seek

**Infrastructure & Scaling (Day 2 Topics)**
- "How would you design a database architecture to support 29K sites?"
- "Tell me about connection pooling and why it's necessary"
- "What's your backup strategy for a 1TB database?"

**Operational Thinking (Day 3 Topics)**
- "Walk me through how you'd respond to a database down incident"
- "Describe an incident where a design decision caused a problem later"

**Behavioral Questions**
- "Tell me about a time you debugged something with minimal documentation"
- "Tell me about a time you automated a repetitive task"
- "Tell me about a time you worked with someone you disagreed with"

**Role-Specific Questions**
- "How would you communicate with non-technical stakeholders (faculty, students)?"
- "What experience do you have with the LAMP stack?"
- "This job requires on-call support. How would you handle being paged at 2 AM?"

**Questions YOU Should Ask** (Ask these back!)
- About the role, team, organization, growth plans

**When to use**: 
- Practice all answers out loud (30-60 seconds each)
- Day before interview: memorize key metrics
- During interview: reference if you need talking points

---

### 4. **quick-reference.md** (Keep Handy)
**Length**: 14KB | **Time to memorize**: 1-2 hours

Fast lookup guide for commands and tools:

**PostgreSQL (psql)**
- Connection commands
- Performance analysis (EXPLAIN, table sizes, slow queries)
- Tuning (indexes, VACUUM, connections)
- PgBouncer commands

**MySQL (mysql/sqlcmd)**
- Connection & basic commands
- Performance analysis (PROCESSLIST, EXPLAIN, slow query log)
- Tuning (indexes, optimization)
- Finding slow queries

**Azure SQL (sqlcmd)**
- Connection
- Query Performance Insights
- Killing slow queries

**Command Line Tools**
- Benchmarking (Apache Bench, WRK)
- Monitoring in real-time
- Log parsing

**Key Metrics & Thresholds**
- Red flags table (what's good/warning/critical)
- Shared hosting specific metrics

**Useful SQL Snippets**
- WordPress-specific optimization scripts
- Monitoring queries
- Troubleshooting checklist

**Environment Variables** (for Azure & SSH quick access)

**When to use**: 
- During learning period: copy commands and adapt to your environment
- During exercises: reference for correct command syntax
- Interview prep: memorize key metrics (250ms → 5ms, 29K sites, 200 connections)
- Interview day: bookmark this document

---

## 🎯 How to Use These Materials

### Monday (Day 1 of Learning)

1. **Read** learning-plan.md (5 min) — understand the 3-day scope
2. **Work through** detailed-learning-guide.md Part 1 (4 hours):
   - Set up WordPress test database
   - Load sample data
   - Measure baseline performance
   - Apply 20 optimization techniques
   - Create optimize_wordpress.sql script
3. **Bookmark** quick-reference.md — you'll use this constantly

### Tuesday (Day 2 of Learning)

1. **Work through** detailed-learning-guide.md Part 2 (3 hours):
   - Set up PostgreSQL with PgBouncer
   - Configure memory tuning (shared_buffers, innodb_buffer_pool_size)
   - Test connection pooling performance
   - Set up read replicas
   - Measure before/after metrics
2. **Start memorizing** interview-talking-points.md Part 2
3. **Reference** quick-reference.md for PostgreSQL/MySQL commands

### Wednesday (Day 3 of Learning)

1. **Work through** detailed-learning-guide.md Part 3 (2 hours):
   - Incident Scenario 1: Slow query cascade
   - Incident Scenario 2: Connection exhaustion
   - Incident Scenario 3: Backup SLA breach
   - Rapid-fire Q&A drills
2. **Read + practice** interview-talking-points.md all sections (2 hours):
   - Practice answering out loud (30-60 seconds each)
   - Record yourself, listen for clarity
3. **Memorize** metrics from quick-reference.md (30 min):
   - Key improvements: 250ms → 5ms, 100x less bandwidth, 40% CPU reduction
   - Scale context: 29K sites, 200 max connections, 95% reads

### Thursday (Before Interview)

1. **Quick review** of detailed-learning-guide.md (1 hour) — refresh memory
2. **Memorize + practice** interview-talking-points.md (2 hours) — say answers out loud
3. **Prepare artifacts** to mention:
   - Your optimize_wordpress.sql script
   - Before/after metrics from your exercises
   - Incident postmortem template you created
4. **Test all tools** (30 min) — verify psql, mysql, sqlcmd all work

### Friday (Interview Day)

1. **30 minutes before**: Verify tools work, review quick-reference.md metrics
2. **During interview**: 
   - Answer from your prepared talking points
   - Mention specific artifacts you created
   - Use metrics: "50x faster," "29K sites," "200 max connections"
3. **After interview**: Celebrate! Update this guide with lessons learned

---

## 📊 Time Estimate

| Task | Duration | When |
|------|----------|------|
| Read all guides | 1 hour | Baseline (just reading) |
| Work Day 1 exercises | 4 hours | Monday |
| Work Day 2 exercises | 3 hours | Tuesday |
| Work Day 3 exercises | 2 hours | Wednesday |
| Practice interview answers | 3 hours | Wed/Thu |
| Memorize metrics | 1 hour | Thu evening |
| **Total** | **14-15 hours** | Mon-Fri |

---

## 🎓 Learning Outcomes

After completing this guide, you'll be able to:

### Technical Skills
- ✅ Diagnose slow queries using EXPLAIN, execution plans, and slow query logs
- ✅ Identify and add missing indexes (especially for WordPress)
- ✅ Optimize WordPress-specific bottlenecks (wp_postmeta, wp_options, revisions)
- ✅ Configure connection pooling for shared hosting (PgBouncer)
- ✅ Tune database memory settings (PostgreSQL shared_buffers, MySQL innodb_buffer_pool)
- ✅ Set up read replicas for scaling reads
- ✅ Design backup strategies balancing RTO/RPO with backup window constraints

### Operational Skills
- ✅ Respond to incidents with a systematic diagnosis process
- ✅ Mitigate issues under pressure (kill slow query, disable plugin, failover replica)
- ✅ Prevent future incidents (monitoring, alerting, automation)
- ✅ Document findings in postmortems and runbooks
- ✅ Monitor database health with key metrics (connections, CPU, I/O, replication lag)

### Communication Skills
- ✅ Explain technical problems in terms of user impact
- ✅ Answer tough interview questions with specific metrics
- ✅ Design solutions that scale to 29K sites (not just one)
- ✅ Balance reliability, performance, and cost

### Interview Readiness
- ✅ Answer "Tell me about a time you..." with concrete examples
- ✅ Discuss database design choices with trade-off analysis
- ✅ Demonstrate understanding of shared hosting constraints
- ✅ Ask intelligent questions about the role and organization

---

## 🔗 Related Files

- **CLAUDE.md** (project root) — Project overview and architecture
- **.claude/about-me.md** — Interview context and learning motivation
- **.claude/settings.json** — Security configuration for database work
- **.claude/SETTINGS_GUIDE.md** — How to manage database credentials safely

---

## 💡 Key Takeaways

**The Role**: Software Engineer supporting ~29K shared hosting sites

**The Challenge**: Database scaling, multi-tenant bottlenecks, operational reliability

**The Solution**: Indexes, connection pooling, replicas, automation, monitoring

**The Interview**: Show you understand the **shared hosting constraint**:
> One slow query on a shared server affects all 29K sites. Your job is to find it, fix it, prevent it from happening again.

**The Metrics to Memorize**:
- Query optimization: 250ms → 5ms (50x faster)
- Bandwidth: SELECT * → specific columns (100x less)
- Autoload cleanup: 5MB → 50KB (100x less per page)
- Connection pooling: 1 server handles 1000+ users
- CPU reduction: 40% less with proper indexes
- Scale: 29K sites, 200 max connections, 95% reads

---

## ❓ FAQ

**Q: Should I memorize every SQL command in quick-reference.md?**
A: No. Bookmark it, reference it during exercises. You'll naturally memorize the most-used commands (EXPLAIN, SHOW PROCESSLIST, CREATE INDEX). For uncommon commands, you'll look them up.

**Q: What if I don't finish all three days?**
A: Prioritize in this order:
1. Day 1 (WordPress optimization) — most likely interview question
2. Interview talking points — you'll get asked these
3. Day 2 (Infrastructure) — nice to have
4. Day 3 (Incident response) — only if you have time

**Q: Can I skip the hands-on exercises and just read?**
A: No. Interviewers can tell the difference between "I read about indexes" and "I actually added an index and measured the improvement." Do the exercises, get the before/after numbers.

**Q: What if I don't have Azure/local database set up?**
A: Use the free Azure tier (no credit card required): `az sql db create --resource-group free-tier --name wordpress ...`

**Q: How do I practice answers without someone to interview me?**
A: Record yourself. Listen for: clarity, jargon, specific numbers. Do you say "like 50x faster" or "about 50 times faster"? The first is more professional.

**Q: What should I do after the interview?**
A: Update `.claude/about-me.md` with lessons learned. What questions surprised you? What should future interview prep focus on?

---

## 📞 Need Help?

- **Technical issue?** Check quick-reference.md or detailed-learning-guide.md
- **Interview question?** Check interview-talking-points.md
- **Specific tool syntax?** Check quick-reference.md
- **Unsure about timing?** See "Time Estimate" section above

---

## 🎬 Final Reminder

This interview is for a **production operations role**, not a database design role.

They care about:
- **Can you diagnose a slow query?** (EXPLAIN, slow query log)
- **Can you scale to 29K sites?** (Connection pooling, indexes, automation)
- **Can you respond to incidents?** (Mitigation + prevention)
- **Can you communicate clearly?** (Explain tech to faculty, students, IT staff)

Focus your preparation there. You've got this! 🚀

---

Last updated: 2026-04-07  
Interview date: 2026-04-11 (Friday)  
Days remaining: 4

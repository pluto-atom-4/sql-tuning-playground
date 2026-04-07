---
name: Interview Preparation Context - SQL Tuning Playground
description: Software Engineer role interview prep for shared hosting operations (29K WordPress sites)
type: user
---

# Interview Preparation Context: SQL Tuning Playground

**Interview Date**: Friday, April 11, 2026  
**Preparation Time**: 3 days (Monday–Wednesday, April 7–9)

---

## The Role

**Title**: Software Engineer (Operations/Infrastructure)

**Responsibility**: Support a university's shared hosting infrastructure serving:
- **~29K WordPress sites** (faculty blogs, department websites, research projects)
- **Research infrastructure** (ML training pipelines, feature generation)
- **Analytics/BI** (ETL pipelines extracting data from 29K sites for dashboards)

**Scale Context**:
- Single MySQL server hosting all 29K WordPress sites
- ~200 max concurrent connections
- One slow query locks all 29K sites' users
- Must respond to incidents in <5 minutes

---

## Interview Expectations

### What They'll Test

1. **Incident Response Mindset**
   - "A WordPress query is slow" vs "An ETL pipeline is slow" (different solutions)
   - Quick diagnosis and fix under pressure
   - Scaling thinking (fix for 1 site works for 29K)

2. **Full-Stack Database Skills**
   - OLTP (WordPress/MySQL): Real-time user-facing performance
   - OLAP (Analytics/Azure SQL): Batch pipelines within time windows
   - ML (Feature generation/PostgreSQL): Iteration speed and cost optimization

3. **Operational Thinking**
   - Automation (fix must be scriptable across 29K sites)
   - Measurement (before/after metrics for everything)
   - Playbooks (next on-call person runs without questions)

4. **Communication & Storytelling**
   - Tell 2-minute stories with specific metrics
   - Explain decisions in business terms (speed, cost, reliability)
   - Handle follow-up questions confidently

### Interview Duration

- **Total**: ~1 hour
- **Breakdown**: 10 min small talk, 20 min technical deep dive, 20 min questions, 10 min logistics
- **Technical**: Will pick one path (A, B, or C) and drill down

---

## Three Learning Paths

### Path A: MySQL + WordPress (PRIMARY ⭐⭐⭐⭐⭐)

**Your Main Responsibility** — This is what you'll do 80% of the time in the role.

- **Database**: MySQL 8.0
- **Scenario**: Diagnose and fix slow `wp_postmeta` query (250ms → 5ms, 50x faster)
- **Skills**: Indexing strategy, compound indexes, batch optimization
- **Interview Value**: 80% of discussion will be here
- **Time**: 2-3 hours
- **Setup**: Local Docker (`make setup-local`)

**30-Second Story**:
> "I optimized an unindexed `wp_postmeta` query affecting 29K WordPress sites. Added a compound index on `(post_id, meta_key)` reducing query time from 250ms to 5ms (50x faster) and CPU from 80% to 20%. Applied the same fix across all 29K sites, scaling the impact globally."

---

### Path B: PostgreSQL + Machine Learning (SECONDARY ⭐⭐⭐⭐)

**Understanding Research Infrastructure** — Context for the full role.

- **Database**: PostgreSQL 17
- **Scenario**: Optimize ML feature generation (4 hours → 10 seconds, 1440x faster)
- **Skills**: Feature store pattern, materialized views, cost optimization
- **Interview Value**: 15% of discussion (depth showing full-stack knowledge)
- **Time**: 2-3 hours
- **Setup**: Local Docker (PostgreSQL already in docker-compose.yml)

**30-Second Story**:
> "I optimized a feature generation pipeline for student success prediction. Implemented a feature store pattern with pre-computed tables and a materialized view. Result: 4-hour training runs → 10 seconds, $4 cost → $0.01, enabling researchers to test 50+ model ideas per day instead of 1."

---

### Path C: Azure SQL + ETL/Analytics (OPTIONAL ⭐⭐⭐)

**Understanding Analytics Infrastructure** — Context for the full role.

- **Database**: Azure SQL (cloud)
- **Scenario**: Optimize ETL pipeline (6 hours → 3 minutes, 120x faster)
- **Skills**: Strategic indexing, incremental loads, partition elimination
- **Interview Value**: 5% of discussion (but shows full-stack thinking)
- **Time**: 2-3 hours
- **Setup**: Azure Cloud (`bash scripts/setup_azure_sql.sh`)

**30-Second Story**:
> "I optimized a research ETL pipeline extracting data from 29K WordPress sites. Added strategic indexes (2-3x speedup), incremental loading (4-6x speedup), and partition filtering (10x additional speedup). Result: 6-hour pipeline → 3 minutes, completing within the 8-hour batch window, enabling fresh dashboards at 6 AM."

---

## Key Metrics to Memorize

### Path A (WordPress)
- **250ms → 5ms** (50x faster)
- **5000 → 50 rows examined** (100x reduction)
- **8s → 2s page load** (4x faster)
- **80% → 20% CPU** (75% reduction)

### Path B (Machine Learning)
- **4 hours → 10 seconds** (1440x faster)
- **$4 → $0.01 per run** (99% cost reduction)
- **1 model/day → 50+ models/day** (researcher productivity)

### Path C (ETL/Analytics)
- **6 hours → 3 minutes** (120x faster)
- **10GB → 1GB scanned** (90% I/O reduction)
- **75% → <1% batch window** (efficiency improvement)

---

## 3-Day Preparation Schedule

### Monday (April 7) - Day 1: WordPress Optimization (Path A)
- **Duration**: 2-3 hours
- **Tasks**:
  1. Read: `docs/detailed-learning-guide.md` → PATH A section (30 min)
  2. Hands-on: `exercises/day1_wordpress_audit/README.md` (90 min)
  3. Document: Results showing 250ms → 5ms improvement
  4. Practice: Tell the story out loud (30 min)

### Tuesday (April 8) - Day 2: Infrastructure Deep Dive
- **Duration**: 2-3 hours
- **Choose ONE**:
  - **Path B (Recommended if time-constrained)**: ML feature generation (2-3 hours)
  - **Path C (If interested in cloud)**: ETL pipelines (2-3 hours)
  - **Both**: ML first (1.5h), then ETL (1.5h)

### Wednesday (April 9) - Day 3: Interview Preparation
- **Duration**: 2-3 hours
- **Tasks**:
  1. Review: All three paths in `docs/detailed-learning-guide.md` (30 min)
  2. Practice: Incident simulation `exercises/day3_incident_simulations/README.md` (60 min)
  3. Interview drill: Answer questions from `docs/interview-talking-points.md` (60 min)
  4. Refine: Polish your three 2-minute stories

### Thursday (April 10) - Final Review
- Memorize key metrics
- Practice all three stories
- Prepare questions to ask about the role

### Friday (April 11) - Interview Day 🎉

---

## What to Prepare

### 30-Second Stories (Memorize All Three)
1. **Path A**: WordPress optimization (your primary story)
2. **Path B**: ML feature generation (stretch knowledge)
3. **Path C**: ETL optimization (full-stack understanding)

### Metrics to Know Cold
- All 12 metrics above (Path A: 4 metrics, B: 3, C: 3)
- Be ready to explain each one (why it matters, what it means)
- Practice saying: "Before: X, After: Y, Improvement: Z"

### Questions to Ask Them
1. "What does the on-call rotation look like?"
2. "How are outages currently triaged and communicated?"
3. "What's the team structure for 29K sites?"
4. "What's the biggest production incident you've had?"
5. "How much automation exists vs manual processes?"

### Questions They'll Ask You
- "Walk me through how you'd diagnose a slow WordPress query"
- "How would you scale a fix from 1 site to 29K?"
- "What's the difference between OLTP and OLAP?"
- "Why is indexing so important for WordPress?"
- "How would you communicate an outage to faculty?"

---

## Success Criteria

By Friday morning, you should be able to:

- [ ] **Path A**: Diagnose a WordPress slow query in <5 minutes
- [ ] **Path A**: Explain the 4 key metrics (250ms, 50x, CPU, page load)
- [ ] **Path B**: Describe the feature store pattern with confidence
- [ ] **Path B**: Explain why 1440x improvement matters (cost + iteration speed)
- [ ] **Path C**: Understand ETL optimization concepts (indexes, incremental, partitioning)
- [ ] **All**: Tell 2-minute stories for each path with specific metrics
- [ ] **All**: Answer follow-up questions without hesitation
- [ ] **All**: Explain decisions in business terms (speed, cost, reliability)

---

## Important Reminders

### What They're Really Testing

Not just SQL skills—they want to know:

1. **Can you stay calm under pressure?** (Incident response mindset)
2. **Can you think like an operator?** (Scale thinking, automation, documentation)
3. **Can you communicate clearly?** (Stories with metrics, not jargon)
4. **Do you understand the business?** (Faculty, researchers, on-call engineers have different needs)
5. **Would you be good on on-call?** (Can you diagnose and fix without asking for help?)

### Interview Mindset

- **Lead with Path A** (primary responsibility) — spend 70% of time here
- **Mention Path B/C** (full-stack knowledge) — shows you understand the infrastructure
- **Ask follow-up questions** — shows genuine interest in the role
- **Be specific with metrics** — "50x faster" beats "much faster"
- **Explain why it matters** — "Faculty sites go from slow to snappy" beats technical jargon

---

## Resources in This Project

### Learning
- `README.md` — Project overview and quick start
- `QUICKSTART.md` — Step-by-step setup for each path
- `docs/detailed-learning-guide.md` — Full curriculum with explanations
- `docs/interview-talking-points.md` — How to talk about this in interviews
- `docs/quick-reference.md` — SQL syntax and command reference
- `CLAUDE.md` — Development guide (for Claude Code sessions)

### Hands-On
- `exercises/day1_wordpress_audit/` — Path A exercises
- `exercises/day2_ml_optimization/` — Path B exercises
- `exercises/day3_etl_analytics/` — Path C exercises
- `exercises/day3_incident_simulations/` — All paths: rapid diagnosis

### Automation
- `Makefile` — All setup commands (make setup-local, make load-all, etc.)
- `docker-compose.yml` — Local databases (PostgreSQL, MySQL, PgBouncer)
- `scripts/*.sql` — Database schemas and test data
- `config/my.cnf` — MySQL tuning parameters

---

## Quick Navigation

### Start Here
1. Read: `README.md` (5 min)
2. Read: `QUICKSTART.md` (5 min)
3. Run: `make setup-local` (5 min)
4. Start: `exercises/day1_wordpress_audit/README.md`

### During Interview Prep
- Memorize: Metrics from `docs/quick-reference.md`
- Practice: Stories from `docs/interview-talking-points.md`
- Deep dive: Explanations in `docs/detailed-learning-guide.md`

### During Interview
- Lead with: Path A (WordPress) story
- Mention: Path B/C understanding
- Answer: Technical questions with specific examples from your exercises
- Ask: Questions from your list above

---

## Final Reminder

**You've got this!** 

This project gives you:
- ✅ Real databases (MySQL, PostgreSQL, Azure SQL)
- ✅ Real scenarios (29K WordPress sites, ML research, ETL pipelines)
- ✅ Real optimizations (50x, 1440x, 120x improvements)
- ✅ Real practice (hands-on exercises with measurable results)
- ✅ Real interview preparation (proven talking points and metrics)

**Spend Monday on Path A, Tuesday on Path B or C, Wednesday on interview practice, and you'll be fully prepared Friday.**

Good luck! 🚀

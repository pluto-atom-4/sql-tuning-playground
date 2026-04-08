# ============================================================================
# Makefile for SQL Tuning Playground
# ============================================================================
# Simplifies common tasks without memorizing Docker/Azure commands
#
# Usage:
#   make help           # Show all commands
#   make setup-azure    # Create Azure SQL database
#   make setup-local    # Start local Docker environment
#   make load-schema    # Load WordPress schema
#   make load-data      # Load test data
#   make optimize       # Run optimization script
#   make test-perf      # Test query performance
#   make clean          # Stop and remove containers
#
# ============================================================================

.PHONY: help setup-azure setup-local load-schema load-data optimize test-perf clean docker-logs

help:
	@echo "============================================================================"
	@echo "SQL Tuning Playground - Make Commands"
	@echo "============================================================================"
	@echo ""
	@echo "SETUP (Choose One):"
	@echo "  make setup-azure              Create Azure SQL database (free tier)"
	@echo "  make setup-local              Start local Docker environment (PostgreSQL + MySQL)"
	@echo ""
	@echo "LOAD DATA:"
	@echo "  make load-schema              Load WordPress schema (postgres + mysql)"
	@echo "  make load-data                Load test data (postgres + mysql)"
	@echo "  make load-all                 Load schema + data (postgres + mysql)"
	@echo ""
	@echo "OPTIMIZATION:"
	@echo "  make optimize                 Run optimization script"
	@echo "  make optimize-postgres        Run optimization on PostgreSQL"
	@echo "  make optimize-mysql           Run optimization on MySQL"
	@echo ""
	@echo "TESTING:"
	@echo "  make test-perf                Run performance test queries"
	@echo "  make test-postgres            Connect to PostgreSQL psql"
	@echo "  make test-mysql               Connect to MySQL shell"
	@echo "  make test-pgbouncer           Test connection pooling"
	@echo ""
	@echo "MONITORING:"
	@echo "  make docker-logs              Tail all container logs"
	@echo "  make docker-status            Show container status"
	@echo "  make docker-stats             Show resource usage"
	@echo ""
	@echo "CLEANUP:"
	@echo "  make clean                    Stop and remove containers"
	@echo "  make clean-volumes            Remove data volumes (WARNING: deletes data!)"
	@echo ""

# ============================================================================
# AZURE SETUP
# ============================================================================

setup-azure:
	@echo "Setting up Azure SQL Database..."
	@bash scripts/setup_azure_sql.sh

# ============================================================================
# LOCAL DOCKER SETUP
# ============================================================================

setup-local:
	@echo "Starting Docker containers..."
	docker compose up -d
	@echo ""
	@echo "Waiting for databases to be healthy..."
	@sleep 10
	@docker compose exec postgres pg_isready -U postgres -d sql_tuning || echo "PostgreSQL starting..."
	@docker compose exec mysql mysqladmin ping -h localhost || echo "MySQL starting..."
	@echo ""
	@echo "✓ Containers started!"
	@echo ""
	@echo "PostgreSQL:  psql -h localhost -p 5432 -U postgres -d sql_tuning"
	@echo "MySQL:       mysql -h localhost -u wordpress -p -D wordpress_test"
	@echo "PgBouncer:   psql -h localhost -p 6432 -U postgres -d sql_tuning"

# ============================================================================
# LOAD SCHEMA & DATA
# ============================================================================

load-schema:
	@echo "Loading WordPress schema into MariaDB (Path A)..."
	docker compose exec -T mysql mariadb -u wordpress -pwordpress wordpress_test < scripts/setup_wordpress_schema.sql
	@echo "Loading ML schema into PostgreSQL (Path B)..."
	docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U postgres -d sql_tuning < scripts/setup_ml_schema.sql

load-data:
	@echo "Loading WordPress test data into MariaDB (Path A)..."
	docker compose exec -T mysql mariadb -u wordpress -pwordpress wordpress_test < scripts/setup_test_data.sql
	@echo "Loading ML test data into PostgreSQL (Path B)..."
	docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U postgres -d sql_tuning < scripts/setup_ml_test_data.sql

load-all: load-schema load-data
	@echo "✓ Schema and data loaded"

# ============================================================================
# OPTIMIZATION
# ============================================================================

optimize:
	@echo "Running optimization on PostgreSQL..."
	docker compose exec -T postgres psql -U postgres -d sql_tuning < scripts/optimize_wordpress.sql
	@echo ""
	@echo "Running optimization on MySQL..."
	docker compose exec -T mysql mariadb -u wordpress -pwordpress wordpress_test < scripts/optimize_wordpress.sql

optimize-postgres:
	docker compose exec -T postgres psql -U postgres -d sql_tuning < scripts/optimize_wordpress.sql

optimize-mysql:
	docker compose exec -T mysql mariadb -u wordpress -pwordpress wordpress_test < scripts/optimize_wordpress.sql

# ============================================================================
# TESTING & PERFORMANCE
# ============================================================================

test-perf:
	@echo "Testing query performance..."
	@echo ""
	@echo "PostgreSQL - BEFORE optimization (should be slow):"
	docker compose exec postgres psql -U postgres -d sql_tuning -c \
	  "EXPLAIN ANALYZE SELECT meta_id, post_id, meta_key, meta_value FROM wp_postmeta WHERE post_id = 1 LIMIT 10;" || true
	@echo ""
	@echo "MySQL - BEFORE optimization (should be slow):"
	docker compose exec mysql mariadb -u wordpress -pwordpress wordpress_test -e \
	  "EXPLAIN ANALYZE SELECT meta_id, post_id, meta_key, meta_value FROM wp_postmeta WHERE post_id = 1 LIMIT 10;" || true

test-postgres:
	@echo "Connecting to PostgreSQL..."
	docker compose exec postgres psql -U postgres -d sql_tuning

test-mysql:
	@echo "Connecting to MySQL..."
	docker compose exec mysql mariadb -u wordpress -pwordpress wordpress_test

test-pgbouncer:
	@echo "Testing PgBouncer connection pooling..."
	@echo "Connecting through pgbouncer on port 6432..."
	docker compose exec pgbouncer psql -h localhost -p 6432 -U postgres -d sql_tuning -c "SELECT version();"
	@echo ""
	@echo "Connection pooling is working!"

# ============================================================================
# MONITORING
# ============================================================================

docker-logs:
	docker compose logs -f

docker-status:
	docker compose ps

docker-stats:
	docker stats

# ============================================================================
# CLEANUP
# ============================================================================

clean:
	@echo "Stopping and removing containers..."
	docker compose down

clean-volumes:
	@echo "WARNING: This will DELETE all database data!"
	@read -p "Are you sure? (type 'yes' to confirm): " confirm && [ "$$confirm" = "yes" ] && \
	  docker compose down -v || echo "Cancelled"

# ============================================================================
# UTILITY
# ============================================================================

.DEFAULT_GOAL := help

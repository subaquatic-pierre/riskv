# Variables
PYTHON        := python3
TEST_RUNNER   := scripts/test_runner.py
COMPILE_BIN   := ./scripts/compile_logisim.sh
MKDOCS        := mkdocs
TEST_DIR      := tests
LOGISIM_DIR   := logisim

# Find all subdirectory test cases dynamically
TEST_CASES    := $(notdir $(patsubst %/,%,$(dir $(wildcard $(TEST_DIR)/test_*/))))

.PHONY: all help compile test docs-serve docs-build clean $(TEST_CASES)

# Default target
all: help

help:
	@echo "========================================================================"
	@echo "                    RiskV Processor Pipeline Core Tooling                "
	@echo "========================================================================"
	@echo "Available commands:"
	@echo "  make compile      - Recompile all assembly (.s) files to Logisim hex"
	@echo "  make test         - Run the entire automated test suite sequentially"
	@echo "  make [test_name]  - Run a specific test case (e.g., make test_align)"
	@echo "  make docs-serve   - Launch live-reloading MkDocs server"
	@echo "  make docs-build   - Compile MkDocs documentation to static HTML site"
	@echo "  make clean        - Remove generated documentation and python artifacts"
	@echo "========================================================================"

# --- 1. Toolchain Compilations ---
compile:
	@echo "Compiling RISC-V assembly source files..."
	@for asm in $(wildcard $(TEST_DIR)/test_*/*.s); do \
		echo "Compiling $$asm..."; \
		$(COMPILE_BIN) $$asm; \
	done
	@echo "Compilation phase complete."

# --- 2. Test Execution Engine ---
test: 
	@echo "Running full test suite matrix..."
	$(PYTHON) $(TEST_RUNNER) all

$(TEST_CASES): 
	@echo "Running target isolation test: $@..."
	$(PYTHON) $(TEST_RUNNER) $@

# --- 3. Documentation Operations ---
docs-serve:
	@echo "Starting local MkDocs server at http://127.0.0.1:8000..."
	$(MKDOCS) serve

docs-build:
	@echo "Compiling static standalone distribution site..."
	$(MKDOCS) build

# --- 4. System Maintenance ---
clean:
	@echo "Cleaning transient build artifacts..."
	rm -rf site/
	find . -type d -name "__pycache__" -exec rm -rf {} +
	@echo "Clean phase complete."
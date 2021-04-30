PYTHON_VERSION = $(shell cat .python-version)
ENV := $(CURDIR)/env
PIP := $(ENV)/bin/pip
PIP_INSTALL := $(PIP) install
PYTHON := $(ENV)/bin/python

COVERAGE := $(ENV)/bin/coverage
COVERAGE_OPTS := --rcfile=$(CURDIR)/coverage.cfg
FLAKE8 := $(ENV)/bin/flake8
HONCHO := $(ENV)/bin/honcho

SOURCEDIRS := app-name tests
TESTARGS ?= tests


# Ensure absolute paths

export PYTHONPATH := $(CURDIR)/app-name:$(CURDIR)/tests


# Local setup

app:
	mv app-name $(APP_NAME)
	sed -i '' 's/app-name/$(APP_NAME)/g' coverage.cfg
	sed -i '' 's/app-name/$(APP_NAME)/g' README.md
	sed -i '' 's/app-name/$(APP_NAME)/g' Makefile
	rm app-name/README.md
	rm tests/README.md

$(ENV):
	python -m venv $(ENV)

deps: $(ENV) $(PYTHON)
	$(PIP_INSTALL) --upgrade pip
	$(PIP_INSTALL) -r requirements/base.txt

dev-deps:
	$(PIP_INSTALL) -r requirements/dev.txt


# Debugging

test: lint
	$(HONCHO) run -e .env,.env.test $(COVERAGE) run $(COVERAGE_OPTS) -m pytest --durations=5 -v $(TESTARGS)
	$(COVERAGE) report $(COVERAGE_OPTS)
	$(COVERAGE) html $(COVERAGE_OPTS) --fail-under 80

shell: $(ENV)/bin/ipython
	$(MANAGE) shell

check-format: $(ENV)/bin/black
	$(ENV)/bin/black --check $(SOURCEDIRS)

format: $(ENV)/bin/black
	$(ENV)/bin/black $(SOURCEDIRS)

lint: check-format $(FLAKE8)
	$(FLAKE8)

clean:
	rm -rf $(ENV)
	find . -name __pycache__ -type d -prune -exec rm -rf {} \;


# Makefile settings

.PHONY: app deps dev-deps test shell check-format format lint clean
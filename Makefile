ENV := $(CURDIR)/.venv
PYTHON := $(ENV)/bin/python

BLACK := $(ENV)/bin/black
COVERAGE := $(ENV)/bin/coverage
COVERAGE_OPTS := --rcfile=$(CURDIR)/coverage.cfg
FLAKE8 := $(ENV)/bin/flake8
HONCHO := $(ENV)/bin/honcho
IPYTHON := $(ENV)/bin/ipython
JINJA := $(ENV)/bin/jinja
MYPY := $(ENV)/bin/mypy
PYTEST := $(ENV)/bin/pytest

MANAGE := $(HONCHO) -e .env,.env.local run $(PYTHON) manage.py

HONCHO_TEST := $(HONCHO) run -e .env,.env.test

SOURCEDIRS := testingthis tests
TESTARGS ?= tests


# Ensure absolute paths

export PYTHONPATH := $(CURDIR)/testingthis:$(CURDIR)/tests


# Local setup

deps:
	poetry install
	source .venv/bin/activate

deps-update:
	poetry add psycopg2@latest \
			   Django@latest \
			   djangorestframework@latest \
			   PyYAML@latest \
			   uritemplate@latest \
			   markdown@latest \
			   Pygments@latest \
			   django-filter@latest \
			   django-guardian@latest \
			   django-permissions-policy@latest

dev-deps-update:
	poetry add black@latest \
			   coverage@latest \
			   flake8@latest \
			   honcho@latest \
			   ipython@latest \
			   mypy@latest \
			   pytest@latest \
			   --group dev


# Django functions

app: deps guard-APP_NAME
	$(MANAGE) startapp $(APP_NAME)
	sed -i '' 's/:$$(CURDIR)\/tests/:$$(CURDIR)\/$(APP_NAME):$$(CURDIR)\/tests/g' Makefile

manage: deps guard-CMD
	$(MANAGE) $(CMD)

start: deps
	$(MANAGE) runserver

migrate: deps
	$(MANAGE) migrate $(args)

migrations: deps
	$(MANAGE) makemigrations $(args)


# Testing

test: lint test-db
	$(HONCHO) run -e .env,.env.test $(COVERAGE) run $(COVERAGE_OPTS) -m pytest --durations=5 -v $(TESTARGS)
	$(COVERAGE) report $(COVERAGE_OPTS)
	$(COVERAGE) html $(COVERAGE_OPTS) --fail-under 80

test-db:
	if\
		psql -lqt | cut -d \| -f 1 | grep -qw testingthis_test;\
	then\
		echo "testingthis_test db exists" &&\
		$(HONCHO_TEST) db reset -y;\
	else\
		createdb testingthis_test &&\
		$(HONCHO_TEST) db init &&\
		$(HONCHO_TEST) db upgrade;\
	fi


# Debugging

shell: deps
	$(MANAGE) shell

check-format: deps
	$(BLACK) --check $(SOURCEDIRS) --exclude .*/migrations/.*.py

format: deps
	$(BLACK) $(SOURCEDIRS) --exclude .*/migrations/.*.py

lint: deps check-format
	$(FLAKE8)

clean:
	rm -rf $(ENV)
	find . -name "__pycache__" | xargs rm -r


# Shell checks

guard-%:
	@ if [ "${${*}}" = "" ]; then echo "You must set environment variable $*"; exit 1; fi


# Makefile settings

.PHONY: deps deps-update dev-deps-update\
	app manage start migrate migrations\
	test test-db\
	shell check-format format lint clean\
	guard-%

PYTHON_VERSION = $(shell cat .python-version)
ENV := $(CURDIR)/env
PIP := $(ENV)/bin/pip
PIP_INSTALL := $(PIP) install
PYTHON := $(ENV)/bin/python

COVERAGE := $(ENV)/bin/coverage
COVERAGE_OPTS := --rcfile=$(CURDIR)/coverage.cfg
FLAKE8 := $(ENV)/bin/flake8
HONCHO := $(ENV)/bin/honcho

MANAGE := $(HONCHO) -e .env,.env.local run $(PYTHON) manage.py

SOURCEDIRS := app-name tests
TESTARGS ?= tests


# Ensure absolute paths

export PYTHONPATH := $(CURDIR)/app-name:$(CURDIR)/tests


# Local setup

app:
	mv app-name $(APP_NAME)
	sed -i '' 's/app-name/$(APP_NAME)/g' coverage.cfg
	sed -i '' 's/app-name/$(APP_NAME)/g' README.md
	sed -i '' 's/app-name/$(APP_NAME)/g' manage.py
	sed -i '' 's/app-name/$(APP_NAME)/g' $(APP_NAME)/asgi.py
	sed -i '' 's/app-name/$(APP_NAME)/g' $(APP_NAME)/settings.py
	sed -i '' 's/app-name/$(APP_NAME)/g' $(APP_NAME)/urls.py
	sed -i '' 's/app-name/$(APP_NAME)/g' $(APP_NAME)/wsgi.py
	sed -i '' 's/app-name/$(APP_NAME)/g' Makefile
	rm tests/README.md
	base64 /dev/urandom | (echo "DJANGO_SECRET_KEY=" && head -c50) | tr -d '\n' > .env.local

$(ENV):
	python -m venv $(ENV)
	$(PIP_INSTALL) pip setuptools==56.0.0 wheel==0.36.2 cython==0.29.23

deps: $(ENV) $(PYTHON)
	$(PIP_INSTALL) --upgrade pip==21.0.1
	$(PIP_INSTALL) -r requirements/base.txt

dev-deps:
	$(PIP_INSTALL) -r requirements/dev.txt


# Django functions

project:
	$(DJANGO_ADMIN) startproject $(args)

django-app: $(HONCHO)
	$(PYTHON) manage.py startapp $(args)

manage: $(HONCHO)
	$(MANAGE) $(cmd)

start: $(HONCHO)
	$(MANAGE) runserver

migrate: $(HONCHO)
	$(MANAGE) migrate $(args)

migrations: $(HONCHO)
	$(MANAGE) makemigrations $(args)


# Debugging

test: lint
	$(HONCHO) run -e .env,.env.test $(COVERAGE) run $(COVERAGE_OPTS) -m pytest --durations=5 -v $(TESTARGS)
	$(COVERAGE) report $(COVERAGE_OPTS)
	$(COVERAGE) html $(COVERAGE_OPTS) --fail-under 80

shell: $(ENV)/bin/ipython
	$(MANAGE) shell

check-format: $(ENV)/bin/black
	$(ENV)/bin/black --check $(SOURCEDIRS) --exclude .*/migrations/.*.py

format: $(ENV)/bin/black
	$(ENV)/bin/black $(SOURCEDIRS) --exclude .*/migrations/.*.py

lint: check-format $(FLAKE8)
	$(FLAKE8)

clean:
	rm -rf $(ENV)
	find . -name __pycache__ -type d -prune -exec rm -rf {} \;


# Makefile settings

.PHONY: app deps dev-deps project django-app manage start migrate migrations test shell check-format format lint clean
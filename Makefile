ENV := $(CURDIR)/.venv
PYTHON := $(ENV)/bin/python

BLACK := $(ENV)/bin/black
COVERAGE := $(ENV)/bin/coverage
COVERAGE_OPTS := --rcfile=$(CURDIR)/coverage.cfg
FLAKE8 := $(ENV)/bin/flake8
HONCHO := $(ENV)/bin/honcho
IPYTHON := $(ENV)/bin/ipython
MYPY := $(ENV)/bin/mypy
PYTEST := $(ENV)/bin/pytest

MANAGE := $(HONCHO) -e .env,.env.local run $(PYTHON) manage.py

HONCHO_TEST := $(HONCHO) run -e .env,.env.test

SOURCEDIRS := {{ APP_NAME }} tests
TESTARGS ?= tests


# Ensure absolute paths

export PYTHONPATH := $(CURDIR)/{{ APP_NAME }}:$(CURDIR)/tests


# Local setup

app: guard-APP_NAME
	mv app $(APP_NAME)
	mv static/app static/$(APP_NAME)
	mv templates/app templates/$(APP_NAME)
	jinja -D APP_NAME $(APP_NAME) coverage.cfg.j2 > coverage.cfg
	jinja -D APP_NAME $(APP_NAME) manage.py.j2 > manage.py
	jinja -D APP_NAME $(APP_NAME) $(APP_NAME)/asgi.py.j2 > $(APP_NAME)/asgi.py
	jinja -D APP_NAME $(APP_NAME) $(APP_NAME)/settings.py.j2 > $(APP_NAME)/settings.py
	jinja -D APP_NAME $(APP_NAME) $(APP_NAME)/urls.py.j2 > $(APP_NAME)/urls.py
	jinja -D APP_NAME $(APP_NAME) $(APP_NAME)/wsgi.py.j2 > $(APP_NAME)/wsgi.py
	sed -i '' 's/app-name/$(APP_NAME)/g' Makefile
	find . -name "j2" | xargs rm -r
	base64 /dev/urandom | (echo "DJANGO_SECRET_KEY=" && head -c50) | tr -d '\n' > .env.local
	echo "\nALLOWED_HOSTS=" >> .env.local
	echo "SECURE_BROWSER_XSS_FILTER=true" >> .env.local
	echo "SECURE_HSTS_SECONDS=3600" >> .env.local
	echo "SECURE_HSTS_INCLUDE_SUBDOMAINS=true" >> .env.local
	echo "SECURE_HSTS_PRELOAD=true" >> .env.local
	echo "SECURE_CONTENT_TYPE_NOSNIFF=true" >> .env.local
	echo "X_FRAME_OPTIONS=DENY" >> .env.local
	echo "SECURE_REFERRER_POLICY=origin" >> .env.local
	echo "CSP_DEFAULT_SRC=\"'self'\"" >> .env.local
	echo "PERMISSIONS_POLICY='{\"accelerometer\": [], \"ambient-light-sensor\": [], \"autoplay\": [], \"camera\": [], \"document-domain\": [], \"encrypted-media\": [], \"fullscreen\": [], \"geolocation\": [], \"gyroscope\": [], \"magnetometer\": [], \"microphone\": [], \"midi\": [], \"payment\": [], \"sync-xhr\": [], \"usb\": []}'" >> .env.local
	echo "CSRF_COOKIE_SECURE=true" >> .env.local
	echo "SESSION_COOKIE_SECURE=true" >> .env.local

postgres-local: guard-NAME guard-USER guard-PASSWORD
	echo "POSTGRES_NAME=$(NAME)" >> .env.local
	echo "POSTGRES_USER=$(USER)" >> .env.local
	echo "POSTGRES_PASSWORD=$(PASSWORD)" >> .env.local
	echo "POSTGRES_HOST=127.0.0.1" >> .env.local
	echo "POSTGRES_PORT=5432" >> .env.local

postgres-settings: guard-NAME guard-USER guard-PASSWORD guard-HOST guard-PORT
	echo "POSTGRES_NAME=$(NAME)" >> .env.local
	echo "POSTGRES_USER=$(USER)" >> .env.local
	echo "POSTGRES_PASSWORD=$(PASSWORD)" >> .env.local
	echo "POSTGRES_HOST=$(HOST)" >> .env.local
	echo "POSTGRES_PORT=$(PORT)" >> .env.local

deps:
	poetry install
	source .venv/bin/activate

deps-update:
	poetry add psycopg2@latest Django@latest django-permissions-policy@latest

dev-deps-update:
	poetry add black@latest coverage@latest flake8@latest honcho@latest ipython@latest mypy@latest pytest@latest --dev


# Django functions

project: guard-PROJECT_NAME
	$(DJANGO_ADMIN) startproject $(PROJECT_NAME)

django-app: deps guard-APP_NAME
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

# test-db check
# 1. Check to see if `airflow_test` database exists
# 2. If it does, reset it
# 3. If it doesn't, create it and run Airflow db commands

# DJANGO THIS SHIT

test-db:
	if\
		psql -lqt | cut -d \| -f 1 | grep -qw {{ APP_NAME }}_test;\
	then\
		echo "{{ APP_NAME }}_test db exists" &&\
		$(HONCHO_TEST) db reset -y;\
	else\
		createdb {{ APP_NAME }}_test &&\
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

.PHONY: app postgres-local postgres-settings deps deps-update dev-deps-update\
	project django-app manage start migrate migrations\
	test test-db\
	shell check-format format lint clean\
	guard-%

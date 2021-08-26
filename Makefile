PYTHON_VERSION = $(shell cat .python-version)
ENV := $(CURDIR)
POETRY_ENV := $(shell find . -maxdepth 1 -type d -name template-python\*)
PYTHON := $(POETRY_ENV)/bin/python

COVERAGE := $(POETRY_ENV)/bin/coverage
COVERAGE_OPTS := --rcfile=$(CURDIR)/coverage.cfg
FLAKE8 := $(POETRY_ENV)/bin/flake8
HONCHO := $(POETRY_ENV)/bin/honcho

MANAGE := $(HONCHO) -e .env,.env.local run $(PYTHON) manage.py

SOURCEDIRS := app-name tests
TESTARGS ?= tests


# Ensure absolute paths

export PYTHONPATH := $(CURDIR)/app-name:$(CURDIR)/tests


# Local setup

app: guard-APP_NAME
	mv app-name $(APP_NAME)
	sed -i '' 's/app-name/$(APP_NAME)/g' coverage.cfg
	sed -i '' 's/app-name/$(APP_NAME)/g' README.md
	sed -i '' 's/app-name/$(APP_NAME)/g' manage.py
	sed -i '' 's/app-name/$(APP_NAME)/g' $(APP_NAME)/asgi.py
	sed -i '' 's/app-name/$(APP_NAME)/g' $(APP_NAME)/settings.py
	sed -i '' 's/app-name/$(APP_NAME)/g' $(APP_NAME)/urls.py
	sed -i '' 's/app-name/$(APP_NAME)/g' $(APP_NAME)/wsgi.py
	sed -i '' 's/app-name/$(APP_NAME)/g' Makefile
	rm static/README.md
	rm tests/README.md
	base64 /dev/urandom | (echo "DJANGO_SECRET_KEY=" && head -c50) | tr -d '\n' > .env.local
	echo "ALLOWED_HOSTS=" >> .env.local
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

$(ENV):
	poetry config virtualenvs.path $(CURDIR)

deps: $(ENV)
	poetry install --no-dev

dev-deps: $(ENV)
	poetry install


# Django functions

project: guard-PROJECT_NAME
	$(DJANGO_ADMIN) startproject $(PROJECT_NAME)

django-app: $(HONCHO)
	$(PYTHON) manage.py startapp $(APP_NAME)
	sed -i '' 's/:$$(CURDIR)\/tests/:$$(CURDIR)\/$(APP_NAME):$$(CURDIR)\/tests/g' Makefile

manage: $(HONCHO) guard-CMD
	$(MANAGE) $(CMD)

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
	rm -rf $(POETRY_ENV)
	find . -name "__pycache__" | xargs rm -r


# Shell checks

guard-%:
	@ if [ "${${*}}" = "" ]; then echo "You must set environment variable $*"; exit 1; fi


# Makefile settings

.PHONY: app deps dev-deps project django-app manage start migrate migrations test shell check-format format lint clean

# Django App Template

Template for starting a new Django app.

## Prerequisites

* [pyenv](https://github.com/pyenv/pyenv) with [Python 3.12.10](https://www.python.org/downloads/release/python-3127/)
* [Poetry](https://python-poetry.org/docs/#installation)

## Initialization

1. `poetry install` to build the virtual environment
2. `poetry run python create_project.py -n project_name` to create the project

## Commands

Update dependencies:

```sh
poetry add django@latest django-filter@latest django-guardian@latest django-permissions-policy@latest djangorestframework@latest jinja2@latest markdown@latest "psycopg[binary]@latest" psycopg2@latest pygments@latest pyyaml@latest uritemplate@latest
```

Update dev dependencies:

```sh
poetry add -G dev black@latest coverage@latest flake8@latest honcho@latest ipython@latest mypy@latest pytest@latest
```

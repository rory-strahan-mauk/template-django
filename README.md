# Django App Template

Template for starting a new Django app.

## Prerequisites

* [pyenv](https://github.com/pyenv/pyenv) with [Python 3.10.0](https://www.python.org/downloads/release/python-396/)
* [Poetry](https://python-poetry.org/docs/#installation)

## Initialization

1. Run `make app APP_NAME=` with the name of your app
2. Run `make postgres-local NAME= USER= PASSWORD=` with information for your local PostgreSQL server
    - Alternatively, run `make postgres-settings NAME= USER= PASSWORD= HOST= PORT=` with information for a remote PostgreSQL server
3. Clean up anything you would like in `Makefile`

That's it! You're good to go.

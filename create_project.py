def main(name: str) -> None:
    """
    Create new Django project and process template files.

    :param name: Name of Django project to create
    :type name: str
    """

    # Django project
    import os

    from django.core.management import execute_from_command_line

    execute_from_command_line(argv=["django-admin", "startproject", name, "."])
    os.remove(path=f"{name}/settings.py")

    # jinja setup
    from jinja2 import Environment, FileSystemLoader

    templates = Environment(loader=FileSystemLoader("jinja_templates"))

    # settings.py
    settings = templates.get_template(name="settings.py.j2")
    settings.stream(APP_NAME=name).dump(fp=f"{name}/settings.py")

    # Makefile
    makefile = templates.get_template(name="Makefile.j2")
    makefile.stream(APP_NAME=name).dump(fp="Makefile")

    # .env.local
    from django.core.management.utils import get_random_secret_key

    env_local = templates.get_template(name=".env.local.j2")
    env_local.stream(SECRET_KEY=get_random_secret_key()).dump(fp=".env.local")

    # coverage.cfg
    coverage = templates.get_template(name="coverage.cfg.j2")
    coverage.stream(APP_NAME=name).dump(fp="coverage.cfg")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("-n", "--name", required=True)
    args = parser.parse_args()

    main(name=args.name)

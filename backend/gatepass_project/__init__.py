import os

# Set the DJANGO_SETTINGS_MODULE environment variable
# This tells Django which settings file to use.
# You can change 'dev' to 'prod' for production deployment.
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'gatepass_project.settings.dev')

# This line is needed if you are using Django 3.2+ and want to
# automatically discover and load app configs.
# default_app_config = 'gatepass_project.wsgi.application' # No, this is wrong.
# The standard way is just to set the environment variable.
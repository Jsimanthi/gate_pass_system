from .base import *

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = True

ALLOWED_HOSTS = ['*'] # Allows all hosts for development

# Other dev-specific settings if any
# Email Configuration for Development (Console Backend)
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'
DEFAULT_FROM_EMAIL = 'admin@yourgatepasssystem.com'
SERVER_EMAIL = 'admin@yourgatepasssystem.com' # For error reporting
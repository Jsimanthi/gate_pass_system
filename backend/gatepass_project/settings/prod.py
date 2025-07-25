from .base import *

DEBUG = False

ALLOWED_HOSTS = ['your_production_domain.com', 'your_server_ip'] # Replace with actual domains/IPs

# SECURITY WARNING: keep the secret key used in production secret!
# Set this as an environment variable in production (e.g., in your server's systemd unit file)
SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY')
if not SECRET_KEY:
    raise ValueError("DJANGO_SECRET_KEY environment variable not set.")

# Database settings in production should often come from environment variables for security
# DATABASES are configured in base.py to read from environment variables by default.

# Production specific static files serving settings (e.g., using WhiteNoise)
# STATIC_ROOT = BASE_DIR / 'staticfiles' # Ensure this matches your deployment setup
# STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

# Security Enhancements for Production
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_HSTS_SECONDS = 31536000 # 1 year
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SECURE_BROWSER_XSS_FILTER = True
X_FRAME_OPTIONS = 'DENY' # Already in middleware, but explicitly setting is good.

# CORS settings for production (restrict to your frontend's production domain)
CORS_ALLOW_ALL_ORIGINS = False
CORS_ALLOWED_ORIGINS = [
    "http://your_prod_web_domain.com",
    "https://your_prod_web_domain.com",
    # For mobile apps, you generally don't need to specify origins for API calls
    # unless your mobile app uses a webview for specific parts that interact with your API.
    # Ensure your mobile app communicates directly with your API server without CORS issues.
]
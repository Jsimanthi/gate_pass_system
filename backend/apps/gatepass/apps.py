from django.apps import AppConfig


class GatepassConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.gatepass"

    def ready(self):
        import apps.gatepass.signals

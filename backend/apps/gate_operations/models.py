from django.db import models
from apps.gatepass.models import GatePass
from apps.users.models import CustomUser

class GateLog(models.Model):
    gate_pass = models.ForeignKey(GatePass, on_delete=models.CASCADE)
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    timestamp = models.DateTimeField(auto_now_add=True)
    action = models.CharField(max_length=255)
    status = models.CharField(max_length=255)
    reason = models.TextField(blank=True, null=True)

    def __str__(self):
        return f"{self.action} by {self.user} at {self.timestamp}"

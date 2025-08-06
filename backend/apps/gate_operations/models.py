from django.db import models
from apps.gatepass.models import GatePass
from apps.users.models import CustomUser

class GateLog(models.Model):
    ACTION_CHOICES = [
        ('entry', 'Entry'),
        ('exit', 'Exit'),
        ('scan_attempt', 'Scan Attempt'),
    ]

    STATUS_CHOICES = [
        ('success', 'Success'),
        ('failure', 'Failure'),
    ]

    gate_pass = models.ForeignKey(GatePass, on_delete=models.CASCADE, null=True, blank=True)
    gate = models.ForeignKey('core_data.Gate', on_delete=models.SET_NULL, null=True, blank=True)
    security_personnel = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    timestamp = models.DateTimeField(auto_now_add=True)
    action = models.CharField(max_length=50, choices=ACTION_CHOICES)
    status = models.CharField(max_length=50, choices=STATUS_CHOICES)
    reason = models.TextField(blank=True, null=True)
    scanned_data = models.TextField(blank=True, null=True)


    def __str__(self):
        return f"{self.get_action_display()} by {self.security_personnel.email} at {self.timestamp} - {self.get_status_display()}"

    class Meta:
        verbose_name = "Gate Log"
        verbose_name_plural = "Gate Logs"
        ordering = ['-timestamp']

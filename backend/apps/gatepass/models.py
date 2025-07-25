from django.db import models
from apps.vehicles.models import Vehicle
from apps.drivers.models import Driver
from apps.core_data.models import Gate, Purpose
from apps.users.models import CustomUser

class GatePass(models.Model):
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE)
    driver = models.ForeignKey(Driver, on_delete=models.CASCADE)
    gate = models.ForeignKey(Gate, on_delete=models.CASCADE)
    purpose = models.ForeignKey(Purpose, on_delete=models.CASCADE)
    requested_by = models.ForeignKey(CustomUser, related_name='requested_by', on_delete=models.CASCADE)
    approved_by = models.ForeignKey(CustomUser, related_name='approved_by', on_delete=models.CASCADE, null=True, blank=True)
    requested_exit_time = models.DateTimeField()
    actual_exit_time = models.DateTimeField(null=True, blank=True)
    actual_entry_time = models.DateTimeField(null=True, blank=True)
    status = models.CharField(max_length=255)
    approval_reason = models.TextField(blank=True, null=True)
    qr_code = models.ImageField(upload_to='qr_codes', blank=True, null=True)

    def __str__(self):
        return f"Gate Pass for {self.vehicle} at {self.gate}"

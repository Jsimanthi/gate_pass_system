from django.db import models
from apps.core_data.models import VehicleType

class Vehicle(models.Model):
    vehicle_number = models.CharField(max_length=255, unique=True)
    type = models.ForeignKey(VehicleType, on_delete=models.CASCADE)
    make = models.CharField(max_length=255)
    model = models.CharField(max_length=255)
    capacity = models.CharField(max_length=255)
    status = models.CharField(max_length=255)
    registration_date = models.DateField()
    notes = models.TextField(blank=True, null=True)

    def __str__(self):
        return self.vehicle_number

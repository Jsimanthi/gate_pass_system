from django.db import models

class Driver(models.Model):
    name = models.CharField(max_length=255)
    license_number = models.CharField(max_length=255, unique=True)
    contact_details = models.CharField(max_length=255)
    address = models.TextField()
    status = models.CharField(max_length=255)

    def __str__(self):
        return self.name

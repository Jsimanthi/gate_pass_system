from django.contrib.auth.models import AbstractUser
from django.db import models

class CustomUser(AbstractUser):
    ROLE_CHOICES = (
        ('Admin', 'Admin'),
        ('Security', 'Security'),
        ('Client Care', 'Client Care'),
        ('User', 'User'),
    )
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='User')

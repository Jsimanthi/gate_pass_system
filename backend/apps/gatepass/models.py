# backend/apps/gatepass/models.py

from django.db import models
from apps.users.models import CustomUser
from apps.vehicles.models import Vehicle
from apps.drivers.models import Driver
from apps.core_data.models import Purpose, Gate
import qrcode
from io import BytesIO
from django.core.files import File
from PIL import Image
import json

class GatePass(models.Model):
    # Status Choices
    PENDING = 'PENDING'
    APPROVED = 'APPROVED'
    REJECTED = 'REJECTED'
    CANCELLED = 'CANCELLED'
    STATUS_CHOICES = [
        (PENDING, 'Pending'),
        (APPROVED, 'Approved'),
        (REJECTED, 'Rejected'),
        (CANCELLED, 'Cancelled'),
    ]

    person_name = models.CharField(max_length=255) # No default needed here, it's provided in POST
    person_nid = models.CharField(max_length=100, blank=True, null=True) # Increased length, optional
    person_phone = models.CharField(max_length=100) # Increased length, no default needed as it's provided in POST
    person_address = models.TextField(blank=True, null=True)

    entry_time = models.DateTimeField() # No default needed if it's always provided by API
    exit_time = models.DateTimeField()   # No default needed if it's always provided by API

    purpose = models.ForeignKey(Purpose, on_delete=models.SET_NULL, null=True, related_name='gatepasses')
    gate = models.ForeignKey(Gate, on_delete=models.SET_NULL, null=True, related_name='gatepasses')

    vehicle = models.ForeignKey(Vehicle, on_delete=models.SET_NULL, null=True, blank=True, related_name='gatepasses')
    driver = models.ForeignKey(Driver, on_delete=models.SET_NULL, null=True, blank=True, related_name='gatepasses')

    qr_code = models.ImageField(upload_to='qrcodes/', blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=PENDING)

    created_by = models.ForeignKey(CustomUser, on_delete=models.SET_NULL, null=True, related_name='created_gatepasses')
    approved_by = models.ForeignKey(CustomUser, on_delete=models.SET_NULL, null=True, blank=True, related_name='approved_gatepasses')

    created_at = models.DateTimeField(auto_now_add=True) # Correct: automatically sets on creation
    updated_at = models.DateTimeField(auto_now=True)    # Correct: automatically updates on save
    alcohol_test_required = models.BooleanField(default=False)
    alcohol_test_photo = models.ImageField(upload_to='alcohol_tests/', blank=True, null=True)

    # For recurring gate passes
    is_recurring = models.BooleanField(default=False)
    recurrence_end_date = models.DateField(null=True, blank=True)
    FREQUENCY_CHOICES = [
        ('DAILY', 'Daily'),
        ('WEEKLY', 'Weekly'),
        ('MONTHLY', 'Monthly'),
    ]
    frequency = models.CharField(max_length=10, choices=FREQUENCY_CHOICES, null=True, blank=True)

    def __str__(self):
        return f"Gate Pass for {self.person_name} ({self.status})"

    def generate_qr_code(self):
        if not self.id:
            return

        qr_data = {
            'gatepass_id': self.id,
            'person_name': self.person_name,
            'status': self.status,
            # Add more data if needed for the scanner
        }
        qr_data_json = json.dumps(qr_data)

        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_L,
            box_size=10,
            border=4,
        )
        qr.add_data(qr_data_json)
        qr.make(fit=True)

        img = qr.make_image(fill_color="black", back_color="white")
        buffer = BytesIO()
        img.save(buffer, format="PNG")
        filename = f'gatepass_{self.id}.png'
        self.qr_code.save(filename, File(buffer), save=False)


class PreApprovedVisitor(models.Model):
    name = models.CharField(max_length=255)
    nid = models.CharField(max_length=100, unique=True)
    phone = models.CharField(max_length=100)
    company = models.CharField(max_length=255)
    approved_by = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='approved_visitors')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.name} ({self.nid})"


class GatePassTemplate(models.Model):
    name = models.CharField(max_length=255, unique=True)
    purpose = models.ForeignKey(Purpose, on_delete=models.SET_NULL, null=True)
    gate = models.ForeignKey(Gate, on_delete=models.SET_NULL, null=True)
    vehicle = models.ForeignKey(Vehicle, on_delete=models.SET_NULL, null=True, blank=True)
    driver = models.ForeignKey(Driver, on_delete=models.SET_NULL, null=True, blank=True)
    created_by = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='gatepass_templates')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name


class GatePassHistory(models.Model):
    gate_pass = models.ForeignKey(GatePass, on_delete=models.CASCADE, related_name='history')
    user = models.ForeignKey(CustomUser, on_delete=models.SET_NULL, null=True)
    action = models.CharField(max_length=50)
    timestamp = models.DateTimeField(auto_now_add=True)
    details = models.TextField(blank=True, null=True)

    def __str__(self):
        return f'{self.gate_pass} - {self.action} by {self.user} at {self.timestamp}'


class VisitorPass(models.Model):
    # Status Choices
    PENDING = 'PENDING'
    APPROVED = 'APPROVED'
    REJECTED = 'REJECTED'
    STATUS_CHOICES = [
        (PENDING, 'Pending'),
        (APPROVED, 'Approved'),
        (REJECTED, 'Rejected'),
    ]

    visitor_name = models.CharField(max_length=255)
    visitor_company = models.CharField(max_length=255)
    purpose = models.TextField()
    whom_to_visit = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='visitor_passes')
    visitor_selfie = models.ImageField(upload_to='visitor_selfies/')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=PENDING)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Visitor Pass for {self.visitor_name} to visit {self.whom_to_visit.get_full_name()} ({self.status})"
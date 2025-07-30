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
from django.shortcuts import render
import qrcode
from django.http import HttpResponse
from django.conf import settings
from io import BytesIO

# Create your views here.
# backend/apps/core_data/views.py

from rest_framework import viewsets, permissions
from .models import Gate, Purpose, VehicleType
from .serializers import GateSerializer, PurposeSerializer, VehicleTypeSerializer

# Gate ViewSet - Accessible only by Admins/Staff
class GateViewSet(viewsets.ModelViewSet):
    queryset = Gate.objects.all()
    serializer_class = GateSerializer
    permission_classes = [permissions.IsAuthenticated] # Only authenticated users can manage gates

# Purpose ViewSet - Accessible only by Admins/Staff
class PurposeViewSet(viewsets.ModelViewSet):
    queryset = Purpose.objects.all()
    serializer_class = PurposeSerializer
    permission_classes = [permissions.IsAuthenticated] # Only authenticated users can manage purposes

# VehicleType ViewSet - Accessible only by Admins/Staff
class VehicleTypeViewSet(viewsets.ModelViewSet):
    queryset = VehicleType.objects.all()
    serializer_class = VehicleTypeSerializer
    permission_classes = [permissions.IsAuthenticated] # Only authenticated users can manage vehicle types

def generate_visitor_qr_code(request):
    # Construct the URL for the visitor form
    visitor_form_url = f"{settings.FRONTEND_BASE_URL}/#/visitor-form"

    # Generate the QR code
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(visitor_form_url)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")

    # Save the image to a byte buffer
    buffer = BytesIO()
    img.save(buffer, format="PNG")

    # Return the image as an HTTP response
    return HttpResponse(buffer.getvalue(), content_type="image/png")
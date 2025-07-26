from django.shortcuts import render

# Create your views here.
# backend/apps/core_data/views.py

from rest_framework import viewsets, permissions
from .models import Gate, Purpose, VehicleType
from .serializers import GateSerializer, PurposeSerializer, VehicleTypeSerializer

# Gate ViewSet - Accessible only by Admins/Staff
class GateViewSet(viewsets.ModelViewSet):
    queryset = Gate.objects.all()
    serializer_class = GateSerializer
    permission_classes = [permissions.IsAdminUser] # Only Admin/Staff users can manage gates

# Purpose ViewSet - Accessible only by Admins/Staff
class PurposeViewSet(viewsets.ModelViewSet):
    queryset = Purpose.objects.all()
    serializer_class = PurposeSerializer
    permission_classes = [permissions.IsAdminUser] # Only Admin/Staff users can manage purposes

# VehicleType ViewSet - Accessible only by Admins/Staff
class VehicleTypeViewSet(viewsets.ModelViewSet):
    queryset = VehicleType.objects.all()
    serializer_class = VehicleTypeSerializer
    permission_classes = [permissions.IsAdminUser] # Only Admin/Staff users can manage vehicle types
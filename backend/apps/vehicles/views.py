# backend/apps/vehicles/views.py

from rest_framework import viewsets, permissions
from .models import Vehicle
from .serializers import VehicleSerializer

# Vehicle ViewSet - Accessible only by Admins/Staff
class VehicleViewSet(viewsets.ModelViewSet):
    queryset = Vehicle.objects.all()
    serializer_class = VehicleSerializer
    permission_classes = [permissions.IsAuthenticated] # Only authenticated users can manage vehicles
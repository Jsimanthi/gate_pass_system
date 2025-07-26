# backend/apps/drivers/views.py

from rest_framework import viewsets, permissions
from .models import Driver
from .serializers import DriverSerializer

# Driver ViewSet - Accessible only by Admins/Staff
class DriverViewSet(viewsets.ModelViewSet):
    queryset = Driver.objects.all()
    serializer_class = DriverSerializer
    permission_classes = [permissions.IsAdminUser] # Only Admin/Staff users can manage drivers
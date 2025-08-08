from django.shortcuts import render

# Create your views here.
# backend/apps/core_data/views.py

import logging
from rest_framework import viewsets, permissions
from .models import Gate, Purpose, VehicleType
from .serializers import GateSerializer, PurposeSerializer, VehicleTypeSerializer

# Get an instance of a logger
logger = logging.getLogger(__name__)

# Gate ViewSet - Accessible only by Admins/Staff
class GateViewSet(viewsets.ModelViewSet):
    queryset = Gate.objects.all()
    serializer_class = GateSerializer
    permission_classes = [permissions.IsAuthenticated] # Only authenticated users can manage gates

    def list(self, request, *args, **kwargs):
        logger.info("--- GateViewSet: list method called ---")
        logger.info(f"Request User: {request.user}")

        initial_queryset = self.get_queryset()
        logger.info(f"Initial queryset count: {initial_queryset.count()}")

        filtered_queryset = self.filter_queryset(initial_queryset)
        logger.info(f"Filtered queryset count: {filtered_queryset.count()}")

        # Log details of the filtered queryset if it's unexpectedly empty
        if initial_queryset.exists() and not filtered_queryset.exists():
            logger.warning("Queryset became empty after filtering!")
            logger.warning(f"Filter backends configured for this view: {self.get_filter_backends()}")

        return super().list(request, *args, **kwargs)


# Purpose ViewSet - Accessible only by Admins/Staff
class PurposeViewSet(viewsets.ModelViewSet):
    queryset = Purpose.objects.all()
    serializer_class = PurposeSerializer
    permission_classes = [permissions.IsAuthenticated] # Only authenticated users can manage purposes

    def list(self, request, *args, **kwargs):
        logger.info("--- PurposeViewSet: list method called ---")
        logger.info(f"Request User: {request.user}")

        initial_queryset = self.get_queryset()
        logger.info(f"Initial queryset count: {initial_queryset.count()}")

        filtered_queryset = self.filter_queryset(initial_queryset)
        logger.info(f"Filtered queryset count: {filtered_queryset.count()}")

        # Log details of the filtered queryset if it's unexpectedly empty
        if initial_queryset.exists() and not filtered_queryset.exists():
            logger.warning("Queryset became empty after filtering!")
            logger.warning(f"Filter backends configured for this view: {self.get_filter_backends()}")

        return super().list(request, *args, **kwargs)


# VehicleType ViewSet - Accessible only by Admins/Staff
class VehicleTypeViewSet(viewsets.ModelViewSet):
    queryset = VehicleType.objects.all()
    serializer_class = VehicleTypeSerializer
    permission_classes = [permissions.IsAuthenticated] # Only authenticated users can manage vehicle types
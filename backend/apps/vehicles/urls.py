# File: apps/vehicles/urls.py

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import VehicleViewSet

router = DefaultRouter()
# Change 'vehicles' to '' to register at the root of this URLconf
# Add a basename for reverse lookup, as '' can be ambiguous without it.
router.register(r'', VehicleViewSet, basename='vehicle')

urlpatterns = [
    path('', include(router.urls)),
]
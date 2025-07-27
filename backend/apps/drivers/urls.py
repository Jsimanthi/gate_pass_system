# File: apps/drivers/urls.py

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import DriverViewSet

router = DefaultRouter()
# Change 'drivers' to '' to register at the root of this URLconf
# Add a basename for reverse lookup, as '' can be ambiguous without it.
router.register(r'', DriverViewSet, basename='driver')

urlpatterns = [
    path('', include(router.urls)),
]
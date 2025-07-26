# backend/apps/gate_operations/urls.py

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ScanQRCodeView, GateLogViewSet # Import GateLogViewSet

router = DefaultRouter()
router.register(r'logs', GateLogViewSet, basename='gatelog') # Add this line

urlpatterns = [
    path('scan_qr_code/', ScanQRCodeView.as_view(), name='scan_qr_code'),
    path('', include(router.urls)), # Include router URLs
]
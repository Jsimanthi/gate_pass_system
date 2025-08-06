# backend/apps/gate_operations/urls.py

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ScanQRCodeView, GateLogViewSet, GateOperationsDashboardView

router = DefaultRouter()
router.register(r'logs', GateLogViewSet, basename='gatelog')

urlpatterns = [
    path('scan_qr_code/', ScanQRCodeView.as_view(), name='scan_qr_code'),
    path('dashboard/', GateOperationsDashboardView.as_view(), name='dashboard'),
    path('', include(router.urls)),
]
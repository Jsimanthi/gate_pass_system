# File: gate_pass_system/apps/core_data/urls.py

from rest_framework.routers import DefaultRouter
from django.urls import path, include
from .views import GateViewSet, PurposeViewSet, VehicleTypeViewSet, generate_visitor_qr_code

router = DefaultRouter()
router.register(r'gates', GateViewSet)
router.register(r'purposes', PurposeViewSet)
router.register(r'vehicle-types', VehicleTypeViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('visitor-qr-code/', generate_visitor_qr_code, name='visitor-qr-code'),
]
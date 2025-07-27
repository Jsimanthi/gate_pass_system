# File: gate_pass_system/apps/core_data/urls.py

from rest_framework.routers import DefaultRouter
from django.urls import path, include
from .views import GateViewSet, PurposeViewSet # Make sure these are imported correctly

router = DefaultRouter()
router.register(r'gates', GateViewSet)
router.register(r'purposes', PurposeViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
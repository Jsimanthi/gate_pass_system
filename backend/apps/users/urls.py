# users/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from fcm_django.api.rest_framework import FCMDeviceViewSet
from .views import CurrentUserView

router = DefaultRouter()
router.register(r'devices', FCMDeviceViewSet, basename='fcm-device')

urlpatterns = [
    path('me/', CurrentUserView.as_view(), name='current_user'),
    path('', include(router.urls)),
]
# users/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from fcm_django.api.rest_framework import FCMDeviceViewSet
from .views import CurrentUserView, EmployeeListView

router = DefaultRouter()
router.register(r'devices', FCMDeviceViewSet, basename='fcm-device')

urlpatterns = [
    path('me/', CurrentUserView.as_view(), name='current_user'),
    path('employees/', EmployeeListView.as_view(), name='employee-list'),
    path('', include(router.urls)),
]
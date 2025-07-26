from django.urls import path
from .views import ScanQRCodeView

urlpatterns = [
    path('scan/', ScanQRCodeView.as_view(), name='scan_qr_code'),
]

# backend/apps/gate_operations/serializers.py
from rest_framework import serializers
from .models import GateLog

class QRCodeScanSerializer(serializers.Serializer):
    """
    Serializer for validating the incoming QR code data.
    """
    qr_code_data = serializers.CharField(required=True)

class GateLogSerializer(serializers.ModelSerializer):
    """
    Serializer for the GateLog model.
    """
    class Meta:
        model = GateLog
        fields = '__all__'
        read_only_fields = ('gate_pass', 'security_personnel', 'timestamp', 'action', 'status', 'reason', 'scanned_data')
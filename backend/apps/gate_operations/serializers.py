from rest_framework import serializers
from .models import GateLog
from apps.gatepass.serializers import GatePassSerializer
from apps.users.serializers import UserSerializer
from apps.core_data.serializers import GateSerializer

class QRCodeScanSerializer(serializers.Serializer):
    """
    Serializer for validating the incoming QR code data.
    """
    qr_code_data = serializers.CharField(required=True)

class GateLogSerializer(serializers.ModelSerializer):
    """
    Serializer for the GateLog model.
    """
    gate_pass = GatePassSerializer(read_only=True)
    security_personnel = UserSerializer(read_only=True)
    gate = GateSerializer(read_only=True)
    timestamp = serializers.SerializerMethodField()

    class Meta:
        model = GateLog
        fields = '__all__'

    def get_timestamp(self, obj):
        return obj.timestamp.strftime("%d-%m-%Y, %I:%M:%S %p") if obj.timestamp else None
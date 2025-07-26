# backend/apps/gate_operations/serializers.py

from rest_framework import serializers
from .models import GateLog
# from apps.gatepass.serializers import GatePassSerializer # Import if you want nested details
# from apps.users.serializers import CustomUserSerializer # Import if you want nested user details
class GateLogSerializer(serializers.ModelSerializer):
    # Optionally, to show details instead of just IDs:
    # gate_pass = GatePassSerializer(read_only=True)
    # scanned_by = CustomUserSerializer(read_only=True)

    class Meta:
        model = GateLog
        fields = '__all__'
        read_only_fields = '__all__' # Gate logs should not be editable via API
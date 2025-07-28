from rest_framework import serializers
from apps.gate_operations.models import GateLog

class GateLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = GateLog
        fields = '__all__'

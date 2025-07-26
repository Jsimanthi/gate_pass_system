# backend/apps/core_data/serializers.py

from rest_framework import serializers
from .models import Gate, Purpose, VehicleType

class GateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Gate
        fields = '__all__'

class PurposeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Purpose
        fields = '__all__'

class VehicleTypeSerializer(serializers.ModelSerializer):
    class Meta:
        model = VehicleType
        fields = '__all__'
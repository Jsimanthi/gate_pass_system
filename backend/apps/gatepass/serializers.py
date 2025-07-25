from rest_framework import serializers
from .models import GatePass

class GatePassSerializer(serializers.ModelSerializer):
    class Meta:
        model = GatePass
        fields = '__all__'

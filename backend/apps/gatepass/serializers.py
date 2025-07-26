# backend/apps/gatepass/serializers.py

from rest_framework import serializers
from .models import GatePass
# from apps.users.serializers import CustomUserSerializer # Keep commented out for now if not used

class GatePassSerializer(serializers.ModelSerializer):
    # If you want to display user details, you'd uncomment the line below and the import
    # created_by = CustomUserSerializer(read_only=True)
    # approved_by = CustomUserSerializer(read_only=True)

    class Meta:
        model = GatePass
        fields = [
            'id',
            'person_name',
            'person_nid',
            'person_phone',
            'person_address',
            'entry_time',
            'exit_time',        # Make sure this matches your model
            'purpose',
            'gate',
            'vehicle',
            'driver',
            'qr_code',
            'status',
            'created_by',
            'approved_by',
            'created_at',
            'updated_at'
        ]
        # These fields are set by the system, not provided in the POST request
        read_only_fields = ['id', 'qr_code', 'status', 'created_by', 'approved_by', 'created_at', 'updated_at']
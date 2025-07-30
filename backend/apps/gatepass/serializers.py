# backend/apps/gatepass/serializers.py

from rest_framework import serializers
from .models import GatePass, Purpose, Gate
from apps.users.models import CustomUser # Import your CustomUser model
from apps.vehicles.models import Vehicle # Import your Vehicle model
from apps.drivers.models import Driver   # Import your Driver model

# Define serializers for related models that you want to nest
class PurposeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Purpose
        fields = ['id', 'name']

class GateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Gate
        fields = ['id', 'name']

class VehicleSerializer(serializers.ModelSerializer):
    # Assuming 'vehicle_type' is a ForeignKey on your Vehicle model
    # and you want to display its name
    vehicle_type_name = serializers.CharField(source='vehicle_type.name', read_only=True)

    class Meta:
        model = Vehicle
        # Ensure these fields match your Vehicle model's actual fields for display
        fields = ['id', 'vehicle_number', 'vehicle_type_name']

class DriverSerializer(serializers.ModelSerializer):
    class Meta:
        model = Driver
        # Ensure these fields match your Driver model's actual fields for display
        fields = ['id', 'name', 'phone_number']

class SimpleUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = ['id', 'username', 'email', 'first_name', 'last_name']


class GatePassSerializer(serializers.ModelSerializer):
    # These fields will be used for READ operations (GET requests), providing nested objects
    purpose = PurposeSerializer(read_only=True)
    gate = GateSerializer(read_only=True)
    vehicle = VehicleSerializer(read_only=True)
    driver = DriverSerializer(read_only=True)
    created_by = SimpleUserSerializer(read_only=True)
    approved_by = SimpleUserSerializer(read_only=True)

    # These fields will be used for WRITE operations (POST/PUT requests),
    # accepting primary keys and mapping them to the ForeignKey fields on the model.
    # Note: No 'source' or 'write_only' needed here as the field names match the model FKs.
    # The default ModelSerializer behavior handles this for creation/update.
    # We list them separately just to be explicit about their role in data submission.
    purpose_id = serializers.PrimaryKeyRelatedField(queryset=Purpose.objects.all(), write_only=True)
    gate_id = serializers.PrimaryKeyRelatedField(queryset=Gate.objects.all(), write_only=True)
    vehicle_id = serializers.PrimaryKeyRelatedField(queryset=Vehicle.objects.all(), allow_null=True, required=False, write_only=True)
    driver_id = serializers.PrimaryKeyRelatedField(queryset=Driver.objects.all(), allow_null=True, required=False, write_only=True)


    class Meta:
        model = GatePass
        fields = [
            'id',
            'person_name',
            'person_nid',
            'person_phone',
            'person_address',
            'entry_time',
            'exit_time',
            'status',
            'qr_code',
            # Read-only nested objects for display
            'purpose',
            'gate',
            'vehicle',
            'driver',
            'created_by',
            'approved_by',
            'created_at',
            'updated_at',
            # Write-only fields for submission (accepts IDs)
            'purpose_id',
            'gate_id',
            'vehicle_id',
            'driver_id',
            'alcohol_test_required',
            'alcohol_test_photo'
        ]
        # These fields are set by the system or derived, not directly sent in the POST request body
        read_only_fields = [
            'id', 'qr_code', 'status', 'created_by', 'approved_by', 'created_at', 'updated_at',
            # The 'purpose', 'gate', 'vehicle', 'driver' fields are implicitly read_only
            # because they are defined with nested serializers.
        ]

    # Override create to handle the PrimaryKeyRelatedFields correctly.
    # The default ModelSerializer create method will often handle this automatically if field names match,
    # but explicit handling is safer especially with 'source' or custom logic.
    def create(self, validated_data):
        purpose_data = validated_data.pop('purpose_id')
        gate_data = validated_data.pop('gate_id')
        vehicle_data = validated_data.pop('vehicle_id', None)
        driver_data = validated_data.pop('driver_id', None)

        gate_pass = GatePass.objects.create(
            purpose=purpose_data,
            gate=gate_data,
            vehicle=vehicle_data,
            driver=driver_data,
            **validated_data
        )
        return gate_pass

    def update(self, instance, validated_data):
        # Similar to create, handle PrimaryKeyRelatedFields for updates
        return super().update(instance, validated_data)
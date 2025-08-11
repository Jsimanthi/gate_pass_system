# backend/apps/gatepass/serializers.py

from rest_framework import serializers
from .models import VisitorPass, GatePass, Purpose, Gate, PreApprovedVisitor, GatePassTemplate
from apps.users.models import CustomUser
from apps.vehicles.models import Vehicle
from apps.drivers.models import Driver

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
    vehicle_type_name = serializers.CharField(source='vehicle_type.name', read_only=True)
    class Meta:
        model = Vehicle
        fields = ['id', 'vehicle_number', 'vehicle_type_name']

class DriverSerializer(serializers.ModelSerializer):
    class Meta:
        model = Driver
        fields = ['id', 'name', 'contact_details']

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

    # Use DateTimeField for handling both input and output for datetime fields.
    # The default behavior correctly handles ISO 8601 strings from your Flutter app.
    # You can customize the format if needed, but it's not required here.
    entry_time = serializers.DateTimeField()
    exit_time = serializers.DateTimeField()

    # created_at and updated_at are read-only fields handled by the model.
    # No need for SerializerMethodField unless you want a custom display format.
    # We can just list them in read_only_fields.
    # If you still want custom formatting for the output, you can keep the
    # SerializerMethodFields, but you MUST define them with the source parameter.
    # A cleaner approach is to use a regular DateTimeField and override to_representation.
    # But for simplicity, let's keep it simple.
    
    # We remove the SerializerMethodField for entry_time and exit_time.
    # The default ModelSerializer will handle the conversion from string to DateTimeField.

    # These fields will be used for WRITE operations (POST/PUT requests),
    # accepting primary keys and mapping them to the ForeignKey fields on the model.
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
            # Now these are handled by the ModelSerializer's default behavior
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
            'alcohol_test_photo',
            'is_recurring',
            'recurrence_end_date',
            'frequency'
        ]
        read_only_fields = [
            'id', 'qr_code', 'status', 'created_by', 'approved_by',
            'purpose', 'gate', 'vehicle', 'driver',
            'created_at', 'updated_at'
        ]
        
    def to_representation(self, instance):
        """
        Customizes the representation for GET requests to format datetime fields.
        This is a better pattern than SerializerMethodField.
        """
        ret = super().to_representation(instance)
        # Format the datetime fields for display
        for field_name in ['entry_time', 'exit_time', 'created_at', 'updated_at']:
            dt_value = getattr(instance, field_name)
            if dt_value:
                ret[field_name] = dt_value.strftime("%d-%m-%Y, %I:%M:%S %p")
            else:
                ret[field_name] = None

        return ret
        
    # The `create` method override is no longer strictly necessary if your field names
    # match your model's FKs. The default ModelSerializer `create` will handle this.
    # However, keeping it makes the code more explicit and readable,
    # and allows you to easily add more logic if needed.
    # You should remove the `pop` calls for entry_time and exit_time from create.

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


class VisitorPassSerializer(serializers.ModelSerializer):
    whom_to_visit = SimpleUserSerializer(read_only=True)
    whom_to_visit_id = serializers.PrimaryKeyRelatedField(
        queryset=CustomUser.objects.all(),
        source='whom_to_visit',
        write_only=True
    )
    visitor_selfie = serializers.ImageField(required=True)

    class Meta:
        model = VisitorPass
        fields = (
            'id',
            'visitor_name',
            'visitor_company',
            'purpose',
            'whom_to_visit',
            'whom_to_visit_id',
            'visitor_selfie',
            'status',
            'created_at',
            'updated_at',
        )
        read_only_fields = ('id', 'status', 'created_at', 'updated_at', 'whom_to_visit')

    def to_representation(self, instance):
        ret = super().to_representation(instance)
        # Format the datetime fields for display
        for field_name in ['created_at', 'updated_at']:
            dt_value = getattr(instance, field_name)
            if dt_value:
                ret[field_name] = dt_value.strftime("%d-%m-%Y, %I:%M:%S %p")
            else:
                ret[field_name] = None

        # Build full URL for the selfie image
        request = self.context.get('request')
        if instance.visitor_selfie and hasattr(instance.visitor_selfie, 'url'):
            if request:
                ret['visitor_selfie'] = request.build_absolute_uri(instance.visitor_selfie.url)
            else:
                # Fallback if request context is not available
                ret['visitor_selfie'] = instance.visitor_selfie.url

        return ret


class PreApprovedVisitorSerializer(serializers.ModelSerializer):
    class Meta:
        model = PreApprovedVisitor
        fields = '__all__'


class GatePassTemplateSerializer(serializers.ModelSerializer):
    class Meta:
        model = GatePassTemplate
        fields = '__all__'
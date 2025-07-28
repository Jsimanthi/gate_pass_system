# backend/apps/users/serializers.py

from rest_framework import serializers
from .models import CustomUser # Assuming CustomUser is your user model

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = [
            'id',
            'username',
            'email',
            'first_name',
            'last_name',
            'is_staff',
            'is_superuser',
            'is_active',
            # Add any other fields you want to expose from your CustomUser model
        ]
        read_only_fields = ['is_staff', 'is_superuser', 'is_active'] # These are usually set by admins
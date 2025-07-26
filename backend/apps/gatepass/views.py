# backend/apps/gatepass/views.py

from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from .models import GatePass
from .serializers import GatePassSerializer

# GatePass ViewSet
class GatePassViewSet(viewsets.ModelViewSet):
    queryset = GatePass.objects.all()
    serializer_class = GatePassSerializer

    # Define permissions based on action
    def get_permissions(self):
        if self.action in ['create', 'list', 'retrieve']:
            # Any authenticated user can create, list, and retrieve their own gate passes
            # (we'll filter queryset later to only show user's own)
            self.permission_classes = [permissions.IsAuthenticated]
        elif self.action in ['update', 'partial_update', 'destroy']:
            # Only the creator of the pass or an admin can update/delete
            # (We'd need a custom permission for "only creator", for now IsAdminUser)
            self.permission_classes = [permissions.IsAdminUser] # For now, restrict to admin for modification/deletion
        elif self.action in ['approve', 'reject']:
            # Only staff/admin can approve or reject gate passes
            self.permission_classes = [permissions.IsAdminUser]
        else:
            self.permission_classes = [permissions.IsAuthenticated] # Default for other custom actions
        return [permission() for permission in self.permission_classes]

    # Override perform_create to set the creator to the current user
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    # Filter queryset so users only see their own gate passes, unless they are admin
    def get_queryset(self):
        user = self.request.user
        if user.is_staff or user.is_superuser:
            return GatePass.objects.all()
        return GatePass.objects.filter(created_by=user)

    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        gate_pass = get_object_or_404(GatePass, pk=pk)

        # Logic to approve the gate pass
        gate_pass.status = GatePass.APPROVED
        gate_pass.approved_by = request.user
        gate_pass.save()

        # Regenerate QR code on approval if needed, or simply ensure it's there
        gate_pass.generate_qr_code() # This method should handle saving the QR to the model field
        gate_pass.save() # Save again after QR code generation

        serializer = self.get_serializer(gate_pass)
        return Response(serializer.data, status=status.HTTP_200_OK)

    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        gate_pass = get_object_or_404(GatePass, pk=pk)

        # Logic to reject the gate pass
        gate_pass.status = GatePass.REJECTED
        gate_pass.approved_by = request.user
        gate_pass.save()

        serializer = self.get_serializer(gate_pass)
        return Response(serializer.data, status=status.HTTP_200_OK)
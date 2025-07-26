# backend/apps/gatepass/views.py

from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from .models import GatePass
from .serializers import GatePassSerializer
from django.core.mail import send_mail # ADD THIS IMPORT
from django.conf import settings     # ADD THIS IMPORT to access DEFAULT_FROM_EMAIL

# GatePass ViewSet
class GatePassViewSet(viewsets.ModelViewSet):
    queryset = GatePass.objects.all()
    serializer_class = GatePassSerializer

    def get_permissions(self):
        if self.action in ['create', 'list', 'retrieve']:
            self.permission_classes = [permissions.IsAuthenticated]
        elif self.action in ['update', 'partial_update', 'destroy']:
            self.permission_classes = [permissions.IsAdminUser]
        elif self.action in ['approve', 'reject']:
            self.permission_classes = [permissions.IsAdminUser]
        else:
            self.permission_classes = [permissions.IsAuthenticated]
        return [permission() for permission in self.permission_classes]

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
        # Optional: Send a notification that a new gate pass request has been submitted
        # send_mail(
        #     'New Gate Pass Request Submitted',
        #     f'A new gate pass request (ID: {serializer.instance.id}) has been submitted by {self.request.user.username}.',
        #     settings.DEFAULT_FROM_EMAIL,
        #     ['approver@yourgatepasssystem.com'], # Replace with actual approver email or lookup
        #     fail_silently=False,
        # )


    def get_queryset(self):
        user = self.request.user
        if user.is_staff or user.is_superuser:
            return GatePass.objects.all()
        return GatePass.objects.filter(created_by=user)

    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        gate_pass = get_object_or_404(GatePass, pk=pk)

        if gate_pass.status == GatePass.APPROVED:
            return Response({"detail": "Gate Pass is already approved."}, status=status.HTTP_400_BAD_REQUEST)

        gate_pass.status = GatePass.APPROVED
        gate_pass.approved_by = request.user
        gate_pass.save()

        gate_pass.generate_qr_code()
        gate_pass.save()

        # Send Approval Notification
        try:
            recipient_email = gate_pass.created_by.email
            if recipient_email:
                subject = f"Your Gate Pass Request (ID: {gate_pass.id}) Has Been APPROVED!"
                message = (
                    f"Dear {gate_pass.created_by.get_full_name() or gate_pass.created_by.username},\n\n"
                    f"Your gate pass request for {gate_pass.person_name} "
                    f"({gate_pass.vehicle.license_plate if gate_pass.vehicle else 'No vehicle'}) "
                    f"on {gate_pass.entry_time.strftime('%Y-%m-%d')} "
                    f"for the purpose of '{gate_pass.purpose.name}' has been APPROVED.\n\n"
                    f"You can now proceed to the gate with your QR code."
                    f"\n\nGate Pass ID: {gate_pass.id}"
                    f"\nApproved By: {request.user.get_full_name() or request.user.username}"
                    f"\n\nThank you,\nGate Pass System"
                )
                send_mail(
                    subject,
                    message,
                    settings.DEFAULT_FROM_EMAIL,
                    [recipient_email],
                    fail_silently=False, # Set to True in production if you don't want crashes on email failure
                )
                print(f"DEBUG: Approval email sent to {recipient_email}") # For console backend confirmation
            else:
                print(f"DEBUG: No email address for user {gate_pass.created_by.username} to send approval notification.")
        except Exception as e:
            print(f"ERROR: Failed to send approval email: {e}")
            # Consider logging this error properly in a production environment

        serializer = self.get_serializer(gate_pass)
        return Response(serializer.data, status=status.HTTP_200_OK)

    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        gate_pass = get_object_or_404(GatePass, pk=pk)

        if gate_pass.status == GatePass.REJECTED:
            return Response({"detail": "Gate Pass is already rejected."}, status=status.HTTP_400_BAD_REQUEST)

        gate_pass.status = GatePass.REJECTED
        gate_pass.approved_by = request.user
        gate_pass.save()

        # Send Rejection Notification
        try:
            recipient_email = gate_pass.created_by.email
            if recipient_email:
                subject = f"Your Gate Pass Request (ID: {gate_pass.id}) Has Been REJECTED!"
                message = (
                    f"Dear {gate_pass.created_by.get_full_name() or gate_pass.created_by.username},\n\n"
                    f"We regret to inform you that your gate pass request for {gate_pass.person_name} "
                    f"({gate_pass.vehicle.license_plate if gate_pass.vehicle else 'No vehicle'}) "
                    f"on {gate_pass.entry_time.strftime('%Y-%m-%d')} "
                    f"for the purpose of '{gate_pass.purpose.name}' has been REJECTED.\n\n"
                    f"Please contact the administration for more details if needed."
                    f"\n\nGate Pass ID: {gate_pass.id}"
                    f"\nRejected By: {request.user.get_full_name() or request.user.username}"
                    f"\n\nThank you,\nGate Pass System"
                )
                send_mail(
                    subject,
                    message,
                    settings.DEFAULT_FROM_EMAIL,
                    [recipient_email],
                    fail_silently=False, # Set to True in production if you don't want crashes on email failure
                )
                print(f"DEBUG: Rejection email sent to {recipient_email}") # For console backend confirmation
            else:
                print(f"DEBUG: No email address for user {gate_pass.created_by.username} to send rejection notification.")
        except Exception as e:
            print(f"ERROR: Failed to send rejection email: {e}")
            # Consider logging this error properly in a production environment

        serializer = self.get_serializer(gate_pass)
        return Response(serializer.data, status=status.HTTP_200_OK)
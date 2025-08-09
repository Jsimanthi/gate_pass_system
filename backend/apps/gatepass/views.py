# backend/apps/gatepass/views.py

from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from .models import VisitorPass, GatePass, PreApprovedVisitor, GatePassTemplate
from .serializers import VisitorPassSerializer, GatePassSerializer, PreApprovedVisitorSerializer, GatePassTemplateSerializer
from django.core.mail import send_mail
from django.conf import settings
from rest_framework.views import APIView
from datetime import date, timedelta, datetime
from dateutil.relativedelta import relativedelta


class DashboardSummaryView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = self.request.user
        base_queryset = GatePass.objects
        if not (user.is_staff or user.is_superuser):
            base_queryset = base_queryset.filter(created_by=user)

        pending_count = base_queryset.filter(status=GatePass.PENDING).count()
        approved_count = base_queryset.filter(status=GatePass.APPROVED).count()
        rejected_count = base_queryset.filter(status=GatePass.REJECTED).count()

        return Response({
            'pending_count': pending_count,
            'approved_count': approved_count,
            'rejected_count': rejected_count,
        })


class VisitorPassViewSet(viewsets.ModelViewSet):
    serializer_class = VisitorPassSerializer
    queryset = VisitorPass.objects.all().order_by('-created_at')

    def get_permissions(self):
        if self.action == 'create':
            self.permission_classes = [permissions.AllowAny]
        else:
            self.permission_classes = [permissions.IsAuthenticated]
        return super().get_permissions()

    def get_queryset(self):
        user = self.request.user
        if not user.is_authenticated:
            return VisitorPass.objects.none()

        if user.groups.filter(name='Security').exists():
            return VisitorPass.objects.filter(status=VisitorPass.APPROVED)

        if user.is_staff or user.is_superuser:
            return VisitorPass.objects.all()

        return VisitorPass.objects.filter(whom_to_visit=user)

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def approve(self, request, pk=None):
        visitor_pass = self.get_object()
        if visitor_pass.whom_to_visit != request.user and not request.user.is_staff:
            return Response({'detail': 'Not authorized to approve this pass.'}, status=status.HTTP_403_FORBIDDEN)

        visitor_pass.status = VisitorPass.APPROVED
        visitor_pass.save()
        # TODO: Add notification logic here for security and visitor
        return Response(VisitorPassSerializer(visitor_pass).data)

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def reject(self, request, pk=None):
        visitor_pass = self.get_object()
        if visitor_pass.whom_to_visit != request.user and not request.user.is_staff:
            return Response({'detail': 'Not authorized to reject this pass.'}, status=status.HTTP_403_FORBIDDEN)

        visitor_pass.status = VisitorPass.REJECTED
        visitor_pass.save()
        # TODO: Add notification logic here for visitor
        return Response(VisitorPassSerializer(visitor_pass).data)


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

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        is_recurring = serializer.validated_data.get('is_recurring', False)

        if is_recurring:
            start_date = serializer.validated_data.get('entry_time').date()
            end_date = serializer.validated_data.get('recurrence_end_date')
            frequency = serializer.validated_data.get('frequency')

            if not end_date or not frequency:
                return Response(
                    {"detail": "Recurrence end date and frequency are required for recurring gate passes."},
                    status=status.HTTP_400_BAD_REQUEST
                )

            gate_passes_data = []
            current_date = start_date
            while current_date <= end_date:
                entry_time = datetime.combine(current_date, serializer.validated_data.get('entry_time').time())
                exit_time = datetime.combine(current_date, serializer.validated_data.get('exit_time').time())

                validated_data = serializer.validated_data.copy()
                validated_data.pop('is_recurring', None)
                validated_data.pop('recurrence_end_date', None)
                validated_data.pop('frequency', None)
                validated_data['entry_time'] = entry_time
                validated_data['exit_time'] = exit_time

                purpose = validated_data.pop('purpose_id')
                gate = validated_data.pop('gate_id')
                vehicle = validated_data.pop('vehicle_id', None)
                driver = validated_data.pop('driver_id', None)

                gate_pass = GatePass.objects.create(
                    purpose=purpose,
                    gate=gate,
                    vehicle=vehicle,
                    driver=driver,
                    created_by=request.user,
                    **validated_data
                )

                person_nid = request.data.get('person_nid')
                if person_nid and PreApprovedVisitor.objects.filter(nid=person_nid).exists():
                    gate_pass.status = GatePass.APPROVED
                    gate_pass.approved_by = request.user

                gate_pass.generate_qr_code()
                gate_pass.save()

                gate_passes_data.append(self.get_serializer(gate_pass).data)

                if frequency == 'DAILY':
                    current_date += timedelta(days=1)
                elif frequency == 'WEEKLY':
                    current_date += timedelta(weeks=1)
                elif frequency == 'MONTHLY':
                    current_date += relativedelta(months=1)

            return Response(gate_passes_data, status=status.HTTP_201_CREATED)
        else:
            self.perform_create(serializer)
            headers = self.get_success_headers(serializer.data)
            return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)

    def perform_create(self, serializer):
        person_nid = self.request.data.get('person_nid')
        if person_nid and PreApprovedVisitor.objects.filter(nid=person_nid).exists():
            serializer.save(
                created_by=self.request.user,
                status=GatePass.APPROVED,
                approved_by=self.request.user,
                alcohol_test_required=self.request.data.get('alcohol_test_required', False)
            )
            gate_pass = serializer.instance
            gate_pass.generate_qr_code()
            gate_pass.save()
        else:
            serializer.save(created_by=self.request.user, alcohol_test_required=self.request.data.get('alcohol_test_required', False))


    def get_queryset(self):
        user = self.request.user
        if user.is_staff or user.is_superuser or user.groups.filter(name='Client Care').exists():
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


class GatePassTemplateViewSet(viewsets.ModelViewSet):
    queryset = GatePassTemplate.objects.all()
    serializer_class = GatePassTemplateSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_permissions(self):
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            self.permission_classes = [permissions.IsAdminUser]
        return [permission() for permission in self.permission_classes]

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    @action(detail=True, methods=['post'])
    def create_gatepass(self, request, pk=None):
        template = self.get_object()
        data = request.data.copy()
        data['purpose_id'] = template.purpose.id if template.purpose else None
        data['gate_id'] = template.gate.id if template.gate else None
        data['vehicle_id'] = template.vehicle.id if template.vehicle else None
        data['driver_id'] = template.driver.id if template.driver else None

        serializer = GatePassSerializer(data=data, context={'request': request})
        if serializer.is_valid():
            self.check_object_permissions(request, template)
            gate_pass = serializer.save(created_by=request.user)
            return Response(GatePassSerializer(gate_pass).data, status=status.HTTP_201_CREATED)
        else:
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class PreApprovedVisitorViewSet(viewsets.ModelViewSet):
    queryset = PreApprovedVisitor.objects.all()
    serializer_class = PreApprovedVisitorSerializer

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            self.permission_classes = [permissions.IsAuthenticated]
        else:
            self.permission_classes = [permissions.IsAdminUser]
        return [permission() for permission in self.permission_classes]

    def perform_create(self, serializer):
        serializer.save(approved_by=self.request.user)

    @action(detail=True, methods=['post'])
    def alcohol_test(self, request, pk=None):
        gate_pass = get_object_or_404(GatePass, pk=pk)
        if not gate_pass.alcohol_test_required:
            return Response({"detail": "Alcohol test not required for this gate pass."}, status=status.HTTP_400_BAD_REQUEST)

        result = request.data.get('result')
        photo = request.data.get('photo')

        if result not in ['pass', 'fail']:
            return Response({"detail": "Invalid result. Must be 'pass' or 'fail'."}, status=status.HTTP_400_BAD_REQUEST)

        if not photo:
            return Response({"detail": "Photo is required."}, status=status.HTTP_400_BAD_REQUEST)

        # Save the photo and update the gate pass
        # This is a simplified example. In a real application, you would want to handle file uploads more robustly.
        gate_pass.alcohol_test_photo = photo
        if result == 'pass':
            gate_pass.status = GatePass.APPROVED
            gate_pass.approved_by = request.user
            gate_pass.save()
            gate_pass.generate_qr_code()
            gate_pass.save()
            # Send approval notification
        else:
            gate_pass.status = GatePass.REJECTED
            gate_pass.approved_by = request.user
            gate_pass.save()
            # Send rejection notification and alert for driver change

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
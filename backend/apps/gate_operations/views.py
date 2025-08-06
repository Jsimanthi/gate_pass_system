from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions, viewsets
from django.shortcuts import get_object_or_404
from apps.gatepass.models import GatePass
from .models import GateLog
from .serializers import GateLogSerializer, QRCodeScanSerializer
import json
from rest_framework.generics import ListAPIView
from rest_framework.pagination import PageNumberPagination

class ScanQRCodeView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, *args, **kwargs):
        serializer = QRCodeScanSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        qr_code_data = serializer.validated_data['qr_code_data']

        try:
            parsed_data = json.loads(qr_code_data)
            gatepass_id = parsed_data.get('gatepass_id')
        except (json.JSONDecodeError, AttributeError):
            self._log_failure(request.user, "Invalid QR code data format.", qr_code_data)
            return Response({"error": "Invalid QR code data format."}, status=status.HTTP_400_BAD_REQUEST)

        if not gatepass_id:
            self._log_failure(request.user, "QR code data missing 'gatepass_id'.", qr_code_data)
            return Response({"error": "QR code data missing 'gatepass_id'."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            gate_pass = GatePass.objects.get(id=gatepass_id)
            if gate_pass.status == GatePass.APPROVED:
                self._log_success(request.user, gate_pass, qr_code_data)
                return Response(self._get_success_response(gate_pass), status=status.HTTP_200_OK)
            else:
                reason = f"Gate Pass has status: {gate_pass.get_status_display()}"
                self._log_failure(request.user, reason, qr_code_data, gate_pass)
                return Response({"error": reason}, status=status.HTTP_403_FORBIDDEN)
        except GatePass.DoesNotExist:
            self._log_failure(request.user, "Gate Pass not found.", qr_code_data)
            return Response({"error": "Gate Pass not found."}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            self._log_failure(request.user, f"An unexpected error occurred: {str(e)}", qr_code_data)
            return Response({"error": "An unexpected error occurred."}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    def _log_failure(self, user, reason, scanned_data, gate_pass=None):
        GateLog.objects.create(
            security_personnel=user,
            action='scan_attempt',
            status='failure',
            reason=reason,
            scanned_data=scanned_data,
            gate_pass=gate_pass
        )

    def _log_success(self, user, gate_pass, scanned_data):
        GateLog.objects.create(
            security_personnel=user,
            gate_pass=gate_pass,
            action='entry',
            status='success',
            scanned_data=scanned_data
        )

    def _get_success_response(self, gate_pass):
        return {
            "message": "Gate Pass Validated Successfully!",
            "gate_pass_details": {
                "id": gate_pass.id,
                "person_name": gate_pass.driver.name,
                "status": gate_pass.get_status_display(),
                "purpose": gate_pass.purpose.name,
                "vehicle_number": gate_pass.vehicle.vehicle_number,
            }
        }


class GateLogViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = GateLog.objects.all()
    serializer_class = GateLogSerializer
    permission_classes = [permissions.IsAdminUser]


class StandardResultsSetPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = 'page_size'
    max_page_size = 100

class GateOperationsDashboardView(ListAPIView):
    queryset = GateLog.objects.order_by('-timestamp')
    serializer_class = GateLogSerializer
    permission_classes = [permissions.IsAdminUser]
    pagination_class = StandardResultsSetPagination
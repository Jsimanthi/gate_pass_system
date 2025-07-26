# backend/apps/gate_operations/views.py
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions, viewsets # ADD viewsets here

from django.shortcuts import get_object_or_404
from apps.gatepass.models import GatePass
from .models import GateLog
from .serializers import GateLogSerializer # ADD THIS LINE
from datetime import datetime
import json

class ScanQRCodeView(APIView):
    permission_classes = [permissions.IsAuthenticated] # Only authenticated users can scan

    def post(self, request, *args, **kwargs):
        qr_code_data = request.data.get('qr_code_data')

        if not qr_code_data:
            GateLog.objects.create(
                timestamp=datetime.now(),
                scanned_by=request.user,
                scan_status=GateLog.FAILED,
                error_message="No QR code data provided."
            )
            return Response({"error": "QR code data is required."}, status=status.HTTP_400_BAD_REQUEST)

        # Try to parse the QR code data. Assuming it's a JSON string.
        try:
            parsed_data = json.loads(qr_code_data)
            gatepass_id = parsed_data.get('gatepass_id')
            # Add other relevant fields if your QR code contains more data, e.g., 'secret_key'
            # For now, let's assume gatepass_id is enough to fetch the GatePass
        except json.JSONDecodeError:
            GateLog.objects.create(
                timestamp=datetime.now(),
                scanned_by=request.user,
                scan_status=GateLog.FAILED,
                scanned_data=qr_code_data,
                error_message="Invalid QR code data format (not JSON)."
            )
            return Response({"error": "Invalid QR code data format."}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            GateLog.objects.create(
                timestamp=datetime.now(),
                scanned_by=request.user,
                scan_status=GateLog.FAILED,
                scanned_data=qr_code_data,
                error_message=f"Error parsing QR code data: {str(e)}"
            )
            return Response({"error": f"Error processing QR code: {str(e)}"}, status=status.HTTP_400_BAD_REQUEST)


        if not gatepass_id:
            GateLog.objects.create(
                timestamp=datetime.now(),
                scanned_by=request.user,
                scan_status=GateLog.FAILED,
                scanned_data=qr_code_data,
                error_message="QR code data missing 'gatepass_id'."
            )
            return Response({"error": "QR code data missing 'gatepass_id'."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            gate_pass = get_object_or_404(GatePass, id=gatepass_id)

            if gate_pass.status == GatePass.APPROVED:
                # Log successful scan
                GateLog.objects.create(
                    gate_pass=gate_pass,
                    timestamp=datetime.now(),
                    scanned_by=request.user,
                    scan_status=GateLog.SUCCESS,
                    scanned_data=qr_code_data
                )
                return Response({
                    "message": "Gate Pass Validated Successfully!",
                    "gate_pass_details": {
                        "id": gate_pass.id,
                        "person_name": gate_pass.person_name,
                        "status": gate_pass.get_status_display(),
                        "entry_time": gate_pass.entry_time,
                        "exit_time": gate_pass.exit_time,
                        "purpose": gate_pass.purpose.name,
                        "vehicle_number": gate_pass.vehicle.license_plate if gate_pass.vehicle else "N/A"
                    }
                }, status=status.HTTP_200_OK)
            elif gate_pass.status == GatePass.PENDING:
                GateLog.objects.create(
                    gate_pass=gate_pass,
                    timestamp=datetime.now(),
                    scanned_by=request.user,
                    scan_status=GateLog.FAILED,
                    scanned_data=qr_code_data,
                    error_message="Gate Pass is PENDING approval."
                )
                return Response({"error": "Gate Pass is pending approval."}, status=status.HTTP_403_FORBIDDEN)
            elif gate_pass.status == GatePass.REJECTED:
                GateLog.objects.create(
                    gate_pass=gate_pass,
                    timestamp=datetime.now(),
                    scanned_by=request.user,
                    scan_status=GateLog.FAILED,
                    scanned_data=qr_code_data,
                    error_message="Gate Pass has been REJECTED."
                )
                return Response({"error": "Gate Pass has been rejected."}, status=status.HTTP_403_FORBIDDEN)
            elif gate_pass.status == GatePass.CANCELLED:
                GateLog.objects.create(
                    gate_pass=gate_pass,
                    timestamp=datetime.now(),
                    scanned_by=request.user,
                    scan_status=GateLog.FAILED,
                    scanned_data=qr_code_data,
                    error_message="Gate Pass has been CANCELLED."
                )
                return Response({"error": "Gate Pass has been cancelled."}, status=status.HTTP_403_FORBIDDEN)
            else:
                # Handle other unexpected statuses
                GateLog.objects.create(
                    gate_pass=gate_pass,
                    timestamp=datetime.now(),
                    scanned_by=request.user,
                    scan_status=GateLog.FAILED,
                    scanned_data=qr_code_data,
                    error_message=f"Gate Pass has an unrecognized status: {gate_pass.status}"
                )
                return Response({"error": f"Gate Pass has an unrecognized status: {gate_pass.get_status_display()}."}, status=status.HTTP_400_BAD_REQUEST)

        except GatePass.DoesNotExist:
            GateLog.objects.create(
                timestamp=datetime.now(),
                scanned_by=request.user,
                scan_status=GateLog.FAILED,
                scanned_data=qr_code_data,
                error_message="Gate Pass not found."
            )
            return Response({"error": "Gate Pass not found."}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            # Catch any other unexpected errors during lookup or processing
            GateLog.objects.create(
                timestamp=datetime.now(),
                scanned_by=request.user,
                scan_status=GateLog.FAILED,
                scanned_data=qr_code_data,
                error_message=f"An unexpected error occurred: {str(e)}"
            )
            return Response({"error": f"An unexpected error occurred: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# GateLog ViewSet - Typically only viewable by Admins/Staff for auditing
class GateLogViewSet(viewsets.ReadOnlyModelViewSet): # ReadOnly because logs shouldn't be created/updated via API generally
    queryset = GateLog.objects.all()
    serializer_class = GateLogSerializer
    permission_classes = [permissions.IsAdminUser] # Only Admin/Staff can view logs
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from apps.gatepass.models import GatePass
from .models import GateLog

class ScanQRCodeView(APIView):
    def post(self, request, *args, **kwargs):
        qr_code_data = request.data.get('qr_code_data')
        if not qr_code_data:
            return Response({'error': 'QR code data is required'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            gate_pass_id = int(qr_code_data.split(': ')[1])
            gate_pass = GatePass.objects.get(id=gate_pass_id)
            if gate_pass.status == 'approved':
                GateLog.objects.create(
                    gate_pass=gate_pass,
                    user=request.user,
                    action='scan',
                    status='success',
                )
                return Response({'status': 'valid', 'gate_pass_id': gate_pass.id})
            else:
                GateLog.objects.create(
                    gate_pass=gate_pass,
                    user=request.user,
                    action='scan',
                    status='failure',
                    reason='Gate pass not approved',
                )
                return Response({'status': 'invalid', 'reason': 'Gate pass is not approved'}, status=status.HTTP_400_BAD_REQUEST)
        except (GatePass.DoesNotExist, IndexError, ValueError):
            GateLog.objects.create(
                user=request.user,
                action='scan',
                status='failure',
                reason='Invalid QR code',
            )
            return Response({'status': 'invalid', 'reason': 'Invalid QR code'}, status=status.HTTP_400_BAD_REQUEST)

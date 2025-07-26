from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import GatePass
from .serializers import GatePassSerializer
import qrcode
from django.core.files.base import ContentFile
from io import BytesIO

class GatePassViewSet(viewsets.ModelViewSet):
    queryset = GatePass.objects.all()
    serializer_class = GatePassSerializer

    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        gate_pass = self.get_object()
        gate_pass.status = 'approved'
        gate_pass.approved_by = request.user
        gate_pass.save()

        # Generate QR code
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_L,
            box_size=10,
            border=4,
        )
        qr.add_data(f"Gate Pass ID: {gate_pass.id}")
        qr.make(fit=True)

        img = qr.make_image(fill_color="black", back_color="white")
        buffer = BytesIO()
        img.save(buffer, format="PNG")
        gate_pass.qr_code.save(f'qr_code_{gate_pass.id}.png', ContentFile(buffer.getvalue()))

        return Response({'status': 'Gate pass approved'})

    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        gate_pass = self.get_object()
        gate_pass.status = 'rejected'
        gate_pass.save()
        return Response({'status': 'Gate pass rejected'})

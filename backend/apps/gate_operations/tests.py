from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase, APIClient
from apps.users.models import CustomUser
from apps.gatepass.models import GatePass, Purpose
from apps.vehicles.models import Vehicle, VehicleType
from apps.drivers.models import Driver
import json

class ScanQRCodeViewTest(APITestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = CustomUser.objects.create_user(username='testuser@example.com', email='testuser@example.com', password='testpassword')
        self.client.force_authenticate(user=self.user)

        self.purpose = Purpose.objects.create(name='Test Purpose')
        self.vehicle_type = VehicleType.objects.create(name='Test Vehicle Type')
        self.vehicle = Vehicle.objects.create(vehicle_number='TEST 123', type=self.vehicle_type, make='Test Make', model='Test Model', capacity='1', registration_date='2024-01-01')
        self.driver = Driver.objects.create(name='Test Driver', license_number='12345')

        self.approved_gate_pass = GatePass.objects.create(
            purpose=self.purpose,
            vehicle=self.vehicle,
            driver=self.driver,
            status=GatePass.APPROVED,
            created_by=self.user,
            person_name='Test Person',
            person_phone='1234567890',
            entry_time='2024-01-01T12:00:00Z',
            exit_time='2024-01-01T13:00:00Z'
        )

        self.pending_gate_pass = GatePass.objects.create(
            purpose=self.purpose,
            vehicle=self.vehicle,
            driver=self.driver,
            status=GatePass.PENDING,
            created_by=self.user,
            person_name='Test Person',
            person_phone='1234567890',
            entry_time='2024-01-01T12:00:00Z',
            exit_time='2024-01-01T13:00:00Z'
        )

    def test_scan_approved_gate_pass(self):
        url = reverse('scan_qr_code')
        qr_code_data = json.dumps({'gatepass_id': self.approved_gate_pass.id})
        data = {'qr_code_data': qr_code_data}
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['message'], 'Gate Pass Validated Successfully!')

    def test_scan_pending_gate_pass(self):
        url = reverse('scan_qr_code')
        qr_code_data = json.dumps({'gatepass_id': self.pending_gate_pass.id})
        data = {'qr_code_data': qr_code_data}
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        self.assertEqual(response.data['error'], 'Gate Pass has status: Pending')

    def test_scan_invalid_qr_code(self):
        url = reverse('scan_qr_code')
        data = {'qr_code_data': 'invalid_json'}
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data['error'], 'Invalid QR code data format.')

    def test_scan_missing_qr_code(self):
        url = reverse('scan_qr_code')
        data = {}
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_scan_gate_pass_not_found(self):
        url = reverse('scan_qr_code')
        qr_code_data = json.dumps({'gatepass_id': 999})
        data = {'qr_code_data': qr_code_data}
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.assertEqual(response.data['error'], 'Gate Pass not found.')

from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase, APIClient
from apps.users.models import CustomUser
from apps.gatepass.models import GatePass, Purpose, Vehicle, Driver
from apps.core_data.models import VehicleType
import json
from datetime import date

class GateOperationsTests(APITestCase):
    def setUp(self):
        self.user = CustomUser.objects.create_user(username='testuser', email='testuser@example.com', password='password')
        self.client = APIClient()
        self.client.force_authenticate(user=self.user)
        self.purpose = Purpose.objects.create(name='Test Purpose')
        self.vehicle_type = VehicleType.objects.create(name='Test Type')
        self.vehicle = Vehicle.objects.create(
            vehicle_number='TEST 1234',
            type=self.vehicle_type,
            make='Test Make',
            model='Test Model',
            capacity='1',
            status='Active',
            registration_date=date.today()
        )
        self.driver = Driver.objects.create(name='Test Driver')

    def test_verify_qr_code_valid(self):
        gate_pass = GatePass.objects.create(
            created_by=self.user,
            person_name="test",
            person_phone="12345",
            entry_time="2025-01-01T12:00:00Z",
            exit_time="2025-01-01T13:00:00Z",
            status='APPROVED',
            purpose=self.purpose,
            vehicle=self.vehicle,
            driver=self.driver
        )
        qr_data = json.dumps({'gatepass_id': gate_pass.id})
        url = reverse('scan_qr_code')
        data = {'qr_code_data': qr_data}
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['message'], 'Gate Pass Validated Successfully!')

    def test_verify_qr_code_invalid(self):
        url = reverse('scan_qr_code')
        data = {'qr_code_data': 'invalid_qr_code'}
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', response.data)

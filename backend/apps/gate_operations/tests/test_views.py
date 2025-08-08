from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase, APIClient
from apps.users.models import CustomUser
from apps.gatepass.models import GatePass, Purpose, Vehicle, Driver
from ..models import GateLog
from apps.core_data.models import VehicleType, Gate
import json
from datetime import date

class GateOperationsTests(APITestCase):
    def setUp(self):
        self.user = CustomUser.objects.create_user(username='testuser', email='testuser@example.com', password='password', is_staff=True)
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
        self.gate_main = Gate.objects.create(name='Main Gate')
        self.gate_service = Gate.objects.create(name='Service Gate')

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
        self.assertEqual(response.data['message'], 'Gate Pass Validated for Entry Successfully!')

    def test_verify_qr_code_invalid(self):
        url = reverse('scan_qr_code')
        data = {'qr_code_data': 'invalid_qr_code'}
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', response.data)

    def test_scan_for_entry_and_exit(self):
        """
        Tests that the first scan logs an 'entry' and the second scan logs an 'exit'.
        """
        gate_pass = GatePass.objects.create(
            created_by=self.user,
            person_name="test entry exit",
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

        # First scan: Should be an entry
        response_entry = self.client.post(url, data, format='json')
        self.assertEqual(response_entry.status_code, status.HTTP_200_OK)
        self.assertIn('Validated for Entry', response_entry.data['message'])

        # Verify the GateLog for entry
        self.assertTrue(
            GateLog.objects.filter(gate_pass=gate_pass, action='entry', status='success').exists()
        )

        # Second scan: Should be an exit
        response_exit = self.client.post(url, data, format='json')
        self.assertEqual(response_exit.status_code, status.HTTP_200_OK)
        self.assertIn('Validated for Exit', response_exit.data['message'])

        # Verify the GateLog for exit
        self.assertTrue(
            GateLog.objects.filter(gate_pass=gate_pass, action='exit', status='success').exists()
        )

    def test_filter_gate_logs(self):
        """
        Tests that the GateLog list endpoint can be filtered.
        """
        # Create some test data
        GateLog.objects.create(
            security_personnel=self.user, action='entry', status='success', gate=self.gate_main
        )
        GateLog.objects.create(
            security_personnel=self.user, action='exit', status='success', gate=self.gate_main
        )
        GateLog.objects.create(
            security_personnel=self.user, action='scan_attempt', status='failure', gate=self.gate_service
        )

        url = reverse('gatelog-list')

        # Test filtering by action
        response = self.client.get(url, {'action': 'entry'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['action'], 'entry')

        # Test filtering by status
        response = self.client.get(url, {'status': 'failure'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['status'], 'failure')

        # Test filtering by gate
        response = self.client.get(url, {'gate': self.gate_service.id})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['gate']['id'], self.gate_service.id)

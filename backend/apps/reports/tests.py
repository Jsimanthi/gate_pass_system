from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from apps.users.models import CustomUser
from apps.gatepass.models import GatePass
from apps.core_data.models import Purpose, Gate, VehicleType
from apps.vehicles.models import Vehicle
from apps.drivers.models import Driver
from apps.gate_operations.models import GateLog
from django.contrib.auth.models import Group
from django.utils import timezone
import datetime

class ReportViewSetTests(APITestCase):
    def setUp(self):
        self.admin_user = CustomUser.objects.create_user(username='admin', password='password123', is_staff=True, is_superuser=True)
        self.client.force_authenticate(user=self.admin_user)
        self.purpose_meeting, _ = Purpose.objects.get_or_create(name='Meeting')
        self.purpose_delivery, _ = Purpose.objects.get_or_create(name='Delivery')
        self.gate_main, _ = Gate.objects.get_or_create(name='Main Gate')
        self.gate_service, _ = Gate.objects.get_or_create(name='Service Gate')
        self.vehicle_type, _ = VehicleType.objects.get_or_create(name='Truck')
        self.driver, _ = Driver.objects.get_or_create(name='Test Driver')
        self.vehicle = Vehicle.objects.create(
            vehicle_number='TEST 123', type=self.vehicle_type, make='Test Make', model='Test Model',
            capacity='1 ton', status='Active', registration_date=timezone.now().date()
        )

        today = timezone.now()
        self.yesterday = today - datetime.timedelta(days=1)

        GatePass.objects.create(
            person_name='John Doe', entry_time=today, exit_time=today + datetime.timedelta(hours=8),
            purpose=self.purpose_meeting, gate=self.gate_main, status=GatePass.APPROVED,
            created_by=self.admin_user, vehicle=self.vehicle, driver=self.driver
        )
        GatePass.objects.create(
            person_name='Jane Smith', entry_time=today, exit_time=today + datetime.timedelta(hours=2),
            purpose=self.purpose_delivery, gate=self.gate_service, status=GatePass.PENDING,
            created_by=self.admin_user, vehicle=self.vehicle, driver=self.driver
        )
        self.yesterdays_pass = GatePass.objects.create(
            person_name='Peter Jones', entry_time=self.yesterday, exit_time=self.yesterday + datetime.timedelta(hours=8),
            purpose=self.purpose_meeting, gate=self.gate_main, status=GatePass.REJECTED,
            created_by=self.admin_user, vehicle=self.vehicle, driver=self.driver
        )
        GateLog.objects.create(
            gate_pass=self.yesterdays_pass, security_personnel=self.admin_user,
            status='failure', reason='Test incident'
        )

    def test_daily_visitor_summary_unfiltered(self):
        url = reverse('report-daily-summary')
        response = self.client.get(url, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['total_gate_passes'], 3)

    def test_daily_summary_filter_by_date(self):
        url = reverse('report-daily-summary')
        yesterday_str = self.yesterday.strftime('%Y-%m-%d')
        response = self.client.get(url, {'start_date': yesterday_str, 'end_date': yesterday_str}, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['total_gate_passes'], 1)
        self.assertEqual(response.data['unique_visitors'], 1)

    def test_monthly_visitor_summary(self):
        url = reverse('report-monthly-summary')
        response = self.client.get(url, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['total_gate_passes'], 3)

    def test_driver_performance_report(self):
        url = reverse('report-driver-performance')
        response = self.client.get(url, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['total_gate_passes'], 3)

    def test_security_incident_report(self):
        url = reverse('report-security-incidents')
        response = self.client.get(url, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['reason'], 'Test incident')

    def test_daily_summary_filter_by_status(self):
        url = reverse('report-daily-summary')
        response = self.client.get(url, {'status': GatePass.APPROVED}, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['total_gate_passes'], 1)

    def test_daily_summary_filter_by_purpose(self):
        url = reverse('report-daily-summary')
        response = self.client.get(url, {'purpose': self.purpose_delivery.id}, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['total_gate_passes'], 1)

    def test_daily_summary_filter_by_gate(self):
        url = reverse('report-daily-summary')
        response = self.client.get(url, {'gate': self.gate_service.id}, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['total_gate_passes'], 1)

    def test_export_daily_summary_as_csv(self):
        url = reverse('report-daily-summary-export')
        response = self.client.get(url, {'format': 'csv'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response['Content-Type'], 'text/csv')
        self.assertIn('Content-Disposition', response)

    def test_export_daily_summary_as_pdf(self):
        url = reverse('report-daily-summary-export')
        response = self.client.get(url, {'format': 'pdf'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response['Content-Type'], 'application/pdf')
        self.assertIn('Content-Disposition', response)

    def test_export_with_invalid_format(self):
        url = reverse('report-daily-summary-export')
        response = self.client.get(url, {'format': 'xml'})
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', response.data)

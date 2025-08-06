from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from apps.users.models import CustomUser
from apps.gatepass.models import GatePass, Purpose, Gate
from apps.vehicles.models import Vehicle
from apps.core_data.models import VehicleType
from apps.drivers.models import Driver
from apps.gate_operations.models import GateLog
from django.contrib.auth.models import Group
from django.utils import timezone
import datetime

class ReportViewSetTests(APITestCase):
    def setUp(self):
        # Create groups
        self.admin_group = Group.objects.create(name='Admin')

        # Create users
        self.admin_user = CustomUser.objects.create_user(username='admin', password='password123', is_staff=True)
        self.admin_user.groups.add(self.admin_group)
        self.client.force_authenticate(user=self.admin_user)

        # Create test data
        self.purpose = Purpose.objects.create(name='Meeting')
        self.gate = Gate.objects.create(name='Main Gate')
        self.vehicle_type = VehicleType.objects.create(name='Truck')
        self.vehicle = Vehicle.objects.create(
            vehicle_number='TEST 123',
            type=self.vehicle_type,
            make='Test Make',
            model='Test Model',
            capacity='1 ton',
            status='Active',
            registration_date=timezone.now().date()
        )
        self.driver = Driver.objects.create(name='Test Driver')

        # Create gate passes
        today = timezone.now().date()
        self.gate_pass = GatePass.objects.create(
            person_name='John Doe',
            entry_time=timezone.make_aware(datetime.datetime.combine(today, datetime.time(9, 0))),
            exit_time=timezone.make_aware(datetime.datetime.combine(today, datetime.time(17, 0))),
            purpose=self.purpose,
            gate=self.gate,
            vehicle=self.vehicle,
            driver=self.driver,
            created_by=self.admin_user
        )

        # Create a security incident
        GateLog.objects.create(
            gate_pass=self.gate_pass,
            security_personnel=self.admin_user,
            status='failure',
            reason='Test incident'
        )

    def test_daily_visitor_summary(self):
        url = reverse('report-daily-visitor-summary')
        response = self.client.get(url, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['total_gate_passes'], 1)
        self.assertEqual(response.data['unique_visitors'], 1)
        self.assertEqual(response.data['unique_vehicles'], 1)

    def test_monthly_visitor_summary(self):
        url = reverse('report-monthly-visitor-summary')
        response = self.client.get(url, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['total_gate_passes'], 1)

    def test_driver_performance_report(self):
        url = reverse('report-driver-performance-report')
        response = self.client.get(url, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['driver__name'], 'Test Driver')

    def test_security_incident_report(self):
        url = reverse('report-security-incident-report')
        response = self.client.get(url, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['reason'], 'Test incident')

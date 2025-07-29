from django.test import TestCase
from apps.users.models import CustomUser
from apps.gatepass.models import GatePass
from apps.gate_operations.models import GateLog

class GateLogModelTests(TestCase):
    def setUp(self):
        self.user = CustomUser.objects.create_user(username='testuser', email='testuser@example.com', password='password')
        self.gate_pass = GatePass.objects.create(
            created_by=self.user,
            person_name="test",
            person_phone="12345",
            entry_time="2025-01-01T12:00:00Z",
            exit_time="2025-01-01T13:00:00Z",
            status='APPROVED'
        )

    def test_create_gate_log(self):
        GateLog.objects.create(
            gate_pass=self.gate_pass,
            security_personnel=self.user,
            action='entry',
            status='success'
        )
        self.assertEqual(GateLog.objects.count(), 1)

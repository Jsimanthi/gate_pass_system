from django.test import TestCase
from .models import GatePass, GatePassHistory, Purpose
from apps.users.models import CustomUser

class GatePassSignalTests(TestCase):
    def setUp(self):
        self.user = CustomUser.objects.create_user(username='testuser', password='password123')
        self.purpose = Purpose.objects.create(name='Test Purpose')

    def test_history_is_created_on_gatepass_creation(self):
        """
        Tests that a GatePassHistory entry is created when a GatePass is created.
        """
        initial_history_count = GatePassHistory.objects.count()

        gate_pass = GatePass.objects.create(
            person_name="Signal Test",
            person_phone="123",
            entry_time="2025-01-01T12:00:00Z",
            exit_time="2025-01-01T13:00:00Z",
            purpose=self.purpose,
            created_by=self.user
        )

        self.assertEqual(GatePassHistory.objects.count(), initial_history_count + 1)
        history_entry = GatePassHistory.objects.latest('timestamp')
        self.assertEqual(history_entry.gate_pass, gate_pass)
        self.assertEqual(history_entry.action, 'CREATED')

    def test_history_is_created_on_status_change(self):
        """
        Tests that a GatePassHistory entry is created when a GatePass status changes.
        """
        gate_pass = GatePass.objects.create(
            person_name="Status Change Test",
            person_phone="456",
            entry_time="2025-02-01T12:00:00Z",
            exit_time="2025-02-01T13:00:00Z",
            purpose=self.purpose,
            created_by=self.user,
            status=GatePass.PENDING
        )

        initial_history_count = GatePassHistory.objects.count()

        # Now, change the status
        gate_pass.status = GatePass.APPROVED
        gate_pass.approved_by = self.user
        gate_pass.save()

        self.assertEqual(GatePassHistory.objects.count(), initial_history_count + 1)
        history_entry = GatePassHistory.objects.latest('timestamp')
        self.assertEqual(history_entry.action, 'STATUS_CHANGED')
        self.assertIn('from PENDING to APPROVED', history_entry.details)

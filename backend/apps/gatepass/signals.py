from django.db.models.signals import pre_save, post_save
from django.dispatch import receiver
from fcm_django.models import FCMDevice
from .models import GatePass, GatePassHistory, VisitorPass
from django.contrib.auth.models import Group

@receiver(pre_save, sender=GatePass)
def store_old_status_on_instance(sender, instance, **kwargs):
    """
    When a GatePass is about to be saved, this signal handler fetches the
    current status from the database and attaches it to the instance.
    This allows the post_save handler to compare the old and new status.
    """
    if instance.pk:
        try:
            # Store the old status in a temporary attribute on the instance
            instance._old_status = GatePass.objects.get(pk=instance.pk).status
        except GatePass.DoesNotExist:
            # This case happens if the instance is being created, so no old status
            instance._old_status = None
    else:
        instance._old_status = None

@receiver(post_save, sender=GatePass)
def log_gate_pass_history_on_save(sender, instance, created, **kwargs):
    """
    Logs changes to the GatePass model in the GatePassHistory, especially
    for creation and status changes.
    """
    user = instance.approved_by if instance.approved_by else instance.created_by
    action = ''
    details = ''

    if created:
        action = 'CREATED'
        details = f'Gate pass created for {instance.person_name}.'
    elif hasattr(instance, '_old_status') and instance._old_status != instance.status:
        # Check if the status has changed by comparing with the old status
        action = 'STATUS_CHANGED'
        details = f'Status changed from {instance._old_status} to {instance.status}.'

        # Send a push notification to the user who created the gate pass
        if instance.created_by:
            devices = FCMDevice.objects.filter(user=instance.created_by, active=True)
            devices.send_message(
                title="Gate Pass Status Updated",
                body=f"Your gate pass for {instance.person_name} has been {instance.get_status_display()}.",
                data={"gatepass_id": str(instance.id)} # Send ID to allow app to navigate
            )

    # We only create a history entry if an action was determined (creation or status change)
    if action:
        GatePassHistory.objects.create(
            gate_pass=instance,
            user=user,
            action=action,
            details=details
        )


@receiver(post_save, sender=VisitorPass)
def send_visitor_pass_notifications(sender, instance, created, **kwargs):
    """
    Sends push notifications when a VisitorPass is created or approved.
    """
    if created:
        # Notify the employee being visited
        try:
            employee_to_visit = instance.whom_to_visit
            devices = FCMDevice.objects.filter(user=employee_to_visit, active=True)
            if devices.exists():
                devices.send_message(
                    title="New Visitor Request",
                    body=f"You have a new visitor request from {instance.visitor_name}.",
                    data={"visitor_pass_id": str(instance.id), "type": "visitor_request"}
                )
        except Exception as e:
            print(f"Error sending notification to employee: {e}")

    else:
        # A more robust way is to check if the status was changed in this save operation.
        # For simplicity, we assume if status is approved, a notification should be sent.
        if instance.status == VisitorPass.APPROVED:
            try:
                # Notify all users in the 'Security' group
                security_group = Group.objects.get(name='Security')
                security_users = security_group.user_set.all()
                devices = FCMDevice.objects.filter(user__in=security_users, active=True)
                if devices.exists():
                    devices.send_message(
                        title="Visitor Approved",
                        body=f"{instance.visitor_name} has been approved to visit {instance.whom_to_visit.get_full_name()}.",
                        data={"visitor_pass_id": str(instance.id), "type": "visitor_approved"}
                    )
            except Group.DoesNotExist:
                print("Security group not found. Cannot send notification.")
            except Exception as e:
                print(f"Error sending notification to security: {e}")

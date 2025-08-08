from django.db.models.signals import pre_save, post_save
from django.dispatch import receiver
from .models import GatePass, GatePassHistory

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

    # We only create a history entry if an action was determined (creation or status change)
    if action:
        GatePassHistory.objects.create(
            gate_pass=instance,
            user=user,
            action=action,
            details=details
        )

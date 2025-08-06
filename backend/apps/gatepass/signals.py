from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import GatePass, GatePassHistory
from django.core.exceptions import ObjectDoesNotExist

@receiver(post_save, sender=GatePass)
def create_gate_pass_history(sender, instance, created, **kwargs):
    user = None
    action = ''
    details = ''

    try:
        if created:
            action = 'CREATED'
            user = instance.created_by
            details = f'Gate pass created for {instance.person_name}.'
        else:
            # Check for status changes
            try:
                old_instance = GatePass.objects.get(pk=instance.pk)
                if old_instance.status != instance.status:
                    action = instance.status
                    user = instance.approved_by
                    details = f'Gate pass status changed to {instance.status}.'
                else:
                    action = 'UPDATED'
                    # It's hard to get the user who updated the instance here.
                    # We can leave it as None or try to get it from somewhere else.
                    # For now, we will leave it as None.
                    details = 'Gate pass details updated.'
            except ObjectDoesNotExist:
                # This should not happen in a post_save signal, but as a fallback
                action = 'UPDATED'
                details = 'Gate pass details updated.'

        if action:
            GatePassHistory.objects.create(
                gate_pass=instance,
                user=user,
                action=action,
                details=details
            )
    except Exception as e:
        # It's good practice to log the exception
        print(f"Error in create_gate_pass_history signal: {e}")

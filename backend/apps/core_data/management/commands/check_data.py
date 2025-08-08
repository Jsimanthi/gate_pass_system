from django.core.management.base import BaseCommand
from apps.core_data.models import Gate, Purpose

class Command(BaseCommand):
    help = 'Checks and prints the data in the Gate and Purpose tables to verify if the initial data migration has run successfully against the connected database.'

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('--- Checking Core Data ---'))

        # Check Gates
        self.stdout.write(self.style.WARNING('\nChecking Gates...'))
        gates = Gate.objects.all()
        if gates.exists():
            self.stdout.write(self.style.SUCCESS(f'Found {gates.count()} Gate(s):'))
            for gate in gates:
                self.stdout.write(f'- ID: {gate.id}, Name: {gate.name}')
        else:
            self.stdout.write(self.style.ERROR('No Gates found in the database.'))

        # Check Purposes
        self.stdout.write(self.style.WARNING('\nChecking Purposes...'))
        purposes = Purpose.objects.all()
        if purposes.exists():
            self.stdout.write(self.style.SUCCESS(f'Found {purposes.count()} Purpose(s):'))
            for purpose in purposes:
                self.stdout.write(f'- ID: {purpose.id}, Name: {purpose.name}')
        else:
            self.stdout.write(self.style.ERROR('No Purposes found in the database.'))

        self.stdout.write(self.style.SUCCESS('\n--- Check Complete ---'))

        if not gates.exists() or not purposes.exists():
            self.stdout.write(self.style.ERROR('\nOne or both tables are empty. Please ensure you have run "python manage.py migrate" against the correct database that your Django application is configured to use.'))

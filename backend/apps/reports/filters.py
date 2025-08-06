import django_filters
from apps.gatepass.models import GatePass

import django_filters
from apps.gatepass.models import GatePass
from apps.gate_operations.models import GateLog

class GatePassFilter(django_filters.FilterSet):
    start_date = django_filters.DateFilter(field_name="entry_time", lookup_expr='gte')
    end_date = django_filters.DateFilter(field_name="entry_time", lookup_expr='lte')

    class Meta:
        model = GatePass
        fields = ['gate', 'purpose', 'status']

class GateLogFilter(django_filters.FilterSet):
    start_date = django_filters.DateFilter(field_name="timestamp", lookup_expr='gte')
    end_date = django_filters.DateFilter(field_name="timestamp", lookup_expr='lte')

    class Meta:
        model = GateLog
        fields = ['gate', 'security_personnel', 'status']

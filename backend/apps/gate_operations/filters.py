import django_filters
from .models import GateLog

class GateLogFilter(django_filters.FilterSet):
    start_date = django_filters.DateFilter(field_name="timestamp", lookup_expr='gte')
    end_date = django_filters.DateFilter(field_name="timestamp", lookup_expr='lte')

    class Meta:
        model = GateLog
        fields = ['gate', 'action', 'status', 'security_personnel']

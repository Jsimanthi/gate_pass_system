from rest_framework import generics
from rest_framework.response import Response
from rest_framework.views import APIView
from apps.gate_operations.models import GateLog
from .serializers import GateLogSerializer
from django.db.models import Count

class GateLogListView(generics.ListAPIView):
    queryset = GateLog.objects.all()
    serializer_class = GateLogSerializer

class GateLogSummaryView(APIView):
    def get(self, request, *args, **kwargs):
        total_entries = GateLog.objects.count()
        successful_entries = GateLog.objects.filter(status='success').count()
        failed_entries = GateLog.objects.filter(status='failure').count()

        summary = {
            'total_entries': total_entries,
            'successful_entries': successful_entries,
            'failed_entries': failed_entries,
        }

        return Response(summary)

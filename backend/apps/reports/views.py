from rest_framework import viewsets
from rest_framework.response import Response
from rest_framework.decorators import action
from django.utils import timezone
from apps.gatepass.models import GatePass
from apps.gate_operations.models import GateLog
from apps.gate_operations.serializers import GateLogSerializer
from django.db.models import Count
from .filters import GatePassFilter, GateLogFilter
from django.http import HttpResponse
import csv
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle
from reportlab.lib import colors
from datetime import timedelta
from django.utils.decorators import method_decorator
from django.views.decorators.cache import cache_page

class ReportViewSet(viewsets.GenericViewSet):
    @method_decorator(cache_page(60 * 15))
    @action(detail=False, methods=['get'], url_path='daily-summary', url_name='daily-summary')
    def daily_visitor_summary(self, request):
        filterset = GatePassFilter(request.query_params, queryset=GatePass.objects.all())
        gate_passes = filterset.qs

        total_gate_passes = gate_passes.count()
        unique_visitors = gate_passes.values('person_name').distinct().count()
        unique_vehicles = gate_passes.filter(vehicle__isnull=False).values('vehicle').distinct().count()

        summary = {
            'filters': request.query_params,
            'total_gate_passes': total_gate_passes,
            'unique_visitors': unique_visitors,
            'unique_vehicles': unique_vehicles,
        }
        return Response(summary)

    @action(detail=False, methods=['get'], url_path='daily-summary/export', url_name='daily-summary-export')
    def daily_visitor_summary_export(self, request):
        filterset = GatePassFilter(request.query_params, queryset=GatePass.objects.all())
        gate_passes = filterset.qs

        data = gate_passes.values_list('person_name', 'person_nid', 'person_phone', 'entry_time', 'exit_time', 'purpose__name', 'vehicle__vehicle_number')
        export_format = request.query_params.get('format')

        if export_format == 'csv':
            response = HttpResponse(content_type='text/csv')
            response['Content-Disposition'] = f'attachment; filename="daily_visitor_summary_{timezone.now().strftime("%Y-%m-%d")}.csv"'
            writer = csv.writer(response)
            writer.writerow(['Person Name', 'NID', 'Phone', 'Entry Time', 'Exit Time', 'Purpose', 'Vehicle Number'])
            for row in data:
                writer.writerow(row)
            return response

        elif export_format == 'pdf':
            response = HttpResponse(content_type='application/pdf')
            response['Content-Disposition'] = f'attachment; filename="daily_visitor_summary_{timezone.now().strftime("%Y-%m-%d")}.pdf"'
            doc = SimpleDocTemplate(response)
            elements = []
            table_data = [['Person Name', 'NID', 'Phone', 'Entry Time', 'Exit Time', 'Purpose', 'Vehicle Number']]
            table_data.extend(list(data))
            table = Table(table_data)
            style = TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
                ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
                ('GRID', (0,0), (-1,-1), 1, colors.black)
            ])
            table.setStyle(style)
            elements.append(table)
            doc.build(elements)
            return response

        else:
            return Response({'error': 'Invalid format. Please use "csv" or "pdf".'}, status=400)

    @method_decorator(cache_page(60 * 15))
    @action(detail=False, methods=['get'], url_path='monthly-summary', url_name='monthly-summary')
    def monthly_visitor_summary(self, request):
        filterset = GatePassFilter(request.query_params, queryset=GatePass.objects.all())
        gate_passes = filterset.qs

        try:
            year = int(request.query_params.get('year', timezone.now().year))
            month = int(request.query_params.get('month', timezone.now().month))
            gate_passes = gate_passes.filter(entry_time__year=year, entry_time__month=month)
        except (ValueError, TypeError):
            pass

        total_gate_passes = gate_passes.count()
        unique_visitors = gate_passes.values('person_name').distinct().count()
        unique_vehicles = gate_passes.filter(vehicle__isnull=False).values('vehicle').distinct().count()

        summary = {
            'filters': request.query_params,
            'total_gate_passes': total_gate_passes,
            'unique_visitors': unique_visitors,
            'unique_vehicles': unique_vehicles,
        }
        return Response(summary)

    @action(detail=False, methods=['get'], url_path='monthly-summary/export', url_name='monthly-summary-export')
    def monthly_visitor_summary_export(self, request):
        filterset = GatePassFilter(request.query_params, queryset=GatePass.objects.all())
        gate_passes = filterset.qs

        try:
            year = int(request.query_params.get('year', timezone.now().year))
            month = int(request.query_params.get('month', timezone.now().month))
            gate_passes = gate_passes.filter(entry_time__year=year, entry_time__month=month)
        except (ValueError, TypeError):
            pass

        data = gate_passes.values_list('person_name', 'person_nid', 'person_phone', 'entry_time', 'exit_time', 'purpose__name', 'vehicle__vehicle_number')
        export_format = request.query_params.get('format')

        if export_format == 'csv':
            response = HttpResponse(content_type='text/csv')
            response['Content-Disposition'] = 'attachment; filename="monthly_visitor_summary.csv"'
            writer = csv.writer(response)
            writer.writerow(['Person Name', 'NID', 'Phone', 'Entry Time', 'Exit Time', 'Purpose', 'Vehicle Number'])
            for row in data:
                writer.writerow(row)
            return response

        elif export_format == 'pdf':
            response = HttpResponse(content_type='application/pdf')
            response['Content-Disposition'] = 'attachment; filename="monthly_visitor_summary.pdf"'
            doc = SimpleDocTemplate(response)
            elements = []
            table_data = [['Person Name', 'NID', 'Phone', 'Entry Time', 'Exit Time', 'Purpose', 'Vehicle Number']]
            table_data.extend(list(data))
            table = Table(table_data)
            table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
                ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
                ('GRID', (0,0), (-1,-1), 1, colors.black)
            ]))
            elements.append(table)
            doc.build(elements)
            return response
        else:
            return Response({'error': 'Invalid format. Please use "csv" or "pdf".'}, status=400)

    @method_decorator(cache_page(60 * 15))
    @action(detail=False, methods=['get'], url_path='driver-performance', url_name='driver-performance')
    def driver_performance_report(self, request):
        filterset = GatePassFilter(request.query_params, queryset=GatePass.objects.all())
        gate_passes = filterset.qs
        driver_performance = gate_passes.filter(driver__isnull=False).values('driver__name').annotate(
            total_gate_passes=Count('id')
        ).order_by('-total_gate_passes')
        return Response(driver_performance)

    @action(detail=False, methods=['get'], url_path='driver-performance/export', url_name='driver-performance-export')
    def driver_performance_report_export(self, request):
        filterset = GatePassFilter(request.query_params, queryset=GatePass.objects.all())
        gate_passes = filterset.qs
        driver_performance = gate_passes.filter(driver__isnull=False).values('driver__name').annotate(
            total_gate_passes=Count('id')
        ).order_by('-total_gate_passes')
        export_format = request.query_params.get('format')

        if export_format == 'csv':
            response = HttpResponse(content_type='text/csv')
            response['Content-Disposition'] = 'attachment; filename="driver_performance_report.csv"'
            writer = csv.writer(response)
            writer.writerow(['Driver Name', 'Total Gate Passes'])
            for row in driver_performance:
                writer.writerow(row.values())
            return response
        elif export_format == 'pdf':
            response = HttpResponse(content_type='application/pdf')
            response['Content-Disposition'] = 'attachment; filename="driver_performance_report.pdf"'
            doc = SimpleDocTemplate(response)
            elements = []
            table_data = [['Driver Name', 'Total Gate Passes']]
            table_data.extend(list(driver_performance.values_list('driver__name', 'total_gate_passes')))
            table = Table(table_data)
            table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
                ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
                ('GRID', (0,0), (-1,-1), 1, colors.black)
            ]))
            elements.append(table)
            doc.build(elements)
            return response
        else:
            return Response({'error': 'Invalid format. Please use "csv" or "pdf".'}, status=400)

    @method_decorator(cache_page(60 * 15))
    @action(detail=False, methods=['get'], url_path='security-incidents', url_name='security-incidents')
    def security_incident_report(self, request):
        filterset = GateLogFilter(request.query_params, queryset=GateLog.objects.filter(status='failure'))
        incidents = filterset.qs
        serializer = GateLogSerializer(incidents, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='security-incidents/export', url_name='security-incidents-export')
    def security_incident_report_export(self, request):
        filterset = GateLogFilter(request.query_params, queryset=GateLog.objects.filter(status='failure'))
        incidents = filterset.qs
        data = incidents.values_list('gate_pass__person_name', 'security_personnel__username', 'timestamp', 'reason')
        export_format = request.query_params.get('format')

        if export_format == 'csv':
            response = HttpResponse(content_type='text/csv')
            response['Content-Disposition'] = 'attachment; filename="security_incident_report.csv"'
            writer = csv.writer(response)
            writer.writerow(['Person Name', 'Security Personnel', 'Timestamp', 'Reason'])
            for row in data:
                writer.writerow(row)
            return response
        elif export_format == 'pdf':
            response = HttpResponse(content_type='application/pdf')
            response['Content-Disposition'] = 'attachment; filename="security_incident_report.pdf"'
            doc = SimpleDocTemplate(response)
            elements = []
            table_data = [['Person Name', 'Security Personnel', 'Timestamp', 'Reason']]
            table_data.extend(list(data))
            table = Table(table_data)
            table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
                ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
                ('GRID', (0,0), (-1,-1), 1, colors.black)
            ]))
            elements.append(table)
            doc.build(elements)
            return response
        else:
            return Response({'error': 'Invalid format. Please use "csv" or "pdf".'}, status=400)

    @action(detail=False, methods=['get'], url_path='data-visualization', url_name='data-visualization')
    def data_visualization(self, request):
        today = timezone.now().date()
        thirty_days_ago = today - timedelta(days=30)
        gate_passes_per_day = GatePass.objects.filter(
            entry_time__date__gte=thirty_days_ago
        ).extra(
            {'date': "date(entry_time)"}
        ).values('date').annotate(count=Count('id')).order_by('date')
        labels = [item['date'] for item in gate_passes_per_day]
        data = [item['count'] for item in gate_passes_per_day]
        chart_data = {
            'labels': labels,
            'data': data,
            'title': 'Gate Passes per Day (Last 30 Days)'
        }
        return Response(chart_data)

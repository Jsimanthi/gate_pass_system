from django.urls import path
from .views import ReportViewSet

urlpatterns = [
    # Data endpoints
    path('daily-summary/', ReportViewSet.as_view({'get': 'daily_visitor_summary'}), name='report-daily-summary'),
    path('monthly-summary/', ReportViewSet.as_view({'get': 'monthly_visitor_summary'}), name='report-monthly-summary'),
    path('driver-performance/', ReportViewSet.as_view({'get': 'driver_performance_report'}), name='report-driver-performance'),
    path('security-incidents/', ReportViewSet.as_view({'get': 'security_incident_report'}), name='report-security-incidents'),
    path('data-visualization/', ReportViewSet.as_view({'get': 'data_visualization'}), name='report-data-visualization'),

    # Export endpoints (restructured)
    path('export/daily-summary/', ReportViewSet.as_view({'get': 'daily_visitor_summary_export'}), name='report-daily-summary-export'),
    path('export/monthly-summary/', ReportViewSet.as_view({'get': 'monthly_visitor_summary_export'}), name='report-monthly-summary-export'),
    path('export/driver-performance/', ReportViewSet.as_view({'get': 'driver_performance_report_export'}), name='report-driver-performance-export'),
    path('export/security-incidents/', ReportViewSet.as_view({'get': 'security_incident_report_export'}), name='report-security-incidents-export'),
]

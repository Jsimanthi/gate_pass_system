from django.urls import path
from .views import ReportViewSet

urlpatterns = [
    path('daily-summary/', ReportViewSet.as_view({'get': 'daily_visitor_summary'}), name='report-daily-summary'),
    path('daily-summary-export/', ReportViewSet.as_view({'get': 'daily_visitor_summary_export'}), name='report-daily-summary-export'),
    path('monthly-summary/', ReportViewSet.as_view({'get': 'monthly_visitor_summary'}), name='report-monthly-summary'),
    path('monthly-summary-export/', ReportViewSet.as_view({'get': 'monthly_visitor_summary_export'}), name='report-monthly-summary-export'),
    path('driver-performance/', ReportViewSet.as_view({'get': 'driver_performance_report'}), name='report-driver-performance'),
    path('driver-performance-export/', ReportViewSet.as_view({'get': 'driver_performance_report_export'}), name='report-driver-performance-export'),
    path('security-incidents/', ReportViewSet.as_view({'get': 'security_incident_report'}), name='report-security-incidents'),
    path('security-incidents-export/', ReportViewSet.as_view({'get': 'security_incident_report_export'}), name='report-security-incidents-export'),
    path('data-visualization/', ReportViewSet.as_view({'get': 'data_visualization'}), name='report-data-visualization'),
]

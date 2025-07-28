from django.urls import path
from .views import GateLogListView, GateLogSummaryView

urlpatterns = [
    path('logs/', GateLogListView.as_view(), name='gate-log-list'),
    path('logs/summary/', GateLogSummaryView.as_view(), name='gate-log-summary'),
]

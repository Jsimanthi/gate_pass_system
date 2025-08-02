from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import GatePassViewSet, DashboardSummaryView

router = DefaultRouter()
router.register(r'gatepasses', GatePassViewSet, basename='gatepass')

urlpatterns = [
    path('', include(router.urls)),
    path('dashboard-summary/', DashboardSummaryView.as_view(), name='dashboard-summary'),
]
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import GatePassViewSet, DashboardSummaryView, PreApprovedVisitorViewSet, GatePassTemplateViewSet

router = DefaultRouter()
router.register(r'gatepasses', GatePassViewSet, basename='gatepass')
router.register(r'pre-approved-visitors', PreApprovedVisitorViewSet, basename='pre-approved-visitor')
router.register(r'gatepass-templates', GatePassTemplateViewSet, basename='gatepass-template')

urlpatterns = [
    path('', include(router.urls)),
    path('dashboard-summary/', DashboardSummaryView.as_view(), name='dashboard-summary'),
]
# users/urls.py
from django.urls import path
from .views import CurrentUserView

urlpatterns = [
    # ... existing URLs
    path('me/', CurrentUserView.as_view(), name='current_user'),
]
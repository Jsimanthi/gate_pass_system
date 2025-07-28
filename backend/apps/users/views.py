# users/views.py (Excerpt)
from rest_framework import generics, permissions
from .serializers import UserSerializer # <--- Make sure this import is there
from django.contrib.auth import get_user_model

User = get_user_model()

class CurrentUserView(generics.RetrieveAPIView):
    serializer_class = UserSerializer # <--- Make sure this is using your UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user
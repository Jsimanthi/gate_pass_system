from rest_framework import generics, permissions
from .serializers import UserSerializer, MyTokenObtainPairSerializer
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.views import TokenObtainPairView

User = get_user_model()

class MyTokenObtainPairView(TokenObtainPairView):
    serializer_class = MyTokenObtainPairSerializer

class CurrentUserView(generics.RetrieveAPIView):
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user


class EmployeeListView(generics.ListAPIView):
    queryset = User.objects.filter(is_active=True).order_by('first_name', 'last_name')
    serializer_class = UserSerializer
    permission_classes = [permissions.AllowAny]
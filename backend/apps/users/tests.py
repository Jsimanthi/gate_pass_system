import pytest
from django.contrib.auth import get_user_model
from fcm_django.models import FCMDevice
from rest_framework.test import APIClient

User = get_user_model()

@pytest.mark.django_db
def test_create_user():
    """
    Tests that a new user can be created.
    """
    user = User.objects.create_user(username='testuser', password='password123')
    assert user.username == 'testuser'
    assert user.is_staff is False
    assert user.is_superuser is False
    assert User.objects.count() == 1

@pytest.mark.django_db
def test_create_superuser():
    """
    Tests that a new superuser can be created.
    """
    admin_user = User.objects.create_superuser(username='adminuser', password='password123', email='admin@test.com')
    assert admin_user.username == 'adminuser'
    assert admin_user.is_staff is True
    assert admin_user.is_superuser is True
    assert User.objects.count() == 1


@pytest.mark.django_db
def test_login_api_success():
    """
    Tests that a user can successfully log in via the API and get JWT tokens.
    """
    client = APIClient()
    # We must create the user first
    User.objects.create_user(username='apiuser', password='apipassword123')

    # Then, we attempt to log in with those credentials
    response = client.post('/api/token/', {
        'username': 'apiuser',
        'password': 'apipassword123'
    })

    # Check if the login was successful
    assert response.status_code == 200

    # Check if the response contains the access and refresh tokens
    data = response.json()
    assert 'access' in data
    assert 'refresh' in data


@pytest.mark.django_db
def test_register_fcm_device():
    """
    Tests that a user can register their FCM device token.
    """
    client = APIClient()
    user = User.objects.create_user(username='fcmuser', password='password123')
    client.force_authenticate(user=user)

    url = '/api/users/devices/'
    data = {
        'registration_id': 'test_device_token_12345',
        'name': 'Test Device',
        'type': 'web'
    }

    response = client.post(url, data, format='json')

    assert response.status_code == 201
    assert FCMDevice.objects.filter(user=user, registration_id='test_device_token_12345').exists()

# Wireless Debugging with Android Device

This document provides instructions on how to set up and use wireless debugging with an Android device for this project.

## 1. Enable Wireless Debugging on Your Android Device

1.  **Enable Developer Options:**
    *   Open the **Settings** app on your Android device.
    *   Go to **About phone**.
    *   Tap on **Build number** 7 times until you see a message that says "You are now a developer!".

2.  **Enable Wireless Debugging:**
    *   Go back to the main **Settings** screen.
    *   Go to **System** > **Developer options**.
    *   Scroll down to the **Debugging** section and enable **Wireless debugging**.

## 2. Connect Your Device to Your Computer Wirelessly

1.  **Connect to the same Wi-Fi network:**
    *   Make sure that your computer and your Android device are connected to the same Wi-Fi network.

2.  **Find your device's IP address and port:**
    *   On your Android device, go to **Settings** > **System** > **Developer options** > **Wireless debugging**.
    *   You will see your device's IP address and port under **IP address & Port**. It will look something like `192.168.1.100:4567`.

3.  **Connect to your device using adb:**
    *   Open a terminal on your computer.
    *   Run the following command, replacing `<device-ip-address>` and `<port>` with the values you found in the previous step:
        ```bash
        adb connect <device-ip-address>:<port>
        ```
    *   You should see a message that says "connected to <device-ip-address>:<port>".

4.  **Verify the connection:**
    *   Run the following command to see a list of connected devices:
        ```bash
        adb devices
        ```
    *   You should see your device in the list.

## 3. Run the Flutter App on Your Wirelessly Connected Device

1.  **Navigate to the Flutter project directory:**
    *   Open a terminal on your computer.
    *   Navigate to the `frontend/gatepass_app` directory in this project.

2.  **Run the app:**
    *   Run the following command to deploy and run the app on your wirelessly connected device:
        ```bash
        flutter run
        ```
    *   The app will now build and run on your device. You can see the logs in the terminal.

## Project Analysis Summary

This project is a comprehensive Gate Pass Management System with a backend built using the Django REST Framework and a frontend built with Flutter.

### Backend

*   **Framework:** Django REST Framework
*   **Database:** PostgreSQL
*   **Core Modules:**
    *   User Management (Custom User Model with JWT Authentication)
    *   Master Data Management (Vehicles, Drivers)
    *   Gate Pass Lifecycle (Request, Approval, QR Code Generation)
    *   Gate Operations & Logging (QR Code Scanning and Verification)
    *   Reporting

### Frontend

*   **Framework:** Flutter
*   **Target Platforms:** Android & Web
*   **Core Features:**
    *   User Authentication (Login/Logout)
    *   Role-based Dashboards (Admin, Manager, Client Care)
    *   Gate Pass Request and Management
    *   QR Code Scanner for Security Personnel
    *   Reporting
*   **Key Dependencies:**
    *   `http`: For API communication
    *   `shared_preferences`: For local data storage
    *   `mobile_scanner`: For QR code scanning
    *   `jwt_decoder`: For handling JWTs

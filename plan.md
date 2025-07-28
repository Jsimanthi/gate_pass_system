# Project Development Plan for Jules AI: Gate Pass Management System
Project Name: World-Class Gate Pass Management System
Technologies: Django REST Framework (Backend), Flutter (Frontend - Android & Web), PostgreSQL (Database)

**IMPORTANT NOTE FOR JULES AI:**
When working on Flutter frontend modules (Phase 5), all file paths should be considered relative to the Flutter project root, which is `frontend/gatepass_app/`. For example, a file like `main.dart` should be placed at `frontend/gatepass_app/lib/main.dart`, not just `lib/main.dart` in the system root. Please ensure all new files and modifications adhere to this full path structure.

### Current Status:
**All backend modules up to and including Phase 3.2 (Gate Pass Approval Workflow & QR Code Generation) are considered Completed.**

**On the Flutter Frontend (Phase 5):**
* **Module 5.1 (Flutter Project Setup & Core Structure) is In Progress**, with core API client and authentication service structures in place.
* **Module 5.2 (Authentication UI - Login/Logout) is Completed**, with a functional login screen.
* **Module 5.3 (Admin/Manager/Client Care Dashboards & UI - Iterative) is In Progress**, with the Gate Pass Request Screen being significantly developed.

This means:
* **Phase 1: Backend Core Setup (Users, Authentication, Base Models)** is **Completed**.
    * Module 1.1: Custom User Model & Django Admin Integration
    * Module 1.2: JWT Authentication Setup
    * Module 1.3: Basic Lookups/Configuration Models
* **Phase 2: Master Data Management (Vehicles, Drivers)** is **Completed**.
    * Module 2.1: Vehicle Management
    * Module 2.2: Driver Management
* **Phase 3: Gate Pass Lifecycle (Request, Approval, Issuance)** is **Completed**.
    * Module 3.1: Gate Pass Request & Creation
    * Module 3.2: Gate Pass Approval Workflow & QR Code Generation (QR code generation and console email notification now fully functional).
* **Frontend `GatePassRequestScreen` Development (from Phase 5.3) is well underway**, including API client integration, dropdown data fetching, form submission, and significant UI/styling refinements (card width, margins, internal padding, and form background color).
* **Frontend `LoginScreen` (from Phase 5.2) is fully implemented**, handling user input, authentication with `AuthService`, and navigation.

---

### IMMEDIATE ACTION REQUIRED BY JULES AI: File System Correction

**Jules AI, before proceeding with any further development, it is critical to correct the file system structure as some Flutter files were previously generated in an incorrect location. Please perform the following steps:**

1.  **Locate Misplaced Files:** Identify all `.dart` files that were incorrectly created directly under `gate_pass_system/lib/`. Based on our conversation, these likely include:
    * `gate_pass_system/lib/main.dart`
    * `gate_pass_system/lib/qr_scanner_screen.dart` (if it was generated there)
    * Potentially any other files (`api_client.dart`, `auth_service.dart`, `app_config.dart`) if they were also misplaced during the initial setup of Module 5.1.

2.  **Move `main.dart`:**
    * Move `gate_pass_system/lib/main.dart` to `gate_pass_system/frontend/gatepass_app/lib/main.dart`.
    * **If `frontend/gatepass_app/lib/main.dart` already exists, compare content and merge if necessary, prioritizing the more complete version. If there's a conflict, prompt for human review.**

3.  **Move `qr_scanner_screen.dart`:**
    * Move `gate_pass_system/lib/qr_scanner_screen.dart` to `gate_pass_system/frontend/gatepass_app/lib/presentation/security/qr_scanner_screen.dart`.
    * **Ensure the directory `frontend/gatepass_app/lib/presentation/security/` exists. If not, create it first.**

4.  **Check and Move Other Potential Misplaced Files:**
    * Check for `gate_pass_system/lib/api_client.dart`. If found and it contains Flutter client code, move it to `gate_pass_system/frontend/gatepass_app/lib/core/api_client.dart`.
    * Check for `gate_pass_system/lib/auth_service.dart`. If found and it contains Flutter auth service code, move it to `gate_pass_system/frontend/gatepass_app/lib/services/auth_service.dart`.
    * Check for `gate_pass_system/lib/config/app_config.dart` (or similar). If found, move it to `gate_pass_system/frontend/gatepass_app/lib/config/app_config.dart`.
    * **For any other `.dart` files found directly under `gate_pass_system/lib/`, analyze their content and move them to their appropriate location within `frontend/gatepass_app/lib/` based on their functionality (e.g., `presentation/`, `models/`, `utils/`, `services/`, `core/`).**

5.  **Remove the Empty Root `lib` Folder:**
    * Once all Flutter-related files have been successfully moved out of `gate_pass_system/lib/`, delete the now empty `gate_pass_system/lib/` directory.

**After these steps, please confirm that the file structure is correct and that the Flutter project (`frontend/gatepass_app/`) can still build and run without errors.**

---

### Core Philosophy for Jules AI's Development Approach:
* **Modular Development:** Build feature by feature, ensuring each component works independently before integration.
* **API-First:** Backend API endpoints will be defined and implemented first, then consumed by the frontend.
* **Test-Driven (where applicable):** Basic tests will be created for critical backend logic and API endpoints.
* **Clear Communication:** I will explain each step, the code, and how to implement it.
* **Iterative Refinement:** I will be open to feedback and adjustments as we progress.

### Overall Development Phases (High-Level):
* **Phase 1: Backend Core Setup (Users, Authentication, Base Models)** - **Completed**
* **Phase 2: Master Data Management (Vehicles, Drivers)** - **Completed**
* **Phase 3: Gate Pass Lifecycle (Request, Approval, Issuance)** - **Completed**
* **Phase 4: Gate Operations & Logging** - **Next Focus (Backend)**
* **Phase 5: Frontend Development (Flutter)** - **In Progress (Login Completed, Request Screen In Progress)**
* **Phase 6: Reporting & Analytics** - **To Be Started**
* **Phase 7: Refinement, Testing & Deployment Preparation** - **To Be Started**

---

### Detailed Development Plan & Module Breakdown for Jules AI:
I will proceed module by module, providing code and instructions for each.

#### Phase 1: Backend Core Setup
##### Module 1.1: Custom User Model & Django Admin Integration
**Status: Completed**
Goal: Replace Django's default User model with a custom one, allowing for future expansion (e.g., specific roles, additional user fields) and integrate it with the Django Admin.
Backend Changes (`backend/`): Create `apps/users` Django app. Define `CustomUser` model inheriting from `AbstractUser`. Configure `AUTH_USER_MODEL` in `gatepass_core/settings/base.py`. Register `CustomUser` in `apps/users/admin.py`. Update `gatepass_core/urls.py` to include `apps.users.urls` (for auth endpoints).
Frontend Impact: No direct UI changes yet, but the authentication system will rely on this.
Jules AI's Output: Will provide code for `apps/users/models.py`, `apps/users/admin.py`, `gatepass_core/settings/base.py` adjustments, and initial `apps/users/urls.py` (for future authentication views if not using DRF's default views directly). Will explain migrations.

##### Module 1.2: JWT Authentication Setup
**Status: Completed**
Goal: Implement JSON Web Token (JWT) based authentication for secure API access.
Backend Changes (`backend/`): Ensure `rest_framework_simplejwt` is in `INSTALLED_APPS` and `REST_FRAMEWORK` settings are correct. Add JWT URL patterns to `gatepass_core/urls.py`.
Frontend Impact: The login process will involve sending credentials to a JWT endpoint and storing the received tokens.
Jules AI's Output: Will provide code for `gatepass_core/urls.py` additions and confirm `gatepass_core/settings/base.py` JWT configurations.

##### Module 1.3: Basic Lookups/Configuration Models
**Status: Completed**
Goal: Create generic models for commonly used, configurable data like VehicleType, PurposeOfTravel, GateLocation. This allows admins to manage these via Django Admin.
Backend Changes (`backend/`): Create `apps/core_data` (or `apps/lookups`) Django app. Define models like `VehicleType`, `Purpose`, `Gate`. Register them in `admin.py`.
Frontend Impact: These will populate dropdowns and choices in later forms.
Jules AI's Output: Will provide code for `apps/core_data/models.py`, `apps/core_data/admin.py`, and `gatepass_core/settings/base.py` (`INSTALLED_APPS`).

#### Phase 2: Master Data Management
##### Module 2.1: Vehicle Management
**Status: Completed**
Goal: Implement full CRUD (Create, Read, Update, Delete) functionality for vehicle records via API.
Backend Changes (`backend/`): Create `apps/vehicles` Django app. Define `Vehicle` model with necessary fields (`vehicle_number`, `type` (FK to `VehicleType`), `make`, `model`, `capacity`, `status`, `registration_date`, `notes`). Create Serializers, Views, and URL patterns for the Vehicle API. Implement permissions (e.g., only Admin can create/update). Register in Django Admin.
Frontend Impact: Admin dashboard UI for managing vehicles (list, add, edit, delete).
Jules AI's Output: Will provide code for `apps/vehicles/models.py`, `apps/vehicles/serializers.py`, `apps/vehicles/views.py`, `apps/vehicles/urls.py`, `apps/vehicles/admin.py`, and `gatepass_core/settings/base.py` (`INSTALLED_APPS`).

##### Module 2.2: Driver Management
**Status: Completed**
Goal: Implement full CRUD functionality for driver records via API.
Backend Changes (`backend/`): Create `apps/drivers` Django app. Define `Driver` model (`name`, `license_number`, `contact_details`, `address`, `status`). Create Serializers, Views, and URL patterns for the Driver API. Implement permissions. Register in Django Admin.
Frontend Impact: Admin dashboard UI for managing drivers.
Jules AI's Output: Will provide code for `apps/drivers/models.py`, `apps/drivers/serializers.py`, `apps/drivers/views.py`, `apps/drivers/urls.py`, `apps/drivers/admin.py`, and `gatepass_core/settings/base.py` (`INSTALLED_APPS`).

#### Phase 3: Gate Pass Lifecycle
##### Module 3.1: Gate Pass Request & Creation
**Status: Completed**
Goal: Allow authorized users (e.g., Managers) to create gate pass requests.
Backend Changes (`backend/`): Create `apps/gatepass` Django app. Define `GatePass` model (`vehicle` (FK), `driver` (FK), `destination` (FK to `Gate` from lookups), `purpose` (FK to `Purpose`), `requested_exit_time`, `status` (pending, approved, rejected, completed), `requested_by` (FK to `CustomUser`), `approved_by` (FK to `CustomUser`, nullable), `approval_reason`). Serializers, Views, URL patterns for creating requests. Permissions for request creation.
Frontend Impact: UI for managers to fill out and submit gate pass requests.
Jules AI's Output: Will provide code for `apps/gatepass/models.py`, `apps/gatepass/serializers.py`, `apps/gatepass/views.py` (for request creation), `apps/gatepass/urls.py`, `apps/gatepass/admin.py`, and `gatepass_core/settings/base.py` (`INSTALLED_APPS`).

##### Module 3.2: Gate Pass Approval Workflow & QR Code Generation
**Status: Completed**
Goal: Implement the approval process and generate unique, scannable QR codes for approved passes.
Backend Changes (`backend/`): Extended `apps/gatepass/views.py` with approval/rejection logic. Implemented logic to generate unique QR code data (e.g., `pass_id`, `vehicle_number`, `expiration`) upon approval. Implemented a separate field/method on `GatePass` model for QR code data/image path. Permissions for approval (e.g., Client Care role).
Frontend Impact: Client Care dashboard to view pending requests, approve/reject forms. Driver's app to display the QR code.
Jules AI's Output: Will provide updates to `apps/gatepass/views.py` and `apps/gatepass/serializers.py`, and suggest a library for QR code generation.

#### Phase 4: Gate Operations & Logging
##### Module 4.1: Gate Scanning & Verification API
**Status: To Be Started (Backend)**
Goal: Provide an API endpoint for security personnel to scan QR codes and verify gate passes in real-time.
Backend Changes (`backend/`): Create `apps/gate_operations` Django app. Define a view that accepts QR code data. Implement verification logic: check pass validity, status, vehicle match. Return immediate feedback (VALID/INVALID, reason). Permissions for security personnel.
Frontend Impact: Security personnel app with a QR scanner interface.
Jules AI's Output: Will provide code for `apps/gate_operations/views.py`, `apps/gate_operations/urls.py`, and `gatepass_core/settings/base.py` (`INSTALLED_APPS`).

##### Module 4.2: Gate Logging
**Status: To Be Started (Backend)**
Goal: Record every gate activity (scan attempt, entry, exit, manual override) with details.
Backend Changes (`backend/`): Extend `apps/gate_operations` with a `GateLog` model (`timestamp`, `gate_pass` (FK), `action` (entry/exit/scan_attempt), `status` (success/failure), `reason` (for failure), `security_personnel` (FK to `CustomUser`)). Integrate logging into the scanning view. Register in Django Admin.
Frontend Impact: No direct UI, but this data will feed into reports.
Jules AI's Output: Will provide updates to `apps/gate_operations/models.py`, `apps/gate_operations/views.py`, and `apps/gate_operations/admin.py`.

#### Phase 5: Frontend Development (Flutter)
This phase will be intertwined with the backend development, but here's the overall structure. I will likely provide Flutter code snippets and instructions after each major backend module is complete.

##### Module 5.1: Flutter Project Setup & Core Structure
**Status: In Progress (Basic API Client and Auth Service integrated; Core project setup ongoing)**
Goal: Initialize the Flutter app, set up basic routing, theme, and API client.
Frontend Changes (`frontend/gatepass_app/`): Define `lib/main.dart`, `lib/config/app_config.dart` (for API URLs). Set up `lib/core/api_client.dart` (using `http` or `Dio` package). Basic routing using `go_router` or similar. State management setup (e.g., `provider` or `flutter_bloc`).

##### Module 5.2: Authentication UI (Login/Logout)
**Status: Completed**
Goal: Enable users to log in and receive JWT tokens.
Frontend Changes (`frontend/gatepass_app/`): `presentation/auth/login_screen.dart`. `core/auth_service.dart` (for handling token storage - `shared_preferences` or `flutter_secure_storage`).

##### Module 5.3: Admin/Manager/Client Care Dashboards & UI (Iterative)
**Status: In Progress (Gate Pass Request Screen significantly developed)**
Goal: Build role-specific dashboards to interact with the backend APIs for master data, gate pass requests, approvals, etc. This will be an ongoing effort as backend modules are completed.
Frontend Changes (`frontend/gatepass_app/presentation/`): `home/dashboard_screen.dart` (conditional UI based on user role). `gate_pass/` (screens for requesting, viewing, approving passes). `common_widgets/` (reusable form fields, buttons).
* **Current Progress for this module:** The `GatePassRequestScreen` in `frontend/gatepass_app/lib/presentation/gate_pass_request/gate_pass_request_screen.dart` is implemented and styled with dynamic card width, adjusted margins, internal padding, and form background color. It successfully fetches dropdown data and submits requests to the backend.

##### Module 5.4: Security Personnel App UI (QR Scanner)
**Status: To Be Started**
Goal: Build the dedicated UI for security personnel to scan QR codes and see verification results.
Frontend Changes (`frontend/gatepass_app/presentation/security/`): `qr_scanner_screen.dart` (using `mobile_scanner` or `barcode_scan2`). Display real-time verification feedback.

#### Phase 6: Reporting & Analytics
##### Module 6.1: Backend Reporting Endpoints
**Status: To Be Started**
Goal: Provide API endpoints to query and filter gate log data for reporting.
Backend Changes (`backend/apps/reports/`): Create `apps/reports` Django app. Views for filtered lists of `GateLog` entries, summary statistics (e.g., vehicles per day, top destinations).
Frontend Impact: UI to select date ranges, filters, and display reports.

#### Phase 7: Refinement, Testing & Deployment Preparation
This will be an ongoing and final phase.

Backend: Add comprehensive unit and integration tests. Implement Dockerization.

Frontend: Add widget and integration tests. Optimize performance.

Security: Review all security aspects (input validation, rate limiting, secure headers).

Documentation: Ensure all API endpoints are well-documented (e.g., using Swagger/OpenAPI).
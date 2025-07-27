// File: lib/presentation/gate_pass_request/gate_pass_request_screen.dart

import 'package:flutter/material.dart';
import 'package:gatepass_app/core/api_client.dart';
import 'package:gatepass_app/services/auth_service.dart'; // Import AuthService
import 'package:intl/intl.dart';

class GatePassRequestScreen extends StatefulWidget {
  // Add ApiClient and AuthService as parameters to the constructor
  final ApiClient apiClient;
  final AuthService authService;

  const GatePassRequestScreen({
    super.key,
    required this.apiClient,
    required this.authService,
  });

  @override
  State<GatePassRequestScreen> createState() => _GatePassRequestScreenState();
}

class _GatePassRequestScreenState extends State<GatePassRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _personNameController = TextEditingController();
  final TextEditingController _personPhoneController = TextEditingController();
  final TextEditingController _entryTimeController = TextEditingController();
  final TextEditingController _exitTimeController = TextEditingController();

  String? _selectedPurposeId;
  String? _selectedGateId;
  String? _selectedVehicleId;
  String? _selectedDriverId;

  List<Map<String, dynamic>> _purposes = [];
  List<Map<String, dynamic>> _gates = [];
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _drivers = [];

  bool _isLoading = true;
  String? _errorMessage;

  // Use the passed apiClient instance
  late final ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    // Assign the passed apiClient to the local _apiClient
    _apiClient = widget.apiClient;
    _fetchDropdownData();
  }

  // Helper to extract results from paginated API response
  List<Map<String, dynamic>> _extractResults(dynamic response) {
    if (response is Map<String, dynamic> &&
        response.containsKey('results') &&
        response['results'] is List) {
      return List<Map<String, dynamic>>.from(response['results']);
    } else if (response is List) {
      // If the API directly returns a list (no pagination)
      return List<Map<String, dynamic>>.from(response);
    }
    // Fallback or error case if response is not expected format
    print(
      'Warning: API response not in expected paginated or list format: $response',
    );
    return [];
  }

  // --- Data Fetching Functions ---
  Future<void> _fetchDropdownData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // These calls will now automatically include the token
      final purposeResponse = await _apiClient.get('/api/core-data/purposes/');
      _purposes = _extractResults(purposeResponse);

      final gateResponse = await _apiClient.get('/api/core-data/gates/');
      _gates = _extractResults(gateResponse);

      final vehicleResponse = await _apiClient.get('/api/vehicles/');
      _vehicles = _extractResults(vehicleResponse);
      _vehicles.insert(0, {'id': '', 'vehicle_number': 'N/A (No Vehicle)'});

      final driverResponse = await _apiClient.get('/api/drivers/');
      _drivers = _extractResults(driverResponse);
      _drivers.insert(0, {'id': '', 'name': 'N/A (No Specific Driver)'});
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: $e';
        print('API Fetch Error: $_errorMessage');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- Date & Time Picker ---
  Future<void> _selectDateTime(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2028),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final DateTime finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        final String formattedDateTime = DateFormat(
          "yyyy-MM-dd'T'HH:mm:ss'Z'",
        ).format(finalDateTime.toUtc());
        controller.text = formattedDateTime;
      }
    }
  }

  // --- Form Submission ---
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_selectedPurposeId == null || _selectedGateId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final Map<String, dynamic> data = {
          'person_name': _personNameController.text,
          'person_phone': _personPhoneController.text,
          'entry_time': _entryTimeController.text,
          'exit_time': _exitTimeController.text,
          'purpose': int.parse(_selectedPurposeId!),
          'gate': int.parse(_selectedGateId!),
          'vehicle':
              _selectedVehicleId != null && _selectedVehicleId!.isNotEmpty
                  ? int.parse(_selectedVehicleId!)
                  : null,
          'driver': _selectedDriverId != null && _selectedDriverId!.isNotEmpty
              ? int.parse(_selectedDriverId!)
              : null,
        };

        // This POST request will also now include the token
        await _apiClient.post('/api/gatepass/', data);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gate Pass Request Submitted Successfully!'),
          ),
        );
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting request: $e')));
        print('API Submission Error: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _personNameController.dispose();
    _personPhoneController.dispose();
    _entryTimeController.dispose();
    _exitTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Gate Pass'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error: $_errorMessage',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red, fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _fetchDropdownData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: <Widget>[
                        TextFormField(
                          controller: _personNameController,
                          decoration: const InputDecoration(
                            labelText: 'Applicant Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter applicant name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _personPhoneController,
                          decoration: const InputDecoration(
                            labelText: 'Applicant Phone',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _entryTimeController,
                          decoration: const InputDecoration(
                            labelText: 'Entry Date & Time',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
                          onTap: () =>
                              _selectDateTime(context, _entryTimeController),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select entry date and time';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _exitTimeController,
                          decoration: const InputDecoration(
                            labelText: 'Exit Date & Time',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
                          onTap: () =>
                              _selectDateTime(context, _exitTimeController),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select exit date and time';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Purpose',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                          value: _selectedPurposeId,
                          hint: const Text('Select Purpose'),
                          items: _purposes.map((purpose) {
                            return DropdownMenuItem<String>(
                              value: purpose['id'].toString(),
                              child: Text(purpose['name']),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedPurposeId = newValue;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a purpose';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Gate',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          value: _selectedGateId,
                          hint: const Text('Select Gate'),
                          items: _gates.map((gate) {
                            return DropdownMenuItem<String>(
                              value: gate['id'].toString(),
                              child: Text(gate['name']),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedGateId = newValue;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a gate';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Vehicle (Optional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.directions_car),
                          ),
                          value: _selectedVehicleId,
                          hint: const Text('Select Vehicle'),
                          items: _vehicles.map((vehicle) {
                            String displayText =
                                vehicle['vehicle_number'] ?? 'N/A';
                            if (vehicle['vehicle_type'] is Map &&
                                vehicle['vehicle_type']['name'] != null) {
                              displayText =
                                  '${vehicle['vehicle_type']['name']} - ${vehicle['vehicle_number'] ?? ''}';
                            }
                            return DropdownMenuItem<String>(
                              value: vehicle['id'].toString(),
                              child: Text(displayText),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedVehicleId = newValue;
                            });
                          },
                        ),
                        const SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Driver (Optional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.drive_eta),
                          ),
                          value: _selectedDriverId,
                          hint: const Text('Select Driver'),
                          items: _drivers.map((driver) {
                            return DropdownMenuItem<String>(
                              value: driver['id'].toString(),
                              child: Text(driver['name']),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedDriverId = newValue;
                            });
                          },
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Submit Gate Pass Request',
                                  style: TextStyle(fontSize: 18),
                                ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }
}
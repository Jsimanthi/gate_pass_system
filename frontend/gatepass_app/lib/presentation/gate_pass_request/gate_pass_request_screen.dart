import 'package:flutter/material.dart';
import 'package:gatepass_app/core/api_client.dart';
import 'package:gatepass_app/services/auth_service.dart';
import 'package:intl/intl.dart';
// Import math for min function (though might not be explicitly used in final render, good to keep for consistency)

class GatePassRequestScreen extends StatefulWidget {
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
  final TextEditingController _personNidController = TextEditingController();
  final TextEditingController _personAddressController =
      TextEditingController();
  // We no longer need these controllers to store the date strings.
  // final TextEditingController _entryTimeController = TextEditingController();
  // final TextEditingController _exitTimeController = TextEditingController();

  // New state variables to hold the DateTime objects directly.
  DateTime? _entryDateTime;
  DateTime? _exitDateTime;

  String? _selectedPurposeId;
  String? _selectedGateId;
  String? _selectedVehicleId;
  String? _selectedDriverId;
  bool _alcoholTestRequired = false;

  List<Map<String, dynamic>> _purposes = [];
  List<Map<String, dynamic>> _gates = [];
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _drivers = [];

  bool _isLoading = true;
  String? _errorMessage;
  bool _isSubmitting = false;

  late final ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient;
    _fetchDropdownData();
  }

  List<Map<String, dynamic>> _extractResults(dynamic response) {
    if (response is Map<String, dynamic> &&
        response.containsKey('results') &&
        response['results'] is List) {
      return List<Map<String, dynamic>>.from(response['results']);
    } else if (response is List) {
      return List<Map<String, dynamic>>.from(response);
    }
    return [];
  }

  Future<void> _fetchDropdownData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
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
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateTime(BuildContext context, bool isEntryTime) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isEntryTime
          ? _entryDateTime ?? DateTime.now()
          : _exitDateTime ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2028),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          isEntryTime
              ? _entryDateTime ?? DateTime.now()
              : _exitDateTime ?? DateTime.now(),
        ),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: Theme.of(context).colorScheme,
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final DateTime finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          if (isEntryTime) {
            _entryDateTime = finalDateTime;
          } else {
            _exitDateTime = finalDateTime;
          }
        });
      }
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_selectedPurposeId == null || _selectedGateId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select Purpose and Gate.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_entryDateTime == null || _exitDateTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select both entry and exit times.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        final Map<String, dynamic> data = {
          'person_name': _personNameController.text,
          'person_phone': _personPhoneController.text,
          'person_nid': _personNidController.text.isNotEmpty
              ? _personNidController.text
              : null,
          'person_address': _personAddressController.text.isNotEmpty
              ? _personAddressController.text
              : null,
          // We now use the stored DateTime objects and convert them to UTC ISO 8601 strings for the API.
          'entry_time': _entryDateTime!.toUtc().toIso8601String(),
          'exit_time': _exitDateTime!.toUtc().toIso8601String(),
          'purpose_id': _selectedPurposeId,
          'gate_id': _selectedGateId,
          'vehicle_id': _selectedVehicleId,
          'driver_id': _selectedDriverId,
          'alcohol_test_required': _alcoholTestRequired,
        };

        await _apiClient.post('/api/gatepass/gatepasses/', data);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gate Pass Request Submitted Successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _formKey.currentState?.reset();
          _personNameController.clear();
          _personPhoneController.clear();
          _personNidController.clear();
          _personAddressController.clear();
          setState(() {
            // Reset the DateTime variables as well.
            _entryDateTime = null;
            _exitDateTime = null;
            _selectedPurposeId = null;
            _selectedGateId = null;
            _selectedVehicleId = null;
            _selectedDriverId = null;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error submitting request: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _personNameController.dispose();
    _personPhoneController.dispose();
    _personNidController.dispose();
    _personAddressController.dispose();
    super.dispose();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth > 600;

    const double formFieldWidth = 450;

    return Scaffold(
      appBar: AppBar(title: const Text('Request Gate Pass')),
      body: SingleChildScrollView(
        child: _isLoading
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
            : Center(
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 20.0,
                  ),
                  elevation: 8.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48.0,
                      vertical: 24.0,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          _buildSectionTitle('Applicant Details'),
                          SizedBox(
                            width: isLargeScreen
                                ? formFieldWidth
                                : double.infinity,
                            child: TextFormField(
                              controller: _personNameController,
                              decoration: const InputDecoration(
                                labelText: 'Applicant Name',
                                hintText: 'Enter full name',
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
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: isLargeScreen
                                ? formFieldWidth
                                : double.infinity,
                            child: TextFormField(
                              controller: _personPhoneController,
                              decoration: const InputDecoration(
                                labelText: 'Applicant Phone',
                                hintText: 'e.g., +1234567890',
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
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: isLargeScreen
                                ? formFieldWidth
                                : double.infinity,
                            child: TextFormField(
                              controller: _personNidController,
                              decoration: const InputDecoration(
                                labelText: 'Applicant NID (Optional)',
                                hintText: 'Enter National ID number',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.credit_card),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: isLargeScreen
                                ? formFieldWidth
                                : double.infinity,
                            child: TextFormField(
                              controller: _personAddressController,
                              decoration: const InputDecoration(
                                labelText: 'Applicant Address (Optional)',
                                hintText: 'Enter full address',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.home),
                              ),
                              maxLines: 3,
                              minLines: 1,
                            ),
                          ),
                          const SizedBox(height: 30),

                          _buildSectionTitle('Pass Details'),
                          SizedBox(
                            width: isLargeScreen
                                ? formFieldWidth
                                : double.infinity,
                            child: TextFormField(
                              // This controller now only holds the formatted display string.
                              controller: TextEditingController(
                                text: _entryDateTime != null
                                    ? DateFormat(
                                        "dd-MM-yyyy, hh:mm:ss a",
                                      ).format(_entryDateTime!)
                                    : '',
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Entry Date & Time',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              readOnly: true,
                              onTap: () => _selectDateTime(context, true),
                              validator: (value) {
                                if (_entryDateTime == null) {
                                  return 'Please select entry date and time';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: isLargeScreen
                                ? formFieldWidth
                                : double.infinity,
                            child: TextFormField(
                              // This controller now only holds the formatted display string.
                              controller: TextEditingController(
                                text: _exitDateTime != null
                                    ? DateFormat(
                                        "dd-MM-yyyy, hh:mm:ss a",
                                      ).format(_exitDateTime!)
                                    : '',
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Exit Date & Time',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              readOnly: true,
                              onTap: () => _selectDateTime(context, false),
                              validator: (value) {
                                if (_exitDateTime == null) {
                                  return 'Please select exit date and time';
                                }
                                if (_entryDateTime != null &&
                                    _exitDateTime!.isBefore(_entryDateTime!)) {
                                  return 'Exit time must be after entry time';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: isLargeScreen
                                ? formFieldWidth
                                : double.infinity,
                            child: DropdownButtonFormField<String>(
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
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: isLargeScreen
                                ? formFieldWidth
                                : double.infinity,
                            child: DropdownButtonFormField<String>(
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
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: isLargeScreen
                                ? formFieldWidth
                                : double.infinity,
                            child: CheckboxListTile(
                              title: const Text('Alcohol Test Required'),
                              value: _alcoholTestRequired,
                              onChanged: (bool? value) {
                                setState(() {
                                  _alcoholTestRequired = value!;
                                });
                              },
                            ),
                          ),

                          const SizedBox(height: 30),

                          _buildSectionTitle('Vehicle & Driver (Optional)'),
                          SizedBox(
                            width: isLargeScreen
                                ? formFieldWidth
                                : double.infinity,
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Vehicle',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.directions_car),
                              ),
                              value: _selectedVehicleId,
                              hint: const Text('Select Vehicle (Optional)'),
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
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: isLargeScreen
                                ? formFieldWidth
                                : double.infinity,
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Driver',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.drive_eta),
                              ),
                              value: _selectedDriverId,
                              hint: const Text('Select Driver (Optional)'),
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
                          ),
                          const SizedBox(height: 30),

                          SizedBox(
                            width: isLargeScreen
                                ? formFieldWidth
                                : double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              child: _isSubmitting
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text('Submit Gate Pass Request'),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

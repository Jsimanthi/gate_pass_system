import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:gatepass_app/core/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// Simple model for Employee data
class Employee {
  final int id;
  final String fullName;

  Employee({required this.id, required this.fullName});

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      fullName: '${json['first_name']} ${json['last_name']}'.trim(),
    );
  }
}

class VisitorFormScreen extends StatefulWidget {
  final ApiClient apiClient;

  const VisitorFormScreen({super.key, required this.apiClient});

  @override
  State<VisitorFormScreen> createState() => _VisitorFormScreenState();
}

class _VisitorFormScreenState extends State<VisitorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _purposeController = TextEditingController();

  List<Employee> _employees = [];
  int? _selectedEmployeeId;
  bool _isFetchingEmployees = true;
  XFile? _selfieFile;
  Uint8List? _selfieBytes;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    try {
      final response = await widget.apiClient.get('/api/users/employees/');
      final List<dynamic> employeeData = response;
      setState(() {
        _employees = employeeData.map((data) => Employee.fromJson(data)).toList();
        _isFetchingEmployees = false;
      });
    } catch (e) {
      setState(() {
        _isFetchingEmployees = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch employees: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 600,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selfieFile = pickedFile;
          _selfieBytes = bytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _selfieFile != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Since ApiClient doesn't support multipart, we build the request here.
        // In a real app, this logic would be moved into ApiClient.
        final uri = Uri.parse('${widget.apiClient.baseUrl}/api/gatepass/visitor-passes/');
        var request = http.MultipartRequest('POST', uri);

        request.fields['visitor_name'] = _nameController.text;
        request.fields['visitor_company'] = _companyController.text;
        request.fields['purpose'] = _purposeController.text;
        request.fields['whom_to_visit_id'] = _selectedEmployeeId.toString();

        request.files.add(await http.MultipartFile.fromPath(
          'visitor_selfie',
          _selfieFile!.path,
          filename: _selfieFile!.name,
        ));

        var response = await request.send();

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request submitted successfully!')),
          );
          // TODO: Navigate to a status page where the visitor can see the approval status.
          // For now, just clear the form.
          _formKey.currentState!.reset();
          setState(() {
            _nameController.clear();
            _companyController.clear();
            _purposeController.clear();
            _selectedEmployeeId = null;
            _selfieFile = null;
            _selfieBytes = null;
          });
        } else {
          final responseBody = await response.stream.bytesToString();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit request: ${response.statusCode} - $responseBody')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else if (_selfieFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please take a selfie to proceed.')),
        );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor Pass Request'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Visitor Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(labelText: 'Visitor Company'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your company name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _purposeController,
                decoration: const InputDecoration(labelText: 'Purpose of Visit'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the purpose of your visit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _isFetchingEmployees
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                      value: _selectedEmployeeId,
                      hint: const Text('Whom to Visit'),
                      items: _employees.map((employee) {
                        return DropdownMenuItem<int>(
                          value: employee.id,
                          child: Text(employee.fullName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedEmployeeId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select an employee to visit';
                        }
                        return null;
                      },
                    ),
              const SizedBox(height: 24),
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: _selfieBytes != null ? MemoryImage(_selfieBytes!) : null,
                    child: _selfieBytes == null ? const Icon(Icons.person, size: 40) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Selfie'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 50), // adjust height
                      ),
                    ),
                  ),
                ],
              ),
              if (_selfieFile == null)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'A selfie is required.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

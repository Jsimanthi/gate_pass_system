import 'package:flutter/material.dart';
import 'package:gatepass_app/core/api_client.dart';
import 'package:gatepass_app/presentation/employee/visitor_request_details_screen.dart';

class VisitorUser {
  final String fullName;
  VisitorUser({required this.fullName});
  factory VisitorUser.fromJson(Map<String, dynamic> json) {
    return VisitorUser(
      fullName: '${json['first_name']} ${json['last_name']}'.trim(),
    );
  }
}

class VisitorPass {
  final int id;
  final String visitorName;
  final String visitorCompany;
  final String purpose;
  final String status;
  final String createdAt;
  final VisitorUser whomToVisit;
  final String visitorSelfieUrl;

  VisitorPass({
    required this.id,
    required this.visitorName,
    required this.visitorCompany,
    required this.purpose,
    required this.status,
    required this.createdAt,
    required this.whomToVisit,
    required this.visitorSelfieUrl,
  });

  factory VisitorPass.fromJson(Map<String, dynamic> json) {
    return VisitorPass(
      id: json['id'],
      visitorName: json['visitor_name'],
      visitorCompany: json['visitor_company'],
      purpose: json['purpose'],
      status: json['status'],
      createdAt: json['created_at'],
      whomToVisit: VisitorUser.fromJson(json['whom_to_visit']),
      visitorSelfieUrl: json['visitor_selfie'],
    );
  }
}

class VisitorRequestsScreen extends StatefulWidget {
  final ApiClient apiClient;
  const VisitorRequestsScreen({super.key, required this.apiClient});

  @override
  State<VisitorRequestsScreen> createState() => _VisitorRequestsScreenState();
}

class _VisitorRequestsScreenState extends State<VisitorRequestsScreen> {
  late Future<List<VisitorPass>> _visitorRequestsFuture;

  @override
  void initState() {
    super.initState();
    _visitorRequestsFuture = _fetchVisitorRequests();
  }

  Future<List<VisitorPass>> _fetchVisitorRequests() async {
    final response = await widget.apiClient.get('/api/gatepass/visitor-passes/');
    final List<dynamic> data = response;
    return data.map((json) => VisitorPass.fromJson(json)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor Requests'),
      ),
      body: FutureBuilder<List<VisitorPass>>(
        future: _visitorRequestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('You have no visitor requests.'));
          }

          final visitorRequests = snapshot.data!;
          return ListView.builder(
            itemCount: visitorRequests.length,
            itemBuilder: (context, index) {
              final request = visitorRequests[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(request.visitorName),
                  subtitle: Text('${request.visitorCompany}\nStatus: ${request.status}'),
                  trailing: const Icon(Icons.chevron_right),
                  isThreeLine: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VisitorRequestDetailsScreen(
                          apiClient: widget.apiClient,
                          visitorPass: request,
                        ),
                      ),
                    ).then((_) {
                      // Refresh the list when returning from the details screen
                      setState(() {
                        _visitorRequestsFuture = _fetchVisitorRequests();
                      });
                    });
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

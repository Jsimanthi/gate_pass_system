import 'package:flutter/material.dart';
import 'package:gatepass_app/core/api_client.dart';
import 'package:gatepass_app/presentation/employee/visitor_requests_screen.dart'; // Reusing the VisitorPass model

class ApprovedVisitorsScreen extends StatefulWidget {
  final ApiClient apiClient;

  const ApprovedVisitorsScreen({super.key, required this.apiClient});

  @override
  State<ApprovedVisitorsScreen> createState() => _ApprovedVisitorsScreenState();
}

class _ApprovedVisitorsScreenState extends State<ApprovedVisitorsScreen> {
  late Future<List<VisitorPass>> _approvedVisitorsFuture;

  @override
  void initState() {
    super.initState();
    _approvedVisitorsFuture = _fetchApprovedVisitors();
  }

  Future<List<VisitorPass>> _fetchApprovedVisitors() async {
    // The backend already filters to show only approved passes for security users
    final response = await widget.apiClient.get('/api/gatepass/visitor-passes/');
    final List<dynamic> data = response;
    return data.map((json) => VisitorPass.fromJson(json)).toList();
  }

  Future<void> _refreshList() async {
    setState(() {
      _approvedVisitorsFuture = _fetchApprovedVisitors();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approved Visitors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshList,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshList,
        child: FutureBuilder<List<VisitorPass>>(
          future: _approvedVisitorsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('There are no approved visitors at the moment.'));
            }

            final approvedVisitors = snapshot.data!;
            return ListView.builder(
              itemCount: approvedVisitors.length,
              itemBuilder: (context, index) {
                final request = approvedVisitors[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(request.visitorSelfieUrl),
                    ),
                    title: Text(request.visitorName),
                    subtitle: Text('Visiting: ${request.whomToVisit.fullName}\nCompany: ${request.visitorCompany}'),
                    isThreeLine: true,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

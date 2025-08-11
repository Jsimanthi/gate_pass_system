import 'package:flutter/material.dart';
import 'package:gatepass_app/core/api_client.dart';
import 'package:gatepass_app/presentation/employee/visitor_requests_screen.dart'; // For VisitorPass model

class VisitorRequestDetailsScreen extends StatefulWidget {
  final ApiClient apiClient;
  final VisitorPass visitorPass;

  const VisitorRequestDetailsScreen({
    super.key,
    required this.apiClient,
    required this.visitorPass,
  });

  @override
  State<VisitorRequestDetailsScreen> createState() => _VisitorRequestDetailsScreenState();
}

class _VisitorRequestDetailsScreenState extends State<VisitorRequestDetailsScreen> {
  bool _isLoading = false;

  Future<void> _approveRequest() async {
    _updateStatus('approve');
  }

  Future<void> _rejectRequest() async {
    _updateStatus('reject');
  }

  Future<void> _updateStatus(String action) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await widget.apiClient.post('/api/gatepass/visitor-passes/${widget.visitorPass.id}/$action/', {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request ${action}d successfully!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to $action request: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor Request Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(widget.visitorPass.visitorSelfieUrl),
                onBackgroundImageError: (exception, stackTrace) {
                  // Handle image loading error
                },
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Visitor Name:', widget.visitorPass.visitorName),
            _buildDetailRow('Visitor Company:', widget.visitorPass.visitorCompany),
            _buildDetailRow('Purpose of Visit:', widget.visitorPass.purpose),
            _buildDetailRow('Status:', widget.visitorPass.status),
            _buildDetailRow('Request Time:', widget.visitorPass.createdAt),
            const SizedBox(height: 32),
            if (widget.visitorPass.status == 'PENDING')
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _rejectRequest,
                            icon: const Icon(Icons.close),
                            label: const Text('Reject'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _approveRequest,
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          ),
                        ),
                      ],
                    ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          const Divider(),
        ],
      ),
    );
  }
}

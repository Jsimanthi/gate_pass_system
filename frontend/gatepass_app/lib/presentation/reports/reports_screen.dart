import 'package:flutter/material.dart';
import 'package:gatepass_app/core/api_client.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportsScreen extends StatefulWidget {
  final ApiClient apiClient;

  const ReportsScreen({super.key, required this.apiClient});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // State for filters
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedStatus;
  int? _selectedPurposeId;
  int? _selectedGateId;

  // Futures for the report data
  Future<Map<String, dynamic>>? _summaryFuture;
  Future<List<dynamic>>? _logsFuture;
  Future<Map<String, dynamic>>? _chartDataFuture;

  // Data for dropdowns
  final List<String> _statusOptions = ['PENDING', 'APPROVED', 'REJECTED', 'CANCELLED'];
  List<Map<String, dynamic>> _purposes = [];
  List<Map<String, dynamic>> _gates = [];
  bool _isLoadingDropdowns = true;
  String? _dropdownError;

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
    _fetchReportData();
  }

  // Helper function to build a query string from parameters
  String _buildQueryString(Map<String, String> params) {
    if (params.isEmpty) return '';
    return '?${params.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&')}';
  }

  // Fetches data for the purpose and gate dropdowns
  Future<void> _fetchDropdownData() async {
    setState(() {
      _isLoadingDropdowns = true;
      _dropdownError = null;
    });
    try {
      final purposesData = await widget.apiClient.get('/api/core-data/purposes/');
      final gatesData = await widget.apiClient.get('/api/core-data/gates/');
      setState(() {
        if (purposesData is List) _purposes = List<Map<String, dynamic>>.from(purposesData);
        if (gatesData is List) _gates = List<Map<String, dynamic>>.from(gatesData);
        if (_purposes.isEmpty || _gates.isEmpty) {
          _dropdownError = 'No data available for dropdowns. Please ensure migrations are run and you are logged in.';
        }
      });
    } catch (e) {
      debugPrint("Error fetching dropdown data: $e");
      String errorMessage = "Failed to load filter options.";
      if (e is ApiError) {
        if (e.statusCode == 401 || e.statusCode == 403) {
          errorMessage = "Authentication error. Please log in again.";
        } else if (e.statusCode == 404) {
          errorMessage = "API endpoint not found. Please check the server configuration.";
        } else {
          errorMessage = "A server error occurred: ${e.statusCode}";
        }
      } else {
        errorMessage = "A network error occurred. Check your connection and API_BASE_URL.";
      }
      setState(() {
        _dropdownError = errorMessage;
      });
    } finally {
      setState(() {
        _isLoadingDropdowns = false;
      });
    }
  }

  // Fetches all report data based on current filters
  Future<void> _fetchReportData() async {
    final Map<String, String> queryParams = {};
    if (_startDate != null) queryParams['start_date'] = DateFormat('yyyy-MM-dd').format(_startDate!);
    if (_endDate != null) queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(_endDate!);
    if (_selectedStatus != null) queryParams['status'] = _selectedStatus!;
    if (_selectedPurposeId != null) queryParams['purpose'] = _selectedPurposeId.toString();
    if (_selectedGateId != null) queryParams['gate'] = _selectedGateId.toString();

    final queryString = _buildQueryString(queryParams);

    setState(() {
      _summaryFuture = widget.apiClient.get('/api/reports/daily-summary/$queryString').then((data) => data is Map<String, dynamic> ? data : {});
      _logsFuture = widget.apiClient.get('/api/reports/security-incidents/$queryString').then((data) => data is List ? data : []);
      _chartDataFuture = widget.apiClient.get('/api/reports/data-visualization/$queryString').then((data) => data is Map<String, dynamic> ? data : {});
    });
  }

  // Displays a date picker for selecting a start or end date
  Future<void> _selectDate(BuildContext context, {required bool isStartDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // Exports the report in the specified format (csv or pdf)
  void _exportReport(String format) async {
    final Map<String, String> queryParams = {};
    if (_startDate != null) queryParams['start_date'] = DateFormat('yyyy-MM-dd').format(_startDate!);
    if (_endDate != null) queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(_endDate!);
    if (_selectedStatus != null) queryParams['status'] = _selectedStatus!;
    if (_selectedPurposeId != null) queryParams['purpose'] = _selectedPurposeId.toString();
    if (_selectedGateId != null) queryParams['gate'] = _selectedGateId.toString();
    queryParams['format'] = format;

    final queryString = _buildQueryString(queryParams);
    // Reverting to using dotenv, but keeping the null-coalescing for safety.
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8000';
    final url = Uri.parse('$baseUrl/api/reports/daily-summary/export/$queryString');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open export URL.')));
      }
    } catch (e) {
      debugPrint("Error launching URL: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('An error occurred during export.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFilters(),
            const SizedBox(height: 20),
            _buildReportContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    bool canApplyFilters = _startDate != null && _endDate != null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filters', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16.0,
              runSpacing: 16.0,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _selectDate(context, isStartDate: true),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_startDate == null ? 'Start Date' : DateFormat('yyyy-MM-dd').format(_startDate!)),
                ),
                ElevatedButton.icon(
                  onPressed: () => _selectDate(context, isStartDate: false),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_endDate == null ? 'End Date' : DateFormat('yyyy-MM-dd').format(_endDate!)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // This section is refactored to always show dropdowns,
            // but they will be disabled if loading or if there's an error.
            Wrap(
              spacing: 16.0,
              runSpacing: 16.0,
              children: [
                // Status Dropdown - always enabled as it's a local list
                _buildDropdown<String>(
                  value: _selectedStatus,
                  hint: 'Select Status',
                  items: _statusOptions.map((e) => {'id': e, 'name': e}).toList(),
                  onChanged: (val) => setState(() => _selectedStatus = val),
                  // It's never loading, so enabled
                  isEnabled: true,
                ),
                // Purpose Dropdown
                _buildDropdown<int>(
                  value: _selectedPurposeId,
                  hint: 'Select Purpose',
                  items: _purposes,
                  onChanged: (val) => setState(() => _selectedPurposeId = val),
                  // Disable if loading or if there's an error
                  isEnabled: !_isLoadingDropdowns && _dropdownError == null,
                ),
                // Gate Dropdown
                _buildDropdown<int>(
                  value: _selectedGateId,
                  hint: 'Select Gate',
                  items: _gates,
                  onChanged: (val) => setState(() => _selectedGateId = val),
                  // Disable if loading or if there's an error
                  isEnabled: !_isLoadingDropdowns && _dropdownError == null,
                ),
              ],
            ),
            // Display loading indicator or error message below the dropdowns
            if (_isLoadingDropdowns)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_dropdownError != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Center(
                  child: Text(
                    _dropdownError!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: canApplyFilters ? _fetchReportData : null,
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Apply Filters'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PopupMenuButton<String>(
                    onSelected: canApplyFilters ? _exportReport : null,
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(value: 'csv', child: Text('Export as CSV')),
                      const PopupMenuItem<String>(value: 'pdf', child: Text('Export as PDF')),
                    ],
                    child: ElevatedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.download),
                      label: const Text("Export"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // The `isEnabled` parameter is added to control the active state of the dropdown.
  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<Map<String, dynamic>> items,
    required ValueChanged<T?> onChanged,
    required bool isEnabled,
  }) {
    // If the dropdown is disabled, the `onChanged` callback is set to null.
    final ValueChanged<T?>? effectiveOnChanged = isEnabled ? onChanged : null;

    return SizedBox(
      width: 200, // Constrain the width of the dropdown
      child: DropdownButtonFormField<T>(
        value: value,
        hint: Text(hint),
        onChanged: effectiveOnChanged,
        items: items.map<DropdownMenuItem<T>>((item) {
          return DropdownMenuItem<T>(
            value: item['id'] as T,
            child: Text(item['name'].toString()),
          );
        }).toList(),
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildReportContent() {
    return Column(
      children: [
        FutureBuilder<Map<String, dynamic>>(
          future: _summaryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
            if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No summary data.'));
            final summary = snapshot.data!;
            return Wrap(
              spacing: 8.0, runSpacing: 8.0,
              children: [
                Chip(label: Text('Total Passes: ${summary['total_gate_passes'] ?? 'N/A'}')),
                Chip(label: Text('Unique Visitors: ${summary['unique_visitors'] ?? 'N/A'}')),
                Chip(label: Text('Unique Vehicles: ${summary['unique_vehicles'] ?? 'N/A'}')),
              ],
            );
          },
        ),
        const Divider(height: 30),
        _buildChart(),
        const Divider(height: 30),
        FutureBuilder<List<dynamic>>(
          future: _logsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
            if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No logs found.'));
            final logs = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index] as Map<String, dynamic>;
                // Get the timestamp string. If it's null, use a default value.
                final timestampString = log['timestamp'] as String? ?? 'N/A';
                String formattedDate = 'N/A';
                
                // Only try to parse if the timestamp is not null
                if (timestampString != 'N/A') {
                  try {
                    // Define the pattern to match the API's date format
                    final apiDateFormat = DateFormat('dd-MM-yyyy, hh:mm:ss a');
                    final dateTime = apiDateFormat.parse(timestampString);
                    // Format the parsed DateTime object for display
                    formattedDate = DateFormat.yMd().add_jm().format(dateTime);
                  } catch (e) {
                    debugPrint('Error parsing date: $e');
                    // Fallback in case parsing fails
                    formattedDate = 'Invalid Date';
                  }
                }
                
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    title: Text('Reason: ${log['reason'] ?? 'N/A'}'),
                    subtitle: Text('By: ${log['security_personnel_email'] ?? 'N/A'} at $formattedDate'),
                    trailing: Chip(
                      label: Text(log['status'] ?? 'N/A'),
                      backgroundColor: (log['status'] == 'failure') ? Colors.red.shade100 : Colors.green.shade100,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildChart() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _chartDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No chart data available.'));

        final chartData = snapshot.data!;
        final labels = List<String>.from(chartData['labels'] ?? []);
        final data = List<num>.from(chartData['data'] ?? []);

        if (labels.isEmpty || data.isEmpty) return const Center(child: Text('No chart data available.'));

        List<FlSpot> spots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList();

        return Column(
          children: [
            Text(chartData['title'] ?? 'Chart', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                    // Show the bottom titles and use the labels from the API.
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          // Ensure we don't try to access an index out of bounds
                          if (value.toInt() >= 0 && value.toInt() < labels.length) {
                            return Text(labels[value.toInt()], style: const TextStyle(fontSize: 10));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 3,
                      color: Theme.of(context).primaryColor,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: Theme.of(context).primaryColor.withAlpha((255 * 0.3).round())),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

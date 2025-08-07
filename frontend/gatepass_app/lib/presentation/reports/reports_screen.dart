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

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
    _fetchReportData();
  }

  String _buildQueryString(Map<String, String> params) {
    if (params.isEmpty) return '';
    return '?${params.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&')}';
  }

  Future<void> _fetchDropdownData() async {
    try {
      final purposesData = await widget.apiClient.get('/api/core-data/purposes/');
      final gatesData = await widget.apiClient.get('/api/core-data/gates/');
      setState(() {
        if (purposesData is List) _purposes = List<Map<String, dynamic>>.from(purposesData);
        if (gatesData is List) _gates = List<Map<String, dynamic>>.from(gatesData);
      });
    } catch (e) {
      debugPrint("Error fetching dropdown data: $e");
    }
  }

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

  Future<void> _selectDate(BuildContext context, {required bool isStartDate}) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2101));
    if (picked != null) setState(() => isStartDate ? _startDate = picked : _endDate = picked);
  }

  void _exportReport(String format) async {
    final Map<String, String> queryParams = {};
    if (_startDate != null) queryParams['start_date'] = DateFormat('yyyy-MM-dd').format(_startDate!);
    if (_endDate != null) queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(_endDate!);
    if (_selectedStatus != null) queryParams['status'] = _selectedStatus!;
    if (_selectedPurposeId != null) queryParams['purpose'] = _selectedPurposeId.toString();
    if (_selectedGateId != null) queryParams['gate'] = _selectedGateId.toString();
    queryParams['format'] = format;

    final queryString = _buildQueryString(queryParams);
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8000';
    final url = Uri.parse('$baseUrl/api/reports/daily-summary/export/$queryString');

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      debugPrint("Could not launch $url");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open export URL.')));
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Filters', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: ElevatedButton.icon(onPressed: () => _selectDate(context, isStartDate: true), icon: const Icon(Icons.calendar_today), label: Text(_startDate == null ? 'Start Date' : DateFormat('yyyy-MM-dd').format(_startDate!)))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton.icon(onPressed: () => _selectDate(context, isStartDate: false), icon: const Icon(Icons.calendar_today), label: Text(_endDate == null ? 'End Date' : DateFormat('yyyy-MM-dd').format(_endDate!)))),
          ],
        ),
        const SizedBox(height: 10),
        _buildDropdown<String>(_selectedStatus, 'Select Status', _statusOptions.map((e) => {'id': e, 'name': e}).toList(), (val) => setState(() => _selectedStatus = val)),
        const SizedBox(height: 10),
        _buildDropdown<int>(_selectedPurposeId, 'Select Purpose', _purposes, (val) => setState(() => _selectedPurposeId = val)),
        const SizedBox(height: 10),
        _buildDropdown<int>(_selectedGateId, 'Select Gate', _gates, (val) => setState(() => _selectedGateId = val)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: ElevatedButton(onPressed: _fetchReportData, child: const Text('Apply Filters'))),
            const SizedBox(width: 10),
            PopupMenuButton<String>(
              onSelected: _exportReport,
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(value: 'csv', child: Text('Export as CSV')),
                const PopupMenuItem<String>(value: 'pdf', child: Text('Export as PDF')),
              ],
              child: ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.download),
                  label: const Text("Export")),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown<T>(T? value, String hint, List<Map<String, dynamic>> items, ValueChanged<T?> onChanged) {
    return DropdownButtonFormField<T>(
      value: value,
      hint: Text(hint),
      onChanged: onChanged,
      items: items.map<DropdownMenuItem<T>>((item) {
        return DropdownMenuItem<T>(
          value: item['id'] as T,
          child: Text(item['name'].toString()),
        );
      }).toList(),
      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12.0)),
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
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    title: Text('Reason: ${log['reason'] ?? 'N/A'}'),
                    subtitle: Text('By: ${log['security_personnel_email'] ?? 'N/A'} at ${DateFormat.yMd().add_jm().format(DateTime.parse(log['timestamp']))}'),
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
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                      belowBarData: BarAreaData(show: true, color: Theme.of(context).primaryColor.withOpacity(0.3)),
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

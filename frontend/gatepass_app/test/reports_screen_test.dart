import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gatepass_app/core/api_client.dart';
import 'package:gatepass_app/presentation/reports/reports_screen.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'reports_screen_test.mocks.dart';

@GenerateMocks([ApiClient])
void main() {
  group('ReportsScreen', () {
    late MockApiClient mockApiClient;

    setUp(() {
      mockApiClient = MockApiClient();

      // Mock for summary
      when(mockApiClient.get(any)).thenAnswer((realInvocation) async {
        final endpoint = realInvocation.positionalArguments.first as String;
        if (endpoint.contains('daily-summary')) {
          return {
            'total_gate_passes': 10,
            'unique_visitors': 5,
            'unique_vehicles': 3,
          };
        }
        if (endpoint.contains('security-incidents')) {
          return [
            {
              'reason': 'Test Incident',
              'security_personnel_email': 'security@test.com',
              'timestamp': DateTime.now().toIso8601String(),
              'status': 'failure',
            }
          ];
        }
        if (endpoint.contains('purposes')) {
          return [
            {'id': 1, 'name': 'Meeting'},
            {'id': 2, 'name': 'Delivery'},
          ];
        }
        if (endpoint.contains('gates')) {
          return [
            {'id': 1, 'name': 'Main Gate'},
            {'id': 2, 'name': 'Service Gate'},
          ];
        }
        if (endpoint.contains('data-visualization')) {
          return {
              'labels': ['2023-01-01', '2023-01-02'],
              'data': [5, 8],
              'title': 'Gate Passes per Day'
          };
        }
        return {};
      });
    });

    testWidgets('renders filters and initial data correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ReportsScreen(apiClient: mockApiClient),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Filters'), findsOneWidget);
      expect(find.text('Total Passes: 10'), findsOneWidget);
      expect(find.text('Unique Visitors: 5'), findsOneWidget);
      expect(find.text('Unique Vehicles: 3'), findsOneWidget);
      expect(find.text('Gate Passes per Day'), findsOneWidget);
      expect(find.text('Reason: Test Incident'), findsOneWidget);
    });
  });
}

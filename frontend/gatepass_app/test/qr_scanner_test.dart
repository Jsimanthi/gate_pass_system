import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gatepass_app/core/api_client.dart';
import 'package:gatepass_app/presentation/security/qr_scanner_screen.dart';
import 'package:mockito/mockito.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mockito/annotations.dart';
import 'qr_scanner_test.mocks.dart';

@GenerateMocks([ApiClient])
void main() {
  group('QrScannerScreen', () {
    late MockApiClient mockApiClient;

    setUp(() {
      mockApiClient = MockApiClient();
    });

    testWidgets('renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QrScannerScreen(apiClient: mockApiClient),
        ),
      );

      expect(find.byType(MobileScanner), findsOneWidget);
      expect(find.text('Scan QR Code'), findsOneWidget);
    });

    testWidgets('handles scan and displays verification result', (WidgetTester tester) async {
      when(mockApiClient.verifyQrCode(any)).thenAnswer((_) async => {'message': 'Gate Pass Validated Successfully!', 'alcohol_test_required': false});

      await tester.pumpWidget(
        MaterialApp(
          home: QrScannerScreen(apiClient: mockApiClient),
        ),
      );

      final QrScannerScreenState state = tester.state(find.byType(QrScannerScreen));
      state.handleScan('test_qr_code');
      await tester.pump();

      expect(find.text('Scan Result: test_qr_code'), findsOneWidget);
      await tester.pump();

      expect(find.text('Verification Result: {message: Gate Pass Validated Successfully!, alcohol_test_required: false}'), findsOneWidget);
    });

    testWidgets('shows alcohol test dialog when required', (WidgetTester tester) async {
      when(mockApiClient.verifyQrCode(any)).thenAnswer((_) async => {'gatepass_id': 123, 'alcohol_test_required': true});

      await tester.pumpWidget(
        MaterialApp(
          home: QrScannerScreen(apiClient: mockApiClient),
        ),
      );

      final QrScannerScreenState state = tester.state(find.byType(QrScannerScreen));
      state.handleScan('test_qr_code');
      await tester.pump();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Alcohol Test Required'), findsOneWidget);
    });
  });
}

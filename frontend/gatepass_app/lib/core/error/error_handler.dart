import 'dart:io';
import 'package:http/http.dart' as http;
import 'failures.dart';

class ErrorHandler {
  Failure handleError(Exception e) {
    if (e is SocketException) {
      return const NetworkFailure('No Internet connection');
    } else if (e is http.ClientException) {
      return NetworkFailure('Network error: ${e.message}');
    } else {
      return ServerFailure('An unexpected error occurred: ${e.toString()}');
    }
  }
}

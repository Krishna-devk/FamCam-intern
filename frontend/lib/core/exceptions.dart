class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, [this.code]);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException(super.message, [super.code]);
}

class CheckoutFailureException extends AppException {
  final int failedItemIndex;
  final Map<String, dynamic> failedItem;
  final String reasonCode;

  CheckoutFailureException({
    required String message,
    required this.failedItemIndex,
    required this.failedItem,
    required this.reasonCode,
  }) : super(message, reasonCode);
}

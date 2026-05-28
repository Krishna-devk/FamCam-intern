sealed class CheckoutResult {}

class BookingDetail {
  final int bookingId;
  final String serviceName;
  final String caregiverName;
  final DateTime date;
  final String startTime;
  final String endTime;
  final int priceCents;

  BookingDetail({
    required this.bookingId,
    required this.serviceName,
    required this.caregiverName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.priceCents,
  });

  factory BookingDetail.fromJson(Map<String, dynamic> json) {
    return BookingDetail(
      bookingId: json['booking_id'] as int,
      serviceName: json['service_name'] as String,
      caregiverName: json['caregiver_name'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      priceCents: json['price_cents'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'service_name': serviceName,
      'caregiver_name': caregiverName,
      'date': date.toIso8601String().substring(0, 10),
      'start_time': startTime,
      'end_time': endTime,
      'price_cents': priceCents,
    };
  }
}

class CheckoutSuccess extends CheckoutResult {
  final List<int> bookingIds;
  final int totalPriceCents;
  final List<BookingDetail> items;

  CheckoutSuccess({
    required this.bookingIds,
    required this.totalPriceCents,
    required this.items,
  });

  factory CheckoutSuccess.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List;
    List<BookingDetail> parsedItems = itemsList.map((i) => BookingDetail.fromJson(i)).toList();
    
    return CheckoutSuccess(
      bookingIds: List<int>.from(json['booking_ids']),
      totalPriceCents: json['total_price_cents'] as int,
      items: parsedItems,
    );
  }
}

class CheckoutFailure extends CheckoutResult {
  final int failedItemIndex;
  final Map<String, dynamic> failedItem;
  final String reasonCode;
  final String message;

  CheckoutFailure({
    required this.failedItemIndex,
    required this.failedItem,
    required this.reasonCode,
    required this.message,
  });

  factory CheckoutFailure.fromJson(Map<String, dynamic> json) {
    return CheckoutFailure(
      failedItemIndex: json['failed_item_index'] as int,
      failedItem: Map<String, dynamic>.from(json['failed_item']),
      reasonCode: json['reason_code'] as String,
      message: json['message'] as String,
    );
  }
}

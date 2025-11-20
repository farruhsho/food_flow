import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TableBooking extends Equatable {
  final String id;
  final int tableNumber;
  final String clientName;
  final String clientPhone;
  final int numberOfGuests;
  final DateTime bookingDate;
  final String bookingTime;
  final String status; // pending, confirmed, cancelled, completed
  final String? specialRequests;
  final String? clientId;

  const TableBooking({
    required this.id,
    required this.tableNumber,
    required this.clientName,
    required this.clientPhone,
    required this.numberOfGuests,
    required this.bookingDate,
    required this.bookingTime,
    required this.status,
    this.specialRequests,
    this.clientId,
  });

  factory TableBooking.fromFirestore(Map<String, dynamic> data, String id) {
    return TableBooking(
      id: id,
      tableNumber: data['tableNumber'] ?? 0,
      clientName: data['clientName'] ?? '',
      clientPhone: data['clientPhone'] ?? '',
      numberOfGuests: data['numberOfGuests'] ?? 0,
      bookingDate: (data['bookingDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      bookingTime: data['bookingTime'] ?? '',
      status: data['status'] ?? 'pending',
      specialRequests: data['specialRequests'],
      clientId: data['clientId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tableNumber': tableNumber,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'numberOfGuests': numberOfGuests,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'bookingTime': bookingTime,
      'status': status,
      'specialRequests': specialRequests,
      'clientId': clientId,
    };
  }

  TableBooking copyWith({
    String? id,
    int? tableNumber,
    String? clientName,
    String? clientPhone,
    int? numberOfGuests,
    DateTime? bookingDate,
    String? bookingTime,
    String? status,
    String? specialRequests,
    String? clientId,
  }) {
    return TableBooking(
      id: id ?? this.id,
      tableNumber: tableNumber ?? this.tableNumber,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      numberOfGuests: numberOfGuests ?? this.numberOfGuests,
      bookingDate: bookingDate ?? this.bookingDate,
      bookingTime: bookingTime ?? this.bookingTime,
      status: status ?? this.status,
      specialRequests: specialRequests ?? this.specialRequests,
      clientId: clientId ?? this.clientId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    tableNumber,
    clientName,
    clientPhone,
    numberOfGuests,
    bookingDate,
    bookingTime,
    status,
    specialRequests,
    clientId,
  ];
}
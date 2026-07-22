import 'package:uuid/uuid.dart';

class AddressModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String houseNumber;
  final String street;
  final String landmark;
  final String city;
  final String state;
  final String pincode;
  final String addressType; // 'Home', 'Work', 'Other'
  final bool isDefault;

  AddressModel({
    String? id,
    required this.name,
    required this.phoneNumber,
    required this.houseNumber,
    required this.street,
    this.landmark = '',
    required this.city,
    required this.state,
    required this.pincode,
    this.addressType = 'Home',
    this.isDefault = false,
  }) : id = id ?? const Uuid().v4();

  factory AddressModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return AddressModel(
      id: id ?? map['id'] ?? const Uuid().v4(),
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      houseNumber: map['houseNumber'] ?? '',
      street: map['street'] ?? '',
      landmark: map['landmark'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      pincode: map['pincode'] ?? '',
      addressType: map['addressType'] ?? 'Home',
      isDefault: map['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'houseNumber': houseNumber,
      'street': street,
      'landmark': landmark,
      'city': city,
      'state': state,
      'pincode': pincode,
      'addressType': addressType,
      'isDefault': isDefault,
    };
  }
  
  String get formattedAddress {
    List<String> parts = [houseNumber, street];
    if (landmark.isNotEmpty) parts.add(landmark);
    parts.addAll([city, "$state - $pincode"]);
    return parts.where((p) => p.trim().isNotEmpty).join(', ');
  }
}

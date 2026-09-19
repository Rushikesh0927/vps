class SavedAddress {
  final String address;
  final String pincode;

  SavedAddress({required this.address, required this.pincode});

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      address: json['address'] ?? '',
      pincode: json['pincode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'pincode': pincode,
    };
  }
}

class UserProfile {
  final String id;
  final String name;
  final String mobile;
  final String email;
  final SavedAddress? savedAddress;

  UserProfile({
    required this.id,
    required this.name,
    required this.mobile,
    required this.email,
    this.savedAddress,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? mobile,
    String? email,
    SavedAddress? savedAddress,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      savedAddress: savedAddress ?? this.savedAddress,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      savedAddress: json['savedAddress'] != null 
          ? SavedAddress.fromJson(json['savedAddress']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'email': email,
      'savedAddress': savedAddress?.toJson(),
    };
  }
}

class UserOrder {
  final String orderId;
  final String productName;
  final String date;
  final String size;
  final int qty;
  final double total;
  final String status;
  final String? driveLink;

  UserOrder({
    required this.orderId,
    required this.productName,
    required this.date,
    required this.size,
    required this.qty,
    required this.total,
    required this.status,
    this.driveLink,
  });
}

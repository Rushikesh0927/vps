import 'editor_models.dart';

class CustomerDetails {
  final String name;
  final String mobile;
  final String whatsapp;
  final String email;
  final String address;
  final String pincode;

  CustomerDetails({
    required this.name,
    required this.mobile,
    required this.whatsapp,
    required this.email,
    required this.address,
    required this.pincode,
  });

  factory CustomerDetails.empty() {
    return CustomerDetails(
      name: '',
      mobile: '',
      whatsapp: '',
      email: '',
      address: '',
      pincode: '',
    );
  }

  CustomerDetails copyWith({
    String? name,
    String? mobile,
    String? whatsapp,
    String? email,
    String? address,
    String? pincode,
  }) {
    return CustomerDetails(
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      address: address ?? this.address,
      pincode: pincode ?? this.pincode,
    );
  }
}

class AddOns {
  final bool customText;
  final String customTextValue;
  final bool customDesign;
  final String customDesignNotes;

  AddOns({
    required this.customText,
    required this.customTextValue,
    required this.customDesign,
    required this.customDesignNotes,
  });

  factory AddOns.empty() {
    return AddOns(
      customText: false,
      customTextValue: '',
      customDesign: false,
      customDesignNotes: '',
    );
  }

  AddOns copyWith({
    bool? customText,
    String? customTextValue,
    bool? customDesign,
    String? customDesignNotes,
  }) {
    return AddOns(
      customText: customText ?? this.customText,
      customTextValue: customTextValue ?? this.customTextValue,
      customDesign: customDesign ?? this.customDesign,
      customDesignNotes: customDesignNotes ?? this.customDesignNotes,
    );
  }
}

class CartItem {
  final String id;
  final PhotoEdit photo;
  final PolaroidSize size;
  final int qty;

  CartItem({
    required this.id,
    required this.photo,
    required this.size,
    required this.qty,
  });

  CartItem copyWith({
    String? id,
    PhotoEdit? photo,
    PolaroidSize? size,
    int? qty,
  }) {
    return CartItem(
      id: id ?? this.id,
      photo: photo ?? this.photo,
      size: size ?? this.size,
      qty: qty ?? this.qty,
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_models.dart';
import '../models/editor_models.dart';

class CartState {
  final List<CartItem> items;
  final AddOns addons;
  final String coupon;
  final double discount;
  final CustomerDetails customerDetails;
  final String paymentMethod;
  final String? orderId;

  // New fields for product context
  final String categoryId;
  final List<int> selectedOptions;
  final double basePrice;

  CartState({
    required this.items,
    required this.addons,
    required this.coupon,
    required this.discount,
    required this.customerDetails,
    required this.paymentMethod,
    this.orderId,
    this.categoryId = '',
    this.selectedOptions = const [],
    this.basePrice = 0,
  });

  factory CartState.initial() {
    return CartState(
      items: [],
      addons: AddOns.empty(),
      coupon: '',
      discount: 0,
      customerDetails: CustomerDetails.empty(),
      paymentMethod: 'online',
    );
  }

  CartState copyWith({
    List<CartItem>? items,
    AddOns? addons,
    String? coupon,
    double? discount,
    CustomerDetails? customerDetails,
    String? paymentMethod,
    String? orderId,
    String? categoryId,
    List<int>? selectedOptions,
    double? basePrice,
  }) {
    return CartState(
      items: items ?? this.items,
      addons: addons ?? this.addons,
      coupon: coupon ?? this.coupon,
      discount: discount ?? this.discount,
      customerDetails: customerDetails ?? this.customerDetails,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      orderId: orderId ?? this.orderId,
      categoryId: categoryId ?? this.categoryId,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      basePrice: basePrice ?? this.basePrice,
    );
  }
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => CartState.initial();

  void setItems(List<PhotoEdit> photos, String categoryId, List<int> selectedOptions, double basePrice) {
    final hasText = photos.any((p) => p.texts.isNotEmpty);
    
    // Create generic cart items without relying on PolaroidSize
    final newItems = photos.map((photo) => CartItem(
      id: photo.id,
      photo: photo,
      size: const PolaroidSize(id: 'std', label: 'Standard', width: 0, height: 0, basePrice: 0), // Dummy backward compat
      qty: photo.qty,
    )).toList();

    state = state.copyWith(
      items: newItems,
      categoryId: categoryId,
      selectedOptions: selectedOptions,
      basePrice: basePrice,
      addons: state.addons.copyWith(customText: hasText || state.addons.customText),
    );
  }

  void updateQty(String id, int qty) {
    final clampedQty = qty > 0 ? qty : 1;
    final updatedItems = state.items.map((i) {
      if (i.id == id) {
        return i.copyWith(qty: clampedQty);
      }
      return i;
    }).toList();
    state = state.copyWith(items: updatedItems);
  }

  void removeItem(String id) {
    final updatedItems = state.items.where((i) => i.id != id).toList();
    state = state.copyWith(items: updatedItems);
  }

  void setAddon(AddOns newAddons) {
    state = state.copyWith(addons: newAddons);
  }

  void setCoupon(String code, double discountAmount) {
    state = state.copyWith(coupon: code, discount: discountAmount);
  }

  void setCustomerDetails(CustomerDetails details) {
    state = state.copyWith(customerDetails: details);
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setOrderId(String id) {
    state = state.copyWith(orderId: id);
  }

  double getSubtotal() {
    return state.basePrice;
  }

  double getAddonCost() {
    return (state.addons.customText ? 10.0 : 0.0) + (state.addons.customDesign ? 15.0 : 0.0);
  }

  double getShipping() {
    final sub = getSubtotal();
    if (sub == 0) return 0;
    return sub >= 500 ? 0.0 : 60.0;
  }

  double getTotal() {
    return getSubtotal() + getAddonCost() + getShipping() - state.discount;
  }

  void clear() {
    state = CartState.initial();
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(() {
  return CartNotifier();
});

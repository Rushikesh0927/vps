import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfdropcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentcomponents/cfpaymentcomponent.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/api/cftheme/cftheme.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../providers/cart_provider.dart';
import '../providers/editor_provider.dart';
import '../providers/user_provider.dart';
import '../utils/config.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _pincodeCtrl;

  String _paymentMethod = 'online'; // 'online' or 'cod'
  bool _isLoading = false;
  int _step = 0; // 0=details, 1=payment, 2=review

  final CFPaymentGatewayService _cfService = CFPaymentGatewayService();

  @override
  void initState() {
    super.initState();
    final userState = ref.read(userProvider);
    _nameCtrl = TextEditingController(text: userState.user?.name ?? '');
    _mobileCtrl = TextEditingController(text: userState.user?.mobile ?? '');
    _addressCtrl = TextEditingController(text: userState.user?.savedAddress?.address ?? '');
    _pincodeCtrl = TextEditingController(text: userState.user?.savedAddress?.pincode ?? '');
    _cfService.setCallback(_onPaymentSuccess, _onPaymentError);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _addressCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  // ── Cashfree Callbacks ────────────────────────────────────────────────────

  void _onPaymentSuccess(String orderId) {
    _finishOrder(orderId, success: true);
  }

  void _onPaymentError(CFErrorResponse error, String orderId) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${error.getMessage()}'),
          backgroundColor: const Color(0xFFFF5A5F),
        ),
      );
    }
  }

  // ── Launch Cashfree Drop Checkout ─────────────────────────────────────────

  Future<void> _launchCashfree(String paymentSessionId, String orderId) async {
    try {
      final session = CFSessionBuilder()
          .setEnvironment(CFEnvironment.PRODUCTION)
          .setPaymentSessionId(paymentSessionId)
          .setOrderId(orderId)
          .build();

      final theme = CFThemeBuilder()
          .setNavigationBarBackgroundColorRes('#FF5A5F')
          .setPrimaryFont('Montserrat')
          .setSecondaryFont('Futura')
          .build();

      final cfPaymentComponent = CFPaymentComponentBuilder()
          .add(CFPaymentModes.CARD)
          .add(CFPaymentModes.UPI)
          .add(CFPaymentModes.NB)
          .add(CFPaymentModes.WALLET)
          .build();

      final dropPayment = CFDropCheckoutPaymentBuilder()
          .setSession(session)
          .setCFUIPaymentComponent(cfPaymentComponent)
          .setCFNativeCheckoutUITheme(theme)
          .build();

      _cfService.doPayment(dropPayment);
    } on CFException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cashfree error: ${e.message}'), backgroundColor: const Color(0xFFFF5A5F)),
        );
      }
    }
  }

  // ── WhatsApp Confirmation ─────────────────────────────────────────────────

  Future<void> _launchWhatsApp(String orderId) async {
    final name = _nameCtrl.text.trim();
    final total = ref.read(cartProvider.notifier).getTotal();
    final editorState = ref.read(editorProvider);
    
    final msg = Uri.encodeComponent(
      '🎉 New Order from Snap-N-Wrap App!\n'
      '━━━━━━━━━━━━━━\n'
      '👤 Name: $name\n'
      '📱 Mobile: ${_mobileCtrl.text.trim()}\n'
      '📦 Category: ${editorState.categoryId}\n'
      '💰 Total: ₹${total.toStringAsFixed(0)}\n'
      '🚚 Address: ${_addressCtrl.text.trim()}, ${_pincodeCtrl.text.trim()}\n'
      '💳 Payment: ${_paymentMethod == 'cod' ? 'Cash on Delivery' : 'Online (Paid)'}\n'
      '🔖 Order ID: $orderId\n'
      '━━━━━━━━━━━━━━\n'
      'Please confirm my order. Thank you!',
    );
    final url = Uri.parse('https://wa.me/918886223462?text=$msg');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // ── Order Finish ──────────────────────────────────────────────────────────

  void _finishOrder(String orderId, {required bool success}) {
    ref.read(cartProvider.notifier).clear();
    _launchWhatsApp(orderId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '✅ Order placed successfully!' : '📝 Order created — please complete payment.'),
          backgroundColor: success ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  // ── API: Create Order ─────────────────────────────────────────────────────

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final cartState = ref.read(cartProvider);
    final userState = ref.read(userProvider);
    final editorState = ref.read(editorProvider);
    final total = ref.read(cartProvider.notifier).getTotal();

    try {
      final payload = {
        'customer': _nameCtrl.text.trim(),
        'mobile': _mobileCtrl.text.trim(),
        'city': _addressCtrl.text.trim(),
        'pincode': _pincodeCtrl.text.trim(),
        'amount': total,
        'size': editorState.categoryId,
        'qty': editorState.photos.length,
        'drive_link': 'App Order — ${editorState.photos.length} photo(s)',
        'addons': [],
        'payment_method': _paymentMethod,
      };

      final headers = <String, String>{'Content-Type': 'application/json'};
      if (userState.user != null) {
        headers['x-user-id'] = userState.user!.id;
      }

      final res = await http.post(
        Uri.parse('${AppConfig.apiUrl}/api/orders'),
        headers: headers,
        body: jsonEncode(payload),
      );

      setState(() => _isLoading = false);

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        final orderId = data['order']['id'] as String;

        if (_paymentMethod == 'cod') {
          // COD — done immediately
          _finishOrder(orderId, success: true);
        } else {
          // Online — create Cashfree payment session
          final payRes = await http.post(
            Uri.parse('${AppConfig.apiUrl}/api/payments/create-order'),
            headers: headers,
            body: jsonEncode({'orderId': orderId, 'amount': total}),
          );

          if (payRes.statusCode == 200) {
            final payData = jsonDecode(payRes.body);
            final sessionId = payData['payment_session_id'] as String;
            await _launchCashfree(sessionId, orderId);
          } else {
            // Fallback to WhatsApp if payment session fails
            _finishOrder(orderId, success: false);
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order. Please try again.'),
            backgroundColor: const Color(0xFFFF5A5F),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: const Color(0xFFFF5A5F),
        ),
      );
    }
  }

  // ── UI Helpers ────────────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF888888)),
        prefixIcon: Icon(icon, color: const Color(0xFFFF5A5F), size: 20),
        filled: true,
        fillColor: const Color(0xFF1C1C1E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF333333))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFFF5A5F), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFFF5A5F))),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFFF5A5F))),
        errorStyle: const TextStyle(color: Color(0xFFFF5A5F)),
      ),
      validator: validator ?? (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      ),
    );
  }

  // ── Step Pages ────────────────────────────────────────────────────────────

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Delivery Details'),
        _buildTextField(controller: _nameCtrl, label: 'Full Name', icon: Icons.person_outline),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _mobileCtrl,
          label: 'Mobile Number',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            if (v.length != 10) return 'Enter valid 10-digit mobile';
            return null;
          },
        ),
        const SizedBox(height: 14),
        _buildTextField(controller: _addressCtrl, label: 'Full Address', icon: Icons.home_outlined, maxLines: 3),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _pincodeCtrl,
          label: 'Pincode',
          icon: Icons.pin_drop_outlined,
          keyboardType: TextInputType.number,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            if (v.length != 6) return 'Enter valid 6-digit pincode';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPaymentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Payment Method'),
        _buildPaymentOption(
          'online',
          'Online Payment',
          'UPI, Cards, Net Banking, Wallets',
          Icons.payment_outlined,
        ),
        const SizedBox(height: 12),
        _buildPaymentOption(
          'cod',
          'Cash on Delivery',
          'Pay when your order arrives',
          Icons.money_outlined,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF333333)),
          ),
          child: Column(
            children: [
              _buildPriceLine('Subtotal', ref.read(cartProvider.notifier).getSubtotal()),
              const SizedBox(height: 8),
              _buildPriceLine('Shipping', ref.read(cartProvider.notifier).getShipping()),
              const Divider(color: Color(0xFF333333), height: 24),
              _buildPriceLine('Total', ref.read(cartProvider.notifier).getTotal(), bold: true, large: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(String value, String title, String subtitle, IconData icon) {
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A0A0B) : const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF5A5F) : const Color(0xFF333333),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFFFF5A5F) : const Color(0xFF888888), size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFFCCCCCC), fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
                ],
              ),
            ),
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? const Color(0xFFFF5A5F) : const Color(0xFF555555), width: 2),
                color: isSelected ? const Color(0xFFFF5A5F) : Colors.transparent,
              ),
              child: isSelected ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceLine(String label, double amount, {bool bold = false, bool large = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          color: bold ? Colors.white : const Color(0xFF888888),
          fontSize: large ? 16 : 14,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
        )),
        Text(
          amount == 0 && label == 'Shipping' ? 'FREE' : '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            color: amount == 0 && label == 'Shipping' ? Colors.green : (bold ? const Color(0xFFFF5A5F) : Colors.white),
            fontSize: large ? 20 : 14,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final editorState = ref.read(editorProvider);
    final total = ref.read(cartProvider.notifier).getTotal();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Order Summary'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF333333)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _reviewRow('👤 Name', _nameCtrl.text),
              _reviewRow('📱 Mobile', _mobileCtrl.text),
              _reviewRow('🏠 Address', _addressCtrl.text),
              _reviewRow('📍 Pincode', _pincodeCtrl.text),
              _reviewRow('📦 Category', editorState.categoryId.replaceAll('_', ' ').toUpperCase()),
              _reviewRow('🖼️ Photos', '${editorState.photos.length} photo(s)'),
              _reviewRow('💳 Payment', _paymentMethod == 'cod' ? 'Cash on Delivery' : 'Online Payment'),
              const Divider(color: Color(0xFF333333), height: 24),
              _buildPriceLine('Total Payable', total, bold: true, large: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  // ── Main Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final steps = ['Details', 'Payment', 'Review'];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Checkout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // ── Step Indicator ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              children: List.generate(steps.length, (i) {
                final isDone = i < _step;
                final isActive = i == _step;
                return Expanded(
                  child: Row(
                    children: [
                      Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDone ? Colors.green : (isActive ? const Color(0xFFFF5A5F) : const Color(0xFF2C2C2E)),
                            ),
                            child: Center(
                              child: isDone
                                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                                  : Text('${i + 1}', style: TextStyle(
                                      color: isActive ? Colors.white : const Color(0xFF888888),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    )),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(steps[i], style: TextStyle(
                            fontSize: 10,
                            color: isActive ? Colors.white : const Color(0xFF888888),
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                          )),
                        ],
                      ),
                      if (i < steps.length - 1)
                        Expanded(child: Container(height: 1, color: i < _step ? Colors.green : const Color(0xFF333333), margin: const EdgeInsets.only(bottom: 20))),
                    ],
                  ),
                );
              }),
            ),
          ),

          // ── Step Content ───────────────────────────────────────────────
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _step == 0
                      ? _buildDetailsStep()
                      : _step == 1
                          ? _buildPaymentStep()
                          : _buildReviewStep(),
                ),
              ),
            ),
          ),

          // ── Navigation Buttons ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            decoration: const BoxDecoration(
              color: Color(0xFF111111),
              border: Border(top: BorderSide(color: Color(0xFF222222))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  if (_step > 0)
                    OutlinedButton(
                      onPressed: () => setState(() => _step--),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF333333)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Icon(Icons.arrow_back),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_step < 2) {
                                if (_step == 0 && !_formKey.currentState!.validate()) return;
                                setState(() => _step++);
                              } else {
                                _placeOrder();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5A5F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              _step == 2
                                  ? (_paymentMethod == 'cod' ? 'Place Order (COD)' : 'Pay & Place Order')
                                  : 'Continue',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

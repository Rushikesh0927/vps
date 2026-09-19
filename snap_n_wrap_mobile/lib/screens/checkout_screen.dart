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
import '../providers/user_provider.dart';
import '../theme.dart';
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
  
  final CFPaymentGatewayService cfPaymentGatewayService = CFPaymentGatewayService();

  @override
  void initState() {
    super.initState();
    final userState = ref.read(userProvider);
    _nameCtrl = TextEditingController(text: userState.user?.name ?? '');
    _mobileCtrl = TextEditingController(text: userState.user?.mobile ?? '');
    _addressCtrl = TextEditingController(text: userState.user?.savedAddress?.address ?? '');
    _pincodeCtrl = TextEditingController(text: userState.user?.savedAddress?.pincode ?? '');
    
    cfPaymentGatewayService.setCallback(verifyPayment, onError);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _addressCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  void verifyPayment(String orderId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment Successful!'), backgroundColor: Colors.green),
    );
    _launchWhatsAppAndFinish(orderId);
  }

  void onError(CFErrorResponse error, String orderId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${error.getMessage()}'), backgroundColor: Colors.red),
    );
  }

  Future<void> _launchWhatsAppAndFinish(String orderId) async {
    final name = _nameCtrl.text.trim();
    final whatsappMsg = Uri.encodeComponent(
      "Hi! I just placed an order on Snap-N-Wrap.\nOrder ID: $orderId\nName: $name\nPlease confirm my order."
    );
    
    final waUrl = Uri.parse("https://wa.me/917993351984?text=$whatsappMsg");
    if (await canLaunchUrl(waUrl)) {
      await launchUrl(waUrl, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch WhatsApp");
    }

    // Clear cart and go home
    ref.read(cartProvider.notifier).clear();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;
    
    final cartState = ref.read(cartProvider);
    final userState = ref.read(userProvider);
    final total = ref.read(cartProvider.notifier).getTotal();

    // Show loading
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator(color: Color(0xFFFF5A5F)))
    );

    try {
      final payload = {
        "customer": _nameCtrl.text.trim(),
        "mobile": _mobileCtrl.text.trim(),
        "city": _addressCtrl.text.trim(),
        "amount": total,
        "size": cartState.items.isNotEmpty ? cartState.items[0].size.label : 'Various',
        "qty": cartState.items.fold(0, (sum, item) => sum + item.qty),
        "drive_link": "App Order", // Assuming file upload happens later or separately via app
        "addons": [],
        "payment_method": "online"
      };

      final headers = {
        'Content-Type': 'application/json',
      };
      if (userState.user != null) {
        headers['x-user-id'] = userState.user!.id;
      }

      final res = await http.post(
        Uri.parse('${AppConfig.apiUrl}/api/orders'),
        headers: headers,
        body: jsonEncode(payload),
      );

      // Hide loading
      if (mounted) Navigator.pop(context);

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        final orderId = data['order']['id'] as String;

        // Skip CF for now since CF payment logic needs a valid session from backend
        // We will directly consider it Cash-On-Delivery / WhatsApp Order for parity
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order Created Successfully!'), backgroundColor: Colors.green),
        );
        
        await _launchWhatsAppAndFinish(orderId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create order: ${res.body}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = ref.read(cartProvider.notifier).getTotal();

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Shipping Details', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                
                _buildTextField(controller: _nameCtrl, label: 'Full Name', icon: Icons.person),
                const SizedBox(height: 16),
                _buildTextField(controller: _mobileCtrl, label: 'Mobile Number', icon: Icons.phone, keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                _buildTextField(controller: _addressCtrl, label: 'Full Address', icon: Icons.home, maxLines: 3),
                const SizedBox(height: 16),
                _buildTextField(controller: _pincodeCtrl, label: 'Pincode', icon: Icons.pin_drop, keyboardType: TextInputType.number),
                
                const SizedBox(height: 48),
                
                // Pay Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _processPayment,
                    child: Text('Pay ₹${total.toInt()}'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: const Color(0xFFFF5A5F)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF5A5F)),
        ),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return 'Please enter $label';
        return null;
      },
    );
  }
}

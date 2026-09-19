import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_models.dart';

class OrderDetailsScreen extends StatelessWidget {
  final UserOrder order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final parsedDate = DateTime.tryParse(order.date) ?? DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: RepaintBoundary(
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: AppBar(
                backgroundColor: const Color(0xFF1D1D1F).withOpacity(0.5),
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                title: Text(
                  'Order #${order.orderId.substring(0, 8)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Timeline
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1D1F),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    Builder(
                      builder: (context) {
                        String statusText = order.status.replaceAll('_', ' ').toUpperCase();
                        if (order.status == 'pending') {
                          statusText = 'PLACED';
                        }
                        Color textColor = Colors.white;
                        if (order.status == 'cancelled' || order.status == 'payment_failed') {
                          textColor = Colors.redAccent;
                        } else if (order.status == 'delivered' || order.status == 'completed') {
                          textColor = Colors.green;
                        }
                        return Text(
                          'Order $statusText',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor, letterSpacing: 1.0),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Placed on ${DateFormat('MMMM dd, yyyy').format(parsedDate)}',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    if (order.status != 'cancelled' && order.status != 'payment_failed')
                      Builder(builder: (context) {
                        final steps = ['Placed', 'Processing', 'Shipped', 'Delivered'];
                        int currentIndex = 0;
                        if (order.status == 'processing') currentIndex = 1;
                        if (order.status == 'shipped' || order.status == 'out_for_delivery') currentIndex = 2;
                        if (order.status == 'delivered' || order.status == 'completed') currentIndex = 3;

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(steps.length * 2 - 1, (index) {
                            if (index % 2 != 0) {
                              final stepIndex = index ~/ 2;
                              final isCompleted = stepIndex < currentIndex;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 11.0),
                                  child: Container(
                                    height: 2,
                                    color: isCompleted ? const Color(0xFFFF5A5F) : Colors.white.withOpacity(0.1),
                                  ),
                                ),
                              );
                            }
                            final stepIndex = index ~/ 2;
                            final isActive = stepIndex == currentIndex;
                            final isCompleted = stepIndex < currentIndex;
                            return Column(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isCompleted || isActive ? const Color(0xFFFF5A5F) : const Color(0xFF2C2C2E),
                                    border: Border.all(
                                      color: isCompleted || isActive ? const Color(0xFFFF5A5F) : Colors.white.withOpacity(0.1),
                                      width: 2,
                                    ),
                                  ),
                                  child: isCompleted
                                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                                      : (isActive ? Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))) : null),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  steps[stepIndex],
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isCompleted || isActive ? Colors.white : Colors.white.withOpacity(0.4),
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            );
                          }),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Items Section (currently aggregated since we don't have detailed item breakdown in UserOrder yet)
              const Text(
                'Order Summary',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1D1F),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.inventory_2_outlined, color: Color(0xFFFF5A5F), size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${order.qty} Premium Items',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Size: ${order.size}',
                                style: const TextStyle(fontSize: 14, color: Color(0xFFA1A1A6)),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${order.total.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Payment Details
              const Text(
                'Payment Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1D1F),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal', style: TextStyle(color: Color(0xFFA1A1A6))),
                        Text('₹${order.total.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Shipping', style: TextStyle(color: Color(0xFFA1A1A6))),
                        Text('Free', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('₹${order.total.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFFF5A5F), fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),

              if (order.status == 'cancelled' || order.status == 'payment_failed') ...[
                // No extra actions for failed/cancelled orders
              ] else if (order.status == 'delivered' || order.status == 'completed') ...[
                // Delivered Actions
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice will be downloaded.')));
                    },
                    icon: const Icon(Icons.receipt_long_outlined, color: Colors.white),
                    label: const Text('Invoice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D1D1F),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.white.withOpacity(0.05)),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Drive Link for Pending/Processing/Shipped
                if (order.driveLink != null && order.driveLink!.isNotEmpty)
                  GestureDetector(
                    onTap: () async {
                      String link = order.driveLink!.trim();
                      if (link.isEmpty || link == 'null') {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No valid link found yet. Please check back later.')));
                        }
                        return;
                      }
                      if (!link.startsWith('http')) {
                        link = 'https://$link';
                      }
                        try {
                          final url = Uri.parse(link);
                          bool launched = await launchUrl(url, mode: LaunchMode.externalNonBrowserApplication);
                          if (!launched) {
                            launched = await launchUrl(url, mode: LaunchMode.externalApplication);
                            if (!launched) {
                              throw Exception('No app can handle this URL');
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF1D1D1F),
                                title: const Text('Could not open link', style: TextStyle(color: Colors.white)),
                                content: Text('Link: $link\n\nPlease copy the link and open it in your browser manually.', style: const TextStyle(color: Colors.white70)),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: link));
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                                      Navigator.pop(ctx);
                                    },
                                    child: const Text('Copy Link', style: TextStyle(color: Colors.blueAccent)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('OK', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_to_drive, color: Colors.blueAccent),
                          SizedBox(width: 8),
                          Text(
                            'View Uploaded Photos',
                            style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const Center(
                    child: Text(
                      'No uploaded photos available for this order.',
                      style: TextStyle(color: Color(0xFFA1A1A6)),
                    ),
                  ),
              ],
              
              const SizedBox(height: 16), // Prevent overlap with Customer Support button
              
              // Always show Customer Support button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final message = 'Hi Snap-N-Wrap, I need help with my Order.\n\n*Order Details:*\nOrder ID: ${order.orderId.substring(0, 8)}\nProduct: ${order.productName}\nAmount: ₹${order.total.toStringAsFixed(2)}\nStatus: ${order.status.toUpperCase()}';
                    final url = Uri.parse('https://wa.me/918886223462?text=${Uri.encodeComponent(message)}');
                    try {
                      bool launched = await launchUrl(url, mode: LaunchMode.externalNonBrowserApplication);
                      if (!launched) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp.')));
                      }
                    }
                  },
                  icon: const Icon(Icons.support_agent_outlined, color: Colors.white),
                  label: const Text('Customer Support', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5A5F),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

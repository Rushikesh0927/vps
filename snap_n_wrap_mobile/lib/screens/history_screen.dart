import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import 'package:intl/intl.dart';
import 'order_details_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final orders = userState.orders;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const Text(
                'My Orders',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64, color: Colors.white.withOpacity(0.2)),
                            const SizedBox(height: 16),
                            Text(
                              'No past orders found',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.8)),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your completed orders will appear here.',
                              style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5)),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: orders.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OrderDetailsScreen(order: order),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                              color: const Color(0xFF1D1D1F),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      order.productName,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                      Builder(
                                        builder: (context) {
                                          Color badgeColor = Colors.orange;
                                          if (order.status == 'delivered' || order.status == 'completed') {
                                            badgeColor = Colors.green;
                                          } else if (order.status == 'cancelled' || order.status == 'payment_failed') {
                                            badgeColor = Colors.red;
                                          }

                                          String statusText = order.status.replaceAll('_', ' ').toUpperCase();
                                          if (order.status == 'pending') {
                                            statusText = 'PLACED';
                                          }

                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: badgeColor.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: badgeColor),
                                            ),
                                            child: Text(
                                              statusText,
                                              style: TextStyle(
                                                color: badgeColor,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.tryParse(order.date) ?? DateTime.now()),
                                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                                ),
                                const SizedBox(height: 16),
                                const Divider(color: Colors.white10),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${order.qty} Items',
                                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                                    ),
                                    Text(
                                      '₹${order.total.toStringAsFixed(2)}',
                                      style: const TextStyle(color: Color(0xFFFF5A5F), fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

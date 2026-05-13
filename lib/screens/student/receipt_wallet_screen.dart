import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';

class ReceiptWalletScreen extends ConsumerStatefulWidget {
  const ReceiptWalletScreen({super.key});

  @override
  ConsumerState<ReceiptWalletScreen> createState() => _ReceiptWalletScreenState();
}

class _ReceiptWalletScreenState extends ConsumerState<ReceiptWalletScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    ref.listen(currentUserProvider, (prev, next) {
      next.whenData((user) {
        if (user == null) return;
        if (_initialized) return;
        _initialized = true;
        ref.read(paymentProvider.notifier).loadStudentPayments(user.id);
      });
    });
  }

  Future<void> _refresh() async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;
    await ref.read(paymentProvider.notifier).loadStudentPayments(user.id);
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.receiptWallet),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: paymentState.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : paymentState.payments.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(20),
                    children: const [
                      SizedBox(height: 40),
                      Icon(Icons.wallet_outlined, size: 48, color: AppColors.lightGrey),
                      SizedBox(height: 14),
                      Text(
                        AppStrings.noPaymentsYet,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkGrey,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        AppStrings.noPaymentsSub,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.mediumGrey, height: 1.6),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: paymentState.payments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final p = paymentState.payments[index];
                      final statusColor = AppColors.getStatusColor(p.verificationStatus);
                      final bg = AppColors.getStatusBackgroundColor(p.verificationStatus);

                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              p.isVerified ? Icons.check_circle_outline_rounded : Icons.pending_rounded,
                              color: statusColor,
                            ),
                          ),
                          title: Text(
                            p.formattedAmount,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkGrey,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${p.semester} • ${p.session}\nRRR: ${p.rrrNumber}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.mediumGrey,
                                height: 1.4,
                              ),
                            ),
                          ),
                          trailing: IconButton(
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: p.rrrNumber));
                              if (!context.mounted) return;
                              AppHelpers.showSnackBar(
                                context,
                                message: 'RRR copied to clipboard',
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, color: AppColors.lightGrey),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

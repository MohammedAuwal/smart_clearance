import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';

class PaymentVerificationScreen extends ConsumerStatefulWidget {
  const PaymentVerificationScreen({super.key});

  @override
  ConsumerState<PaymentVerificationScreen> createState() =>
      _PaymentVerificationScreenState();
}

class _PaymentVerificationScreenState
    extends ConsumerState<PaymentVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rrrController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _rrrController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double? _parseAmount(String raw) {
    final cleaned = raw.replaceAll(',', '').trim();
    return double.tryParse(cleaned);
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();

    final user = await ref.read(currentUserProvider.future);
    if (user == null) {
      AppHelpers.showSnackBar(
        context,
        message: 'Please login again.',
        isError: true,
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final amount = _parseAmount(_amountController.text);
    if (amount == null || amount <= 0) {
      AppHelpers.showSnackBar(
        context,
        message: 'Enter a valid amount paid',
        isError: true,
      );
      return;
    }

    final semester = AppHelpers.getCurrentSemester();
    final session = AppHelpers.getCurrentSession();

    final ok = await ref.read(paymentProvider.notifier).verifyPayment(
          studentId: user.id,
          rrr: _rrrController.text.trim(),
          amount: amount,
          semester: semester,
          session: session,
        );

    if (!mounted) return;

    if (ok) {
      AppHelpers.showSnackBar(
        context,
        message: 'Payment verified and saved successfully.',
        isSuccess: true,
      );
    } else {
      final err = ref.read(paymentProvider).errorMessage;
      if (err != null) {
        AppHelpers.showSnackBar(context, message: err, isError: true);
        ref.read(paymentProvider.notifier).clearError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.paymentVerification)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.infoBorder),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'MVP Note: This verification currently saves your RRR as verified. '
                    'Later, we will connect real Remita verification.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.info,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppStrings.rrrNumber,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkGrey,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _rrrController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: Validators.validateRrr,
                      decoration: const InputDecoration(
                        hintText: AppStrings.rrrHint,
                        prefixIcon: Icon(Icons.confirmation_number_outlined),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Amount Paid',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkGrey,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _verify(),
                      validator: (v) => Validators.validateRequired(v, 'Amount'),
                      decoration: const InputDecoration(
                        hintText: 'e.g. 45000',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                    ),
                    const SizedBox(height: 22),
                    ElevatedButton(
                      onPressed: paymentState.isVerifying ? null : _verify,
                      child: paymentState.isVerifying
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(AppStrings.verifyPayment),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          if (paymentState.currentVerification != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verification Result',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _kv('RRR', paymentState.currentVerification!.rrrNumber),
                    _kv('Amount', paymentState.currentVerification!.formattedAmount),
                    _kv('Status', paymentState.currentVerification!.statusDisplay),
                    _kv('Semester', paymentState.currentVerification!.semester),
                    _kv('Session', paymentState.currentVerification!.session),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              k,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.mediumGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.darkGrey,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

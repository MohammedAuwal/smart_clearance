import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment_model.dart';
import '../core/services/supabase_service.dart';
import '../core/utils/helpers.dart';

// ─── Payment State ────────────────────────────────────────────────────────────
class PaymentState {
  final bool isLoading;
  final bool isVerifying;
  final List<PaymentModel> payments;
  final PaymentModel? currentVerification;
  final String? errorMessage;
  final String? successMessage;

  const PaymentState({
    this.isLoading = false,
    this.isVerifying = false,
    this.payments = const [],
    this.currentVerification,
    this.errorMessage,
    this.successMessage,
  });

  PaymentState copyWith({
    bool? isLoading,
    bool? isVerifying,
    List<PaymentModel>? payments,
    PaymentModel? currentVerification,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearVerification = false,
  }) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      isVerifying: isVerifying ?? this.isVerifying,
      payments: payments ?? this.payments,
      currentVerification:
          clearVerification ? null : currentVerification ?? this.currentVerification,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }

  bool get hasError => errorMessage != null;
  bool get hasSuccess => successMessage != null;
  bool get hasPayments => payments.isNotEmpty;

  // Get the most recent verified payment
  PaymentModel? get latestPayment {
    final verified = payments.where((p) => p.isVerified).toList();
    if (verified.isEmpty) return null;
    verified.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return verified.first;
  }

  // Check if student has paid for the current semester
  bool isPaidForSemester(String semester, String session) {
    return payments.any(
      (p) =>
          p.isVerified &&
          p.semester == semester &&
          p.session == session,
    );
  }
}

// ─── Payment Notifier ─────────────────────────────────────────────────────────
class PaymentNotifier extends StateNotifier<PaymentState> {
  final SupabaseService _supabaseService;

  PaymentNotifier({required SupabaseService supabaseService})
      : _supabaseService = supabaseService,
        super(const PaymentState());

  // ─── Load All Payments for a Student ──────────────────────────────────
  Future<void> loadStudentPayments(String studentId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _supabaseService.getStudentPayments(studentId);

    if (result.success) {
      state = state.copyWith(
        isLoading: false,
        payments: result.data ?? [],
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.error,
      );
    }
  }

  // ─── Verify RRR Payment ────────────────────────────────────────────────
  // For MVP: We do manual verification since Remita API needs business account
  // The student enters RRR and amount, we save it as verified
  // In production: Replace this with actual Remita API call
  Future<bool> verifyPayment({
    required String studentId,
    required String rrr,
    required double amount,
    required String semester,
    required String session,
  }) async {
    state = state.copyWith(isVerifying: true, clearError: true);

    try {
      // Step 1: Check if this RRR has already been verified
      final alreadyVerified = await _supabaseService.rrrAlreadyVerified(rrr);

      if (alreadyVerified) {
        state = state.copyWith(
          isVerifying: false,
          errorMessage:
              'This RRR number has already been verified. '
              'Each RRR can only be used once.',
        );
        return false;
      }

      // Step 2: For MVP, we trust the student's entry and mark as verified
      // In production: Call Remita API here to confirm payment
      // final remitaResult = await RemitaService().verifyRrr(rrr);

      // Step 3: Save the payment record to Supabase
      final payment = PaymentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        studentId: studentId,
        rrrNumber: rrr.trim(),
        amountPaid: amount,
        paymentDate: DateTime.now(),
        semester: semester,
        session: session,
        verificationStatus: 'verified',
        verifiedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final saveResult = await _supabaseService.savePayment(payment);

      if (saveResult.success) {
        // Add to local list
        final updatedPayments = [
          saveResult.data!,
          ...state.payments,
        ];

        state = state.copyWith(
          isVerifying: false,
          payments: updatedPayments,
          currentVerification: saveResult.data,
          successMessage:
              'Payment verified successfully! '
              'Your school fee for $semester has been confirmed.',
        );
        return true;
      } else {
        state = state.copyWith(
          isVerifying: false,
          errorMessage: saveResult.error ?? 'Failed to save payment record.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isVerifying: false,
        errorMessage: 'Verification failed. Please try again.',
      );
      return false;
    }
  }

  // ─── Upload Physical Receipt as Backup ────────────────────────────────
  Future<bool> updateReceiptUrl({
    required String paymentId,
    required String receiptUrl,
  }) async {
    final result = await _supabaseService.updatePaymentReceipt(
      paymentId: paymentId,
      receiptUrl: receiptUrl,
    );

    if (result.success) {
      // Update the local list
      final updatedPayments = state.payments.map((p) {
        if (p.id == paymentId) {
          return p.copyWith(receiptUrl: receiptUrl);
        }
        return p;
      }).toList();

      state = state.copyWith(payments: updatedPayments);
      return true;
    }
    return false;
  }

  // ─── Clear Error and Success ───────────────────────────────────────────
  void clearError() => state = state.copyWith(clearError: true);
  void clearSuccess() => state = state.copyWith(clearSuccess: true);
  void clearVerification() => state = state.copyWith(clearVerification: true);
}

// ─── Payment Provider ─────────────────────────────────────────────────────────
final paymentProvider =
    StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  return PaymentNotifier(supabaseService: SupabaseService());
});

// ─── Student Payments List Provider ──────────────────────────────────────────
// Automatically loads payments when studentId is provided
final studentPaymentsProvider =
    FutureProvider.family<List<PaymentModel>, String>((ref, studentId) async {
  final result = await SupabaseService().getStudentPayments(studentId);
  if (result.success) return result.data ?? [];
  return [];
});

// ─── Current Semester Payment Status Provider ─────────────────────────────────
final currentSemesterPaidProvider =
    Provider.family<bool, String>((ref, studentId) {
  final paymentState = ref.watch(paymentProvider);
  final semester = AppHelpers.getCurrentSemester();
  final session = AppHelpers.getCurrentSession();
  return paymentState.isPaidForSemester(semester, session);
});

class PaymentModel {
  final String id;
  final String studentId;
  final String rrrNumber;
  final double amountPaid;
  final DateTime paymentDate;
  final String semester;
  final String session;
  final String verificationStatus;
  final DateTime? verifiedAt;
  final String? receiptUrl;
  final DateTime createdAt;

  const PaymentModel({
    required this.id,
    required this.studentId,
    required this.rrrNumber,
    required this.amountPaid,
    required this.paymentDate,
    required this.semester,
    required this.session,
    required this.verificationStatus,
    this.verifiedAt,
    this.receiptUrl,
    required this.createdAt,
  });

  // ─── From Supabase JSON ──────────────────────────────────────────────────────
  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      rrrNumber: json['rrr_number'] as String,
      amountPaid: (json['amount_paid'] as num).toDouble(),
      paymentDate: DateTime.parse(json['payment_date'] as String),
      semester: json['semester'] as String,
      session: json['session'] as String,
      verificationStatus: json['verification_status'] as String,
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'] as String)
          : null,
      receiptUrl: json['receipt_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // ─── To JSON for Supabase Insert ─────────────────────────────────────────────
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'rrr_number': rrrNumber,
      'amount_paid': amountPaid,
      'payment_date': paymentDate.toIso8601String(),
      'semester': semester,
      'session': session,
      'verification_status': verificationStatus,
      'verified_at': verifiedAt?.toIso8601String(),
      'receipt_url': receiptUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ─── For Supabase Insert (without id and created_at, Supabase generates them)
  Map<String, dynamic> toInsertJson() {
    return {
      'student_id': studentId,
      'rrr_number': rrrNumber,
      'amount_paid': amountPaid,
      'payment_date': paymentDate.toIso8601String(),
      'semester': semester,
      'session': session,
      'verification_status': verificationStatus,
      'verified_at': verifiedAt?.toIso8601String(),
      'receipt_url': receiptUrl,
    };
  }

  // ─── CopyWith ────────────────────────────────────────────────────────────────
  PaymentModel copyWith({
    String? id,
    String? studentId,
    String? rrrNumber,
    double? amountPaid,
    DateTime? paymentDate,
    String? semester,
    String? session,
    String? verificationStatus,
    DateTime? verifiedAt,
    String? receiptUrl,
    DateTime? createdAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      rrrNumber: rrrNumber ?? this.rrrNumber,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentDate: paymentDate ?? this.paymentDate,
      semester: semester ?? this.semester,
      session: session ?? this.session,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ─── Convenience Getters ─────────────────────────────────────────────────────
  bool get isVerified => verificationStatus == 'verified';
  bool get isPending => verificationStatus == 'pending';
  bool get isFailed => verificationStatus == 'failed';

  // Format amount as Nigerian Naira
  String get formattedAmount {
    final amount = amountPaid.toStringAsFixed(2);
    // Add comma separators
    final parts = amount.split('.');
    final whole = parts[0];
    final decimal = parts[1];
    final buffer = StringBuffer();
    int count = 0;
    for (int i = whole.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(whole[i]);
      count++;
    }
    return '₦${buffer.toString().split('').reversed.join()}.$decimal';
  }

  String get statusDisplay {
    switch (verificationStatus) {
      case 'verified':
        return 'Verified';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      default:
        return 'Unknown';
    }
  }

  @override
  String toString() {
    return 'PaymentModel(id: $id, rrr: $rrrNumber, status: $verificationStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

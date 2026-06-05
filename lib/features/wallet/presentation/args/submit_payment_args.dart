class SubmitPaymentArgs {
  const SubmitPaymentArgs({
    required this.flatId,
    this.canManage = false,
    this.initialAmount,
    this.paymentRequestId,
    this.requestedAmount,
    this.requestNote,
    this.requestedByName,
  });

  final String flatId;

  /// Whether the current user is a manager — used to open the correct tab
  /// after payment submission.
  final bool canManage;

  final double? initialAmount;
  final String? paymentRequestId;
  final double? requestedAmount;
  final String? requestNote;
  final String? requestedByName;
}

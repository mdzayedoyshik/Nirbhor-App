class SubmitPaymentArgs {
  const SubmitPaymentArgs({
    required this.flatId,
    this.initialAmount,
    this.paymentRequestId,
    this.requestedAmount,
    this.requestNote,
    this.requestedByName,
  });

  final String flatId;
  final double? initialAmount;
  final String? paymentRequestId;
  final double? requestedAmount;
  final String? requestNote;
  final String? requestedByName;
}

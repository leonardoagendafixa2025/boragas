enum InvoiceStatus { open, paid, overdue }

class CommissionInvoiceModel {
  final String id;
  final String storeId;
  final String storeName;
  final String period; // e.g. "01/11 a 07/11"
  final double totalStoreSales;
  final double commissionPercent;
  final double totalCommissionDue;
  final DateTime dueDate;
  final InvoiceStatus status;
  final String pixCopyPaste;

  const CommissionInvoiceModel({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.period,
    required this.totalStoreSales,
    required this.commissionPercent,
    required this.totalCommissionDue,
    required this.dueDate,
    required this.status,
    required this.pixCopyPaste,
  });

  CommissionInvoiceModel copyWith({
    String? id,
    String? storeId,
    String? storeName,
    String? period,
    double? totalStoreSales,
    double? commissionPercent,
    double? totalCommissionDue,
    DateTime? dueDate,
    InvoiceStatus? status,
    String? pixCopyPaste,
  }) {
    return CommissionInvoiceModel(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      period: period ?? this.period,
      totalStoreSales: totalStoreSales ?? this.totalStoreSales,
      commissionPercent: commissionPercent ?? this.commissionPercent,
      totalCommissionDue: totalCommissionDue ?? this.totalCommissionDue,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      pixCopyPaste: pixCopyPaste ?? this.pixCopyPaste,
    );
  }
}

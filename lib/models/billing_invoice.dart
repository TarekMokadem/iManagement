class BillingInvoice {
  final String id;
  final String? number;
  final String status;
  final int amountDue;
  final String currency;
  final DateTime? createdAt;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final String? hostedInvoiceUrl;
  final String? invoicePdfUrl;

  BillingInvoice({
    required this.id,
    required this.status,
    required this.amountDue,
    required this.currency,
    this.number,
    this.createdAt,
    this.periodStart,
    this.periodEnd,
    this.hostedInvoiceUrl,
    this.invoicePdfUrl,
  });

  factory BillingInvoice.fromJson(Map<String, dynamic> json) {
    DateTime? parseUnix(dynamic value) {
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true).toLocal();
      }
      return null;
    }

    return BillingInvoice(
      id: json['id'] as String,
      number: json['number'] as String?,
      status: json['status'] as String? ?? 'unknown',
      amountDue: (json['amount_due'] as int?) ?? 0,
      currency: (json['currency'] as String? ?? 'usd').toUpperCase(),
      createdAt: parseUnix(json['created']),
      periodStart: parseUnix((json['period_start'] ?? json['lines']?['data']?[0]?['period']?['start'])),
      periodEnd: parseUnix((json['period_end'] ?? json['lines']?['data']?[0]?['period']?['end'])),
      hostedInvoiceUrl: json['hosted_invoice_url'] as String?,
      invoicePdfUrl: json['invoice_pdf'] as String?,
    );
  }
}



class WeeklyTrend {
  final String day;
  final int count;

  WeeklyTrend({required this.day, required this.count});

  factory WeeklyTrend.fromJson(Map<String, dynamic> json) {
    return WeeklyTrend(
      day: json['day']?.toString() ?? '',
      count: int.tryParse(json['count']?.toString() ?? '0') ?? 0,
    );
  }
}

class ShopAnalytics {
  final double totalSales;
  final double totalStockValue;
  final double customerDues;
  final List<WeeklyTrend> weeklyTrend;

  ShopAnalytics({
    required this.totalSales,
    required this.totalStockValue,
    required this.customerDues,
    required this.weeklyTrend,
  });

  factory ShopAnalytics.fromJson(Map<String, dynamic> json) {
    return ShopAnalytics(
      totalSales: double.tryParse(json['total_sales']?.toString() ?? '0.0') ?? 0.0,
      totalStockValue: double.tryParse(json['total_stock_value']?.toString() ?? '0.0') ?? 0.0,
      customerDues: double.tryParse(json['customer_dues']?.toString() ?? '0.0') ?? 0.0,
      weeklyTrend: (json['weekly_trend'] as List? ?? [])
          .map((i) => WeeklyTrend.fromJson(i))
          .toList(),
    );
  }
}

class RecentSale {
  final String orderRef;
  final String customerName;
  final double amount;
  final String date;

  RecentSale({
    required this.orderRef,
    required this.customerName,
    required this.amount,
    required this.date,
  });

  factory RecentSale.fromJson(Map<String, dynamic> json) {
    return RecentSale(
      orderRef: json['order_ref']?.toString() ?? '',
      customerName: json['customer_name'] ?? 'Walk-in',
      amount: double.tryParse(json['amount']?.toString() ?? '0.0') ?? 0.0,
      date: json['date']?.toString() ?? '',
    );
  }
}
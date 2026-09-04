class DayEndSummary {
  final DateTime date;
  final int totalBills;
  final double retailSales;
  final double wholesaleSales;
  final double totalSales;
  final double cashSales;
  final double cardSales;
  final double creditSales;
  final double totalCost;
  final double grossProfit;
  final double totalExpenses;
  final double netProfit;

  DayEndSummary({
    required this.date,
    required this.totalBills,
    required this.retailSales,
    required this.wholesaleSales,
    required this.totalSales,
    required this.cashSales,
    required this.cardSales,
    required this.creditSales,
    required this.totalCost,
    required this.grossProfit,
    required this.totalExpenses,
    required this.netProfit,
  });
}

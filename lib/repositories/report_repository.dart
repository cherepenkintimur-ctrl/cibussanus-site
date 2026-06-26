import '../database/db_service.dart';

class ReportRepository {
  const ReportRepository();

  Future<double> revenueByPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final row = await DbService.instance.queryOne(
      '''
      SELECT COALESCE(SUM(total_amount), 0) AS revenue
      FROM orders
      WHERE order_date >= ? AND order_date < ?
      ''',
      arguments: [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    return row == null ? 0.0 : (row['revenue'] as num).toDouble();
  }

  Future<Map<String, double>> checkStatisticsByPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final row = await DbService.instance.queryOne(
      '''
      SELECT
          COALESCE(AVG(total_amount), 0) AS average_check,
          COALESCE(MAX(total_amount), 0) AS maximum_check,
          COALESCE(MIN(total_amount), 0) AS minimum_check
      FROM orders
      WHERE order_date >= ? AND order_date < ?
      ''',
      arguments: [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    return {
      'average_check': row == null ? 0.0 : (row['average_check'] as num).toDouble(),
      'maximum_check': row == null ? 0.0 : (row['maximum_check'] as num).toDouble(),
      'minimum_check': row == null ? 0.0 : (row['minimum_check'] as num).toDouble(),
    };
  }

  Future<List<Map<String, dynamic>>> hourlyLoadByPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return DbService.instance.query(
      '''
      SELECT
          CAST(strftime('%H', order_date) AS INTEGER) AS hour,
          COUNT(*) AS orders_count,
          COALESCE(SUM(total_amount), 0) AS revenue
      FROM orders
      WHERE order_date >= ? AND order_date < ?
      GROUP BY strftime('%H', order_date)
      ORDER BY hour
      ''',
      arguments: [startDate.toIso8601String(), endDate.toIso8601String()],
    );
  }

  Future<List<Map<String, dynamic>>> topDishesByPeriod({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    return DbService.instance.query(
      '''
      SELECT
          d.id AS dish_id,
          d.name AS dish_name,
          SUM(oi.quantity) AS quantity_sold,
          COALESCE(SUM(oi.line_total), 0) AS revenue
      FROM order_items oi
      JOIN orders o ON o.id = oi.order_id
      JOIN dishes d ON d.id = oi.dish_id
      WHERE o.order_date >= ? AND o.order_date < ?
      GROUP BY d.id, d.name
      ORDER BY quantity_sold DESC, revenue DESC
      LIMIT ?
      ''',
      arguments: [startDate.toIso8601String(), endDate.toIso8601String(), limit],
    );
  }
}

class DbQueries {
  DbQueries._();

  static const String revenueByPeriod = '''
SELECT COALESCE(SUM(total_amount), 0) AS revenue
FROM orders
WHERE order_date >= ? AND order_date < ?
''';

  static const String checkStatisticsByPeriod = '''
SELECT
    COALESCE(AVG(total_amount), 0) AS average_check,
    COALESCE(MAX(total_amount), 0) AS maximum_check,
    COALESCE(MIN(total_amount), 0) AS minimum_check
FROM orders
WHERE order_date >= ? AND order_date < ?
''';

  static const String hourlyLoadByPeriod = '''
SELECT
    CAST(strftime('%H', order_date) AS INTEGER) AS hour,
    COUNT(*) AS orders_count,
    COALESCE(SUM(total_amount), 0) AS revenue
FROM orders
WHERE order_date >= ? AND order_date < ?
GROUP BY strftime('%H', order_date)
ORDER BY hour
''';

  static const String topDishesByPeriod = '''
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
''';
}

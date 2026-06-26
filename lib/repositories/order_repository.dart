import '../database/db_service.dart';
import '../models/order.dart';
import '../models/order_item.dart';

class OrderRepository {
  const OrderRepository();

  Future<int> create({
    required String orderNumber,
    DateTime? orderDate,
    String? paymentMethod,
    String? notes,
    required List<OrderItem> items,
  }) async {
    return DbService.instance.transaction<int>(() async {
      final orderId = await DbService.instance.insert('orders', {
        'order_number': orderNumber,
        'order_date': orderDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'total_amount': 0,
        'payment_method': paymentMethod,
        'notes': notes,
      });

      await _insertItems(orderId, items);
      await recalculateTotal(orderId);

      return orderId;
    });
  }

  Future<int> updateWithItems({
    required int id,
    required String orderNumber,
    DateTime? orderDate,
    String? paymentMethod,
    String? notes,
    required List<OrderItem> items,
  }) async {
    return DbService.instance.transaction<int>(() async {
      await DbService.instance.update(
        'orders',
        {
          'order_number': orderNumber,
          if (orderDate != null) 'order_date': orderDate.toIso8601String(),
          'payment_method': paymentMethod,
          'notes': notes,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      await DbService.instance.delete(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [id],
      );

      await _insertItems(id, items);
      await recalculateTotal(id);

      return id;
    });
  }

  Future<void> _insertItems(int orderId, List<OrderItem> items) async {
    for (final item in items) {
      final lineTotal = item.quantity * item.unitPrice;
      await DbService.instance.insert('order_items', {
        'order_id': orderId,
        'dish_id': item.dishId,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
        'line_total': lineTotal,
      });
    }
  }

  Future<List<OrderModel>> getAll() async {
    final rows = await DbService.instance.query(
      'SELECT id, order_number, order_date, total_amount, payment_method, notes FROM orders ORDER BY order_date DESC, id DESC',
    );
    return rows.map(OrderModel.fromMap).toList();
  }

  Future<OrderModel?> getById(int id) async {
    final row = await DbService.instance.queryOne(
      'SELECT id, order_number, order_date, total_amount, payment_method, notes FROM orders WHERE id = ?',
      arguments: [id],
    );
    return row == null ? null : OrderModel.fromMap(row);
  }

  Future<List<Map<String, dynamic>>> getDetails(int orderId) async {
    return DbService.instance.query(
      '''
      SELECT
          oi.id,
          oi.order_id,
          oi.dish_id,
          d.name AS dish_name,
          oi.quantity,
          oi.unit_price,
          oi.line_total
      FROM order_items oi
      JOIN dishes d ON d.id = oi.dish_id
      WHERE oi.order_id = ?
      ORDER BY oi.id
      ''',
      arguments: [orderId],
    );
  }

  Future<int> update({
    required int id,
    required String orderNumber,
    DateTime? orderDate,
    String? paymentMethod,
    String? notes,
  }) async {
    return DbService.instance.update(
      'orders',
      {
        'order_number': orderNumber,
        if (orderDate != null) 'order_date': orderDate.toIso8601String(),
        'payment_method': paymentMethod,
        'notes': notes,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) async {
    return DbService.instance.delete(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> recalculateTotal(int orderId) async {
    final row = await DbService.instance.queryOne(
      'SELECT COALESCE(SUM(line_total), 0) AS total FROM order_items WHERE order_id = ?',
      arguments: [orderId],
    );

    final total = row == null ? 0.0 : (row['total'] as num).toDouble();

    await DbService.instance.update(
      'orders',
      {'total_amount': total},
      where: 'id = ?',
      whereArgs: [orderId],
    );

    return total;
  }
}

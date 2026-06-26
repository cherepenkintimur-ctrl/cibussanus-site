import '../database/db_service.dart';
import '../models/order_item.dart';

class OrderItemRepository {
  const OrderItemRepository();

  Future<int> create(OrderItem item) async {
    final id = await DbService.instance.insert('order_items', {
      'order_id': item.orderId,
      'dish_id': item.dishId,
      'quantity': item.quantity,
      'unit_price': item.unitPrice,
      'line_total': item.lineTotal,
    });
    return id;
  }

  Future<List<OrderItem>> getByOrderId(int orderId) async {
    final rows = await DbService.instance.query(
      'SELECT id, order_id, dish_id, quantity, unit_price, line_total FROM order_items WHERE order_id = ? ORDER BY id',
      arguments: [orderId],
    );
    return rows.map(OrderItem.fromMap).toList();
  }

  Future<OrderItem?> getById(int id) async {
    final row = await DbService.instance.queryOne(
      'SELECT id, order_id, dish_id, quantity, unit_price, line_total FROM order_items WHERE id = ?',
      arguments: [id],
    );
    return row == null ? null : OrderItem.fromMap(row);
  }

  Future<int> update(OrderItem item) async {
    if (item.id == null) {
      throw ArgumentError('Order item id is required for update');
    }
    return DbService.instance.update(
      'order_items',
      {
        'order_id': item.orderId,
        'dish_id': item.dishId,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
      },
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> delete(int id) async {
    return DbService.instance.delete(
      'order_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

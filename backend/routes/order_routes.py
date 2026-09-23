from flask import Blueprint, request, jsonify
from models import db, Order, OrderItem, Product

order_bp = Blueprint('order', __name__)

PLATFORM_COMMISSION = 0.05

@order_bp.route('/place', methods=['POST'])
def place_order():
    data = request.get_json()
    buyer_id = data['buyer_id']
    address = data['address']
    items = data['items']

    total_amount = 0
    order_items_data = []

    for item in items:
        product = Product.query.get(item['product_id'])
        if not product:
            return jsonify({"error": f"Product {item['product_id']} not found"}), 404
        if product.stock < item['quantity']:
            return jsonify({"error": f"Not enough stock for {product.name}"}), 400

        item_total = product.price * item['quantity']
        total_amount += item_total
        order_items_data.append((product, item['quantity'], item_total))

    new_order = Order(buyer_id=buyer_id, total_amount=total_amount, address=address, status='Pending')
    db.session.add(new_order)
    db.session.flush()

    for product, quantity, item_total in order_items_data:
        platform_earning = item_total * PLATFORM_COMMISSION
        seller_earning = item_total - platform_earning

        order_item = OrderItem(
            order_id=new_order.id,
            product_id=product.id,
            quantity=quantity,
            price_at_purchase=product.price,
            seller_earning=seller_earning,
            platform_earning=platform_earning
        )
        db.session.add(order_item)
        product.stock -= quantity

    db.session.commit()
    return jsonify({"message": "Order placed successfully", "order_id": new_order.id, "total": total_amount}), 201


@order_bp.route('/buyer/<int:buyer_id>', methods=['GET'])
def get_buyer_orders(buyer_id):
    orders = Order.query.filter_by(buyer_id=buyer_id).all()
    result = []
    for o in orders:
        result.append({"id": o.id, "total_amount": o.total_amount, "status": o.status, "order_date": str(o.order_date)})
    return jsonify(result)


@order_bp.route('/seller/<int:seller_id>/earnings', methods=['GET'])
def seller_earnings(seller_id):
    items = db.session.query(OrderItem).join(Product).filter(Product.seller_id == seller_id).all()
    total_earning = sum(i.seller_earning for i in items)
    total_orders = len(items)
    return jsonify({"seller_id": seller_id, "total_earning": total_earning, "total_orders": total_orders})


@order_bp.route('/admin/earnings', methods=['GET'])
def admin_earnings():
    items = db.session.query(OrderItem).all()
    total_platform_earning = sum(i.platform_earning for i in items)
    return jsonify({"total_platform_earning": total_platform_earning, "total_orders": len(items)})
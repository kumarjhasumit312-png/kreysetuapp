from flask import Blueprint, request, jsonify
from datetime import datetime
from models import db, Product, Order, OrderItem
from routes.voucher_routes import Voucher

order_bp = Blueprint('order', __name__)

PLATFORM_COMMISSION = 0.05


@order_bp.route('/place', methods=['POST'])
def place_order():
    data = request.get_json()
    buyer_id = data['buyer_id']
    address = data['address']
    items = data['items']
    voucher_code = (data.get('voucher_code') or '').strip().upper()

    subtotal = 0
    order_items_data = []

    for item in items:
        product = Product.query.get(item['product_id'])

        if not product:
            return jsonify({
                "error": f"Product {item['product_id']} not found"
            }), 404

        if product.stock < item['quantity']:
            return jsonify({
                "error": f"Not enough stock for {product.name}"
            }), 400

        item_total = product.price * item['quantity']
        subtotal += item_total

        order_items_data.append(
            (product, item['quantity'], item_total)
        )

    # ---------- Voucher / discount code ----------
    discount = 0

    if voucher_code:
        voucher = Voucher.query.filter_by(
            code=voucher_code,
            is_active=True
        ).first()

        if not voucher:
            return jsonify({
                "error": "Invalid voucher code"
            }), 400

        if voucher.expiry_date < datetime.utcnow().date().isoformat():
            return jsonify({
                "error": "Voucher has expired"
            }), 400

        if voucher.discount_type == 'percent':
            discount = subtotal * (voucher.discount_value / 100)
        else:
            discount = voucher.discount_value

        discount = min(discount, subtotal)

    total_amount = subtotal - discount

    new_order = Order(
        buyer_id=buyer_id,
        total_amount=total_amount,
        address=address,
        status='Pending'
    )

    db.session.add(new_order)
    db.session.flush()

    for product, quantity, item_total in order_items_data:
        share = (item_total / subtotal) if subtotal > 0 else 0
        item_final = item_total - (discount * share)

        platform_earning = item_final * PLATFORM_COMMISSION
        seller_earning = item_final - platform_earning

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

    return jsonify({
        "message": "Order placed successfully",
        "order_id": new_order.id,
        "subtotal": subtotal,
        "discount": discount,
        "total": total_amount
    }), 201


@order_bp.route('/buyer/<int:buyer_id>', methods=['GET'])
def get_buyer_orders(buyer_id):
    orders = Order.query.filter_by(buyer_id=buyer_id).all()

    result = []

    for order in orders:
        result.append({
            "id": order.id,
            "total_amount": order.total_amount,
            "status": order.status,
            "order_date": str(order.order_date),
            "address": order.address
        })

    return jsonify(result)


@order_bp.route('/<int:order_id>', methods=['GET'])
def get_order_details(order_id):
    order = Order.query.get(order_id)

    if not order:
        return jsonify({"error": "Order not found"}), 404

    items = OrderItem.query.filter_by(order_id=order_id).all()

    item_list = []

    for item in items:
        product = Product.query.get(item.product_id)

        item_list.append({
            "product_id": item.product_id,
            "product_name": product.name if product else "Product",
            "quantity": item.quantity,
            "price": float(item.price_at_purchase),
            "total_price": float(
                item.price_at_purchase * item.quantity
            ),
            "seller_earning": float(item.seller_earning),
            "platform_earning": float(item.platform_earning)
        })

    return jsonify({
        "id": order.id,
        "buyer_id": order.buyer_id,
        "address": order.address,
        "status": order.status,
        "order_date": str(order.order_date),
        "total_amount": float(order.total_amount),
        "items": item_list
    })


@order_bp.route('/seller/<int:seller_id>/orders', methods=['GET'])
def get_seller_orders(seller_id):
    order_ids = (
        db.session.query(OrderItem.order_id)
        .join(Product)
        .filter(Product.seller_id == seller_id)
        .distinct()
    )

    orders = (
        Order.query
        .filter(Order.id.in_(order_ids))
        .order_by(Order.order_date.desc())
        .all()
    )

    result = []

    for order in orders:
        result.append({
            "id": order.id,
            "buyer_id": order.buyer_id,
            "address": order.address,
            "total_amount": float(order.total_amount),
            "status": order.status,
            "order_date": str(order.order_date)
        })

    return jsonify(result)


@order_bp.route('/seller/<int:seller_id>/earnings', methods=['GET'])
def seller_earnings(seller_id):
    items = (
        db.session.query(OrderItem)
        .join(Product)
        .filter(Product.seller_id == seller_id)
        .all()
    )

    total_earning = sum(item.seller_earning for item in items)
    total_orders = len(items)

    return jsonify({
        "seller_id": seller_id,
        "total_earning": float(total_earning),
        "total_orders": total_orders
    })


@order_bp.route('/admin/earnings', methods=['GET'])
def admin_earnings():
    items = db.session.query(OrderItem).all()

    total_platform_earning = sum(
        item.platform_earning for item in items
    )

    return jsonify({
        "total_platform_earning": float(total_platform_earning),
        "total_orders": len(items)
    })


@order_bp.route('/<int:order_id>/status', methods=['PUT'])
def update_order_status(order_id):
    data = request.get_json()
    new_status = data.get('status')

    valid_statuses = ['Pending', 'Shipped', 'Delivered']

    if new_status not in valid_statuses:
        return jsonify({"error": "Invalid status"}), 400

    order = Order.query.get(order_id)

    if not order:
        return jsonify({"error": "Order not found"}), 404

    order.status = new_status
    db.session.commit()

    return jsonify({
        "message": "Status updated",
        "status": new_status
    }), 200


@order_bp.route('/<int:order_id>/cancel', methods=['POST'])
def cancel_order(order_id):
    order = Order.query.get(order_id)

    if not order:
        return jsonify({"error": "Order not found"}), 404

    if order.status in ['Shipped', 'Delivered']:
        return jsonify({
            "error": "Shipped or delivered order cannot be cancelled"
        }), 400

    order.status = 'Cancelled'
    db.session.commit()

    return jsonify({
        "message": "Order cancelled successfully",
        "status": order.status
    }), 200
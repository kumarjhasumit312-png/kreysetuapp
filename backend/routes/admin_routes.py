from flask import Blueprint, jsonify
from models import db, User, Product, Order, OrderItem

admin_bp = Blueprint('admin', __name__)


@admin_bp.route('/users', methods=['GET'])
def get_users():
    users = User.query.order_by(User.id.desc()).all()
    return jsonify([
        {
            'id': u.id,
            'name': u.name,
            'email': u.email,
            'role': u.role,
            'created_at': u.created_at.isoformat() if u.created_at else None,
        }
        for u in users
    ])


@admin_bp.route('/products', methods=['GET'])
def get_products():
    products = Product.query.order_by(Product.id.desc()).all()
    return jsonify([p.to_dict() for p in products])


@admin_bp.route('/products/<int:product_id>', methods=['DELETE'])
def delete_product(product_id):
    product = Product.query.get(product_id)
    if not product:
        return jsonify({'error': 'Product not found'}), 404

    if OrderItem.query.filter_by(product_id=product_id).first():
        return jsonify({'error': 'Is product ke orders ban chuke hain, delete nahi ho sakta'}), 400

    db.session.delete(product)
    db.session.commit()
    return jsonify({'message': 'Product deleted'}), 200


@admin_bp.route('/orders', methods=['GET'])
def get_orders():
    orders = Order.query.order_by(Order.id.desc()).all()
    return jsonify([
        {
            'id': o.id,
            'buyer_id': o.buyer_id,
            'total_amount': o.total_amount,
            'status': o.status,
            'address': o.address,
            'order_date': o.order_date.isoformat() if o.order_date else None,
        }
        for o in orders
    ])
from sqlalchemy import func


@admin_bp.route('/earnings', methods=['GET'])
def get_earnings():
    rows = (
        db.session.query(OrderItem, Order)
        .join(Order, Order.id == OrderItem.order_id)
        .filter(func.lower(Order.status) != 'cancelled')
        .all()
    )

    total_sales = 0.0
    platform_total = 0.0
    seller_total = 0.0
    platform_delivered = 0.0
    platform_pending = 0.0
    per_order = {}

    for item, order in rows:
        sale = item.price_at_purchase * item.quantity
        total_sales += sale
        platform_total += item.platform_earning
        seller_total += item.seller_earning

        if (order.status or '').lower() == 'delivered':
            platform_delivered += item.platform_earning
        else:
            platform_pending += item.platform_earning

        o = per_order.setdefault(order.id, {
            'id': order.id,
            'status': order.status,
            'sale': 0.0,
            'platform': 0.0,
        })
        o['sale'] += sale
        o['platform'] += item.platform_earning

    recent = sorted(per_order.values(), key=lambda x: x['id'], reverse=True)

    return jsonify({
        'total_sales': round(total_sales, 2),
        'platform_earning': round(platform_total, 2),
        'seller_earning': round(seller_total, 2),
        'platform_delivered': round(platform_delivered, 2),
        'platform_pending': round(platform_pending, 2),
        'orders_count': len(per_order),
        'recent': recent[:50],
    })
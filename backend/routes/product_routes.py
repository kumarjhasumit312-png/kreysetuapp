from flask import Blueprint, request, jsonify
from models import db, Product, OrderItem


product_bp = Blueprint('product', __name__)


VALID_TYPES = ('new', 'used')
VALID_CONDITIONS = ('Like New', 'Good', 'Fair')


@product_bp.route('/', methods=['GET'])
def get_all_products():
    listing_type = request.args.get('type')

    query = Product.query

    if listing_type in VALID_TYPES:
        query = query.filter_by(listing_type=listing_type)

    products = query.order_by(Product.created_at.desc()).all()

    return jsonify([p.to_dict() for p in products])


@product_bp.route('/add', methods=['POST'])
def add_product():
    data = request.get_json()

    listing_type = data.get('listing_type', 'new')

    if listing_type not in VALID_TYPES:
        return jsonify({
            'error': "listing_type must be 'new' or 'used'"
        }), 400

    item_condition = data.get('item_condition')

    if listing_type == 'used':
        if item_condition not in VALID_CONDITIONS:
            return jsonify({
                'error': 'item_condition must be one of: Like New, Good, Fair'
            }), 400
    else:
        item_condition = None

    stock = data.get('stock')

    if stock is None:
        stock = 1 if listing_type == 'used' else 0

    new_product = Product(
        seller_id=data['seller_id'],
        name=data['name'],
        description=data.get('description', ''),
        price=data['price'],
        stock=stock,
        category=data.get('category', ''),
        image_url=data.get('image_url', ''),
        expiry_date=data.get('expiry_date'),
        discount_price=data.get('discount_price'),
        listing_type=listing_type,
        item_condition=item_condition,
        city=(data.get('city') or '').strip() or None
    )

    db.session.add(new_product)
    db.session.commit()

    return jsonify({
        'message': 'Product added',
        'product': new_product.to_dict()
    }), 201


@product_bp.route('/seller/<int:seller_id>', methods=['GET'])
def get_seller_products(seller_id):
    products = Product.query.filter_by(seller_id=seller_id).all()

    return jsonify([
        {
            'id': p.id,
            'seller_id': p.seller_id,
            'name': p.name,
            'description': p.description,
            'price': float(p.price),
            'stock': p.stock,
            'category': p.category,
            'image_url': p.image_url,
            'listing_type': p.listing_type,
            'item_condition': p.item_condition,
            'city': p.city,
        }
        for p in products
    ])


@product_bp.route('/<int:product_id>', methods=['DELETE'])
def delete_product(product_id):
    product = Product.query.get(product_id)

    if not product:
        return jsonify({'error': 'Product not found'}), 404

    try:
        OrderItem.query.filter_by(product_id=product_id).delete()

        db.session.delete(product)
        db.session.commit()

        return jsonify({'message': 'Product deleted'}), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500
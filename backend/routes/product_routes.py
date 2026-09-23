from flask import Blueprint, request, jsonify
from models import db, Product

product_bp = Blueprint('product', __name__)

@product_bp.route('/', methods=['GET'])
def get_all_products():
    products = Product.query.all()
    return jsonify([p.to_dict() for p in products])


@product_bp.route('/add', methods=['POST'])
def add_product():
    data = request.get_json()
    new_product = Product(
        seller_id=data['seller_id'],
        name=data['name'],
        description=data.get('description', ''),
        price=data['price'],
        stock=data['stock'],
        category=data.get('category', ''),
        image_url=data.get('image_url', '')
    )
    db.session.add(new_product)
    db.session.commit()
    return jsonify({"message": "Product added", "product": new_product.to_dict()}), 201
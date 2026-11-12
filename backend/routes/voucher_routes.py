from flask import Blueprint, request, jsonify
from datetime import datetime
from models import db, Product

voucher_bp = Blueprint('voucher', __name__)


# ---------------- DISCOUNT CODE MODEL (cart ke liye) ----------------
class Voucher(db.Model):
    __tablename__ = 'discount_codes'

    id = db.Column(db.Integer, primary_key=True)
    code = db.Column(db.String(50), unique=True, nullable=False)
    discount_type = db.Column(db.String(10), nullable=False)  # 'flat' ya 'percent'
    discount_value = db.Column(db.Float, nullable=False)
    expiry_date = db.Column(db.String(10), nullable=False)    # YYYY-MM-DD
    is_active = db.Column(db.Boolean, default=True)

    def to_dict(self):
        return {
            "id": self.id,
            "code": self.code,
            "discount_type": self.discount_type,
            "discount_value": self.discount_value,
            "expiry_date": self.expiry_date,
        }


# ---------------- VOUCHER LISTING (product ki tarah bechna) ----------------
@voucher_bp.route('/create', methods=['POST'])
def create_voucher():
    data = request.get_json()

    expiry_str = data.get('expiry_date')
    if not expiry_str:
        return jsonify({"error": "expiry_date is required (YYYY-MM-DD)"}), 400

    try:
        expiry = datetime.strptime(expiry_str, '%Y-%m-%d').date()
    except ValueError:
        return jsonify({"error": "expiry_date must be in YYYY-MM-DD format"}), 400

    if expiry <= datetime.utcnow().date():
        return jsonify({"error": "Expiry date must be in the future"}), 400

    original_value = data.get('original_value')
    selling_price = data.get('selling_price')

    if not original_value or not selling_price:
        return jsonify({"error": "original_value and selling_price are required"}), 400

    if selling_price >= original_value:
        return jsonify({"error": "Selling price should be less than original value"}), 400

    voucher = Product(
        seller_id=data['seller_id'],
        name=data['title'],
        description=data.get('description', ''),
        price=original_value,
        discount_price=selling_price,
        stock=1,
        category='Voucher',
        image_url='',
        expiry_date=expiry_str
    )
    db.session.add(voucher)
    db.session.commit()

    return jsonify({"message": "Voucher listed successfully", "voucher": voucher.to_dict()}), 201


@voucher_bp.route('/', methods=['GET'])
def get_available_vouchers():
    today_str = datetime.utcnow().date().isoformat()

    vouchers = Product.query.filter(
        Product.category == 'Voucher',
        Product.stock > 0,
        Product.expiry_date > today_str
    ).order_by(Product.expiry_date.asc()).all()

    return jsonify([v.to_dict() for v in vouchers]), 200


@voucher_bp.route('/seller/<int:seller_id>', methods=['GET'])
def get_seller_vouchers(seller_id):
    vouchers = Product.query.filter_by(seller_id=seller_id, category='Voucher').all()
    return jsonify([v.to_dict() for v in vouchers]), 200


# ---------------- DISCOUNT CODE (cart mein daalne wala) ----------------
@voucher_bp.route('/generate', methods=['POST'])
def generate_code():
    data = request.get_json() or {}

    code = (data.get('code') or '').strip().upper()
    dtype = data.get('discount_type')
    value = data.get('discount_value')
    expiry_str = data.get('expiry_date')

    if not code or dtype not in ('flat', 'percent') or not value or not expiry_str:
        return jsonify({"error": "code, discount_type (flat/percent), discount_value, expiry_date are required"}), 400

    try:
        expiry = datetime.strptime(expiry_str, '%Y-%m-%d').date()
    except ValueError:
        return jsonify({"error": "expiry_date must be YYYY-MM-DD"}), 400

    if expiry <= datetime.utcnow().date():
        return jsonify({"error": "Expiry date must be in the future"}), 400

    if Voucher.query.filter_by(code=code).first():
        return jsonify({"error": "Code already exists"}), 400

    v = Voucher(code=code, discount_type=dtype, discount_value=float(value), expiry_date=expiry_str)
    db.session.add(v)
    db.session.commit()

    return jsonify({"message": "Code generated", "voucher": v.to_dict()}), 201


@voucher_bp.route('/validate', methods=['POST'])
def validate_code():
    data = request.get_json() or {}
    code = (data.get('code') or '').strip().upper()

    v = Voucher.query.filter_by(code=code, is_active=True).first()
    if not v:
        return jsonify({"error": "Invalid voucher code"}), 404

    if v.expiry_date < datetime.utcnow().date().isoformat():
        return jsonify({"error": "Voucher has expired"}), 400

    return jsonify({"voucher": v.to_dict()}), 200
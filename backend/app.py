import importlib.util
import os

from flask import Flask, jsonify
from flask_cors import CORS

from config import Config
from models import db


def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    # Photo upload limit: 5 MB
    app.config['MAX_CONTENT_LENGTH'] = 5 * 1024 * 1024

    # '/api/upload' aur '/api/upload/' dono chalein (redirect ka jhanjhat nahi)
    app.url_map.strict_slashes = False

    db.init_app(app)

    CORS(
        app,
        resources={r"/api/*": {
            "origins": "*",
            "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
            "allow_headers": ["Content-Type", "Authorization"],
        }}
    )

    # Blueprints import
    from routes.auth_routes import auth_bp
    from routes.product_routes import product_bp
    from routes.order_routes import order_bp
    from routes.voucher_routes import voucher_bp
    from routes.admin_routes import admin_bp
    from routes.upload_routes import upload_bp

    # Blueprints register
    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(product_bp, url_prefix='/api/products')
    app.register_blueprint(order_bp, url_prefix='/api/orders')
    app.register_blueprint(voucher_bp, url_prefix='/api/vouchers')
    app.register_blueprint(admin_bp, url_prefix='/api/admin')
    app.register_blueprint(upload_bp, url_prefix='/api/upload')

    # Optional: order cancel / profile update wali extra_routes.py
    # (sirf tab register hoga jab file maujood ho, warna app crash nahi hogi)
    if importlib.util.find_spec('routes.extra_routes') is not None:
        from routes.extra_routes import extra_bp
        app.register_blueprint(extra_bp, url_prefix='/api')

    # ---------- JSON error responses ----------
    # Flutter har response ko jsonDecode karta hai, isliye HTML error page
    # ki jagah hamesha JSON error milna chahiye.
    @app.errorhandler(404)
    def not_found(_):
        return jsonify({"error": "Route not found"}), 404

    @app.errorhandler(405)
    def method_not_allowed(_):
        return jsonify({"error": "Method not allowed"}), 405

    @app.errorhandler(413)
    def too_large(_):
        return jsonify({"error": "File bahut badi hai (max 5 MB)"}), 413

    @app.errorhandler(500)
    def server_error(_):
        return jsonify({"error": "Internal server error"}), 500

    @app.route('/api/health')
    def health():
        return jsonify({"status": "ok"})

    with app.app_context():
        db.create_all()

    return app


if __name__ == '__main__':
    app = create_app()

    # Startup pe saare routes print honge (debug ke liye)
    if os.environ.get('WERKZEUG_RUN_MAIN') == 'true':
        print('\n--- REGISTERED ROUTES ---')
        for rule in sorted(app.url_map.iter_rules(), key=lambda r: r.rule):
            methods = ','.join(
                sorted(m for m in rule.methods if m not in ('HEAD', 'OPTIONS'))
            )
            print(f'{methods:<12} {rule.rule}')
        print('-------------------------\n')

    # host='0.0.0.0' se phone bhi same Wi-Fi pe connect kar sakega
    app.run(host='0.0.0.0', port=5000, debug=True)
    
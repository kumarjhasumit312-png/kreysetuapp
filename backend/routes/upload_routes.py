import os
import uuid
from flask import Blueprint, request, jsonify, send_from_directory

upload_bp = Blueprint('upload', __name__)

ALLOWED = {'png', 'jpg', 'jpeg', 'webp'}
UPLOAD_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'uploads'
)


@upload_bp.route('/image', methods=['POST'])
def upload_image():
    file = request.files.get('image')
    if not file or not file.filename:
        return jsonify({'error': 'Photo nahi mili'}), 400

    ext = file.filename.rsplit('.', 1)[-1].lower() if '.' in file.filename else 'jpg'
    if ext not in ALLOWED:
        return jsonify({'error': 'Sirf png, jpg, jpeg, webp allowed hai'}), 400

    os.makedirs(UPLOAD_DIR, exist_ok=True)
    name = f"{uuid.uuid4().hex}.{ext}"
    file.save(os.path.join(UPLOAD_DIR, name))

    return jsonify({'image_url': f'/api/upload/files/{name}'}), 201


@upload_bp.route('/files/<path:filename>', methods=['GET'])
def serve_file(filename):
    return send_from_directory(UPLOAD_DIR, filename)
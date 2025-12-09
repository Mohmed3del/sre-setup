import json
import os
import platform
import sys
from datetime import datetime
from flask import Flask, jsonify

app = Flask(__name__)

def get_env(key, default=None):
    return os.getenv(key, default)

@app.route('/')
def home():
    return jsonify({
        'message': 'Welcome to Python Service',
        'endpoints': [
            '/health',
            '/ready',
            '/api/users',
            '/api/items',
            '/api/env'
        ],
        'service': 'python-service'
    })

@app.route('/health')
def health():
    return jsonify({
        'status': 'UP',
        'service': 'python-service',
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/ready')
def ready():
    return jsonify({
        'status': 'READY',
        'ready': True
    })

@app.route('/api/users')
def get_users():
    users = [
        {'id': 1, 'name': 'Alice', 'email': 'alice@example.com'},
        {'id': 2, 'name': 'Bob', 'email': 'bob@example.com'},
        {'id': 3, 'name': 'Charlie', 'email': 'charlie@example.com'}
    ]
    return jsonify({'users': users})

@app.route('/api/items')
def get_items():
    items = [
        {'id': 1, 'name': 'Python Book', 'price': 49.99},
        {'id': 2, 'name': 'Python Mug', 'price': 19.99},
        {'id': 3, 'name': 'Python Sticker', 'price': 4.99}
    ]
    return jsonify({'items': items})

@app.route('/api/env')
def get_env_info():
    return jsonify({
        'python_version': sys.version,
        'platform': platform.platform(),
        'environment': get_env('ENV', 'development'),
        'hostname': get_env('HOSTNAME', 'unknown'),
        'memory_info': {
            'max_rss': os.sysconf('SC_PAGE_SIZE') * os.sysconf('SC_PHYS_PAGES') / (1024 ** 3)
        }
    })

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Not Found'}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({'error': 'Internal Server Error'}), 500

if __name__ == '__main__':
    port = int(get_env('PORT', 8080))
    debug = get_env('ENV', 'development') == 'development'
    app.run(host='0.0.0.0', port=port, debug=debug)
import os
from flask import Flask, jsonify, request
import psycopg2
import bcrypt
import jwt
import datetime
from functools import wraps
from dotenv import load_dotenv

# Ortam değişkenlerini yükle
load_dotenv()

app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv("SECRET_KEY", "default_secret_key")

# PostgreSQL bağlantı bilgilerini .env'den al
DB_URL = os.getenv("DATABASE_URL")

def get_db_connection():
    conn = psycopg2.connect(DB_URL, sslmode='require')
    return conn

def init_db():
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Users tablosu
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS users (
        user_id SERIAL PRIMARY KEY,          -- Kullanıcı ID
        name VARCHAR(100) NOT NULL,          -- İsim
        email VARCHAR(100) UNIQUE NOT NULL,  -- E-mail
        profile_photo TEXT,                  -- Profil Fotoğrafı (URL veya dosya yolu)
        password_hash TEXT NOT NULL,         -- Şifre (hashlenmiş)
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Oluşturulma zamanı
    )
    ''')
    
    # Categories tablosu
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS categories (
        category_id SERIAL PRIMARY KEY,      -- Kategori ID
        category_name VARCHAR(100) NOT NULL  -- Kategori Adı (ör. Cilt bakımı, Saç bakımı)
    )
    ''')
    
    # Products tablosu
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS products (
        product_id SERIAL PRIMARY KEY,       -- Ürün ID
        name VARCHAR(100) NOT NULL,          -- Ürün Adı
        brand VARCHAR(100),                  -- Marka
        category_id INTEGER REFERENCES categories(category_id), -- Kategori ile ilişki
        description TEXT,                    -- Ürün Bilgisi
        average_rating DECIMAL(2,1),         -- Ortalama Puan
        product_photo TEXT                   -- Ürün Fotoğrafı (URL veya dosya yolu)
    )
    ''')
    
    # Reviews tablosu
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS reviews (
        review_id SERIAL PRIMARY KEY,          -- İnceleme ID
        product_id INTEGER REFERENCES products(product_id), -- Ürün ID ile ilişki
        user_id INTEGER REFERENCES users(user_id), -- Kullanıcı ID ile ilişki
        review_text TEXT,                      -- İnceleme Metni
        rating INTEGER CHECK (rating BETWEEN 1 AND 5), -- Kullanıcı Yıldız Puanı (1-5 arası)
        review_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- İnceleme Tarihi
        likes_count INTEGER DEFAULT 0,         -- Beğeni Sayısı
        replies TEXT                           -- Yanıtlar (isteğe bağlı metin listesi)
    )
    ''')
    
    # Favorites tablosu
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS favorites (
        favorite_id SERIAL PRIMARY KEY,      -- Favori ID
        user_id INTEGER REFERENCES users(user_id), -- Favorileyen kullanıcı
        product_id INTEGER REFERENCES products(product_id), -- Favorilenen ürün
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Favorileme zamanı
    )
    ''')
    
    conn.commit()
    cursor.close()
    conn.close()
    print("Veritabanı tabloları başarıyla oluşturuldu.")

def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get('x-access-token')
        if not token:
            return jsonify({'message': 'Token eksik!'}), 401
        try:
            data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=["HS256"])
            current_user = data['user_id']
        except:
            return jsonify({'message': 'Geçersiz token!'}), 401
        return f(current_user, *args, **kwargs)
    return decorated

@app.route('/')
def home():
    return "Hoş geldiniz! Flask API'niz çalışıyor."

@app.route('/register', methods=['POST'])
def register_user():
    data = request.get_json()
    name = data.get('name')
    email = data.get('email')
    password = data.get('password')
    profile_photo = data.get('profile_photo')  # Yeni ekledik

    hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            "INSERT INTO users (name, email, password_hash, profile_photo) VALUES (%s, %s, %s, %s) RETURNING user_id",
            (name, email, hashed_password, profile_photo)
        )
        user_id = cursor.fetchone()[0]
        conn.commit()
        return jsonify({"message": "Kullanıcı başarıyla kaydedildi.", "user_id": user_id}), 201
    except psycopg2.IntegrityError:
        conn.rollback()
        return jsonify({"error": "Bu email ile kayıtlı bir kullanıcı zaten var."}), 400
    finally:
        cursor.close()
        conn.close()

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')

    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT user_id, password_hash FROM users WHERE email = %s", (email,))
    user = cursor.fetchone()
    cursor.close()
    conn.close()

    if user and bcrypt.checkpw(password.encode('utf-8'), user[1].encode('utf-8')):
        token = jwt.encode({
            'user_id': user[0],
            'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=24)
        }, app.config['SECRET_KEY'], algorithm='HS256')
        return jsonify({'token': token})
    else:
        return jsonify({'message': 'Geçersiz email veya şifre!'}), 401

@app.route('/users', methods=['GET'])
@token_required
def get_users(current_user):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT user_id, name, email, profile_photo, created_at FROM users")
    users_data = cursor.fetchall()
    cursor.close()
    conn.close()
    
    # Veriyi daha anlaşılır hale getirmek için kısa sözlüklere dönüştürme
    users = []
    for user in users_data:
        users.append({
            'user_id': user[0],
            'name': user[1],
            'email': user[2],
            'profile_photo': user[3],
            'created_at': user[4]
        })
    
    return jsonify(users)

@app.route('/product', methods=['POST'])
@token_required
def add_product(current_user):
    data = request.get_json()
    name = data.get('name')  # product_name yerine name kullandık
    brand = data.get('brand')
    category_id = data.get('category_id')
    description = data.get('description')
    average_rating = data.get('average_rating')
    product_photo = data.get('product_photo')

    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO products (name, brand, category_id, description, average_rating, product_photo) VALUES (%s, %s, %s, %s, %s, %s) RETURNING product_id",
        (name, brand, category_id, description, average_rating, product_photo)
    )
    product_id = cursor.fetchone()[0]
    conn.commit()
    cursor.close()
    conn.close()
    return jsonify({"message": "Ürün başarıyla eklendi.", "product_id": product_id}), 201

@app.route('/products', methods=['GET'])
@token_required
def get_products(current_user):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT product_id, name, brand, category_id, description, average_rating, product_photo FROM products")
    products_data = cursor.fetchall()
    cursor.close()
    conn.close()
    
    # Veriyi daha anlaşılır hale getirmek için kısa sözlüklere dönüştürme
    products = []
    for product in products_data:
        products.append({
            'product_id': product[0],
            'name': product[1],
            'brand': product[2],
            'category_id': product[3],
            'description': product[4],
            'average_rating': float(product[5]) if product[5] else None,
            'product_photo': product[6]
        })
    
    return jsonify(products)

@app.route('/favorite', methods=['POST'])
@token_required
def add_favorite(current_user):
    data = request.get_json()
    product_id = data.get('product_id')

    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            "INSERT INTO favorites (user_id, product_id) VALUES (%s, %s) RETURNING favorite_id",
            (current_user, product_id)
        )
        favorite_id = cursor.fetchone()[0]
        conn.commit()
        return jsonify({"message": "Favori başarıyla eklendi.", "favorite_id": favorite_id}), 201
    except psycopg2.IntegrityError:
        conn.rollback()
        return jsonify({"error": "Bu ürün zaten favorilerinizde bulunuyor."}), 400
    finally:
        cursor.close()
        conn.close()

@app.route('/favorites', methods=['GET'])
@token_required
def get_user_favorites(current_user):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT f.favorite_id, p.product_id, p.name, p.brand, p.description, p.average_rating, p.product_photo, f.created_at
        FROM favorites f
        JOIN products p ON f.product_id = p.product_id
        WHERE f.user_id = %s
    """, (current_user,))
    favorites_data = cursor.fetchall()
    cursor.close()
    conn.close()
    
    # Veriyi daha anlaşılır hale getirmek için kısa sözlüklere dönüştürme
    favorites = []
    for fav in favorites_data:
        favorites.append({
            'favorite_id': fav[0],
            'product_id': fav[1],
            'name': fav[2],
            'brand': fav[3],
            'description': fav[4],
            'average_rating': float(fav[5]) if fav[5] else None,
            'product_photo': fav[6],
            'favorited_at': fav[7]
        })
    
    return jsonify(favorites)

@app.route('/category', methods=['POST'])
@token_required
def add_category(current_user):
    data = request.get_json()
    category_name = data.get('category_name')

    if not category_name:
        return jsonify({"error": "Kategori adı gereklidir."}), 400

    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            "INSERT INTO categories (category_name) VALUES (%s) RETURNING category_id",
            (category_name,)
        )
        category_id = cursor.fetchone()[0]
        conn.commit()
        return jsonify({"message": "Kategori başarıyla eklendi.", "category_id": category_id}), 201
    except psycopg2.IntegrityError:
        conn.rollback()
        return jsonify({"error": "Bu isimde bir kategori zaten var."}), 400
    finally:
        cursor.close()
        conn.close()

@app.route('/categories', methods=['GET'])
@token_required
def get_categories(current_user):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT category_id, category_name FROM categories")
    categories_data = cursor.fetchall()
    cursor.close()
    conn.close()
    
    # Veriyi daha anlaşılır hale getirmek için kısa sözlüklere dönüştürme
    categories = []
    for category in categories_data:
        categories.append({
            'category_id': category[0],
            'category_name': category[1]
        })
    
    return jsonify(categories)

@app.route('/review', methods=['POST'])
@token_required
def add_review(current_user):
    data = request.get_json()
    product_id = data.get('product_id')
    review_text = data.get('review_text')
    rating = data.get('rating')
    
    if not product_id or not rating or not isinstance(rating, int) or rating < 1 or rating > 5:
        return jsonify({"error": "Ürün ID ve 1-5 arası geçerli bir puan gereklidir."}), 400

    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # İnceleme ekle
        cursor.execute(
            "INSERT INTO reviews (product_id, user_id, review_text, rating) VALUES (%s, %s, %s, %s) RETURNING review_id",
            (product_id, current_user, review_text, rating)
        )
        review_id = cursor.fetchone()[0]
        
        # Ürünün ortalama puanını güncelle
        cursor.execute(
            "UPDATE products SET average_rating = (SELECT AVG(rating) FROM reviews WHERE product_id = %s) WHERE product_id = %s",
            (product_id, product_id)
        )
        
        conn.commit()
        return jsonify({"message": "İnceleme başarıyla eklendi.", "review_id": review_id}), 201
    except psycopg2.Error as e:
        conn.rollback()
        return jsonify({"error": f"İnceleme eklenirken bir hata oluştu: {str(e)}"}), 400
    finally:
        cursor.close()
        conn.close()

@app.route('/reviews/<int:product_id>', methods=['GET'])
@token_required
def get_product_reviews(current_user, product_id):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT r.review_id, r.review_text, r.rating, r.review_date, r.likes_count, r.replies, 
               u.user_id, u.name, u.profile_photo
        FROM reviews r
        JOIN users u ON r.user_id = u.user_id
        WHERE r.product_id = %s
        ORDER BY r.review_date DESC
    """, (product_id,))
    reviews_data = cursor.fetchall()
    cursor.close()
    conn.close()
    
    # Veriyi daha anlaşılır hale getirmek için kısa sözlüklere dönüştürme
    reviews = []
    for review in reviews_data:
        reviews.append({
            'review_id': review[0],
            'review_text': review[1],
            'rating': review[2],
            'review_date': review[3],
            'likes_count': review[4],
            'replies': review[5],
            'user': {
                'user_id': review[6],
                'name': review[7],
                'profile_photo': review[8]
            }
        })
    
    return jsonify(reviews)

if __name__ == '__main__':
    init_db()  # Uygulamayı başlatmadan önce veritabanını hazırla
    print("Flask uygulaması başarıyla başlatıldı ve http://127.0.0.1:5000 üzerinde çalışıyor.")
    app.run(debug=True, host='127.0.0.1', port=5000)
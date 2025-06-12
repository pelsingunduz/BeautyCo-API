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
    
    # Örnek kategoriler ekle (eğer yoksa)
    cursor.execute("SELECT COUNT(*) FROM categories")
    if cursor.fetchone()[0] == 0:
        cursor.execute("""
            INSERT INTO categories (category_name) VALUES 
            ('Makyaj'), ('Cilt Bakımı'), ('Saç'), ('Parfüm')
        """)
        conn.commit()
        print("Örnek kategoriler eklendi.")
    
    # Örnek ürünler ekle (eğer yoksa)
    cursor.execute("SELECT COUNT(*) FROM products")
    if cursor.fetchone()[0] == 0:
        cursor.execute("""
            INSERT INTO products (name, brand, category_id, description, average_rating, product_photo) VALUES 
            ('Hydra Beauty Serum', 'Chanel', 2, 'Yoğun nemlendirici serum', 4.5, 'https://example.com/chanel-serum.jpg'),
            ('Rouge Allure Lipstick', 'Chanel', 1, 'Mat ruj', 4.2, 'https://example.com/chanel-lipstick.jpg'),
            ('The Ordinary Retinol 0.2%', 'The Ordinary', 2, 'Anti-aging serum', 4.3, 'https://example.com/ordinary-retinol.jpg'),
            ('Gloss Bomb Universal', 'Fenty Beauty', 1, 'Parlak ruj', 4.1, 'https://example.com/fenty-gloss.jpg'),
            ('Kérastase Nutritive Shampoo', 'Kérastase', 3, 'Besleyici şampuan', 4.4, 'https://example.com/kerastase-shampoo.jpg'),
            ('Shalimar Parfum', 'Guerlain', 4, 'Klasik kadın parfümü', 4.6, 'https://example.com/shalimar.jpg')
        """)
        conn.commit()
        print("Örnek ürünler eklendi.")
    
    cursor.close()
    conn.close()
    print("Veritabanı tabloları başarıyla oluşturuldu ve örnek veriler eklendi.")

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
    profile_photo = data.get('profile_photo')
    
    # Basit validasyon
    if not all([name, email, password]):
        return jsonify({"error": "İsim, email ve şifre gereklidir."}), 400

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
    except Exception as e:
        conn.rollback()
        return jsonify({"error": f"Kayıt işlemi sırasında hata: {str(e)}"}), 500
    finally:
        cursor.close()
        conn.close()

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')
    
    if not all([email, password]):
        return jsonify({'message': 'Email ve şifre gereklidir!'}), 400

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
        return jsonify({'token': token, 'message': 'Giriş başarılı!'}), 200
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
            'id': user[0],  # Flutter tarafında kullanılan key ismi
            'name': user[1],
            'email': user[2],
            'profile_photo': user[3],
            'created_at': user[4].isoformat() if user[4] else None
        })
    
    return jsonify(users)

@app.route('/product', methods=['POST'])
@token_required
def add_product(current_user):
    data = request.get_json()
    name = data.get('name')
    brand = data.get('brand')
    category_id = data.get('category_id')
    description = data.get('description')
    average_rating = data.get('average_rating')
    product_photo = data.get('product_photo')

    # Gerekli alanların kontrolü
    if not name:
        return jsonify({"error": "Ürün adı gereklidir."}), 400

    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            "INSERT INTO products (name, brand, category_id, description, average_rating, product_photo) VALUES (%s, %s, %s, %s, %s, %s) RETURNING product_id",
            (name, brand, category_id, description, average_rating, product_photo)
        )
        product_id = cursor.fetchone()[0]
        conn.commit()
        return jsonify({"message": "Ürün başarıyla eklendi.", "product_id": product_id}), 201
    except psycopg2.Error as e:
        conn.rollback()
        return jsonify({"error": f"Ürün eklenirken bir hata oluştu: {str(e)}"}), 400
    finally:
        cursor.close()
        conn.close()

@app.route('/products', methods=['GET'])
@token_required
def get_products(current_user):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT product_id, name, brand, category_id, description, average_rating, product_photo FROM products")
    products_data = cursor.fetchall()
    cursor.close()
    conn.close()
    
    # Flutter tarafının beklediği formatta veri dönüştürme
    products = []
    for product in products_data:
        products.append({
            'id': product[0],  # Flutter'da product_id olarak kullanılıyor
            'name': product[1],
            'brand': product[2],
            'categoryId': product[3],  # Flutter'da categoryId olarak kullanılıyor
            'description': product[4],
            'averageRating': float(product[5]) if product[5] else None,
            'productPhoto': product[6]
        })
    
    return jsonify(products)

@app.route('/favorite', methods=['POST'])
@token_required
def add_favorite(current_user):
    data = request.get_json()
    product_id = data.get('product_id')

    if not product_id:
        return jsonify({"error": "Ürün ID gereklidir."}), 400

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
            'favorited_at': fav[7].isoformat() if fav[7] else None
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
    
    # Flutter tarafının beklediği formatta veri dönüştürme
    categories = []
    for category in categories_data:
        categories.append({
            'id': category[0],  # Flutter'da id olarak kullanılıyor
            'name': category[1]  # Flutter'da name olarak kullanılıyor
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
        return jsonify({"success": True, "message": "İnceleme başarıyla eklendi.", "review_id": review_id}), 201
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
        print(f"DEBUG: Review text from DB: {review[1]}")
        reviews.append({
            'review_id': review[0],
            'review_text': review[1],
            'rating': review[2],
            'review_date': review[3].isoformat() if review[3] else None,
            'likes_count': review[4],
            'replies': review[5],
            'user': {
                'user_id': review[6],
                'name': review[7],
                'profile_photo': review[8]
            }
        })
    
    return jsonify(reviews)

@app.route('/users/<user_id>', methods=['GET'])
@token_required
def get_user_profile(current_user, user_id):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # Kullanıcı bilgilerini al
        cursor.execute("""
            SELECT user_id, name, email, profile_photo, created_at,
                   (SELECT COUNT(*) FROM reviews WHERE user_id = users.user_id) as review_count
            FROM users 
            WHERE user_id = %s
        """, (user_id,))
        user_data = cursor.fetchone()
        
        if not user_data:
            return jsonify({"error": "Kullanıcı bulunamadı"}), 404
            
        # Kullanıcının incelemelerini al
        cursor.execute("""
            SELECT r.review_id, r.review_text, r.rating, r.review_date,
                   p.product_id, p.name as product_name, p.brand, p.product_photo
            FROM reviews r
            JOIN products p ON r.product_id = p.product_id
            WHERE r.user_id = %s
            ORDER BY r.review_date DESC
        """, (user_id,))
        reviews_data = cursor.fetchall()
        
        # Veriyi düzenle
        user = {
            'id': user_data[0],
            'name': user_data[1],
            'email': user_data[2],
            'profile_photo': user_data[3],
            'created_at': user_data[4].isoformat() if user_data[4] else None,
            'review_count': user_data[5],
            'reviews': []
        }
        
        # İncelemeleri ekle
        for review in reviews_data:
            print(f"DEBUG: Review text from DB: {review[1]}")
            user['reviews'].append({
                'id': review[0],
                'content': review[1],
                'rating': review[2],
                'created_at': review[3].isoformat() if review[3] else None,
                'product': {
                    'id': review[4],
                    'name': review[5],
                    'brand': review[6],
                    'product_photo': review[7]
                }
            })
        
        return jsonify(user)
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        cursor.close()
        conn.close()

# Bağlantı testi endpoint'i
@app.route('/test', methods=['GET'])
def test_connection():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT 1")
        cursor.close()
        conn.close()
        return jsonify({"message": "Veritabanı bağlantısı başarılı!"}), 200
    except Exception as e:
        return jsonify({"error": f"Veritabanı bağlantı hatası: {str(e)}"}), 500

@app.route('/feed', methods=['GET'])
@token_required
def get_feed_posts(current_user):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("""
            SELECT 
                r.review_id, r.review_text, r.rating, r.review_date,
                p.product_id, p.name as product_name, p.brand, p.product_photo,
                u.user_id, u.name as user_name, u.profile_photo
            FROM reviews r
            JOIN products p ON r.product_id = p.product_id
            JOIN users u ON r.user_id = u.user_id
            ORDER BY r.review_date DESC
        """)
        feed_data = cursor.fetchall()

        posts = []
        for post in feed_data:
            posts.append({
                'review_id': post[0],
                'content': post[1],
                'rating': float(post[2]) if post[2] else 0.0,
                'review_date': post[3].isoformat() if post[3] else None,
                'product_id': post[4],
                'product_name': post[5],
                'brand': post[6],
                'product_photo': post[7],
                'user_id': post[8],
                'username': post[9],
                'user_profile_photo': post[10],
            })
        return jsonify(posts)
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        cursor.close()
        conn.close()

if __name__ == '__main__':
    init_db()  # Uygulamayı başlatmadan önce veritabanını hazırla
    print("Flask uygulaması başarıyla başlatıldı ve http://127.0.0.1:5000 üzerinde çalışıyor.")
    app.run(debug=True, host='127.0.0.1', port=5000)
from flask import Flask, jsonify, request
import psycopg2
import bcrypt
import re

app = Flask(_name_)

# Ana sayfa rotası
@app.route('/')
def home():
    return "Hoşgeldiniz! Flask API çalışıyor."

# Favicon isteğine boş yanıt
@app.route('/favicon.ico')
def favicon():
    return '', 204  # Favicon isteğine boş yanıt

# PostgreSQL bağlantı bilgileri
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "BeautyCoDB"
DB_USER = "postgres"
DB_PASSWORD = "1013"

# PostgreSQL bağlantı fonksiyonu
def get_db_connection():
    conn = psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )
    return conn

# Kullanıcıları listeleme endpointi
@app.route('/users', methods=['GET'])
def get_users():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users")  # Kullanıcıları veritabanından al
    users = cursor.fetchall()
    cursor.close()
    conn.close()
    return jsonify(users)

# Kullanıcı kaydı oluşturma
@app.route('/create-user', methods=['POST'])
def create_user():
    new_user = request.get_json()
    email = new_user['email']
    password = new_user['password']

    # Şifreyi hash'le
def hash_password(password: str) -> str:
    hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())


    # Email formatını doğrula
    if not re.match(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$', email):
        return jsonify({"error": "Geçerli bir e-posta adresi giriniz."}), 400

    # Şifre uzunluğunu kontrol et   
    if len(password) < 8:
        return jsonify({"error": "Şifre en az 8 karakter olmalıdır."}), 400

    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Email'in benzersiz olup olmadığını kontrol et
    cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
    if cursor.fetchone():
        cursor.close()
        conn.close()
        return jsonify({"error": "Bu e-posta adresi zaten kullanılıyor."}), 400
    
    
    cursor.execute(
        "INSERT INTO users (name, email, profile_photo, password, past_comments) VALUES (%s, %s, %s, %s, %s) RETURNING user_id",
        (new_user['name'], email, new_user['profile_photo'], hashed_password, new_user['past_comments'])
    )
    user_id = cursor.fetchone()[0]
    conn.commit()
    cursor.close()
    conn.close()
    new_user["user_id"] = user_id
    return jsonify(new_user), 201

# Kullanıcı güncelleme
@app.route('/update-user/<int:user_id>', methods=['PATCH'])
def update_user(user_id):
    update_data = request.get_json()
    conn = get_db_connection()
    cursor = conn.cursor()
    
    update_fields = []
    values = []
    
    if "email" in update_data:
        update_fields.append("email = %s")
        values.append(update_data["email"])

    if "profile_photo" in update_data:
        update_fields.append("profile_photo = %s")
        values.append(update_data["profile_photo"])

    if "password" in update_data:
        update_fields.append("password = %s")
        hashed_password = bcrypt.hashpw(update_data["password"].encode('utf-8'), bcrypt.gensalt())
        values.append(hashed_password)
    
    if not update_fields:
        return jsonify({"error": "Güncellenecek veri bulunamadı"}), 400
    
    values.append(user_id)
    query = f"UPDATE users SET {', '.join(update_fields)} WHERE user_id = %s RETURNING *"

    cursor.execute(query, tuple(values))
    updated_user = cursor.fetchone()
    conn.commit()
    cursor.close()
    conn.close()
    
    if updated_user:
        return jsonify({"message": f"Kullanıcı ID {user_id} başarıyla güncellendi."}), 200
    return jsonify({"error": "Kullanıcı bulunamadı"}), 404

# Kullanıcı silme
@app.route('/users/<int:user_id>', methods=['DELETE'])
def delete_user(user_id):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM users WHERE user_id = %s RETURNING *", (user_id,))
    deleted_user = cursor.fetchone()
    conn.commit()
    cursor.close()
    conn.close()
    
    if deleted_user:
        return jsonify({"message": f"Kullanıcı ID {user_id} başarıyla silindi."}), 200
    return jsonify({"error": "Kullanıcı bulunamadı"}), 404

# Ürün ekleme
@app.route('/products', methods=['POST'])
def add_product():
    new_product = request.get_json()
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO products (name, description, price) VALUES (%s, %s, %s) RETURNING product_id",
        (new_product['name'], new_product['description'], new_product['price'])
    )
    product_id = cursor.fetchone()[0]
    conn.commit()
    cursor.close()
    conn.close()
    new_product["product_id"] = product_id
    return jsonify(new_product), 201

# Belirli bir ürün getirme
@app.route('/products/<int:product_id>', methods=['GET'])
def get_product_by_id(product_id):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM products WHERE product_id = %s", (product_id,))
    product = cursor.fetchone()
    cursor.close()
    conn.close()

    if product:
        return jsonify(product)
    return jsonify({"error": "Ürün bulunamadı"}), 404

# Flask uygulamasını başlat
if _name_ == '_main_':
    app.run(debug=True, port=5001)
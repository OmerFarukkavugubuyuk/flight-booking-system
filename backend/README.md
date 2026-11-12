# ✈️ Flight Booking System - Backend

Flight Booking System projesinin backend servisi için kurulum ve kullanım kılavuzu. Bu doküman; backend servisinin nasıl kurulacağını, veritabanının nasıl ayağa kaldırılacağını ve API uç noktalarının Postman üzerinden nasıl test edileceğini adım adım açıklar.

## 📋 İçindekiler

1. [Proje Gereksinimleri](#1-proje-gereksinimleri)
2. [Veritabanı Kurulumu (MySQL & phpMyAdmin)](#2-veritabanı-kurulumu-mysql--phpmyadmin)
3. [Backend Sunucusunu Başlatma](#3-backend-sunucusunu-başlatma)
4. [Postman ile API Test Rehberi](#4-postman-ile-api-test-rehberi)

---

## 1. Proje Gereksinimleri

- **Node.js** (v18 veya üzeri önerilir)
- **XAMPP** (MySQL ve phpMyAdmin sunucularını çalıştırmak için)
- **Postman** (API uç noktalarını test etmek için)

---

## 2. Veritabanı Kurulumu (MySQL & phpMyAdmin)

1. **XAMPP Kontrol Paneli**'ni açın ve **Apache** ile **MySQL** servislerini `Start` butonuna basarak çalıştırın.
2. MySQL satırındaki **Admin** butonuna tıklayarak tarayıcınızda **phpMyAdmin** arayüzünü açın.
3. Sol menüden **New (Yeni)** butonuna tıklayın:
   - **Veritabanı Adı:** `flight_booking`
   - **Karakter Seti (Collation):** `utf8mb4_unicode_ci`
   - **Create (Oluştur)** butonuna basın.
4. Sol menüden yeni oluşturduğunuz `flight_booking` veritabanını seçin ve üst menüden **Import (İçe Aktar)** sekmesine tıklayın:
   - Proje klasöründeki `database/schema.sql` dosyasını seçin ve en alttan **Import** diyerek tabloları oluşturun.
   - İşlem tamamlandığında tekrar **Import** sekmesine giderek `database/seed.sql` dosyasını seçin ve içe aktarın.

   > 💡 `seed.sql` adımı test verilerini ve havalimanlarını yükler.

---

## 3. Backend Sunucusunu Başlatma

1. Terminalinizi açın ve proje içerisindeki `backend` klasörüne gidin:

   ```bash
   cd backend
   ```

2. Gerekli bağımlılıkları yükleyin (ilk kez çalıştırıyorsanız):

   ```bash
   npm install
   ```

3. `backend/db.js` dosyasındaki MySQL bağlantı ayarlarının XAMPP yapılandırmanıza uygun olduğundan emin olun. XAMPP varsayılanında şifre boştur:

   ```js
   password: ''
   ```

4. Sunucuyu başlatın:

   ```bash
   node index.js
   ```

Başarılı çalıştığında terminalde şu mesajı görürsünüz:

```
Server running on http://localhost:3000
```

---

## 4. Postman ile API Test Rehberi

Postman uygulamasını açarak backend servislerini aşağıdaki yöntemlerle test edebilirsiniz.

### A. Havalimanlarını Listeleme

| | |
|---|---|
| **Method** | `GET` |
| **URL** | `http://localhost:3000/api/airports` |

**Açıklama:** Sistemde kayıtlı olan tüm havalimanlarının listesini döner.

### B. Kullanıcı Kaydı (Signup)

| | |
|---|---|
| **Method** | `POST` |
| **URL** | `http://localhost:3000/api/auth/signup` |

**Body:** `raw` → `JSON` seçin, aşağıdaki veriyi yapıştırıp **Send** tuşuna basın:

```json
{
  "fullName": "Test User",
  "email": "test@example.com",
  "name": "testuser",
  "password": "password123"
}
```

### C. Kullanıcı Girişi (Login)

| | |
|---|---|
| **Method** | `POST` |
| **URL** | `http://localhost:3000/api/auth/login` |

**Body:** `raw` → `JSON` seçin:

```json
{
  "name": "testuser",
  "password": "password123"
}
```

### D. Uçuş Tekliflerini Arama (Offers)

| | |
|---|---|
| **Method** | `GET` |
| **URL** | `http://localhost:3000/api/offers?dep=JFK&arr=LHR&date=2026-12-07` |

**Açıklama:** Belirtilen kalkış, varış ve tarih kriterlerine uygun uçuş tekliflerini listeler.

| Parametre | Açıklama | Örnek |
|-----------|----------|-------|
| `dep` | Kalkış havalimanı kodu | `JFK` |
| `arr` | Varış havalimanı kodu | `LHR` |
| `date` | Uçuş tarihi (YYYY-MM-DD) | `2026-12-07` |

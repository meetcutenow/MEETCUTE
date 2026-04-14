# MeetCute Backend — Pokretanje

## Preduvjeti
- Java 17+
- Maven 3.8+
- MySQL 8+

## Korak 1 — Kreiraj bazu podataka

```sql
CREATE DATABASE meetcuteapp
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
```

## Korak 2 — Pokreni SQL shemu

```bash
mysql -u root -p meetcuteapp < src/main/resources/schema.sql
```

## Korak 3 — Konfiguracija (application.properties)

Promijeni ako trebaš:
```
spring.datasource.username=root
spring.datasource.password=MANISTRA
```

## Korak 4 — Pokretanje

```bash
cd meetcute-backend
mvn spring-boot:run
```

Backend sluša na: **http://localhost:8080**

---

## Flutter integracija

Kopiraj `api_service.dart` u `projekt/lib/services/`.

| Platforma | URL u api_service.dart |
|---|---|
| Android emulator | `http://10.0.2.2:8080/api` |
| iOS simulator | `http://127.0.0.1:8080/api` |
| Fizički uređaj | `http://<tvoj-IP>:8080/api` |

## API Endpointi

| Metoda | Put | Opis |
|--------|-----|------|
| POST | /api/auth/register | Registracija |
| POST | /api/auth/login | Prijava |
| POST | /api/auth/refresh | Osvježi token |
| POST | /api/auth/logout | Odjava |
| GET  | /api/users/me | Moj profil |
| PUT  | /api/users/me | Ažuriraj profil |
| GET  | /api/users/{id} | Tuđi profil |
| PUT  | /api/users/me/location | Ažuriraj lokaciju |
| POST | /api/users/me/visibility | Toggle vidljivosti |
| GET  | /api/questions | Tajna pitanja |
| GET  | /api/events | Svi eventi |
| GET  | /api/events?city=Zagreb | Eventi po gradu |
| POST | /api/events | Kreiraj event (Premium) |
| POST | /api/events/{id}/attend | Prijava/otkaz na event |
| POST | /api/likes | Lajkaj korisnika |
| GET  | /api/matches | Svi matchevi |
| POST | /api/matches/{id}/answer | Odgovori na tajno pitanje |
| GET  | /api/conversations/{id}/messages | Poruke |
| POST | /api/conversations/{id}/messages | Pošalji poruku |
| GET  | /api/notifications | Obavijesti |
| POST | /api/notifications/read | Označi pročitanim |

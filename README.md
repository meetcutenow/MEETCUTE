# MeetCute - Upute za pokretanje

MeetCute - mobilna aplikacija za upoznavanje koja temelji svoju match logiku na blizini korisnika (kada se kompatibilni korisnici nađu na istoj
lokaciji dobivaju push obavijest s profilom potencijalnog spoja te ukoliko su oboje suglasni, mogu se upoznati) i zajedničkim interesima i kompatibilnosti. 
Također nudi organizirana događanja (Speed Dating, Running Date, itd.), mogućnost organiziranja vlastitih događanja(korisnicima/organizacijama) i
filtriranje svojih spojeva. 

plan za dalje:

trenutno implementirana osnovna match logika koju treba nadograditi

-kompletno funkcionalna match logika koja se temelji na blizini i kompatibilnosti

-implementirati Redis - lokacija, match logika

-funkcionalne poruke i grupni razgovori za korisnike prijavljene na određena događanja (maknuti primjere iz koda)

-mogućnost prihvaćanja/odbijanja korisnika na vlastitom događanju

-push obavijesti

# Deploy
Ova aplikacija je primarno razvijena kao mobilna aplikacija (Flutter) i nije zamišljena kao klasična web aplikacija koja se pokreće u pregledniku.

Zbog toga postoje dvije odvojene konfiguracije:

Ovaj repozitorij → služi za lokalno pokretanje i razvoj
Deploy verzija → nalazi se na zasebnom repozitoriju i koristi se isključivo za demonstraciju funkcionalnosti u produkcijskom okruženju

---

link: https://meetcutedeploy.netlify.app/

---


Flutter Web (Netlify)

        ↓
        
Spring Boot API (Railway)

        ↓
        
MySQL (Railway)


Whisper Server (Railway) - AI izrada profila

----

 
!Web Ograničenja 

1. Funkcija "Popuni profil glasom" nije dostupna u web pregledniku. Aplikacija koristi record paket koji za snimanje audio zapisa koristi lokalni datotečni sustav
 (dart:io) i sprema .wav datoteku na uređaju. Funkcija je u potpunosti dostupna u mobilnoj verziji aplikacije (Android/iOS).

3. Dodavanje profilnih fotografija i slika događanja nije dostupno u web pregledniku. Aplikacija koristi image_picker i File iz dart:io za čitanje odabrane slike i njeno slanje kao MultipartRequest na backend. Funkcionalnost je u potpunosti dostupna u mobilnoj verziji aplikacije (Android/iOS).


# Lokalno pokretanje

meetcute/

├── meetcute-backend/    – Spring Boot REST API (Java)

├── projekt/             – Flutter mobilna aplikacija

└── whisper-server/      – Python server za glasovni unos (AI izrada profila)


dodatne komponente: Cloudinary (pohrana slika), JSON Web Token (autentifikacija)

---

# Preduvjeti

- Java 17+ — https://adoptium.net
- Maven 3.9+ — https://maven.apache.org/download.cgi
- MySQL 8.0+ — https://dev.mysql.com/downloads/installer/
- Flutter SDK 3.x — https://flutter.dev/docs/get-started/install
- Python 3.10+ (samo za glasovni unos)

---

# 1. Baza podataka

Pokrenuti MySQL i uvesti dump koji se nalazi u projektu:

mysql -u root -p < baza_polufinale.sql


Dump vec sadrži sve tablice, podatke i testne korisnike/događanja za primjer.

->testni korisnici:

username: lorna | lozinka: Lorna123

username: vera | lozinka: Lorna123

username: ivan | lozinka: Lorna123

username: matko | lozinka: Lorna123

organizacije:

username:meetcute | lozinka:Lorna123

---

# 2. Konfiguracija backenda

U mapi `meetcute-backend/src/main/resources/` postoji `application.properties.template`.
Kopirati ga i preimenovati u `application.properties`:



cp application.properties.template application.properties



Urediti sljedeće vrijednosti:



properties

spring.datasource.url=jdbc:mysql://localhost:3306/meetcuteapp

spring.datasource.username=TVOJ_MYSQL_USERNAME

spring.datasource.password=TVOJA_MYSQL_LOZINKA


jwt.secret=BILO_KOJI_RANDOM_STRING_MINIMALNO_32_ZNAKA

jwt.access-token-expiration=86400000

jwt.refresh-token-expiration=2592000000

cloudinary.cloud-name=TVOJ_CLOUD_NAME

cloudinary.api-key=TVOJ_API_KEY

cloudinary.api-secret=TVOJ_API_SECRET


groq.api-key=TVOJ_GROQ_API_KEY


Cloudinary — besplatni račun na cloudinary.com.

Groq — besplatni račun na console.groq.com.



# 3. Pokretanje backenda

cd meetcute-backend
mvn spring-boot:run

Kada se ispiše "Started BackendApplication" u konzoli, backend je spreman na portu 8080.

Dodani automatizirani testovi pod meetcute-backend/src/test/java/com/meetcute/backend/.



# 4. Pokretanje frontenda

cd projekt
flutter pub get
flutter run


VAZNO za fizički uredaj: u kodu treba zamijeniti `localhost` s IP adresom racunala u lokalnoj mreži. Na Android emulatoru koristi `10.0.2.2` umjesto `localhost`.


# 5. Whisper server

Potreban samo za funkciju "Popuni profil glasom".

cd whisper-server
python -m venv venv

 Windows:
venv\Scripts\activate

 macOS/Linux:
source venv/bin/activate

pip install -r requirements.txt
python server.py

Pri prvom pokretanju preuzima Whisper model (~1.5 GB), to se događa samo jednom i traje nekoliko minuta.


# Redosljed pokretanja

1. MySQL mora biti pokrenut
2. Pokrenuti backend: `mvn spring-boot:run` u mapi meetcute-backend
3. Pokreni Flutter app: `flutter run` u mapi projekt
4. (opcionalno) Pokrenuti Whisper: `python server.py` u mapi whisper-server

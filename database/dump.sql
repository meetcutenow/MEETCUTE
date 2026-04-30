-- MySQL dump 10.13  Distrib 8.0.45, for Win64 (x86_64)
--
-- Host: localhost    Database: meetcuteapp
-- ------------------------------------------------------
-- Server version	8.0.45

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `companies`
--

DROP TABLE IF EXISTS `companies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `companies` (
  `id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `org_name` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `logo_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `is_banned` tinyint(1) NOT NULL DEFAULT '0',
  `push_token` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `last_seen_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `email` (`email`),
  KEY `idx_company_active` (`is_active`,`is_banned`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `companies`
--

LOCK TABLES `companies` WRITE;
/*!40000 ALTER TABLE `companies` DISABLE KEYS */;
INSERT INTO `companies` VALUES ('82b42728-e1e4-46ba-b81e-c62a6b3903af','meetcute','MeetCute','meetcutenow@gmail.com','$2a$10$9EfMrypCefviLpH.OFuHquVg1YoNJfs0Di9BiXIrTYkVjilYwxaGS','https://res.cloudinary.com/dfgdls3ro/image/upload/v1776804816/meetcute/logos/beeg2jatxgbrsfyhifqr.png',1,0,NULL,'2026-04-19 00:39:27','2026-04-30 22:57:12','2026-04-30 22:57:13');
/*!40000 ALTER TABLE `companies` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `company_refresh_tokens`
--

DROP TABLE IF EXISTS `company_refresh_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `company_refresh_tokens` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `company_id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `token_hash` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `expires_at` datetime NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_revoked` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `token_hash` (`token_hash`),
  KEY `idx_crt_company` (`company_id`),
  CONSTRAINT `fk_crt_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `company_refresh_tokens`
--

LOCK TABLES `company_refresh_tokens` WRITE;
/*!40000 ALTER TABLE `company_refresh_tokens` DISABLE KEYS */;
INSERT INTO `company_refresh_tokens` VALUES (1,'82b42728-e1e4-46ba-b81e-c62a6b3903af','3e609f89mE1S9trQ','2026-05-30 22:50:34','2026-04-30 22:50:34',1),(2,'82b42728-e1e4-46ba-b81e-c62a6b3903af','e442d76eNMZ4zoQg','2026-05-30 22:56:22','2026-04-30 22:56:22',1),(3,'82b42728-e1e4-46ba-b81e-c62a6b3903af','383a4e2ah6AIJWJg','2026-05-30 22:57:13','2026-04-30 22:57:13',1);
/*!40000 ALTER TABLE `company_refresh_tokens` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `conversation_participants`
--

DROP TABLE IF EXISTS `conversation_participants`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `conversation_participants` (
  `conversation_id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `joined_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_read_at` datetime DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`conversation_id`,`user_id`),
  KEY `idx_cp_user` (`user_id`),
  CONSTRAINT `fk_cp_conv` FOREIGN KEY (`conversation_id`) REFERENCES `conversations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_cp_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `conversation_participants`
--

LOCK TABLES `conversation_participants` WRITE;
/*!40000 ALTER TABLE `conversation_participants` DISABLE KEYS */;
/*!40000 ALTER TABLE `conversation_participants` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `conversations`
--

DROP TABLE IF EXISTS `conversations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `conversations` (
  `id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `match_id` bigint unsigned DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_message_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_conv_match` (`match_id`),
  KEY `idx_conv_last` (`last_message_at`),
  CONSTRAINT `fk_conv_match` FOREIGN KEY (`match_id`) REFERENCES `matches` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `conversations`
--

LOCK TABLES `conversations` WRITE;
/*!40000 ALTER TABLE `conversations` DISABLE KEYS */;
/*!40000 ALTER TABLE `conversations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `event_attendees`
--

DROP TABLE IF EXISTS `event_attendees`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `event_attendees` (
  `event_id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('joined','cancelled') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'joined',
  `joined_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`event_id`,`user_id`),
  KEY `idx_ea_user` (`user_id`),
  CONSTRAINT `fk_ea_event` FOREIGN KEY (`event_id`) REFERENCES `events` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_ea_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `event_attendees`
--

LOCK TABLES `event_attendees` WRITE;
/*!40000 ALTER TABLE `event_attendees` DISABLE KEYS */;
INSERT INTO `event_attendees` VALUES ('ce622973-73af-4a45-8e51-226cfe21ab15','6acfaccb-bd78-4fa0-84fa-587efc6f1cba','joined','2026-04-25 15:34:19','2026-04-25 15:52:41'),('d0d5389b-b8f1-4339-97a2-c7a9f9e66d9b','153b31c2-15f4-4c73-83c9-a5e8c701f06e','cancelled','2026-04-30 22:55:22','2026-04-30 22:56:50'),('d0d5389b-b8f1-4339-97a2-c7a9f9e66d9b','6acfaccb-bd78-4fa0-84fa-587efc6f1cba','joined','2026-04-25 15:08:00','2026-04-25 15:07:59'),('d0d5389b-b8f1-4339-97a2-c7a9f9e66d9b','a1fb1e95-8cd9-4bd5-ab58-f4c78156f249','joined','2026-04-30 22:48:00','2026-04-30 22:47:59'),('d0d5389b-b8f1-4339-97a2-c7a9f9e66d9b','a79e359c-0938-405d-b5d8-caf8e50328ec','joined','2026-04-19 22:22:57','2026-04-21 01:37:55'),('d0d5389b-b8f1-4339-97a2-c7a9f9e66d9b','b9ebf69d-6f9e-468c-89e4-0306a1e8275e','joined','2026-04-28 11:29:04','2026-04-28 11:29:04');
/*!40000 ALTER TABLE `event_attendees` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `events`
--

DROP TABLE IF EXISTS `events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `events` (
  `id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `creator_id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `company_id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `title` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `city` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `specific_location` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `event_date` date NOT NULL,
  `time_start` time DEFAULT NULL,
  `time_end` time DEFAULT NULL,
  `category` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `age_group` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `gender_group` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `max_attendees` smallint DEFAULT NULL,
  `ticket_price` decimal(8,2) DEFAULT NULL,
  `ticket_currency` varchar(5) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'EUR',
  `cover_photo_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `card_color_hex` char(7) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '#6DD5E8',
  `is_user_event` tinyint(1) NOT NULL DEFAULT '0',
  `is_company_event` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_event_city` (`city`),
  KEY `idx_event_date` (`event_date`),
  KEY `idx_event_category` (`category`),
  KEY `idx_event_creator` (`creator_id`),
  KEY `idx_event_coords` (`latitude`,`longitude`),
  KEY `idx_event_active` (`is_active`),
  KEY `idx_event_company` (`company_id`),
  CONSTRAINT `fk_event_company` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_event_creator` FOREIGN KEY (`creator_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `events`
--

LOCK TABLES `events` WRITE;
/*!40000 ALTER TABLE `events` DISABLE KEYS */;
INSERT INTO `events` VALUES ('8458c5cf-3775-11f1-882d-005056c00001',NULL,NULL,'Running dating','Idealna prilika za ljubitelje trčanja.','Zagreb','Jarun, Aleja Matije Ljubeka, Zagreb',45.7785000,15.9148000,'2025-04-14','10:00:00','12:00:00','Sport','18-25','all',NULL,NULL,'EUR',NULL,'#6DD5E8',0,0,1,'2026-04-13 22:15:29','2026-04-13 22:15:29'),('8458d5f7-3775-11f1-882d-005056c00001',NULL,NULL,'Jutarnja kava','Opuštena jutarnja kava u Starom Gradu.','Zagreb','Caffe Bar Booksa, Martićeva 14d, Zagreb',45.8131000,15.9741000,'2025-04-15','08:30:00','10:00:00','Kava','26-35','all',NULL,NULL,'EUR',NULL,'#FFD166',0,0,1,'2026-04-13 22:15:29','2026-04-13 22:15:29'),('8458dd7d-3775-11f1-882d-005056c00001',NULL,NULL,'Piknik u parku','Piknik uz dobro raspoloženje.','Zagreb','Ulaz 1, Maksimirski perivoj, Zagreb',45.8237000,16.0189000,'2025-04-16','12:00:00','15:00:00','Priroda','all','female',NULL,NULL,'EUR',NULL,'#95D5B2',0,0,1,'2026-04-13 22:15:29','2026-04-13 22:15:29'),('8458e13f-3775-11f1-882d-005056c00001',NULL,NULL,'Večer komedije','Večer smijeha i kulture u HNK-u.','Zagreb','HNK Zagreb, Trg Republike Hrvatske 15',45.8089000,15.9702000,'2025-04-17','20:00:00','22:30:00','Kultura','36-45','all',NULL,NULL,'EUR',NULL,'#FFB3C6',0,0,1,'2026-04-13 22:15:29','2026-04-13 22:15:29'),('8458e49f-3775-11f1-882d-005056c00001',NULL,NULL,'Street food festival','Okusi sve što Zagreb ima za ponuditi.','Zagreb','Trg bana Josipa Jelačića 1, Zagreb',45.8132000,15.9773000,'2025-04-18','11:00:00','20:00:00','Hrana','all','all',NULL,NULL,'EUR',NULL,'#FFD166',0,0,1,'2026-04-13 22:15:29','2026-04-13 22:15:29'),('8458e7c7-3775-11f1-882d-005056c00001',NULL,NULL,'Plaža & kava','Kava uz šum mora na Bačvicama.','Split','Plaža Bačvice, Put Firula, Split',43.5016000,16.4413000,'2025-04-14','09:00:00','11:00:00','Kava','18-25','all',NULL,NULL,'EUR',NULL,'#6DD5E8',0,0,1,'2026-04-13 22:15:29','2026-04-13 22:15:29'),('8458eadd-3775-11f1-882d-005056c00001',NULL,NULL,'Dioklecijanova noć','Šetnja unutar zidina stare palače.','Split','Peristil, Dioklecijanova palača, Split',43.5081000,16.4402000,'2025-04-20','21:00:00','23:30:00','Kultura','26-35','all',NULL,NULL,'EUR',NULL,'#FFB3C6',0,0,1,'2026-04-13 22:15:29','2026-04-13 22:15:29'),('8458ede8-3775-11f1-882d-005056c00001',NULL,NULL,'Tvrđa fest','Festival hrane, glazbe i kulture.','Osijek','Trg Svetog Trojstva 6, Tvrđa, Osijek',45.5606000,18.6956000,'2025-04-22','17:00:00','22:00:00','Kultura','all','all',NULL,NULL,'EUR',NULL,'#FFD166',0,0,1,'2026-04-13 22:15:29','2026-04-13 22:15:29'),('8458f104-3775-11f1-882d-005056c00001',NULL,NULL,'Sunčani sat','Zalazak sunca uz morske orgulje.','Zadar','Morske orgulje, Obala kralja P. Krešimira IV, Zadar',44.1152000,15.2214000,'2025-04-15','18:30:00','20:00:00','Priroda','18-25','female',NULL,NULL,'EUR',NULL,'#95D5B2',0,0,1,'2026-04-13 22:15:29','2026-04-13 22:15:29'),('8458f410-3775-11f1-882d-005056c00001',NULL,NULL,'Vinska večer','Degustacija dalmatinskih vina.','Zadar','Konoba Stomorica, Stomorica 12, Zadar',44.1164000,15.2272000,'2025-04-19','19:00:00','22:00:00','Hrana','36-45','all',NULL,NULL,'EUR',NULL,'#FFB3C6',0,0,1,'2026-04-13 22:15:29','2026-04-13 22:15:29'),('ce622973-73af-4a45-8e51-226cfe21ab15','a79e359c-0938-405d-b5d8-caf8e50328ec',NULL,'Jutarnja kava!!','Ugodna kava.','Split','caffe bar Mačak',43.5094009,16.4801870,'2026-04-28','10:00:00','12:00:00','Kava','g18_25','all',10,NULL,'EUR',NULL,'#6DD5E8',1,0,1,'2026-04-25 15:33:13','2026-04-26 13:32:14'),('d0d5389b-b8f1-4339-97a2-c7a9f9e66d9b',NULL,'82b42728-e1e4-46ba-b81e-c62a6b3903af','MeetCute upoznavanje','upoznavanje','Zagreb','Dom sportova',45.8078441,15.9518004,'2026-04-22','10:00:00','14:00:00','Kava','all','all',300,5.00,'EUR',NULL,'#B5D8FF',0,1,1,'2026-04-19 22:21:45','2026-04-26 14:48:33');
/*!40000 ALTER TABLE `events` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `interests`
--

DROP TABLE IF EXISTS `interests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `interests` (
  `id` smallint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `emoji` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `category` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_interest_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `interests`
--

LOCK TABLES `interests` WRITE;
/*!40000 ALTER TABLE `interests` DISABLE KEYS */;
INSERT INTO `interests` VALUES (1,'Crtanje','????','Kreativno'),(2,'Fotografija','????','Kreativno'),(3,'Pisanje','✍️','Kreativno'),(4,'Film','????','Zabava'),(5,'Trčanje','????','Sport'),(6,'Biciklizam','????','Sport'),(7,'Planinarenje','????','Priroda'),(8,'Teretana','????️','Sport'),(9,'Boks','????','Sport'),(10,'Tenis','????','Sport'),(11,'Nogomet','⚽','Sport'),(12,'Odbojka','????','Sport'),(13,'Kuhanje','????‍????','Hrana'),(14,'Putovanja','✈️','Avantura'),(15,'Gaming','????','Zabava'),(16,'Formula','????️','Sport'),(17,'Glazba','????','Kreativno');
/*!40000 ALTER TABLE `interests` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `likes`
--

DROP TABLE IF EXISTS `likes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `likes` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `liker_id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `liked_id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `context_type` enum('proximity','event','map') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'proximity',
  `context_event_id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `liked_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_like_pair` (`liker_id`,`liked_id`),
  KEY `idx_like_liked` (`liked_id`),
  KEY `idx_like_time` (`liked_at`),
  CONSTRAINT `fk_like_liked` FOREIGN KEY (`liked_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_like_liker` FOREIGN KEY (`liker_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `likes`
--

LOCK TABLES `likes` WRITE;
/*!40000 ALTER TABLE `likes` DISABLE KEYS */;
/*!40000 ALTER TABLE `likes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `matches`
--

DROP TABLE IF EXISTS `matches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matches` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_a_id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_b_id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `common_interests` tinyint NOT NULL DEFAULT '0',
  `distance_m` int DEFAULT NULL,
  `status` enum('pending_meetup','expired','unmatched') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending_meetup',
  `matched_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `chat_unlocked_at` datetime DEFAULT NULL,
  `expires_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_match_pair` (`user_a_id`,`user_b_id`),
  KEY `idx_match_b` (`user_b_id`),
  KEY `idx_match_status` (`status`),
  KEY `idx_match_expires` (`expires_at`),
  CONSTRAINT `fk_match_a` FOREIGN KEY (`user_a_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_match_b` FOREIGN KEY (`user_b_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matches`
--

LOCK TABLES `matches` WRITE;
/*!40000 ALTER TABLE `matches` DISABLE KEYS */;
/*!40000 ALTER TABLE `matches` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `messages`
--

DROP TABLE IF EXISTS `messages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `messages` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `conversation_id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `sender_id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `body` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `photo_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `sent_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_deleted` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `idx_msg_conv` (`conversation_id`,`sent_at`),
  KEY `idx_msg_sender` (`sender_id`),
  CONSTRAINT `fk_msg_conv` FOREIGN KEY (`conversation_id`) REFERENCES `conversations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_msg_sender` FOREIGN KEY (`sender_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `messages`
--

LOCK TABLES `messages` WRITE;
/*!40000 ALTER TABLE `messages` DISABLE KEYS */;
/*!40000 ALTER TABLE `messages` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notifications`
--

DROP TABLE IF EXISTS `notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notifications` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `type` enum('joined_event','cancelled_event','event_reminder','new_event','nearby_person','mutual_like','new_message','general') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `body` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `event_id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `match_id` bigint unsigned DEFAULT NULL,
  `nearby_user_id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_read` tinyint(1) NOT NULL DEFAULT '0',
  `accent_color` char(7) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_notif_user` (`user_id`,`is_read`),
  KEY `idx_notif_event` (`event_id`),
  KEY `idx_notif_match` (`match_id`),
  CONSTRAINT `fk_notif_event` FOREIGN KEY (`event_id`) REFERENCES `events` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_notif_match` FOREIGN KEY (`match_id`) REFERENCES `matches` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_notif_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=37 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notifications`
--

LOCK TABLES `notifications` WRITE;
/*!40000 ALTER TABLE `notifications` DISABLE KEYS */;
INSERT INTO `notifications` VALUES (13,'a79e359c-0938-405d-b5d8-caf8e50328ec','new_event','Događaj izmijenjen','\"MeetCute\" je ažuriran od strane organizatora MeetCute. Provjeri nove detalje.','d0d5389b-b8f1-4339-97a2-c7a9f9e66d9b',NULL,NULL,0,'#FFD166','2026-04-21 23:23:50'),(14,'6acfaccb-bd78-4fa0-84fa-587efc6f1cba','new_event','Događaj izmijenjen','\"Jutarnja kava\" je ažuriran. Provjeri nove detalje.','ce622973-73af-4a45-8e51-226cfe21ab15',NULL,NULL,0,'#FFD166','2026-04-25 15:44:35'),(21,'a79e359c-0938-405d-b5d8-caf8e50328ec','new_event','Nova prijava!','Lorna2 se prijavio/la na tvoj event \"Jutarnja kava\".','ce622973-73af-4a45-8e51-226cfe21ab15',NULL,NULL,0,'#95D5B2','2026-04-25 15:52:14'),(24,'6acfaccb-bd78-4fa0-84fa-587efc6f1cba','new_event','Događaj izmijenjen','\"Jutarnja kava!!\" je ažuriran. Provjeri nove detalje.','ce622973-73af-4a45-8e51-226cfe21ab15',NULL,NULL,0,'#FFD166','2026-04-26 13:32:14'),(25,'6acfaccb-bd78-4fa0-84fa-587efc6f1cba','new_event','Događaj izmijenjen','\"MeetCute\" je ažuriran od strane organizatora MeetCute. Provjeri nove detalje.','d0d5389b-b8f1-4339-97a2-c7a9f9e66d9b',NULL,NULL,0,'#FFD166','2026-04-26 14:11:14'),(34,'a79e359c-0938-405d-b5d8-caf8e50328ec','new_event','Događaj izmijenjen','\"MeetCute\" je ažuriran od strane organizatora MeetCute. Provjeri nove detalje.','d0d5389b-b8f1-4339-97a2-c7a9f9e66d9b',NULL,NULL,0,'#FFD166','2026-04-26 14:27:32'),(35,'6acfaccb-bd78-4fa0-84fa-587efc6f1cba','new_event','Događaj izmijenjen','\"MeetCute upoznavanje\" je ažuriran od strane organizatora MeetCute. Provjeri nove detalje.','d0d5389b-b8f1-4339-97a2-c7a9f9e66d9b',NULL,NULL,0,'#FFD166','2026-04-26 14:48:33'),(36,'a79e359c-0938-405d-b5d8-caf8e50328ec','new_event','Događaj izmijenjen','\"MeetCute upoznavanje\" je ažuriran od strane organizatora MeetCute. Provjeri nove detalje.','d0d5389b-b8f1-4339-97a2-c7a9f9e66d9b',NULL,NULL,0,'#FFD166','2026-04-26 14:48:33');
/*!40000 ALTER TABLE `notifications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `refresh_tokens`
--

DROP TABLE IF EXISTS `refresh_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `refresh_tokens` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `token_hash` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `expires_at` datetime NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_revoked` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_rt_token` (`token_hash`),
  KEY `idx_rt_user` (`user_id`),
  KEY `idx_rt_expires` (`expires_at`),
  CONSTRAINT `fk_rt_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `refresh_tokens`
--

LOCK TABLES `refresh_tokens` WRITE;
/*!40000 ALTER TABLE `refresh_tokens` DISABLE KEYS */;
INSERT INTO `refresh_tokens` VALUES (1,'a1fb1e95-8cd9-4bd5-ab58-f4c78156f249','b3154c790r8zHlGA','2026-05-30 22:52:10','2026-04-30 22:52:10',0),(2,'a79e359c-0938-405d-b5d8-caf8e50328ec','ce2af22azlX_loKw','2026-05-30 22:52:49','2026-04-30 22:52:49',0),(3,'a1fb1e95-8cd9-4bd5-ab58-f4c78156f249','3d8800c1GEGSRmCw','2026-05-30 22:53:42','2026-04-30 22:53:42',0),(4,'b9ebf69d-6f9e-468c-89e4-0306a1e8275e','98bb9903FQk6Sh1g','2026-05-30 22:54:12','2026-04-30 22:54:12',0),(5,'153b31c2-15f4-4c73-83c9-a5e8c701f06e','70c24661QE2D3ohw','2026-05-30 22:54:47','2026-04-30 22:54:47',0),(6,'a1fb1e95-8cd9-4bd5-ab58-f4c78156f249','71d84584APfGnOdg','2026-05-30 22:55:49','2026-04-30 22:55:49',0),(7,'153b31c2-15f4-4c73-83c9-a5e8c701f06e','7b4a16eb3rQQg9Vg','2026-05-30 22:56:42','2026-04-30 22:56:42',0),(8,'6acfaccb-bd78-4fa0-84fa-587efc6f1cba','223fc91chCq2AcLA','2026-05-30 22:58:15','2026-04-30 22:58:15',0),(9,'153b31c2-15f4-4c73-83c9-a5e8c701f06e','713937a0AZOY3v4A','2026-05-30 22:59:05','2026-04-30 22:59:05',0);
/*!40000 ALTER TABLE `refresh_tokens` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_interests`
--

DROP TABLE IF EXISTS `user_interests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_interests` (
  `user_id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `interest_id` smallint unsigned NOT NULL,
  PRIMARY KEY (`user_id`,`interest_id`),
  KEY `idx_ui_interest` (`interest_id`),
  CONSTRAINT `fk_ui_interest` FOREIGN KEY (`interest_id`) REFERENCES `interests` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_ui_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_interests`
--

LOCK TABLES `user_interests` WRITE;
/*!40000 ALTER TABLE `user_interests` DISABLE KEYS */;
INSERT INTO `user_interests` VALUES ('a79e359c-0938-405d-b5d8-caf8e50328ec',1),('a79e359c-0938-405d-b5d8-caf8e50328ec',2),('b9ebf69d-6f9e-468c-89e4-0306a1e8275e',4),('153b31c2-15f4-4c73-83c9-a5e8c701f06e',5),('a1fb1e95-8cd9-4bd5-ab58-f4c78156f249',6),('a79e359c-0938-405d-b5d8-caf8e50328ec',6),('b9ebf69d-6f9e-468c-89e4-0306a1e8275e',6),('153b31c2-15f4-4c73-83c9-a5e8c701f06e',7),('a1fb1e95-8cd9-4bd5-ab58-f4c78156f249',7),('153b31c2-15f4-4c73-83c9-a5e8c701f06e',8),('6acfaccb-bd78-4fa0-84fa-587efc6f1cba',9),('a79e359c-0938-405d-b5d8-caf8e50328ec',9),('6acfaccb-bd78-4fa0-84fa-587efc6f1cba',10),('a1fb1e95-8cd9-4bd5-ab58-f4c78156f249',10),('153b31c2-15f4-4c73-83c9-a5e8c701f06e',11),('b9ebf69d-6f9e-468c-89e4-0306a1e8275e',11),('6acfaccb-bd78-4fa0-84fa-587efc6f1cba',13),('a1fb1e95-8cd9-4bd5-ab58-f4c78156f249',13),('153b31c2-15f4-4c73-83c9-a5e8c701f06e',14),('6acfaccb-bd78-4fa0-84fa-587efc6f1cba',14),('a1fb1e95-8cd9-4bd5-ab58-f4c78156f249',14),('b9ebf69d-6f9e-468c-89e4-0306a1e8275e',14),('153b31c2-15f4-4c73-83c9-a5e8c701f06e',15),('b9ebf69d-6f9e-468c-89e4-0306a1e8275e',17);
/*!40000 ALTER TABLE `user_interests` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_locations`
--

DROP TABLE IF EXISTS `user_locations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_locations` (
  `user_id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `latitude` decimal(10,7) NOT NULL,
  `longitude` decimal(10,7) NOT NULL,
  `city` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  KEY `idx_loc_coords` (`latitude`,`longitude`),
  CONSTRAINT `fk_loc_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_locations`
--

LOCK TABLES `user_locations` WRITE;
/*!40000 ALTER TABLE `user_locations` DISABLE KEYS */;
/*!40000 ALTER TABLE `user_locations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_photos`
--

DROP TABLE IF EXISTS `user_photos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_photos` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `photo_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `photo_order` tinyint NOT NULL DEFAULT '0',
  `is_primary` tinyint(1) NOT NULL DEFAULT '0',
  `uploaded_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_photo_order` (`user_id`,`photo_order`),
  KEY `idx_photo_user` (`user_id`),
  CONSTRAINT `fk_photo_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_photos`
--

LOCK TABLES `user_photos` WRITE;
/*!40000 ALTER TABLE `user_photos` DISABLE KEYS */;
INSERT INTO `user_photos` VALUES (13,'a79e359c-0938-405d-b5d8-caf8e50328ec','https://res.cloudinary.com/dfgdls3ro/image/upload/v1777582408/meetcute/profiles/yflp9grigighicradf9g.jpg',0,1,'2026-04-30 22:53:29'),(14,'a79e359c-0938-405d-b5d8-caf8e50328ec','https://res.cloudinary.com/dfgdls3ro/image/upload/v1777582409/meetcute/profiles/tfqxjyzowfcjxjyfud5j.jpg',1,0,'2026-04-30 22:53:30'),(15,'a1fb1e95-8cd9-4bd5-ab58-f4c78156f249','https://res.cloudinary.com/dfgdls3ro/image/upload/v1777582437/meetcute/profiles/k3ryltvuowicamjj28it.jpg',0,1,'2026-04-30 22:53:58'),(16,'a1fb1e95-8cd9-4bd5-ab58-f4c78156f249','https://res.cloudinary.com/dfgdls3ro/image/upload/v1777582438/meetcute/profiles/yi2zypd838udtaxyznur.jpg',1,0,'2026-04-30 22:53:59'),(17,'b9ebf69d-6f9e-468c-89e4-0306a1e8275e','https://res.cloudinary.com/dfgdls3ro/image/upload/v1777582469/meetcute/profiles/ll6libsf8aieaixskro1.jpg',0,1,'2026-04-30 22:54:30'),(18,'b9ebf69d-6f9e-468c-89e4-0306a1e8275e','https://res.cloudinary.com/dfgdls3ro/image/upload/v1777582470/meetcute/profiles/aaxsnvgavyomlz1jovf3.jpg',1,0,'2026-04-30 22:54:31'),(19,'153b31c2-15f4-4c73-83c9-a5e8c701f06e','https://res.cloudinary.com/dfgdls3ro/image/upload/v1777582503/meetcute/profiles/a0muy7iygna1jig0luck.jpg',0,1,'2026-04-30 22:55:05'),(20,'153b31c2-15f4-4c73-83c9-a5e8c701f06e','https://res.cloudinary.com/dfgdls3ro/image/upload/v1777582505/meetcute/profiles/uq07gxrb4uf6e7kvbwdp.jpg',1,0,'2026-04-30 22:55:06'),(21,'6acfaccb-bd78-4fa0-84fa-587efc6f1cba','https://res.cloudinary.com/dfgdls3ro/image/upload/v1777582719/meetcute/profiles/pgdsvitmatldzewcsisa.jpg',0,1,'2026-04-30 22:58:40'),(22,'6acfaccb-bd78-4fa0-84fa-587efc6f1cba','https://res.cloudinary.com/dfgdls3ro/image/upload/v1777582720/meetcute/profiles/xsjfbyupcwk1c1sjsno0.jpg',1,0,'2026-04-30 22:58:41');
/*!40000 ALTER TABLE `user_photos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_profiles`
--

DROP TABLE IF EXISTS `user_profiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_profiles` (
  `user_id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `birth_day` tinyint DEFAULT NULL,
  `birth_month` tinyint DEFAULT NULL,
  `birth_year` smallint DEFAULT NULL,
  `height_cm` smallint DEFAULT NULL,
  `gender` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `hair_color` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `eye_color` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `has_piercing` tinyint(1) DEFAULT NULL,
  `has_tattoo` tinyint(1) DEFAULT NULL,
  `seeking_gender` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `max_distance_pref_m` int unsigned NOT NULL DEFAULT '300',
  `ice_breaker` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_visible` tinyint(1) NOT NULL DEFAULT '1',
  `pref_age_from` int DEFAULT NULL,
  `pref_age_to` int DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  CONSTRAINT `fk_profile_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_profiles`
--

LOCK TABLES `user_profiles` WRITE;
/*!40000 ALTER TABLE `user_profiles` DISABLE KEYS */;
INSERT INTO `user_profiles` VALUES ('153b31c2-15f4-4c73-83c9-a5e8c701f06e',1,1,2002,191,'musko','smeda','smede',1,1,'zensko',300,'Ispričaj mi svoj najdraži vic.',1,18,25,'2026-04-28 11:25:31','2026-04-28 11:25:31'),('6acfaccb-bd78-4fa0-84fa-587efc6f1cba',23,1,2004,165,'zensko','smeda','zelene',0,1,'sve',300,'Volim kad mi ljudi priđu opušteno i pitaju me koji film gledam.',1,18,99,'2026-04-25 15:07:43','2026-04-25 15:07:43'),('a1fb1e95-8cd9-4bd5-ab58-f4c78156f249',12,12,1981,172,'zensko','smeda','smede',0,0,'musko',300,'Volim kad mi ljudi priđu opušteno:)',1,40,60,'2026-04-28 11:19:16','2026-04-30 22:50:02'),('a79e359c-0938-405d-b5d8-caf8e50328ec',30,4,2004,174,'zensko','smeda','smede',0,0,'musko',300,'Nek me pita kakvu kavu pijem!!',1,23,30,'2026-04-15 23:07:25','2026-04-21 00:52:50'),('b9ebf69d-6f9e-468c-89e4-0306a1e8275e',2,6,1990,185,'musko','smeda','zelene',0,1,'musko',300,'Pitaj me o mom zadnjem putovanju!',1,30,40,'2026-04-28 11:28:15','2026-04-28 11:28:15');
/*!40000 ALTER TABLE `user_profiles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `display_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `password_hash` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_premium` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `is_banned` tinyint(1) NOT NULL DEFAULT '0',
  `push_token` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `last_seen_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_users_username` (`username`),
  UNIQUE KEY `uq_users_email` (`email`),
  KEY `idx_users_active` (`is_active`,`is_banned`),
  KEY `idx_users_last_seen` (`last_seen_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES ('153b31c2-15f4-4c73-83c9-a5e8c701f06e','ivan','Ivan',NULL,'$2a$10$QTkz2LgBsuOcJFOiAsb8Hebf5aqsqp7HsFEm9J5GmsPJibJtLou5a',0,1,0,NULL,'2026-04-28 11:25:30','2026-04-30 22:59:05','2026-04-30 22:59:05'),('6acfaccb-bd78-4fa0-84fa-587efc6f1cba','lorna2','Lorna2',NULL,'$2a$10$3WIq/xzBUDY8vzmmfjRkUOgPCOg8.4RjCk7I2YyP3N9zVXYswD4nS',0,1,0,NULL,'2026-04-25 15:07:43','2026-04-30 22:58:14','2026-04-30 22:58:15'),('a1fb1e95-8cd9-4bd5-ab58-f4c78156f249','vera','Vera',NULL,'$2a$10$.WZZ1whGL3YIVOS9qR1pne1539t0.Q/2fnC7/ftJ0o1LF9vclXAA.',0,1,0,NULL,'2026-04-28 11:19:16','2026-04-30 22:55:49','2026-04-30 22:55:49'),('a79e359c-0938-405d-b5d8-caf8e50328ec','lorna','Lorna',NULL,'$2a$10$GmT9Jw49G6pgTqml0ve3W./FFAgpSVlOEJoLlg1KGMI5XlXbiGsH2',1,1,0,NULL,'2026-04-15 23:07:25','2026-04-30 22:52:48','2026-04-30 22:52:49'),('b9ebf69d-6f9e-468c-89e4-0306a1e8275e','matko','Matko',NULL,'$2a$10$sgA7aXi6f.ys5GNRgpd92.78xtWyQtmNuXlsZbodLIMpQZXTopfoa',0,1,0,NULL,'2026-04-28 11:28:15','2026-04-30 22:54:11','2026-04-30 22:54:12');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-04-30 23:23:02

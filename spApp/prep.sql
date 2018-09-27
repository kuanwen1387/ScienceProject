DROP TABLE IF EXISTS `WSJPrep`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `WSJPrep` (
  `text` varchar(500) NOT NULL,
  `favouriteCount` int(11) NOT NULL DEFAULT '0',
  `created` datetime NOT NULL,
  `id` varchar(50) NOT NULL DEFAULT '0',
  `screenName` varchar(20) NOT NULL,
  `retweetCount` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

DROP TABLE IF EXISTS `BWPrep`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `BWPrep` (
  `text` varchar(500) NOT NULL,
  `favouriteCount` int(11) NOT NULL DEFAULT '0',
  `created` datetime NOT NULL,
  `id` varchar(50) NOT NULL DEFAULT '0',
  `screenName` varchar(20) NOT NULL,
  `retweetCount` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

DROP TABLE IF EXISTS `businessPrep`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `businessPrep` (
  `text` varchar(500) NOT NULL,
  `favouriteCount` int(11) NOT NULL DEFAULT '0',
  `created` datetime NOT NULL,
  `id` varchar(50) NOT NULL DEFAULT '0',
  `screenName` varchar(20) NOT NULL,
  `retweetCount` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

DROP TABLE IF EXISTS `FinancialTimesPrep`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `FinancialTimesPrep` (
  `text` varchar(500) NOT NULL,
  `favouriteCount` int(11) NOT NULL DEFAULT '0',
  `created` datetime NOT NULL,
  `id` varchar(50) NOT NULL DEFAULT '0',
  `screenName` varchar(20) NOT NULL,
  `retweetCount` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

DROP TABLE IF EXISTS `BBCBusinessPrep`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `BBCBusinessPrep` (
  `text` varchar(500) NOT NULL,
  `favouriteCount` int(11) NOT NULL DEFAULT '0',
  `created` datetime NOT NULL,
  `id` varchar(50) NOT NULL DEFAULT '0',
  `screenName` varchar(20) NOT NULL,
  `retweetCount` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
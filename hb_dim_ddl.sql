/***********************************************
** DATA ENGINEERING PLATFORMS
** File: hb_dim_ddl.sql
** Desc: Creation of the dimensional Model (DDL) for Final Project
** Auth: Amy Tramontozzi, William Yeh, Ron Chen, Emily Hong
** Date: 12/11/2024
************************************************/
SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ALLOW_INVALID_DATES';
SET SQL_SAFE_UPDATES=0; 

-- -----------------------------------------------------
-- Schema hbdim
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `hbdim` DEFAULT CHARACTER SET utf16 ;
USE `hbdim` ;

-- -----------------------------------------------------
-- Table `hbdim`.`dimtime`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `hbdim`.`dimtime` (
  `dateId` BIGINT(20) NOT NULL,
  `date` DATE NOT NULL,
  `year` SMALLINT NOT NULL,                     -- Year (e.g., 2023)
  `month` VARCHAR(15) NOT NULL,                 -- Month name (e.g., 'July')
  `day_of_month` TINYINT NOT NULL,               -- Day of the month (1-31)
  PRIMARY KEY (`dateId`),
  UNIQUE INDEX `date` (`date` ASC))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8;

-- -----------------------------------------------------
-- Table `hbdim`.`numbers`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `hbdim`.`numbers` (
  `number` BIGINT(20) NULL DEFAULT NULL)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8;

-- -----------------------------------------------------
-- Table `hbdim`.`numbers_small`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `hbdim`.`numbers_small` (
  `number` INT(11) NULL DEFAULT NULL)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8;

-- -----------------------------------------------------
-- Table `hbdim`.`dimCustomers`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `hbdim`.`dimCustomers` (
  `customerNumber` INT PRIMARY KEY,
  `customerName` VARCHAR(50) NOT NULL,
  `customerLastName` VARCHAR(50) NOT NULL,
  `is_repeated_guest` SMALLINT(1) NOT NULL,
  `previous_cancellations` SMALLINT(2) NOT NULL,
  `previous_bookings_not_canceled` SMALLINT(2) NOT NULL,
  `phone` VARCHAR(50) NOT NULL,
  `customer_type` VARCHAR(50) NOT NULL, 
  `country` VARCHAR(30) NOT NULL)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8;

-- -----------------------------------------------------
-- Table `hbdim`.`dimEmployees`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `hbdim`.`dimEmployees` (
  `employeeNumber` INT(3) NOT NULL,
  `lastName` VARCHAR(50) NOT NULL,
  `firstName` VARCHAR(50) NOT NULL,
  PRIMARY KEY (`employeeNumber`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8;


-- -----------------------------------------------------
-- Table `hbdim`.`dimWeather`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `hbdim`.`dimWeather` (
    `weather_key` INT PRIMARY KEY,       -- Surrogate key
    `temp_max` FLOAT,
    `temp_min` FLOAT,
    `temperature` FLOAT NOT NULL,
    `feels_like_max` FLOAT,
    `feels_like_min` FLOAT,
    `feels_like` FLOAT,
    `dew_point` FLOAT,
    `humidity` FLOAT,
    `precipitation` FLOAT NOT NULL,
    `precip_probability` TINYINT,
    `precip_coverage` TINYINT,
    `precip_type` VARCHAR(15),
    `wind_gust` FLOAT,
    `wind_speed` FLOAT,
    `wind_direction` FLOAT,
    `sea_level_pressure` FLOAT,
    `cloud_coverage` TINYINT,
    `visibility` FLOAT,
    `solar_radiation` FLOAT,
    `solar_energy` FLOAT,
    `uv_index` TINYINT,
    `moon_phase` FLOAT,
    `description` TEXT)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8;

-- -----------------------------------------------------
-- Table `hbdim`.`dimArtist`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `hbdim`.`dimArtist` (
  `artistID` INT PRIMARY KEY,
  `Name` VARCHAR(100) NOT NULL,
  `Genre` VARCHAR(20) NOT NULL,
  `age` INT(2) NOT NULL)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4;

-- -----------------------------------------------------
-- Table `hbdim`.`dimVenue`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `hbdim`.`dimVenue` (
  `venueID` INT PRIMARY KEY,
  `Name` VARCHAR(100) NOT NULL,
  `capacity` INT(7) NOT NULL)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4;

-- -----------------------------------------------------
-- Table `hbdim`.`dimBooking`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `hbdim`.`dimBooking` (
    `bookingID` INT PRIMARY KEY,       
    `is_canceled` TINYINT(1) NOT NULL,
    `duration_category` TINYINT(1) NOT NULL,
    `lead_time_group` TINYINT(1) NOT NULL,
    `deposit_type` VARCHAR(15) NOT NULL, 
    `adults` TINYINT,
    `children` TINYINT,
    `babies` TINYINT,
    `booking_changes` TINYINT NOT NULL,
    `adr_group` TINYINT(1) NOT NULL,
    `reservation_status` VARCHAR(45) NOT NULL,
    `cancellation_lead_time_category` VARCHAR(15) NULL)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8;

-- -----------------------------------------------------
-- Table `hbdim`.`dimConcert`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `hbdim`.`dimConcert` (
    `concertID` INT PRIMARY KEY,
    `artistID` INT NOT NULL,
    `venueID` INT NOT NULL,
    `dateId` BIGINT(20) NOT NULL,  -- Foreign key to `dimTime`
    UNIQUE (`artistID`, `venueID`, `dateId`), -- Ensures no duplicate concerts for the same artist/venue/date
    FOREIGN KEY (`artistID`) REFERENCES `dimArtist` (`artistID`),
    FOREIGN KEY (`venueID`) REFERENCES `dimVenue` (`venueID`),
    FOREIGN KEY (`dateId`) REFERENCES `dimTime` (`dateId`)
)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4;

-- -----------------------------------------------------
-- Table `hbdim`.`factTripDetails`
-- -----------------------------------------------------

CREATE TABLE IF NOT EXISTS `hbdim`.`factTripDetails` (
  `tripID` INT(11) AUTO_INCREMENT,
  `bookingID` INT NOT NULL,
  `customerNumber` INT(8) NOT NULL,
  `employeeNumber` INT(8) NULL,
  `dateId` BIGINT(20) NOT NULL,
  `weather_key` INT NOT NULL, 
  `artistID` INT(4) NULL,
  `venueID` INT(4) NULL,
  `attended_concert` SMALLINT(1) NOT NULL,
  `concertid` INT NULL,
  PRIMARY KEY (`tripID`),
  INDEX `fk_factTripDetails_dimBooking_idx` (`bookingID` ASC),
  INDEX `fk_factTripDetails_dimCustomers_idx` (`customerNumber` ASC),
  INDEX `fk_factTripDetails_dimEmployees_idx` (`employeeNumber` ASC),
  INDEX `fk_factTripDetails_dimTime_idx` (`dateId` ASC),
  INDEX `fk_factTripDetails_dimWeather_idx` (`weather_key` ASC),
  INDEX `fk_factTripDetails_dimArtist_idx` (`artistID` ASC),
  INDEX `fk_factTripDetails_dimVenue_idx` (`venueID` ASC),
  INDEX `fk_factTripDetails_dimConcert_idx` (`concertID` ASC),
  CONSTRAINT `fk_factTripDetails_dimBooking`
    FOREIGN KEY (`bookingID`)
    REFERENCES `hbdim`.`dimBooking` (`bookingID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_factTripDetails_dimCustomers`
    FOREIGN KEY (`customerNumber`)
    REFERENCES `hbdim`.`dimCustomers` (`customerNumber`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_factTripDetails_dimEmployees`
    FOREIGN KEY (`employeeNumber`)
    REFERENCES `hbdim`.`dimEmployees` (`employeeNumber`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,    
  CONSTRAINT `fk_factTripDetails_dimtime`
    FOREIGN KEY (`dateId`)
    REFERENCES `hbdim`.`dimtime` (`dateId`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_TripOrderDetails_dimWeather`
    FOREIGN KEY (`weather_key`)
    REFERENCES `hbdim`.`dimWeather` (`weather_key`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_TripOrderDetails_dimArtist`
    FOREIGN KEY (`artistID`)
    REFERENCES `hbdim`.`dimArtist` (`artistID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_TripOrderDetails_dimVenue`
    FOREIGN KEY (`venueID`)
    REFERENCES `hbdim`.`dimVenue` (`venueID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_factTripDetails_dimConcert`
    FOREIGN KEY (`concertID`)
    REFERENCES `hbdim`.`dimConcert` (`ConcertID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8;

SHOW WARNINGS;

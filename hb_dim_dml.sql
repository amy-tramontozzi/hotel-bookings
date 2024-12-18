/***********************************************
** DATA ENGINEERING PLATFORMS (MSCA 31012)
** File: hb_dim_dml.sql
** Desc: Populating data in the dimensional Model (DML) for Final Project
** Auth: Amy Tramontozzi, William Yeh, Ron Chen, Emily Hong
** Date: 12/11/2024
************************************************/

USE hbdim;
-- -----------------------------------------------------
-- Populate Time dimension
-- -----------------------------------------------------

INSERT INTO numbers_small VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);

INSERT INTO numbers
SELECT 
    thousands.number * 1000 + hundreds.number * 100 + tens.number * 10 + ones.number
FROM
    numbers_small thousands,
    numbers_small hundreds,
    numbers_small tens,
    numbers_small ones
LIMIT 1000000;

INSERT INTO dimtime (dateId, date)
SELECT 
    number,
    DATE_ADD('2015-01-01',
        INTERVAL number DAY)
FROM
    numbers
WHERE
    DATE_ADD('2015-01-01',
        INTERVAL number DAY) BETWEEN '2015-01-01' AND '2017-12-31'
ORDER BY number;

UPDATE dimtime 
SET 
    month = DATE_FORMAT(date, '%M'),
    year = DATE_FORMAT(date, '%Y'),
    day_of_month = DATE_FORMAT(date, '%d');

-- Create a staging table for the concert data
CREATE TABLE IF NOT EXISTS hbdim.stagingConcert (
    Date DATE,        -- Concert date
    artistid INT,     -- Artist ID
    venueid INT,      -- Venue ID
    concertid INT     -- Concert ID or any other relevant column
);

-- Insert data into the dimConcert table, associating each concert date with the corresponding dateId
-- Insert data into dimConcert, ensuring uniqueness for each combination
INSERT INTO hbdim.dimConcert (dateId, venueID, artistID, concertID)
SELECT
    s.venueid,
    s.artistid,
    s.concertid,
    t.dateId  -- Select the dateId from dimtime
FROM hbdim.stagingConcert s
LEFT JOIN hbdim.dimtime t  -- Alias for the dimtime table
ON s.Date = t.date;  -- Use ON instead of WHERE for joining

CREATE TABLE IF NOT EXISTS `hbdim`.`factstagetrip` (
  `tripID` INT(11) AUTO_INCREMENT PRIMARY KEY,
  `bookingID` INT NOT NULL,
  `customerNumber` INT(8) NOT NULL,
  `employeeNumber` INT(8) NULL DEFAULT NULL,
  `date` DATE NOT NULL,
  `weather_key` INT NOT NULL, 
  `artistID` INT NULL DEFAULT NULL,
  `venueID` INT NULL DEFAULT NULL,
  `attended_concert` SMALLINT(1) NOT NULL,
  `concertID` INT NULL DEFAULT NULL
);

INSERT INTO hbdim.factTripDetails (bookingID, customerNumber, employeeNumber, weather_key, artistID, venueID, concertID, attended_concert, dateID)
SELECT DISTINCT
    s.bookingID,
    s.customerNumber,
    s.employeeNumber,
    s.weather_key,
    s.artistID,
    s.venueID,
    s.concertID,
    s.attended_concert,
    t.dateId  -- Select the dateId from dimtime
FROM hbdim.factstagetrip s
LEFT JOIN hbdim.dimtime t  -- Alias for the dimtime table
ON s.Date = t.date;  -- Use ON instead of WHERE for joining

SELECT COUNT(*) FROM factTripDetails;
-- END--


-- PASSENGER --

-- update passenger
drop procedure if exists update_passenger;

DELIMITER //

CREATE PROCEDURE update_passenger (
    IN 
    id int(11),
    fname VARCHAR(20),
    lname VARCHAR(20),
    DOB DATE,
    email VARCHAR(50),
    telNo VARCHAR(15),
    Address_Street VARCHAR(100),
    Address_City VARCHAR(50),
    Address_Postcode VARCHAR(10),
    Address_State VARCHAR(50),
    countryName VARCHAR(200)
    )
BEGIN

UPDATE passenger 
SET FirstName = fname, LastName = lname,
DOB = DOB, email = email, telNo = telNo, 
Address_Street = Address_Street, Address_City = Address_City, 
Address_Postcode = Address_Postcode, Address_State = Address_State, 
countryName = countryName
WHERE id = passenger_id;

END //

DELIMITER ;

-- Delete Passenger
drop procedure if exists delete_passenger;

DELIMITER //

CREATE PROCEDURE delete_passenger (
    IN 
    id int(11))
BEGIN

DELETE FROM passenger 
WHERE id = passenger_id;

END //

DELIMITER ;

-- insert passenger

drop procedure if exists insert_passenger;

DELIMITER //

CREATE PROCEDURE insert_passenger (
    IN FirstName_I VARCHAR(20),
    LastName_I VARCHAR(20),
    DOB_I DATE,
    email_I VARCHAR(50),
    telNo_I VARCHAR(15),
    Address_Street_I VARCHAR(100),
    Address_City_I VARCHAR(50),
    Address_Postcode_I VARCHAR(10),
    Address_State_I VARCHAR(50),
    Country_I VARCHAR(200)
    )
BEGIN

SET @id =  (SELECT MAX(passenger_id)+1 FROM passenger);


INSERT INTO passenger
VALUES (@id, FirstName_I, LastName_I,DOB_I, email_I,
telNo_I, Address_Street_I, Address_City_I, Address_Postcode_I, Address_State_I, Country_I);

END //

DELIMITER ;


-- FLIGHT --
drop procedure if exists update_flight;

DELIMITER //

CREATE PROCEDURE update_flight (
    IN 
    id int(11),
    departureTerminal varchar(1),
    departureTime time,
    arrivalTime time,
    aircraftRegNo varchar(6),
    route_id int(11),
    flightDate date
    )
BEGIN

UPDATE flight 
SET departureTerminal = departureTerminal, departureTime = departureTime,
arrivalTime = arrivalTime, aircraftRegNo = aircraftRegNo, route_id = route_id, 
flightDate = flightDate
WHERE id = flightNumber;

END //

DELIMITER ;

-- delete flight
drop procedure if exists delete_flight;

DELIMITER //

CREATE PROCEDURE delete_flight (
    IN 
    id int(11))
BEGIN

DELETE FROM flight 
WHERE id = flightNumber;

END //

DELIMITER ;

-- Insert into flight
drop procedure if exists insert_flight;

DELIMITER //

CREATE PROCEDURE insert_flight (
    IN 
    departureTerminal varchar(1),
    departureTime time,
    arrivalTime time,
    aircraftRegNo varchar(6),
    route_id int(11),
    flightDate date
    )
BEGIN

SET @flightNumber =  (SELECT MAX(flightNumber)+1 FROM flight );


INSERT INTO flight 
VALUES (@flightNumber, departureTerminal, departureTime, arrivalTime, aircraftRegNo, route_id, flightDate);

END //

DELIMITER ;


-- TICKET -- 

-- Update Ticket
drop procedure if exists update_ticket;

DELIMITER //

CREATE PROCEDURE update_ticket (
    IN 
    id varchar(7),
    purchaseDate date,
    seatNo varchar(3),
    flightNo int(11),
    passenger_id int(11),
    price int(11))
BEGIN

SET SQL_SAFE_UPDATES = 0;

UPDATE ticket 
SET purchaseDate = purchaseDate,
seatNo = seatNo, flightNo = flightNo, 
passenger_id = passenger_id, price = price
WHERE id = reservationID;

END //

DELIMITER ;



-- Delete ticket
drop procedure if exists delete_ticket;

DELIMITER //

CREATE PROCEDURE delete_ticket (
    IN 
    id varchar(7))
BEGIN
DELETE FROM ticket
WHERE id = reservationID;

END //

DELIMITER ;



-- insert ticket
drop procedure if exists insert_ticket;

DELIMITER //

CREATE PROCEDURE insert_ticket (
    IN 
    reservationID varchar(7),
    purchaseDate date,
    seatNo varchar(3),
    flightNo int(11),
    passenger_id int(11))
BEGIN
DECLARE today_date DATE;
DECLARE date_diff INT;
DECLARE flight_date DATE;
SELECT flightDate INTO flight_date FROM flight
WHERE flightNumber = flightNo;

SELECT CURRENT_DATE() INTO today_date;
SELECT DATEDIFF(flight_date, today_date)	INTO date_diff;
IF date_diff >= 90 THEN
	INSERT INTO ticket(reservationID, purchaseDate, seatNo, flightNo, passenger_id, price)
	VALUES (reservationID, purchaseDate, seatNo, flightNo, passenger_id, 30);
ELSE
	IF date_diff > 0 THEN
		INSERT INTO ticket(reservationID, purchaseDate, seatNo, flightNo, passenger_id, price)
		VALUES (reservationID, purchaseDate, seatNo, flightNo, passenger_id, 400 - (date_diff/90) * 370);
	ELSE
		INSERT INTO ticket(reservationID, purchaseDate, seatNo, flightNo, passenger_id, price)
		VALUES (reservationID, purchaseDate, seatNo, flightNo, passenger_id, 0);
	END IF;
END IF;
END //

DELIMITER ;



-- MEMBERSHIP LEVEL --
-- Update membershipLevel
drop procedure if exists update_membership_level;

DELIMITER //

CREATE PROCEDURE update_membership_level (
    IN 
    id varchar(50),
   levelFeatures varchar(300),
   levelPoints int(11)
    )
BEGIN

UPDATE membershipLevel 
SET levelFeatures = levelFeatures,
levelPoints = levelPoints
WHERE id = memberLevel;

END //

DELIMITER ;

-- Delete membershipLevel
drop procedure if exists delete_membership_level;

DELIMITER //

CREATE PROCEDURE delete_membership_level (
    IN 
    id varchar(50)
    )
BEGIN

DELETE FROM membershipLevel 
WHERE id = memberLevel;

END //

DELIMITER ;


-- Insert membershipLevel
drop procedure if exists insert_membership_level;
DELIMITER //

CREATE PROCEDURE insert_membership_level (
    IN 
    id varchar(50),
   levelFeatures varchar(300),
   levelPoints int(11)
    )
BEGIN

INSERT INTO membershipLevel 
VALUES (id, levelFeatures, levelPoints);

END //



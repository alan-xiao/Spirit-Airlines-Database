USE airportdb;


-- Looking up reservations 
DROP PROCEDURE IF EXISTS passenger_user_res;
DELIMITER //
CREATE PROCEDURE passenger_user_res (
	IN res_ID VARCHAR(7)
)
BEGIN
SELECT reservationID, FirstName, LastName, purchaseDate, concat('$',ticket.price) AS price, numPoints AS yourPoints, seatNo, 
ticket.flightNo, departureTerminal, departureTime, arrivalTime,  
flightDate, a2.airportCity AS departureCity, a2.airportName AS departureAirport, 
a1.airportCity AS arrivalCity, a1.airportName AS arrivalAirport FROM passenger AS p
INNER JOIN ticket
ON p.passenger_id = ticket.passenger_id
INNER JOIN flight
ON flight.flightNumber = ticket.flightNo
INNER JOIN route
ON flight.route_id = route.route_id
INNER JOIN airport AS a1
ON route.arrivalIata = a1.codeIataAirport
INNER JOIN airport AS a2
ON route.departureIata = a2.codeIataAirport
LEFT JOIN loyaltylevel AS l
ON l.passenger_id = p.passenger_id
WHERE ticket.reservationID = res_ID;
END //
DELIMITER ;

-- Inserting passenger into the passenger table
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


-- Looking up flights given origin and destination
DROP PROCEDURE IF EXISTS find_destination;
DELIMITER //
CREATE PROCEDURE find_destination (
	IN city_origin VARCHAR(50), city_destination VARCHAR(50)
)
BEGIN
SELECT flightNumber, flightDate, a2.airportCity AS departureCity, a2.airportName AS departureAirport, 
a1.airportCity AS arrivalCity, a1.airportName AS arrivalAirport, departureTerminal, departureTime, arrivalTime  FROM flight
INNER JOIN route
ON flight.route_id = route.route_id
INNER JOIN airport AS a1
ON route.arrivalIata = a1.codeIataAirport
INNER JOIN airport AS a2
ON route.departureIata = a2.codeIataAirport
WHERE a2.airportCity = city_origin
AND a1.airportCity = city_destination;
END //

DELIMITER ;

-- Looking up flights given origin

DROP PROCEDURE IF EXISTS find_destination_origin;
DELIMITER //
CREATE PROCEDURE find_destination_origin (
	IN city_origin VARCHAR(50)
)
BEGIN
SELECT flightNumber, flightDate, a2.airportCity AS departureCity, a2.airportName AS departureAirport, 
a1.airportCity AS arrivalCity, a1.airportName AS arrivalAirport, departureTerminal, departureTime, arrivalTime  FROM flight
INNER JOIN route
ON flight.route_id = route.route_id
INNER JOIN airport AS a1
ON route.arrivalIata = a1.codeIataAirport
INNER JOIN airport AS a2
ON route.departureIata = a2.codeIataAirport
WHERE a2.airportCity = city_origin;
END //

DELIMITER ;


-- Looking up flights given destination
DROP PROCEDURE IF EXISTS find_destination_destination;
DELIMITER //
CREATE PROCEDURE find_destination_destination (
	IN city_destination VARCHAR(50)
)
BEGIN
SELECT flightNumber, flightDate, a2.airportCity AS departureCity, a2.airportName AS departureAirport, 
a1.airportCity AS arrivalCity, a1.airportName AS arrivalAirport, departureTerminal, departureTime, arrivalTime  FROM flight
INNER JOIN route
ON flight.route_id = route.route_id
INNER JOIN airport AS a1
ON route.arrivalIata = a1.codeIataAirport
INNER JOIN airport AS a2
ON route.departureIata = a2.codeIataAirport
WHERE a1.airportCity = city_destination;
END //

DELIMITER ;


-- Looking up all flights
DROP PROCEDURE IF EXISTS find_destination_all;
DELIMITER //
CREATE PROCEDURE find_destination_all (
)
BEGIN
SELECT flightNumber, flightDate, a2.airportCity AS departureCity, a2.airportName AS departureAirport, 
a1.airportCity AS arrivalCity, a1.airportName AS arrivalAirport, departureTerminal, departureTime, arrivalTime 
 FROM flight
INNER JOIN route
ON flight.route_id = route.route_id
INNER JOIN airport AS a1
ON route.arrivalIata = a1.codeIataAirport
INNER JOIN airport AS a2
ON route.departureIata = a2.codeIataAirport;
END //

DELIMITER ;


-- Update the ticket table to include price (scaled by a factor depending on purchase date)

DROP PROCEDURE IF EXISTS passenger_purchase_ticket;
DELIMITER //
CREATE PROCEDURE passenger_purchase_ticket (
	IN input_flight_number INT, input_res_number VARCHAR(7), input_email VARCHAR(50), input_seat VARCHAR(3)
)
BEGIN
DECLARE input_passenger_id INT;
DECLARE today_date DATE;
DECLARE date_diff INT;
DECLARE flight_date DATE;
SELECT flightDate INTO flight_date FROM flight
WHERE flightNumber = input_flight_number;
SELECT passenger_id INTO input_passenger_id FROM passenger AS p 
WHERE p.email = input_email;
SELECT CURRENT_DATE() INTO today_date;
SELECT DATEDIFF(flight_date, today_date)	INTO date_diff;
IF date_diff >= 90 THEN
	INSERT INTO ticket(reservationID, purchaseDate, seatNo, flightNo, passenger_id, price)
	VALUES (input_res_number, today_date, input_seat, input_flight_number, input_passenger_id, 30);
ELSE
	IF date_diff > 0 THEN
		INSERT INTO ticket(reservationID, purchaseDate, seatNo, flightNo, passenger_id, price)
		VALUES (input_res_number, today_date, input_seat, input_flight_number, input_passenger_id, 400 - (date_diff/90) * 370);
	ELSE
		INSERT INTO ticket(reservationID, purchaseDate, seatNo, flightNo, passenger_id, price)
		VALUES (input_res_number, today_date, input_seat, input_flight_number, input_passenger_id, 0);
	END IF;
END IF;
END //

DELIMITER ;

-- Updating loyalty
DROP TRIGGER IF EXISTS update_loyalty;
DELIMITER //

CREATE TRIGGER update_loyalty AFTER INSERT ON ticket
FOR EACH ROW
BEGIN
DECLARE points INT DEFAULT 0;
DECLARE finished INT DEFAULT 0;
DECLARE indexPoints INT DEFAULT 0;
DECLARE newLevel VARCHAR(50);
DECLARE curPoints CURSOR FOR 
	SELECT levelPoints FROM membershiplevel ORDER BY levelPoints DESC;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;
IF NOT EXISTS(SELECT * FROM loyaltylevel WHERE passenger_id = NEW.passenger_id)
THEN
INSERT INTO loyaltylevel (memberLevel, passenger_id, numPoints) VALUES ('Bronze', NEW.passenger_id, 0);
END IF;
SELECT COUNT(passenger_id)*10 INTO points FROM ticket
GROUP BY passenger_id
HAVING passenger_id = NEW.passenger_id;
UPDATE loyaltylevel SET numPoints = points
WHERE passenger_id = NEW.passenger_id;
OPEN curPoints;
getPoints: LOOP
	FETCH curPoints INTO indexPoints;
    IF finished = 1 THEN 
		LEAVE getPoints;
	ELSEIF indexPoints <= points THEN 
		LEAVE getPoints;
	END IF;
END LOOP;
CLOSE curPoints;
SELECT memberlevel INTO newLevel FROM membershiplevel WHERE levelPoints = indexPoints;
UPDATE loyaltylevel
SET memberLevel = newLevel
WHERE passenger_id = NEW.passenger_id;
END //
DELIMITER ;


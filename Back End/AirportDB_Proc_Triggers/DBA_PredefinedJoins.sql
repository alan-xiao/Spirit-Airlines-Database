USE airportdb;

DROP PROCEDURE IF EXISTS passenger_info;
DELIMITER //

CREATE PROCEDURE passenger_info (
)
BEGIN
SELECT p.passenger_id, FirstName, LastName, email, memberLevel, numPoints, COUNT(p.passenger_id) AS tickets_purchased, SUM(t.price) AS money_paid FROM passenger AS p
INNER JOIN loyaltylevel AS l
ON l.passenger_id = p.passenger_id
INNER JOIN ticket AS t
ON p.passenger_id = t.passenger_id
GROUP BY p.passenger_id, FirstName, LastName, email, memberLevel, numPoints
ORDER BY p.passenger_id;
END //

DELIMITER ;


DROP PROCEDURE IF EXISTS route_info;
DELIMITER //

CREATE PROCEDURE route_info (
)
BEGIN
SELECT route_id, arrivalIata, departureIata, flights, COUNT(route_id) AS tickets, concat('$',IFNULL(SUM(price), 0)) AS money_made FROM
(SELECT r.route_id, arrivalIata, departureIata, COUNT(r.route_id) AS flights, flightNumber FROM route AS r 
LEFT JOIN flight AS f
ON r.route_id = f.route_id
GROUP BY r.route_id, flightNumber) AS t1
LEFT JOIN ticket AS t
ON t.flightNo = t1.flightNumber
GROUP BY route_id, flightNumber ;
END //

DELIMITER ;

DROP PROCEDURE IF EXISTS aircraft_info;
DELIMITER //

CREATE PROCEDURE aircraft_info (
)
BEGIN
SELECT t1.aircraftRegNo, planeModel, flights_taken, COUNT(reservationID) AS total_passengers, concat('$',IFNULL(SUM(price),0)) AS money_made FROM 
(SELECT a.aircraftRegNo, planeModel, COUNT(a.aircraftRegNo) AS flights_taken FROM aircraft AS a
LEFT JOIN flight AS f1
ON f1.aircraftRegNo = a.aircraftRegNo
GROUP BY a.aircraftRegNo) AS t1
LEFT JOIN flight AS f2
ON f2.aircraftRegNo = t1.aircraftRegNo
LEFT JOIN ticket AS t
ON flightNumber = t.flightNo
GROUP BY t1.aircraftRegNo;
END //

DELIMITER ;
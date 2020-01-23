-- Regional Schools Database

-- create the database
DROP DATABASE IF EXISTS AirportDB;
CREATE DATABASE AirportDB;

-- select the database
USE AirportDB;

CREATE TABLE airport(
  codeIataAirport VARCHAR(3) PRIMARY KEY,
  airportName VARCHAR(100) NOT NULL, 
  codeIataCity VARCHAR(3) NOT NULL,
  latitudeAirport VARCHAR(20),
  longitudeAirport VARCHAR(20),
  timezone VARCHAR(50) NOT NULL,
  airportCity VARCHAR(50) NOT NULL);

CREATE TABLE aircraft(
  aircraftRegNo VARCHAR(6) PRIMARY KEY,
  productionLine VARCHAR(100) NOT NULL,
  planeModel VARCHAR(4) NOT NULL,
  registrationDate DATE NOT NULL,
  enginesCount INT NOT NULL,
  Num_seats INT NOT NULL);
  
CREATE TABLE route(
  route_id INT PRIMARY KEY,
  arrivalIata VARCHAR(3) NOT NULL, 
  departureIata VARCHAR(3) NOT NULL,
  price INT NOT NULL,
  CONSTRAINT origin_fk_airport
  FOREIGN KEY (departureIata)
  REFERENCES airport (codeIataAirport)
  ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT destination_fk_airport
  FOREIGN KEY (arrivalIata)
  REFERENCES airport (codeIataAirport)
  ON UPDATE CASCADE ON DELETE CASCADE);

CREATE TABLE flight(
  flightNumber INT PRIMARY KEY,
  departureTerminal VARCHAR(1),
  departureTime TIME NOT NULL,
  arrivalTime TIME NOT NULL,
  aircraftRegNo VARCHAR(6) NOT NULL,
  route_id INT NOT NULL,
  flightDate DATE NOT NULL,
  CONSTRAINT flight_fk_aircraft
  FOREIGN KEY (aircraftRegNo)
  REFERENCES aircraft (aircraftRegNo)
  ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT flight_fk_route
  FOREIGN KEY (route_id)
  REFERENCES route (route_id)
  ON UPDATE CASCADE ON DELETE CASCADE);
 

CREATE TABLE country(
  countryName VARCHAR(200) PRIMARY KEY
  );
 
 
 CREATE TABLE passenger(
  passenger_id INT PRIMARY KEY,
  FirstName VARCHAR(20) NOT NULL,
  LastName VARCHAR(20) NOT NULL,
  DOB DATE NOT NULL, 
  email VARCHAR(50) NOT NULL, 
  telNo VARCHAR(15)  NOT NULL,
  Address_Street VARCHAR(100) NOT NULL,
  Address_City VARCHAR(50) NOT NULL,
  Address_Postcode VARCHAR(10) NOT NULL,
  Address_State VARCHAR(50) NOT NULL,
  countryName VARCHAR(200) NOT NULL,
  CONSTRAINT passenger_fk_country
  FOREIGN KEY (countryName)
  REFERENCES country (countryName)
  ON UPDATE RESTRICT ON DELETE RESTRICT
  );
  

 
CREATE TABLE ticket(
  reservationID VARCHAR(7) NOT NULL,
  purchaseDate DATE NOT NULL,
  seatNo VARCHAR(3),
  flightNo INT NOT NULL,
  passenger_id INT(11) NOT NULL,
  price INT(11) NOT NULL,
  CONSTRAINT ticket_fk_flight
  FOREIGN KEY (flightNo)
  REFERENCES flight (flightNumber)
  ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT ticket_fk_passenger
  FOREIGN KEY (passenger_id)
  REFERENCES passenger (passenger_id)
  ON UPDATE CASCADE ON DELETE CASCADE
  );
  

CREATE TABLE membershipLevel (
  memberLevel VARCHAR(50) PRIMARY KEY,
  levelFeatures VARCHAR(300) NOT NULL,
  levelPoints INT NOT NULL
);
 
 
CREATE TABLE loyaltyLevel (
  memberLevel VARCHAR(50),
  passenger_id INT,
  numPoints INT NOT NULL,
  CONSTRAINT loyaltyLevel_fk_membershipLevel
  FOREIGN KEY (memberLevel)
  REFERENCES membershipLevel (memberLevel)
  ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT loyaltyLevel_fk_passenger
  FOREIGN KEY (passenger_id)
  REFERENCES passenger (passenger_id)
  ON UPDATE CASCADE ON DELETE CASCADE,
  primary key(memberLevel,passenger_id)
);





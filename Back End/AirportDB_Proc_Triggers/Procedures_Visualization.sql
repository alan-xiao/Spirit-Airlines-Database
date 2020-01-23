USE airportdb;


-- The number of flights on a given day
drop procedure if exists timeseries_flights;
delimiter $$ 

create procedure timeseries_flights()
deterministic
begin
select flightDate, count(flightNumber) AS 'Number of Flights' from flight
group by flightDate;
end$$

delimiter ;


-- Gets the revenue for the given month of the year
drop procedure if exists monthly_timeseries;

delimiter $$ 

create procedure monthly_timeseries()
deterministic
begin
select YEAR(purchaseDate) AS Year, MONTH(purchaseDate) AS Month, sum(price) as Revenue, count(reservationID) as 'Number of Tickets', count(distinct passenger_id) as 'Number of Customers'
from ticket
group by YEAR(purchaseDate), MONTH(purchaseDate);


end$$

delimiter ;


-- The total number of customers
drop procedure if exists total_customers;
delimiter $$ 

create procedure total_customers()
deterministic
begin
select count(*) AS 'Total Number of Customers' from passenger;
end$$

delimiter ;


-- The total revenue
drop procedure if exists total_revenue;
delimiter $$ 

create procedure total_revenue()
deterministic
begin
select sum(price) AS 'Total Revenue' from ticket;
end$$

delimiter ;


-- The total tickets
drop procedure if exists total_tickets;
delimiter $$ 

create procedure total_tickets()
deterministic
begin
select count(reservationID) from ticket;
end$$

delimiter ;


-- Customers by loyalty level
drop procedure if exists cust_loyaltyLevel;
delimiter $$ 

create procedure cust_loyaltyLevel()
deterministic
begin
select memberLevel, COUNT(passenger_id) AS 'Number of Customers' from loyaltyLevel
GROUP BY memberLevel ;
end$$

delimiter ;




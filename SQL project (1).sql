CREATE DATABASE flight_analysis;
USE flight_analysis;

CREATE TABLE airlines (
    IATA_CODE VARCHAR(10) PRIMARY KEY,
    AIRLINE_NAME VARCHAR(255)
);

CREATE TABLE airports (
    IATA_CODE VARCHAR(10) PRIMARY KEY,
    AIRPORT_NAME VARCHAR(255),
    CITY VARCHAR(100),
    STATE VARCHAR(100),
    COUNTRY VARCHAR(100),
    LATITUDE FLOAT,
    LONGITUDE FLOAT
);

CREATE TABLE flights (
    YEAR INT,
    MONTH INT,
    DAY INT,
    DAY_OF_WEEK INT,
    AIRLINE VARCHAR(10),
    FLIGHT_NUMBER VARCHAR(10),
    TAIL_NUMBER VARCHAR(50),
    ORIGIN_AIRPORT VARCHAR(10),
    DESTINATION_AIRPORT VARCHAR(10),
    SCHEDULED_DEPARTURE INT,
    DEPARTURE_TIME INT,
    DEPARTURE_DELAY INT,
    SCHEDULED_ARRIVAL INT,
    ARRIVAL_TIME INT,
    ARRIVAL_DELAY INT,
    DISTANCE INT,
    CANCELLED INT,
    DIVERTED INT
);

ALTER TABLE flights
ADD COLUMN FLIGHT_DATE DATE;

UPDATE flights
SET FLIGHT_DATE = STR_TO_DATE(CONCAT(YEAR, '-', MONTH, '-', DAY), '%Y-%m-%d');

DELETE FROM flights
WHERE AIRLINE IS NULL OR ORIGIN_AIRPORT IS NULL OR DESTINATION_AIRPORT IS NULL;

-- Scheduled Departure
ALTER TABLE flights ADD COLUMN SCHEDULED_DEPARTURE_TIME TIME;
UPDATE flights
SET SCHEDULED_DEPARTURE_TIME = STR_TO_DATE(LPAD(SCHEDULED_DEPARTURE, 4, '0'), '%H%i');

-- Scheduled Arrival
ALTER TABLE flights ADD COLUMN SCHEDULED_ARRIVAL_TIME TIME;
UPDATE flights
SET SCHEDULED_ARRIVAL_TIME = STR_TO_DATE(LPAD(SCHEDULED_ARRIVAL, 4, '0'), '%H%i');

-- Departure Time
ALTER TABLE flights ADD COLUMN DEPARTURE_TIME_NEW TIME;
UPDATE flights
SET DEPARTURE_TIME_NEW = STR_TO_DATE(LPAD(DEPARTURE_TIME, 4, '0'), '%H%i');

-- Arrival Time
ALTER TABLE flights ADD COLUMN ARRIVAL_TIME_NEW TIME;
UPDATE flights
SET ARRIVAL_TIME_NEW = STR_TO_DATE(
    CASE 
        WHEN ARRIVAL_TIME = 2400 THEN '0000'
        ELSE LPAD(ARRIVAL_TIME, 4, '0')
    END,
    '%H%i'
)
WHERE ARRIVAL_TIME IS NOT NULL;


CREATE VIEW master_flight_data AS
SELECT 
    f.FLIGHT_DATE,
    f.DAY_OF_WEEK,
    f.AIRLINE,
    a.AIRLINE_NAME,
    f.ORIGIN_AIRPORT,
    ao.AIRPORT_NAME AS ORIGIN_AIRPORT_NAME,
    ao.CITY AS ORIGIN_CITY,
    ao.STATE AS ORIGIN_STATE,
    f.DESTINATION_AIRPORT,
    ad.AIRPORT_NAME AS DESTINATION_AIRPORT_NAME,
    ad.CITY AS DESTINATION_CITY,
    ad.STATE AS DESTINATION_STATE,
    f.SCHEDULED_DEPARTURE_TIME,
    f.DEPARTURE_TIME_NEW,
    f.DEPARTURE_DELAY,
    f.SCHEDULED_ARRIVAL_TIME,
    f.ARRIVAL_TIME_NEW,
    f.ARRIVAL_DELAY,
    f.DISTANCE,
    f.CANCELLED,
    f.DIVERTED
FROM flights 
LEFT JOIN airlines a ON f.AIRLINE = a.IATA_CODE
LEFT JOIN airports ao ON f.ORIGIN_AIRPORT = ao.IATA_CODE
LEFT JOIN airports ad ON f.DESTINATION_AIRPORT = ad.IATA_CODE;

select * from master_flight_Data;
select * from flights;


-- KPI 1

SELECT 'Weekday' AS Day_Type,
       COUNT(*) AS Flight_Count,
       ROUND(AVG(CAST(ARRIVAL_DELAY AS DECIMAL)), 2) AS Avg_Arrival_Delay,
       SUM(CANCELLED) AS Cancelled_Flights,
       sum(case when DEPARTURE_DELAY > 0 then 1 else 0 end) as delayed_departures,
       sum(case when ARRIVAL_DELAY > 0 then 1 else 0 end) as delayed_arrivals 
FROM master_flight_data
WHERE DAY_OF_WEEK BETWEEN 1 AND 5

UNION

SELECT 'Weekend',
       COUNT(*),
       ROUND(AVG(CAST(ARRIVAL_DELAY AS DECIMAL)), 2),
       SUM(CANCELLED),
       sum(case when DEPARTURE_DELAY > 0 then 1 else 0 end) as delayed_departures,
    sum(case when ARRIVAL_DELAY > 0 then 1 else 0 end) as delayed_arrivals 
FROM master_flight_data
WHERE DAY_OF_WEEK IN (6, 7);


-- KPI 2
SELECT 
	airline_name,
    DATE(FLIGHT_DATE) AS flight_date,
    COUNT(*) AS cancelled_flights
FROM master_flight_data
WHERE 
    AIRLINE_NAME = 'JetBlue Airways'
    AND CANCELLED > 0
    AND DAY(FLIGHT_DATE) = 1
    AND FLIGHT_DATE IS NOT NULL
GROUP BY DATE(FLIGHT_DATE)
ORDER BY flight_date;



/*KPI 3 – Delay Analysis by State, City and Week wise*/

select week(flight_date,1) as week_no, master_flight_data.ORIGIN_STATE,flight_analysis.master_flight_data.ORIGIN_CITY,
flight_analysis.master_flight_data.FLIGHT_DATE,airlines.AIRLINE_NAME,
ROUND(AVG(ARRIVAL_DELAY), 2) AS Avg_Arrival_Delay,
ROUND(AVG(DEPARTURE_DELAY), 2) AS Avg_Departure_Delay,
sum(case when flight_analysis.master_flight_data.DEPARTURE_DELAY > 0 then 1 else 0 end) as delayed_departures,
sum(case when flight_analysis.master_flight_data.ARRIVAL_DELAY > 0 then 1 else 0 end) as delayed_arrivals 
from flight_analysis.airports 
inner join flight_analysis.master_flight_data
on flight_analysis.airports.IATA_CODE = flight_analysis.master_flight_data.ORIGIN_AIRPORT
inner join flight_analysis.airlines
on flight_analysis.airlines.IATA_CODE = flight_analysis.master_flight_data.AIRLINE
group by flight_analysis.master_flight_data.FLIGHT_DATE, state,ORIGIN_CITY,ORIGIN_STATE,AIRLINE_NAME;


-- KPI 4:- No. of Airlines with no departure/arrival delay with distance covered between 2500 and 3000. 
SELECT DISTINCT AIRLINE_NAME AS airline_names, count(AIRLINE_NAME) as number_of_airlines
FROM master_flight_data
WHERE DEPARTURE_DELAY <= 0
  AND ARRIVAL_DELAY <= 0
  AND DISTANCE BETWEEN 2500 AND 3000
group by AIRLINE_NAME;

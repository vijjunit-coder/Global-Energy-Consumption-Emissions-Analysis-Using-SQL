CREATE DATABASE ENERGYDB2;
USE ENERGYDB2;

-- 1. country table
CREATE TABLE country (
    CID VARCHAR(10) PRIMARY KEY,
    Country VARCHAR(100) UNIQUE
);

SELECT * FROM COUNTRY;

-- 2. emission_3 table
CREATE TABLE emission_3 (
    country VARCHAR(100),
    energy_type VARCHAR(50),
    year INT,
    emission INT,
    per_capita_emission DOUBLE,
    FOREIGN KEY (country) REFERENCES country(Country)
);

SELECT * FROM EMISSION_3;


-- 3. population table
CREATE TABLE population (
    countries VARCHAR(100),
    year INT,
    Value DOUBLE,
    FOREIGN KEY (countries) REFERENCES country(Country)
);

SELECT * FROM POPULATION;

-- 4. production table
CREATE TABLE production (
    country VARCHAR(100),
    energy VARCHAR(50),
    year INT,
    production INT,
    FOREIGN KEY (country) REFERENCES country(Country)
);


SELECT * FROM PRODUCTION;

-- 5. gdp_3 table
CREATE TABLE gdp_3 (
    Country VARCHAR(100),
    year INT,
    Value DOUBLE,
    FOREIGN KEY (Country) REFERENCES country(Country)
);

SELECT * FROM GDP_3;

-- 6. consumption table
CREATE TABLE consumption (
    country VARCHAR(100),
    energy VARCHAR(50),
    year INT,
    consumption INT,
    FOREIGN KEY (country) REFERENCES country(Country)
);

SELECT * FROM CONSUMPTION;

-- Data Analysis Questions

-- 1.What is the total emission per country for the most recent year available?



    SELECT 
    energy_type, 
    SUM(emission) AS total_emission
FROM 
    emission_3
WHERE 
    year = (SELECT MAX(year) FROM emission_3)
GROUP BY 
    energy_type
ORDER BY 
    total_emission DESC;

-- 2. What are the top 5 countries by GDP in the most recent year?

SELECT
    Country,
    Value AS GDP
FROM
    gdp_3
WHERE
    year = (SELECT MAX(year) FROM gdp_3)
ORDER BY
    Value DESC
LIMIT 5;

-- 3.Compare energy production and consumption by country and year. 

SELECT
    p.country,
    p.year,
    p.total_production,
    c.total_consumption
FROM
    (
        SELECT
            country,
            year,
            SUM(production) AS total_production
        FROM
            production
        GROUP BY
            country,
            year
    ) AS p
INNER JOIN
    (
        SELECT
            country,
            year,
            SUM(consumption) AS total_consumption
        FROM
            consumption
        GROUP BY
            country,
            year
    ) AS c
ON
    p.country = c.country AND p.year = c.year
ORDER BY
    p.country, p.year;
        
-- 4.Which energy types contribute most to emissions across all countries?
        
   SELECT
    energy_type,
    SUM(emission) AS Total_Emissions
FROM
    emission_3
GROUP BY
    energy_type
ORDER BY
    Total_Emissions DESC;
    
   -- Trend Analysis Over Time
   
   -- 5.How have global emissions changed year over year?
   SELECT
    year,
    SUM(emission) AS Total_Global_Emissions
FROM
    emission_3
GROUP BY
    year
ORDER BY
    year;


-- 6.What is the trend in GDP for each country over the given years?

SELECT
    Country,
    year,
    Value AS GDP
FROM
    gdp_3
ORDER BY
    Country,
    year; 

-- 7.How has population growth affected total emissions in each country?

    
    SELECT
    E.country,
    E.year,
    P.Value AS Population,
    SUM(E.emission) AS Total_Emissions
FROM
    emission_3 AS E
JOIN
    population AS P ON E.country = P.countries AND E.year = P.year
GROUP BY
    E.country, E.year, P.Value 
ORDER BY
    E.country, E.year DESC; 
    
  -- 8.  Has energy consumption increased or decreased over the years for major economies?
  
  SELECT
    country,
    year,
    SUM(consumption) AS Total_Consumption 
FROM
    consumption
GROUP BY
    country,
    year
ORDER BY
    country,
    year;
    
    -- 9.What is the average yearly change in emissions per capita for each country
    
    
    WITH YearlyChange AS (
    SELECT 
        country,
        -- Cast to FLOAT to prevent integer truncation
        (CAST(per_capita_emission AS FLOAT) - 
         LAG(CAST(per_capita_emission AS FLOAT)) OVER (PARTITION BY country ORDER BY year)) 
         AS Yearly_Change_Per_Capita
    FROM 
        emission_3
)
SELECT 
    country,
    AVG(Yearly_Change_Per_Capita) AS Average_Yearly_Change_Per_Capita
FROM 
    YearlyChange
WHERE 
    Yearly_Change_Per_Capita IS NOT NULL
GROUP BY 
    country
ORDER BY 
    country;
    
    -- Ratio & Per Capita Analysis
    -- 10.What is the emission-to-GDP ratio for each country by year?
    
    SELECT 
    E.country,
    E.year,
    G.Value AS GDP,
    SUM(E.emission) AS Total_Emissions,
    ROUND(SUM(E.emission) / G.Value, 4) AS Emission_to_GDP_Ratio
FROM 
    emission_3 AS E
JOIN 
    gdp_3 AS G
ON 
    E.country = G.Country 
    AND E.year = G.year
GROUP BY 
    E.country,
    E.year,
    G.Value
ORDER BY 
    E.country,
    E.year;
    
    -- 11.What is the energy consumption per capita for each country over the last decade?
    
SELECT 
    C.country,
    C.year,
    P.Value AS Population,
    SUM(C.consumption) AS Total_Consumption,
    ROUND(SUM(C.consumption) / P.Value, 4) 
    AS Energy_Consumption_Per_Capita
FROM 
    consumption AS C
JOIN 
    population AS P
ON 
    C.country = P.countries
    AND C.year = P.year
WHERE 
    C.year >= (SELECT MAX(year) - 9 FROM consumption)
GROUP BY 
    C.country,
    C.year,
    P.Value
ORDER BY 
    C.country,
    C.year;

    
    -- 12.How does energy production per capita vary across countries?

SELECT
    P.country,
    P.year,
    -- Calculate Production Per Capita (Total Production / Population)
    (SUM(P.production) / POP.Value) AS Production_Per_Capita
FROM
    production AS P
JOIN
    population AS POP ON P.country = POP.countries AND P.year = POP.year
GROUP BY
    P.country, P.year, POP.Value
ORDER BY
    P.country, P.year; 
    
    -- 13.Which countries have the highest energy consumption relative to GDP?
    
    SELECT 
    c.country, 
    c.year,
    -- (Total Consumption / GDP Value)
    (SUM(c.consumption) * 1.0 / g.Value) AS energy_to_gdp_ratio
FROM consumption c
JOIN gdp_3 g ON c.country = g.Country AND c.year = g.year
GROUP BY c.country, c.year, g.Value
ORDER BY energy_to_gdp_ratio DESC;
    
    -- 14.What is the correlation between GDP growth and energy production growth?
    
    SELECT 
    g.Country, 
    g.year,
    -- GDP Growth Rate
    (g.Value - LAG(g.Value) OVER (PARTITION BY g.Country ORDER BY g.year)) / LAG(g.Value) 
    OVER (PARTITION BY g.Country ORDER BY g.year) AS gdp_growth,
    -- Energy Production Growth Rate
    (p.production - LAG(p.production) OVER (PARTITION BY p.country ORDER BY p.year)) / LAG(p.production) 
    OVER (PARTITION BY p.country ORDER BY p.year) AS prod_growth
FROM gdp_3 g
JOIN (SELECT country, year, SUM(production) as production FROM production GROUP BY 1, 2) p 
    ON g.Country = p.country AND g.year = p.year
ORDER BY g.Country, g.year;

   -- Global Comparisons
   
 -- 15.What are the top 10 countries by population and how do their emissions compare?
    
 SELECT 
    p.countries, 
    p.Value AS population, 
    e.emission AS total_emissions
FROM population p
JOIN emission_3 e 
    ON p.countries = e.country AND p.year = e.year
WHERE p.year = (SELECT MAX(2021) FROM population)
ORDER BY population DESC
LIMIT 10;
  
-- 16.Which countries have improved (reduced) their per capita emissions the most over the last decade?
    SELECT 
    country,
    -- (Past value - Current value) gives the total reduction
    (MAX(CASE WHEN year = 2011 THEN per_capita_emission END) * 1.0) - 
    (MAX(CASE WHEN year = 2021 THEN per_capita_emission END) * 1.0) AS total_reduction
FROM emission_3
GROUP BY country
HAVING total_reduction IS NOT NULL
ORDER BY total_reduction DESC
LIMIT 10;

-- 17. What is the global share (%) of emissions by country?

SELECT 
    country, 
    -- Calculation: (Country Total / Global Total) * 100
    SUM(emission) * 100.0 / (SELECT SUM(emission) FROM emission_3 
    WHERE year = (SELECT MAX(year) FROM emission_3)) 
    AS global_share_percentage
FROM emission_3
WHERE year = (SELECT MAX(year) FROM emission_3)
GROUP BY country
ORDER BY global_share_percentage DESC;

-- 18. What is the global average GDP, emission, and population by year?
SELECT 
    g.year,
    -- Calculate global averages
    AVG(g.Value) AS avg_gdp,
    AVG(p.Value) AS avg_population,
    AVG(e_sum.total_emission) AS avg_emission
FROM gdp_3 g
JOIN population p ON TRIM(g.Country) = TRIM(p.countries) AND g.year = p.year
JOIN (
    -- Summing emissions first so we get one total per country/year
    SELECT country, year, SUM(emission) as total_emission 
    FROM emission_3 
    GROUP BY country, year
) e_sum ON TRIM(g.Country) = TRIM(e_sum.country) AND g.year = e_sum.year
GROUP BY g.year
ORDER BY g.year;
    
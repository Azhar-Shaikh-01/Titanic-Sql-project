-----------------------------------------------------------------------------------------------------------------------------
/*                                  Passenger Demographics                                                               */
-----------------------------------------------------------------------------------------------------------------------------

-- Q1 How many passengers were in each passenger class?

SELECT 
    Class.Pclass, COUNT(*) AS TotalPassengers
   
FROM 
    Class
JOIN 
    Survival ON Class.PassengerId = Survival.PassengerId
GROUP BY 
    Class.Pclass;
--------------------------------------------------------------------------------------------------------------------
-- Q2.What was the distribution of ages among the passengers?

SELECT 
    CASE 
        WHEN Age < 13 THEN 'Child (<13)'
        WHEN Age BETWEEN 13 AND 19 THEN 'Teen(13-19)'
        WHEN Age BETWEEN 20 AND 39 THEN 'Adult(20-39)'
        WHEN Age BETWEEN 40 AND 59 THEN 'Middle Age Adult(40-59)'
        ELSE 'Senior Adult(60+)'
    END AS AgeGroup,
    COUNT(*) AS TotalPassengers,
  
   (cast(COUNT(*)as float)*100/ (select count(*) from Passengers)) AS AgeDistributionpercentage
FROM 
    Passengers
join Survival on Passengers.PassengerId = Survival.PassengerId
GROUP BY 
    AgeGroup;
----------------------------------------------------------------------------------------------------------------------------

-- Q3.What was the ratio of male to female passengers onboard?

SELECT 
    ROUND(
        SUM(CASE WHEN Passengers.Sex = 'male' THEN 1 ELSE 0 END) * 1.0 /
        SUM(CASE WHEN Passengers.Sex = 'female' THEN 1 ELSE 0 END),
    2) AS MaleToFemaleRatio
FROM 
    Passengers;

-----------------------------------------------------------------------------------------------------------------------------
/*                                 Survival Analysis                                                                      */
-----------------------------------------------------------------------------------------------------------------------------

-- Q1. What was the overall survival rate among passengers?

SELECT 
    AVG(Survived)*100 AS OverallSurvivalRate
FROM 
    Survival;
    
with psr as
(select count(survived) as alive from Survival
WHERE survived= 1)
select cast(alive as float)/(SELECT count(survived) from Survival)*100 from psr;
---------------------------------------------------------------------------------------------------------------------------------

-- Q2. How did survival rates differ based on gender?
SELECT 
    Passengers.Sex,
    AVG(Survival.Survived) * 100 AS OverallSurvivalRate
FROM 
    Survival
JOIN 
    Passengers ON Passengers.PassengerId = Survival.PassengerId
GROUP BY 
    Passengers.Sex;

-------------------------------------------------------------------------------------------------------------------------------

-- Q3. Did passenger class influence survival rates?

SELECT 
    Class.Pclass,
    COUNT(CASE WHEN Survival.Survived = 1 THEN 1 END) AS Survivors,
    COUNT(*) AS TotalPassengers,
    CAST(COUNT(CASE WHEN Survival.Survived = 1 THEN 1 END) AS FLOAT) / COUNT(*)*100 AS SurvivalRate
FROM 
    Class
JOIN 
    Survival ON Class.PassengerId = Survival.PassengerId
GROUP BY 
    Class.Pclass;

-----------------------------------------------------------------------------------------------------------------------
-- Q4. What was the survival rate among different age groups?

/* Child = <13
Teen = 13-19 yrs.
Adult = 20-39 yrs.
Middle Age Adult = 40-59 yrs.
Senior Adult = 60+
*/

SELECT 
    CASE 
        WHEN Age < 13 THEN 'Child'
        WHEN Age BETWEEN 13 AND 19 THEN 'Teen'
        WHEN Age BETWEEN 20 AND 39 THEN 'Adult'
        WHEN Age BETWEEN 40 AND 59 THEN 'Middle Age Adult'
        ELSE 'Senior Adult'
    END AS AgeGroup,
    COUNT(*) AS TotalPassengers,
    SUM(Survived) AS Survivors,
    SUM(Survived) * 100 / COUNT(*) AS SurvivalRate
FROM 
    Passengers
join Survival on Passengers.PassengerId = Survival.PassengerId
GROUP BY 
    AgeGroup;

----------------------------------------------------------------------------------------------------------------------
-- Q5. Did the port of embarkation impact survival rates?

SELECT 
    Passengers.embarked,
    COUNT(CASE WHEN Survival.Survived = 1 THEN 1 END) AS Survivors,
    COUNT(*) AS TotalPassengers,
    CAST(COUNT(CASE WHEN Survival.Survived = 1 THEN 1 END) AS FLOAT) / COUNT(*)*100 AS SurvivalRate
FROM 
    Passengers
JOIN 
    Survival ON Passengers.PassengerId = Survival.PassengerId
GROUP BY 
    Passengers.embarked
order by TotalPassengers desc;
-----------------------------------------------------------------------------------------------------------------------------
/*                                  Family Relationships                                                                */
-----------------------------------------------------------------------------------------------------------------------------
-- Q1. How many families were onboard, considering sibling/spouse and parent/child relationships?

SELECT count(*) from Family
WHERE sibsp != 0 and parch !=0
-------------------------------------------------------------------------------------------------------------------------
-- Q2. Did the size of the family affect the survival rate?

SELECT 
    Family.Parch AS Relationship,
    'Survived' AS Status,
    SUM(CASE WHEN Survival.Survived = 1 THEN 1 ELSE 0 END) AS Count
FROM 
    Family
JOIN 
    Survival ON Family.PassengerId = Survival.PassengerId
WHERE 
    Family.Parch != 0
GROUP BY 
    Family.Parch

UNION

SELECT 
    Family.Parch AS Relationship,
    'Unsurvived' AS Status,
    SUM(CASE WHEN Survival.Survived = 0 THEN 1 ELSE 0 END) AS Count
FROM 
    Family
JOIN 
    Survival ON Family.PassengerId = Survival.PassengerId
WHERE 
    Family.Parch != 0
GROUP BY 
    Family.Parch

UNION

SELECT 
    Family.SibSp AS Relationship,
    'Survived' AS Status,
    SUM(CASE WHEN Survival.Survived = 1 THEN 1 ELSE 0 END) AS Count
FROM 
    Family
JOIN 
    Survival ON Family.PassengerId = Survival.PassengerId
GROUP BY 
    Family.SibSp

UNION

SELECT 
    Family.SibSp AS Relationship,
    'Unsurvived' AS Status,
    SUM(CASE WHEN Survival.Survived = 0 THEN 1 ELSE 0 END) AS Count
FROM 
    Family
JOIN 
    Survival ON Family.PassengerId = Survival.PassengerId
GROUP BY 
    Family.SibSp
ORDER BY 
    Relationship DESC, Status;
----------------------------------------------------------------------------------------------------------------------------
-- Q3. How many passengers had siblings or spouses onboard?
SELECT count(*) from Family
where sibsp!=0;

----------------------------------------------------------------------------------------------------------------------------
-- Q4. Were there any children traveling alone?

SELECT * from Passengers 
join Family on Passengers.PassengerId= Family.PassengerId
where Family.sibsp =0 and Family.parch =0 and  Passengers.age <13;

-----------------------------------------------------------------------------------------------------------------------------
/*                                 Fare Analysis                                                               */
-----------------------------------------------------------------------------------------------------------------------------
-- Q1. What was the fare distribution across different passenger classes?
SELECT 
    Class.Pclass,
    ROUND(MIN(Ticket.Fare), 2) AS MinFare,
    ROUND(MAX(Ticket.Fare), 2) AS MaxFare,
    ROUND(AVG(Ticket.Fare), 2) AS AvgFare
FROM 
    Ticket
JOIN 
    Class ON Class.PassengerId = Ticket.PassengerId
WHERE 
    Ticket.Fare > 0  -- Exclude fares that are zero
GROUP BY 
    Class.Pclass
ORDER BY 
    Class.Pclass;
----------------------------------------------------------------------------------------------------------------------------------
-- Q2. Who were the passengers with the highest and lowest fares? 
SELECT 
    Passengers.PassengerId,
    Passengers.Name,
    Ticket.Fare AS Fare,
    'Highest' AS FareType
FROM 
    Ticket
JOIN 
    Passengers ON Ticket.PassengerId = Passengers.PassengerId
WHERE 
    Ticket.Fare = (SELECT MAX(Fare) FROM Ticket)
UNION
SELECT 
    Passengers.PassengerId,
    Passengers.Name,
    Ticket.Fare AS Fare,
    'Lowest' AS FareType
FROM 
    Ticket
JOIN 
    Passengers ON Ticket.PassengerId = Passengers.PassengerId
WHERE 
    Ticket.Fare = (SELECT MIN(Fare) FROM Ticket WHERE Fare > 0)
----------------------------------------------------------------------------------------------------------------------------------

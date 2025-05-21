create database ZomatoProject;

use ZomatoProject;

select Count(restaurantID) as KPI_Total_RestaurantCount from zomato_tab;
select count(distinct city) as KPI_Total_CityCount from zomato_tab;
select count(distinct country) as KPI_Total_CountryCount from zomato_tab;


-- All the KPIs 
select  count(distinct country) as KPI_Total_CountryCount, count(distinct city) as KPI_Total_CityCount, Count(restaurantID) as KPI_Total_RestaurantCount  from zomato_tab;

-- Q3. Find the Numbers of Resturants based on City and Country
select count(restaurantid), city, country from zomato_tab group by city, country;

-- Q4 Number of Restaurants opened based on year, Q & M --

-- by Year, Quarter,Month_wise Count of Restaurants that were started 

select substring(z.datekey_opening,1,4) as YearofInception, 
cal.quarter, cal.month_num,month_name,count(z.restaurantID) as RestaurantCount
from zomato_tab as z
inner join cal_tab as cal
on z.datekey_opening = cal.datekey_opening
group by substring(z.datekey_opening,1,4),cal.quarter,month_num,month_name
order by YearofInception,cal.quarter,month_num,month_name asc;

-- Individually year wise
select substring(datekey_opening,1,4) as year, count(datekey_opening) as Yearwise_Resturant_Count 
	from zomato_tab 
	group by substring(datekey_opening,1,4) 
    order by year asc ;
-- by year done

-- by quarter
select cal.quarter, count(z.restaurantID) QuarterWise_Restaurant_Count from zomato_tab as z
inner join cal_tab as cal
on z.datekey_opening = cal.datekey_opening
group by cal.quarter
order by cal.quarter;

-- by month
select cal.month_name,cal.month_num, count(z.restaurantID) as MonthWise_Restaurant_Count 
from zomato_tab as z
inner join cal_tab as cal
on z.datekey_opening = cal.datekey_opening
group by cal.month_name, cal.month_num
order by cal.month_num asc;

select rating from zomato_tab;

-- Q5. done Count of Restaurants according to the rating 
select temp.ratings as Rating, sum(temp.Restaurantct) Total_Restaurants from
(select count(RestaurantID) as Restaurantct, ceil(rating) as ratings
from zomato_tab group by rating) as temp
group by temp.ratings
order by temp.ratings asc;
-- -----

-- Q6: buckets based on Average Price of reasonable size
select cost_range as Price_Bucket_in_INR, count(*) as Total_restaurants 
	from
	(select case 
		when ((z.Average_Cost_for_two)*(ctry.ToINR)) <=1000 then "0-1000"
        when  ((z.Average_Cost_for_two)*(ctry.ToINR))between 1001 and 3000 then "1001-3000"
        when  ((z.Average_Cost_for_two)*(ctry.ToINR)) between 3001 and 6000 then "3001-6000"
        when ((z.Average_Cost_for_two)*(ctry.ToINR)) between 6001 and 10000 then "6001-10000"
        else "Tenthousand+"
        end as cost_range        
	from zomato_tab as z 
    inner join ctry_curr_tab as ctry
    on z.CountryCode = ctry.CountryCode) as temp
    group by cost_range
    order by cost_range;
        
	-- Q7: Percentage of Resturants based on "Has_Table_booking" 
-- select concat(Cast(round(100*(22.45/(select count(*)from zomato_tab) ),2) as char),"%");
select Table_booking_option, concat(Cast(round(100*(count(*)/(select count(*)from zomato_tab) ),2) as char),"%") as Percentage_of_booking
from
	(select case
		when Has_Table_booking = "Yes" then "Yay"
        else "Nay" 
        end as Table_booking_option 
        from zomato_tab) as temp
	group by Table_booking_option;
    
-- Q8: Percentage of Resturants that has online delivery option
select Online_delivery_option, 
		concat(cast(round(100*count(*)/(select count(*) from zomato_tab),2) as char),"%") as Pecentage
from 
     (select case
				when Has_Online_Delivery = "Yes" then "Is There"
                else "Not There"
                end as Online_Delivery_option
                from zomato_tab) as temp
	group by Online_Delivery_option;
                

--  For all the cuisines


-- OUT OF THE BOX -- cuisine as a search criterion.
-- SP for the same
CREATE DEFINER=`root`@`localhost` PROCEDURE `ZOMATO_CUISINE_FILTER`(IN CUISINE_FILTER VARCHAR(30), 
			OUT RESTAURANT_CT INT, 
            out Cuisine varchar(30))
begin
    
    select count(*) into RESTAURANT_CT from zomato_tab where trim(CUISINE_FILTER) in (trim(cuisine1), trim(cuisine2),trim(cuisine3), trim(cuisine4),trim(cuisine5), trim(cuisine6),trim(cuisine7));
	set Cuisine = concat(CUISINE_FILTER," Restaurant_Count");
end;

-- Count of Restaurants that has a particular cuisine; give Cuisine of your choice and see the number of restaurants offering
-- that cuisine.

select * from zomato_tab;

CALL ZOMATO_CUISINE_FILTER(" Fast Food",@C,@cus);
select @cus as Cuisine, @c as restaurant_Count;

--  

select CountryCode,country from ctry_curr_tab;
-- ----
select z.Price_Range, count(z.restaurantid) as RestaurantCount,  Round(avg(z.Average_Cost_for_two *c.ToINR),2) as Avg_Cost_in_INR
from zomato_tab as z
inner join ctry_curr_tab as c
on z.CountryCode = c.CountryCode
where z.CountryCode = 1
group by z.price_range
order by z.price_range;

-- top 10 costliest restaurants from India

select * from zomato_tab as z
inner join ctry_curr_tab  as c
on z.CountryCode = c.CountryCode
-- where z.CountryCode = 1 
order by (z.Average_Cost_for_two*c.ToINR) desc limit 10 ;


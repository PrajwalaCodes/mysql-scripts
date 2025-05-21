use e_commerce; -- Schema

select count(distinct customer_id ) from customers;
select count(*) from customers;
select count(*) from orders_tab;
select count(*) from order_items;

-- To know the weeknumber in a week; eg:1 - sunday, 2- Monday etc
select dayofweek(order_purchase_timestamp), 
		dayname(order_purchase_timestamp) from orders_tab  
        limit 10;
        
-- 1. KPI Weekday Vs Weekend Order
select OrderAnalysis, count(*) as OrderCount from 
(
select case 
	when (dayofweek(order_purchase_timestamp) = 1 or dayofweek(order_purchase_timestamp) = 7)  then "Weekend"
    else "Weekday"
end as OrderAnalysis
from orders_tab) as temp
group by OrderAnalysis;

-- 1.1 Counts wrt all the days of a week.->
select WeekAnalysis, count(*) as countbyday from 
	(select case
		when dayofweek(order_purchase_timestamp) = 1 then "Sunday"
		when dayofweek(order_purchase_timestamp) = 2 then "Monday"
		when dayofweek(order_purchase_timestamp) = 3 then "Tuesday"
		when dayofweek(order_purchase_timestamp) = 4 then "Wednesday"
		when dayofweek(order_purchase_timestamp) = 5 then "Thursday"
		when dayofweek(order_purchase_timestamp) = 6 then "Friday"
		else "Saturday"
			end as WeekAnalysis
	 from orders_tab
	 where year(order_purchase_timestamp) > 2000
	) as temp
    group by weekAnalysis
    order by countbyday desc;
 
-- Weekday Analysis by total Counts and Payments
  
select OrderAnalysis, count(*) as OrderCount, 
		(sum(Payments)/(select sum(payment_value) from order_payments op1) )*100 as TotalPayments_Percent
from 
(
select case 
	when (dayofweek(order_purchase_timestamp) = 1 or dayofweek(order_purchase_timestamp) = 7)  then "Weekend"
    else "Weekday"
end as OrderAnalysis, op.payment_value as Payments
from orders_tab o
inner join order_payments op
on o.order_id = op.order_id ) as temp
group by OrderAnalysis;
    
-- 2.Number of Orders with review score 5 and payment type as credit card or other means. 
    
    select op1.payment_type as PaymentMode, count( op1.order_id) OrderCount 
    from orders_reviews as or1
    left join order_payments op1
    on or1.order_id = op1.order_id
	where or1.review_score = 5
	group by op1.payment_type 
	order by OrderCount desc; 
     
-- 3.KPI Average number of days taken for order_delivered_customer_date for pet_shop
   
	select floor(avg(Delivery_Days)) from orders_tab o inner join order_items ot
    on o.order_id = ot.order_id
    inner join product_names p
    on ot.product_id = p.product_id
    and year(order_delivered_customer_date)>2000 
    and product_name = "pet_shop";
   
-- 4. Average price, count of orders and payment values from customers of sao paulo city 
    select ceil(avg(price)), ceil(avg(payment_value))
    from order_items ot 
    left join orders_tab o
    on ot.order_id  = o.order_id
    left join order_payments op
    on ot.order_id = op.order_id
    inner join customers c
    on c.customer_id = o.customer_id
    where customer_city = "sao paulo"; -- 109
    
    -- avg price in general
    select ceil(avg(price))
    from order_items; --  121

-- costliest category in price        
    select product_name, price 
    from product_names p, order_items ot
    where p.product_id = ot.product_id
	and ot.price = (select max(price) from order_items);
    
    -- or
    
    select product_name, max(price) as maxprice
    from product_names p, order_items ot
    where p.product_id = ot.product_id
	and price is not null
    group by product_name
    order by maxprice desc limit 1; -- offset 0
    
 -- cheapest category in price    
	select distinct product_name, price 
    from product_names p, order_items ot
    where p.product_id = ot.product_id
	and ot.price = (select min(price) from order_items);
  
  -- top (5) ordered categories with spending trend ranking
  select distinct product_name, count(distinct order_id) order_count, round(sum(price)) as categorytotal,
  rank() over (order by round(sum(price)) desc) as ranking
  from product_names p, order_items ot
  where p.product_id = ot.product_id
  group by product_name; -- with least amount spent on security_and_services
 -- limit 5; -- for 5 values
 
 -- Exploring: Freight value affecting review score?
 
 select distinct product_name, price,freight_value, review_score
 from order_items ot
 left join orders_reviews orv
 on ot.order_id = orv.order_id
 left join product_names p
 on p.product_id = ot.product_id
where freight_value> price -- where frieght  value is higher than price of the item
order by review_score desc;

-- lets dig deeper and see the review wise count of such orders

select Rating, count(*) from 
(select case
		when (review_score = 5) then "5"
        when (review_score = 4) then "4"
        when (review_score = 3) then "3"
        when (review_score = 2) then "2"
        when (review_score = 1) then "1"
        else "NA" end as Rating
        from order_items ot
	inner join orders_reviews orv
	on ot.order_id = orv.order_id
    inner join product_names p
	on p.product_id = ot.product_id
    where freight_value> price) as subq
    group by Rating ;
    
-- rank by freight_value: categories where the customers are willing to pay more for transportation and not 
 
 select distinct product_name, ceil(sum(price)), ceil(sum(freight_value))
	,rank() over (order by sum(freight_value) desc ) as ranking
 from order_items ot
inner join product_names p
on p.product_id = ot.product_id
where freight_value> price 
group by product_name
order by ranking asc;

-- 5 Relationship between shipping days and review scores wrt products
    
    select distinct product_name, Delivery_Days, review_score
    from orders_tab o 
    inner join orders_reviews Orr
    on o.order_id = orr.order_id
    inner join order_items ot
    on o.order_id = ot.order_id
    inner join product_names p
    on ot.product_id = p.product_id
   order by Delivery_Days asc;
    
   -- 5.1  exploring further: avg of deleiveryDays per category
   select distinct product_name, avg(Delivery_Days)
   from orders_tab o 
   inner join orders_reviews Orr
    on o.order_id = orr.order_id
    inner join order_items ot
    on o.order_id = ot.order_id
    inner join product_names p
    on ot.product_id = p.product_id
    group by product_name
    order by product_name asc ;
   
     -- 5.2 Relationship between estimated delivery date, shipping days Vs review scores
    select order_estimated_delivery_date, 
		date(order_delivered_customer_date)as Delivered_On, Delivery_Days, 
			review_score
    from orders_tab o inner join orders_reviews Orr
    on o.order_id = orr.order_id
    where year(order_delivered_customer_date) >2000
    and order_estimated_delivery_date is not null
    order by Delivery_Days asc;
    
    -- going further; if we look at the lag in estimated delivery date and Actual delivery date, 
    -- negative values often have low review score.
    -- implies in-time delivery has higher chance of good reviews.
  select datediff((concat_ws("-",right(order_estimated_delivery_date,4),mid(order_estimated_delivery_date,4,2),
		left(order_estimated_delivery_date,2))),date(order_delivered_customer_date)) as LaginDelivery,
		review_score
	from orders_tab o 
	inner join orders_reviews Orr
	on o.order_id = orr.order_id
    where year(order_delivered_customer_date) >2000
    and order_estimated_delivery_date is not null
    order by LaginDelivery asc;
    
 -- shows the trend of review scores when there is a lag(estimated date - delivery date)   
    select subq.review_score,count(*) as review_cts,
		(select if (subq.review_score = 1,"1",
				if (subq.review_score = 2, "2",
					if (subq.review_score = 3,"3",
						if (subq.review_score = 4,"4",
							if (subq.review_score = 5,"5",0))))) ) as review_count
	from (select datediff((concat_ws("-",right(order_estimated_delivery_date,4),mid(order_estimated_delivery_date,4,2),
	left(order_estimated_delivery_date,2))),date(order_delivered_customer_date)) as LaginDelivery,
	review_score
	from orders_tab o 
	inner join orders_reviews Orr
	on o.order_id = orr.order_id
    where year(order_delivered_customer_date) >2000
    and order_estimated_delivery_date is not null) as subq
    where subq.LaginDelivery <0
    group by review_score
    order by review_score;
  -- Conclusion: Reviews are not solely dependent on just shipping period, other factors need to be evaluated in order to come to a conclusion.

-- Status wise count of orders
 select order_status, count(order_id) CountofOrders
 from orders_tab
 group by order_status;
 
 -- **** Thank you **** -
#What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(m.price) AS total_spent 
FROM sales s 
JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;

##How many days has each customer visited the restaurant?
select customer_id,count(distinct(order_date) ) as days_visited from sales
group by customer_id;


##What was the first item from the menu purchased by each customer?
SELECT s.customer_id, m.product_name, s.order_date
FROM sales s
JOIN menu m ON s.product_id = m.product_id
WHERE s.order_date = (
    SELECT MIN(order_date)
    FROM sales
    WHERE customer_id = s.customer_id
)
ORDER BY s.customer_id, s.order_date;




##What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT m.product_name, COUNT(s.product_id) AS purchase_count
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY purchase_count DESC;


##Which item was the most popular for each customer?
select s.customer_id,m.product_name , count( s.product_id) as total_purchesed
from sales s join menu m on s.product_id= m.product_id
group by s.customer_id;


WITH CustomerPurchases AS (
  SELECT 
    s.customer_id,
    m.product_name,
    COUNT(s.product_id) AS total_purchased,
    ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS rank_p
  FROM sales s
  JOIN menu m ON s.product_id = m.product_id
  GROUP BY s.customer_id, m.product_name
)
SELECT 
  customer_id,
  product_name,
  total_purchased
FROM CustomerPurchases
WHERE rank_p = 1;


##Which item was purchased first by the customer after they became a member?
select s.customer_id, m.product_name,s.order_date
from sales s join menu m on s.product_id=m.product_id
join members mb on s.customer_id=mb.customer_id
where s.order_date>mb.join_date and s.customer_id=mb.customer_id
order by s.order_date asc
limit 2


##Which item was purchased just before the customer became a member?
select s.customer_id,m.product_name,s.order_date                 
from sales s join menu m on s.product_id=m.product_id
join members mb on s.customer_id=mb.customer_id
where s.order_date< mb.join_date
and s.order_date =(
select max(s2.order_date) from sales s2
where s2.customer_id=s.customer_id and s2.order_date<mb.join_date);

##What is the total items and amount spent for each member before they became a member?
select s.customer_id, m.product_name, count(s.product_id) as item_count, m.price, sum(m.price) as spent
from sales s join menu m on s.product_id=m.product_id
join members mb on s.customer_id=mb.customer_id
where s.order_date<mb.join_date
group by s.customer_id,m.product_name,m.price;


##If each $1 spent equates to 10 points and sushi has a 2x points multiplier - 
##how many points would each customer have?
select s.customer_id, m.product_name , count(s.customer_id) as total_count,
sum( case 
       when m.product_name='sushi' then (m.price*2)*10
       else m.price*10
       end
	)as total_points
       from sales s join menu m on s.product_id=m.product_id
       group by s.customer_id,m.product_name;

##In the first week after a customer joins the program (including their join date) they earn 
##2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

select s.customer_id ,
sum( case
       when s.order_date between mb.join_date and date_add(mb.join_date, interval 7 day) then m.price *20
       when m.product_name = 'sushi' then m.price*20
       else m.price*10
	   end
    ) as total_points
       from sales s join menu m on s.product_id=m.product_id
       join members mb on mb.customer_id= s.customer_id 
       where s.customer_id in( 'A' , 'B')
       and s.order_date between '2021-01-01' and '2021-01-31' 
       group by s.customer_id;

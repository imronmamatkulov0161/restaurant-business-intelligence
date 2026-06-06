-- ============================================================
-- Restaurant Business Intelligence System — SQL Analysis
-- Author: Imron Mamatkulov
-- Database: PostgreSQL 17
-- Dataset: 100,000+ rows across 13 tables
-- ============================================================


-- ============================================================
-- SECTION 1: MENU & PROFITABILITY ANALYSIS
-- ============================================================

-- 1. Most profitable menu items by margin
SELECT 
    item_name,
    category,
    price,
    cost,
    ROUND(price - cost, 2) AS profit,
    ROUND((price - cost) / NULLIF(price, 0) * 100, 1) AS margin_pct
FROM menu_items
WHERE price > 0
ORDER BY profit DESC
LIMIT 10;

-- 2. Price tier analysis: do cheaper items sell more?
SELECT 
    CASE 
        WHEN actual_selling_price < 10 THEN 'Budget (< $10)'
        WHEN actual_selling_price < 25 THEN 'Mid ($10-25)'
        WHEN actual_selling_price < 50 THEN 'Premium ($25-50)'
        ELSE 'Luxury ($50+)'
    END AS price_tier,
    COUNT(*) AS orders,
    ROUND(AVG(quantity_sold), 0) AS avg_qty,
    ROUND(SUM(actual_selling_price * quantity_sold), 2) AS total_revenue,
    ROUND(AVG((actual_selling_price - typical_ingredient_cost) / NULLIF(actual_selling_price, 0) * 100), 1) AS avg_margin_pct
FROM sales
GROUP BY price_tier
ORDER BY avg_qty DESC;

-- 3. Top 10 best selling items by quantity
SELECT 
    menu_item_name,
    SUM(quantity_sold) AS total_qty,
    ROUND(AVG(actual_selling_price), 2) AS avg_price,
    ROUND(SUM(actual_selling_price * quantity_sold), 2) AS total_revenue
FROM sales
GROUP BY menu_item_name
ORDER BY total_qty DESC
LIMIT 10;


-- ============================================================
-- SECTION 2: REVENUE & TIME ANALYSIS
-- ============================================================

-- 4. Revenue by meal type
SELECT 
    meal_type,
    COUNT(*) AS total_orders,
    ROUND(SUM(actual_selling_price * quantity_sold), 2) AS total_revenue,
    ROUND(AVG(actual_selling_price), 2) AS avg_price,
    ROUND(AVG(quantity_sold), 0) AS avg_qty
FROM sales
GROUP BY meal_type
ORDER BY total_revenue DESC;

-- 5. Monthly revenue trend
SELECT 
    TO_CHAR(date, 'YYYY-MM') AS month,
    COUNT(*) AS total_orders,
    ROUND(SUM(actual_selling_price * quantity_sold), 2) AS monthly_revenue,
    ROUND(AVG(quantity_sold), 0) AS avg_qty
FROM sales
GROUP BY TO_CHAR(date, 'YYYY-MM')
ORDER BY month ASC;

-- 6. Monthly growth rate (window function)
SELECT 
    month,
    monthly_revenue,
    LAG(monthly_revenue) OVER (ORDER BY month) AS prev_month,
    ROUND((monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY month)) / NULLIF(LAG(monthly_revenue) OVER (ORDER BY month), 0) * 100, 1) AS growth_pct
FROM (
    SELECT 
        TO_CHAR(date, 'YYYY-MM') AS month,
        ROUND(SUM(actual_selling_price * quantity_sold), 2) AS monthly_revenue
    FROM sales
    GROUP BY TO_CHAR(date, 'YYYY-MM')
) monthly
ORDER BY month;

-- 7. Revenue by day of week
SELECT 
    TO_CHAR(date, 'Day') AS day_name,
    EXTRACT(DOW FROM date) AS day_num,
    COUNT(*) AS total_orders,
    ROUND(SUM(actual_selling_price * quantity_sold), 2) AS revenue
FROM sales
GROUP BY TO_CHAR(date, 'Day'), EXTRACT(DOW FROM date)
ORDER BY day_num;

-- 8. Peak hours analysis (from 73,000 orders)
SELECT 
    EXTRACT(HOUR FROM time) AS hour,
    COUNT(*) AS orders,
    SUM(count) AS items_sold,
    ROUND(SUM(count) * 100.0 / (SELECT SUM(count) FROM orders), 1) AS pct_of_total
FROM orders
GROUP BY EXTRACT(HOUR FROM time)
ORDER BY items_sold DESC
LIMIT 5;

-- 9. Busiest hours breakdown
SELECT 
    EXTRACT(HOUR FROM time) AS hour,
    COUNT(*) AS total_orders,
    SUM(count) AS total_items
FROM orders
GROUP BY EXTRACT(HOUR FROM time)
ORDER BY hour ASC;


-- ============================================================
-- SECTION 3: EXTERNAL FACTORS
-- ============================================================

-- 10. Weather impact on sales
SELECT 
    weather_condition,
    COUNT(*) AS total_orders,
    ROUND(AVG(quantity_sold), 0) AS avg_qty,
    ROUND(AVG(actual_selling_price), 2) AS avg_price,
    ROUND(SUM(actual_selling_price * quantity_sold), 2) AS total_revenue
FROM sales
GROUP BY weather_condition
ORDER BY total_revenue DESC;

-- 11. Promotions impact on sales
SELECT 
    has_promotion,
    COUNT(*) AS orders,
    ROUND(AVG(quantity_sold), 0) AS avg_qty,
    ROUND(AVG(actual_selling_price), 2) AS avg_price,
    ROUND(SUM(actual_selling_price * quantity_sold), 2) AS total_revenue
FROM sales
GROUP BY has_promotion;


-- ============================================================
-- SECTION 4: RESTAURANT PERFORMANCE
-- ============================================================

-- 12. Performance by restaurant type
SELECT 
    restaurant_type,
    COUNT(*) AS total_sales,
    ROUND(AVG(actual_selling_price), 2) AS avg_price,
    ROUND(AVG(typical_ingredient_cost), 2) AS avg_cost,
    ROUND(AVG(actual_selling_price - typical_ingredient_cost), 2) AS avg_profit,
    ROUND(AVG((actual_selling_price - typical_ingredient_cost) / NULLIF(actual_selling_price, 0) * 100), 1) AS margin_pct
FROM sales
GROUP BY restaurant_type
ORDER BY avg_profit DESC;

-- 13. Complete restaurant scorecard (multiple JOINs)
SELECT 
    r.name,
    r.city,
    r.price AS price_level,
    rc.cuisine,
    ROUND(AVG(rt.food_rating), 2) AS food_score,
    ROUND(AVG(rt.service_rating), 2) AS service_score,
    ROUND(AVG(rt.rating), 2) AS overall_score,
    COUNT(rt.rating) AS total_ratings
FROM restaurants r
JOIN ratings rt ON r.place_id = rt.place_id
LEFT JOIN restaurant_cuisines rc ON r.place_id = rc.place_id
GROUP BY r.name, r.city, r.price, rc.cuisine
HAVING COUNT(rt.rating) >= 5
ORDER BY overall_score DESC
LIMIT 15;

-- 14. Most popular cuisines by rating
SELECT 
    rc.cuisine,
    COUNT(*) AS restaurant_count,
    ROUND(AVG(rt.food_rating), 2) AS avg_food_rating
FROM restaurant_cuisines rc
JOIN ratings rt ON rc.place_id = rt.place_id
GROUP BY rc.cuisine
HAVING COUNT(*) >= 3
ORDER BY avg_food_rating DESC
LIMIT 15;


-- ============================================================
-- SECTION 5: CUSTOMER ANALYSIS
-- ============================================================

-- 15. Customer demographics vs ratings
SELECT 
    c.budget,
    c.marital_status,
    COUNT(DISTINCT c.user_id) AS customers,
    ROUND(AVG(rt.rating), 2) AS avg_rating,
    ROUND(AVG(rt.food_rating), 2) AS avg_food_rating
FROM customers c
JOIN ratings rt ON c.user_id = rt.user_id
GROUP BY c.budget, c.marital_status
HAVING COUNT(*) >= 3
ORDER BY avg_rating DESC;

-- 16. Customer ratings: food vs service
SELECT 
    r.name AS restaurant_name,
    COUNT(rt.rating) AS total_ratings,
    ROUND(AVG(rt.food_rating), 2) AS avg_food,
    ROUND(AVG(rt.service_rating), 2) AS avg_service,
    ROUND(AVG(rt.rating), 2) AS avg_overall
FROM ratings rt
JOIN restaurants r ON rt.place_id = r.place_id
GROUP BY r.name
HAVING COUNT(rt.rating) >= 5
ORDER BY avg_overall DESC
LIMIT 10;

-- 17. Payment method preferences
SELECT 
    cp.payment_method,
    COUNT(DISTINCT cp.user_id) AS customers_using,
    (SELECT COUNT(DISTINCT place_id) FROM restaurant_payments rp WHERE rp.payment_method = cp.payment_method) AS restaurants_accepting
FROM customer_payments cp
GROUP BY cp.payment_method
ORDER BY customers_using DESC;


-- ============================================================
-- SECTION 6: REVIEW ANALYSIS
-- ============================================================

-- 18. Top reviewed restaurants with sentiment
SELECT 
    restaurant,
    COUNT(*) AS total_reviews,
    ROUND(AVG(CASE WHEN rating ~ '^\d+\.?\d*$' THEN rating::NUMERIC END), 2) AS avg_numeric_rating,
    SUM(CASE WHEN rating = 'Like' THEN 1 ELSE 0 END) AS likes,
    SUM(CASE WHEN rating = 'Dislike' THEN 1 ELSE 0 END) AS dislikes
FROM reviews
GROUP BY restaurant
HAVING COUNT(*) >= 20
ORDER BY total_reviews DESC
LIMIT 15;

-- 19. Items frequently ordered together (self-join)
SELECT 
    a.item AS item_1,
    b.item AS item_2,
    COUNT(*) AS times_ordered_together
FROM orders a
JOIN orders b ON a.order_number = b.order_number AND a.item < b.item
GROUP BY a.item, b.item
ORDER BY times_ordered_together DESC
LIMIT 10;

-- 20. Full business summary
SELECT 
    (SELECT COUNT(DISTINCT menu_item_name) FROM sales) AS total_menu_items,
    (SELECT COUNT(*) FROM sales) AS total_sales_records,
    (SELECT COUNT(*) FROM orders) AS total_orders,
    (SELECT COUNT(*) FROM reviews) AS total_reviews,
    (SELECT COUNT(DISTINCT restaurant_type) FROM sales) AS restaurant_types,
    (SELECT ROUND(SUM(actual_selling_price * quantity_sold), 2) FROM sales) AS total_revenue,
    (SELECT ROUND(AVG(actual_selling_price), 2) FROM sales) AS avg_price;

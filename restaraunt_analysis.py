import psycopg2
import pandas as pd
import matplotlib.pyplot as plt
import warnings
warnings.filterwarnings('ignore')

# Connect to PostgreSQL
conn = psycopg2.connect(
    host="localhost",
    database="restaurant_bi",
    user="postgres",
    password="YOUR_PASSWORD"
)

print("Connected to database!")

# ── CHART 1: Revenue by Meal Type (Bar Chart) ──
df1 = pd.read_sql("""
    SELECT meal_type, ROUND(SUM(actual_selling_price * quantity_sold), 2) AS revenue
    FROM sales GROUP BY meal_type ORDER BY revenue DESC
""", conn)

plt.figure(figsize=(8, 5))
plt.bar(df1['meal_type'], df1['revenue'], color=['#1A56A0', '#27AE60', '#E74C3C'])
plt.title('Revenue by Meal Type', fontsize=14, fontweight='bold')
plt.ylabel('Revenue ($)')
plt.tight_layout()
plt.savefig('chart1_revenue_by_meal.png', dpi=150)
plt.close()
print("Chart 1 saved!")

# ── CHART 2: Monthly Revenue Trend (Line Chart) ──
df2 = pd.read_sql("""
    SELECT TO_CHAR(date, 'YYYY-MM') AS month,
    ROUND(SUM(actual_selling_price * quantity_sold), 2) AS revenue
    FROM sales GROUP BY TO_CHAR(date, 'YYYY-MM') ORDER BY month
""", conn)

plt.figure(figsize=(10, 5))
plt.plot(df2['month'], df2['revenue'], marker='o', color='#1A56A0', linewidth=2)
plt.title('Monthly Revenue Trend (2024)', fontsize=14, fontweight='bold')
plt.xlabel('Month')
plt.ylabel('Revenue ($)')
plt.xticks(rotation=45)
plt.grid(axis='y', alpha=0.3)
plt.tight_layout()
plt.savefig('chart2_monthly_revenue.png', dpi=150)
plt.close()
print("Chart 2 saved!")

# ── CHART 3: Weather Impact on Sales (Bar Chart) ──
df3 = pd.read_sql("""
    SELECT weather_condition, ROUND(SUM(actual_selling_price * quantity_sold), 2) AS revenue,
    COUNT(*) AS orders
    FROM sales GROUP BY weather_condition ORDER BY revenue DESC
""", conn)

plt.figure(figsize=(8, 5))
plt.bar(df3['weather_condition'], df3['revenue'], color=['#F39C12', '#95A5A6', '#3498DB'])
plt.title('Revenue by Weather Condition', fontsize=14, fontweight='bold')
plt.ylabel('Revenue ($)')
plt.tight_layout()
plt.savefig('chart3_weather_impact.png', dpi=150)
plt.close()
print("Chart 3 saved!")

# ── CHART 4: Restaurant Type Profit Margins (Horizontal Bar) ──
df4 = pd.read_sql("""
    SELECT restaurant_type,
    ROUND(AVG((actual_selling_price - typical_ingredient_cost) / NULLIF(actual_selling_price, 0) * 100), 1) AS margin
    FROM sales GROUP BY restaurant_type ORDER BY margin DESC
""", conn)

plt.figure(figsize=(8, 5))
plt.barh(df4['restaurant_type'], df4['margin'], color=['#1A56A0', '#2A5CAD', '#3A6CBD', '#4A7CCD', '#5A8CDD'])
plt.title('Profit Margin by Restaurant Type (%)', fontsize=14, fontweight='bold')
plt.xlabel('Margin (%)')
plt.tight_layout()
plt.savefig('chart4_profit_margins.png', dpi=150)
plt.close()
print("Chart 4 saved!")

# ── CHART 5: Top 10 Best Selling Items (Bar Chart) ──
df5 = pd.read_sql("""
    SELECT menu_item_name, SUM(quantity_sold) AS total_qty
    FROM sales GROUP BY menu_item_name ORDER BY total_qty DESC LIMIT 10
""", conn)

plt.figure(figsize=(10, 6))
plt.barh(df5['menu_item_name'], df5['total_qty'], color='#27AE60')
plt.title('Top 10 Best Selling Items', fontsize=14, fontweight='bold')
plt.xlabel('Total Quantity Sold')
plt.gca().invert_yaxis()
plt.tight_layout()
plt.savefig('chart5_top_items.png', dpi=150)
plt.close()
print("Chart 5 saved!")

# ── CHART 6: Hourly Order Distribution (Line Chart) ──
df6 = pd.read_sql("""
    SELECT EXTRACT(HOUR FROM time) AS hour, COUNT(*) AS orders
    FROM orders GROUP BY EXTRACT(HOUR FROM time) ORDER BY hour
""", conn)

plt.figure(figsize=(10, 5))
plt.fill_between(df6['hour'], df6['orders'], alpha=0.3, color='#1A56A0')
plt.plot(df6['hour'], df6['orders'], color='#1A56A0', linewidth=2)
plt.title('Orders by Hour of Day', fontsize=14, fontweight='bold')
plt.xlabel('Hour (24h)')
plt.ylabel('Number of Orders')
plt.xticks(range(0, 24))
plt.grid(axis='y', alpha=0.3)
plt.tight_layout()
plt.savefig('chart6_hourly_orders.png', dpi=150)
plt.close()
print("Chart 6 saved!")

# ── CHART 7: Price Tier Distribution (Pie Chart) ──
df7 = pd.read_sql("""
    SELECT CASE 
        WHEN actual_selling_price < 10 THEN 'Budget'
        WHEN actual_selling_price < 25 THEN 'Mid-Range'
        WHEN actual_selling_price < 50 THEN 'Premium'
        ELSE 'Luxury'
    END AS tier, COUNT(*) AS orders
    FROM sales GROUP BY tier ORDER BY orders DESC
""", conn)

plt.figure(figsize=(7, 7))
colors = ['#1A56A0', '#27AE60', '#F39C12', '#E74C3C']
plt.pie(df7['orders'], labels=df7['tier'], autopct='%1.1f%%', colors=colors, startangle=90)
plt.title('Sales Distribution by Price Tier', fontsize=14, fontweight='bold')
plt.tight_layout()
plt.savefig('chart7_price_tiers.png', dpi=150)
plt.close()
print("Chart 7 saved!")

# ── CHART 8: Food vs Service Ratings (Scatter Plot) ──
df8 = pd.read_sql("""
    SELECT AVG(food_rating) AS food, AVG(service_rating) AS service, place_id
    FROM ratings GROUP BY place_id
""", conn)

plt.figure(figsize=(8, 6))
plt.scatter(df8['food'], df8['service'], alpha=0.6, color='#E74C3C', s=80)
plt.title('Food Rating vs Service Rating', fontsize=14, fontweight='bold')
plt.xlabel('Average Food Rating')
plt.ylabel('Average Service Rating')
plt.grid(alpha=0.3)
plt.tight_layout()
plt.savefig('chart8_food_vs_service.png', dpi=150)
plt.close()
print("Chart 8 saved!")

conn.close()
print("\nAll 8 charts saved in your project folder!")
# Data

**Source:** [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle). It has 9 tables covering ~100,000 orders placed between 2016 and 2018.

The CSV files are not stored in this repo because of their size (~120 MB raw). To run the project:

1. Download the dataset from Kaggle.
2. Put the 9 CSV files in this `data/` folder.
3. Run the [notebook](../notebooks/olist_eda_and_cleaning.ipynb). It writes the cleaned tables back to this folder with an `_updated` suffix (e.g. `customers_updated.csv`).

---

## Summary of Changes to the Raw Data

| Table (raw file → cleaned file) | Rows (raw → cleaned) | Changes |
|---|---|---|
| **Order reviews**<br>`olist_order_reviews_dataset.csv` → `order_reviews_updated.csv` | 99,224 → **98,410** | Removed **814 rows** whose `review_id` was reused on another order (first occurrence kept), so each review is counted once. |
| **Product category translation**<br>`product_category_name_translation.csv` → `product_category_name_translation_updated.csv` | 71 → 71 | Removed a hidden carriage return (`\r`) at the end of every English category name (`'health_beauty\r'` → `'health_beauty'`). |
| **Geolocation**<br>`olist_geolocation_dataset.csv` → `geolocation_updated.csv` | 1,000,163 → 1,000,163 | Added `city_clean`: city names in lowercase with accents removed, so "são paulo" and "sao paulo" count as one city (Sao Paulo: 135,800 → **160,719** records). |
| **Orders**<br>`olist_orders_dataset.csv` → `order_details_updated.csv` | 99,441 → 99,441 | Converted the 5 date columns from text to datetime. Added `delivery_time` and **`delivery_days`** (days from order approval to customer delivery). Renamed the table to `order_details`. |
| **Order items**<br>`olist_order_items_dataset.csv` → `order_items_updated.csv` | 112,650 → 112,650 | Renamed `freight_value` → **`shipping_cost`**. Converted `shipping_limit_date` to datetime. Added **`shipping_percent`** (shipping cost as % of item price). |
| **Products**<br>`olist_products_dataset.csv` → `product_details_updated.csv` | 32,951 → 32,951 | Added **`volume_cm3`** (length × height × width) and **`density_g_cm3`** (weight ÷ volume). Renamed the table to `product_details`. |
| **Customers**<br>`olist_customers_dataset.csv` → `customers_updated.csv` | 99,441 → 99,441 | Renamed `customer_zip_code_prefix` → **`zipcode`**. |
| **Payments**<br>`olist_order_payments_dataset.csv` → `order_payments_updated.csv` | 103,886 → 103,886 | No changes. |
| **Sellers**<br>`olist_sellers_dataset.csv` → `sellers_updated.csv` | 3,095 → 3,095 | No changes. |

### Scoping rule (applied in analysis, not to the files)

September–December 2016 has only 1–2 orders per month (the platform's pilot phase), and September 2018 is a partial month. Monthly trends are therefore limited to **January 2017 – August 2018**. All rows stay in the files.

---

## How the Tables Connect

`order_details` is the central table. Every other table links to it directly or through `order_items`:

| Table | Key | Links to |
|---|---|---|
| `order_details` | `order_id` | `customers` (`customer_id`) |
| `order_items` | `order_id`, `order_item_id` | `order_details`, `product_details` (`product_id`), `sellers` (`seller_id`) |
| `order_payments` | `order_id`, `payment_sequential` | `order_details` |
| `order_reviews` | `review_id` | `order_details` (`order_id`) |
| `customers` | `customer_id` | `customer_unique_id` identifies the actual person across orders |
| `product_details` | `product_id` | `product_category_name_translation` (`product_category_name`) |
| `sellers` | `seller_id` | — |
| `geolocation` | `geolocation_zip_code_prefix` | zip code prefix of customers and sellers |

# Brazilian E-Commerce (Olist): Key Findings

Full write-up of results from the two analysis phases:

1. **Python (pandas):** exploratory analysis, cleaning and feature engineering ([notebook](../notebooks/olist_eda_and_cleaning.ipynb))
2. **SQL (MySQL):** joined, aggregated business questions ([queries](../sql/olist_analysis_queries.sql))

The interactive [Tableau dashboard](https://public.tableau.com/shared/26D5ZS9ZF?:display_count=n&:origin=viz_share_link) visualizes the main results.

---

## Contents

- [Business Questions](#business-questions)
- [Data Quality Notes](#data-quality-notes)
- [Phase 1: Table-Level Findings (Python)](#phase-1-table-level-findings-python)
- [Phase 2: Joined & Aggregated Findings (SQL)](#phase-2-joined--aggregated-findings-sql)
- [Summary & Recommendations](#summary--recommendations)

---

## Business Questions

| # | Question | Where answered |
|---|----------|----------------|
| Q1 | How does review score relate to delivery timing? | Python section 10 + SQL Q1 |
| Q2 | Which city generates the most revenue? | SQL Q2 |
| Q3 | Which product categories are in highest demand? | SQL Q3 |
| Q4 | How do sellers compare on volume vs. satisfaction? | SQL Q4a / Q4b |
| Q5 | How do shipping cost and delivery time vary by state? | SQL Q5 |
| Q6 | Which products generate the most revenue, and where do they sell from? | SQL Q6 |
| Q7 | Which zip codes perform best? | SQL Q7 |
| Q8 | How much revenue comes from repeat vs. one-time customers? | SQL Q8 |
| Q9 | Which states have the highest order failure rate? | SQL Q9 |
| Q10 | Which month had the highest order volume and revenue? | SQL Q10 |

Two early questions, "how long does delivery take?" and "delivery days for the lowest reviews", are answered directly in the Python EDA (Order Details and Order Reviews sections). "Products per seller" was dropped as a low-value count with no clear business action.

---

## Data Quality Notes

Issues found and fixed during cleaning. They affect how the results should be read:

| Issue | Fix | Impact |
|-------|-----|--------|
| **814 reused `review_id`s**: the same review is attached to more than one order | Kept the first occurrence (`drop_duplicates(subset='review_id')`) before any review analysis | 99,224 → 98,410 review rows; each review counted once, and Python and SQL results agree |
| **Accent inconsistency in city names**: "sao paulo" and "são paulo" counted as two cities | Lowercase + Unicode normalization to ASCII | Sao Paulo = **160,719** location records, not ~135,800 |
| **Trailing carriage return in English category names** (`'health_beauty\r'`) | `str.strip()` on the translation table | Clean category labels in SQL and Tableau |
| **Incomplete time edges**: Sep–Dec 2016 has 1–2 orders/month (pilot phase); Sep 2018 is partial | Time-based analysis scoped to **Jan 2017 – Aug 2018** | Monthly trends aren't distorted by edge months |
| Raw column names | `freight_value` → `shipping_cost`, `customer_zip_code_prefix` → `zipcode` | Readable SQL |

---

## Phase 1: Table-Level Findings (Python)

### Customers
- 99,441 order records map to **96,096 unique customers** (`customer_unique_id`).
- **Repeat-customer rate: 3.12%.** The most loyal customer ordered 17 times; the next-highest ordered 9.
- ~42% of customers are in SP state and ~13% in RJ. At city level, ~15.6% are in Sao Paulo and ~7% in Rio de Janeiro.
- Sao Paulo city has the most customers (15,540); zip code 22790 (Rio de Janeiro) has the most customers of any zip code (142).

### Order Items
- Item price: mean \$120.65, median \$74.99. Shipping cost: mean \$19.99, median \$16.26.
- **Shipping averages 32.1% of item price**, a heavy relative cost on cheap items.
- 88,863 orders contain a single item; the largest order has 21 items.
- Highest-revenue product: `bb50f2e236e5eea0100680137654686c` (\$63,885).

### Order Payments
- Mean payment value \$154.10; most payments are around \$50, with a maximum of \$13,664.
- Payment types: credit card 76,795 · boleto 19,784 · voucher 5,775 · debit card 1,529 · not defined 3.
- 52,546 payments are made in a single installment; the distribution has a long tail up to 24 installments.

### Order Details
- 96,478 of 99,441 orders (97%) were delivered.
- Most orders arrive within 10 days of approval (median ≈ 9.9 days, mean ≈ 12.1 days).

### Product Details
- 32,951 products across 73 categories (71 have English translations).
- Weight, length, height and width are moderately correlated (r ≈ 0.20–0.56). Photo count is essentially uncorrelated with physical size (r ≈ 0.00–0.07), as expected for a listing choice.

### Sellers
- 3,095 sellers: 1,849 in SP state and 349 in PR; by city, 694 in Sao Paulo and 127 in Curitiba.
- Zip code 14940 hosts 49 sellers; the next-highest zip code has 10.

### Order Reviews
- Scores (after the duplicate fix): 5 = 56,910 · 4 = 19,007 · 1 = 11,282 · 3 = 8,097 · 2 = 3,114. Strongly skewed to 5 stars, with a secondary spike at 1 star.
- 75.4% of low reviews (score ≤ 2) include a written comment.
- **27.58% of low-rated orders were delivered after the estimated delivery date.**
- Order status strongly predicts dissatisfaction: 12.8% of delivered orders get a low review, compared with 69–93% for shipped, canceled, invoiced, unavailable and processing orders.
- Average delivery timing falls steadily with review score: 1★ orders arrive 4.0 days before the estimate, 5★ orders 13.4 days before.

![Average delivery timing vs. estimate by review score](../images/review_score_vs_delivery.png)

---

## Phase 2: Joined & Aggregated Findings (SQL)

### Q1: Review score vs. delivery timing
| Review group | Avg days vs. estimate | Orders |
|---|---|---|
| High (3–5) | −12.9 (early) | 83,404 |
| Low (1–2) | −5.1 (early) | 12,203 |

Both groups arrive before the estimate on average, but low-rated orders have a much smaller "early-delivery cushion". **Welch's t-test: t = −54.44, p < 0.0001.** The gap is not random variation.

### Q2: Revenue by city
Sao Paulo leads with **\$1,914,924.54** across 15,402 orders. Rio de Janeiro is second with \$992,538.86 across 6,834 orders, about half of Sao Paulo's revenue.

### Q3: Revenue and demand by category
| Category | Units | Revenue | Avg price |
|---|---|---|---|
| health_beauty | 9,670 | **\$1,258,681.34** (highest revenue) | \$130.16 |
| watches_gifts | 5,991 | \$1,205,005.68 | **\$201.14** (highest price) |
| bed_bath_table | **11,115** (highest volume) | \$1,036,988.68 | \$93.30 |

Volume doesn't guarantee revenue. health_beauty out-earns bed_bath_table with fewer units, and watches_gifts ranks second in revenue on price alone.

### Q4: Seller performance, volume vs. satisfaction
- **Top by volume:** `6560211a19b47992c3666cc44a7e94c0` handled 1,834 orders with an average score of 3.91.
- **Top by satisfaction (≥ 20 orders):** `48efc9d94a9834137efd9ea76b065a38` has a perfect 5.0 across 33 orders.

The two lists differ: sellers to scale with are not the same as sellers to learn from.

### Q5: Shipping cost and delivery time by state
- **Most expensive and slowest:** Roraima (RR) and Paraíba (PB), both averaging \$43.09 shipping, with 27.7 and 19.9 days to deliver.
- **Cheapest and fastest:** Sao Paulo (SP), with \$15.11 shipping and 8.2 days, which matches its lead in revenue and order volume.

### Q6: Top revenue products
- `bb50f2e236e5eea0100680137654686c` (seller in Sao Bernardo do Campo, SP): **\$63,885.00** across 195 units.
- `6cdd53843498f92890544667809f1595` (Curitiba, PR): \$54,730.20 across 156 units.
- `aca2eb7d00ea1a7b8ebd4e68314663af` (Sao Paulo, SP) has the most units in the top 10 (527) but only \$37,608.90 in revenue, a much lower price point.
- 6 of the top 10 revenue products come from SP-based sellers.

### Q7: Best-performing zip codes
Zip code **22790 (Rio de Janeiro)** leads with \$22,154.89 across 142 orders.

### Q8: Repeat vs. one-time customers
| Type | Customers | Revenue | Avg per customer |
|---|---|---|---|
| One-time | 92,507 | \$12,828,351.84 | \$138.67 |
| Repeat | 2,913 (~3%) | \$763,291.86 | **\$262.03** |

Repeat customers spend nearly twice as much each, which makes retention a high-leverage opportunity despite the low repeat rate.

### Q9: Order failure rate by state (≥ 100 orders)
- SP has the most orders (41,746) and a below-average failure rate of 1.48%.
- **Highest:** Rondônia (RO) at 2.77%. **Lowest:** Alagoas (AL) at 0.48%.
- No clear link between volume and failure rate.

### Q10: Monthly trend (Jan 2017 – Aug 2018)
**November 2017** had the highest order volume (7,421) and revenue (\$1,003,862.14) of any complete month, consistent with Black Friday seasonality. Volume then held at a higher plateau of roughly 6,000–7,200 orders per month through 2018.

---

## Summary & Recommendations

**Main finding:** delivery performance drives customer satisfaction. Three independent views agree:

- **Python:** 27.58% of low-rated orders arrived late.
- **SQL:** the early-delivery cushion shrinks from ~13 days (high ratings) to ~5 days (low ratings).
- **Statistics:** Welch's t = −54.44, p < 0.0001.

**Recommendations**

1. **Protect the delivery promise.** Set estimated delivery dates by region so that slow, expensive states (RR, PB, and other northern and northeastern states) get realistic estimates. Proactively notify customers when an order is at risk of arriving late.
2. **Invest in logistics outside the Southeast.** In the slowest states, shipping costs nearly 3× as much as in SP and takes 2.4–3.4× as long. Regional fulfillment or carrier renegotiation targets both satisfaction and conversion.
3. **Build retention.** Only ~3% of customers return, but they spend ~2× more each. Post-purchase campaigns, timed ahead of the November peak, are the clearest revenue lever.
4. **Manage sellers on satisfaction as well as volume.** The highest-volume seller averages 3.91★. Share the practices of top-rated sellers and flag high-volume, low-rating sellers for review.
5. **Lean into price mix.** High-ticket categories (watches_gifts, health_beauty) generate outsized revenue per unit and are good candidates for promotion.

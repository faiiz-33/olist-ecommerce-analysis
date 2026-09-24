# Tableau Dashboard

### [▶ Open the live dashboard on Tableau Public](https://public.tableau.com/shared/26D5ZS9ZF?:display_count=n&:origin=viz_share_link)

**Dashboard:** Brazilian E-Commerce (Olist)

## Data model

The nine cleaned tables (`data/*_updated.csv`) are joined in a Tableau **relationship model** with `order_details` at the center, so each sheet aggregates at its own level of detail without join duplication. CSVs were exported directly from Python rather than MySQL Workbench, which avoids Workbench's 1,000-row export cap.

## Sheets

| Sheet | Question it answers |
|---|---|
| `spending vs date` | How did order revenue trend month to month? (Nov 2017 Black Friday peak) |
| `product cat vs spending` | Which product categories generate the most revenue? |
| `map` | How is revenue distributed across Brazilian states? |
| `avg delivery vs review score` | Do late or barely-on-time deliveries lead to worse reviews? |
| `price vs reviews` | Does item price affect review score? |
| `payment installment vs price` | Do higher-priced orders use more installments? |

## Opening the workbook locally

`olist_dashboard.twb` connects to the cleaned CSVs. After running the notebook, open the workbook in Tableau Desktop or Tableau Public. If prompted for the data location, point it to the `data/` folder.

# Introduction

In this scenario an e-commerce platform is currently seeing a strong overall conversion rate. However, management is concerned that this strong overall rate may mask significant leakage at individual funnel stages due to limited visibility. So I was tasked to find and identify if such leaks exists, and create a tool for future monitoring and reporting so the company can stay ahead of the game.

# Dataset

For the full field descriptions see the  [Data Dictionary](https://github.com/theodorosmalezidis/E_Commerce_Funnel_Optimization/blob/main/Data%20Dictionary.md).

# Project Workflow & Goals

To address management's concerns i constructed a two-phase execution: 

 **Phase 1: Diagnostic Analysis**

 - Audit the end-to-end customer journey to quantify stage-by-stage conversion rates and identify any significant leakage.
 
  **Phase 2: Developing a BI tool solution**

 - Develop a permanent, automated monitoring tool for real-time BI reporting.


This approach ensures both a diagnostic understanding of the problem and an operational solution for the future.




# My Tools for the Project

- **Google Big Query :** Cloud Data Warehouse used for ingesting the raw dataset, hosting tables, and executing all SQL analytical queries.
- **SQL :** Primary language for data exploration, analysis and manipulation. 
- **VS Code :**  Integrated environment for project structuring, Markdown documentation, and local file management.
- **Git :** Version control for tracking code changes and project history.
- **GitHub :** Platform for hosting and sharing scripts and documentation.


# Phase 1: Diagnostic Analysis

- Step 1: Calculate the percentage of users who successfully transition from one stage of the customer journey to the next.

```sql
with funnel_stages as(

  select
      count(distinct case when event_type='page_view' then user_id end) as stage_1_view
    , count(distinct case when event_type='add_to_cart' then user_id end) as stage_2_add_to_cart
    , count(distinct case when event_type='checkout_start' then user_id end) as stage_3_checkout
    , count(distinct case when event_type='payment_info' then user_id end) as stage_4_payment
    , count(distinct case when event_type='purchase' then user_id end) as stage_5_purchase

  from
    `user-events-491208.user_events.user_events`
)

select
    round((stage_2_add_to_cart*100.0/stage_1_view), 2) as view_to_cart_rate
  , round((stage_3_checkout*100.0/stage_2_add_to_cart), 2) as cart_to_checkout_rate
  , round((stage_4_payment*100.0/stage_3_checkout), 2) as checkout_to_payment_rate
  , round((stage_5_purchase*100.0/stage_4_payment), 2) as payment_to_purchase_rate
  , round((stage_5_purchase*100.0/stage_1_view), 2) as conversion_rate

from
  funnel_stages
```
<br><br>
*Table 1*
| Metric                      | Rate (%) |
|-----------------------------|----------|
| View to Cart Rate           | 31.06    |
| Cart to Checkout Rate       | 71.02    |
| Checkout to Payment Rate    | 81.50    |
| Payment to Purchase Rate    | 91.88    |
| Conversion Rate             | 16.52    |


First obvious finding is the big leakage in the first stage from view to cart, all other stages show conversion rates roughly between 71% and 92%, quite high. As quite high is the overall conversion rate of 16.52%.

- Step 2: Driil down and calculate funnel conversion rates by different angles to identify if this leakage is emerging in all of them.

**By country**
```sql
with country_funnel as(

  select
      country
    , count(distinct case when event_type='page_view' then user_id end) as views
    , count(distinct case when event_type='add_to_cart' then user_id end) as carts
    , count(distinct case when event_type='checkout_start' then user_id end) as checkouts
    , count(distinct case when event_type='payment_info' then user_id end) as payments
    , count(distinct case when event_type='purchase' then user_id end) as purchases

  from
    `user-events-491208.user_events.user_events`
  group by
    country
)
select
    country
  , round((carts*100.0/views), 2) as cart_conversion_rate
  , round((checkouts*100.0/carts), 2) as checkout_conversion_rate
  , round((payments*100.0/checkouts), 2) as payment_conversion_rate
  , round((purchases*100.0/payments), 2) as purchase_conversion_rate
  , round((purchases*100.0/views), 2)as overall_conversion_rate
  
from
  country_funnel
order by
  overall_conversion_rate desc
```
<br><br>
*Table 2*

| Country | cart_conversion_rate (%) |checkout_conversion_rate (%) | payment_conversion_rate (%) | purchase_conversion_rate (%) | overall_conversion_rate (%) |
|:---|:---|:---|:---|:---|:---|
| United Kingdom | 34.02 | 73.28 | 81.18 | 95.65 | 19.35 |
| Australia | 34.97 | 73.68 | 75.00 | 95.24 | 18.40 |
| France | 31.80 | 72.12 | 84.00 | 95.24 | 18.35 |
| Japan | 31.50 | 79.61 | 76.83 | 95.24 | 18.35 |
| Netherlands | 30.12 | 77.00 | 83.12 | 87.50 | 16.87 |
| Germany | 31.45 | 66.00 | 86.36 | 92.98 | 16.67 |
| Spain | 32.92 | 64.49 | 84.06 | 91.38 | 16.31 |
| India | 31.67 | 73.68 | 79.76 | 86.57 | 16.11 |
| Brazil | 31.56 | 68.14 | 83.12 | 89.06 | 15.92 |
| USA | 29.10 | 70.11 | 80.33 | 95.92 | 15.72 |
| Canada | 31.35 | 72.00 | 79.17 | 87.72 | 15.67 |
| South Korea | 25.83 | 72.09 | 91.94 | 91.23 | 15.62 |
| Mexico | 32.43 | 70.00 | 79.76 | 85.07 | 15.41 |
| Sweden | 27.51 | 68.75 | 83.33 | 92.73 | 14.61 |
| Italy | 29.43 | 63.44 | 77.97 | 100.00 | 14.56 |

Same findings in country level for the funnel stage we investigate, the conversion rate ranges from 25.83% to 34.97%

**By product category**

```sql
with category_funnel as(

  select
      product_category
    , count(distinct case when event_type='page_view' then user_id end) as views
    , count(distinct case when event_type='add_to_cart' then user_id end) as carts
    , count(distinct case when event_type='checkout_start' then user_id end) as checkouts
    , count(distinct case when event_type='payment_info' then user_id end) as payments
    , count(distinct case when event_type='purchase' then user_id end) as purchases

  from
    `user-events-491208.user_events.user_events`
  group by
    product_category
)

select
    product_category
  , round((carts*100.0/views), 2) as cart_conversion_rate
  , round((checkouts*100.0/carts), 2) as checkout_conversion_rate
  , round((payments*100.0/checkouts), 2) as payment_conversion_rate
  , round((purchases*100.0/payments), 2) as purchase_conversion_rate
  , round((purchases*100.0/views), 2)as overall_conversion_rate
  
from
  category_funnel
order by
  overall_conversion_rate desc
```

<br><br>
*Table 3*
| Product Category | cart_conversion_rate (%) | checkout_conversion_rate (%) | payment_conversion_rate (%) | purchase_conversion_rate (%) | overall_conversion_rate (%) |
|:---|:---|:---|:---|:---|:---|
| Accessories | 31.39 | 74.62 | 82.23 | 90.74 | 17.48 |
| Other | 30.88 | 70.56 | 83.43 | 92.47 | 16.81 |
| Electronics | 30.62 | 73.39 | 78.02 | 94.37 | 16.54 |
| Home & Kitchen | 32.12 | 67.73 | 80.63 | 91.56 | 16.06 |
| Apparel | 30.40 | 69.58 | 81.42 | 89.93 | 15.49 |

Same findings in product category level too for the funnel stage we investigate, the conversion rate ranges from 30.40% to 32.12%


**By traffic source**

```sql
with source_funnel as(

  select
      traffic_source
    , count(distinct case when event_type='page_view' then user_id end) as views
    , count(distinct case when event_type='add_to_cart' then user_id end) as carts
    , count(distinct case when event_type='checkout_start' then user_id end) as checkouts
    , count(distinct case when event_type='payment_info' then user_id end) as payments
    , count(distinct case when event_type='purchase' then user_id end) as purchases

  from
    `user-events-491208.user_events.user_events`
  group by
    traffic_source
)

select
    traffic_source
  , round((carts*100.0/views), 2) as cart_conversion_rate
  , round((checkouts*100.0/carts), 2) as checkout_conversion_rate
  , round((payments*100.0/checkouts), 2) as payment_conversion_rate
  , round((purchases*100.0/payments), 2) as purchase_conversion_rate
  , round((purchases*100.0/views), 2)as overall_conversion_rate
  
from
  source_funnel
order by
  views desc
```
<br><br>
*Table 4*

| Traffic Source | cart_conversion_rate (%) | checkout_conversion_rate (%) | payment_conversion_rate (%) | purchase_conversion_rate (%) | overall_conversion_rate (%) |
|:---|:---|:---|:---|:---|:---|
| Email | 62.45 | 69.94 | 83.33 | 93.16 | 33.91 |
| Paid Ads | 36.98 | 72.91 | 82.76 | 94.44 | 21.07 |
| Organic | 32.83 | 70.70 | 80.55 | 90.03 | 16.83 |
| Social | 13.59 | 70.50 | 79.43 | 91.07 | 6.93 |

An interesting result, although in general we meet the same trend here in funnel conversion rates, social as traffic source have lower than average numbers especially in both cart_conversion_rate and overall_conversion_rate with 13.59% and 6.93% respectively, where email traffic showcases significantly higher rates with 62.45% and 33.91% in the same funnel stages.

Step 2 Summary: The "View to Cart" leakage is universal across all dimensions. While Country and Product Category show relative stability, Traffic Source reveals the most extreme variance: Social is the weakest link (13.59% View to Cart), while Email is the strongest (62.45% View to Cart).

- Step 3: Calculate session-based funnel conversion time for both total and complete journes.

```sql
with funnel_duration as(

  select
      session_id
    , min(case when event_type='page_view' then event_date end) as view_time
    , min(case when event_type='add_to_cart' then event_date end) as cart_time
    , min(case when event_type='checkout_start' then event_date end) as checkout_time
    , min(case when event_type='payment_info' then event_date end) as payment_time
    , min(case when event_type='purchase' then event_date end) as purchase_time

  from
    `user-events-491208.user_events.user_events`
  group by
    session_id
)
select
    count(*) as total_journes
  , round(avg(timestamp_diff(cart_time, view_time, minute)), 2) as avg_view_to_cart_minutes
  , round(avg(timestamp_diff(checkout_time, cart_time, minute)), 2) as avg_cart_to_checkout_minutes
  , round(avg(timestamp_diff(payment_time, checkout_time, minute)), 2) as avg_checkout_to_payment_minutes
  , round(avg(timestamp_diff(purchase_time, payment_time, minute)), 2) as avg_payment_to_purchase_minutes
  , round(avg(timestamp_diff(purchase_time, view_time, minute)), 2) as avg_total_jurney_minutes

from
  funnel_duration
```
<br><br>
*Table 5*
| Metric | Value |
|:---|:---|
| Total Journeys | 5000 |
| Avg. View to Cart (Min) | 11.06 |
| Avg. Cart to Checkout (Min) | 5.44 |
| Avg. Checkout to Payment (Min) | 5.05 |
| Avg. Payment to Purchase (Min) | 3.04 |
| Avg. Total Journey (Min) | 24.63 |

```sql
with funnel_complete_duration as(

  select
      session_id
    , min(case when event_type='page_view' then event_date end) as view_time
    , min(case when event_type='add_to_cart' then event_date end) as cart_time
    , min(case when event_type='checkout_start' then event_date end) as checkout_time
    , min(case when event_type='payment_info' then event_date end) as payment_time
    , min(case when event_type='purchase' then event_date end) as purchase_time
  from
    `user-events-491208.user_events.user_events`
  group by
    session_id
  having
    min(case when event_type='purchase' then event_date end) is not null -- to calculate only complete journeys

)

select
    count(*) as total_complete_journes
  , round(avg(timestamp_diff(cart_time, view_time, minute)), 2) as avg_view_to_cart_minutes
  , round(avg(timestamp_diff(checkout_time, cart_time, minute)), 2) as avg_cart_to_checkout_minutes
  , round(avg(timestamp_diff(payment_time, checkout_time, minute)), 2) as avg_checkout_to_payment_minutes
  , round(avg(timestamp_diff(purchase_time, payment_time, minute)), 2) as avg_payment_to_purchase_minutes
  , round(avg(timestamp_diff(purchase_time, view_time, minute)), 2) as avg_total_jurney_minutes
from
  funnel_complete_duration
```
<br><br>
*Table 6*
| Metric | Value |
|:---|:---|
| Total Complete Journeys | 826 |
| Avg. View to Cart (Min) | 11.16 |
| Avg. Cart to Checkout (Min) | 5.37 |
| Avg. Checkout to Payment (Min) | 5.06 |
| Avg. Payment to Purchase (Min) | 3.04 |
| Avg. Total Journey (Min) | 24.63 |

Step 3 summary: For comparison and to reveal if there is any difference in conversion time within funnel stages, between total and only complete journes i calculated both, although the final stages will always be identical in both cases because the total sessions view lacks data for incomplete journeys. The highlight of the results is the Front-End Delay: the initial View to Cart stage is the longest part of the journey in both cases, averaging 11.16 minutes for successful buyers and 11.06 for total journeys, showing the highest duration amongst all the stages. Another proof that this stage of the funnel costs the platform a considerable number of potential buyers.

# Phase 2: Developing a BI tool solution

# Findings & Recommendations


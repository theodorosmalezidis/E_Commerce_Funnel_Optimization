/*  Global Conversion Rates 
   Calculates the percentage of users moving between each funnel stage and the overall conversion rate. */

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
  , round((stage_5_purchase*100.0/stage_1_view), 2) as convertion_rate
from
  funnel_stages;


/* Funnel Performance by Country 
 stage-to-stage conversion rates by geographic location, ordered by overall success. */

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
  overall_conversion_rate desc;


/* Funnel Performance by Product Category 
   analyzes how different product types convert from initial view to final purchase. */

with country_funnel as(
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
  country_funnel
order by
  overall_conversion_rate desc;


/* Funnel Performance by Traffic Source 
   analyzes funnel conversion rates across different marketing channels. */

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
  views desc;


/* Average Time to Conversion (All Sessions) 
   measures the average time duration of funnel stages for all sessions. */

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
  funnel_duration;



/* Average Time to Conversion (Complete Journeys) 
   measures the average time duration of funnel stages, focused only  on sessions that completed the journey. */


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
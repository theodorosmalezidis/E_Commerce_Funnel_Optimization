/*  SCHEDULED WEEKLY REFRESH
   Generates a master funnel summary for the last 7 days to power automated dashboards and weekly reporting. */

create or replace table `user-events-491208.user_events.weekly_global_funnel_summary` as

with funnel_stages as(
  select
      traffic_source
    , count(distinct user_id) as total_visitors
    , count(distinct case when event_type='page_view' then user_id end) as stage_1_view
    , count(distinct case when event_type='add_to_cart' then user_id end) as stage_2_add_to_cart
    , count(distinct case when event_type='checkout_start' then user_id end) as stage_3_checkout
    , count(distinct case when event_type='payment_info' then user_id end) as stage_4_payment
    , count(distinct case when event_type='purchase' then user_id end) as stage_5_purchase
  from
    `user-events-491208.user_events.user_events`
  where
    date(event_date) between date_sub(current_date(), interval 7 day) and current_date()
  group by
    traffic_source  
)
select
    traffic_source
  , total_visitors
  , round((stage_2_add_to_cart*100.0/stage_1_view), 2) as view_to_cart_rate
  , round((stage_3_checkout*100.0/stage_2_add_to_cart), 2) as cart_to_checkout_rate
  , round((stage_4_payment*100.0/stage_3_checkout), 2) as checkout_to_payment_rate
  , round((stage_5_purchase*100.0/stage_4_payment), 2) as payment_to_purchase_rate
  , round((stage_5_purchase*100.0/stage_1_view), 2) as conversion_rate
from
  funnel_stages
order by 
  conversion_rate desc;


/* PARAMETRIC STORED PROCEDURE
   Enables on-demand funnel analysis by traffic source for a specific target country without modifying code. */

CREATE OR REPLACE PROCEDURE `user-events-491208.user_events.funnel_by_source_for_country`(target_country STRING)
BEGIN

with funnel_stages as(
  select
      traffic_source
    , count(distinct user_id) as total_visitors
    , count(distinct case when event_type='page_view' then user_id end) as stage_1_view
    , count(distinct case when event_type='add_to_cart' then user_id end) as stage_2_add_to_cart
    , count(distinct case when event_type='checkout_start' then user_id end) as stage_3_checkout
    , count(distinct case when event_type='payment_info' then user_id end) as stage_4_payment
    , count(distinct case when event_type='purchase' then user_id end) as stage_5_purchase
  from
    `user-events-491208.user_events.user_events`
  where
    country = target_country
  group by
    traffic_source  
)
select
    target_country as country
  , traffic_source
  , total_visitors
  , round((stage_2_add_to_cart*100.0/stage_1_view), 2) as view_to_cart_rate
  , round((stage_3_checkout*100.0/stage_2_add_to_cart), 2) as cart_to_checkout_rate
  , round((stage_4_payment*100.0/stage_3_checkout), 2) as checkout_to_payment_rate
  , round((stage_5_purchase*100.0/stage_4_payment), 2) as payment_to_purchase_rate
  , round((stage_5_purchase*100.0/stage_1_view), 2) as conversion_rate
from
  funnel_stages
order by 
  conversion_rate desc;

END;

/* EXECUTION: On-Demand Regional Analysis
   Triggers the stored procedure to calculate real-time funnel metrics for a specific country (e.g., 'USA'). */

CALL `user-events-491208.user_events.funnel_by_source_for_country`('USA');
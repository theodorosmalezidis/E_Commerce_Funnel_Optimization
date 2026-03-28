

# Data Dictionary

### 1. **user_events Table**


| Column Name      | Data Type     | Description                                                                                   |
|------------------|---------------|-----------------------------------------------------------------------------------------------|
| user_id       | INT          | Unique identifier for each individual user.
| session_id        | STRING           | Unique identifier for a single browsing session (one user can have many).                                        |
| event_id | INT  | A unique identifier for each specific action within asession (a session can have many).         |
| event_type          | STRING  | Type of user action (e.g., page_view, add_to_cart, purchase).                                  |
| event_date    | TIMESTAMP  | Exact date and time when the event occurred.                                                |
| product_id| INT  | Unique identifier for the product involved in the event.                               |
| amount      | FLOAT        | Transaction value (populated for purchase events only).
| traffic_source     | STRING          | Marketing channel that referred the user (e.g., Social, Organic).                                  |
| country      | STRING  | The user's geographic location (Country of residence).               |
| product_category           | STRING  | The category to which the product belongs.|

---



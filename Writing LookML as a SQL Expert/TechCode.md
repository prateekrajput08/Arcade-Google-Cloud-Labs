# 🌐 Writing LookML as a SQL Expert || GSP1332 🚀 [![Open Lab](https://img.shields.io/badge/Open-Lab-blue?style=flat)](https://www.skills.google/games/6976/labs/43318)

## ⚠️ Disclaimer ⚠️

<blockquote style="background-color: #fffbea; border-left: 6px solid #f7c948; padding: 1em; font-size: 15px; line-height: 1.5;">
  <strong>Educational Purpose Only:</strong> This script and guide are provided for the educational purposes to help you understand the lab services and boost your career.Before using the script, please open and review it to familiarize yourself with Google Cloud services.
  <br><br>
  <strong>Terms Compliance:</strong> Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learningexperience — not to circumvent it.
</blockquote>

---

<div style="padding: 15px; margin: 10px 0;">

## Create View `order_items`

```bash
view: order_items {
  sql_table_name: `cloud-training-demos.thelook_ecommerce.order_items` ;;
  drill_fields: [id]

  # ---------------------------
  # PRIMARY KEY
  # ---------------------------
  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
  }

  # ---------------------------
  # DATE DIMENSION GROUPS
  # ---------------------------
  dimension_group: created {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.created_at ;;
  }

  dimension_group: delivered {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.delivered_at ;;
  }

  dimension_group: returned {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.returned_at ;;
  }

  dimension_group: shipped {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.shipped_at ;;
  }

  # ---------------------------
  # OTHER DIMENSIONS
  # ---------------------------
  dimension: inventory_item_id {
    type: number
    sql: ${TABLE}.inventory_item_id ;;
  }

  dimension: order_id {
    type: number
    sql: ${TABLE}.order_id ;;
  }

  dimension: product_id {
    type: number
    sql: ${TABLE}.product_id ;;
  }

  dimension: user_id {
    type: number
    sql: ${TABLE}.user_id ;;
  }

  dimension: sale_price {
    type: number
    sql: ${TABLE}.sale_price ;;
  }

  dimension: status {
    type: string
    sql: ${TABLE}.status ;;
  }

  # ---------------------------
  # MEASURES
  # ---------------------------
  measure: count {
    label: "# of Order Items"
    type: count
    drill_fields: [id]
  }

  measure: total_sale_price {
    type: sum
    sql: ${sale_price} ;;
    value_format_name: usd
  }

  measure: customer_dividends {
    description: "Customers receive 10% of their total sales as a gift card for future purchases."
    type: number
    sql: 0.1 * ${total_sale_price} ;;
    value_format_name: usd
  }
}
```

## Open:  `qwiklabs-looker.model`
```bash
explore: order_items {
  label: "Ordered Items"

  join: users {
    type: left_outer
    sql_on: ${order_items.user_id} = ${users.id} ;;
    relationship: many_to_one
  }
}
```

## Update `order_items.view`

```bash
view: order_items {
  sql_table_name: `cloud-training-demos.thelook_ecommerce.order_items` ;;
  drill_fields: [id]

  # =========================
  # PRIMARY KEY
  # =========================
  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
  }

  # =========================
  # DATE DIMENSION GROUPS
  # =========================
  dimension_group: created {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.created_at ;;
  }

  dimension_group: delivered {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.delivered_at ;;
  }

  dimension_group: returned {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.returned_at ;;
  }

  dimension_group: shipped {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.shipped_at ;;
  }

  # =========================
  # OTHER DIMENSIONS
  # =========================
  dimension: inventory_item_id {
    type: number
    sql: ${TABLE}.inventory_item_id ;;
  }

  dimension: order_id {
    type: number
    sql: ${TABLE}.order_id ;;
  }

  dimension: product_id {
    type: number
    sql: ${TABLE}.product_id ;;
  }

  dimension: user_id {
    type: number
    sql: ${TABLE}.user_id ;;
  }

  dimension: sale_price {
    type: number
    sql: ${TABLE}.sale_price ;;
  }

  dimension: status {
    type: string
    sql: ${TABLE}.status ;;
  }

  # =========================
  # MEASURES
  # =========================
  measure: count {
    label: "# of Order Items"
    type: count
    drill_fields: [id]
  }

  measure: total_sale_price {
    type: sum
    sql: ${sale_price} ;;
    value_format_name: usd
  }

  measure: customer_dividends {
    description: "Customers receive 10% of their total sales as a gift card for future purchases."
    type: number
    sql: 0.1 * ${total_sale_price} ;;
    value_format_name: usd
  }
}
```

## Create View `top_100_users`

```bash
view: top_100_users {
  derived_table: {
    explore_source: order_items {
      column: user_id {}
      column: customer_dividends {}
      column: total_sale_price {}
      column: email { field: users.email }
    }
  }

  dimension: user_id {
    primary_key: yes
    type: number
  }

  dimension: customer_dividends {
    value_format: "$#,##0.00"
    type: number
  }

  dimension: total_sale_price {
    value_format: "$#,##0.00"
    type: number
  }

  dimension: email {
    type: string
  }
}
```

</div>

---
## 🎉 **Congratulations! Lab Completed Successfully!** 🏆

<div style="text-align:center; padding: 10px 0; max-width: 640px; margin: 0 auto;">
  <h3 style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin-bottom: 14px;">📱 Join the Tech & Code Community</h3>
  <a href="https://www.youtube.com/@TechCode9?sub_confirmation=1" style="margin: 0 6px; display: inline-block;">
    <img src="https://img.shields.io/badge/Subscribe-Tech%20&%20Code-FF0000?style=for-the-badge&logo=youtube&logoColor=white" alt="YouTube Channel">
  </a>
  <a href="https://www.linkedin.com/in/prateekrajput08/" style="margin: 0 6px; display: inline-block;">
    <img src="https://img.shields.io/badge/LinkedIn-Prateek%20Rajput-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn Profile">
  </a>
  <a href="https://t.me/techcode9" style="margin: 0 6px; display: inline-block;">
    <img src="https://img.shields.io/badge/Telegram-Tech%20Code-0088cc?style=for-the-badge&logo=telegram&logoColor=white" alt="Telegram Channel">
  </a>
  <a href="https://www.instagram.com/techcodefacilitator" style="margin: 0 6px; display: inline-block;">
    <img src="https://img.shields.io/badge/Instagram-Tech%20Code-E4405F?style=for-the-badge&logo=instagram&logoColor=white" alt="Instagram Profile">
  </a>
</div>

---

<div align="center">
  <p style="font-size: 12px; color: #586069;">
    <em>This guide is provided for educational purposes. Always follow Qwiklabs terms of service and YouTube's community guidelines.</em>
  </p>
  <p style="font-size: 12px; color: #586069;">
    <em>Last updated: December 2025</em>
  </p>
</div>

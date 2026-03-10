# 🌐 Getting Started with Liquid to Customize the Looker User Experience || GSP933 🚀 [![Open Lab](https://img.shields.io/badge/Open-Lab-blue?style=flat)](https://www.skills.google/games/6880/labs/42752)

## ⚠️ Disclaimer ⚠️

<blockquote style="background-color: #fffbea; border-left: 6px solid #f7c948; padding: 1em; font-size: 15px; line-height: 1.5;">
  <strong>Educational Purpose Only:</strong> This script and guide are provided for the educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services.
  <br><br>
  <strong>Terms Compliance:</strong> Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience — not to circumvent it.
</blockquote>

---

<div style="padding: 15px; margin: 10px 0;">

## Update `User.view`:
```bash
view: users {
  sql_table_name: `cloud-training-demos.looker_ecomm.users`
    ;;
  drill_fields: [id]

  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
  }

  dimension: age {
    type: number
    sql: ${TABLE}.age ;;
  }

  dimension: city {
    type: string
    sql: ${TABLE}.city ;;
  }

  dimension: city_link {
    type: string
    sql: ${TABLE}.city ;;
    link: {
      label: "Search the web"
      url: "http://www.google.com/search?q={{ value | url_encode }}"
      icon_url: "http://www.google.com/s2/favicons?domain=www.{{ value | url_encode }}.com"
    }
  }

  dimension: order_history_button {
    label: "Order History"
    sql: ${TABLE}.id ;;
    html: <a href="/explore/training_ecommerce/order_items?fields=order_items.order_item_id, users.first_name, users.last_name, users.id, order_items.order_item_count, order_items.total_revenue&f[users.id]={{ value }}"><button>Order History</button></a> ;;
  }

  dimension: country {
    type: string
    map_layer_name: countries
    sql: ${TABLE}.country ;;
  }

  dimension_group: created {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.created_at ;;
  }

  dimension: email {
    type: string
    sql: ${TABLE}.email ;;
  }

  dimension: first_name {
    type: string
    sql: ${TABLE}.first_name ;;
  }

  dimension: gender {
    type: string
    sql: ${TABLE}.gender ;;
  }

  dimension: last_name {
    type: string
    sql: ${TABLE}.last_name ;;
  }

  dimension: latitude {
    type: number
    sql: ${TABLE}.latitude ;;
  }

  dimension: longitude {
    type: number
    sql: ${TABLE}.longitude ;;
  }

  dimension: state {
    type: string
    sql: ${TABLE}.state ;;
    map_layer_name: us_states
  }
  
  dimension: state_link {
    type: string
    sql: ${TABLE}.state ;;
    map_layer_name: us_states
    html: {% if _explore._name == "order_items" %}
          <a href="/explore/training_ecommerce/order_items?fields=order_items.detail*&f[users.state]= {{ value }}">{{ value }}</a>
        {% else %}
          <a href="/explore/training_ecommerce/users?fields=users.detail*&f[users.state]={{ value }}">{{ value }}</a>
        {% endif %} ;;
  }

  dimension: traffic_source {
    type: string
    sql: ${TABLE}.traffic_source ;;
  }

  dimension: zip {
    type: zipcode
    sql: ${TABLE}.zip ;;
  }

  measure: count {
    type: count
    drill_fields: [id, last_name, first_name, events.count, order_items.count]
  }
}
```
## Update `order_item.view`
```bash
view: order_items {
    sql_table_name: `cloud-training-demos.looker_ecomm.order_items`
      ;;
    drill_fields: [order_item_id]
  
    dimension: order_item_id {
      primary_key: yes
      type: number
      sql: ${TABLE}.id ;;
    }
  
    dimension_group: created {
      type: time
      timeframes: [
        raw,
        time,
        date,
        week,
        month,
        quarter,
        year
      ]
      sql: ${TABLE}.created_at ;;
    }
  
    dimension_group: delivered {
      type: time
      timeframes: [
        raw,
        date,
        week,
        month,
        quarter,
        year
      ]
      convert_tz: no
      datatype: date
      sql: ${TABLE}.delivered_at ;;
    }
  
    dimension: inventory_item_id {
      type: number
      # hidden: yes
      sql: ${TABLE}.inventory_item_id ;;
    }
  
    dimension: order_id {
      type: number
      sql: ${TABLE}.order_id ;;
    }
  
    dimension_group: returned {
      type: time
      timeframes: [
        raw,
        time,
        date,
        week,
        month,
        quarter,
        year
      ]
      sql: ${TABLE}.returned_at ;;
    }
  
    dimension: sale_price {
      type: number
      sql: ${TABLE}.sale_price ;;
    }
  
    dimension_group: shipped {
      type: time
      timeframes: [
        raw,
        date,
        week,
        month,
        quarter,
        year
      ]
      convert_tz: no
      datatype: date
      sql: ${TABLE}.shipped_at ;;
    }
  
    dimension: status {
      type: string
      sql: ${TABLE}.status ;;
    }
  
    dimension: user_id {
      type: number
      # hidden: yes
      sql: ${TABLE}.user_id ;;
    }
  
  
    measure: average_sale_price {
      type: average
      sql: ${sale_price} ;;
      drill_fields: [detail*]
      value_format_name: usd_0
    }
  
    measure: order_item_count {
      type: count
      drill_fields: [detail*]
    }
  
    measure: order_count {
      type: count_distinct
      sql: ${order_id} ;;
    }
  
    measure: total_revenue {
      type: sum
      sql: ${sale_price} ;;
      value_format_name: usd
    }
  
    measure: total_revenue_conditional {
      type: sum
      sql: ${sale_price} ;;
      value_format_name: usd
      html: {% if value > 1300.00 %}
            <p style="color: white; background-color: ##FFC20A; margin: 0; border-radius: 5px; text-align:center">{{ rendered_value }}</p>
            {% elsif value > 1200.00 %}
            <p style="color: white; background-color: #0C7BDC; margin: 0; border-radius: 5px; text-align:center">{{ rendered_value }}</p>
            {% else %}
            <p style="color: white; background-color: #6D7170; margin: 0; border-radius: 5px; text-align:center">{{ rendered_value }}</p>
            {% endif %}
            ;;
    }
  
    measure: total_revenue_from_completed_orders {
      type: sum
      sql: ${sale_price} ;;
      filters: [status: "Complete"]
      value_format_name: usd
    }
  
  
    # ----- Sets of fields for drilling ------
    set: detail {
      fields: [
        order_item_id,
        users.last_name,
        users.id,
        users.first_name,
        inventory_items.id,
        inventory_items.product_name
      ]
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
    <em>Last updated: November 2025</em>
  </p>
</div>

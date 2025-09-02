# Data Analysis: Business Metrics Analysis with SQL and Python

## About the Project
This project analyzes **user engagement, content creation, and monetization metrics**, which automatically generates gameplay highlights for streamers.  
By combining **SQL queries** with **Python analytics**, this project identifies **key performance indicators (KPIs)** that can guide product decisions and business growth.  

---

## 🗂 Dataset
The analysis is based on multiple relational tables from the private database:

- **gamesession** → User-submitted gameplay streams  
- **clips** → AI-generated or user-edited clips  
- **downloaded_clips** → Clips downloaded by users  
- **shared_clips** → Clips shared or scheduled for sharing  
- **premium** → Premium subscription activity  
---

## 📌 Key Business Metrics
1. **Monthly Active Users (MAU)** → Measures platform engagement  
2. **Premium Conversion Rate** → % of users upgrading to premium  
3. **Clips Generated per User** → Content creation activity  
4. **CTT Usage Rate** → Popularity of Convert-to-TikTok feature  
5. **Churn Risk Indicators** → Users with declining clip/download activity  

---

## 🧑‍💻 SQL Queries
The analysis, each joining at least two tables, such as:
- Active users by month  
- Premium plan adoption over time  
- Average clips per user by plan type  
- CTT feature usage  
- User retention based on clip activity  

---

## 🖥 Tools & Libraries
- **SQL** (MySQL) – Data extraction  
- **Python** (Pandas, Matplotlib, Seaborn) – Analysis & visualization  

---

## 📊 Analysis & Insights
- **MAU** → Stable user growth, with peak activity around seasonal events.
- **Clip Engagement** → TikTok conversion shows high adoption.
- **Downloads vs Shares** → Downloads are higher, but sharing shows steady upward trend.
- **Premium** → Conversion rate ~ X%, driven by heavy clip users.
- **Churn Risk** → Users with low/no activity post-premium expiration highlight retention challenges.

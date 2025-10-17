# 🌐 Create and Manage AlloyDB Instances: Challenge Lab || GSP395 🚀 [![Open Lab](https://img.shields.io/badge/Open-Lab-blue?style=flat)](https://www.cloudskillsboost.google/course_templates/642/labs/557016)

## ⚠️ Disclaimer ⚠️

<blockquote style="background-color: #fffbea; border-left: 6px solid #f7c948; padding: 1em; font-size: 15px; line-height: 1.5;">
  <strong>Educational Purpose Only:</strong> This script and guide are provided for the educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services.
  <br><br>
  <strong>Terms Compliance:</strong> Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience — not to circumvent it.
</blockquote>

---

<div style="padding: 15px; margin: 10px 0;">

## ☁️ Run in Cloud Shell:

```bash
curl -LO raw.githubusercontent.com/prateekrajput08/Arcade-Google-Cloud-Labs/refs/heads/main/Create%20and%20Manage%20AlloyDB%20Instances%3A%20Challenge%20Lab/TechCode.sh
sudo chmod +x TechCode.sh 
./TechCode.sh
```

```bash
export ALLOYDB=
```

```bash
echo $ALLOYDB  > alloydbip.txt
psql -h $ALLOYDB -U postgres
```

```bash
Change3Me
```

```bash
CREATE TABLE regions (
    region_id bigint NOT NULL,
    region_name varchar(25)
) ;
ALTER TABLE regions ADD PRIMARY KEY (region_id);
```

```bash
CREATE TABLE countries (
    country_id char(2) NOT NULL,
    country_name varchar(40),
    region_id bigint
) ;
ALTER TABLE countries ADD PRIMARY KEY (country_id);
```

```bash
CREATE TABLE departments (
    department_id smallint NOT NULL,
    department_name varchar(30),
    manager_id integer,
    location_id smallint
) ;
ALTER TABLE departments ADD PRIMARY KEY (department_id);
```

```bash
INSERT INTO regions VALUES ( 1, 'Europe' );
INSERT INTO regions VALUES ( 2, 'Americas' );
INSERT INTO regions VALUES ( 3, 'Asia' );
INSERT INTO regions VALUES ( 4, 'Middle East and Africa' );
```

```bash
INSERT INTO countries VALUES ('IT', 'Italy', 1 );
INSERT INTO countries VALUES ('JP', 'Japan', 3  );
INSERT INTO countries VALUES ('US', 'United States of America', 2  );
INSERT INTO countries VALUES ('CA', 'Canada', 2  );
INSERT INTO countries VALUES ('CN', 'China', 3  );
INSERT INTO countries VALUES ('IN', 'India', 3 );
INSERT INTO countries VALUES ('AU', 'Australia', 3  );
INSERT INTO countries VALUES ('ZW', 'Zimbabwe', 4  );
INSERT INTO countries VALUES ('SG', 'Singapore', 3 );
```

```bash
INSERT INTO departments VALUES (10, 'Administration', 200, 1700 );
INSERT INTO departments VALUES (20, 'Marketing', 201, 1800);
INSERT INTO departments VALUES (30, 'Purchasing', 114, 1700 );
INSERT INTO departments VALUES (40, 'Human Resources', 203, 2400);
INSERT INTO departments VALUES (50, 'Shipping', 121, 1500);
INSERT INTO departments VALUES (60, 'IT', 103, 1400);
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
    <em>Last updated: October 2025</em>
  </p>
</div>

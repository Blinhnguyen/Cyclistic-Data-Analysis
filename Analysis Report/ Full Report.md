# Cyclistic-Data-Analysis
Phân tích dữ liệu kinh doanh 6 tháng tại công ty giả lập Cyclistic
![image](https://github.com/Blinhnguyen/Cyclistic-Data-Analysis/assets/174605183/8c7e522b-fa3f-4b99-a400-b1b59771df86)
```
SELECT *
INTO tripdata_6months_raw
FROM (
	SELECT * FROM [dbo].[tripdata_2023_11]
	UNION ALL
	SELECT * FROM [dbo].[tripdata_2023_12]
	UNION ALL
	SELECT * FROM [dbo].[tripdata_2024_01]
	UNION ALL
	SELECT * FROM [dbo].[tripdata_2024_02]
	UNION ALL
	SELECT * FROM [dbo].[tripdata_2024_03]
	UNION ALL
	SELECT * FROM [dbo].[tripdata_2024_04]
) AS combined_table
```

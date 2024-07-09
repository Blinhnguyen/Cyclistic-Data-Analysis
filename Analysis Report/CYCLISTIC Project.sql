/* LÀM SẠCH DỮ LIỆU */
-- 1. Gộp các file dữ liệu thành 1 bảng mới.
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

-- 2. Loại bỏ các giá trị null trong cột start_station_name, start_station_id, end_station_name, end_station_id.
SELECT *
INTO [dbo].[tripdata_6months_nonull]
FROM [dbo].[tripdata_6months_raw]
WHERE 
	[start_station_name] IS NOT NULL
AND	[start_station_id] IS NOT NULL
AND [end_station_name] IS NOT NULL
AND [end_station_id] IS NOT NULL


/* PHÂN TÍCH DỮ LIỆU */
-- 3. Tạo một VIEW chứa thêm các thông tin về tháng, ngày trong tuần và thời gian chuyến đi.
CREATE VIEW tripdata_details AS
SELECT
	[rideable_type],
	MONTH([started_at]) AS month_start,
	CONVERT(TIME(0), CAST([started_at] AS TIME)) AS time_start,
	DATEPART(WEEKDAY, [started_at]) AS day,
	MONTH([ended_at]) AS month_end,
	CONVERT(TIME(0), CAST([ended_at] AS TIME)) AS time_end,
	DATEDIFF(SECOND, [started_at], [ended_at]) AS secs_length,
	DATEDIFF(MINUTE, [started_at], [ended_at]) AS mins_length,
	[start_station_name],
	[end_station_name],
	[member_casual]
FROM [dbo].[tripdata_6months_nonull]

-- 4. Tính thời gian chuyến đi trung bình, thời gian chuyến đi ngắn nhất và dài nhất.
SELECT
	AVG(mins_length) AS avg_mins,
	MAX([mins_length]) AS max,
	MIN([mins_length]) AS min
FROM [dbo].[tripdata_details]

-- 5. Số lượng các chuyến đi có thời gian nhỏ hơn 0.
SELECT COUNT(*) AS negative_rides_length
FROM [dbo].[tripdata_details]
WHERE mins_length <= 0

-- 6. Số lượng các chuyến đi có thời gian lớn hơn 1 ngày (1440 phút).
SELECT COUNT(*) AS more_than_day_rides
FROM [dbo].[tripdata_details]
WHERE mins_length > 1440

-- 7. Tạo một VIEW chỉ chứa các chuyến đi có thời gian lớn hơn 0 và nhỏ hơn 1 ngày.
CREATE VIEW tripdata_day_only AS
SELECT *
FROM [dbo].[tripdata_details]
WHERE mins_length > 0 AND mins_length < 1440

-- 8. Số lượng chuyến đi theo từng ngày trong tuần.
SELECT
	[day],
	COUNT(*) AS num_of_rides,
	[member_casual]
FROM [dbo].[tripdata_day_only]
GROUP BY [day], [member_casual]
ORDER BY [day]

-- 9. Số lượng chuyến đi theo từng giờ trong ngày, chuyển ngày trong tuần sang dạng text.
SELECT 
	CASE
		WHEN [day] = 1 THEN 'Sunday'
		WHEN [day] = 2 THEN 'Monday'
		WHEN [day] = 3 THEN 'Tuesday'
		WHEN [day] = 4 THEN 'Wednesday'
		WHEN [day] = 5 THEN 'Thursday'
		WHEN [day] = 6 THEN 'Friday'
		ELSE 'Saturday'
	END AS day_of_week,
	DATEPART(HOUR, [time_start]) AS hour,
	COUNT(*) AS rides_per_hour,
	[member_casual]
FROM [dbo].[tripdata_day_only]
GROUP BY [member_casual], day, DATEPART(HOUR, [time_start])
ORDER BY [member_casual], day, hour

-- 10. Số lượng chuyến đi theo từng tuyến đường và loại người dùng.
SELECT
	CONCAT([start_station_name], ' to ', [end_station_name]) AS route,
	COUNT(*) AS num_of_rides,
	[member_casual]
FROM [dbo].[tripdata_day_only]
GROUP BY 
	CONCAT([start_station_name], ' to ', [end_station_name]),
	[member_casual]
ORDER BY num_of_rides DESC

-- 11. Số lượng chuyến đi theo loại xe và loại người dùng.
SELECT
	[rideable_type],
	COUNT(*) AS rides_per_type,
	[member_casual]
FROM [dbo].[tripdata_day_only]
GROUP BY [rideable_type], [member_casual]
ORDER BY rides_per_type DESC

-- 12. Thời gian trung bình mỗi chuyến đi theo từng ngày trong tuần, sắp xếp theo loại khách hàng và giờ trong ngày.
SELECT
	CASE
		WHEN [day] = 1 THEN 'Sunday'
		WHEN [day] = 2 THEN 'Monday'
		WHEN [day] = 3 THEN 'Tuesday'
		WHEN [day] = 4 THEN 'Wednesday'
		WHEN [day] = 5 THEN 'Thursday'
		WHEN [day] = 6 THEN 'Friday'
		ELSE 'Saturday'
	END AS day_of_week,
	ROUND(AVG([mins_length]),2) AS a_ride_length,
	[member_casual],
	DATEPART(HOUR, [time_start]) AS hour
FROM [dbo].[tripdata_day_only]
GROUP BY [member_casual], [day], DATEPART(HOUR, [time_start])
ORDER BY [member_casual], [day], hour

-- 13. Thời gian trung bình mỗi chuyến đi theo tuyến đường, loại khách hàng và loại xe sử dụng; sắp xếp theo số lượng chuyến đi giảm dần.
SELECT
	CASE
		WHEN [day] = 1 THEN 'Sunday'
		WHEN [day] = 2 THEN 'Monday'
		WHEN [day] = 3 THEN 'Tuesday'
		WHEN [day] = 4 THEN 'Wednesday'
		WHEN [day] = 5 THEN 'Thursday'
		WHEN [day] = 6 THEN 'Friday'
		ELSE 'Saturday'
	END AS day_of_week,
	CONCAT([start_station_name], ' to ', [end_station_name]) AS route,
	COUNT(*) AS num_of_rides,
	[rideable_type],
	[member_casual],
	DATEPART(HOUR, [time_start]) AS hour
FROM [dbo].[tripdata_day_only]
GROUP BY 
	[member_casual], 
	[day], 
	DATEPART(HOUR, [time_start]),
	CONCAT([start_station_name], ' to', [end_station_name]),
	[rideable_type]
ORDER BY num_of_rides DESC

-- 14. Thời gian trung bình chuyến đi theo loại khách hàng.
CREATE VIEW avg_time AS
SELECT 
	AVG([mins_length]) AS avg_time,
	[member_casual]
FROM [dbo].[tripdata_details]
GROUP BY [member_casual]

-- 15. Top 300 các tuyến đường có nhiều chuyến đi nhất theo loại khách hàng và loại xe.
CREATE VIEW top_300_route AS
SELECT
	TOP 300
	CONCAT([start_station_name], ' to ', [end_station_name]) AS route_name,
	[start_lat], [start_lng],
	[end_lat], [end_lng],
	COUNT(*) AS rides_taken,
	[member_casual],
	[rideable_type]
FROM [dbo].[tripdata_6months_nonull]
GROUP BY 
	[member_casual], [rideable_type], [start_lat], [start_lng], [end_lat], [end_lng], 
	CONCAT([start_station_name], ' to ', [end_station_name])
ORDER BY rides_taken DESC

-- 16. Tháng có số lượng chuyến đi nhiều nhất
SELECT TOP 1
	DATENAME(MONTH, [started_at]) AS Month,
	COUNT(*) AS rides_taken
FROM [dbo].[tripdata_6months_nonull]
GROUP BY DATENAME(MONTH, [started_at])
ORDER BY rides_taken DESC

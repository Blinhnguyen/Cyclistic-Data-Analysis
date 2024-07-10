# Cyclistic Bike Share Company Data Analysis
![image](https://github.com/Blinhnguyen/Cyclistic-Data-Analysis/assets/174605183/068ca97e-f235-4f27-8626-f45c5a004c60)


Báo cáo này chứa đầy đủ thông tin cần thiết về dữ liệu kinh doanh trong vòng 6 tháng tại công ty chia sẻ xe đạp Cyclistic (từ tháng 11/2023 dến tháng 4/2024) và các giai đoạn của dự án bao gồm đặt câu hỏi, làm sạch dữ liệu, phân tích dữ liệu, trực quan hóa dữ liệu và đưa ra đề xuất.

## Table of Contents

* [Project Context](#project-context)
* [Phase 1: Ask](#phase-1-ask)
* [Phase 2: Prepare](#phase-2-prepare)
* [Phase 3: Process](#phase-3-process)
* [Phase 4: Analyze](#phase-4-analyze)
* [Phase 5: Share](#phase-5-share)
* [Phase 6: Act](#phase-6-act)

## Project Context
Đóng vai trò là chuyên viên phân tích dữ liệu tại công ty Cyclistic, nhiệm vụ được giao cho bạn xoay quanh việc hỗ trợ công ty đạt được mục tiêu chiến lược là gia tăng số lượng các gói membership theo năm. Để đạt được mục đích, đầu tiên bạn cần tập trung phân tích hành vi và sở thích của hai đối tượng khách hàng chính của công ty là khách hàng vãng lai (casual rider) và khách hàng có gói thành viên theo năm (annual member). Thông qua việc phân tích và trực quan hóa dữ liệu, bạn sẽ cần phải đưa ra các insight để phát triển các kế hoạch marketing với mục tiêu chính là chuyển đổi các khách hàng vãng lai thành khách hàng lâu dài của công ty.

## Phase 1: Ask
Sử dụng mô hình __SMART__ trong Marketing để đặt câu hỏi phù hợp trong việc phân tích:
  * __S__ - Specific
  * __M__ - Measurable
  * __A__ - Action-Oriented
  * __R__ - Relevant
  * __T__ - Time-Bound

_Câu hỏi đặt ra:_
  1. Khách hàng vãng lai (casual rider) và khách hàng có gói thành viên (annual member) sử dụng xe đạp khác nhau như thế nào?
  2. Tại sao khách hàng vãng lai lại lựa chọn mua gói thành viên?
  3. Công ty có thể sử dụng marketing để khuyến khích khách hàng mua gói thành viên như thế nào?

## Phase 2: Prepare
Dự án sử dụng nguồn dữ liệu được cung cấp bởi Google qua [Amazon Web Services](https://divvy-tripdata.s3.amazonaws.com/index.html).

Cụ thể, dự án sử dụng dữ liệu kinh doanh của công ty Cyclistic trong 6 tháng (11/2023 - 04/2024). Các dữ liệu được sử dụng nằm trong folder [Data Input](https://github.com/Blinhnguyen/Cyclistic-Data-Analysis/tree/main/Data%20Input).

![image](https://github.com/Blinhnguyen/Cyclistic-Data-Analysis/assets/174605183/5dc7fbba-fea4-4afd-aec0-d41f19bc05ff)

Bảng dữ liệu chứa 13 trường, bao gồm thông tin về *ID chuyến đi*, *loại xe*, *thời gian bắt đầu và kết thúc*, *trạm bắt đầu và kết thúc*, *tọa độ và tên các trạm*, *loại khách hàng*.

Các số liệu thường được sử dụng để phân tích việc sử dụng xe:
  1. Tỉ lệ sử dụng giữa khách hàng vãng lai và thành viên.
  2. Tần suất sử dụng xe theo từng loại xe đạp.
  3. Thời gian trung bình sử dụng xe.
  4. Số lượng chuyến đi trong ngày.
  5. Các tuyến đường xe được sử dụng phổ biến nhất theo từng loại khách hàng.

## Phase 3: Process
Làm sạch và chuyển đổi dữ liệu sử dụng Microsoft SQL Server:

__1. Gộp các file dữ liệu thành 1 bảng mới.__
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

![image](https://github.com/Blinhnguyen/Cyclistic-Data-Analysis/assets/174605183/577b9575-73c2-43f9-a0c0-5be45176292a)

Kết quả trả về: 1,671,340 dòng.


__2. Loại bỏ các giá trị null trong cột start_station_name, start_station_id, end_station_name, end_station_id.__
```
SELECT *
INTO [dbo].[tripdata_6months_nonull]
FROM [dbo].[tripdata_6months_raw]
WHERE 
	[start_station_name] IS NOT NULL
AND	[start_station_id] IS NOT NULL
AND [end_station_name] IS NOT NULL
AND [end_station_id] IS NOT NULL
```

![image](https://github.com/Blinhnguyen/Cyclistic-Data-Analysis/assets/174605183/36a22cb6-013f-4c53-905a-a1ef91877d28)

Kết quả trả về: 1,268,561 dòng.


## Phase 4: Analyze
__1. Tạo một VIEW chứa thêm các thông tin về tháng, ngày trong tuần và thời gian chuyến đi.__
```
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
```

![image](https://github.com/Blinhnguyen/Cyclistic-Data-Analysis/assets/174605183/12a0c270-8c4d-414f-9f91-18118f2193a4)

__2. Tính thời gian chuyến đi trung bình, thời gian chuyến đi ngắn nhất và dài nhất.__
```
SELECT
	AVG(mins_length) AS avg_mins,
	MAX([mins_length]) AS max,
	MIN([mins_length]) AS min;
FROM [dbo].[tripdata_details]
```
![image](https://github.com/Blinhnguyen/Cyclistic-Data-Analysis/assets/174605183/6365c29d-d19b-45d8-ac67-5ba732de7ba8)

__3. Số lượng các chuyến đi có thời gian nhỏ hơn 0.__
```
SELECT COUNT(*) AS negative_rides_length
FROM [dbo].[tripdata_details]
WHERE mins_length <= 0
```
![image](https://github.com/Blinhnguyen/Cyclistic-Data-Analysis/assets/174605183/b262a234-6fe4-4b42-a8e1-5a8fa7df5671)

__4. Số lượng các chuyến đi có thời gian lớn hơn 1 ngày (1440 phút).__
```
SELECT COUNT(*) AS more_than_day_rides
FROM [dbo].[tripdata_details]
WHERE mins_length > 1440
```
![image](https://github.com/Blinhnguyen/Cyclistic-Data-Analysis/assets/174605183/c7c33a9a-4e5b-493d-a890-cfdf7ee25e63)

__5. Tạo một VIEW chỉ chứa các chuyến đi có thời gian lớn hơn 0 và nhỏ hơn 1 ngày.__
```
CREATE VIEW tripdata_day_only AS
SELECT *
FROM [dbo].[tripdata_details]
WHERE mins_length > 0 AND mins_length < 1440
```
![image](https://github.com/Blinhnguyen/Cyclistic-Data-Analysis/assets/174605183/0572ccad-1c60-4042-b733-3ee32805190e)

Kết quả: 1,256,107 dòng.

__6. Số lượng chuyến đi theo từng ngày trong tuần.__
```
SELECT
	[day],
	COUNT(*) AS num_of_rides,
	[member_casual]
FROM [dbo].[tripdata_day_only]
GROUP BY [day], [member_casual]
ORDER BY [day]
```
![image](https://github.com/Blinhnguyen/Cyclistic-Data-Analysis/assets/174605183/2d998883-1f51-4102-b837-ae3f2a0b9ea0)

Kết quả: 14 dòng.

__7. Số lượng chuyến đi theo từng giờ trong ngày, chuyển ngày trong tuần sang dạng text.__
```
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
```
![image](https://github.com/Blinhnguyen/Cyclistic-Data-Analysis/assets/174605183/6955f4da-541e-4922-8d4c-afe01be83e87)

Kết quả: 36 dòng.

__8. Số lượng chuyến đi theo từng tuyến đường và loại người dùng.__
```
SELECT
	CONCAT([start_station_name], ' to', [end_station_name]) AS route,
	COUNT(*) AS num_of_rides,
	[member_casual]
FROM [dbo].[tripdata_day_only]
GROUP BY 
	CONCAT([start_station_name], ' to', [end_station_name]),
	[member_casual]
ORDER BY num_of_rides DESC
```
![image](https://github.com/Blinhnguyen/Cyclistic-Data-Analysis/assets/174605183/ef6836f8-e2a4-4f5f-82ab-5109c499218d)

Kết quả: 153,265 dòng.

__9. Số lượng chuyến đi theo loại xe và loại người dùng.__
```
SELECT
	[rideable_type],
	COUNT(*) AS rides_per_type,
	[member_casual]
FROM [dbo].[tripdata_day_only]
GROUP BY [rideable_type], [member_casual]
ORDER BY rides_per_type DESC
```
![image](https://github.com/Blinhnguyen/Cyclistic-Data-Analysis/assets/174605183/d5064663-2d13-41e5-9ae1-ce6429a6d3e0)

__10. Thời gian trung bình mỗi chuyến đi theo từng ngày trong tuần, sắp xếp theo loại khách hàng và giờ trong ngày.__
```
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
```
![image](https://github.com/Blinhnguyen/Cyclistic-Data-Analysis/assets/174605183/d1e19faa-85c9-4aad-9bd6-11bef8d630bc)

Kết quả: 336 dòng.

__11. Thời gian trung bình mỗi chuyến đi theo tuyến đường, loại khách hàng và loại xe sử dụng; sắp xếp theo số lượng chuyến đi giảm dần.__
```
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
	CONCAT([start_station_name], ' to', [end_station_name]) AS route,
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
```
![image](https://github.com/Blinhnguyen/Cyclistic-Data-Analysis/assets/174605183/7b664172-a273-4f23-a4e4-93debf5c1a3d)

Kết quả: 889,895 dòng.


## Phase 5: Share
Dự án sử dụng PowerBI để trực quan hóa dữ liệu và hỗ trợ đưa ra phân tích.

![image](https://github.com/Blinhnguyen/Cyclistic-Data-Analysis/assets/174605183/a1525d7a-310b-4c20-abe1-b3b12d8d0771)

__Các Insight chính:__
1. Số lượng khách hàng __member__ nhiều hơn đáng kể so với số lượng khách hàng __casual__ với gần 75%^ trong số tổng cộng 1,671,340 chuyến đi trong vòng 6 tháng, cho thấy đây là đối tượng khách hàng trọng tâm mang lại nguồn doanh thu chính cho công ty. Đồng thời, số lượt khách hàng sử dụng đạt đỉnh điểm vào tháng 4 với tổng cộng gần 300,000 chuyến đi.
2. Thời gian trung bình cho 1 chuyến đi là khoảng 14 phút và khách hàng __member__ thường có thời gian sử dụng xe ngắn hơn so với khách hàng __casual__ với thời gian trung bình chênh lệch khoảng 9 phút.
3. Xe đạp truyền thống được sử dụng phổ biến hơn xe đạp điện.
4. Khách hàng __member__ sử dụng xe nhiều nhất vào các ngày trong tuần với số lượng nhiều nhất vào thứ 3, thứ 4 và thứ 5; trong khi đó khách hàng __casual__ có xu hướng sử dụng xe vào các ngày cuối tuần như thứ 7 và Chủ nhật.
5. Khách hàng __member__ có xu hướng sử dụng xe vào các giờ cao điểm (khoảng 8 giờ sáng và 17h chiều), chiếm hơn 47% số lượng so với cả tuần. Trong khi đó, số lượng khách hàng __casual__ sử dụng xe tăng đều trong 1 ngày, đạt đỉnh vào khoảng 17h chiều và có xu hướng giảm vào cuối ngày.
6. Không chỉ vậy, sự phân bổ các địa điểm sử dụng xe cũng khác nhau giữa 2 loại khách hàng. Khách hàng __member__ thường xuyên sử dụng xe trong nội thành, các khu dân cư và hầu hết đi qua các trường Đại học trong thành phố như University of Chicago và Illinois Institute of Technology. Ngược lại, khách hàng __casual__ có xu hướng sử dụng xe tại các địa điểm gần bờ biển và các công viên như biển Oak Street, công viên Millennium và cảng Chicago.

=> Nhìn tổng quan, các dữ liệu cho thấy rằng khách hàng __casual__ có xu hướng đạp xe như một hình thức vận động và giải trí vào giờ tan làm, thời gian rảnh rỗi hoặc các ngày cuối tuần. Trong khi đó, khách hàng __member__ sử dụng xe đạp làm phương tiện di chuyển chính, có thể là sinh viên hoặc những người muốn hạn chế kẹt xe vào giờ cao điểm tại Chicago - 1 trong những thành phố có tỉ lệ xảy ra tắc nghẽn giao thông cao nhất nước Mỹ. Đây là insight chính để lựa chọn khách hàng mục tiêu trong chiến dịch marketing sắp tới của công ty.
   

## Phase 6: Act
Dự án đưa ra các đề xuất dựa trên __mô hình Marketing mix 4P__

__1. Product__ - Sản phẩm:
 * Đưa ra các option thay thế trong giao diện app theo xu hướng trẻ trung, hiện đại, phù hợp với đối tượng khách hàng trẻ, đối tượng sinh viên.
 * Trang trí đa dạng ngoại hình xe theo mùa, theo sự kiện, mang các chủ đề được quan tâm như bảo vệ môi trường, Pride month, Christmas,...

__2. Price__ - Giá:
 * Đưa ra các gói membership ngắn hạn hơn một năm, ví dụ như gói membership theo tháng, theo quý hoặc gói membership cách tuần đặc biệt khuyến khích khách hàng sử dụng xe vào các ngày cuối tuần.
 * Đưa ra thêm option về kế hoạch trả phí, gia hạn gói membership.

__3. Place__ - Kênh phân phối:
 * Mở thêm các trạm xe tại các khu vực dân cư đông đúc và các công viên ven biển.
 * Đẩy mạnh phân phối dịch vụ bằng cách liên kết với các trường Đại học. 

__4. Promotion__ - Xúc tiến bán:
 * Đưa ra các chương trình khuyến mãi đặc biệt dành cho sinh viên, giảm giá tích điểm cho các lượt giới thiệu khách hàng mới.
 * Truyền thông qua các nền tảng mạng xã hội với nội dung ngắn, mang chủ đề viral phù hợp với đối tượng khách hàng trẻ.
 * Thuê các biển quảng cáo điện tử, billboard vào ban ngày tại các tuyến đường phổ biến, các vị trí công viên, bãi biển,... nơi tập trung nhiều nhất đối tượng khách hàng vãng lai.

   
## Conclusion
Dự án phân tích các insight của khách hàng để đưa ra các đề xuất phù hợp nhất cho chiến dịch marketing sắp tới của công ty. Tuy nhiên để nhận diện rõ hơn chân dung khách hàng, công ty nên tiến hành thu thập các thông tin nhân khẩu học như độ tuổi, nghề nghiệp, mức lương, tình trạng hôn nhân,... giúp tối ưu hóa chi phí và tăng độ hiệu quả của chiến dịch.

Các thông tin liên quan về trực quan hóa, code,... nằm trong các folder còn lại.


Cre: Blinh Nguyễn

Email: blnguyen2103@gmail.com





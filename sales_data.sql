--Inspecting data
select * from [dbo].[sales_data_sample]

--Checking unique values
select distinct status from [dbo].[sales_data_sample] --Nice one to plot
select distinct year_id from [dbo].[sales_data_sample] 
select distinct PRODUCTLINE from [dbo].[sales_data_sample] ---keeping track, good to plot
select distinct COUNTRY from [dbo].[sales_data_sample] ---Nice to plot
select distinct DEALSIZE from [dbo].[sales_data_sample] ---Nice to plot
select distinct TERRITORY from [dbo].[sales_data_sample] ---Nice to plot


--ANALYSIS
---grouping sales by productline
select PRODUCTLINE, sum(SALES) revenue
from sales_data_sample
group by PRODUCTLINE
order by revenue desc

select YEAR_ID, sum(sales) revenue
from [dbo].[sales_data_sample]
group by YEAR_ID
order by revenue desc-- least sales in 2005
select distinct MONTH_ID from sales_data_sample
where YEAR_ID=2005 --only operated for half a year in 2005

select DEALSIZE, sum(sales) revenue
from [dbo].[sales_data_sample]
group by DEALSIZE
order by revenue desc

--best month for sales in specific year? how much earned that month?

select MONTH_ID, sum(sales) revenue, count(ORDERNUMBER) frequency
from [dbo].[sales_data_sample]
where year_id=2003 -- change year
group by MONTH_ID
order by revenue desc-- best month nov in 2003 and 2004


--what are they selling in November?
select MONTH_ID, PRODUCTLINE, sum(sales) revenue, count(ORDERNUMBER) frequency
from sales_data_sample
where year_id=2003 and MONTH_ID=11
group by MONTH_ID, PRODUCTLINE
order by revenue desc

select MONTH_ID, PRODUCTLINE, sum(sales) revenue, count(ORDERNUMBER) frequency
from sales_data_sample
where year_id=2004 and MONTH_ID=11
group by MONTH_ID, PRODUCTLINE
order by revenue desc


--rfm analysis: who is the best customer?

drop table if exists #rfm
;with rfm as
(
	select
		CUSTOMERNAME,
		sum(sales) MonetaryValue,
		avg(sales) AvgMonetaryValue,
		count(ORDERNUMBER) Frequency,
		max(ORDERDATE) AS LastPurchase,
		(select max(ORDERDATE) from sales_data_sample) AS MaxOrderDate,
		datediff(DD, max(ORDERDATE), (select max(ORDERDATE) from sales_data_sample)) Recency
	from sales_data_sample
	group by CUSTOMERNAME
),

rfm_calc as
(
select 
	r.*,
	NTILE(4) OVER (order by Recency desc) rfm_recency,
	NTILE(4) OVER (order by Frequency) rfm_frequency,
	NTILE(4) OVER (order by MonetaryValue) rfm_monetary
from rfm r
)

select 
	c.*, rfm_recency + rfm_frequency + rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary as varchar) rfm_string
into #rfm
from rfm_calc c

select CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_string in (311, 411, 331) then 'new customers'
		when rfm_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm

--xml path analysis
--what products most often sold together? (for promotions) 


--select * from sales_data_sample where ORDERNUMBER=10411


	select distinct ORDERNUMBER, stuff(
		(
		select ',' + PRODUCTCODE
		from sales_data_sample p
		where ORDERNUMBER in
			(
	
			select ORDERNUMBER
			from
				(
				select ORDERNUMBER, count(*) rn
				from sales_data_sample
				where status = 'shipped'
				group by ORDERNUMBER
				) m
			where rn =3 --orders with that many products
			)
			and p.ORDERNUMBER = s.ORDERNUMBER
			for xml path ('')
			)
			,1,1 , '') ProductCodes --puts into one column
	from sales_data_sample s
	order by ProductCodes desc




--city with highest number of sales in a country?
select city, sum (sales) Revenue, count(PRODUCTCODE) products
from [Portfolio].[dbo].[sales_data_sample]
where country = 'UK'
group by city
order by 2 desc

--best products in city?

select PRODUCTLINE, city, count(PRODUCTLINE) n
from [Portfolio].[dbo].[sales_data_sample]
where country = 'UK'
group by PRODUCTLINE,city
order by city desc, n desc

---What is the best product in United States?
select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
from [Portfolio].[dbo].[sales_data_sample]
where country = 'UK'
group by  country, YEAR_ID, PRODUCTLINE
order by 4 desc
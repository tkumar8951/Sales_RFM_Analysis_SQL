--Inspecting Data
select * from sales_data_sample

--Checking unique values
select distinct STATUS from sales_data_sample --Nice to plot
select distinct YEAR_ID from sales_data_sample
select distinct PRODUCTLINE from sales_data_sample --Nice to plot
select distinct COUNTRY from sales_data_sample --Nice to plot
select distinct TERRITORY from sales_data_sample --Nice to plot
select distinct DEALSIZE from sales_data_sample --Nice to plot

select distinct MONTH_ID from sales_data_sample
where YEAR_ID=2004

--ANALYSIS
--grouping sales by productline
select PRODUCTLINE, SUM(SALES) as revenue
from sales_data_sample
group by PRODUCTLINE
order by 2 desc

select YEAR_ID, SUM(SALES) as revenue
from sales_data_sample
group by YEAR_ID
order by 2 desc

select DEALSIZE, SUM(SALES) as revenue
from sales_data_sample
group by DEALSIZE
order by 2 desc

--What was the best month for sales? How much was earned in that month?
select MONTH_ID, count(ORDERNUMBER) as frequency, SUM(SALES) as revenue
from sales_data_sample
where YEAR_ID= 2005 -- change year to see the rest
group by MONTH_ID
order by 3 desc

--November seems to be the month, What product do they sell in November classic cars I believe
select MONTH_ID, PRODUCTLINE, count(ORDERNUMBER) as frequency, SUM(SALES) as revenue
from sales_data_sample
where YEAR_ID= 2004 and MONTH_ID=11 -- change year to see the rest
group by MONTH_ID,PRODUCTLINE
order by 3 desc

--Who is the best customer(this could be best answered by RFM)

Drop table if exists #rfm
;with rfm as
(
	select
		CUSTOMERNAME,
		count(ORDERNUMBER) as frequency,
		avg(SALES) as MonetaryValue,
		sum(SALES) as AvgMonetaryValue,
		max(ORDERDATE) as LastOrderDate,
		(select MAX(ORDERDATE) from sales_data_sample) as MaxOrderDate,
		DATEDIFF(DD,max(ORDERDATE),(select MAX(ORDERDATE) from sales_data_sample)) Recency
	from sales_data_sample
	group by CUSTOMERNAME
),

rfm_calc as
(

	select r.*,
		NTILE(4) over (order by Recency desc) rfm_recency,
		NTILE(4) over (order by frequency) rfm_frequency,
		NTILE(4) over (order by MonetaryValue) rfm_MonetaryValue 
	from rfm r
)	
select
	c.*, rfm_recency+rfm_frequency+rfm_MonetaryValue as rfm_cell,
	cast(rfm_recency as varchar) +cast(rfm_frequency as varchar)+cast(rfm_MonetaryValue as varchar)rfm_cell_string
into #rfm
from rfm_calc as c

select CUSTOMERNAME,rfm_recency,rfm_frequency,rfm_MonetaryValue,
	case 
		when rfm_cell_string in (111,112,121,122,123,132,211,212,114,141) then 'LostCustomers'--lost customers
		when rfm_cell_string in (133,134,143,244,334,343,344,144) then 'SlippingAway_CantLoose'--(Big spenders who haven't purchased lately) slipping away
		when rfm_cell_string in (311,411,331) then 'NewCustomers'
		when rfm_cell_string in (222,223,233,322) then 'potential_churners'
		when rfm_cell_string in (323,333,321,422,332,432) then 'active'--(Customers who buy often and recently, but at low price points)
		when rfm_cell_string in (433,434,443,444) then 'Loyal'
	end rfm_segment
from #rfm


--What products are most often sold together?
--select * from sales_data_sample where ORDERNUMBER=10411
select distinct ORDERNUMBER,stuff(
	(select ','+ PRODUCTCODE
	from sales_data_sample as p
	where ORDERNUMBER in
			(	
			select ORDERNUMBER
				from   (
						select ORDERNUMBER, COUNT(*) as rn
						from sales_data_sample
						where STATUS ='Shipped'
						group by ORDERNUMBER
						) m
				where rn=3
			) and p.ORDERNUMBER=s.ORDERNUMBER
		for xml path(''))
	,1,1,'') as ProductCodes
from sales_data_sample as s
order by 2 desc
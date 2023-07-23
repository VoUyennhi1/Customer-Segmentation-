with customer_statistics as (
    select CustomerID,
           abs(datediff(max(str_to_date(Purchase_Date,'%m/%d/%y')),'2022-09-01')) as recency,
           coalesce(round((count(distinct(str_to_date(Purchase_Date,'%m/%d/%y'))))/
                    (round(abs(datediff(max(cast(created_date as date)),'2022-09-01'))/365,0)),2),0) as frequency,
           coalesce(round((sum(GMV)) /
               (round(abs(datediff(max(cast(created_date as date)),'2022-09-01'))/365,0)),0),0) as monetary,
           (row_number() over (order by abs(datediff(max(str_to_date(Purchase_Date,'%m/%d/%y')),'2022-09-01'))))as rn_rencency,
           (row_number() over (order by coalesce(round((sum(GMV)) /
               (round(abs(datediff(max(cast(created_date as date)),'2022-09-01'))/365,0)),0),0))) as rn_monetary,
            (row_number() over (order by coalesce(round((count(distinct(str_to_date(Purchase_Date,'%m/%d/%y'))))/
                    (round(abs(datediff(max(cast(created_date as date)),'2022-09-01'))/365,0)),2),0))) as rn_frequency
    from customer_transaction CT
    join customer_registered CR on CT.CustomerID = CR.ID
    where CustomerID <> 0 and stopdate is null
    group by CustomerID),
    RFM_MAPPING as (
    select *, case
        when recency < ((select recency from customer_statistics
                                        where rn_rencency = ((select count(distinct(CustomerID))*0.25
                                                             from customer_statistics))))
            and recency >= (select recency from customer_statistics where rn_rencency = 1)
        then '1'
        when recency < ((select recency from customer_statistics
                                        where rn_rencency = ((select count(distinct(CustomerID))*0.5
                                                             from customer_statistics))))
            and recency >= ((select recency from customer_statistics
                                        where rn_rencency = ((select count(distinct(CustomerID))*0.25
                                                             from customer_statistics))))
        then '2'
        when recency < ((select recency from customer_statistics
                                        where rn_rencency = ((select count(distinct(CustomerID))*0.75
                                                             from customer_statistics))))
            and recency >= ((select recency from customer_statistics
                                        where rn_rencency = ((select count(distinct(CustomerID))*0.5
                                                             from customer_statistics))))
        then '3'
    else '4' end as R,
        case
        when frequency < ((select frequency from customer_statistics
                                        where rn_frequency = ((select count(distinct(CustomerID))*0.25
                                                             from customer_statistics))))
            and frequency >= (select frequency from customer_statistics where rn_rencency = 1)
        then '1'
        when frequency < ((select frequency from customer_statistics
                                        where rn_frequency = ((select count(distinct(CustomerID))*0.5
                                                             from customer_statistics))))
            and frequency >= ((select frequency from customer_statistics
                                        where rn_frequency = ((select count(distinct(CustomerID))*0.25
                                                             from customer_statistics))))
        then '2'
        when frequency < ((select frequency from customer_statistics
                                        where rn_frequency = ((select count(distinct(CustomerID))*0.75
                                                             from customer_statistics))))
            and frequency >= ((select frequency from customer_statistics
                                        where rn_frequency = ((select count(distinct(CustomerID))*0.5
                                                             from customer_statistics))))
        then '3'
    else '4' end as F,
        case
    when monetary < ((select monetary from customer_statistics
                                        where rn_monetary = ((select count(distinct(CustomerID))*0.25
                                                             from customer_statistics))))
            and monetary >= (select monetary from customer_statistics where rn_rencency = 1)
        then '1'
        when monetary < ((select monetary from customer_statistics
                                        where rn_monetary = ((select count(distinct(CustomerID))*0.5
                                                             from customer_statistics))))
            and monetary >= ((select monetary from customer_statistics
                                        where rn_monetary = ((select count(distinct(CustomerID))*0.25
                                                             from customer_statistics))))
        then '2'
        when monetary < ((select monetary from customer_statistics
                                        where rn_monetary = ((select count(distinct(CustomerID))*0.75
                                                             from customer_statistics))))
            and monetary  >= ((select monetary from customer_statistics
                                        where rn_monetary = ((select count(distinct(CustomerID))*0.5
                                                             from customer_statistics))))
        then '3'
    else '4' end as M
    from customer_statistics)
select CustomerID, recency, frequency, monetary, R,F,M, concat(R,F,M) as RFM
from customer_statistics
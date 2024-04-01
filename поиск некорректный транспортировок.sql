SET TIME ZONE 'Asia/Irkutsk';

WITH TM(dtstart, dtfinish) as ((VALUES(DATE_TRUNC('DAY', ('2022-01-01'::TIMESTAMP)::DATE),DATE_TRUNC('DAY', ('2022-05-02'::TIMESTAMP))::DATE))) -- Входные параметры
select 
wencoid, 
Count(pmpeid) as pmpeid2
from
(SELECT 
pm.elementid as pmpeid, 
am.elementid as amid, 
pm.transportationmovement_wencoid as wencoid, 
am.batchid as batchid,
pm.transportationmovement_wencoid as кол_рейсов
FROM public.accmovements_movement am
join public.pamovements_mixedpolygonentity pm on pm.elementid=am.elementid
where 
am.starttime > (Select dtstart from tm)- time '05:00:00' and am.endtime <= (Select dtfinish from tm)+ time '19:00:00'
 and 
 (pm.modelreference = 'o:site/app/RcAppProAcc/AccountingModelDetail' or pm.modelreference = 'o:RcAppProAcc/Models/AccountingModelDetail')
 and pm.templatereference = 's:PolyusMesPa/Domains/PaMovements/TransportationMovement' 
order by 2)
	as q
	group by 1
	having count(pmpeid)<3
	order by 2 asc

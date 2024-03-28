SET TIME ZONE 'Asia/Irkutsk';
WITH TM(dtstart, dtfinish) as ((VALUES(DATE_TRUNC('DAY', ('2022-08-31'::TIMESTAMP)::DATE),DATE_TRUNC('DAY', ('2022-09-29'::TIMESTAMP))::DATE))) -- Входные параметры
select
qwwe.*
from(
select wencoid,
	endtime,
sum(qwe.Масса_isloading) as Масса_isloading,
sum(qwe.Масса_isunloading) as Масса_isunloading,
sum(qwe.Масса_isexcavate) as Масса_isexcavate,
case
when sum(qwe.Масса_isexcavate) <>sum(qwe.Масса_isunloading)
then 'Масса_isexcavate_false'
else 'Масса_isexcavate_true'
end mass
from(
select 
	endtime,
wencoid, 
case
when isloading ='true'
then ROUND(sum(Масса) ,2)
end Масса_isloading,
case
when isunloading ='true'
then ROUND(sum(Масса), 2)
end Масса_isunloading,
case
when isexcavate ='true'
then ROUND(sum(Масса), 2)
end Масса_isexcavate
from
(SELECT 
 am.endtime as endtime,
pm.elementid as pmpeid, 
am.elementid as amid, 
pm.transportationmovement_wencoid as wencoid, 
am.batchid as batchid,
pm.transportationmovement_wencoid as кол_рейсов,
pm.transportationmovement_isloading as isloading ,pm.transportationmovement_isunloading as isunloading,pm.transportationmovement_isexcavate as isexcavate,
(((SELECT Value FROM jsonb_array_elements(am.Amount::jsonb->'Attributes') WHERE jsonb_extract_path_text(Value, 'Id')='Value')->'Value'->>'Value')::numeric) as Масса
/*(((SELECT Value FROM jsonb_array_elements(am.ExtraAmount::jsonb->'Attributes') WHERE jsonb_extract_path_text(Value, 'Id')='Value')->'Value'->>'Value')::numeric) as Объем*/
FROM public.accmovements_movement am
join public.pamovements_mixedpolygonentity pm on pm.elementid=am.elementid
where 
am.starttime > (Select dtstart from tm)- time '05:00:00' and am.endtime <= (Select dtfinish from tm)+ time '19:00:00'
 and 
 (pm.modelreference = 'o:site/app/RcAppProAcc/AccountingModelDetail' or pm.modelreference = 'o:RcAppProAcc/Models/AccountingModelDetail')
 and pm.templatereference = 's:PolyusMesPa/Domains/PaMovements/TransportationMovement' 
  group by pmpeid,amid
order by 2)
 as q
 group by 1,q.isloading,q.isunloading,q.isexcavate,wencoid,endtime
 --aving count(pmpeid)<6
 order by 1,2 asc
 ) as qwe
  group by 1,wencoid,endtime
 ) as qwwe
 where wencoid in ( )
-- where mass ilike 'Масса_isexcavate_false'

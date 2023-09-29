--DECLARE @dt as datetime


--SET @dt = '2023-01-01';


SELECT 
	t.LoadLocation
	,t.DumpLocation
	,t.Material
	,(CASE 
	   WHEN t.Licence = 'ДиП м.Вернинское к.Вернинский' THEN 'Вернинское № ИРК 3464 БР'
	   WHEN t.Licence = 'ДиП м.Верх.Кадал.к.Верхний Кадаликанский' THEN 'ВКадаликанскийлицензия'
	   WHEN t.Licence = 'ДиП м.Кадаликанское к.Кадаликанский' THEN 'Кадаликанскийлицензия'
	   WHEN t.Licence = 'ДиП м.Первенец к.Вернинский' THEN 'Первенец № ИРК 03455 БР'
	   WHEN t.Licence = 'ДиП м.Смежный к.Вернинский' THEN 'Смежный № ИРК 03465 БР'
	   END) as Licence
	  ,t.LoadEquip
	  ,SUM(COALESCE(t.MassApproved,0)) as MassApproved
	  ,SUM(COALESCE(t.VolumeApproved,0)) as VolumeApproved
	  ,SUM(COALESCE(t.MassAU,0)) as MassAU
FROM
(
SELECT
	--TF.[Block] as LoadLocation--блок, для транспортировки со склада пустое
	TF.[LoadLocation] as LoadLocation --место погрузки, для карьера пустое
	,TF.[DumpLocation] --место выгрузки
	,TF.[Material] --Тип руды
	,SPP.SppName as Licence --СПП|Лицензия
	,LE.Position as LoadEquip --погрузчик
	--,HE.Position as  --самосвал
	--,[Turn]--Очередь
	--,[Stage]--Этап
	--,Sum(TF.[Mass]) MassFact
	--,sum(TF.[Volume]) VolFact
	,AP.[Mass] MassApproved
	  ,AP.[Volume] VolumeApproved
	  ,(AP.FractionAu * AP.Mass)  as MassAU
	  --,sum([MassCycleTotal]) as MassCycleTotal
      --,sum([VolumeCycleTotal]) as VolumeCycleTotal
  FROM [MesMarkExchangeDb].[dbo].[TransportationWorkFact]  TF
       LEFT JOIN MesMarkExchangeDb.dbo.Equipment LE ON TF.LoadEquip = LE.ElementCode
	   LEFT JOIN MesMarkExchangeDb.dbo.TransportationWorkApproved AP ON AP.Id = TF.Id
	   LEFT JOIN MesMarkExchangeDb.dbo.Licence SPP ON TF.SppElement = SPP.ElementCode
       --Left join MesMarkExchangeDb.dbo.Equipment HE on TF.TransportEquip=HE.ElementCode
WHERE DumpTime >= dateadd(hour,19,convert(datetime,eomonth(@dt,-1))) and DumpTime <=dateadd(hour,19,convert(datetime,eomonth(@dt)))
and tf.StateId=3 and ap.StateId = 3
and tf.LoadLocation is not null

UNION ALL

SELECT
	TF.[Block] as LoadLocation --блок, для транспортировки со склада пустое
	--,TF.[LoadLocation] --место погрузки, для карьера пустое
	,TF.[DumpLocation] --место выгрузки
	,TF.[Material] --Тип руды
	,SPP.SppName as Licence --СПП|Лицензия
	,LE.Position as LoadEquip --погрузчик
	--,HE.Position as  --самосвал
	--,[Turn]--Очередь
	--,[Stage]--Этап
	--,Sum(TF.[Mass]) MassFact
	--,sum(TF.[Volume]) VolFact
	,AP.[Mass] MassApproved
	  ,AP.[Volume] VolumeApproved
	  ,(AP.FractionAu * AP.Mass)  as MassAU
	  --,sum([MassCycleTotal]) as MassCycleTotal
      --,sum([VolumeCycleTotal]) as VolumeCycleTotal
  FROM [MesMarkExchangeDb].[dbo].[TransportationWorkFact]  TF
       LEFT JOIN MesMarkExchangeDb.dbo.Equipment LE ON TF.LoadEquip = LE.ElementCode
	   LEFT JOIN MesMarkExchangeDb.dbo.TransportationWorkApproved AP ON AP.Id = TF.Id
	   LEFT JOIN MesMarkExchangeDb.dbo.Licence SPP ON TF.SppElement = SPP.ElementCode
       --Left join MesMarkExchangeDb.dbo.Equipment HE on TF.TransportEquip=HE.ElementCode
WHERE DumpTime >= dateadd(hour,19,convert(datetime,eomonth(@dt,-1))) and DumpTime <=dateadd(hour,19,convert(datetime,eomonth(@dt))) and LoadStartTime >='2022-12-30 19:00:00'
and tf.StateId=3 and ap.StateId = 3
and tf.Block is not null

UNION ALL

SELECT
	TM.[LoadLocation] as LoadLocation --место погрузки, для карьера пустое
	,TM.[DumpLocation] --место выгрузки
	,TM.[Material] --Тип руды
	,TMSPP.SppName as Licence --СПП|Лицензия
	,EQ.Position as LoadEquip --погрузчик
	--,HE.Position as  --самосвал
	--,[Turn]--Очередь
	--,[Stage]--Этап
	--,Sum(TF.[Mass]) MassFact
	--,sum(TF.[Volume]) VolFact
	,TMAP.[Mass] MassApproved
	  ,TMAP.[Volume] VolumeApproved
	  ,(TMAP.FractionAu * TMAP.Mass)  as MassAU
	  --,sum([MassCycleTotal]) as MassCycleTotal
      --,sum([VolumeCycleTotal]) as VolumeCycleTotal
	  FROM [MesMarkExchangeDb].[dbo].[TrammingWorkFact] TM
	  LEFT JOIN MesMarkExchangeDb.dbo.Equipment EQ ON TM.Equip = EQ.ElementCode
	  LEFT JOIN MesMarkExchangeDb.dbo.Licence TMSPP ON TMSPP.ElementCode = TM.SppElement
	  LEFT JOIN MesMarkExchangeDb.dbo.TrammingWorkApproved TMAP ON TMAP.Id = TM.Id
	 WHERE DumpEndTime >= dateadd(hour,19,convert(datetime,eomonth(@dt,-1))) and DumpEndTime <=dateadd(hour,19,convert(datetime,eomonth(@dt)))
	  and TM.StateId = 3 and TMAP.StateId = 1 -- TMAP.StateId = 1  для этого запроса 1 , потому что мы не забираем корректировки из АРММ  TrammingWorkFact (временно 02.03.23)
) t
--where t. LoadLocation ='Штабель 3'
--and Mass != MassCycleTotal
GROUP BY t.LoadLocation, t.DumpLocation, t.Material, t.Licence, t.LoadEquip
ORDER BY t.LoadLocation, t.DumpLocation, t.Material, t.Licence, t.LoadEquip

-----------------------------------------------------------------


SET TIME ZONE 'Asia/Irkutsk';
--EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON)
WITH TM(dt) as (VALUES(DATE_TRUNC('DAY', (@dt::DATE)::TIMESTAMP)))
--WITH TM(dt) as (VALUES(DATE_TRUNC('DAY', ('2023-09-06')::TIMESTAMP)))
Select --Наименование,
	--МатериалКомпонента,
	Точка_погрузки,
	Точка_разгрузки,
	Интматериал,
	Лицензия,
	Погрузчик,
Sum(МассаТвердого) as Масса,
Sum(ЖидМасса) as Объем,
--sum(КолВоЗолотаИЛИ_КолВоКомпонента) as КолВоЗолота
--avg(СодержаниеЗолотаИЛИ_СодержаниеКомпонента) as СодержаниеКомпонента1ЗаМесяц,
 --avg(СодержаниеВКомпоненте) as СодержаниеВКомпоненте,
 sum(КолВоВКомпоненте) as КолВоЗолота
 /*case
 	when sum(КолВоВКомпоненте)<> null then sum(КолВоВКомпоненте)
	when sum(КолВоВКомпоненте) is null then null
	end as КолВоВКомпоненте*/

from
(SELECT
	ac.elementcode,									/* Результрующие колонки */
	am.starttime,
	am.endtime,
	--ac.elementcode as Наименование,
	PMP.transportationmovement_loadername as Погрузчик,
	-- anode2.ElementCode as Точка_погрузки,
	anode3.ElementCode as Точка_разгрузки,
	T_Licenz.elementcode as Лицензия,
	pgb.elementcode as Точка_погрузки,
	mvint.elementcode as Интматериал,
	mm.fullname as Материал,null as МатериалКомпонента, null as Компонент,



	Coalesce(GEO_AMOUNT,0) as МассаТвердого,
	Coalesce(GEO_EXTRA_AMOUNT, 0) as ЖидМасса,
	(am.components::json->'Elements'->0->'Attributes'->1->'Value'->'Attributes'->0->'Value'->>'Value')::float as СодержаниеЗолотаИЛИ_СодержаниеКомпонента,
GEO_SHARE*(am.components::json->'Elements'->0->'Attributes'->2->'Value'->'Attributes'->0->'Value'->>'Value')::float as КолВоЗолотаИЛИ_КолВоКомпонента,
(am.components::json->'Elements'->0->'Attributes'->0->'Value'->'Elements'->0->'Attributes'->1->'Value'->'Attributes'->0->'Value'->>'Value')::float as СодержаниеВКомпоненте,
GEO_SHARE*(am.components::json->'Elements'->0->'Attributes'->0->'Value'->'Elements'->0->'Attributes'->2->'Value'->'Attributes'->0->'Value'->>'Value')::float as КолВоВКомпоненте

												/*Соединение Таблиц*/

from accchannels_channel ac
	join accmovements_movement am on ac.elementid=am.channel
 	left join (

SELECT
	elementid, transportationmovement_transportname, transportationmovement_loadername, transportationmovement_movementfrom, transportationmovement_movementto, transportationmovement_loaderreference, transportationmovement_transportreference,
COALESCE((SELECT elementid FROM public.pageology_outline WHERE elementid = ((SELECT Value FROM json_array_elements((SELECT Value FROM json_array_elements(GEO.Value->'Attributes')WHERE(Value->> 'Id') = 'GeoRecord')->'Value'->'Attributes') WHERE(Value->> 'Id') = 'ElementId')->'Value'->>'Value')),
(SELECT ou.elementid FROM public.pageology_outline ou
                                            JOIN public.pageology_suboutline sou ON sou.outline = ou.elementid
WHERE sou.elementid = ((SELECT Value FROM json_array_elements((SELECT Value FROM json_array_elements(GEO.Value->'Attributes')WHERE(Value->> 'Id') = 'GeoRecord')->'Value'->'Attributes') WHERE(Value->> 'Id') = 'ElementId')->'Value'->>'Value')))
                                AS outline,
COALESCE((SELECT COALESCE( ou.licence, bl.licence) FROM public.pageology_outline ou JOIN pageology_block bl ON bl.elementid = ou.block WHERE ou.elementid = ((SELECT Value FROM json_array_elements((SELECT Value FROM json_array_elements(GEO.Value->'Attributes')WHERE(Value->> 'Id') = 'GeoRecord')->'Value'->'Attributes') WHERE(Value->> 'Id') = 'ElementId')->'Value'->>'Value')),
(SELECT COALESCE( ou.licence, bl.licence) FROM public.pageology_outline ou JOIN pageology_block bl ON bl.elementid = ou.block
                                            JOIN public.pageology_suboutline sou ON sou.outline = ou.elementid
WHERE sou.elementid = ((SELECT Value FROM json_array_elements((SELECT Value FROM json_array_elements(GEO.Value->'Attributes')WHERE(Value->> 'Id') = 'GeoRecord')->'Value'->'Attributes') WHERE(Value->> 'Id') = 'ElementId')->'Value'->>'Value')))
                                AS licencemix,
						
						--geomix, GEO.ROW,
--((SELECT Value FROM json_array_elements((SELECT Value FROM json_array_elements(GEO.Value->'Attributes')WHERE(Value->> 'Id') = 'GeoRecord')->'Value'->'Attributes') WHERE(Value->> 'Id') = 'ElementId')->'Value'->>'Value') AS gid,
((SELECT Value FROM json_array_elements(GEO.Value->'Attributes')WHERE(Value->> 'Id') = 'Share')->'Value'->>'Value')::numeric AS GEO_SHARE,
((SELECT Value FROM json_array_elements(GEO.Value->'Attributes')WHERE(Value->> 'Id') = 'Amount')->'Value'->>'Value')::numeric AS GEO_AMOUNT,
((SELECT Value FROM json_array_elements(GEO.Value->'Attributes')WHERE(Value->> 'Id') = 'ExtraAmount')->'Value'->>'Value')::numeric AS GEO_EXTRA_AMOUNT
                      --,((SELECT Value FROM json_array_elements(MOV.Amount::json->'Attributes') WHERE (Value->>'Id')='Value')->'Value'->>'Value')::numeric as MOV_Amount
                        FROM public.pamovements_mixedpolygonentity AS MIX
                          --LEFT JOIN public.accmovements_movement AS MOV ON MOV.elementid = MIX.elementid
LEFT JOIN LATERAL(SELECT VALUE, ROW_NUMBER()OVER(ORDER BY VALUE::Text)AS ROW FROM json_array_elements(MIX.geomix::json->'Elements'))as GEO on true

    ) PMP ON PMP.elementid = AM.elementid --Транспортировка

 join accchannels_nodebase anode2 on anode2.elementid=pmp.transportationmovement_movementfrom
  join accchannels_nodebase anode3 on anode3.elementid=pmp.transportationmovement_movementto
  inner join public.accmovements_nodeinstance ANI_Source ON ANI_Source.elementid = AM.source
  inner join public.accmovements_nodeinstance ANI_Dest ON ANI_Dest.elementid = AM.destination
 join paminingpolygon_miningpolygoncollection T_Licenz
  ON T_Licenz.elementid = PMP.licencemix--::json->'Elements'-> 0 -> 'Attributes'-> 0 ->'Value'->'Attributes'-> 0 ->'Value' ->>'Value'
 join pageology_outline pgo on pgo.elementid=pmp.outline
 join pageology_block pgb on pgo.block=pgb.elementid
 join mvmaterials_materialint mvint on mvint.elementid=pgo.integrationmaterial
  --join pageology_level pgl on pgl.elementid=pgb.level
	join material_material mm on mm.elementid = am.material


												/*Условия и ограничения*/

where  am.modelreference = 'o:site/app/RcAppProAcc/AccountingModelDetail'
and  (am.endtime > date_trunc('Month',(SELECT dt FROM TM))-interval '5 hour' and am.endtime <= date_trunc('Month',(SELECT dt FROM TM)+interval '1 month')-interval '5 hour'	)											/*Выбор необходимых хранилищ*/
and
ac.elementcode in (
	'Взорванная горная масса (субконтура) --> Экскавация'
     ) --Массив каналов
------------------
 UNION ALL

SELECT
	ac.elementcode,									/* Результрующие колонки */
	am.starttime,
	am.endtime,
	PMP.transportationmovement_loadername as Погрузчик,
	anode3.ElementCode as Точка_разгрузки,
	T_Licenz.elementcode as Лицензия,
	anode2.ElementCode as Точка_погрузки,
	--pgb.elementcode as Точка_погрузки,
	mvint.elementcode as Интматериал,
	mm.fullname as Материал,null as МатериалКомпонента, null as Компонент,
	/*

	ac.elementcode,									/* Результрующие колонки */
	am.starttime,
	am.endtime,
	PMP.transportationmovement_loadername as Погрузчик,
	anode3.ElementCode as Точка_разгрузки,
	T_Licenz.elementcode as Лицензия,
	pgb.elementcode as Точка_погрузки,
	mvint.elementcode as Интматериал,
	mm.fullname as Материал,mn.fullname as МатериалКомпонента, mq.Fullname as Компонент,

	*/


	/* Парсинг Json для компонентов */
	Coalesce(GEO_AMOUNT,0) as МассаТвердого,
	Coalesce(GEO_EXTRA_AMOUNT, 0) as ЖидМасса,
	(am.components::json->'Elements'->0->'Attributes'->1->'Value'->'Attributes'->0->'Value'->>'Value')::float as СодержаниеЗолотаИЛИ_СодержаниеКомпонента,
GEO_SHARE*(am.components::json->'Elements'->0->'Attributes'->2->'Value'->'Attributes'->0->'Value'->>'Value')::float as КолВоЗолотаИЛИ_КолВоКомпонента,
(am.components::json->'Elements'->0->'Attributes'->0->'Value'->'Elements'->0->'Attributes'->1->'Value'->'Attributes'->0->'Value'->>'Value')::float as СодержаниеВКомпоненте,
GEO_SHARE*(am.components::json->'Elements'->0->'Attributes'->0->'Value'->'Elements'->0->'Attributes'->2->'Value'->'Attributes'->0->'Value'->>'Value')::float as КолВоВКомпоненте

												/*Соединение Таблиц*/

from accchannels_channel ac
	join accmovements_movement am on ac.elementid=am.channel
 	left join (

SELECT
	elementid, transportationmovement_transportname, transportationmovement_loadername, transportationmovement_movementfrom, transportationmovement_movementto, transportationmovement_loaderreference, transportationmovement_transportreference,
COALESCE((SELECT elementid FROM public.pageology_outline WHERE elementid = ((SELECT Value FROM json_array_elements((SELECT Value FROM json_array_elements(GEO.Value->'Attributes')WHERE(Value->> 'Id') = 'GeoRecord')->'Value'->'Attributes') WHERE(Value->> 'Id') = 'ElementId')->'Value'->>'Value')),
(SELECT ou.elementid FROM public.pageology_outline ou
                                            JOIN public.pageology_suboutline sou ON sou.outline = ou.elementid
WHERE sou.elementid = ((SELECT Value FROM json_array_elements((SELECT Value FROM json_array_elements(GEO.Value->'Attributes')WHERE(Value->> 'Id') = 'GeoRecord')->'Value'->'Attributes') WHERE(Value->> 'Id') = 'ElementId')->'Value'->>'Value')))
                                AS outline,
COALESCE((SELECT COALESCE( ou.licence, bl.licence) FROM public.pageology_outline ou JOIN pageology_block bl ON bl.elementid = ou.block WHERE ou.elementid = ((SELECT Value FROM json_array_elements((SELECT Value FROM json_array_elements(GEO.Value->'Attributes')WHERE(Value->> 'Id') = 'GeoRecord')->'Value'->'Attributes') WHERE(Value->> 'Id') = 'ElementId')->'Value'->>'Value')),
(SELECT COALESCE( ou.licence, bl.licence) FROM public.pageology_outline ou JOIN pageology_block bl ON bl.elementid = ou.block
                                            JOIN public.pageology_suboutline sou ON sou.outline = ou.elementid
WHERE sou.elementid = ((SELECT Value FROM json_array_elements((SELECT Value FROM json_array_elements(GEO.Value->'Attributes')WHERE(Value->> 'Id') = 'GeoRecord')->'Value'->'Attributes') WHERE(Value->> 'Id') = 'ElementId')->'Value'->>'Value')))
                                AS licencemix,
						--geomix, GEO.ROW,
	--((SELECT Value FROM json_array_elements((SELECT Value FROM json_array_elements(GEO.Value->'Attributes')WHERE(Value->> 'Id') = 'GeoRecord')->'Value'->'Attributes') WHERE(Value->> 'Id') = 'ElementId')->'Value'->>'Value') AS gid,
((SELECT Value FROM json_array_elements(GEO.Value->'Attributes')WHERE(Value->> 'Id') = 'Share')->'Value'->>'Value')::numeric AS GEO_SHARE,
((SELECT Value FROM json_array_elements(GEO.Value->'Attributes')WHERE(Value->> 'Id') = 'Amount')->'Value'->>'Value')::numeric AS GEO_AMOUNT,
((SELECT Value FROM json_array_elements(GEO.Value->'Attributes')WHERE(Value->> 'Id') = 'ExtraAmount')->'Value'->>'Value')::numeric AS GEO_EXTRA_AMOUNT
                      --,((SELECT Value FROM json_array_elements(MOV.Amount::json->'Attributes') WHERE (Value->>'Id')='Value')->'Value'->>'Value')::numeric as MOV_Amount
                        FROM public.pamovements_mixedpolygonentity AS MIX
                          --LEFT JOIN public.accmovements_movement AS MOV ON MOV.elementid = MIX.elementid
LEFT JOIN LATERAL(SELECT VALUE, ROW_NUMBER()OVER(ORDER BY VALUE::Text)AS ROW FROM json_array_elements(MIX.geomix::json->'Elements'))as GEO on true
	
	) PMP ON PMP.elementid = AM.elementid --Транспортировка

 join accchannels_nodebase anode2 on anode2.elementid=pmp.transportationmovement_movementfrom
  join accchannels_nodebase anode3 on anode3.elementid=pmp.transportationmovement_movementto
  inner join public.accmovements_nodeinstance ANI_Source ON ANI_Source.elementid = AM.source
  inner join public.accmovements_nodeinstance ANI_Dest ON ANI_Dest.elementid = AM.destination
 join paminingpolygon_miningpolygoncollection T_Licenz
  ON T_Licenz.elementid = PMP.licencemix--::json->'Elements'-> 0 -> 'Attributes'-> 0 ->'Value'->'Attributes'-> 0 ->'Value' ->>'Value'
 join pageology_outline pgo on pgo.elementid=pmp.outline
 join pageology_block pgb on pgo.block=pgb.elementid
 join mvmaterials_materialint mvint on mvint.elementid=pgo.integrationmaterial
  --join pageology_level pgl on pgl.elementid=pgb.level
	join material_material mm on mm.elementid = am.material


												/*Условия и ограничения*/

where  am.modelreference = 'o:site/app/RcAppProAcc/AccountingModelDetail'
and  (am.endtime > date_trunc('Month',(SELECT dt FROM TM))-interval '5 hour' and am.endtime <= date_trunc('Month',(SELECT dt FROM TM)+interval '1 month')-interval '5 hour'	)										/*Выбор необходимых хранилищ*/
and
ac.elementcode in (

      'Штабель 0 --> Экскавация на складе',
      'Штабель 1 --> Экскавация на складе',
      'Штабель 1.1 --> Экскавация на складе',
      'Штабель 11 --> Экскавация на складе',
      'Штабель 15.1 --> Экскавация на складе',
      'Штабель 15.2 --> Экскавация на складе',
      'Штабель 15.3 --> Экскавация на складе',
      'Штабель 15.4 --> Экскавация на складе',
      'Штабель 2 --> Экскавация на складе',
      'Штабель 2.1 --> Экскавация на складе',
      'Штабель 2.2 --> Экскавация на складе',
      'Штабель 2.3 --> Экскавация на складе',
      'Штабель 2.4 --> Экскавация на складе',
      'Штабель 3 --> Экскавация на складе',
      'Штабель 4 --> Экскавация на складе',
      'Штабель 5.1-- > Экскавация(втор.дробл.)(0139)',
      'Склад 11 --> Экскавация на складе',
      'Склад 13 --> Экскавация на складе',
      'Склад 14 --> Экскавация на складе'
     ) --Массив каналов
 UNION ALL
SELECT
	ac.elementcode,									/* Результрующие колонки */
	am.starttime,
	am.endtime,
	--ac.elementcode as Наименование,
	PMP.transportationmovement_loadername as Погрузчик,
	-- anode2.ElementCode as Точка_погрузки,
	anode3.ElementCode as Точка_разгрузки,
	T_Licenz.elementcode as Лицензия,
	pgb.elementcode as Точка_погрузки,
	mvint.elementcode as Интматериал,
	mm.fullname as Материал,
	null as МатериалКомпонента,
	null as Компонент,



	/* Парсинг Json для компонентов */
	Coalesce(GEO_AMOUNT,0) as МассаТвердого,
	Coalesce(GEO_EXTRA_AMOUNT, 0) as ЖидМасса,
	null as СодержаниеЗолотаИЛИ_СодержаниеКомпонента,
	null as КолВоЗолотаИЛИ_КолВоКомпонента,
	null as СодержаниеВКомпоненте,
	null as КолВоВКомпоненте


	/*Coalesce((((SELECT Value FROM json_array_elements(
	(SELECT Value FROM json_array_elements(ct.Value->'Attributes') as t1 					WHERE (t1.Value->>'Id')='Fraction')->'Value'->'Attributes') as t2
	WHERE (t2.Value->>'Id')='Value')->'Value'->>'Value')::float), 0) as СодержаниеЗолотаИЛИ_СодержаниеКомпонента,
	Coalesce((((SELECT Value FROM json_array_elements(
	(SELECT Value FROM json_array_elements(ct.Value->'Attributes') as t1 					WHERE (t1.Value->>'Id')='Amount')->'Value'->'Attributes') as t2
	WHERE (t2.Value->>'Id')='Value')->'Value'->>'Value')::float), 0) as КолВоЗолотаИЛИ_КолВоКомпонента,
	Coalesce((((Select Value from json_array_elements(
	(SELECT Value FROM json_array_elements(
	(SELECT Value FROM json_array_elements(ct.Value->'Attributes') as t1 				WHERE (t1.Value->>'Id')='Components')->'Value'->'Elements' ->0->'Attributes') as t2
	WHERE (t2.Value->>'Id')='Fraction')->'Value'->'Attributes') as t3  			WHERE (t3.Value ->>'Id')='Value')->'Value'->>'Value')::float), 0) as СодержаниеВКомпоненте,
	Coalesce((((Select Value from json_array_elements(
	(SELECT Value FROM json_array_elements(
	(SELECT Value FROM json_array_elements(ct.Value->'Attributes') as t1 				WHERE (t1.Value->>'Id')='Components')->'Value'->'Elements' ->0->'Attributes') as t2
	WHERE (t2.Value->>'Id')='Amount')->'Value'->'Attributes') as t3  			WHERE (t3.Value ->>'Id')='Value')->'Value'->>'Value')::float), 0) as КолВоВКомпоненте*/

	/*Соединение Таблиц*/

	from accchannels_channel ac
	join accmovements_movement am on ac.elementid=am.channel
 	left join (

SELECT
	elementid, transportationmovement_transportname, transportationmovement_loadername, transportationmovement_movementfrom, transportationmovement_movementto, transportationmovement_loaderreference, transportationmovement_transportreference,
COALESCE((SELECT elementid FROM public.pageology_outline WHERE elementid = ((SELECT Value FROM json_array_elements((SELECT Value FROM json_array_elements(GEO.Value->'Attributes')WHERE(Value->> 'Id') = 'GeoRecord')->'Value'->'Attributes') WHERE(Value->> 'Id') = 'ElementId')->'Value'->>'Value')),
(SELECT ou.elementid FROM public.pageology_outline ou
                                            JOIN public.pageology_suboutline sou ON sou.outline = ou.elementid
WHERE sou.elementid = ((SELECT Value FROM json_array_elements((SELECT Value FROM json_array_elements(GEO.Value->'Attributes')WHERE(Value->> 'Id') = 'GeoRecord')->'Value'->'Attributes') WHERE(Value->> 'Id') = 'ElementId')->'Value'->>'Value')))
                                AS outline,
COALESCE((SELECT COALESCE( ou.licence, bl.licence) FROM public.pageology_outline ou JOIN pageology_block bl ON bl.elementid = ou.block WHERE ou.elementid = ((SELECT Value FROM json_array_elements((SELECT Value FROM json_array_elements(GEO.Value->'Attributes')WHERE(Value->> 'Id') = 'GeoRecord')->'Value'->'Attributes') WHERE(Value->> 'Id') = 'ElementId')->'Value'->>'Value')),
(SELECT COALESCE( ou.licence, bl.licence) FROM public.pageology_outline ou JOIN pageology_block bl ON bl.elementid = ou.block
                                            JOIN public.pageology_suboutline sou ON sou.outline = ou.elementid
WHERE sou.elementid = ((SELECT Value FROM json_array_elements((SELECT Value FROM json_array_elements(GEO.Value->'Attributes')WHERE(Value->> 'Id') = 'GeoRecord')->'Value'->'Attributes') WHERE(Value->> 'Id') = 'ElementId')->'Value'->>'Value')))
                                AS licencemix,
						
						--geomix, GEO.ROW,
	--((SELECT Value FROM json_array_elements((SELECT Value FROM json_array_elements(GEO.Value->'Attributes')WHERE(Value->> 'Id') = 'GeoRecord')->'Value'->'Attributes') WHERE(Value->> 'Id') = 'ElementId')->'Value'->>'Value') AS gid,
((SELECT Value FROM json_array_elements(GEO.Value->'Attributes')WHERE(Value->> 'Id') = 'Share')->'Value'->>'Value')::numeric AS GEO_SHARE,
((SELECT Value FROM json_array_elements(GEO.Value->'Attributes')WHERE(Value->> 'Id') = 'Amount')->'Value'->>'Value')::numeric AS GEO_AMOUNT,
((SELECT Value FROM json_array_elements(GEO.Value->'Attributes')WHERE(Value->> 'Id') = 'ExtraAmount')->'Value'->>'Value')::numeric AS GEO_EXTRA_AMOUNT
                      --,((SELECT Value FROM json_array_elements(MOV.Amount::json->'Attributes') WHERE (Value->>'Id')='Value')->'Value'->>'Value')::numeric as MOV_Amount
                        FROM public.pamovements_mixedpolygonentity AS MIX
                          --LEFT JOIN public.accmovements_movement AS MOV ON MOV.elementid = MIX.elementid
LEFT JOIN LATERAL(SELECT VALUE, ROW_NUMBER()OVER(ORDER BY VALUE::Text)AS ROW FROM json_array_elements(MIX.geomix::json->'Elements'))as GEO on true

	) PMP ON PMP.elementid = AM.elementid --Транспортировка

 join accchannels_nodebase anode2 on anode2.elementid=pmp.transportationmovement_movementfrom
  join accchannels_nodebase anode3 on anode3.elementid=pmp.transportationmovement_movementto
  inner join public.accmovements_nodeinstance ANI_Source ON ANI_Source.elementid = AM.source
  inner join public.accmovements_nodeinstance ANI_Dest ON ANI_Dest.elementid = AM.destination
 join paminingpolygon_miningpolygoncollection T_Licenz
  ON T_Licenz.elementid = PMP.licencemix--::json->'Elements'-> 0 -> 'Attributes'-> 0 ->'Value'->'Attributes'-> 0 ->'Value' ->>'Value'
 join pageology_outline pgo on pgo.elementid=pmp.outline
 join pageology_block pgb on pgo.block=pgb.elementid
 join mvmaterials_materialint mvint on mvint.elementid=pgo.integrationmaterial
  --join pageology_level pgl on pgl.elementid=pgb.level
	join material_material mm on mm.elementid = am.material
	/*cross JOIN LATERAL json_array_elements(am.Components::json->'Elements') as ct
	left join material_material mn ON mn.elementid =
(SELECT Value
	FROM json_array_elements(
(SELECT Value FROM json_array_elements(ct.Value->'Attributes') as t1 WHERE (t1.Value->>'Id')='Material')->'Value'->'Attributes') as t2
			WHERE (t2.Value->>'Id')='ElementId')->'Value'->>'Value'
left join material_material mq ON mq.elementid =
(Select Value from json_array_elements(
(SELECT Value FROM json_array_elements(
(SELECT Value FROM json_array_elements(ct.Value->'Attributes') as t1 				WHERE (t1.Value->>'id')='Components')->'Value'->'Elements' ->1->'Attributes') as t2
				WHERE (t2.Value->>'id')='Material')->'Value'->'Attributes') as t3  			WHERE (t3.Value ->>'id')='ElementId')->'Value'->>'Value'*/

												/*Условия и ограничения*/

where  am.modelreference = 'o:site/app/RcAppProAcc/AccountingModelDetail'
and  (am.endtime > date_trunc('Month',(SELECT dt FROM TM))-interval '5 hour' and am.endtime <= date_trunc('Month',(SELECT dt FROM TM)+interval '1 month')-interval '5 hour'	)											/*Выбор необходимых хранилищ*/
and
ac.elementcode in (
	      'Взорванная горная масса (Кадаликанское) --> Экскавация (Кадаликанское)',
      'Взорванная горная масса (В. Кадаликанское) --> Экскавация (В. Кадаликанское)'

     )

)  as q
group by 1,2,3,4,5
order by 1,2,3,4,5





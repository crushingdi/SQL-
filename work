
 5. проверить расширения бвр на запас
select* from accmovements_nodeinstance accnode
left join dbomovements_boreholestore movborstore on movborstore.elementid=accnode.elementid
where movborstore.elementid='baac0e51ef164a39b83062629f75982a'
-----------------------------------------------------------


-----------------------------------------------------------
6. Сделать блок доступным для взрывания

select * from public.dbo_blastproject where block='e4431fb212ba41b5aa0ca28c72d66453'
сделать true для isreadytoblast

BlastBlock: {Id: "e4431fb212ba41b5aa0ca28c72d66453", Label: "700-5-1"}

-----------------------------------------------------------
7. Сделать скважины подвержденными через IsApproved

SELECT distinct dh.elementid,/*toblast.project id_project pblock."number",*/ dh."number",dh.isdefective, dh.isavailabletocharge, dh.blastblock as dhblock, db.block as dbblock, cr.project,toblast.IsApproved,toblast.addat, toblast.updateat
--elementid, isdefective, isavailabletocharge, "number",issubdrill, license, stage, 
--turn, drillblock, machine, blastblock, producingblock, modelreference, elementcode, 
--addat, updateat, domain, isnondeletable, isreadonly, creationtime, expirationtime, templatereference, modelreferenceinternal
	FROM dbo_blastproject db
	left join public.dbo_chargingwork cr on db.block=cr.block
	left join  dbo_borehole dh on dh.blastblock=db.block
	left join public.dbo_toblastborehole toblast2 on toblast2.borehole=dh.elementid
	left join public.dbo_toblastborehole toblast on cr.project=toblast.project
	--join pageology_blastblock pblock on db.block=pblock.blastblock
	where toblast.project='7eaae69002c44bc7840ce1e2cc93b415' 
	--and toblast.addat>'2022-11-22 19:00:00.00+07' 
	--and toblast.IsApproved= 'false'-- 
	--and number='016'

Взять dh.elementid пойти в dbo_toblastborehole и выбрать все по проекту и апдейт атрибута IsApproved

Добавить взрывной блок из модели к запросу

---------------------------------------------------------------------------------
8.
--запасы на число. делаем выборку по времени и блоку и лицензии

Select bp.elementId,pit."name",acch.elementcode, bh.elementid as boreholeId, bh.number, ni.elementid as NiElementId
, (((SELECT Value
             FROM jsonb_array_elements(ni.store_amount::jsonb -> 'Attributes')
             WHERE jsonb_extract_path_text(Value, 'Id') = 'Value') -> 'Value' ->> 'Value')::float) as store_amount
, (((SELECT Value
             FROM jsonb_array_elements(ni.store_extraamount::jsonb -> 'Attributes')
             WHERE jsonb_extract_path_text(Value, 'Id') = 'Value') -> 'Value' ->> 'Value')::float) as store_extraamount
,ni.starttime, ni.endtime
--, bhs.*
from dbo_blastproject bp
join dbo_toblastborehole tb on bp.elementid = tb.project
join dbo_borehole bh on bh.elementid = tb.borehole
join public.dbomovements_boreholestore bhs on bhs.borehole = bh.elementid 
and bhs.modelreference = 'o:site/app/RcAppProAcc/AccountingModelDetail' 
and bhs.templatereference = 's:PolyusMesPa/Domains/DboMovements/ChargedBorehole'
join public.accmovements_nodeinstance ni on ni.elementid = bhs.elementid
join accchannels_nodebase accnode on  accnode.elementid=ni.node
left join pageology_pit pit on pit.elementid=bp.pit
join accmovements_movement acc on acc.batchid=ni.batchid
left join public.accchannels_channel acch on acc.channel=acch.elementid
where bp.block in 
-------или номер блока
/*(select elementid from pageology_blastblock 
where elementid='dd4d71d925024bfc84a67141e569f0ca'
--number in ('700-7') 
and elementcode like 'Вер%') */
------или проекта массового взрыва
(select block from dbo_blastproject  where elementid = '270e0daef73a4d4da8e40c18ee38b6d2')
and ni.starttime >= '2022-11-26 07:00:00 +08' and ni.endtime <= '2022-12-26 19:00:00 +08' 
--bh.elementid = '51e3002a162b4d4fae885e01cbf66145'
order by ni.starttime, bh.number

всталяем bp.elementID в запрос:

select * from dbo_blastproject  where elementid = 'a4ad6a4a59884e30a90cae5247c83ab2'

select * from dbo_toblastborehole 
where project = '9418c3675ac948b2893cb0ccb0d76be1'

делаем апдейт всех скважин по проекту в статус isapproved = true:

update dbo_toblastborehole set isapproved = true where project = 'bdc0c6c91c144b48a4e3f6fa74314525' and isapproved = false

---------------------------------------------------------------
9. Сверка Бурения 
1. Запрос постгрес

	SET TIME ZONE 'Asia/Irkutsk';
Select 
am.elementid  as am_elementid,
PDB.borehole as  PDB_borehole ,
PDB.work as  PDB_work ,
to_char(sd.proday, 'DD.MM.YYYY') as ДатаБурения,
sd.proday as date,
   tt.elementcode as Смена,
  tt2.label as Лицензия,
  tt4.label as Очередь,
  tt3.label as Этап,
  am.sourcecreation as ктосоздал,
  PDB.OperSysId as OperSysId,
	am.batchid as  batchid,
	bl.elementid as project,
  erp_t.position as position,
  db.number as Блок,
  BH.number as Скважина,
  bh.elementid as elementid,
  rr.Name   as Станок,
  mm.ElementCode as материал,
  Case mm.ElementCode
           when 'Пробуренные скважины (1075621)' then 'Горная масса'
           When 'Скважины руды (1028255)' then 'Руда'
           When 'Скважины вскрыши (1028251)' then 'Вскрыша'
           else null
           end  as материал2,
					 mv.elementcode тип_скважины,
Coalesce(Sum(((SELECT Value
  FROM jsonb_array_elements(pbh.Depth::jsonb -> 'Attributes')
    WHERE jsonb_extract_path_text(Value, 'Id') = 'Value') -> 'Value' ->> 'Value'):: float)) as ПлановоеБурение,
Coalesce(Sum((((SELECT Value
  FROM jsonb_array_elements(am.Amount::jsonb->'Attributes')
          WHERE jsonb_extract_path_text(Value, 'Id') = 'Value') -> 'Value' ->>'Value')::float))) as Пробуренно,
Coalesce(Sum((((SELECT Value
  FROM jsonb_array_elements(am.Amount::jsonb->'Attributes')
          WHERE jsonb_extract_path_text(Value, 'Id') = 'Value') -> 'Value' ->>'Value')::float))) -
Coalesce(Sum((((SELECT Value
  FROM jsonb_array_elements(pbh.Depth::jsonb -> 'Attributes')
    WHERE jsonb_extract_path_text(Value, 'Id') = 'Value') -> 'Value' ->> 'Value'):: float))) as ОТклонениеПМ,
case when Coalesce(Sum((((SELECT Value
  FROM jsonb_array_elements(am.Amount::jsonb->'Attributes')
          WHERE jsonb_extract_path_text(Value, 'Id') = 'Value') -> 'Value' ->>'Value')::float)))<=0 or
Coalesce(Sum((((SELECT Value
  FROM jsonb_array_elements(pbh.Depth::jsonb -> 'Attributes')
WHERE jsonb_extract_path_text(Value, 'Id') = 'Value') -> 'Value' ->> 'Value'):: float)))<=0 then 0 else Coalesce(Sum((((SELECT Value
  FROM jsonb_array_elements(am.Amount::jsonb->'Attributes')
          WHERE jsonb_extract_path_text(Value, 'Id') = 'Value') -> 'Value' ->>'Value')::float))) /
Coalesce(Sum((((SELECT Value
  FROM jsonb_array_elements(pbh.Depth::jsonb -> 'Attributes')
    WHERE jsonb_extract_path_text(Value, 'Id') = 'Value') -> 'Value' ->> 'Value'):: float)))-1 end as ОТклонениеПР,
       bh.isdefective as ПризнакБрака,
       bh.issubdrill as ПризнакПеребура,
       PDB.startAt as НачалоБурения,
       PDB.endAT as КонецБурения,
	   PDB.addat as addat,
	   PDB.updateat as updateat
--count(BH.number)  as КолСкважин
from dbo_drillingwork DW
    left join erpresources_resource rr on dw.machine = rr.elementid
	left join public.erpequipment_technicalplace erp_t on erp_t.processsegment=rr.elementid
    Left join dbo_shiftdef sd on sd.elementid = dw.shift
    left join dbomovements_producedrilledborehole PDB on pdb.work = dw.elementid
    left join dbo_borehole bh on bh.elementid = pdb.borehole
	 left join dbo_toblastborehole tb on bh.elementid=tb.borehole
	 left join dbo_blastproject bl on tb.project=bl.elementid
    left join pageology_drillblock db on db.elementid = bh.drillblock
    left join accmovements_movement am on am.elementid = pdb.elementid
    join material_material mm on am.material = mm.elementid
    left join dbo_plannedborehole pbh on pbh.elementid = bh.plannedborehole
    left join tree_treenode tt on tt.elementid = sd.timesdef
    left join tree_treenode tt2 on bh.license=tt2.elementid
    left join tree_treenode tt3 on bh.stage=tt3.elementid
    left join tree_treenode tt4 on bh.turn=tt4.elementid
		left join mvholetypes_mvtypehole mv on mv.elementid=bh.holetype
where (sd.proday:: date :: timestamp >= '2023-02-01' and sd.proday:: date :: timestamp <= '2023-02-16')  --and am.sourcecreation is null
--and erp_t.position ='1106' 
--and erp_t.position='1106' 
--and erp_t.position='1106'
--and OperSysId ilike '%115'
--and db.number='690-1' 
--and BH.number in  ('118','133', '148', '163', '119', '134' , '149', '150')
--and erp_t.position='1105' 
--and tt.elementcode='Смена №2'
--and BH.number like '%115'
and am.elementid in ('2394561774d04e24b8e0a17da83e6d8d' , '7bc6194e105a41c2b4f875b4cc5c17a5')
/*in (
	'Д272',*/
--and  (bh.isdefective = 'true' or bh.issubdrill = 'true')
--and am.batchid='b427d474a67240a8aaf96ea93db956a4'

--PDB.startAt  between '2022-11-25'::timestamp - interval '4 hour' and '2022-11-25'::timestamp + time '19:59:59'
group by --ДатаБурения,
Блок,Лицензия,Очередь,Этап,Скважина,Смена,Станок,mm.ElementCode,ПризнакБрака,ПризнакПеребура,НачалоБурения,КонецБурения,date,
OperSysId,ктосоздал,PDB.addat,PDB.updateat,position,batchid,am.elementid,bh.elementid,bl.elementid,PDB.borehole,PDB_work, mv.elementcode
order by ДатаБурения,Смена,Скважина
	
	
	
	


и запрос интегра:

DECLARE @dateStart as datetime, @dateEnd as datetime, @offset as int;


DECLARE @dateStart as datetime, @dateEnd as datetime, @offset as int;

SET @dateStart = '2022-12-10 19:00:00';
SET @dateEnd = '2022-12-11 19:00:00';


select
t.DRILL_REC_IDENT,
	T.WencoId,
	T.DrillBlockNumber, 
	--T.HoleId as HoleId,
	--DATALENGTH(SUBSTRING(T.HoleId, 1, LEN(T.HoleId)))  as HoleIdCount, 
	case
		when T.HoleIdCount=2 then '0' + T.HoleId
		when T.HoleIdCount<2 then '00' + T.HoleId
		else HoleId
		end as HoleId,
	HoleIdCount,
	T.PlannedCollarY, 
	T.PlannedCollarX, 
	T.PlannedCollarZ, 
	max(T.DrillTipCollarY) as DrillTipCollarY, 
	max(T.DrillTipCollarX) as DrillTipCollarX, 
	max(T.DrillTipCollarZ) as DrillTipCollarZ, 
	T.PlannedToeY, 
	T.PlannedToeX,  
	T.PlannedToeZ, 
	max(T.DrillTipToeY) as DrillTipToeY, 
	max(T.DrillTipToeX) as DrillTipToeX, 
	min(T.DrillTipToeZ) as DrillTipToeZ, 
	sum(T.Depth) as Depth, 
	T.EquipmentId, 
	min(T.StartTimeStamp) as StartTimeStamp, 
	max(T.EndTimeStamp) as EndTimeStamp, 
	T.LicenseName, 
	max(T.DateTimeChange) as DateTimeChange,
    max(T.DateTimeDelete) as DateTimeDelete,	 
	T.DrillHoleType
from (
select distinct
	DT2.DRILL_REC_IDENT,
	'DH/'+CAST(DT2.DRILL_BLAST_IDENT as NVARCHAR(30)) + '/' +  replace(replace(replace(replace(DT2.HOLE_CODE ,'/''-',''),'(',''),')',''),' ','') as WencoId
    ,(SELECT SUBSTRING( DB.BLAST_LOCATION_SNAME,V.number,1)
          FROM master.dbo.spt_values V
          WHERE V.type='P' AND V.number BETWEEN 1 AND LEN( DB.BLAST_LOCATION_SNAME) AND SUBSTRING(DB.BLAST_LOCATION_SNAME,V.number,1) LIKE '[0123456789-]'
        ORDER BY V.number
        FOR XML PATH('')) as DrillBlockNumber
	,replace(replace(replace(replace(DH.HOLE_CODE,'/''-',''),'(',''),')',''),' ','') as HoleId
	,DATALENGTH(SUBSTRING(replace(replace(replace(replace(DH.HOLE_CODE,'/''-',''),'(',''),')',''),' ',''), 1, LEN(DH.HOLE_CODE)))  as HoleIdCount
	,DH.DESIGN_NORTHING AS PlannedCollarY
	,DH.DESIGN_EASTING as PlannedCollarX
	,DH.DESIGN_ELEVATION AS PlannedCollarZ
	,DT2.HOLE_NORTHING AS DrillTipCollarY
	,DT2.HOLE_EASTING AS DrillTipCollarX
	,DT2.HOLE_ELEVATION AS DrillTipCollarZ
	,DH.DESIGN_TOE_NORTHING AS PlannedToeY
	,DH.DESIGN_TOE_EASTING AS PlannedToeX
	,DH.DESIGN_TOE_ELEVATION AS PlannedToeZ
	--,DH.DESIGN_DEPTH AS 'Плановая глубина'
	,DT2.HOLE_TOE_NORTHING AS DrillTipToeY
	,DT2.HOLE_TOE_EASTING AS DrillTipToeX
	,DT2.HOLE_TOE_ELEVATION AS DrillTipToeZ
	,Case when isnull(DT2.DateTimeDelete, '') = '' then DT2.HOLE_DEPTH else 0 end AS Depth
	,DT2.EQUIP_IDENT as EquipmentId
	,DT2.DRILL_START_TIMESTAMP as StartTimeStamp
	,DT2.END_TIMESTAMP as EndTimeStamp
	--,DH.COMMENT
	,C.PIT_NAME as LicenseName
	,(select max(changetime) from asugtk2mes_journal where operid = DT2.DRILL_REC_IDENT) as DateTimeChange
	,case when (select count(DTR.DRILL_REC_IDENT) from asugtk.DRILL_TRANS DTR where DTR.DRILL_BLAST_IDENT = DT2.DRILL_BLAST_IDENT and DTR.HOLE_CODE = DT2.HOLE_CODE and isnull(DTR.DateTimeDelete,'') =  '') > 0 then null 
	else DT2.DateTimeDelete end as DateTimeDelete 
	,2 as DrillHoleType
	----, case который будет брать и 2 и 3 в случаи если в  HoleId присутствует хотя б одна П.
from asugtk.DRILL_TRANS DT
	join asugtk.DRILL_TRANS DT2 on DT2.DRILL_BLAST_IDENT = DT.DRILL_BLAST_IDENT and DT2.HOLE_CODE=DT.HOLE_CODE  
	join asugtk.DRILL_BLAST DB on DT2.DRILL_BLAST_IDENT = DB.DRILL_BLAST_IDENT
	join asugtk.DRILL_HOLE DH on DT2.DRILL_BLAST_IDENT = DH.DRILL_BLAST_IDENT and DH.HOLE_CODE=DT2.HOLE_CODE
	join asugtk.LOCATION_BLAST_PATTERN c on DB.BLAST_LOCATION_SNAME = c.LOCATION_SNAME
where DT.DRILL_REC_IDENT in
    (select distinct DTIdent.DRILL_REC_IDENT 
		from dbo.asugtk2mes_journal mj
		join asugtk.DRILL_TRANS DTIdent on DTIdent.DRILL_REC_IDENT = mj.operid
		where mj.SourceTableName = 'asugtk.DRILL_TRANS' 
		and ((mj.changetime between @dateStart and @dateEnd) 
		or (DTIdent.END_TIMESTAMP between @dateStart and @dateEnd)) 
		and (DTIdent.END_TIMESTAMP is not null) 
		and isnull(DTIdent.HOLE_DEPTH,0) > 0
		and charindex(' ', DTIdent.HOLE_CODE) like '%[A-Za-z0-9]%' )	
		) as T
		where HoleId like '[БПД(0-9)]%[0-9]' and EquipmentId like '%1106%'
		
group by WencoId, DrillBlockNumber, HoleId, PlannedCollarY, PlannedCollarX, PlannedCollarZ, PlannedToeY, PlannedToeX, PlannedToeZ, EquipmentId, LicenseName, DrillHoleType,T.HoleIdCount,DRILL_REC_IDENT
order by  EndTimeStamp 



10. Выверка АРММ и МЕС

АРММ:

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
	  ,SUM(t.MassApproved) as MassApproved
	  ,SUM(t.VolumeApproved) as VolumeApproved
	  ,SUM(t.MassAU) as MassAU
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
WHERE DumpTime >= '2022-10-31 19:00:00' and DumpTime <='2022-11-30 19:00:00'
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
WHERE DumpTime >= '2022-10-31 19:00:00' and DumpTime <='2022-11-30 19:00:00'
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
	  WHERE DumpEndTime >= '2022-10-31 19:00:00' and DumpEndTime <= '2022-11-30 19:00:00'
	  and TM.StateId = 3 and TMAP.StateId = 1
) t
--and LoadLocation ='Штабель 3'
--and Mass != MassCycleTotal
GROUP BY t.LoadLocation, t.DumpLocation, t.Material, t.Licence, t.LoadEquip
ORDER BY t.LoadLocation, t.DumpLocation, t.Material, t.Licence, t.LoadEquip



МЕС:
SET TIME ZONE 'Asia/Irkutsk';
--EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON)
WITH TM(dt) as (VALUES(DATE_TRUNC('DAY', ('2022-11-30'::DATE)::TIMESTAMP)))
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
	mm.fullname as Материал,mn.fullname as МатериалКомпонента, mq.Fullname as Компонент,
 
	

	/* Парсинг Json для компонентов */
	Coalesce((((SELECT Value FROM jsonb_array_elements(am.Amount::jsonb->'Attributes') WHERE jsonb_extract_path_text(Value, 'Id')='Value')->'Value'->>'Value')::float),0) as МассаТвердого,
Coalesce((((SELECT Value FROM jsonb_array_elements(am.Extraamount::jsonb->'Attributes') 			WHERE jsonb_extract_path_text(Value, 'Id')='Value')->'Value'->>'Value')::float), 0) as ЖидМасса,
Coalesce((((SELECT Value FROM json_array_elements(
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
				WHERE (t2.Value->>'Id')='Amount')->'Value'->'Attributes') as t3  			WHERE (t3.Value ->>'Id')='Value')->'Value'->>'Value')::float), 0) as КолВоВКомпоненте

												/*Соединение Таблиц*/

from accchannels_channel ac
	join accmovements_movement am on ac.elementid=am.channel
 	left join public.pamovements_mixedpolygonentity PMP ON PMP.elementid = AM.elementid --Транспортировка

 join accchannels_nodebase anode2 on anode2.elementid=pmp.transportationmovement_movementfrom 
  join accchannels_nodebase anode3 on anode3.elementid=pmp.transportationmovement_movementto
  inner join public.accmovements_nodeinstance ANI_Source ON ANI_Source.elementid = AM.source
  inner join public.accmovements_nodeinstance ANI_Dest ON ANI_Dest.elementid = AM.destination
 join paminingpolygon_miningpolygoncollection T_Licenz                              
  ON T_Licenz.elementid = PMP.licencemix::json->'Elements'-> 0 -> 'Attributes'-> 0 ->'Value'->'Attributes'-> 0 ->'Value' ->>'Value'
 join pageology_outline pgo on pgo.elementid=pmp.outline 
 join pageology_block pgb on pgo.block=pgb.elementid
 join mvmaterials_materialint mvint on mvint.elementid=pgo.integrationmaterial
  --join pageology_level pgl on pgl.elementid=pgb.level
	join material_material mm on mm.elementid = am.material
	cross JOIN LATERAL json_array_elements(am.Components::json->'Elements') as ct
	left join material_material mn ON mn.elementid = 
(SELECT Value 
	FROM json_array_elements(
(SELECT Value FROM json_array_elements(ct.Value->'Attributes') as t1 WHERE (t1.Value->>'Id')='Material')->'Value'->'Attributes') as t2
			WHERE (t2.Value->>'Id')='ElementId')->'Value'->>'Value' 
left join material_material mq ON mq.elementid = 
(Select Value from json_array_elements(
(SELECT Value FROM json_array_elements(
(SELECT Value FROM json_array_elements(ct.Value->'Attributes') as t1 				WHERE (t1.Value->>'id')='Components')->'Value'->'Elements' ->1->'Attributes') as t2
				WHERE (t2.Value->>'id')='Material')->'Value'->'Attributes') as t3  			WHERE (t3.Value ->>'id')='ElementId')->'Value'->>'Value'

												/*Условия и ограничения*/

where  am.modelreference = 'o:site/app/RcAppProAcc/AccountingModelDetail'
and  (am.endtime > date_trunc('Month',(SELECT dt FROM TM))-interval '5 hour' and am.endtime <= (select dt from tm)::timestamp + interval '19 hour'	)											/*Выбор необходимых хранилищ*/
and
ac.elementcode in ( 
	'Взорванная горная масса (субконтура) --> Экскавация'    
     ) --Массив каналов

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
	mm.fullname as Материал,mn.fullname as МатериалКомпонента, mq.Fullname as Компонент,
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
	Coalesce((((SELECT Value FROM jsonb_array_elements(am.Amount::jsonb->'Attributes') WHERE jsonb_extract_path_text(Value, 'Id')='Value')->'Value'->>'Value')::float),0) as МассаТвердого,
Coalesce((((SELECT Value FROM jsonb_array_elements(am.Extraamount::jsonb->'Attributes') 			WHERE jsonb_extract_path_text(Value, 'Id')='Value')->'Value'->>'Value')::float), 0) as ЖидМасса,
Coalesce((((SELECT Value FROM json_array_elements(
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
				WHERE (t2.Value->>'Id')='Amount')->'Value'->'Attributes') as t3  			WHERE (t3.Value ->>'Id')='Value')->'Value'->>'Value')::float), 0) as КолВоВКомпоненте

												/*Соединение Таблиц*/

from accchannels_channel ac
	join accmovements_movement am on ac.elementid=am.channel
 	left join public.pamovements_mixedpolygonentity PMP ON PMP.elementid = AM.elementid --Транспортировка

 join accchannels_nodebase anode2 on anode2.elementid=pmp.transportationmovement_movementfrom 
  join accchannels_nodebase anode3 on anode3.elementid=pmp.transportationmovement_movementto
  inner join public.accmovements_nodeinstance ANI_Source ON ANI_Source.elementid = AM.source
  inner join public.accmovements_nodeinstance ANI_Dest ON ANI_Dest.elementid = AM.destination
 join paminingpolygon_miningpolygoncollection T_Licenz                              
  ON T_Licenz.elementid = PMP.licencemix::json->'Elements'-> 0 -> 'Attributes'-> 0 ->'Value'->'Attributes'-> 0 ->'Value' ->>'Value'
 join pageology_outline pgo on pgo.elementid=pmp.outline 
 join pageology_block pgb on pgo.block=pgb.elementid
 join mvmaterials_materialint mvint on mvint.elementid=pgo.integrationmaterial
  --join pageology_level pgl on pgl.elementid=pgb.level
	join material_material mm on mm.elementid = am.material
	cross JOIN LATERAL json_array_elements(am.Components::json->'Elements') as ct
	left join material_material mn ON mn.elementid = 
(SELECT Value 
	FROM json_array_elements(
(SELECT Value FROM json_array_elements(ct.Value->'Attributes') as t1 WHERE (t1.Value->>'Id')='Material')->'Value'->'Attributes') as t2
			WHERE (t2.Value->>'Id')='ElementId')->'Value'->>'Value' 
left join material_material mq ON mq.elementid = 
(Select Value from json_array_elements(
(SELECT Value FROM json_array_elements(
(SELECT Value FROM json_array_elements(ct.Value->'Attributes') as t1 				WHERE (t1.Value->>'id')='Components')->'Value'->'Elements' ->1->'Attributes') as t2
				WHERE (t2.Value->>'id')='Material')->'Value'->'Attributes') as t3  			WHERE (t3.Value ->>'id')='ElementId')->'Value'->>'Value'

												/*Условия и ограничения*/

where  am.modelreference = 'o:site/app/RcAppProAcc/AccountingModelDetail'
and  (am.endtime > date_trunc('Month',(SELECT dt FROM TM))-interval '5 hour' and am.endtime <= (select dt from tm)::timestamp + interval '19 hour'	)											/*Выбор необходимых хранилищ*/
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
	Coalesce((((SELECT Value FROM jsonb_array_elements(am.Amount::jsonb->'Attributes') WHERE jsonb_extract_path_text(Value, 'Id')='Value')->'Value'->>'Value')::float),0) as МассаТвердого,
Coalesce((((SELECT Value FROM jsonb_array_elements(am.Extraamount::jsonb->'Attributes') 			WHERE jsonb_extract_path_text(Value, 'Id')='Value')->'Value'->>'Value')::float), 0) as ЖидМасса,
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
 	left join public.pamovements_mixedpolygonentity PMP ON PMP.elementid = AM.elementid --Транспортировка

 join accchannels_nodebase anode2 on anode2.elementid=pmp.transportationmovement_movementfrom 
  join accchannels_nodebase anode3 on anode3.elementid=pmp.transportationmovement_movementto
  inner join public.accmovements_nodeinstance ANI_Source ON ANI_Source.elementid = AM.source
  inner join public.accmovements_nodeinstance ANI_Dest ON ANI_Dest.elementid = AM.destination
 join paminingpolygon_miningpolygoncollection T_Licenz                              
  ON T_Licenz.elementid = PMP.licencemix::json->'Elements'-> 0 -> 'Attributes'-> 0 ->'Value'->'Attributes'-> 0 ->'Value' ->>'Value'
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
and  (am.endtime > date_trunc('Month',(SELECT dt FROM TM))-interval '5 hour' and am.endtime <= (select dt from tm)::timestamp + interval '19 hour'	)											/*Выбор необходимых хранилищ*/
and
ac.elementcode in ( 
	      'Взорванная горная масса (Кадаликанское) --> Экскавация (Кадаликанское)', 
      'Взорванная горная масса (В. Кадаликанское) --> Экскавация (В. Кадаликанское)'
     
     )

)  as q 
group by 1,2,3,4,5
order by 1,2,3,4,5



11.
select pgdb.number, bh.number, bh.elementid, accm.starttime, accm.endtime--, accm.amount
from dbo_borehole bh 
join dbomovements_producedrilledborehole pdb on pdb.borehole = bh.elementid
join public.accmovements_movement accm on accm.elementid = pdb.elementid
join pageology_drillblock pgdb on pgdb.elementid = bh.DrillBlock 
where accm.endtime >= '2022-10-31 19:00:00 +08' and accm.endtime <= '2022-11-30 19:00:00 +08'
and bh.elementid not in (Select distinct bh.elementid
from dbo_blastproject bp
join dbo_toblastborehole tb on bp.elementid = tb.project
join dbo_borehole bh on bh.elementid = tb.borehole
join dbomovements_producedrilledborehole pdb on pdb.borehole = bh.elementid and pdb.modelreference = 'o:site/app/RcAppProAcc/AccountingModelDetail'
join accmovements_movement accm on accm.elementid = pdb.elementid and accm.modelreference = 'o:site/app/RcAppProAcc/AccountingModelDetail'
where accm.endtime >= '2022-10-31 19:00:00 +08' and accm.endtime <= '2022-11-30 19:00:00 +08')
order by pgdb.number, bh.number





--------------------

Select bp.elementId,pit."name", bh.elementid as boreholeId, bh.number, ni.elementid as NiElementId
, (((SELECT Value
             FROM jsonb_array_elements(ni.store_amount::jsonb -> 'Attributes')
             WHERE jsonb_extract_path_text(Value, 'Id') = 'Value') -> 'Value' ->> 'Value')::float) as store_amount
, (((SELECT Value
             FROM jsonb_array_elements(ni.store_extraamount::jsonb -> 'Attributes')
             WHERE jsonb_extract_path_text(Value, 'Id') = 'Value') -> 'Value' ->> 'Value')::float) as store_extraamount
,ni.starttime, ni.endtime
--, bhs.*
from dbo_blastproject bp
join dbo_toblastborehole tb on bp.elementid = tb.project
join dbo_borehole bh on bh.elementid = tb.borehole
join public.dbomovements_boreholestore bhs on bhs.borehole = bh.elementid 
and bhs.modelreference = 'o:site/app/RcAppProAcc/AccountingModelDetail' 
and bhs.templatereference = 's:PolyusMesPa/Domains/DboMovements/ChargedBorehole'
join public.accmovements_nodeinstance ni on ni.elementid = bhs.elementid
join accchannels_nodebase accnode on  accnode.elementid=ni.node
left join pageology_pit pit on pit.elementid=bp.pit
where bp.block in 
(select elementid from pageology_blastblock 
where elementid='dd4d71d925024bfc84a67141e569f0ca'
--number in ('700-7') 
and elementcode like 'Вер%') 
and ni.starttime >= '2022-11-26 07:00:00 +08' and ni.endtime <= '2022-12-26 19:00:00 +08' 
--bh.elementid = '51e3002a162b4d4fae885e01cbf66145'
order by bh.number

--5d8cf7bd9e614c39a53f70773d683c2e


всталяем bp.elementID в запрос:

select * from dbo_blastproject  where elementid = 'a4ad6a4a59884e30a90cae5247c83ab2'

select * from dbo_toblastborehole 
where project = '9418c3675ac948b2893cb0ccb0d76be1'

делаем апдейт всех скважин по проекту в статус isapproved = true:

update dbo_toblastborehole set isapproved = true where project = 'bdc0c6c91c144b48a4e3f6fa74314525' and isapproved = false

-----------------------------------
select * from dbo_blastproject  where elementid = '270e0daef73a4d4da8e40c18ee38b6d2'



SELECT acc.batchid , acch.elementcode,acc.elementid
FROM public.accmovements_movement acc
left join public.accchannels_channel acch on acc.channel=acch.elementid

where batchid='5d8cf7bd9e614c39a53f70773d683c2e'


--------------------------------------
не включенные пробуренные скважины в проекта МВ. 
------------------------------------------
select pgdb.ElementCode, pgdb.number, bh.isdefective, bh.number, bh.elementid, accm.starttime, accm.endtime, accm.Sourcecreation--, accm.amount
from dbo_borehole bh 
join dbomovements_producedrilledborehole pdb on pdb.borehole = bh.elementid
join public.accmovements_movement accm on accm.elementid = pdb.elementid
join pageology_drillblock pgdb on pgdb.elementid = bh.DrillBlock 
where accm.endtime > '2023-01-31 19:00:00 +08' and accm.endtime <= '2023-02-28 19:00:00 +08'
and bh.elementid not in (Select distinct bh.elementid
from dbo_blastproject bp
join dbo_toblastborehole tb on bp.elementid = tb.project
join dbo_borehole bh on bh.elementid = tb.borehole
join dbomovements_producedrilledborehole pdb on pdb.borehole = bh.elementid and pdb.modelreference = 'o:site/app/RcAppProAcc/AccountingModelDetail'
join accmovements_movement accm on accm.elementid = pdb.elementid and accm.modelreference = 'o:site/app/RcAppProAcc/AccountingModelDetail'
where accm.endtime > '2023-01-31 19:00:00 +08' and accm.endtime <= '2023-02-28 19:00:00 +08'
            )
and bh.isdefective = false
--and pgdb.ElementCode like '%992-%'
order by accm.starttime, pgdb.number, bh.number


4.
-----проверить расширения бвр на запас
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
--Новый запрос
/*Declare @timeOffsetBack as int, @timeOffsetDir as int, @timeMark as datetime;
set @timeOffsetBack = '60'
set @timeOffsetDir = '360'
set @timeMark ='2022-04-05 15:00:00'*/

DECLARE @dateStart as datetime, @dateEnd as datetime, @offset as int;
/*
SET @offset = (select top 1 Offset from [asugtk].TimezoneAdjustment);
SET @dateStart = DATEADD(MINUTE, -@timeOffsetBack, @timeMark);
SET @dateEnd = DATEADD(MINUTE, @timeOffsetDir, @dateStart);*/


SET @dateStart = '2023-09-26 19:00:00';
SET @dateEnd = '2023-10-05 19:00:00';

select
	cast (T.WencoId as NVARCHAR (40)) as WencoId,
	T.DrillBlockNumber, 
	--T.HoleId as HoleId_t,
	case
		when T.HoleIdCount=1 then '00' + T.HoleId
		when T.HoleIdCount=2 then '0' + T.HoleId
		when T.HoleIdCount<2 then '00' + T.HoleId
		else HoleId
		end as HoleId,
		DATALENGTH(SUBSTRING(T.HoleId, 1, LEN(T.HoleId)))  as HoleIdCount, 
	--HoleIdCount,
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
	max(DateTimeChange) as DateTimeChange,
	--null as DateTimeChange,
    DateTimeDelete,	 
	--T.DrillHoleType,
	T.DrillHoleType as DrillHoleType
	--cast(IIF(T.HoleId like '%П%',3, T.DrillHoleType) as int) AS DrillHoleType
	--,T.HAS_MANUAL_DEPTH
	
	
from (
select distinct
	N'DH/'+CAST(DT2.DRILL_BLAST_IDENT as NVARCHAR(30)) + '/' +  replace(replace(replace(replace(DT2.HOLE_CODE ,'/''-',''),'(',''),')',''),' ','') as WencoId
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
	,Case 
	when isnull(DT2.DateTimeDelete, '') = '' and (DT2.AS_DRILLED_DEPTH<=0 or DT2.HAS_MANUAL_DEPTH=0)
	then DT2.HOLE_DEPTH
	when isnull(DT2.DateTimeDelete, '') = '' and  (DT2.AS_DRILLED_DEPTH>0 or DT2.HAS_MANUAL_DEPTH=1)
	then DT2.AS_DRILLED_DEPTH 
	when isnull(DT2.DateTimeDelete, '') = '' and  DT2.HAS_MANUAL_DEPTH is null
	then DT2.HOLE_DEPTH
	else 0 
	end AS Depth
	,DT2.EQUIP_IDENT as EquipmentId
	,DT2.DRILL_START_TIMESTAMP as StartTimeStamp
	,DT2.END_TIMESTAMP as EndTimeStamp
	--,DH.COMMENT
	,C.PIT_NAME as LicenseName
	,max(DT2.DateTimeChange) as DateTimeChange
	,max(DT.DateTimeDelete) as DateTimeDelete
	--,2 as DrillHoleType
	--,DT2.HAS_MANUAL_DEPTH as HAS_MANUAL_DEPTH
	,(case	
		when DH.HOLE_CODE like 'П%' then '3'
		when DT2.HAS_MANUAL_DEPTH=1 then '3'
		else '2'
		end) as DrillHoleType
from asugtk.DRILL_TRANS DT
	left join asugtk.DRILL_TRANS DT2 on DT2.DRILL_BLAST_IDENT = DT.DRILL_BLAST_IDENT and DT2.HOLE_CODE=DT.HOLE_CODE  
	join asugtk.DRILL_BLAST DB on DT2.DRILL_BLAST_IDENT = DB.DRILL_BLAST_IDENT
	join asugtk.DRILL_HOLE DH on DT2.DRILL_BLAST_IDENT = DH.DRILL_BLAST_IDENT and DH.HOLE_CODE=DT2.HOLE_CODE
	join asugtk.LOCATION_BLAST_PATTERN c on DB.BLAST_LOCATION_SNAME = c.LOCATION_SNAME
	--left join dbo.asugtk2mes_journal mj DT2.DRILL_REC_IDENT = mj.operid
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
		group by DT2.DRILL_BLAST_IDENT,DT2.HOLE_CODE,DB.BLAST_LOCATION_SNAME,DH.HOLE_CODE,
		DH.DESIGN_NORTHING
	,DH.DESIGN_EASTING
	,DH.DESIGN_ELEVATION
	,DT2.HOLE_NORTHING
	,DT2.HOLE_EASTING
	,DT2.HOLE_ELEVATION
	,DH.DESIGN_TOE_NORTHING
	,DH.DESIGN_TOE_EASTING
	,DH.DESIGN_TOE_ELEVATION
	,DT2.HOLE_TOE_NORTHING
	,DT2.HOLE_TOE_EASTING
	,DT2.HOLE_TOE_ELEVATION
	,DT2.DateTimeDelete
	,DT2.HOLE_DEPTH
	,DT2.EQUIP_IDENT
	,DT2.DRILL_START_TIMESTAMP
	,DT2.END_TIMESTAMP
	,C.PIT_NAME
	,DT.DateTimeDelete
	,DT2.HAS_MANUAL_DEPTH
	,DT2.AS_DRILLED_DEPTH 
		) as T
		where T.Depth<>'0'  --and wencoid like '%DH/-1769/04%'--and T.DrillBlockNumber='972-18' and holeid like '%111'  --972-18 --and WencoId like 'DH/-1729/04%'--and holeid like '%142%'  --and T.DrillBlockNumber='850-117' --and holeid='086' 
		
group by WencoId, DrillBlockNumber, HoleId, PlannedCollarY, PlannedCollarX, PlannedCollarZ, PlannedToeY, PlannedToeX, PlannedToeZ, EquipmentId, LicenseName, DrillHoleType,T.HoleIdCount,T.HoleId,DateTimeChange,T.DateTimeDelete ---,HAS_MANUAL_DEPTH


UNION ALL

select
	cast (T.WencoId as NVARCHAR (40)) as WencoId,
	T.DrillBlockNumber, 
	--T.HoleId as HoleId,
	case
		when T.HoleIdCount=1 then '00' + T.HoleId
		when T.HoleIdCount=2 then '0' + T.HoleId
		when T.HoleIdCount<2 then '00' + T.HoleId
		else HoleId
		end as HoleId,
		DATALENGTH(SUBSTRING(T.HoleId, 1, LEN(T.HoleId)))  as HoleIdCount, 
	--HoleIdCount,
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
	--T.DrillHoleType,
	T.DrillHoleType as DrillHoleType
	--cast(IIF(T.HoleId like '%П%',3, T.DrillHoleType) as int) AS DrillHoleType
	--,null HAS_MANUAL_DEPTH
	
	
from (
select distinct
	N'DH/'+CAST(DT2.DRILL_BLAST_IDENT as NVARCHAR(30)) + '/' +  replace(replace(replace(replace(DT2.HOLE_CODE ,'/''-',''),'(',''),')',''),' ','') as WencoId
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
	,DT2.DateTimeDelete as DateTimeChange
	,DT2.DateTimeDelete as DateTimeDelete 
	--,2 as DrillHoleType
	--,null HAS_MANUAL_DEPTH
	,(case	
		when DH.HOLE_CODE like 'П%' then '3'
		when DT2.HAS_MANUAL_DEPTH=1 then '3'
		else '2'
		end) as DrillHoleType
from [asugtk].[DRILL_TRANS_DELETED_ENTRIES] DT
	left  join [asugtk].[DRILL_TRANS_DELETED_ENTRIES] DT2 on DT2.DRILL_BLAST_IDENT = DT.DRILL_BLAST_IDENT and DT2.HOLE_CODE=DT.HOLE_CODE  
	 join asugtk.DRILL_BLAST DB on DT2.DRILL_BLAST_IDENT = DB.DRILL_BLAST_IDENT
	join asugtk.DRILL_HOLE DH on DT2.DRILL_BLAST_IDENT = DH.DRILL_BLAST_IDENT and DH.HOLE_CODE=DT2.HOLE_CODE
	join asugtk.LOCATION_BLAST_PATTERN c on DB.BLAST_LOCATION_SNAME = c.LOCATION_SNAME

	 where DT2.END_TIMESTAMP is not null 
	
		) as T
		where 		
		DateTimeDelete>= @dateStart and DateTimeDelete<=@dateEnd and Depth<>'0' --and holeid='126' --and T.DrillBlockNumber='850-117' and holeid='086' and Depth<>'0' and  T.DrillBlockNumber='850-117'
		
group by WencoId, DrillBlockNumber, HoleId, PlannedCollarY, PlannedCollarX, PlannedCollarZ, PlannedToeY, PlannedToeX, PlannedToeZ, EquipmentId, LicenseName, DrillHoleType,T.HoleIdCount,T.HoleId,DateTimeChange
		
order by DateTimeDelete desc

select dr.* from asugtk.DRILL_HOLE dr
where DRILL_BLAST_IDENT='-1769' and HOLE_CODE like '04%'
order by HOLE_CODE 

select HOLE_CODE,HOLE_DEPTH,AS_DRILLED_DEPTH , dr.* from asugtk.DRILL_TRANS dr
where DRILL_BLAST_IDENT='-1769' and HOLE_CODE like '04%'
order by dr.HOLE_CODE 



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





ОГОК


Запрос для движений:



select top (1000)
--am.elementid  as am_elementid,
PDB.borehole as  PDB_borehole ,
PDB.work as  PDB_work ,
cast(sd.proday as date) as ДатаБурения,
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
 /* Case mm.ElementCode
           when 'Пробуренные скважины (1075621)' then 'Горная масса'
           When 'Скважины руды (1028255)' then 'Руда'
           When 'Скважины вскрыши (1028251)' then 'Вскрыша'
           else null
           end  as материал2,*/
					 mv.elementcode тип_скважины,
Sum(pbh.in_68f22640dd9d436fb702c292cbea89b6) as ПлановоеБурение,
/*
[in_4327758a6d04413eb3cc99f7ba675e22]
[in_e545f954c7054f0dbd5c5242961fa63d]*/
Sum(am.in_e545f954c7054f0dbd5c5242961fa63d) as Пробуренно,
Sum(am.in_e545f954c7054f0dbd5c5242961fa63d) - Sum(pbh.in_68f22640dd9d436fb702c292cbea89b6) as ОТклонениеПМ,
/*case when Coalesce(Sum((((SELECT Value
  FROM jsonb_array_elements(am.Amount::jsonb->'Attributes')
          WHERE jsonb_extract_path_text(Value, 'Id') = 'Value') -> 'Value' ->>'Value')::float)))<=0 or
Coalesce(Sum((((SELECT Value
  FROM jsonb_array_elements(pbh.Depth::jsonb -> 'Attributes')
WHERE jsonb_extract_path_text(Value, 'Id') = 'Value') -> 'Value' ->> 'Value'):: float)))<=0 then 0 else Coalesce(Sum((((SELECT Value
  FROM jsonb_array_elements(am.Amount::jsonb->'Attributes')
          WHERE jsonb_extract_path_text(Value, 'Id') = 'Value') -> 'Value' ->>'Value')::float))) /
Coalesce(Sum((((SELECT Value
  FROM jsonb_array_elements(pbh.Depth::jsonb -> 'Attributes')
    WHERE jsonb_extract_path_text(Value, 'Id') = 'Value') -> 'Value' ->> 'Value'):: float)))-1 end as ОТклонениеПР,*/
       bh.isdefective as ПризнакБрака,
       bh.issubdrill as ПризнакПеребура,
       PDB.startAt as НачалоБурения,
       PDB.endAT as КонецБурения,
	   PDB.addat as addat,
	   PDB.updateat as updateat
--count(BH.number)  as КолСкважин
from dbo_drillingwork DW
    left join erpresources_resource rr on dw.machine = rr.elementid
	left join erpequipment_technicalplace erp_t on erp_t.processsegment=rr.elementid
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
	--join  [dbo].[app_entity_in_attribute]  att on pbh.elementid=att.column_name --and att.column_name='Depth'
where (sd.proday>= '2023-03-31' and sd.proday <= '2023-04-30')  --and am.sourcecreation is null
--and erp_t.position ='1106' 
--and erp_t.position='1106' 
--and erp_t.position='1106'
--and OperSysId ilike '%115'
--and db.number='690-1' 
--and BH.number in  ('118','133', '148', '163', '119', '134' , '149', '150')
--and erp_t.position='1105' 
--and tt.elementcode='Смена №2'
--and BH.number like '%115'
--and am.elementid in ('2394561774d04e24b8e0a17da83e6d8d' , '7bc6194e105a41c2b4f875b4cc5c17a5')
/*in (
	'Д272',*/
--and  (bh.isdefective = 'true' or bh.issubdrill = 'true')
--and am.batchid='b427d474a67240a8aaf96ea93db956a4'

--PDB.startAt  between '2022-11-25'::timestamp - interval '4 hour' and '2022-11-25'::timestamp + time '19:59:59'
group by 
PDB.borehole,
PDB.borehole ,
PDB.work ,
sd.proday ,
sd.proday,
   tt.elementcode ,
  tt2.label ,
  tt4.label,
  tt3.label ,
  am.sourcecreation,
  PDB.OperSysId ,
	am.batchid ,
	bl.elementid ,
  erp_t.position ,
  db.number ,
  BH.number ,
  bh.elementid ,
  rr.Name  ,
  mm.ElementCode,
  mv.elementcode,
   bh.isdefective ,
       bh.issubdrill ,
       PDB.startAt ,
       PDB.endAT ,
	   PDB.addat ,
	   PDB.updateat 
 
 
 /*) as q
group by --ДатаБурения,
Блок,Лицензия,Очередь,Этап,Скважина,Смена,Станок,q.материал,ПризнакБрака,ПризнакПеребура,НачалоБурения,КонецБурения,date,
OperSysId,ктосоздал,q.addat,q.updateat,position,batchid,q.elementid,q.elementid,q.elementid,q.PDB_borehole,PDB_work --, q.elementcode
order by ДатаБурения,Смена,Скважина*/



------------------------------------
проверить дубли списания ВВ :

select elementid,material,amount,batchid,channel,endtime from accmovements_movement where elementid in (select elementid from dbomovements_chargingborehole where borehole = '44582b872d5e413bb46befa9ee9b1bc5' --595fb0f8fe5f480e9fba718712784784
and modelreference = 'o:site/app/RcAppProAcc/AccountingModelDetail')
order by channel, material

если надо удалить , берем elementid

и в метод асс DeleteMovements

-------------------------------------------
проверить сколько раз скважина была включена в в работу по заряжанию:

select * 
from  dbo_toblastborehole tb 
 join dbo_blastproject bp on tb.project=bp.elementid
 left join public.dbo_chargingwork ch on ch.project=tb.project
where bp.elementid = '8d99557888af4cdb8b4c592b4072cc0c'
and tb.borehole='cdfe3af0d8664b0caf4743160ec3e8c1'

select ch.elementid,chm.elementid,tb.borehole, * 
from  dbo_toblastborehole tb 
 join dbo_blastproject bp on tb.project=bp.elementid
 left join public.dbo_chargingwork ch on ch.project=tb.project
 left join  public.dbomovements_chargingborehole chm on chm.borehole=tb.borehole
where bp.elementid = '8d99557888af4cdb8b4c592b4072cc0c'
and tb.borehole='8ade42019e9644a5bc396f2237fe781e' and ch.elementid='4b8e0db61bd94814979f77609cce53a9'

('096e9152a8234db9862d9aa888563107'/*,
'4b8e0db61bd94814979f77609cce53a9'*/)

----------------------Обновленный запрос интегра для скважин 
DECLARE @dateStart as datetime, @dateEnd as datetime, @offset as int;
/*
SET @offset = (select top 1 Offset from [asugtk].TimezoneAdjustment);
SET @dateStart = DATEADD(MINUTE, -@timeOffsetBack, @timeMark);
SET @dateEnd = DATEADD(MINUTE, @timeOffsetDir, @dateStart);*/

SET @dateStart = '2023-08-10 19:00:00';
SET @dateEnd = '2023-10-11 19:00:00';

select  
CAST(WencoId as NVARCHAR(30)) + '/' +  replace(replace(replace(replace(HoleId ,'/''-',''),'(',''),')',''),' ','') as WencoId,
HoleId,
HoleIdCount,
PlannedCollarY,
PlannedCollarX, 
PlannedCollarZ, 
DrillTipCollarY, 
DrillTipCollarX, 
DrillTipCollarZ, 
	T.PlannedToeY, 
	T.PlannedToeX,  
	T.PlannedToeZ, 
DrillTipToeY, 
DrillTipToeX, 
DrillTipToeZ, 
Depth, 
EquipmentId, 
StartTimeStamp, 
EndTimeStamp, 
LicenseName, 
DateTimeChange,
	--null as DateTimeChange,
DateTimeDelete,	 
	--T.DrillHoleType,
DrillHoleType,
	--cast(IIF(T.HoleId like '%П%',3, T.DrillHoleType) as int) AS DrillHoleType
	--,T.HAS_MANUAL_DEPTH
IS_REDRILL 

from (
select
	--cast (T.WencoId as NVARCHAR (40)) as WencoId,
	
		CAST(WencoId as NVARCHAR(30)) as WencoId,
	/*case
		when T.IS_REDRILL='Y' then 'П'+ HoleId
		else HoleId
		end as HoleId,*/
	T.DrillBlockNumber, 
	--T.HoleId as HoleId_t,
	case
		when T.HoleIdCount=1 then '00' +  replace(replace(replace(replace(T.HoleId,'/''-',''),'(',''),')',''),' ','')
		when T.HoleIdCount=2 then '0' + replace(replace(replace(replace(T.HoleId,'/''-',''),'(',''),')',''),' ','')
		when T.HoleIdCount<2 then '00' + replace(replace(replace(replace(T.HoleId,'/''-',''),'(',''),')',''),' ','')
		when T.IS_REDRILL='Y' and T.HoleIdCount=3 then 'П'+ replace(replace(replace(replace(T.HoleId,'/''-',''),'(',''),')',''),' ','')
		when T.IS_REDRILL='Y' and T.HoleIdCount=4 then 'П'+ replace(replace(replace(replace(T.HoleId,'/''-',''),'(',''),')',''),' ','')
		when T.IS_REDRILL='Y' and T.HoleIdCount=5 then 'П'+ replace(replace(replace(replace(T.HoleId,'/''-',''),'(',''),')',''),' ','')
		when T.IS_REDRILL='Y' and T.HoleIdCount=6 then 'П'+ replace(replace(replace(replace(T.HoleId,'/''-',''),'(',''),')',''),' ','')
		when T.IS_REDRILL='Y' and T.HoleIdCount=7 then 'П'+ replace(replace(replace(replace(T.HoleId,'/''-',''),'(',''),')',''),' ','')
		else replace(replace(replace(replace(T.HoleId,'/''-',''),'(',''),')',''),' ','')
		end as HoleId,
	
		--replace(replace(replace(replace(DH.HOLE_CODE,'/''-',''),'(',''),')',''),' ','') as HoleId
		--CAST(WencoId2 as NVARCHAR(30)) + '/' +  replace(replace(replace(replace(t.HoleId ,'/''-',''),'(',''),')',''),' ','') as WencoId2,
		DATALENGTH(SUBSTRING(T.HoleId, 1, LEN(T.HoleId)))  as HoleIdCount, 
	--HoleIdCount,
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
	max(DateTimeChange) as DateTimeChange,
	--null as DateTimeChange,
    DateTimeDelete,	 
	--T.DrillHoleType,
	T.DrillHoleType as DrillHoleType
	--cast(IIF(T.HoleId like '%П%',3, T.DrillHoleType) as int) AS DrillHoleType
	--,T.HAS_MANUAL_DEPTH
	,T.IS_REDRILL  as IS_REDRILL 
from (
select distinct
	--N'DH/'+CAST(DT2.DRILL_BLAST_IDENT as NVARCHAR(30)) + '/' +  replace(replace(replace(replace(DT2.HOLE_CODE ,'/''-',''),'(',''),')',''),' ','') as WencoId,
	N'DH/'+CAST(DT2.DRILL_BLAST_IDENT as NVARCHAR(30)) as WencoId,
    (SELECT SUBSTRING( DB.BLAST_LOCATION_SNAME,V.number,1)
          FROM master.dbo.spt_values V
          WHERE V.type='P' AND V.number BETWEEN 1 AND LEN( DB.BLAST_LOCATION_SNAME) AND SUBSTRING(DB.BLAST_LOCATION_SNAME,V.number,1) LIKE '[0123456789-]'
        ORDER BY V.number
        FOR XML PATH('')) as DrillBlockNumber,
	DH.HOLE_CODE as HoleId,
	--,replace(replace(replace(replace(DH.HOLE_CODE,'/''-',''),'(',''),')',''),' ','') as HoleId
	DATALENGTH(SUBSTRING(replace(replace(replace(replace(DH.HOLE_CODE,'/''-',''),'(',''),')',''),' ',''), 1, LEN(DH.HOLE_CODE)))  as HoleIdCount
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
	,Case 
	when isnull(DT2.DateTimeDelete, '') = '' and  DT2.HAS_MANUAL_DEPTH=0
	then sum(DT2.HOLE_DEPTH) 
	when isnull(DT2.DateTimeDelete, '') = '' and  DT2.HAS_MANUAL_DEPTH=1
	then sum(DT2.AS_DRILLED_DEPTH) 
	when isnull(DT2.DateTimeDelete, '') = '' and  DT2.HAS_MANUAL_DEPTH is null
	then sum(DT2.HOLE_DEPTH) 
	else 0 end AS Depth
	,DT2.EQUIP_IDENT as EquipmentId
	,DT2.DRILL_START_TIMESTAMP as StartTimeStamp
	,DT2.END_TIMESTAMP as EndTimeStamp
	--,DH.COMMENT
	,C.PIT_NAME as LicenseName
	,max(DT2.DateTimeChange) as DateTimeChange
	,max(DT.DateTimeDelete) as DateTimeDelete
	--,2 as DrillHoleType
	--,DT2.HAS_MANUAL_DEPTH as HAS_MANUAL_DEPTH
	,(case	
		when DH.HOLE_CODE like 'П%' then '3'
		--when DT2.IS_REDRILL='Y' then '3'
		else '2'
		end) as DrillHoleType,
		--,null as DrillHoleType,
		DT2.IS_REDRILL as IS_REDRILL 
from asugtk.DRILL_TRANS DT
	left join asugtk.DRILL_TRANS DT2 on DT2.DRILL_BLAST_IDENT = DT.DRILL_BLAST_IDENT and DT2.HOLE_CODE=DT.HOLE_CODE  
	join asugtk.DRILL_BLAST DB on DT2.DRILL_BLAST_IDENT = DB.DRILL_BLAST_IDENT
	join asugtk.DRILL_HOLE DH on DT2.DRILL_BLAST_IDENT = DH.DRILL_BLAST_IDENT and DH.HOLE_CODE=DT2.HOLE_CODE
	join asugtk.LOCATION_BLAST_PATTERN c on DB.BLAST_LOCATION_SNAME = c.LOCATION_SNAME
	--left join dbo.asugtk2mes_journal mj DT2.DRILL_REC_IDENT = mj.operid
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
		group by DT2.DRILL_BLAST_IDENT,DT2.HOLE_CODE,DB.BLAST_LOCATION_SNAME,DH.HOLE_CODE,
		DH.DESIGN_NORTHING
	,DH.DESIGN_EASTING
	,DH.DESIGN_ELEVATION
	,DT2.HOLE_NORTHING
	,DT2.HOLE_EASTING
	,DT2.HOLE_ELEVATION
	,DH.DESIGN_TOE_NORTHING
	,DH.DESIGN_TOE_EASTING
	,DH.DESIGN_TOE_ELEVATION
	,DT2.HOLE_TOE_NORTHING
	,DT2.HOLE_TOE_EASTING
	,DT2.HOLE_TOE_ELEVATION
	,DT2.DateTimeDelete
	,DT2.HOLE_DEPTH
	,DT2.EQUIP_IDENT
	,DT2.DRILL_START_TIMESTAMP
	,DT2.END_TIMESTAMP
	,C.PIT_NAME
	,DT.DateTimeDelete
	,DT2.HAS_MANUAL_DEPTH
	,DT2.IS_REDRILL
		) as T
		where T.Depth<>'0' and T.DrillBlockNumber='972-18'  and holeid like '%098%'   --and WencoId like 'DH/-1688/%111'--and holeid like '%142%'  --and T.DrillBlockNumber='972-18' --and holeid='086' 
		
group by WencoId, DrillBlockNumber, HoleId, PlannedCollarY, PlannedCollarX, PlannedCollarZ, PlannedToeY, PlannedToeX, PlannedToeZ, EquipmentId, LicenseName, DrillHoleType,T.HoleIdCount,T.HoleId,DateTimeChange,T.DateTimeDelete,T.IS_REDRILL --WencoId2 ---,HAS_MANUAL_DEPTH

) as T
UNION ALL

select  
CAST(WencoId as NVARCHAR(30)) + '/' +  replace(replace(replace(replace(HoleId ,'/''-',''),'(',''),')',''),' ','') as WencoId,
HoleId,
HoleIdCount,
PlannedCollarY,
PlannedCollarX, 
PlannedCollarZ, 
DrillTipCollarY, 
DrillTipCollarX, 
DrillTipCollarZ, 
	T.PlannedToeY, 
	T.PlannedToeX,  
	T.PlannedToeZ, 
DrillTipToeY, 
DrillTipToeX, 
DrillTipToeZ, 
Depth, 
EquipmentId, 
StartTimeStamp, 
EndTimeStamp, 
LicenseName, 
DateTimeChange,
	--null as DateTimeChange,
DateTimeDelete,	 
	--T.DrillHoleType,
DrillHoleType,
	--cast(IIF(T.HoleId like '%П%',3, T.DrillHoleType) as int) AS DrillHoleType
	--,T.HAS_MANUAL_DEPTH
IS_REDRILL 
from (
--cast (T.WencoId as NVARCHAR (40)) as WencoId,
	select
		CAST(WencoId as NVARCHAR(30)) as WencoId,
	/*case
		when T.IS_REDRILL='Y' then 'П'+ HoleId
		else HoleId
		end as HoleId,*/
	T.DrillBlockNumber, 
	--T.HoleId as HoleId_t,
	case
		when T.HoleIdCount=1 then '00' +  replace(replace(replace(replace(T.HoleId,'/''-',''),'(',''),')',''),' ','')
		when T.HoleIdCount=2 then '0' + replace(replace(replace(replace(T.HoleId,'/''-',''),'(',''),')',''),' ','')
		when T.HoleIdCount<2 then '00' + replace(replace(replace(replace(T.HoleId,'/''-',''),'(',''),')',''),' ','')
		when T.IS_REDRILL='Y' and T.HoleIdCount=3 then 'П'+ replace(replace(replace(replace(T.HoleId,'/''-',''),'(',''),')',''),' ','')
		when T.IS_REDRILL='Y' and T.HoleIdCount=4 then 'П'+ replace(replace(replace(replace(T.HoleId,'/''-',''),'(',''),')',''),' ','')
		when T.IS_REDRILL='Y' and T.HoleIdCount=5 then 'П'+ replace(replace(replace(replace(T.HoleId,'/''-',''),'(',''),')',''),' ','')
		when T.IS_REDRILL='Y' and T.HoleIdCount=6 then 'П'+ replace(replace(replace(replace(T.HoleId,'/''-',''),'(',''),')',''),' ','')
		when T.IS_REDRILL='Y' and T.HoleIdCount=7 then 'П'+ replace(replace(replace(replace(T.HoleId,'/''-',''),'(',''),')',''),' ','')
		else replace(replace(replace(replace(T.HoleId,'/''-',''),'(',''),')',''),' ','')
		end as HoleId,
	
		--replace(replace(replace(replace(DH.HOLE_CODE,'/''-',''),'(',''),')',''),' ','') as HoleId
		--CAST(WencoId2 as NVARCHAR(30)) + '/' +  replace(replace(replace(replace(t.HoleId ,'/''-',''),'(',''),')',''),' ','') as WencoId2,
		DATALENGTH(SUBSTRING(T.HoleId, 1, LEN(T.HoleId)))  as HoleIdCount, 
	--HoleIdCount,
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
	max(DateTimeChange) as DateTimeChange,
	--null as DateTimeChange,
    DateTimeDelete,	 
	--T.DrillHoleType,
	T.DrillHoleType as DrillHoleType
	--cast(IIF(T.HoleId like '%П%',3, T.DrillHoleType) as int) AS DrillHoleType
	--,T.HAS_MANUAL_DEPTH
	,T.IS_REDRILL  as IS_REDRILL 
	
from (
select distinct
	N'DH/'+CAST(DT2.DRILL_BLAST_IDENT as NVARCHAR(30)) + '/' +  replace(replace(replace(replace(DT2.HOLE_CODE ,'/''-',''),'(',''),')',''),' ','') as WencoId
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
	,DT2.DateTimeDelete as DateTimeChange
	,DT2.DateTimeDelete as DateTimeDelete 
	--,2 as DrillHoleType
	--,null HAS_MANUAL_DEPTH
	,DT2.IS_REDRILL
	,(case	
		when DH.HOLE_CODE like 'П%' then '3'
		when DT2.IS_REDRILL='Y' then '3'
		else '2'
		end) as DrillHoleType
from [asugtk].[DRILL_TRANS_DELETED_ENTRIES] DT
	left  join [asugtk].[DRILL_TRANS_DELETED_ENTRIES] DT2 on DT2.DRILL_BLAST_IDENT = DT.DRILL_BLAST_IDENT and DT2.HOLE_CODE=DT.HOLE_CODE  
	 join asugtk.DRILL_BLAST DB on DT2.DRILL_BLAST_IDENT = DB.DRILL_BLAST_IDENT
	join asugtk.DRILL_HOLE DH on DT2.DRILL_BLAST_IDENT = DH.DRILL_BLAST_IDENT and DH.HOLE_CODE=DT2.HOLE_CODE
	join asugtk.LOCATION_BLAST_PATTERN c on DB.BLAST_LOCATION_SNAME = c.LOCATION_SNAME

	 where DT2.END_TIMESTAMP is not null 
	
		) as T
		where 		
		DateTimeDelete>= @dateStart and DateTimeDelete<=@dateEnd and Depth<>'0' --and holeid='126' --and T.DrillBlockNumber='850-117' and holeid='086' and Depth<>'0' and  T.DrillBlockNumber='850-117'
		
group by WencoId, DrillBlockNumber, HoleId, PlannedCollarY, PlannedCollarX, PlannedCollarZ, PlannedToeY, PlannedToeX, PlannedToeZ, EquipmentId, LicenseName, DrillHoleType,T.HoleIdCount,T.HoleId,DateTimeChange,T.IS_REDRILL,DateTimeDelete
	  ) as T	
order by DateTimeDelete desc

--------------------

Запас уже существует. id: fddd8d835f5e4a6eb126929349dfdb10; code: Store Карьер Вернинский/800/800-77//П084|c19ca8c50d4348f0a160f81269fab4f6; timeRange: [2023-10-09T19:00:00.0000000+08:00 - 2023-10-10T07:00:00.0000000+08:00]; previousStore: [ - ]; storage: [Пробуренные скважины - 98fd8358b52b4b118e8d3a22ea20ff5c]; storePlace: Карьер Вернинский/800/800-77//П084|8f2d00f62fa94673b687b937b61790ce|2023-10-09T19:00:00.0000000+08:00-]. Store: code: Store |738308c349b64445a9c5f49d161d59f7; timeRange: [2023-10-09T19:00:00.0000000+08:00 - ]; previousStore: [ - ]; storage: [Пробуренные скважины - 98fd8358b52b4b118e8d3a22ea20ff5c]; storePlace: Карьер Вернинский/800/800-77//П084|8f2d00f62fa94673b687b937b61790ce|2023-10-09T19:00:00.0000000+08:00-];
Ошибки операции:

10-10-2023 15:09:37.622|ERROR|DrillingWorksService|TRACKED|Code: -4720463957083221316, exception level = 0
Name: InvalidOperationException
Message: Fault operation. Ошибки валидации:
Запас уже существует. id: fddd8d835f5e4a6eb126929349dfdb10; code: Store Карьер Вернинский/800/800-77//П084|c19ca8c50d4348f0a160f81269fab4f6; timeRange: [2023-10-09T19:00:00.0000000+08:00 - 2023-10-10T07:00:00.0000000+08:00]; previousStore: [ - ]; storage: [Пробуренные скважины - 98fd8358b52b4b118e8d3a22ea20ff5c]; storePlace: Карьер Вернинский/800/800-77//П084|8f2d00f62fa94673b687b937b61790ce|2023-10-09T19:00:00.0000000+08:00-]. Store: code: Store |738308c349b64445a9c5f49d161d59f7; timeRange: [2023-10-09T19:00:00.0000000+08:00 - ]; previousStore: [ - ]; storage: [Пробуренные скважины - 98fd8358b52b4b118e8d3a22ea20ff5c]; storePlace: Карьер Вернинский/800/800-77//П084|8f2d00f62fa94673b687b937b61790ce|2023-10-09T19:00:00.0000000+08:00-];

Name: Exception
Message: Не удалось сохранить Stores.
Stack Trace:    at PolyusMesPa.Dbo.Service.Services.DrillingWorksService.AddNewStores(List`1 newStores, List`1 newStorePlaces, MethodTracker`1 tracker)
   at PolyusMesPa.Dbo.Service.Services.DrillingWorksService.IncludeBoreholesInDrillWork(IncludeExcludeBoreholeInDrillWorkDto dto, ICallContext callContext)
   
   
   select * from
	--public.accmovements_nodeinstance
	public.accmovements_storeplace
	where elementcode like '%Вернинский/800/800-75//011%'
	-- storage 98fd8358b52b4b118e8d3a22ea20ff5c
	
	----
	select * from 
	public.accmovements_storeplace
	where elementid='97124baf75a54d128f95fc4fe56cda89'
	
	select* from
	public.accmovements_nodeinstance
	where --elementid='fddd8d835f5e4a6eb126929349dfdb10'
	store_storeplace='97124baf75a54d128f95fc4fe56cda89'
   
   --batctid
   
	select * from
	public.dbomovements_boreholestore
	where borehole='1b522136d3c646a38af7c3d8eb2d738c'
	
	select * from 
	public.dbomovements_producedrilledborehole
	where borehole='1b522136d3c646a38af7c3d8eb2d738c'
	
	--далее уудаляем движение, запас и место хранения
	
	
________________________________________________________________________________________________________________
	
	Время жизни запаса не попадает в интервал времени жизни места хранения. code: 
Store |6b04daab08384d99a4c87d56b49ebd3c; timeRange: [2023-07-09T19:00:00.0000000+08:00 - ]; previousStore: [ - ]; 
storage: [Пробуренные скважины (В. Кадаликанское) - 2553191e76e14870a850d0fa3ec424ff]; storePlace: [В. Кадаликанский/982/982-35//075 - 44df4ef678b248bc83eda3f43e73ef6c]. 

получем data по:

select * from 
	public.accmovements_storeplace
	where elementid='b936333d76c74fc5a8dd7cfd2ecc4e39'

{{gatewayUrl}}/rc-mag-int-restgateway/sys/CallUi?applicationId=RestGateway&callableReference=o:RcAppProAcc/UiManager[GetStorePlaceByElementId]

{
    "ModelReference": "o:site/app/RcAppProAcc/AccountingModelDetail",
    "Id": "b936333d76c74fc5a8dd7cfd2ecc4e39"  -- места хранения
}


апдейтим, копируем data ( скрывает пункт для копируем скобки {} и выставляем нужно время местахранения:

{{gatewayUrl}}/rc-mag-int-restgateway/sys/CallUi?applicationId=RestGateway&callableReference=o:RcAppProAcc/UiManager[UpdateStorePlace]



Line 128: Message: Не удалось добавить скважины в работу по бурению с ошибкой Fault operation. Время жизни запаса не попадает в интервал времени жизни места хранения. code: Store Карьер Вернинский/670/670-8//031|e749463b02e444739339786f1b99220d; timeRange: [2023-10-28T07:00:00.0000000+08:00 - ]; previousStore: [ - ]; storage: [Пробуренные скважины - 98fd8358b52b4b118e8d3a22ea20ff5c]; storePlace: Карьер Вернинский/670/670-8//031|ff181916c2dc44d18fbba86dcf8c2753|2023-10-29T19:00:00.0000000+08:00-]
	Line 143: Message: Не удалось добавить скважины в работу по бурению с ошибкой Fault operation. Время жизни запаса не попадает в интервал времени жизни места хранения. code: Store Карьер Вернинский/670/670-8//036|04cd2efadae84c8bb58aa22237c6422f; timeRange: [2023-10-28T19:00:00.0000000+08:00 - ]; previousStore: [ - ]; storage: [Пробуренные скважины - 98fd8358b52b4b118e8d3a22ea20ff5c]; storePlace: Карьер Вернинский/670/670-8//036|9de42937559545ff9f3d1d07b6620efa|2023-10-30T07:00:00.0000000+08:00-]
	Line 158: Message: Не удалось добавить скважины в работу по бурению с ошибкой Fault operation. Время жизни запаса не попадает в интервал времени жизни места хранения. code: Store Карьер Вернинский/670/670-8//037|65b7c2d943b54a1795f0b006574d461e; timeRange: [2023-10-28T19:00:00.0000000+08:00 - ]; previousStore: [ - ]; storage: [Пробуренные скважины - 98fd8358b52b4b118e8d3a22ea20ff5c]; storePlace: Карьер Вернинский/670/670-8//037|7f0cc7dd358743bbbe90868ef4df6598|2023-10-30T07:00:00.0000000+08:00-]
	Line 369: Message: Не удалось добавить скважины в работу по бурению с ошибкой Fault operation. Время жизни запаса не попадает в интервал времени жизни места хранения. code: Store Карьер Вернинский/670/670-8//031|ea961769848c4083903981bff336e329; timeRange: [2023-10-28T07:00:00.0000000+08:00 - ]; previousStore: [ - ]; storage: [Пробуренные скважины - 98fd8358b52b4b118e8d3a22ea20ff5c]; storePlace: Карьер Вернинский/670/670-8//031|ff181916c2dc44d18fbba86dcf8c2753|2023-10-29T19:00:00.0000000+08:00-]
	Line 384: Message: Не удалось добавить скважины в работу по бурению с ошибкой Fault operation. Время жизни запаса не попадает в интервал времени жизни места хранения. code: Store Карьер Вернинский/670/670-8//032|80d03da387364b1eb33c9df5993c17f6; timeRange: [2023-10-28T19:00:00.0000000+08:00 - ]; previousStore: [ - ]; storage: [Пробуренные скважины - 98fd8358b52b4b118e8d3a22ea20ff5c]; storePlace: Карьер Вернинский/670/670-8//032|f16d27fd84dd4c3987cbd1e7da2197eb|2023-10-30T07:00:00.0000000+08:00-]
	Line 399: Message: Не удалось добавить скважины в работу по бурению с ошибкой Fault operation. Время жизни запаса не попадает в интервал времени жизни места хранения. code: Store Карьер Вернинский/670/670-8//033|127fa8b964ab4d9ea8b952ae955e1017; timeRange: [2023-10-28T19:00:00.0000000+08:00 - ]; previousStore: [ - ]; storage: [Пробуренные скважины - 98fd8358b52b4b118e8d3a22ea20ff5c]; storePlace: Карьер Вернинский/670/670-8//033|207cb11e6aea4afe9ee6ca3cd5b6f36a|2023-10-30T07:00:00.0000000+08:00-]
	Line 573: Message: Не удалось добавить скважины в работу по бурению с ошибкой Fault operation. Время жизни запаса не попадает в интервал времени жизни места хранения. code: Store Карьер Вернинский/670/670-8//038|ab869499ef9447b5b74ac23d7153a9e0; timeRange: [2023-10-28T19:00:00.0000000+08:00 - ]; previousStore: [ - ]; storage: [Пробуренные скважины - 98fd8358b52b4b118e8d3a22ea20ff5c]; storePlace: Карьер Вернинский/670/670-8//038|3ef033c67d1546ddaaf06bdd3b60014b|2023-10-29T19:00:00.0000000+08:00-]
	Line 588: Message: Не удалось добавить скважины в работу по бурению с ошибкой Fault operation. Время жизни запаса не попадает в интервал времени жизни места хранения. code: Store Карьер Вернинский/670/670-8//039|3a592216847c41d5b6220afef691c750; timeRange: [2023-10-28T19:00:00.0000000+08:00 - ]; previousStore: [ - ]; storage: [Пробуренные скважины - 98fd8358b52b4b118e8d3a22ea20ff5c]; storePlace: Карьер Вернинский/670/670-8//039|bb51c46645254e878fba657495dcb456|2023-10-29T19:00:00.0000000+08:00-]
	Line 603: Message: Не удалось добавить скважины в работу по бурению с ошибкой Fault operation. Время жизни запаса не попадает в интервал времени жизни места хранения. code: Store Карьер Вернинский/670/670-8//016|03575af317904292826617ccd952a1d1; timeRange: [2023-10-28T19:00:00.0000000+08:00 - ]; previousStore: [ - ]; storage: [Пробуренные скважины - 98fd8358b52b4b118e8d3a22ea20ff5c]; storePlace: Карьер Вернинский/670/670-8//016|c6cd786ed2f6453fa18d13774ac330ed|2023-10-30T07:00:00.0000000+08:00-]

Время жизни запаса не попадает в интервал времени жизни места хранения. code: Store |bcfa45893ca941c2b21ad1068dca4bd5; timeRange: [2023-10-26T19:00:00.0000000+08:00 - ]; previousStore: [ - ]; storage: [Пробуренные скважины - 98fd8358b52b4b118e8d3a22ea20ff5c]; storePlace: Карьер Вернинский/800/800-84//034|f086e52938744189b05d948e6896ae9e|2023-10-30T07:00:00.0000000+08:00-]. Store: code: Store |bcfa45893ca941c2b21ad1068dca4bd5; timeRange: [2023-10-26T19:00:00.0000000+08:00 - ]; previousStore: [ - ]; storage: [Пробуренные скважины - 98fd8358b52b4b118e8d3a22ea20ff5c]; storePlace: Карьер Вернинский/800/800-84//034|f086e52938744189b05d948e6896ae9e|2023-10-30T07:00:00.0000000+08:00-]
Время жизни запаса не попадает в интервал времени жизни места хранения. code: Store |8f8cf7f2ca974d9eae9630b4e04aa107; timeRange: [2023-10-26T19:00:00.0000000+08:00 - ]; previousStore: [ - ]; storage: [Пробуренные скважины - 98fd8358b52b4b118e8d3a22ea20ff5c]; storePlace: Карьер Вернинский/800/800-84//153|8e44b145553a4b53860fc478a549614b|2023-10-27T07:00:00.0000000+08:00-]. Store: code: Store |8f8cf7f2ca974d9eae9630b4e04aa107; timeRange: [2023-10-26T19:00:00.0000000+08:00 - ]; previousStore: [ - ]; storage: [Пробуренные скважины - 98fd8358b52b4b118e8d3a22ea20ff5c]; storePlace: Карьер Вернинский/800/800-84//153|8e44b145553a4b53860fc478a549614b|2023-10-27T07:00:00.0000000+08:00-];









----------------------------------1
1. ПОИСК каналов и запасов по  для обновления материалов
2. Поменять в конфиге материалы


----------------------------------
1. ПОИСК каналов и запасов по  для обновления материалов
2. Поменять в конфиге материалы

/*
select acc.elementid,acc.channel,acc.material,acc.starttime, mm.elementcode
		from
		public.accmovements_movement acc
		join public.material_material mm on acc.material=mm.elementid
		where acc.channel='0ed1a637be584a39ad7ccd2821dca607' and  acc.modelreference='o:site/app/RcAppProAcc/AccountingModelDetail' 
		and acc.starttime>='2023-09-30 19:00:00+07'
		
		*/
		
		select elementid,elementcode,  * from
	public.accchannels_channel
	where elementcode in (
		/*'Бурение (Константиновское) --> Пробуренные скважины (Константиновское)', --0ed1a637be584a39ad7ccd2821dca607
		'Пробуренные скважины (Константиновское) --> Заряжание (Константиновское)',  --
		'Пробуренные скважины (Константиновское) --> Взрывание (Константиновское)'*/
		'Заряжание (Константиновское) --> Заряженные скважины (Константиновское)',
		'Заряженные скважины (Константиновское) --> Взрывание (Константиновское)'
		/*'Взрывание (Константиновское) --> Взорванная горная масса (Константиновское)',
		'Взорванная горная масса (Константиновское) --> Экскавация (Константиновское)'*/
		) 
		and  modelreference='o:site/app/RcAppProMdm/AccountingChannelsModelDetail'
		
		select * from 
		public.material_material
		where elementcode in (
		'Взрывные скважины ВСДП (1078066)', --2f7d1dd2cfb746cbacc79a5c2be1b71d заменить на 65e0f7e0076e47c88f2219a7884c0525
		'Заряженная горная масса ВСДП (1078067)', --3831bf15569a4d0d9895b1e0dc360a4b заменить на a0089af385e94cf6a8c625b7e586fb2d
		'Взорванная горная масса ВСДП (1028333)', --6f68acb8cb9646eea05748647c00bdc0 заменить на c778d84cd67c4ec9aee4d95f0e78471c
			'Взрывные скважины ВСДП гранит (000001)', --65e0f7e0076e47c88f2219a7884c0525
			'Заряженная горная масса ВСДП гранит (000002)', --a0089af385e94cf6a8c625b7e586fb2d
			'Взорванная горная масса ВСДП гранит (000003)'  --c778d84cd67c4ec9aee4d95f0e78471c

		)
/*
"2f7d1dd2cfb746cbacc79a5c2be1b71d"
"3831bf15569a4d0d9895b1e0dc360a4b"
"6f68acb8cb9646eea05748647c00bdc0"
*/

-----START
--поиск материалов 'Взрывные скважины ВСДП (1078066)', --2f7d1dd2cfb746cbacc79a5c2be1b71d заменить на 65e0f7e0076e47c88f2219a7884c0525
select acc.elementid,acc.channel,acc.starttime,acc.material,acc.source,acc.destination
from 	
public.accmovements_movement acc
	WHERE acc.channel in (
	'e91893bb444e44dbad3962b0c92d40ce',
	'56072cda62aa460a88e3e15704d3a5e0',
	'0ed1a637be584a39ad7ccd2821dca607')
	and 
	acc.material='65e0f7e0076e47c88f2219a7884c0525' and acc.starttime>='2023-09-30 19:00:00+03'   and acc.modelreference ='o:site/app/RcAppProAcc/AccountingModelDetail'

--АПДЕЙТ материалов 'Взрывные скважины ВСДП (1078066)', --2f7d1dd2cfb746cbacc79a5c2be1b71d заменить на 65e0f7e0076e47c88f2219a7884c0525
	/*
	update public.accmovements_movement
	set material = '65e0f7e0076e47c88f2219a7884c0525'
	where elementid in (
	select acc.elementid
	from 	
	public.accmovements_movement acc
		WHERE acc.channel in (
		'e91893bb444e44dbad3962b0c92d40ce',
		'56072cda62aa460a88e3e15704d3a5e0',
		'0ed1a637be584a39ad7ccd2821dca607')
		and 
		acc.material='2f7d1dd2cfb746cbacc79a5c2be1b71d' and acc.starttime>='2023-09-30 19:00:00+03'   and acc.modelreference ='o:site/app/RcAppProAcc/AccountingModelDetail'
	)
	*/

--поиск материалов 'Заряженная горная масса ВСДП (1078067)', --3831bf15569a4d0d9895b1e0dc360a4b заменить на a0089af385e94cf6a8c625b7e586fb2d
select acc.elementid,acc.channel,acc.starttime,acc.material,acc.source,acc.destination
from 	
public.accmovements_movement acc
	WHERE acc.channel in (
	'322d8d9b5adb4d1985d4d374f46465c2', --Заряжание (Константиновское) --> Заряженные скважины (Константиновское)
	'0daa447abad640bba14e10f0cb459c30' --Заряженные скважины (Константиновское) --> Взрывание (Константиновское)
	)
	and acc.material='3831bf15569a4d0d9895b1e0dc360a4b' 
	and acc.starttime>='2023-09-30 19:00:00+03'   and acc.modelreference ='o:site/app/RcAppProAcc/AccountingModelDetail'

--АПДЕЙТ материалов 'Заряженная горная масса ВСДП (1078067)', --3831bf15569a4d0d9895b1e0dc360a4b заменить на a0089af385e94cf6a8c625b7e586fb2d
	/*
	update public.accmovements_movement
	set material = 'a0089af385e94cf6a8c625b7e586fb2d'
	where elementid in (
	select acc.elementid
from 	
public.accmovements_movement acc
	WHERE acc.channel in (
	'322d8d9b5adb4d1985d4d374f46465c2', --Заряжание (Константиновское) --> Заряженные скважины (Константиновское)
	'0daa447abad640bba14e10f0cb459c30' --Заряженные скважины (Константиновское) --> Взрывание (Константиновское)
	)
	and acc.material='3831bf15569a4d0d9895b1e0dc360a4b' and acc.starttime>='2023-09-30 19:00:00+03'   and acc.modelreference ='o:site/app/RcAppProAcc/AccountingModelDetail'
	)
	*/

--поиск материалов 'Взорванная горная масса ВСДП (1028333)', --6f68acb8cb9646eea05748647c00bdc0 заменить на c778d84cd67c4ec9aee4d95f0e78471c
select acc.elementid,acc.channel,acc.starttime,acc.material,acc.source,acc.destination
from 	
public.accmovements_movement acc
	WHERE acc.channel in (
	'a4814439f32c4ac4aab004aa4bcf84e5',  --Взорванная горная масса (Константиновское) --> Экскавация (Константиновское)
	'4dae25e08dc743d1929793ead370cd9e'  -- Взрывание (Константиновское) --> Взорванная горная масса (Константиновское)
	)
	and 
	acc.material='c778d84cd67c4ec9aee4d95f0e78471c' and acc.starttime>='2023-09-30 19:00:00+03'   and acc.modelreference ='o:site/app/RcAppProAcc/AccountingModelDetail'
	
	--АПДЕЙТ материалов 'Заряженная горная масса ВСДП (1078067)', --3831bf15569a4d0d9895b1e0dc360a4b заменить на a0089af385e94cf6a8c625b7e586fb2d
	/*
	update public.accmovements_movement
	set material = 'c778d84cd67c4ec9aee4d95f0e78471c'
	where elementid in (
	select acc.elementid
from 	
public.accmovements_movement acc
	WHERE acc.channel in (
	'a4814439f32c4ac4aab004aa4bcf84e5',  --Взорванная горная масса (Константиновское) --> Экскавация (Константиновское)
	'4dae25e08dc743d1929793ead370cd9e'  -- Взрывание (Константиновское) --> Взорванная горная масса (Константиновское)
	)
	and 
	acc.material='6f68acb8cb9646eea05748647c00bdc0' and acc.starttime>='2023-09-30 19:00:00+03'   and acc.modelreference ='o:site/app/RcAppProAcc/AccountingModelDetail'
	)
	*/
	
	
	
	--получаем места хранения 
	select * from 
	public.accchannels_nodebase
	where elementcode  in (
		'Пробуренные скважины (Константиновское)' ,  -- Взрывные скважины ВСДП гранит (000001)
	    'Заряженные скважины (Константиновское)',    -- Заряженная горная масса ВСДП гранит (000002)
		'Взорванная горная масса (Константиновское)') -- Взорванная горная масса ВСДП гранит (000003)
	and modelreference='o:site/app/RcAppProMdm/AccountingChannelsModelDetail'
	
   --получаем запасы по месту хранения для апдейта материала
   --2f7d1dd2cfb746cbacc79a5c2be1b71d	Взрывные скважины ВСДП (1078066)  - Взрывные скважины ВСДП гранит (000001)
   --3831bf15569a4d0d9895b1e0dc360a4b	Заряженная горная масса ВСДП (1078067)
   --6f68acb8cb9646eea05748647c00bdc0	Взорванная горная масса ВСДП (1028333)

--'Взрывные скважины ВСДП (1078066)', --2f7d1dd2cfb746cbacc79a5c2be1b71d заменить на 65e0f7e0076e47c88f2219a7884c0525
	  select store_material, * 
	  from   --store_material
	  public.accmovements_nodeinstance
	  where store_material='2f7d1dd2cfb746cbacc79a5c2be1b71d'  
	  and node in (
	    'cac1db61b165405b85523c4221882e24', --Заряженные скважины (Константиновское) -- Заряженная горная масса ВСДП гранит (000002)
		'fc7277a1fc2447cba6662e933a114264', --Пробуренные скважины (Константиновское) -- Взрывные скважины ВСДП гранит (000001)
		'236586f829204894bfa49560610fc152' --Взорванная горная масса (Константиновское) -- Взорванная горная масса ВСДП гранит (000003)
		  )
	and starttime>='2023-09-30 19:00:00+08' and modelreference='o:site/app/RcAppProAcc/AccountingModelDetail'
	/*--апдейт материала на запасах
	update public.accmovements_nodeinstance
	set store_material='65e0f7e0076e47c88f2219a7884c0525'
	where elementid in (select elementid 
	  from   --store_material
	  public.accmovements_nodeinstance
	  where store_material='2f7d1dd2cfb746cbacc79a5c2be1b71d'  
	  and node in (
	    'cac1db61b165405b85523c4221882e24', --Заряженные скважины (Константиновское)
		'fc7277a1fc2447cba6662e933a114264', --Пробуренные скважины (Константиновское)
		'236586f829204894bfa49560610fc152' --Взорванная горная масса (Константиновское)
		  )
	and starttime>='2023-09-30 19:00:00+08') and modelreference='o:site/app/RcAppProAcc/AccountingModelDetail'
	
	*/
	
	
	--'Заряженная горная масса ВСДП (1078067)', --3831bf15569a4d0d9895b1e0dc360a4b заменить на a0089af385e94cf6a8c625b7e586fb2d
	  select store_material, * 
	  from   --store_material
	  public.accmovements_nodeinstance
	  where store_material='3831bf15569a4d0d9895b1e0dc360a4b'  
	  and node in (
	    'cac1db61b165405b85523c4221882e24', --Заряженные скважины (Константиновское) -- Заряженная горная масса ВСДП гранит (000002)
		'fc7277a1fc2447cba6662e933a114264', --Пробуренные скважины (Константиновское) -- Взрывные скважины ВСДП гранит (000001)
		'236586f829204894bfa49560610fc152' --Взорванная горная масса (Константиновское) -- Взорванная горная масса ВСДП гранит (000003)
		  )
	and starttime>='2023-09-30 19:00:00+08' and modelreference='o:site/app/RcAppProAcc/AccountingModelDetail'
	
	/*--апдейт материала на запасах
	update public.accmovements_nodeinstance
	set store_material='a0089af385e94cf6a8c625b7e586fb2d'
	where elementid in (select elementid 
	  from   --store_material
	  public.accmovements_nodeinstance
	  where store_material='3831bf15569a4d0d9895b1e0dc360a4b'  
	  and node in (
	    'cac1db61b165405b85523c4221882e24', --Заряженные скважины (Константиновское) -- Заряженная горная масса ВСДП гранит (000002)
		'fc7277a1fc2447cba6662e933a114264', --Пробуренные скважины (Константиновское) -- Взрывные скважины ВСДП гранит (000001)
		'236586f829204894bfa49560610fc152' --Взорванная горная масса (Константиновское) -- Взорванная горная масса ВСДП гранит (000003)
		  )
	and starttime>='2023-09-30 19:00:00+08') and modelreference='o:site/app/RcAppProAcc/AccountingModelDetail'
	
	*/
	
	--	'Взорванная горная масса ВСДП (1028333)', --6f68acb8cb9646eea05748647c00bdc0 заменить на a0089af385e94cf6a8c625b7e586fb2d
	
	select store_material, * 
	  from   --store_material
	  public.accmovements_nodeinstance
	  where store_material='a0089af385e94cf6a8c625b7e586fb2d' 	  and 
	  node in (
	    'cac1db61b165405b85523c4221882e24', --Заряженные скважины (Константиновское) -- Заряженная горная масса ВСДП гранит (000002)
		'fc7277a1fc2447cba6662e933a114264', --Пробуренные скважины (Константиновское) -- Взрывные скважины ВСДП гранит (000001)
		'236586f829204894bfa49560610fc152' --Взорванная горная масса (Константиновское) -- Взорванная горная масса ВСДП гранит (000003)
		  )
	and starttime>='2023-09-30 19:00:00+08' and modelreference='o:site/app/RcAppProAcc/AccountingModelDetail'
	
--e2a04307495c4b68881e1936b45bc91b
	/*
	--апдейт материала на запасах
	update public.accmovements_nodeinstance
	set store_material='a0089af385e94cf6a8c625b7e586fb2d'
	where elementid in (select elementid 
	  from   --store_material
	  public.accmovements_nodeinstance
	  where store_material='c778d84cd67c4ec9aee4d95f0e78471c'  
	  and node in (
	    'cac1db61b165405b85523c4221882e24', --Заряженные скважины (Константиновское) -- Заряженная горная масса ВСДП гранит (000002)
		'fc7277a1fc2447cba6662e933a114264', --Пробуренные скважины (Константиновское) -- Взрывные скважины ВСДП гранит (000001)
		'236586f829204894bfa49560610fc152' --Взорванная горная масса (Константиновское) -- Взорванная горная масса ВСДП гранит (000003)
		  )
	and starttime>='2023-09-30 19:00:00+08')
	*/
	
	select store_material, * 
	  from   --store_material
	  public.accmovements_nodeinstance
	  where store_material='6f68acb8cb9646eea05748647c00bdc0' 	  
	  and 
	  node in (
	    '236586f829204894bfa49560610fc152' --Заряженные скважины (Константиновское) -- Заряженная горная масса ВСДП гранит (000002)
		 --Взорванная горная масса (Константиновское) -- Взорванная горная масса ВСДП гранит (000003)
		  )
	and starttime>='2023-10-17 19:00:00+08' 
	--and  endtime<='2023-10-17 19:00:00+08' 
	and modelreference='o:site/app/RcAppProAcc/AccountingModelDetail'
	order by endtime
--e2a04307495c4b68881e1936b45bc91b
	
	/*
	--апдейт материала на запасах
	
	update public.accmovements_nodeinstance
	set store_material='c778d84cd67c4ec9aee4d95f0e78471c'
	where elementid in (select elementid 
	  from   --store_material
	  public.accmovements_nodeinstance
	  where store_material='6f68acb8cb9646eea05748647c00bdc0'  
	  and node in (
	    '236586f829204894bfa49560610fc152' --Взорванная горная масса (Константиновское) -- Взорванная горная масса ВСДП гранит (000003)
		  )
	and starttime>='2023-09-30 19:00:00+08' and  endtime<='2023-10-17 19:00:00+08' and modelreference='o:site/app/RcAppProAcc/AccountingModelDetail'
	)
	
	
	*/
	
	
	/*
	'Взрывные скважины ВСДП (1078066)', --2f7d1dd2cfb746cbacc79a5c2be1b71d заменить на 65e0f7e0076e47c88f2219a7884c0525
		'Заряженная горная масса ВСДП (1078067)', --3831bf15569a4d0d9895b1e0dc360a4b заменить на a0089af385e94cf6a8c625b7e586fb2d
		'Взорванная горная масса ВСДП (1028333)', --6f68acb8cb9646eea05748647c00bdc0 заменить на c778d84cd67c4ec9aee4d95f0e78471c
			'Взрывные скважины ВСДП гранит (000001)', --65e0f7e0076e47c88f2219a7884c0525
			'Заряженная горная масса ВСДП гранит (000002)', --a0089af385e94cf6a8c625b7e586fb2d
			'Взорванная горная масса ВСДП гранит (000003)'  --c778d84cd67c4ec9aee4d95f0e78471c
			*/
	
	____________________________
	Если к 1 скважине 2 движеняи привязаны в бд 2 движения
	находим, удаляем через deletemov или
	удаляем из работы по бутению
	ищем сообщение и кидаем заново, заряжаем
	


----------------------
Найти кол-во  заряжанных скважин 

select b.number b_number,count(b.number),
pl.number,b.blastblock ,tb.borehole tb_borehole,b.elementid b_elementid,b.isavailabletocharge,tb.project from
public.dbo_toblastborehole tb
--join public.dbo_toblastborehole tb  on tb.project=ch.project
--join public.dbo_chargingwork ch on tb.project=ch.project
join public.dbo_borehole b on tb.borehole=b.elementid
left join public.dbo_plannedborehole pl on pl.elementid=b.plannedborehole

where --ch.elementid='97415ef0bcb942aea7f8456764c5f729'
tb.project='c18c23267aac45c2871001f37019bca7'
group by  b.number,pl.number,tb.borehole,tb.project,b.blastblock,b.elementid
having  count(b.number)>=1
order by b.number
	
--------------------------------------------



ПОИСК СКВАЖИН ПО НОМЕРАМ если привязались некорректные план/факт по координатам

select project,p.number ,p.elementid,b.number as b_number,b2.elementid
from 
public.dbo_plannedborehole p
join ( select number from public.dbo_borehole where drillblock='e384b0996ada4e9e94812f7805736902') as b on p.number=b.number
join public.dbo_borehole b2 on b.number=b2.number and b2.drillblock='e384b0996ada4e9e94812f7805736902'
where p.project='75a482fcbccc47eba6184fc772cbef32'
order by b.number


----------------------
Найти парк для конфига:
SELECT *FROM public.erpequipment_technicalplace
	where position='1109' or position='1103' 
	
	select * from public.tree_treenode
	where elementid in ('5cdbe7edfe914692850c34032fb6aae1','fd1843bd6dc44b80be18a38ed30c972e')
	
	5cdbe7edfe914692850c34032fb6aae1
	fd1843bd6dc44b80be18a38ed30c972e
	
	select elementcode, * from public.erpresources_resource
	where elementid in ('b18d825331834c2abfafd2b19ca064fc')
	
	__________________________________________________________________-
	находим по месту хранения и ноде запасы дял удаления 
	
	select * 
	from public.accmovements_storeplace
	where --elementid='2a57ec94f8034b8eb97d3735070cceaa'
	name like '%Карьер Сухой Лог/1140/1140-2//013%'
	
	select node.elementcode,* from public.accmovements_nodeinstance ni
	join public.accchannels_nodebase node on ni.node=node.elementid
	where ni.store_storeplace='32ce03c7120549eda1b3519eb80bb922'
	
	
	-----------------------------------------------
	ошибка при создании бластблока 
	у блока выставлено expirationtime с датой , удалить в  public.pageology_blastblock и по id удалить в  public.tree_treenode 
	подождпть обновление кэша геолической модели
	
	
	-----------------------------------
	заряжание и взрывание 
	
select blastblock.number,ch.elementcode,acc.starttime,acc.endtime, --acc.Amount,acc.ExtraAmount
Sum(((SELECT Value FROM jsonb_array_elements(acc.Amount::jsonb->'Attributes') WHERE jsonb_extract_path_text(Value, 'Id')='Value')->'Value'->>'Value')::numeric) as Масса,
Sum(((SELECT Value FROM jsonb_array_elements(acc.ExtraAmount::jsonb->'Attributes') WHERE jsonb_extract_path_text(Value, 'Id')='Value')->'Value'->>'Value')::numeric) as Объем
from 
public.dbomovements_consumeinblastborehole c
join  public.accmovements_movement acc on c.borehole=acc.batchid
--public.accmovements_movement acc
join public.accchannels_channel ch on acc.channel=ch.elementid
join public.dbo_blastproject bl on c.project=bl.elementid
join public.pageology_blastblock blastblock   on bl.block=blastblock.elementid
--where c.project='16f8d5e1756342ca833334070a487e01' 
--and 
where c.project ='6737d8463f004351b9428c5b2efd3ddf'
--ch.elementcode='Заряженные скважины --> Взрывание (СухЛог)' or ch.elementcode='Взрывание --> Взорванная горная масса  (СухЛог)'
and acc.modelreference='o:site/app/RcAppProAcc/AccountingModelDetail'
--acc.starttime>='2024-01-05 19:00:00+08' and acc.endtime<='2024-01-06 19:00:00+08'
group by ch.elementcode,blastblock.number,acc.starttime,acc.endtime


по каналам учета

select ch.elementcode,acc.starttime,acc.endtime, --acc.Amount,acc.ExtraAmount
Sum(((SELECT Value FROM jsonb_array_elements(acc.Amount::jsonb->'Attributes') WHERE jsonb_extract_path_text(Value, 'Id')='Value')->'Value'->>'Value')::numeric) as Масса,
Sum(((SELECT Value FROM jsonb_array_elements(acc.ExtraAmount::jsonb->'Attributes') WHERE jsonb_extract_path_text(Value, 'Id')='Value')->'Value'->>'Value')::numeric) as Объем
from 
public.accmovements_movement acc 
--public.accmovements_movement acc
join public.accchannels_channel ch on acc.channel=ch.elementid
--where c.project='16f8d5e1756342ca833334070a487e01' 
--and 
where ch.elementcode='Заряженные скважины --> Взрывание (СухЛог)' or ch.elementcode='Взрывание --> Взорванная горная масса  (СухЛог)'
and acc.modelreference='o:site/app/RcAppProAcc/AccountingModelDetail'
and acc.starttime>='2024-01-05 19:00:00+08' and acc.endtime<='2024-01-06 19:00:00+08'
group by ch.elementcode,acc.starttime,acc.endtime



------------------------------
select tb.project blast_id , tb.elementid toblastborehole_id,ch.elementid chargingwork_id,ch.shiftdef,shift.proday, tt.elementcode
from
public.dbo_toblastborehole tb
join public.dbo_chargingwork ch on tb.project=ch.project
join public.dbo_shiftdef shift on shift.elementid=ch.shiftdef
left join tree_treenode tt on tt.elementid = shift.timesdef
where ch.project='7c6c89fa0be84a2ab1c4e261b7195c19'




-------------получить факт ВВ 

select acc.sourcecreation,c.templatereference,*

	from public.dbomovements_chargingborehole c
	 join public.accmovements_movement acc on c.elementid=acc.elementid
     where c.templatereference ilike '%s:PolyusMesPa/Domains/DboMovements/ConsumedMaterial%' and acc.sourcecreation <> 'Administrator'
limit 100


обновить бластблок-----------------------------------------

проверяем  blastblock is null
select blastblock,* 
from public.dbo_borehole
	--set blastblock = '12c0dab906ac40f0a3f1a03c79b6b803'	
	where elementid in (select borehole from public.dbo_toblastborehole
	where project='b7807df37ea34fdf9ab62c7ed6229492') and blastblock is null

апдейтим
/*

update  public.dbo_borehole
	set blastblock = '12c0dab906ac40f0a3f1a03c79b6b803'	
	where elementid in (select borehole from public.dbo_toblastborehole
	where project='b7807df37ea34fdf9ab62c7ed6229492') and blastblock is null

*/

select blastblock,* 
from public.dbo_borehole
	--set blastblock = '12c0dab906ac40f0a3f1a03c79b6b803'	
	where elementid in (select borehole from public.dbo_toblastborehole
	where project='b7807df37ea34fdf9ab62c7ed6229492') and blastblock is null
	
	
	
	
	-------
	дубли в заряжании скважин
	
	select count(tb.borehole),tb.borehole ,tb.elementid tb_elementid--count(pl.elementid) 
,tb.addat,tb.updateat
from
public.dbo_toblastborehole tb
join public.dbo_blastproject b on b.elementid=tb.project
--join public.dbo_planchargematerial pl on pl.toblastborehole=tb.elementid
where tb.project='6737d8463f004351b9428c5b2efd3ddf' and tb.borehole not in ('b75a2382cca4492caf1f5b149c5093de')--and tb.borehole='311dca4a89b94b9f879c8c2ee3ab40b6'
and tb.addat>'2024-01-24 17:26:16.465103+07'
group by  tb.borehole,tb.elementid,tb.addat,tb.updateat
--having count(tb.borehole)<2
order by tb.borehole



--------------
Если нет цепочки запасов нет, и есть только 1 запас открытый , чтобы зарядить , над поменять старт/енд запаса на нужную дату и зарядить этой же сменой

или надо зарядить скважины которы закрыты в другой дате или когда-то ранее.
апдейтим время окончания сторе плейс
апдейтим время начала и окончания на запасах

----------------


получить списания мтр на скважину


select ch.elementcode,
acc.templatereference,chr.templatereference,
pr.borehole pr_borehole,
pr.startat,
chr.elementid chr_elementid,
acc.elementid acc_elementid,
* from
public.dbomovements_producedrilledborehole pr
join public.dbo_toblastborehole tb on tb.borehole=pr.borehole
 join public.dbomovements_chargingborehole chr on tb.borehole=chr.borehole
join public.accmovements_movement acc on  chr.elementid=acc.elementid
join public.accchannels_channel ch on acc.channel=ch.elementid
where chr.templatereference='s:PolyusMesPa/Domains/DboMovements/ConsumedMaterial'
--acc.templatereference ilike '%s:PolyusMesPa/Domains/DboMovements/ConsumedMaterial%'
and pr.borehole='633114cd154140e6ada7fa937fafd17f'
and pr.startat>'2024-02-01 19:10:22+03'
limit 100



--------------------
Получить processordernoderef в erpresources_resource

SELECT pr.elementid pr_elementid, 
acc.elementid acc_elementid,
ch.elementid ch_elementid,
ch.target ch_target,
net_node.elementid net_node_elementid_facterpnode,
net_node.elementcode net_node_elementcode,
'/////',
erp.isstorage erp_isstorage,
erp.processordernoderef erp_processordernoderef,
'/////',
* from 
public.dbomovements_producedrilledborehole pr 
join public.accmovements_movement acc on pr.elementid = acc.elementid
join net_channel ch on ch.elementid = acc.channel
join net_node net_node on  net_node.elementid = ch.target
join erpaccountingchannelsmodel_facterpnode facterpnode on facterpnode.elementid = net_node.elementid
join  erpresources_resource erp on erp.processordernoderef=facterpnode.processordernoderef
order by pr.addat desc
limit 100



--- повторное отправка события

SELECT  s."Id",s."EventRef", s."DeliverRef", s."EventId"    ,*
	FROM public."EventInstanceDbtos" EVENT
	join public."SubscriptionDbtos" s on s."Id" = EVENT."EventId"
	where (EVENT."EventId" ='1452' or  EVENT."EventId" ='39') 
	--and data ilike '%1822d415c91e4429a7ca67265b0445e1%'
	
	order by "RaisedAt" desc
	
	select * from
	public."DeliverDbtos"
	where "EventInstanceId"='1452'
	--"IsDelivered"  false
	--"NextAttemptAfterAt" чуьть больше текущего
	
	select * from 
	public."DeliverAttemptDbtos"
	where "DeliverId" = '2972'
	-- тут смотреть сколько раз отправлялось событие
	
	
	--------------------------------------------
	Для группировки результатов по batchid и вывода elementid с максимальным endtime для каждого batchid, нужно использовать агрегатную функцию MAX() в сочетании с группировкой. 
	Затем можно соединить результат с исходной таблицей, чтобы получить соответствующий elementid. Вот пример запроса, который делает это:


SELECT
    ni.batchid,
    ni.elementid,
    ni.endtime
FROM
    nodeinstance ni
INNER JOIN (
    SELECT
        batchid,
        MAX(endtime) as max_endtime
    FROM
        nodeinstance
    WHERE
        batchid IN ('725f531ba2aa4a07beeb496ef74f6d35', '0c0a69997f7344c1a43ee531a4356f2a')
    GROUP BY
        batchid
) grouped_ni ON ni.batchid = grouped_ni.batchid AND ni.endtime = grouped_ni.max_endtime


Этот запрос сначала выбирает максимальные endtime для каждого batchid в подзапросе, а затем соединяет результат с исходной таблицей nodeinstance для получения соответствующих elementid.




проверить пустые движения и pr 

select b.number,b.elementid,pr.elementid pr,acc.elementid mov,acc.sourcecreation,ni.elementid ni_id,acc.source ni_id_source,pr.*
from public.dbomovements_producedrilledborehole pr 
full join public.dbo_borehole b  on b.elementid=pr.borehole
full join public.accmovements_movement acc on pr.elementid=acc.elementid
full join public.accmovements_nodeinstance ni on ni.node=acc.destination
full join public.accmovements_nodeinstance ni2 on ni.node=acc.source
where acc.modelreference='o:site/app/RcAppProAcc/AccountingModelDetail' and  pr.startat >='2024-03-01 02:51:25+07' --and acc.elementid is null 
--pr.work in (	'3805b9a8f3fb42df806b26aa12c2fe7b')

OR

select b.number,b.elementid,pr.elementid pr,acc.elementid mov,acc.sourcecreation,pr.*
from public.dbomovements_producedrilledborehole pr 
full join public.dbo_borehole b  on b.elementid=pr.borehole
full join public.accmovements_movement acc on pr.elementid=acc.elementid
where pr.work in (	'59a04522b5d143a6bc4e61ea186ce09f')
order by b.number


-----------------

operation. Ошибки валидации:
[o:site/app/RcAppProAcc/AccountingModelDetail] [Rc.App.Pro.Acc.Client.Domains.Movements.Store] TryGetElementFromCache() - Идентификатор не может быть пустым;
Ошибки операции:

находим storeplace и удаляем его если там нет запасов и заново бурим скважины




------------------------
Находим кривые borehole и plannedborehole по number в toblastborehole

select 
pl.project id_проект_на_бурение,
drillbock.number номер_бурового_блока,
drillbock.elementid id_бурового_блока,
pl.elementid id_плановой_скважины,
rr.elementid,
rr.name,
pl.number plan_number_borehole,
b.number number_факт_скважины,
b.elementid id_факт_скважины,
b.plannedborehole,
tb.elementid tb_id,
tb.borehole tb_borehole,
tb.plannedborehole,
pr.elementid id_опер_бурения,
acc.elementid  accid_опер_бурения,
b.producingblock id_эксп_блока_факт_скважины,
b.blastblock id_взрывного_блока,
blastblock.number номер_взр_блока,

*
from
dbo_plannedborehole pl 
join dbo_drillproject dr on pl.project=dr.elementid
join pageology_drillblock drillbock on dr.block=drillbock.elementid
full join dbo_borehole b on pl.elementid = b.plannedborehole
full join public.dbomovements_producedrilledborehole pr on pr.borehole=b.elementid
full join public.accmovements_movement acc on pr.elementid=acc.elementid
full join pageology_blastblock blastblock  on b.blastblock=blastblock.elementid
 join dbo_drillingwork DW on dw.elementid=pr.work
    full join erpresources_resource rr on dw.machine = rr.elementid
	full join public.erpequipment_technicalplace erp_t on erp_t.processsegment=rr.elementid
full join public.dbo_toblastborehole tb on tb.borehole=b.elementid
where drillbock.number = '1110-4' -- ввести буровой блок
--and pl.number in ('434','435', '436') -- ввести номер плановых скважин
--and b.number in ('434','435', '436') -- ввести номер фактчиеской скважин
--drillbock.elementid='fa6830d66ec1425899f3318bdc52aea5'
--and b.plannedborehole<>pl.elementid
--and pl.number<>b.number
order by pl.number


----------------------
select b.number,ch.borehole,acc.elementid,ch.consumedmaterial_priority ,acc.material,mm.elementid,mm.elementcode,ch.templatereference, * from
public.dbomovements_chargingborehole ch
join public.accmovements_movement acc on acc.elementid=ch.elementid
join public.material_material mm on acc.material=mm.elementid
join dbo_borehole b on ch.borehole=b.elementid
where ch.work='fa94a3c1161441c982a81cbf1ce04b94'
--and ch.borehole ='4112125eeaa84eaea476bfb7b6678975'
and ch.templatereference='s:PolyusMesPa/Domains/DboMovements/ConsumedMaterial'
order by ch.borehole --,mm.elementcode

апдейт



update public.dbomovements_chargingborehole
set consumedmaterial_priority = 1
where work in (
	'7ecbcb6e435f40c4bf1820bdd9f9058e',
	'cb1e1dd602a04787901ed59337d2ae70',
	'04a7bbadb9684caf903fe8c60c6f80bd'
	) and elementid in (
select ch.elementid from
public.dbomovements_chargingborehole ch
join public.accmovements_movement acc on acc.elementid=ch.elementid
join public.material_material mm on acc.material=mm.elementid
join dbo_borehole b on ch.borehole=b.elementid
where ch.work in (
	'7ecbcb6e435f40c4bf1820bdd9f9058e',
	'cb1e1dd602a04787901ed59337d2ae70',
	'04a7bbadb9684caf903fe8c60c6f80bd'
	)
	
--and ch.borehole ='4112125eeaa84eaea476bfb7b6678975'
and ch.templatereference='s:PolyusMesPa/Domains/DboMovements/ConsumedMaterial'
and ch.consumedmaterial_priority is null
)



----------------------------------
Поменять блока
select * from
public.pageology_block
where name ilike '%AD%'
order by name


select * from
public.pageology_drillblock
where number ilike '%AD%'

select * from
public.pageology_blastblock
where number ilike '%AD%'

select * from
public.tree_treenode
where elementid in (

'a1733f903d514c4ab96c03c24e1d678c',
'9ab93e16548d415c8a13fe5733fb1d6a',
'11527c877a8647b5b7de56d711b9fd6a',
	'9a066eae6bad4c8587f88c4302d9a4e3',
'5af27a45c7bf46818a6e43f6885c3c6e',
	'3872dbc491d9433b8015eb758c860f51',
'21befc1f999241ec8a53a542c3ad6e9b'
)












--new ver 01.22.2024
--Оптимизированный запрос
--Новый запрос
/*Declare @timeOffsetBack as int, @timeOffsetDir as int, @timeMark as datetime;
set @timeOffsetBack = '60'
set @timeOffsetDir = '360'
set @timeMark ='2022-04-05 15:00:00'*/

DECLARE @dateStart as datetime, @dateEnd as datetime, @offset as int;

SET @offset = (select top 1 Offset from [asugtk].TimezoneAdjustment);
SET @dateStart = DATEADD(MINUTE, -@timeOffsetBack, @timeMark);
SET @dateEnd = DATEADD(MINUTE, @timeOffsetDir, @dateStart);

/*
SET @dateStart = '2023-11-02 19:00:00';
SET @dateEnd = '2023-11-04 19:00:00';
*/

select
	N'DH/'+CAST(T.DRILL_BLAST_IDENT as NVARCHAR(30)) + '/' +  replace(replace(replace(replace(T.HoleId ,'/''-',''),'(',''),')',''),' ','') as WencoId,
	T.DrillBlockNumber, 
	--T.HoleId as HoleId_t,
	case
		when LEN(T.HoleId) = 1 then '00' + T.HoleId
		when LEN(T.HoleId)=2 then '0' + T.HoleId
		else HoleId
		end as HoleId,
	--HoleIdCount,
	max(T.PlannedCollarY) as PlannedCollarY, 
	max(T.PlannedCollarX) as PlannedCollarX, 
	max(T.PlannedCollarZ) as PlannedCollarZ, 
	max(T.DrillTipCollarY) as DrillTipCollarY, 
	max(T.DrillTipCollarX) as DrillTipCollarX, 
	max(T.DrillTipCollarZ) as DrillTipCollarZ, 
	max(T.PlannedToeY) as PlannedToeY, 
	max(T.PlannedToeX) as PlannedToeX,  
	max(T.PlannedToeZ) as PlannedToeZ, 
	max(T.DrillTipToeY) as DrillTipToeY, 
	max(T.DrillTipToeX) as DrillTipToeX, 
	max(T.DrillTipToeZ) as DrillTipToeZ, 
	sum(T.Depth) as Depth, 
	T.EquipmentId, 
	min(T.StartTimeStamp) as StartTimeStamp, 
	max(T.EndTimeStamp) as EndTimeStamp, 
	T.LicenseName, 
	max(DateTimeChange) as DateTimeChange,
    DateTimeDelete,	 
	T.DrillHoleType as DrillHoleType
	
from (
select distinct
	DH.DRILL_BLAST_IDENT
    ,(SELECT SUBSTRING( DB.BLAST_LOCATION_SNAME,V.number,1)
          FROM master.dbo.spt_values V
          WHERE V.type='P' AND V.number BETWEEN 1 AND LEN( DB.BLAST_LOCATION_SNAME) AND SUBSTRING(DB.BLAST_LOCATION_SNAME,V.number,1) LIKE '[0123456789-]'
        ORDER BY V.number
        FOR XML PATH('')) as DrillBlockNumber
	,case 
	 when DT2.IS_REDRILL='Y' then [dbo].[GetNumberBorehole](DH.DRILL_BLAST_IDENT,DH.HOLE_CODE,DT2.END_TIMESTAMP)
	 else replace(replace(replace(replace(DH.HOLE_CODE,'/''-',''),'(',''),')',''),' ','') end as HoleId
	,isnull(DH.DESIGN_NORTHING,0) AS PlannedCollarY
	,isnull(DH.DESIGN_EASTING,0) as PlannedCollarX
	,isnull(DH.DESIGN_ELEVATION,0) AS PlannedCollarZ
	,isnull(DT2.HOLE_NORTHING,0) AS DrillTipCollarY
	,isnull(DT2.HOLE_EASTING,0) AS DrillTipCollarX
	,isnull(DT2.HOLE_ELEVATION,0) AS DrillTipCollarZ
	,isnull(DH.DESIGN_TOE_NORTHING,0) AS PlannedToeY
	,isnull(DH.DESIGN_TOE_EASTING,0) AS PlannedToeX
	,isnull(DH.DESIGN_TOE_ELEVATION,0) AS PlannedToeZ
	,isnull(DT2.HOLE_TOE_NORTHING,0) AS DrillTipToeY
	,isnull(DT2.HOLE_TOE_EASTING,0) AS DrillTipToeX
	,isnull(DT2.HOLE_TOE_ELEVATION,0) AS DrillTipToeZ
	,DT2.HOLE_DEPTH AS Depth
	,DT2.EQUIP_IDENT as EquipmentId
	,DT2.DRILL_START_TIMESTAMP as StartTimeStamp
	,DT2.END_TIMESTAMP as EndTimeStamp
	,C.PIT_NAME as LicenseName
	,DT2.DateTimeChange as DateTimeChange
	,DT.DateTimeDelete as DateTimeDelete
	,(case	
		when DH.HOLE_CODE like 'П%' then '3'
		when DT2.IS_REDRILL='Y'  then '3'
		else '2'
		end) as DrillHoleType
from asugtk.DRILL_TRANS DT
	left join asugtk.DRILL_TRANS DT2 on DT2.DRILL_BLAST_IDENT = DT.DRILL_BLAST_IDENT and DT2.HOLE_CODE=DT.HOLE_CODE  
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
		)
		and isnull(DT2.HOLE_DEPTH,0) <> 0
UNION ALL

select distinct
	DH.DRILL_BLAST_IDENT
    ,(SELECT SUBSTRING( DB.BLAST_LOCATION_SNAME,V.number,1)
          FROM master.dbo.spt_values V
          WHERE V.type='P' AND V.number BETWEEN 1 AND LEN( DB.BLAST_LOCATION_SNAME) AND SUBSTRING(DB.BLAST_LOCATION_SNAME,V.number,1) LIKE '[0123456789-]'
        ORDER BY V.number
        FOR XML PATH('')) as DrillBlockNumber
	,replace(replace(replace(replace(DH.HOLE_CODE,'/''-',''),'(',''),')',''),' ','') as HoleId
	,isnull(DH.DESIGN_NORTHING,0) AS PlannedCollarY
	,isnull(DH.DESIGN_EASTING,0) as PlannedCollarX
	,isnull(DH.DESIGN_ELEVATION,0) AS PlannedCollarZ
	,isnull(DT2.HOLE_NORTHING,0) AS DrillTipCollarY
	,isnull(DT2.HOLE_EASTING,0) AS DrillTipCollarX
	,isnull(DT2.HOLE_ELEVATION,0) AS DrillTipCollarZ
	,isnull(DH.DESIGN_TOE_NORTHING,0) AS PlannedToeY
	,isnull(DH.DESIGN_TOE_EASTING,0) AS PlannedToeX
	,isnull(DH.DESIGN_TOE_ELEVATION,0) AS PlannedToeZ
	,isnull(DT2.HOLE_TOE_NORTHING,0) AS DrillTipToeY
	,isnull(DT2.HOLE_TOE_EASTING,0) AS DrillTipToeX
	,isnull(DT2.HOLE_TOE_ELEVATION,0) AS DrillTipToeZ
	,DT2.HOLE_DEPTH AS Depth
	,DT2.EQUIP_IDENT as EquipmentId
	,DT2.DRILL_START_TIMESTAMP as StartTimeStamp
	,DT2.END_TIMESTAMP as EndTimeStamp
	,C.PIT_NAME as LicenseName
	,DT2.DateTimeChange as DateTimeChange
	,DT2.DateTimeDelete as DateTimeDelete 
	,(case	
		when DH.HOLE_CODE like 'П%' then '3'
		when DT2.IS_REDRILL='Y'  then '3'
		else '2'
		end) as DrillHoleType
from [asugtk].[DRILL_TRANS_DELETED_ENTRIES] DT
	left  join [asugtk].[DRILL_TRANS_DELETED_ENTRIES] DT2 on DT2.DRILL_BLAST_IDENT = DT.DRILL_BLAST_IDENT and DT2.HOLE_CODE=DT.HOLE_CODE  
	join asugtk.DRILL_BLAST DB on DT2.DRILL_BLAST_IDENT = DB.DRILL_BLAST_IDENT
	join asugtk.DRILL_HOLE DH on DT2.DRILL_BLAST_IDENT = DH.DRILL_BLAST_IDENT and DH.HOLE_CODE=DT2.HOLE_CODE
	join asugtk.LOCATION_BLAST_PATTERN c on DB.BLAST_LOCATION_SNAME = c.LOCATION_SNAME
where DT2.END_TIMESTAMP is not null 
	and DT2.DateTimeDelete>= @dateStart and DT2.DateTimeDelete<=@dateEnd and isnull(DT2.HOLE_DEPTH,0) <> 0
) T		
group by T.DRILL_BLAST_IDENT, T.DrillBlockNumber, T.HoleId, T.EquipmentId, T.LicenseName, T.DrillHoleType, T.DateTimeDelete

order by DateTimeChange







--old ver 2023
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

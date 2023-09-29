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
SET @dateStart = '2023-02-10 19:00:00';
SET @dateEnd = '2023-02-11 19:00:00';*/

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
		) as T
		where T.Depth<>'0'  --and WencoId like 'DH/-1729/04%'--and holeid like '%142%'  --and T.DrillBlockNumber='850-117' --and holeid='086' 
		
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

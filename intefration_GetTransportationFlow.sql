DECLARE @dateStart as datetime;
SET @dateStart = @timeMark
--SET @dateStart = DATEADD(MINUTE,-30,@timeMark)



SELECT DISTINCT 'TM' + Cast ([TRAMMING_REC_IDENT] as varchar (20)) as WencoId
,[DUMP_END_TIMESTAMP] as LoadStartTime
,[DUMP_END_TIMESTAMP] as LoadEndTime
,[DUMP_END_TIMESTAMP] as DumpTime
,i.changetime as DateTimeChange
,[DateTimeDelete] as DateTimeDelete
,eq.[SERIAL_NUMBER] as HaulUnitId
,eq.[SERIAL_NUMBER] as LoadUnitId
,null as LicenceName
,[LOAD_LOCATION_SNAME] as LoadLocation
,[BLOCK_SNAME] as BlockSName
,[MATERIAL_IDENT] as Material
,[DUMP_LOCATION_SNAME] as DumpLocation
,null as EmptyDistance
,null as HaulDistance
,(CASE
  WHEN (MATERIAL_IDENT = 'HG' OR MATERIAL_IDENT = 'MG' OR MATERIAL_IDENT = 'LG') AND QUANTITY_ORE <> 0 THEN QUANTITY_ORE
  WHEN (MATERIAL_IDENT = 'HG' OR MATERIAL_IDENT = 'MG' OR MATERIAL_IDENT = 'LG') AND (QUANTITY_ORE IS NULL OR QUANTITY_ORE = 0) THEN QUANTITY_REPORTING * 2.7
  WHEN MATERIAL_IDENT = 'WST' AND QUANTITY_WASTE <> 0 THEN QUANTITY_WASTE
  WHEN MATERIAL_IDENT = 'WST' AND (QUANTITY_WASTE IS NULL OR QUANTITY_WASTE = 0) THEN QUANTITY_REPORTING * 2.7
  END) as QuantityMass
,[QUANTITY_REPORTING] as QuantityVolume
,null as HaulOperatorId
,[BADGE_IDENT] as LoadOperatorId
,null as LoadShift
,[DUMP_END_SHIFT_IDENT] as DumpShift
,null as EvalEmptyNeg
,null as EvalEmptyPos
,null as EvalHaulNeg
,null as EvalHaulPos
,null as Components
,null as Lithology
,null as LoadCoordinateX
,null as LoadCoordinateY
,null as LoadCoordinateZ
FROM [asugtk].[TRAMMING_TRANS] g inner join [dbo].[asugtk2mes_journal] i on g.TRAMMING_REC_IDENT = i.operid and i.IS_READING = 0
left join [asugtk].[EQUIP] eq on eq.EQUIP_IDENT = g.EQUIP_IDENT
where [DUMP_END_TIMESTAMP] >= '2023-08-31 19:00:00' and DUMP_END_TIMESTAMP is not null and [LOAD_LOCATION_SNAME] not in ('Штабель 6.1', 'Штабель 6.0') and [DUMP_LOCATION_SNAME] in ('C-150', 'LT120E')

union all
SELECT DISTINCT 'TR'+ cast (a.[HAUL_CYCLE_REC_IDENT] as varchar (20)) as WencoId
,a.[LOAD_START_TIMESTAMP] as LoadStartTime
,isnull (b.END_TIMESTAMP, DATEADD(MINUTE,+1,a.[LOAD_START_TIMESTAMP]))   as LoadEndTime
,a.[DUMP_END_TIMESTAMP] as DumpTime
,h.changetime as DateTimeChange
,a.[DateTimeDelete] as DateTimeDelete
,hu.[SERIAL_NUMBER] as HaulUnitId
,lu.[SERIAL_NUMBER] as LoadUnitId
,f.[PIT_NAME] as LicenceName
,a.[LOAD_LOCATION_SNAME] as LoadLocation
,(CASE 
       WHEN a.BLOCK_SNAME is null AND a.MATERIAL_IDENT = 'WST' THEN 'WST1'
	   ELSE a.BLOCK_SNAME END) as BlockSName
,a.[MATERIAL_IDENT] as Material
,a.[DUMP_LOCATION_SNAME] as DumpLocation
,a.[EMPTY_DISTANCE] as EmptyDistance
,a.[HAUL_DISTANCE] as HaulDistance
,(CASE 
   WHEN a.SCALE_WEIGHT IS NOT NULL AND a.SCALE_WEIGHT > 0.5 * a.PAYLOAD_TARGET AND a.SCALE_WEIGHT < 1.5 * a.PAYLOAD_TARGET and (a.PAYLOAD_REPORTING IS NULL or a.PAYLOAD_REPORTING = 0) THEN a.SCALE_WEIGHT
   WHEN a.PAYLOAD_REPORTING IS NOT NULL THEN a.PAYLOAD_REPORTING   
   WHEN a.PAYLOAD_REPORTING IS NULL THEN a.PAYLOAD_TARGET
   END)as QuantityMass
,a.[QUANTITY_REPORTING] as QuantityVolume
,a.[HAULING_UNIT_BADGE_IDENT] as HaulOperatorId
,a.[LOADING_UNIT_BADGE_IDENT] as LoadOperatorId
,a.[LOAD_START_SHIFT_IDENT] as LoadShift
,a.[DUMP_END_SHIFT_IDENT] as DumpShift
,a.[ELEVATION_EMPTY_NEGATIVE] as EvalEmptyNeg
,a.[ELEVATION_EMPTY_POSITIVE] as EvalEmptyPos
,a.[ELEVATION_HAUL_NEGATIVE] as EvalHaulNeg
,a.[ELEVATION_HAUL_POSITIVE] as EvalHaulPos
,'5/' + CAST (d.[QUALITY_VALUE] as varchar (20)) as Components
,e.[BLAST_NUMBER] as Lithology
,null as LoadCoordinateX
,null as LoadCoordinateY
,null as LoadCoordinateZ
--,lc.BUCKET_EASTING as LoadCoordinateX
--,lc.BUCKET_NORTHING as LoadCoordinateY
--,lc.BUCKET_ELEVATION as LoadCoordinateZ
FROM [asugtk].[HAUL_CYCLE_TRANS] a inner join [dbo].[asugtk2mes_journal] h on a.HAUL_CYCLE_REC_IDENT = h.operid and h.IS_READING = 0
left join [asugtk].EQUIPMENT_STATUS_TRANS b on a.LOADING_UNIT_IDENT = b.EQUIP_IDENT and a.LOAD_START_TIMESTAMP = b.START_TIMESTAMP
left join [asugtk].LOCATION_BLK_QLT d on a.LOAD_LOCATION_SNAME = d.LOCATION_SNAME and a.BLOCK_SNAME = d.BLOCK_SNAME
left join [asugtk].LOCATION_BLK e on a.LOAD_LOCATION_SNAME = e.LOCATION_SNAME and a.BLOCK_SNAME = e.BLOCK_SNAME
left join [asugtk].[LOCATION_DIG] f on a.LOAD_LOCATION_SNAME = f.LOCATION_SNAME 
left join [asugtk].[EQUIP] hu on hu.EQUIP_IDENT = a.HAULING_UNIT_IDENT
left join [asugtk].[EQUIP] lu on lu.EQUIP_IDENT = a.LOADING_UNIT_IDENT
--left join [asugtk].BV_LOAD_TRANS c on a.HAUL_CYCLE_REC_IDENT = c.HAUL_CYCLE_REC_IDENT 
--LEFT OUTER JOIN (SELECT LOAD_REC_IDENT, BUCKET_EASTING, BUCKET_NORTHING, BUCKET_ELEVATION, RANK() OVER (PARTITION BY LOAD_REC_IDENT
--ORDER BY TIMESTAMP ASC) AS bc_order from [IntegraDB].[asugtk].BV_BUCKET_TRANS  ) lc on lc.LOAD_REC_IDENT=c.LOAD_REC_IDENT and lc.bc_order = 1
where [DUMP_END_TIMESTAMP] >= '2023-08-31 19:00:00' and DUMP_END_TIMESTAMP is not null
  and (isnull(d.QUALITY_CODE,5)=  5)-- and (isnull(d.ACTIVE,'Y')='Y') and (isnull(e.ACTIVE,'Y')='Y')
  and [LOAD_LOCATION_SNAME] not in ('Кадаликан','Верхний Кадаликанский','Дамба 1','Пригруз дренажной дамбы','Дамба очередь 13','Штабель 6.0','ХХ Флотации')
  and b.DateTimeDelete is null
  and a.[LOAD_START_TIMESTAMP] is not null
  order by DUMP_END_TIMESTAMP

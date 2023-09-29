DECLARE @dateStart as datetime, @dateEnd as datetime, @offset as int;
set @offset = 0--(select top 1 Offset from [asugtk].TimezoneAdjustment);
SET @dateStart = '2023-01-30 07:00:00';
SET @dateEnd = '2023-01-30 19:00:00';


SELECT DB.BLAST_LOCATION_SNAME AS 'Blok'

--,DH.HOLE_CODE AS 'Название скважины'

--,DH.DESIGN_NORTHING AS 'Плановый X устья'

--,DH.DESIGN_EASTING as 'Плановый Y устья'

--,DH.DESIGN_ELEVATION AS 'Плановый Z устья'

--,DH.DESIGN_TOE_NORTHING AS 'Плановый X забоя'

--,DH.DESIGN_TOE_EASTING AS 'Плановый Y забоя'

--,DH.DESIGN_TOE_ELEVATION AS 'Плановый Z забоя'

--,DH.DESIGN_DEPTH AS 'Плановая глубина'

--,DT2.HOLE_NORTHING AS 'Фактический X устья'

--,DT2.HOLE_EASTING AS 'Фактический Y устья'

--,DT2.HOLE_ELEVATION AS 'Фактический Z устья'

--,DT3.HOLE_TOE_NORTHING AS 'Фактический X забоя'

--,DT3.HOLE_TOE_EASTING AS 'Фактический Y забоя'

--,DT3.HOLE_TOE_ELEVATION AS 'Фактический Z забоя'
-- ,DT1.sum_HOLE_DEPTH AS 'Фактическая глубина'
,DT3.EQUIP_IDENT as 'Станок'
,sum (DT1.sum_HOLE_DEPTH) AS 'metr'
,count (DH.HOLE_CODE) AS 'Количество скважин'
--,DT2.DRILL_START_TIMESTAMP AS 'Начало бурения'
--,DT3.END_TIMESTAMP AS 'Окончание бурения'
--,DH.COMMENT 
--,C.PIT_NAME AS 'Лицензия' 
--,DT1.changetime
FROM asugtk.DRILL_HOLE DH
INNER JOIN asugtk.DRILL_BLAST DB ON DH.DRILL_BLAST_IDENT=DB.DRILL_BLAST_IDENT
LEFT JOIN (select DRILL_BLAST_IDENT,HOLE_CODE,max(case when DateTimeDelete is null then END_TIMESTAMP else null end) Max_END_TIMESTAMP,
sum(case when DateTimeDelete is null then HOLE_DEPTH else null end) sum_HOLE_DEPTH,
min(case when DateTimeDelete is null then DRILL_START_TIMESTAMP else null end) Min_DRILL_START_TIMESTAMP, max(J.changetime) changetime
from asugtk.DRILL_TRANS DT left join dbo.asugtk2mes_journal J on 
       J.id=(select max(j1.id) from dbo.asugtk2mes_journal J1 where J1.operid=DT.DRILL_REC_IDENT and J1.SourceTableName='asugtk.DRILL_TRANS')
       group by DRILL_BLAST_IDENT,HOLE_CODE) DT1 on DT1.DRILL_BLAST_IDENT=DH.DRILL_BLAST_IDENT and DT1.HOLE_CODE=DH.HOLE_CODE
left join asugtk.DRILL_TRANS DT2 on DT1.DRILL_BLAST_IDENT=DT2.DRILL_BLAST_IDENT and DT1.HOLE_CODE=DT2.HOLE_CODE and DT1.MIN_DRILL_START_TIMESTAMP=DT2.DRILL_START_TIMESTAMP and DT2.DateTimeDelete is null
left join asugtk.DRILL_TRANS DT3 on DT1.DRILL_BLAST_IDENT=DT3.DRILL_BLAST_IDENT and DT1.HOLE_CODE=DT3.HOLE_CODE and DT1.Max_END_TIMESTAMP=DT3.END_TIMESTAMP and DT3.DateTimeDelete is null
left join asugtk.LOCATION_BLAST_PATTERN c on DB.BLAST_LOCATION_SNAME = c.LOCATION_SNAME
where 
DT3.end_TIMESTAMP between @dateStart and @dateEnd
--order by DT3.end_TIMESTAMP desc
group by DT3.EQUIP_IDENT, DB.BLAST_LOCATION_SNAME
-- order by DT3.EQUIP_IDENT asc
order by DT3.EQUIP_IDENT asc, Blok asc
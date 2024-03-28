USE [IntegraDB]
GO
/****** Object:  Trigger [asugtk].[TR_DRILL_TRANS_DELETED_ENTRIES]    Script Date: 11.10.2023 23:52:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER TRIGGER  [asugtk].[TR_DRILL_TRANS_DELETED_ENTRIES]
ON [asugtk].[DRILL_TRANS]
AFTER Update
--Вставляем данные из таблицы [asugtk].[DRILL_TRANS]
AS
IF @@ROWCOUNT=0
--Проверка на количество вставляемых строк. Если 0 то возврат, если есть хотя бы 1 запись продолжить
 RETURN
 
 SET NOCOUNT ON
--Отключение вывода сообщений о количестве обработанных записей
 
 IF ( UPDATE([DRILL_BLAST_IDENT]) OR UPDATE([HOLE_CODE]) )
 -- Если происходит апдейт DRILL_BLAST_IDENT или  HOLE_CODE в  [asugtk].[DRILL_TRANS] , то вставляем записи до апдейта в табличку [asugtk].[DRILL_TRANS_DELETED_ENTRIES] 

BEGIN
Print 'Вошли'
 INSERT INTO [DRILL_TRANS_DELETED_ENTRIES]
(
[system_id]
      ,[DRILL_REC_IDENT]
      ,[CYCLE_START_TIMESTAMP]
      ,[CYCLE_START_SHIFT_DATE]
      ,[CYCLE_START_SHIFT_IDENT]
      ,[DRILL_START_TIMESTAMP]
      ,[DRILL_START_SHIFT_DATE]
      ,[DRILL_START_SHIFT_IDENT]
      ,[EQUIP_IDENT]
      ,[BADGE_IDENT]
      ,[DRILL_BLAST_IDENT]
      ,[HOLE_CODE]
      ,[HOLE_DEPTH]
      ,[IS_REDRILL]
      ,[END_TIMESTAMP]
      ,[END_SHIFT_DATE]
      ,[END_SHIFT_IDENT]
      ,[EQUIP_POSITION_NORTHING]
      ,[EQUIP_POSITION_EASTING]
      ,[COMMENT]
      ,[pk_hash]
      ,[DateTimeChange]
      ,[DateTimeDelete]
      ,[HOLE_NORTHING]
      ,[HOLE_EASTING]
      ,[HOLE_ELEVATION]
      ,[HOLE_TOE_NORTHING]
      ,[HOLE_TOE_EASTING]
      ,[HOLE_TOE_ELEVATION]
      ,[HOLE_DIAMETER]
      ,[COLLAR_GPS_QUALITY]
      ,[TOE_GPS_QUALITY]
      ,[HOLE_TYPE]
      ,[HAS_MANUAL_DEPTH]
      ,[AS_DRILLED_DEPTH]
      ,[SOURCE_ID]
)
SELECT
d.[system_id]
      ,d.[DRILL_REC_IDENT]
      ,d.[CYCLE_START_TIMESTAMP]
      ,d.[CYCLE_START_SHIFT_DATE]
      ,d.[CYCLE_START_SHIFT_IDENT]
      ,d.[DRILL_START_TIMESTAMP]
      ,d.[DRILL_START_SHIFT_DATE]
      ,d.[DRILL_START_SHIFT_IDENT]
      ,d.[EQUIP_IDENT]
      ,d.[BADGE_IDENT]
      ,d.[DRILL_BLAST_IDENT]
      ,d.[HOLE_CODE]
      ,d.[HOLE_DEPTH]
      ,d.[IS_REDRILL]
      ,d.[END_TIMESTAMP]
      ,d.[END_SHIFT_DATE]
      ,d.[END_SHIFT_IDENT]
      ,d.[EQUIP_POSITION_NORTHING]
      ,d.[EQUIP_POSITION_EASTING]
      ,d.[COMMENT]
      ,d.[pk_hash]
      ,d.[DateTimeChange]
      ,CURRENT_TIMESTAMP
      ,d.[HOLE_NORTHING]
      ,d.[HOLE_EASTING]
      ,d.[HOLE_ELEVATION]
      ,d.[HOLE_TOE_NORTHING]
      ,d.[HOLE_TOE_EASTING]
      ,d.[HOLE_TOE_ELEVATION]
      ,d.[HOLE_DIAMETER]
      ,d.[COLLAR_GPS_QUALITY]
      ,d.[TOE_GPS_QUALITY]
      ,d.[HOLE_TYPE]
      ,d.[HAS_MANUAL_DEPTH]
      ,d.[AS_DRILLED_DEPTH]
      ,d.[SOURCE_ID]
From deleted as d
INNER JOIN Inserted i ON d.[DRILL_REC_IDENT] = i.[DRILL_REC_IDENT]  -- сравнения записей во временных таблицах , если записи не равны, то записываем их в табличку deleted
where  d.[HOLE_CODE] <> i.[HOLE_CODE] or d.[DRILL_BLAST_IDENT] <> i.[DRILL_BLAST_IDENT]  -- исключаем отбор записей на которых занулили глубину
END

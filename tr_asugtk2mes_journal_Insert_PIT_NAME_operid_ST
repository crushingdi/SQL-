USE [IntegraDB]
GO
/****** Object:  Trigger [asugtk].[tr_asugtk2mes_journal_Insert_PIT_NAME_operid_ST]    Script Date: 5/17/2024 8:24:21 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
ALTER TRIGGER [asugtk].[tr_asugtk2mes_journal_Insert_PIT_NAME_operid_ST] 
  ON [asugtk].[LOCATION_DIG] 
  AFTER UPDATE 
AS  
BEGIN 
  SET NOCOUNT ON; 

IF (UPDATE (PIT_NAME) and ((select Count(isnull(ins.[PIT_NAME],'')) 
from inserted ins
left join deleted del on ins.LOCATION_SNAME = del.LOCATION_SNAME
where  isnull(ins.[PIT_NAME],'') <> '' and isnull(ins.[PIT_NAME],'') <> isnull(del.[PIT_NAME],'')) > 0))
BEGIN
--фиксируем временной интервал обновления
  declare @starTime datetime, @endTime datetime;
  set @starTime = DATEADD(hour,-5, DATEADD(month, DATEDIFF(month, 0, GETDATE ()), 0));
  set @endTime = DATEADD(hour,+19, cast(EOMONTH (GETDATE ()) as datetime));
-- удаление старых записей журнала
  delete [dbo].[asugtk2mes_journal]
  where  (ChangeType = 'UPDATE' or ChangeType = 'INSERT')
  and [operid] in (
       select  
       hct.HAUL_CYCLE_REC_IDENT
  FROM [asugtk].[HAUL_CYCLE_TRANS] hct   
  join [asugtk].[LOCATION_DIG] f  on hct.LOAD_LOCATION_SNAME = f.LOCATION_SNAME 
  LEFT JOIN [import].[EquipImportRestriction] [eir1] WITH(NOLOCK) ON
				[eir1].[system_id] = 1 AND
				[eir1].[EQUIP_IDENT] = [hct].[HAULING_UNIT_IDENT]
   LEFT JOIN [import].[EquipImportRestriction] [eir2] WITH(NOLOCK) ON
				[eir2].[system_id] = 1 AND
				[eir2].[EQUIP_IDENT] = [hct].[LOADING_UNIT_IDENT]
  where f.LOCATION_SNAME  in (select ins.LOCATION_SNAME from inserted ins
		left join deleted del on ins.LOCATION_SNAME = del.LOCATION_SNAME
		where  isnull(ins.[PIT_NAME],'') <> '' and isnull(ins.[PIT_NAME],'') <> isnull(del.[PIT_NAME],''))
     and hct.HAUL_CYCLE_REC_IDENT is not null 
	 and hct.[DUMP_END_TIMESTAMP] > @starTime  and hct.[DUMP_END_TIMESTAMP] < @endTime

	 AND ([hct].[START_TIMESTAMP] >= [eir1].[TIMESTAMP_IMPORT_RESTRICTION] OR [eir1].[TIMESTAMP_IMPORT_RESTRICTION] IS NULL)
     AND ([hct].[START_TIMESTAMP] >= [eir2].[TIMESTAMP_IMPORT_RESTRICTION] OR [eir2].[TIMESTAMP_IMPORT_RESTRICTION] IS NULL)	
	 )
-- вставка новых  записей журнала
  INSERT [dbo].[asugtk2mes_journal] 
           ([SourceTableName] 
           ,[ChangeType] 
           ,[operid] 
           ,[changetime]
		   ,[UpdTriggerTableName]) 
    (select  
		'asugtk.HAUL_CYCLE_TRANS', 
		'UPDATE', 
		hct.HAUL_CYCLE_REC_IDENT, 
		getdate(),
		'asugtk.LOCATION_DIG'
  FROM [asugtk].[HAUL_CYCLE_TRANS] hct   
  join [asugtk].[LOCATION_DIG] f  on hct.LOAD_LOCATION_SNAME = f.LOCATION_SNAME 
  LEFT JOIN [import].[EquipImportRestriction] [eir1] WITH(NOLOCK) ON
				[eir1].[system_id] = 1 AND
				[eir1].[EQUIP_IDENT] = [hct].[HAULING_UNIT_IDENT]
   LEFT JOIN [import].[EquipImportRestriction] [eir2] WITH(NOLOCK) ON
				[eir2].[system_id] = 1 AND
				[eir2].[EQUIP_IDENT] = [hct].[LOADING_UNIT_IDENT]
  where f.LOCATION_SNAME  in (select ins.LOCATION_SNAME from inserted ins
		left join deleted del on ins.LOCATION_SNAME = del.LOCATION_SNAME
		where  isnull(ins.[PIT_NAME],'') <> '' and isnull(ins.[PIT_NAME],'') <> isnull(del.[PIT_NAME],''))
    and hct.HAUL_CYCLE_REC_IDENT is not null 
	and hct.[DUMP_END_TIMESTAMP] > @starTime and hct.[DUMP_END_TIMESTAMP] < @endTime

	AND ([hct].[START_TIMESTAMP] >= [eir1].[TIMESTAMP_IMPORT_RESTRICTION] OR [eir1].[TIMESTAMP_IMPORT_RESTRICTION] IS NULL)
    AND ([hct].[START_TIMESTAMP] >= [eir2].[TIMESTAMP_IMPORT_RESTRICTION] OR [eir2].[TIMESTAMP_IMPORT_RESTRICTION] IS NULL)	
	) 
END 
END

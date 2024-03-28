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

--получаем  JSON plandistributedcharge
select b.number ,mm.elementcode,mm.elementid mm_id,pl.elementid,pl.plandistributedcharge
from 
public.dbo_toblastborehole tb
join public.dbo_planchargematerial pl on tb.elementid=pl.toblastborehole
join public.dbo_borehole b on b.elementid=tb.borehole
join public.material_material mm on pl.material=mm.elementid
where pl.project='d618f027298b422796c1408ecad1563d' and mm.elementid in ('1c8fec78f78045779318b4434f95ceec'/*,'1c8fec78f78045779318b4434f95ceec'*/)
--and (b.number between '088' and '092' or b.number between '100' and '104' or b.number between '110' and '115' or b.number between '126' and '148' )
order by b.number

-- update JSON plandistributedcharge
update public.dbo_planchargematerial
set plandistributedcharge='{"ElementTypeReference":"s:PolyusMesPa/Types/DistributedCharge","IsDictionary":false,"Elements":[{"Attributes":[{"Value":{"Value":520.00,"TypeReference":"s:sys/core/types/Float"},"Id":"Amount"},{"Value":{"Value":1,"TypeReference":"s:sys/core/types/Integer"},"Id":"Priority"}],"DynamicAttributes":{},"TypeReference":"s:PolyusMesPa/Types/DistributedCharge"}],"ElementsDictionary":{},"LookupKey":null,"TypeReference":"a:s:PolyusMesPa/Types/DistributedCharge"}'
where elementid in (
select pl.elementid
from 
public.dbo_toblastborehole tb
join public.dbo_planchargematerial pl on tb.elementid=pl.toblastborehole
join public.dbo_borehole b on b.elementid=tb.borehole
join public.material_material mm on pl.material=mm.elementid
where pl.project='d618f027298b422796c1408ecad1563d' and mm.elementid in ('1c8fec78f78045779318b4434f95ceec'/*,'1c8fec78f78045779318b4434f95ceec'*/)
--and b.number between '042' and '047' 
and	b.number = '160'
	--and (b.number between '075' and '086'  )
order by b.number
)

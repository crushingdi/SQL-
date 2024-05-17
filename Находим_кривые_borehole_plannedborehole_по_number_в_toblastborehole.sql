
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

SELECT
        mix.elementid, geomix, GEO.ROW,
        ((SELECT Value FROM json_array_elements((SELECT Value FROM json_array_elements(GEO.Value->'Attributes')WHERE(Value->> 'Id') = 'GeoRecord')->'Value'->'Attributes') WHERE(Value->> 'Id') = 'ElementId')->'Value'->>'Value') AS gid,
  ((SELECT Value FROM json_array_elements(GEO.Value->'Attributes')WHERE(Value->> 'Id') = 'Share')->'Value'->>'Value')::numeric AS GEO_SHARE,
  ((SELECT Value FROM json_array_elements(GEO.Value->'Attributes')WHERE(Value->> 'Id') = 'Amount')->'Value'->>'Value')::numeric AS GEO_AMOUNT,
  ((SELECT Value FROM json_array_elements(GEO.Value->'Attributes')WHERE(Value->> 'Id') = 'ExtraAmount')->'Value'->>'Value')::numeric AS GEO_EXTRA_AMOUNT
  ,((SELECT Value FROM json_array_elements(MOV.Amount::json->'Attributes') WHERE (Value->>'Id')='Value')->'Value'->>'Value')::numeric as MOV_Amount
       FROM public.pamovements_mixedpolygonentity AS MIX
      LEFT JOIN public.accmovements_movement AS MOV ON MOV.elementid = MIX.elementid
       LEFT OUTER JOIN LATERAL(SELECT VALUE, ROW_NUMBER()OVER(ORDER BY VALUE::Text)AS ROW FROM json_array_elements(MIX.geomix::json->'Elements'))as GEO on true
        WHERE mix.elementid = '9c172385424d47da9332b8ece314e150'

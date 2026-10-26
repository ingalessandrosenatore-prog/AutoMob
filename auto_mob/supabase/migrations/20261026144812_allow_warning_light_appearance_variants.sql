-- Identity is symbol + observed color + flashing, not symbol alone.
-- 43 legacy symbols × 6 colors × 2 modes bounds existing accepted inputs.
create or replace function public.valid_report_warning_lights(p_lights jsonb)
returns boolean language plpgsql immutable security invoker set search_path = ''
as $$
declare v_light jsonb; v_observations jsonb[] := '{}';
begin
  if p_lights is null or jsonb_typeof(p_lights) <> 'array' then return false; end if;
  if jsonb_array_length(p_lights) > 516 then return false; end if;
  for v_light in select value from jsonb_array_elements(p_lights) loop
    if jsonb_typeof(v_light) <> 'object'
      or not (v_light ?& array['code','color','flashing'])
      or jsonb_typeof(v_light->'code') <> 'string'
      or (v_light->>'code') !~ '^(S(0[1-9]|[1-3][0-9]|40)|STOP|SERVICE|OTHER)$'
      or jsonb_typeof(v_light->'color') <> 'string'
      or (v_light->>'color') not in ('red','amber','green','blue','white','unknown')
      or jsonb_typeof(v_light->'flashing') <> 'boolean'
      or jsonb_build_array(v_light->>'code', v_light->>'color', v_light->'flashing') = any(v_observations)
    then return false; end if;
    v_observations := array_append(v_observations, jsonb_build_array(v_light->>'code', v_light->>'color', v_light->'flashing'));
  end loop;
  return true;
end;
$$;

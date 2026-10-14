-- Standalone MBBS attendance tracker storage.
-- Intentionally separate from the existing NEET-PG study-tracker tables.
create table if not exists public.attendance_tracker_state (
  user_id uuid primary key references auth.users(id) on delete cascade,
  state jsonb not null,
  revision bigint not null default 1 check (revision >= 1),
  updated_at timestamptz not null default now()
);

alter table public.attendance_tracker_state enable row level security;

drop policy if exists "Users can read own attendance state" on public.attendance_tracker_state;
create policy "Users can read own attendance state"
  on public.attendance_tracker_state for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own attendance state" on public.attendance_tracker_state;
drop policy if exists "Users can update own attendance state" on public.attendance_tracker_state;
drop policy if exists "Users can delete own attendance state" on public.attendance_tracker_state;
revoke insert, update, delete on public.attendance_tracker_state from anon, authenticated;
grant select on public.attendance_tracker_state to authenticated;

create or replace function public.save_attendance_tracker_state(
  p_state jsonb,
  p_expected_revision bigint
)
returns table(ok boolean, revision bigint)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_revision bigint;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;
  if p_state is null or jsonb_typeof(p_state) <> 'object' then
    raise exception 'State must be a JSON object' using errcode = '22023';
  end if;

  if p_expected_revision = 0 then
    insert into public.attendance_tracker_state(user_id, state, revision, updated_at)
      values (v_uid, p_state, 1, now())
      on conflict (user_id) do nothing
      returning public.attendance_tracker_state.revision into v_revision;
    if v_revision is null then
      return query select false, (select s.revision from public.attendance_tracker_state s where s.user_id = v_uid);
      return;
    end if;
    return query select true, v_revision;
    return;
  end if;

  update public.attendance_tracker_state s
     set state = p_state, revision = s.revision + 1, updated_at = now()
   where s.user_id = v_uid and s.revision = p_expected_revision
   returning s.revision into v_revision;

  if v_revision is null then
    return query select false, (select s.revision from public.attendance_tracker_state s where s.user_id = v_uid);
  else
    return query select true, v_revision;
  end if;
end;
$$;

revoke all on function public.save_attendance_tracker_state(jsonb, bigint) from public, anon;
grant execute on function public.save_attendance_tracker_state(jsonb, bigint) to authenticated;

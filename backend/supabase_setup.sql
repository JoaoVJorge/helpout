create extension if not exists pgcrypto;

create or replace function public.generate_friend_code()
returns text
language sql
as $$
  select upper(substr(md5(random()::text || clock_timestamp()::text), 1, 10));
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  friend_code text not null default public.generate_friend_code() unique,
  is_dark_mode boolean not null default false,
  user_name text not null default '',
  nick_name text not null default '',
  email text,
  phone_number text,
  birth_date date,
  profile_photo_base64 text,
  accent_color_value bigint not null default 4294940679,
  avatar_icon_index integer not null default 0,
  notifications_enabled boolean not null default true,
  language_code text,
  focus_lock_studying_enabled boolean not null default false,
  focus_lock_exercises_enabled boolean not null default false,
  focus_lock_reading_enabled boolean not null default false,
  focus_lock_hobbies_enabled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles
  add column if not exists focus_lock_studying_enabled boolean not null default false,
  add column if not exists focus_lock_exercises_enabled boolean not null default false,
  add column if not exists focus_lock_reading_enabled boolean not null default false,
  add column if not exists focus_lock_hobbies_enabled boolean not null default false;

create table if not exists public.friendships (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.profiles(id) on delete cascade,
  addressee_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'blocked')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (requester_id, addressee_id),
  check (requester_id <> addressee_id)
);

create table if not exists public.groups (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  theme text not null,
  invite_code text not null unique,
  privacy text not null default 'inviteOnly',
  created_at timestamptz not null default now()
);

create table if not exists public.group_members (
  group_id uuid not null references public.groups(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'member',
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

create table if not exists public.activity_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  category text not null,
  subject_id text,
  subject_name text,
  seconds integer not null default 0,
  pages integer not null default 0,
  completed_tasks integer not null default 0,
  occurred_at timestamptz not null default now()
);

create table if not exists public.user_subjects (
  id text not null,
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  category text not null
    check (category in ('studying', 'exercises', 'reading', 'hobbies')),
  color_value bigint not null,
  total_seconds integer not null default 0,
  goal_seconds integer not null default 0,
  current_pages integer not null default 0,
  goal_pages integer not null default 0,
  notes text not null default '',
  icon_name text not null default '',
  rest_minutes integer not null default 5,
  focus_session_count integer not null default 1,
  wallpaper_index integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, id)
);

create table if not exists public.daily_goals (
  id text not null,
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  color_value bigint not null,
  target_days integer not null default 0,
  completed_dates text[] not null default '{}',
  goal_type text not null default 'total'
    check (goal_type in ('daily', 'total')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, id)
);

create table if not exists public.schedule_entries (
  id text not null,
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  weekday integer not null check (weekday between 1 and 7),
  start_minutes integer check (
    start_minutes is null or start_minutes between 0 and 1439
  ),
  end_minutes integer check (
    end_minutes is null or end_minutes between 0 and 1440
  ),
  color_value bigint not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, id)
);

create table if not exists public.group_image_messages (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  image_base64 text not null,
  created_at timestamptz not null default now()
);

create index if not exists friendships_requester_idx
  on public.friendships(requester_id);
create index if not exists friendships_addressee_idx
  on public.friendships(addressee_id);
create index if not exists group_members_user_idx
  on public.group_members(user_id);
create index if not exists activity_entries_user_period_idx
  on public.activity_entries(user_id, occurred_at);
create index if not exists user_subjects_user_category_idx
  on public.user_subjects(user_id, category);
create index if not exists daily_goals_user_idx
  on public.daily_goals(user_id);
create index if not exists schedule_entries_user_weekday_idx
  on public.schedule_entries(user_id, weekday, start_minutes);
create index if not exists group_image_messages_group_created_idx
  on public.group_image_messages(group_id, created_at);

create or replace view public.user_progress_metrics
with (security_invoker = true) as
select
  p.id as user_id,
  subject_metrics.total_focus_seconds::integer,
  subject_metrics.studying_seconds::integer,
  subject_metrics.exercises_seconds::integer,
  subject_metrics.reading_seconds::integer,
  subject_metrics.hobbies_seconds::integer,
  subject_metrics.pages_read::integer,
  subject_metrics.focus_goal_seconds::integer,
  subject_metrics.reading_goal_pages::integer,
  goal_metrics.completed_goal_days::integer,
  goal_metrics.goals_count::integer,
  subject_metrics.subjects_count::integer,
  coalesce(month_activity.focus_seconds, 0)::integer as month_focus_seconds,
  coalesce(month_activity.sessions, 0)::integer as month_sessions,
  coalesce(month_activity.pages, 0)::integer as month_pages,
  coalesce(month_activity.completed_tasks, 0)::integer
    as month_completed_tasks
from public.profiles p
left join lateral (
  select
    coalesce(sum(s.total_seconds), 0) as total_focus_seconds,
    coalesce(
      sum(s.total_seconds) filter (where s.category = 'studying'),
      0
    ) as studying_seconds,
    coalesce(
      sum(s.total_seconds) filter (where s.category = 'exercises'),
      0
    ) as exercises_seconds,
    coalesce(
      sum(s.total_seconds) filter (where s.category = 'reading'),
      0
    ) as reading_seconds,
    coalesce(
      sum(s.total_seconds) filter (where s.category = 'hobbies'),
      0
    ) as hobbies_seconds,
    coalesce(sum(s.current_pages), 0) as pages_read,
    coalesce(sum(s.goal_seconds), 0) as focus_goal_seconds,
    coalesce(sum(s.goal_pages), 0) as reading_goal_pages,
    count(*) as subjects_count
  from public.user_subjects s
  where s.user_id = p.id
) subject_metrics on true
left join lateral (
  select
    coalesce(sum(cardinality(g.completed_dates)), 0) as completed_goal_days,
    count(*) as goals_count
  from public.daily_goals g
  where g.user_id = p.id
) goal_metrics on true
left join lateral (
  select
    coalesce(sum(a.seconds), 0) as focus_seconds,
    count(*) filter (where a.seconds > 0) as sessions,
    coalesce(sum(a.pages), 0) as pages,
    coalesce(sum(a.completed_tasks), 0) as completed_tasks
  from public.activity_entries a
  where a.user_id = p.id
    and a.occurred_at >= date_trunc('month', now())
) month_activity on true
where p.id = auth.uid();

create or replace function public.are_friends(user_a uuid, user_b uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.friendships f
    where f.status = 'accepted'
      and (
        f.requester_id = user_a and f.addressee_id = user_b
        or f.requester_id = user_b and f.addressee_id = user_a
      )
  );
$$;

create or replace function public.is_group_member(
  target_group_id uuid,
  target_user_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.group_members gm
    where gm.group_id = target_group_id
      and gm.user_id = target_user_id
  );
$$;

create or replace function public.share_group(user_a uuid, user_b uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.group_members a
    join public.group_members b on b.group_id = a.group_id
    where a.user_id = user_a
      and b.user_id = user_b
  );
$$;

create or replace function public.owns_group(
  target_group_id uuid,
  target_user_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.groups g
    where g.id = target_group_id
      and g.owner_id = target_user_id
  );
$$;

create or replace function public.search_friend_candidates(
  search_text text default '',
  result_limit integer default 12
)
returns table (
  id uuid,
  user_name text,
  nick_name text,
  friend_code text,
  accent_color_value bigint
)
language sql
stable
security definer
set search_path = public
as $$
  select
    p.id,
    p.user_name,
    p.nick_name,
    p.friend_code,
    p.accent_color_value
  from public.profiles p
  where p.id <> auth.uid()
    and not exists (
      select 1
      from public.friendships f
      where f.status in ('pending', 'accepted')
        and (
          f.requester_id = auth.uid() and f.addressee_id = p.id
          or f.requester_id = p.id and f.addressee_id = auth.uid()
        )
    )
    and (
      coalesce(nullif(trim(search_text), ''), '') = ''
      or p.user_name ilike '%' || replace(trim(search_text), '@', '') || '%'
      or p.nick_name ilike '%' || replace(trim(search_text), '@', '') || '%'
      or p.friend_code ilike '%' || replace(trim(search_text), '@', '') || '%'
    )
  order by p.created_at desc
  limit greatest(1, least(coalesce(result_limit, 12), 30));
$$;

grant execute on function public.search_friend_candidates(text, integer)
to authenticated;

create or replace function public.find_profile_by_friend_code(lookup_code text)
returns table (
  id uuid,
  user_name text,
  nick_name text,
  friend_code text,
  accent_color_value bigint
)
language sql
stable
security definer
set search_path = public
as $$
  select
    p.id,
    p.user_name,
    p.nick_name,
    p.friend_code,
    p.accent_color_value
  from public.profiles p
  where p.id <> auth.uid()
    and upper(p.friend_code) = upper(replace(trim(lookup_code), '@', ''))
    and not exists (
      select 1
      from public.friendships f
      where f.status in ('pending', 'accepted')
        and (
          f.requester_id = auth.uid() and f.addressee_id = p.id
          or f.requester_id = p.id and f.addressee_id = auth.uid()
        )
    )
  limit 1;
$$;

grant execute on function public.find_profile_by_friend_code(text)
to authenticated;

create or replace function public.create_group_with_members(
  group_name text,
  group_theme text,
  invited_friend_ids uuid[]
)
returns table (
  id uuid,
  owner_id uuid,
  name text,
  theme text,
  invite_code text,
  privacy text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  new_group_id uuid;
  new_invite_code text;
begin
  if current_user_id is null then
    raise exception 'User must be authenticated to create a group.'
      using errcode = '28000';
  end if;

  if coalesce(array_length(invited_friend_ids, 1), 0) < 1 then
    raise exception 'A group requires at least one invited friend.'
      using errcode = '23514';
  end if;

  if exists (
    select 1
    from unnest(invited_friend_ids) invited_id
    where not public.are_friends(current_user_id, invited_id)
  ) then
    raise exception 'Only accepted friends can be invited to a group.'
      using errcode = '42501';
  end if;

  new_invite_code :=
    'H' || upper(substr(md5(random()::text || clock_timestamp()::text), 1, 10));

  insert into public.groups (owner_id, name, theme, invite_code, privacy)
  values (
    current_user_id,
    trim(group_name),
    group_theme,
    new_invite_code,
    'inviteOnly'
  )
  returning groups.id into new_group_id;

  insert into public.group_members (group_id, user_id, role)
  values (new_group_id, current_user_id, 'owner');

  insert into public.group_members (group_id, user_id, role)
  select new_group_id, invited_id, 'member'
  from unnest(invited_friend_ids) invited_id
  on conflict do nothing;

  return query
  select
    g.id,
    g.owner_id,
    g.name,
    g.theme,
    g.invite_code,
    g.privacy,
    g.created_at
  from public.groups g
  where g.id = new_group_id;
end;
$$;

grant execute on function public.create_group_with_members(text, text, uuid[])
to authenticated;

alter table public.profiles enable row level security;
alter table public.friendships enable row level security;
alter table public.groups enable row level security;
alter table public.group_members enable row level security;
alter table public.activity_entries enable row level security;
alter table public.user_subjects enable row level security;
alter table public.daily_goals enable row level security;
alter table public.schedule_entries enable row level security;
alter table public.group_image_messages enable row level security;

drop policy if exists "profiles are visible to self, friends, and group peers"
on public.profiles;
drop policy if exists "users insert own profile" on public.profiles;
drop policy if exists "users update own profile" on public.profiles;
drop policy if exists "users see own friendships" on public.friendships;
drop policy if exists "users request friendships" on public.friendships;
drop policy if exists "users answer received friendships" on public.friendships;
drop policy if exists "users delete own friendships" on public.friendships;
drop policy if exists "members see their groups" on public.groups;
drop policy if exists "users create owned groups" on public.groups;
drop policy if exists "owners update groups" on public.groups;
drop policy if exists "owners delete groups" on public.groups;
drop policy if exists "members see group memberships" on public.group_members;
drop policy if exists "owners add group members" on public.group_members;
drop policy if exists "owners remove group members" on public.group_members;
drop policy if exists "users leave their groups" on public.group_members;
drop policy if exists "users see activity from group peers"
on public.activity_entries;
drop policy if exists "users insert own activity" on public.activity_entries;
drop policy if exists "users manage own activity" on public.activity_entries;
drop policy if exists "users delete own activity" on public.activity_entries;
drop policy if exists "users manage own subjects" on public.user_subjects;
drop policy if exists "users manage own goals" on public.daily_goals;
drop policy if exists "users manage own schedule entries"
on public.schedule_entries;

drop policy if exists "users read own subjects" on public.user_subjects;
drop policy if exists "users insert own subjects" on public.user_subjects;
drop policy if exists "users update own subjects" on public.user_subjects;
drop policy if exists "users delete own subjects" on public.user_subjects;
drop policy if exists "users read own goals" on public.daily_goals;
drop policy if exists "users insert own goals" on public.daily_goals;
drop policy if exists "users update own goals" on public.daily_goals;
drop policy if exists "users delete own goals" on public.daily_goals;
drop policy if exists "users read own schedule entries"
on public.schedule_entries;
drop policy if exists "users insert own schedule entries"
on public.schedule_entries;
drop policy if exists "users update own schedule entries"
on public.schedule_entries;
drop policy if exists "users delete own schedule entries"
on public.schedule_entries;
drop policy if exists "members read group image messages"
on public.group_image_messages;
drop policy if exists "members insert own group image messages"
on public.group_image_messages;

create policy "profiles are visible to self, friends, and group peers"
on public.profiles for select
using (
  id = auth.uid()
  or public.are_friends(auth.uid(), profiles.id)
  or public.share_group(auth.uid(), profiles.id)
);

create policy "users insert own profile"
on public.profiles for insert
with check (id = auth.uid());

create policy "users update own profile"
on public.profiles for update
using (id = auth.uid())
with check (id = auth.uid());

create policy "users see own friendships"
on public.friendships for select
using (requester_id = auth.uid() or addressee_id = auth.uid());

create policy "users request friendships"
on public.friendships for insert
with check (requester_id = auth.uid());

create policy "users answer received friendships"
on public.friendships for update
using (addressee_id = auth.uid())
with check (addressee_id = auth.uid());

create policy "users delete own friendships"
on public.friendships for delete
using (requester_id = auth.uid() or addressee_id = auth.uid());

create policy "members see their groups"
on public.groups for select
using (public.is_group_member(groups.id, auth.uid()));

create policy "users create owned groups"
on public.groups for insert
with check (owner_id = auth.uid());

create policy "owners update groups"
on public.groups for update
using (owner_id = auth.uid())
with check (owner_id = auth.uid());

create policy "owners delete groups"
on public.groups for delete
using (owner_id = auth.uid());

create policy "members see group memberships"
on public.group_members for select
using (public.is_group_member(group_members.group_id, auth.uid()));

create policy "owners add group members"
on public.group_members for insert
with check (public.owns_group(group_members.group_id, auth.uid()));

create policy "owners remove group members"
on public.group_members for delete
using (public.owns_group(group_members.group_id, auth.uid()));

create policy "users leave their groups"
on public.group_members for delete
using (user_id = auth.uid());

create policy "users see activity from group peers"
on public.activity_entries for select
using (
  user_id = auth.uid()
  or public.share_group(auth.uid(), activity_entries.user_id)
);

create policy "users insert own activity"
on public.activity_entries for insert
with check (user_id = auth.uid());

create policy "users manage own activity"
on public.activity_entries for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "users delete own activity"
on public.activity_entries for delete
using (user_id = auth.uid());

create policy "users read own subjects"
on public.user_subjects for select
using (user_id = auth.uid());

create policy "users insert own subjects"
on public.user_subjects for insert
with check (user_id = auth.uid());

create policy "users update own subjects"
on public.user_subjects for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "users delete own subjects"
on public.user_subjects for delete
using (user_id = auth.uid());

create policy "users read own goals"
on public.daily_goals for select
using (user_id = auth.uid());

create policy "users insert own goals"
on public.daily_goals for insert
with check (user_id = auth.uid());

create policy "users update own goals"
on public.daily_goals for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "users delete own goals"
on public.daily_goals for delete
using (user_id = auth.uid());

create policy "users read own schedule entries"
on public.schedule_entries for select
using (user_id = auth.uid());

create policy "users insert own schedule entries"
on public.schedule_entries for insert
with check (user_id = auth.uid());

create policy "users update own schedule entries"
on public.schedule_entries for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "users delete own schedule entries"
on public.schedule_entries for delete
using (user_id = auth.uid());

create policy "members read group image messages"
on public.group_image_messages for select
using (public.is_group_member(group_image_messages.group_id, auth.uid()));

create policy "members insert own group image messages"
on public.group_image_messages for insert
with check (
  sender_id = auth.uid()
  and public.is_group_member(group_image_messages.group_id, auth.uid())
);

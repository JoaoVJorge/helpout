create extension if not exists pgcrypto;

create or replace function public.generate_friend_code()
returns text
language sql
as $$
  select upper(substr(encode(gen_random_bytes(6), 'hex'), 1, 10));
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
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

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

create index if not exists friendships_requester_idx
  on public.friendships(requester_id);
create index if not exists friendships_addressee_idx
  on public.friendships(addressee_id);
create index if not exists group_members_user_idx
  on public.group_members(user_id);
create index if not exists activity_entries_user_period_idx
  on public.activity_entries(user_id, occurred_at);

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

alter table public.profiles enable row level security;
alter table public.friendships enable row level security;
alter table public.groups enable row level security;
alter table public.group_members enable row level security;
alter table public.activity_entries enable row level security;

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
drop policy if exists "users see activity from group peers"
on public.activity_entries;
drop policy if exists "users insert own activity" on public.activity_entries;
drop policy if exists "users manage own activity" on public.activity_entries;
drop policy if exists "users delete own activity" on public.activity_entries;

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
with check (
  exists (
    select 1
    from public.groups g
    where g.id = group_members.group_id
      and g.owner_id = auth.uid()
  )
);

create policy "owners remove group members"
on public.group_members for delete
using (
  exists (
    select 1
    from public.groups g
    where g.id = group_members.group_id
      and g.owner_id = auth.uid()
  )
);

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

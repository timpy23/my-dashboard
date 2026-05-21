-- ============================================================
--  Personal Dashboard — Supabase Schema
--  Run this in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================

-- Enable UUID generation
create extension if not exists "pgcrypto";


-- ============================================================
-- HEALTH
-- ============================================================
create table if not exists health (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users(id) on delete cascade,
  date        date not null default current_date,
  steps       integer default 0,
  water       integer default 0,   -- glasses
  weight      numeric(5,2),        -- kg
  mood        smallint check (mood between 1 and 10),
  notes       text,
  created_at  timestamptz default now()
);

alter table health enable row level security;

create policy "Users can manage their own health data"
  on health for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index health_user_date on health(user_id, date desc);


-- ============================================================
-- SLEEP
-- ============================================================
create table if not exists sleep (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users(id) on delete cascade,
  date        date not null default current_date,
  hours       numeric(4,1),
  bedtime     time,
  wake_time   time,
  quality     smallint check (quality between 1 and 5),
  created_at  timestamptz default now()
);

alter table sleep enable row level security;

create policy "Users can manage their own sleep data"
  on sleep for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index sleep_user_date on sleep(user_id, date desc);


-- ============================================================
-- GOALS
-- ============================================================
create table if not exists goals (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users(id) on delete cascade,
  title       text not null,
  category    text default 'Personal',
  target      numeric(10,2) not null default 100,
  current     numeric(10,2) not null default 0,
  unit        text default '',
  deadline    date,
  done        boolean default false,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

alter table goals enable row level security;

create policy "Users can manage their own goals"
  on goals for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index goals_user_id on goals(user_id);


-- ============================================================
-- TODOS
-- ============================================================
create table if not exists todos (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users(id) on delete cascade,
  text        text not null,
  priority    text default 'med' check (priority in ('high', 'med', 'low')),
  due_date    date,
  project     text default '',
  done        boolean default false,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

alter table todos enable row level security;

create policy "Users can manage their own todos"
  on todos for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index todos_user_done on todos(user_id, done);


-- ============================================================
-- PROJECTS
-- ============================================================
create table if not exists projects (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users(id) on delete cascade,
  name        text not null,
  description text default '',
  status      text default 'active' check (status in ('active', 'paused', 'done')),
  progress    smallint default 0 check (progress between 0 and 100),
  tags        text[] default '{}',
  start_date  date,
  end_date    date,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

alter table projects enable row level security;

create policy "Users can manage their own projects"
  on projects for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index projects_user_status on projects(user_id, status);


-- ============================================================
-- NOTES
-- ============================================================
create table if not exists notes (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users(id) on delete cascade,
  title       text not null default 'Note',
  body        text default '',
  color       text default '#1a1a1e',
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

alter table notes enable row level security;

create policy "Users can manage their own notes"
  on notes for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index notes_user_id on notes(user_id);


-- ============================================================
-- AUTO-UPDATE updated_at ON CHANGES
-- ============================================================
create or replace function update_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger goals_updated_at    before update on goals    for each row execute function update_updated_at();
create trigger todos_updated_at    before update on todos    for each row execute function update_updated_at();
create trigger projects_updated_at before update on projects for each row execute function update_updated_at();
create trigger notes_updated_at    before update on notes    for each row execute function update_updated_at();


-- ============================================================
-- DONE — all tables created with RLS policies
-- ============================================================
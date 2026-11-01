-- Stackle database. Paste this whole file into the Supabase SQL editor and press Run.
-- Two tables: scores (public leaderboard) and feedback (only you can read it).

create table if not exists public.scores (
  id          bigint generated always as identity primary key,
  created_at  timestamptz not null default now(),
  mode        text not null check (mode in ('endless', 'daily')),
  day         text not null check (day ~ '^\d{4}-\d{2}-\d{2}$'),   -- player's local date of the run
  name        text not null check (char_length(name) between 1 and 12),
  score       int  not null check (score between 0 and 1000),
  perfects    int  not null default 0 check (perfects between 0 and 1000),
  device_id   uuid not null
);
create index if not exists scores_leaderboard on public.scores (mode, day, score desc);
create index if not exists scores_endless on public.scores (mode, score desc);

create table if not exists public.feedback (
  id          bigint generated always as identity primary key,
  created_at  timestamptz not null default now(),
  message     text not null check (char_length(message) between 1 and 1000),
  score       int,
  device_id   uuid,
  user_agent  text
);

-- Row level security: the game uses the public anon key, so lock down what it can do.
alter table public.scores   enable row level security;
alter table public.feedback enable row level security;

drop policy if exists "anyone can post a score"   on public.scores;
drop policy if exists "anyone can read scores"    on public.scores;
drop policy if exists "anyone can send feedback"  on public.feedback;

create policy "anyone can post a score"  on public.scores   for insert to anon with check (true);
create policy "anyone can read scores"   on public.scores   for select to anon using (true);
create policy "anyone can send feedback" on public.feedback for insert to anon with check (true);
-- No select policy on feedback: players cannot read each other's messages. You read them in the Table Editor.

-- Handy views for you (run in the SQL editor any time):
--   select day, name, score, perfects from scores where mode='daily' order by day desc, score desc;
--   select created_at, score, message from feedback order by created_at desc;
--   select count(distinct device_id) as players, count(*) as runs from scores;

-- Rocket Message v15 — Templates & Variables
-- Run in Supabase SQL Editor (after supabase_schema.sql).
-- Each user manages their own message templates and personalization
-- variables. No admin override — these are private per-account.

create extension if not exists pgcrypto;

-- ── message_templates ────────────────────────────────────────────
create table if not exists public.message_templates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  body text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.message_templates enable row level security;

drop policy if exists message_templates_select_own on public.message_templates;
drop policy if exists message_templates_insert_own on public.message_templates;
drop policy if exists message_templates_update_own on public.message_templates;
drop policy if exists message_templates_delete_own on public.message_templates;

create policy message_templates_select_own
on public.message_templates for select to authenticated
using (user_id = auth.uid());

create policy message_templates_insert_own
on public.message_templates for insert to authenticated
with check (user_id = auth.uid());

create policy message_templates_update_own
on public.message_templates for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy message_templates_delete_own
on public.message_templates for delete to authenticated
using (user_id = auth.uid());

create index if not exists message_templates_user_idx
  on public.message_templates(user_id, created_at);

-- Keep updated_at current on edits.
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists message_templates_set_updated_at on public.message_templates;
create trigger message_templates_set_updated_at
before update on public.message_templates
for each row execute function public.set_updated_at();

-- ── message_variables ────────────────────────────────────────────
create table if not exists public.message_variables (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  key text not null,
  value text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.message_variables enable row level security;

-- One value per variable name per user; also what upsert(onConflict:'user_id,key') relies on.
create unique index if not exists message_variables_user_key_unique
  on public.message_variables(user_id, key);

drop policy if exists message_variables_select_own on public.message_variables;
drop policy if exists message_variables_insert_own on public.message_variables;
drop policy if exists message_variables_update_own on public.message_variables;
drop policy if exists message_variables_delete_own on public.message_variables;

create policy message_variables_select_own
on public.message_variables for select to authenticated
using (user_id = auth.uid());

create policy message_variables_insert_own
on public.message_variables for insert to authenticated
with check (user_id = auth.uid());

create policy message_variables_update_own
on public.message_variables for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy message_variables_delete_own
on public.message_variables for delete to authenticated
using (user_id = auth.uid());

drop trigger if exists message_variables_set_updated_at on public.message_variables;
create trigger message_variables_set_updated_at
before update on public.message_variables
for each row execute function public.set_updated_at();

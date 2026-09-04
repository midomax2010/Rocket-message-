-- WhatsApp Campaign v11
-- Run in Supabase SQL Editor.
-- Admin: midomax2010@gmail.com can read/manage all contacts.
-- Other users can read/manage only their own contacts.

create extension if not exists pgcrypto;

alter table public.contacts enable row level security;

alter table public.contacts
  add column if not exists opted_in boolean not null default false,
  add column if not exists opted_out boolean not null default false,
  add column if not exists last_contacted_at timestamptz,
  add column if not exists send_count integer not null default 0;

create unique index if not exists contacts_user_phone_unique
  on public.contacts(user_id, phone);

-- Remove conflicting old policies if they exist.
drop policy if exists contacts_select_own on public.contacts;
drop policy if exists contacts_insert_own on public.contacts;
drop policy if exists contacts_update_own on public.contacts;
drop policy if exists contacts_delete_own on public.contacts;
drop policy if exists contacts_select on public.contacts;
drop policy if exists contacts_insert on public.contacts;
drop policy if exists contacts_update on public.contacts;
drop policy if exists contacts_delete on public.contacts;

create policy contacts_select_v11
on public.contacts for select to authenticated
using (
  user_id = auth.uid()
  or lower(coalesce(auth.jwt()->>'email','')) = 'midomax2010@gmail.com'
);

create policy contacts_insert_v11
on public.contacts for insert to authenticated
with check (user_id = auth.uid());

create policy contacts_update_v11
on public.contacts for update to authenticated
using (
  user_id = auth.uid()
  or lower(coalesce(auth.jwt()->>'email','')) = 'midomax2010@gmail.com'
)
with check (
  user_id = auth.uid()
  or lower(coalesce(auth.jwt()->>'email','')) = 'midomax2010@gmail.com'
);

create policy contacts_delete_v11
on public.contacts for delete to authenticated
using (
  user_id = auth.uid()
  or lower(coalesce(auth.jwt()->>'email','')) = 'midomax2010@gmail.com'
);

create table if not exists public.contact_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  contact_id uuid references public.contacts(id) on delete set null,
  event_type text not null,
  created_at timestamptz not null default now()
);

alter table public.contact_events enable row level security;
drop policy if exists contact_events_select_own on public.contact_events;
drop policy if exists contact_events_insert_own on public.contact_events;
create policy contact_events_select_v11 on public.contact_events for select to authenticated
using (user_id = auth.uid() or lower(coalesce(auth.jwt()->>'email','')) = 'midomax2010@gmail.com');
create policy contact_events_insert_v11 on public.contact_events for insert to authenticated
with check (user_id = auth.uid());

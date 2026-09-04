-- WhatsApp Campaign Web v9 Safe Mode
-- Run in Supabase SQL Editor after the existing schema.

alter table public.contacts
  add column if not exists opted_in boolean not null default false,
  add column if not exists opted_out boolean not null default false,
  add column if not exists last_contacted_at timestamptz,
  add column if not exists send_count integer not null default 0;

create index if not exists contacts_opted_in_idx on public.contacts(user_id, opted_in, opted_out);

-- Optional campaign/contact event log. It stores only the authenticated user's own events.
create table if not exists public.contact_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  contact_id uuid references public.contacts(id) on delete cascade,
  event_type text not null check (event_type in ('opened','sent_manual','opted_out','blocked','unblocked')),
  created_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb
);
create index if not exists contact_events_user_idx on public.contact_events(user_id, created_at desc);

alter table public.contact_events enable row level security;
drop policy if exists "contact_events_select_own" on public.contact_events;
drop policy if exists "contact_events_insert_own" on public.contact_events;
create policy "contact_events_select_own" on public.contact_events for select using (auth.uid() = user_id);
create policy "contact_events_insert_own" on public.contact_events for insert with check (auth.uid() = user_id);

-- Keep the existing contacts RLS policies. Never expose service_role keys in the browser.

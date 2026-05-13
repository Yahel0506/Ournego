-- Phase 1 - Map search/visits analytics foundation
-- Tracks business interactions with source and timestamp.

create extension if not exists pgcrypto;

create table if not exists public.user_interactions (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(business_id) on delete cascade,
  user_id uuid null references auth.users(id) on delete set null,
  interaction_type text not null check (
    interaction_type in (
      'view_business_profile',
      'open_contact',
      'open_catalog',
      'open_reviews',
      'share_business'
    )
  ),
  source text not null check (
    source in (
      'map',
      'search',
      'deeplink',
      'share_link',
      'category_filter',
      'unknown'
    )
  ),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_user_interactions_business_created_at
  on public.user_interactions (business_id, created_at desc);

create index if not exists idx_user_interactions_type_source_created_at
  on public.user_interactions (interaction_type, source, created_at desc);

create index if not exists idx_user_interactions_user_created_at
  on public.user_interactions (user_id, created_at desc);

alter table public.user_interactions enable row level security;

-- Public read so map ranking can aggregate visit signals client-side.
drop policy if exists "user_interactions_select_public" on public.user_interactions;
create policy "user_interactions_select_public"
on public.user_interactions
for select
to anon, authenticated
using (true);

-- Public insert, user_id can be null for guests.
drop policy if exists "user_interactions_insert_public" on public.user_interactions;
create policy "user_interactions_insert_public"
on public.user_interactions
for insert
to anon, authenticated
with check (true);

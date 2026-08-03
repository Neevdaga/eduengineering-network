-- EduEngineering Network — Database Setup
-- Run this ONCE in Supabase: Project → SQL Editor → New Query → paste all of this → Run

-- ============================================================
-- STEP 0: Set your master admin email
-- Replace the email below with YOUR login email (the one you'll
-- use to sign into Supabase auth for this site).
-- ============================================================
create table if not exists app_config (
  key text primary key,
  value text not null
);
insert into app_config (key, value) values ('master_admin_email', 'neevdaga@gmail.com')
  on conflict (key) do update set value = excluded.value;

-- ============================================================
-- TABLES
-- ============================================================
create table if not exists schools (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references auth.users(id) not null,
  name text not null,
  slug text unique not null,
  contact_name text,
  contact_email text,
  status text not null default 'pending' check (status in ('pending','approved','denied')),
  created_at timestamptz not null default now()
);

create table if not exists requests (
  id uuid primary key default gen_random_uuid(),
  school_id uuid references schools(id) not null,
  requester_name text not null,
  contact text not null,
  item_request text not null,
  needed_by date,
  status text not null default 'new' check (status in ('new','in_progress','done','declined')),
  created_at timestamptz not null default now()
);

-- ============================================================
-- HELPER: is the current logged-in user the master admin?
-- ============================================================
create or replace function is_master_admin()
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from app_config
    where key = 'master_admin_email'
    and value = auth.email()
  );
$$;

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
alter table schools enable row level security;
alter table requests enable row level security;

-- SCHOOLS policies
create policy "schools_select_own_or_master"
  on schools for select
  using (owner_id = auth.uid() or is_master_admin());

create policy "schools_insert_own"
  on schools for insert
  with check (owner_id = auth.uid());

create policy "schools_update_own_details_or_master_status"
  on schools for update
  using (owner_id = auth.uid() or is_master_admin())
  with check (owner_id = auth.uid() or is_master_admin());

-- REQUESTS policies
-- Anyone (even logged out) can submit a request to an approved school
create policy "requests_insert_public"
  on requests for insert
  to anon, authenticated
  with check (
    exists (select 1 from schools where id = school_id and status = 'approved')
  );

-- Only that school's owner or the master admin can view requests
create policy "requests_select_owner_or_master"
  on requests for select
  using (
    exists (select 1 from schools where schools.id = requests.school_id and schools.owner_id = auth.uid())
    or is_master_admin()
  );

-- Only that school's owner or the master admin can update status
create policy "requests_update_owner_or_master"
  on requests for update
  using (
    exists (select 1 from schools where schools.id = requests.school_id and schools.owner_id = auth.uid())
    or is_master_admin()
  );

-- Public needs to be able to read basic APPROVED school info (name/slug) to fill out the request form
create policy "schools_select_public_approved"
  on schools for select
  to anon
  using (status = 'approved');

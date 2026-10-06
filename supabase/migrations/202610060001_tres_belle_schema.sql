begin;
create extension if not exists btree_gist;
create type public.app_role as enum ('patient','doctor','staff','admin');
create type public.appointment_status as enum ('pending','confirmed','checked_in','in_progress','completed','cancelled_by_patient','cancelled_by_clinic','no_show');
create type public.payment_status as enum ('unpaid','deposit_pending','deposit_paid','paid','refunded','waived');

create table public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 role public.app_role not null default 'patient', first_name text, last_name text,
 phone text, avatar_url text, active boolean not null default true,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.patient_details (
 user_id uuid primary key references public.profiles(id) on delete cascade,
 birth_date date, sex_at_birth text, address text,
 emergency_contact_name text, emergency_contact_phone text,
 allergies text, medical_conditions text, current_medications text,
 privacy_consent_at timestamptz, marketing_consent boolean not null default false,
 updated_at timestamptz not null default now()
);
create table public.doctors (
 user_id uuid primary key references public.profiles(id) on delete restrict,
 slug text not null unique, display_name text not null, credentials text not null,
 specialty text not null, biography text, license_number text, image_path text,
 buffer_minutes int not null default 10 check(buffer_minutes between 0 and 120),
 accepting_appointments boolean not null default true
);
create table public.locations (
 id uuid primary key default gen_random_uuid(), name text not null,
 timezone text not null default 'Asia/Manila', address text not null,
 city text not null, province text not null, postal_code text,
 phone text, email text, latitude numeric(9,6), longitude numeric(9,6),
 active boolean not null default true
);
create table public.service_categories (
 id uuid primary key default gen_random_uuid(), name text not null unique,
 slug text not null unique, sort_order int not null default 0
);
create table public.services (
 id uuid primary key default gen_random_uuid(),
 category_id uuid references public.service_categories(id) on delete set null,
 name text not null, slug text not null unique, description text,
 duration_minutes int not null check(duration_minutes between 5 and 480),
 cleanup_minutes int not null default 0, requires_consultation boolean not null default true,
 active boolean not null default true
);
create table public.service_prices (
 id uuid primary key default gen_random_uuid(),
 service_id uuid not null references public.services(id) on delete cascade,
 amount numeric(12,2) not null check(amount>=0), promotional_amount numeric(12,2),
 currency char(3) not null default 'PHP', unit text not null default 'session',
 starting_price boolean not null default false, valid_from timestamptz not null default now(),
 valid_until timestamptz, check(valid_until is null or valid_until>valid_from)
);
create unique index one_current_price on public.service_prices(service_id) where valid_until is null;
create table public.doctor_services (
 doctor_id uuid references public.doctors(user_id) on delete cascade,
 service_id uuid references public.services(id) on delete cascade,
 custom_duration_minutes int, active boolean not null default true,
 primary key(doctor_id,service_id)
);
create table public.doctor_schedule_rules (
 id uuid primary key default gen_random_uuid(),
 doctor_id uuid not null references public.doctors(user_id) on delete cascade,
 location_id uuid not null references public.locations(id) on delete cascade,
 iso_day smallint not null check(iso_day between 1 and 7),
 start_time time not null, end_time time not null, slot_minutes int not null default 30,
 effective_from date not null default current_date, effective_until date,
 active boolean not null default true, check(end_time>start_time)
);
create table public.doctor_schedule_exceptions (
 id uuid primary key default gen_random_uuid(),
 doctor_id uuid not null references public.doctors(user_id) on delete cascade,
 location_id uuid references public.locations(id), available boolean not null default false,
 starts_at timestamptz not null, ends_at timestamptz not null, reason text,
 created_by uuid references public.profiles(id), check(ends_at>starts_at)
);
create table public.appointments (
 id uuid primary key default gen_random_uuid(), reference_code text not null unique,
 patient_id uuid not null references public.patient_details(user_id),
 doctor_id uuid not null references public.doctors(user_id),
 service_id uuid not null references public.services(id),
 service_price_id uuid references public.service_prices(id),
 location_id uuid not null references public.locations(id),
 starts_at timestamptz not null, ends_at timestamptz not null,
 status public.appointment_status not null default 'pending',
 payment_status public.payment_status not null default 'unpaid',
 quoted_amount numeric(12,2), currency char(3) not null default 'PHP',
 patient_notes text, internal_notes text, cancellation_reason text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 check(ends_at>starts_at)
);
alter table public.appointments add constraint no_doctor_double_booking exclude using gist
 (doctor_id with =,tstzrange(starts_at,ends_at,'[)') with &&)
 where(status in('pending','confirmed','checked_in','in_progress'));
create index appointments_patient_date on public.appointments(patient_id,starts_at desc);
create index appointments_doctor_date on public.appointments(doctor_id,starts_at);
create table public.appointment_history (
 id bigint generated always as identity primary key,
 appointment_id uuid not null references public.appointments(id) on delete cascade,
 from_status public.appointment_status, to_status public.appointment_status not null,
 changed_by uuid references public.profiles(id), note text,
 changed_at timestamptz not null default now()
);

-- Safe role helper: authorization is stored in public.profiles, not editable user metadata.
create function public.has_role(required public.app_role) returns boolean
language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.profiles where id=(select auth.uid()) and role=required and active);
$$;
create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 insert into public.profiles(id,first_name,last_name,phone)
 values(new.id,new.raw_user_meta_data->>'first_name',new.raw_user_meta_data->>'last_name',new.phone);
 return new;
end; $$;
create trigger on_auth_user_created after insert on auth.users
for each row execute function public.handle_new_user();
create function public.touch_updated_at() returns trigger language plpgsql as $$
begin new.updated_at=now(); return new; end $$;
create trigger profiles_touch before update on public.profiles for each row execute function public.touch_updated_at();
create trigger patients_touch before update on public.patient_details for each row execute function public.touch_updated_at();
create trigger appointments_touch before update on public.appointments for each row execute function public.touch_updated_at();

-- RLS and least-privilege grants.
alter table public.profiles enable row level security;
alter table public.patient_details enable row level security;
alter table public.doctors enable row level security;
alter table public.locations enable row level security;
alter table public.service_categories enable row level security;
alter table public.services enable row level security;
alter table public.service_prices enable row level security;
alter table public.doctor_services enable row level security;
alter table public.doctor_schedule_rules enable row level security;
alter table public.doctor_schedule_exceptions enable row level security;
alter table public.appointments enable row level security;
alter table public.appointment_history enable row level security;

revoke all on all tables in schema public from anon,authenticated;
grant select on public.doctors,public.locations,public.service_categories,public.services,public.service_prices,public.doctor_services to anon,authenticated;
grant select on public.profiles,public.patient_details to authenticated;
grant update(first_name,last_name,phone,avatar_url) on public.profiles to authenticated;
grant update(birth_date,sex_at_birth,address,emergency_contact_name,emergency_contact_phone,allergies,medical_conditions,current_medications,privacy_consent_at,marketing_consent,updated_at) on public.patient_details to authenticated;
grant insert on public.patient_details to authenticated;
grant select,insert on public.appointments to authenticated;
grant select on public.doctor_schedule_rules,public.doctor_schedule_exceptions,public.appointment_history to authenticated;

create policy "public doctors" on public.doctors for select to anon,authenticated using(true);
create policy "public locations" on public.locations for select to anon,authenticated using(active);
create policy "public categories" on public.service_categories for select to anon,authenticated using(true);
create policy "public services" on public.services for select to anon,authenticated using(active);
create policy "public prices" on public.service_prices for select to anon,authenticated using(valid_until is null or valid_until>now());
create policy "public doctor services" on public.doctor_services for select to anon,authenticated using(active);
create policy "own profile" on public.profiles for select to authenticated using((select auth.uid())=id or public.has_role('admin') or public.has_role('staff'));
create policy "update own profile" on public.profiles for update to authenticated using((select auth.uid())=id) with check((select auth.uid())=id);
create policy "own patient details" on public.patient_details for select to authenticated using((select auth.uid())=user_id or public.has_role('doctor') or public.has_role('staff') or public.has_role('admin'));
create policy "insert own patient details" on public.patient_details for insert to authenticated with check((select auth.uid())=user_id);
create policy "update own patient details" on public.patient_details for update to authenticated using((select auth.uid())=user_id) with check((select auth.uid())=user_id);
create policy "read schedules" on public.doctor_schedule_rules for select to authenticated using(true);
create policy "read exceptions" on public.doctor_schedule_exceptions for select to authenticated using(true);
create policy "read relevant appointments" on public.appointments for select to authenticated using(patient_id=(select auth.uid()) or doctor_id=(select auth.uid()) or public.has_role('staff') or public.has_role('admin'));
create policy "patients create appointments" on public.appointments for insert to authenticated with check(patient_id=(select auth.uid()));
create policy "patient or clinic updates" on public.appointments for update to authenticated using(patient_id=(select auth.uid()) or doctor_id=(select auth.uid()) or public.has_role('staff') or public.has_role('admin'));
create policy "read relevant history" on public.appointment_history for select to authenticated using(exists(select 1 from public.appointments a where a.id=appointment_id and (a.patient_id=(select auth.uid()) or a.doctor_id=(select auth.uid()) or public.has_role('staff') or public.has_role('admin'))));

create function public.cancel_own_appointment(appointment_uuid uuid, reason text)
returns void language plpgsql security definer set search_path='' as $$
begin
 update public.appointments
 set status='cancelled_by_patient',cancellation_reason=reason,updated_at=now()
 where id=appointment_uuid and patient_id=(select auth.uid())
   and status in('pending','confirmed');
 if not found then raise exception 'Appointment cannot be cancelled'; end if;
end; $$;
revoke all on function public.cancel_own_appointment(uuid,text) from public;
grant execute on function public.cancel_own_appointment(uuid,text) to authenticated;
commit;

# Supabase setup

Apply with Supabase CLI:

    supabase db push

Authentication is owned by Supabase Auth. Patient signup automatically creates a
public profile. Do not add password, session, or reset-token tables.

Create or invite the two doctor users in Authentication > Users, then run:

    update public.profiles set role='doctor' where id='<AUTH_USER_UUID>';
    insert into public.doctors(user_id,slug,display_name,credentials,specialty,image_path)
    values ('<AUTH_USER_UUID>','dr-van-aldrin-ramos','Dr. Van Aldrin Ramos','RN MD',
    'Aesthetic Medicine & Cosmetic Surgery','/images/doctor1.png');

Repeat for Dr. Melvic Mae Roxas with her Auth UUID. Add doctor_services and
doctor_schedule_rules only after both doctor Auth users exist.

Never expose the Supabase secret/service-role key in browser code. Test all RLS
policies with patient, doctor, staff, anonymous, and service-role sessions before
production.

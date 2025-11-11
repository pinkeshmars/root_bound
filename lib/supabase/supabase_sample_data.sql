-- Helper function to insert users into auth.users table
CREATE OR REPLACE FUNCTION insert_user_to_auth(
    email text,
    password text
) RETURNS UUID AS $$
DECLARE
  user_id uuid;
  encrypted_pw text;
BEGIN
  user_id := gen_random_uuid();
  encrypted_pw := crypt(password, gen_salt('bf'));
  
  INSERT INTO auth.users
    (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES
    (gen_random_uuid(), user_id, 'authenticated', 'authenticated', email, encrypted_pw, '2023-05-03 19:41:43.585805+00', '2023-04-22 13:10:03.275387+00', '2023-04-22 13:10:31.458239+00', '{"provider":"email","providers":["email"]}', '{}', '2023-05-03 19:41:43.580424+00', '2023-05-03 19:41:43.585948+00', '', '', '', '');
  
  INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES
    (gen_random_uuid(), user_id, format('{"sub":"%s","email":"%s"}', user_id::text, email)::jsonb, 'email', '2023-05-03 19:41:43.582456+00', '2023-05-03 19:41:43.582497+00', '2023-05-03 19:41:43.582497+00');
  
  RETURN user_id;
END;
$$ LANGUAGE plpgsql;

-- Insert sample data into the 'users' table
INSERT INTO public.users (id, email, display_name, created_at, updated_at)
SELECT
    insert_user_to_auth('james.parker@yopmail.com', 'password123'),
    'james.parker@yopmail.com',
    'James Parker',
    '2023-01-15 10:00:00+00',
    '2023-01-15 10:00:00+00';

INSERT INTO public.users (id, email, display_name, created_at, updated_at)
SELECT
    insert_user_to_auth('sarah.connor@yopmail.com', 'securepass'),
    'sarah.connor@yopmail.com',
    'Sarah Connor',
    '2023-02-20 11:30:00+00',
    '2023-02-20 11:30:00+00';

-- Insert sample data into the 'habits' table
INSERT INTO public.habits (user_id, name, icon, color, is_completed, streak, created_at, updated_at)
SELECT
    (SELECT id FROM public.users WHERE email = 'james.parker@yopmail.com'),
    'Drink 8 glasses of water',
    'water-glass',
    '#4CAF50',
    TRUE,
    25,
    '2023-01-15 10:05:00+00',
    '2023-05-03 19:41:43.585948+00';

INSERT INTO public.habits (user_id, name, icon, color, is_completed, streak, created_at, updated_at)
SELECT
    (SELECT id FROM public.users WHERE email = 'james.parker@yopmail.com'),
    'Read for 30 minutes',
    'book-open',
    '#2196F3',
    FALSE,
    10,
    '2023-01-16 09:00:00+00',
    '2023-05-02 18:00:00+00';

INSERT INTO public.habits (user_id, name, icon, color, is_completed, streak, created_at, updated_at)
SELECT
    (SELECT id FROM public.users WHERE email = 'james.parker@yopmail.com'),
    'Exercise for 45 minutes',
    'dumbbell',
    '#FFC107',
    TRUE,
    5,
    '2023-01-17 07:30:00+00',
    '2023-05-03 19:41:43.585948+00';

INSERT INTO public.habits (user_id, name, icon, color, is_completed, streak, created_at, updated_at)
SELECT
    (SELECT id FROM public.users WHERE email = 'sarah.connor@yopmail.com'),
    'Meditate for 15 minutes',
    'lotus',
    '#9C27B0',
    TRUE,
    30,
    '2023-02-20 11:35:00+00',
    '2023-05-03 19:41:43.585948+00';

INSERT INTO public.habits (user_id, name, icon, color, is_completed, streak, created_at, updated_at)
SELECT
    (SELECT id FROM public.users WHERE email = 'sarah.connor@yopmail.com'),
    'Learn a new language',
    'language',
    '#00BCD4',
    FALSE,
    7,
    '2023-02-21 14:00:00+00',
    '2023-05-01 10:00:00+00';

INSERT INTO public.habits (user_id, name, icon, color, is_completed, streak, created_at, updated_at)
SELECT
    (SELECT id FROM public.users WHERE email = 'sarah.connor@yopmail.com'),
    'Write in journal',
    'feather',
    '#FF5722',
    TRUE,
    15,
    '2023-02-22 20:00:00+00',
    '2023-05-03 19:41:43.585948+00';
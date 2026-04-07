-- NORWAY TRIP PLANNER - Supabase Schema

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- STOPS table
create table stops (
  id uuid primary key default uuid_generate_v4(),
  order_index integer not null,
  name text not null,
  day_label text,
  hiking_name text,
  hiking_detail text,
  hiking_difficulty text check (hiking_difficulty in ('easy','medium','hard')),
  food_store text,
  food_note text,
  drive_from_prev text,
  coordinates text,
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ACCOMMODATIONS table
create table accommodations (
  id uuid primary key default uuid_generate_v4(),
  stop_id uuid references stops(id) on delete cascade,
  name text,
  address text,
  booking_ref text,
  url text,
  price_amount numeric(10,2),
  price_currency text default 'NOK' check (price_currency in ('NOK','SEK','EUR')),
  price_type text default 'hytta' check (price_type in ('hytta','per_room','per_person')),
  num_nights integer default 1,
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- IMAGES table
create table images (
  id uuid primary key default uuid_generate_v4(),
  stop_id uuid references stops(id) on delete cascade,
  url text not null,
  caption text,
  storage_path text,
  order_index integer default 0,
  created_at timestamptz default now()
);

-- SETTINGS table (for exchange rates etc)
create table settings (
  key text primary key,
  value text not null,
  updated_at timestamptz default now()
);

-- Insert default settings
insert into settings (key, value) values
  ('nok_sek_rate', '0.96'),
  ('eur_sek_rate', '11.20'),
  ('last_rate_fetch', '');

-- Row Level Security
alter table stops enable row level security;
alter table accommodations enable row level security;
alter table images enable row level security;
alter table settings enable row level security;

-- Public read access for all tables
create policy "Public read stops" on stops for select using (true);
create policy "Public read accommodations" on accommodations for select using (true);
create policy "Public read images" on images for select using (true);
create policy "Public read settings" on settings for select using (true);

-- Authenticated write access
create policy "Auth write stops" on stops for all using (auth.role() = 'authenticated');
create policy "Auth write accommodations" on accommodations for all using (auth.role() = 'authenticated');
create policy "Auth write images" on images for all using (auth.role() = 'authenticated');
create policy "Auth write settings" on settings for all using (auth.role() = 'authenticated');

-- Storage bucket for images
insert into storage.buckets (id, name, public) values ('trip-images', 'trip-images', true);
create policy "Public read images bucket" on storage.objects for select using (bucket_id = 'trip-images');
create policy "Auth upload images" on storage.objects for insert with check (bucket_id = 'trip-images' and auth.role() = 'authenticated');
create policy "Auth delete images" on storage.objects for delete using (bucket_id = 'trip-images' and auth.role() = 'authenticated');

-- Seed initial stops data
insert into stops (order_index, name, day_label, hiking_name, hiking_detail, hiking_difficulty, food_store, food_note, drive_from_prev) values
(1, 'Oslo', 'Dag 1', 'Vettakollen fr. Sognsvann', '9 km · 2,5 h · Oslofjordvy', 'easy', 'Rema 1000 / Kiwi', 'Finns överallt i Oslo', 'Stockholm → Oslo · E18 · ~520 km · ca 5,5 h'),
(2, 'Geilo', 'Dag 2', 'Geilohovda / sommarliften', '5,7 km · 2 h · Hardangerviddavy', 'medium', 'Rema 1000 (AMFI Geilo)', 'Begränsat – komplettera', 'Oslo → Geilo · Rv7 · ~210 km · ca 2,5 h'),
(3, 'Odda / Tyssedal', 'Dag 3', 'Husedalen – 4 vattenfall', '8 km · 3–4 h · Dramatisk dalgång', 'medium', 'Coop Prix (litet)', 'HANDLA I BERGEN ISTÄLLET', 'Geilo → Odda · Rv7/Rv13 · ~130 km · ca 2 h'),
(4, 'Bergen', 'Dag 4', 'Fløyen / Ulriken', '2–3 h · Panoramavy hela Bergen', 'easy', 'Rema 1000 / Kiwi', 'STORHANDLA HÄR – 3–4 dagar', 'Odda → Bergen · E16/E39 · ~170 km · ca 2,5 h'),
(5, 'Sogndal', 'Dag 5', 'Molden – Sognefjordsvy', '6 km · 3–4 h · Europas längsta fjord', 'medium', 'Rema 1000 (Stedjevegen)', 'Fyll på inför Geiranger', 'Bergen → Sogndal · E16 + färja · ~160 km · ca 3 h'),
(6, 'Geiranger', 'Dag 6', 'Skageflå-gården (färja + vandring)', '3–4 h · Vy ner i fjorden · UNESCO', 'medium', 'NOLLINKÖP', 'Bara dyr turisthandel', 'Sogndal → Geiranger · Trollstigen · ~220 km · ca 4 h'),
(7, 'Ålesund', 'Dag 7', 'Aksla – 418 trappsteg', '2–3 h · Vy över öarna · Art Nouveau', 'easy', 'Rema 1000 / Kiwi', 'Återfyll allt här', 'Geiranger → Ålesund · färja Hellesylt · ~110 km · ca 3 h'),
(8, 'Lillehammer', 'Dag 8', 'Nevelfjell fr. Nordseter', '9,8 km · 3 h · Rondane/Jotunheimvy', 'medium', 'Rema 1000 / Kiwi', 'Sista norska inköpet', 'Ålesund → Lillehammer · E136/E6 · ~380 km · ca 4,5 h'),
(9, 'Tällberg', 'Dag 9', 'Siljansledens höjder', '2–3 h · Dalälven & Siljansvy', 'easy', 'ICA / Coop i Leksand (~8 km)', 'Svenska priser igen!', 'Lillehammer → Tällberg · E6/väg 70 · ~390 km · ca 4,5 h');

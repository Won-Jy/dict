-- ============================================================
-- 개인 단어장 — Supabase 초기 설정
-- Supabase 대시보드 → SQL Editor 에 전체 붙여넣고 실행하세요.
-- ============================================================

-- ---------- 1. 테이블 ----------

create table if not exists public.entries (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  lang        text not null check (lang in ('en','fr','de')),
  term        text not null,
  meaning     text not null default '',
  etymology   text not null default '',
  note        text not null default '',
  audio_path  text,
  deleted_at  timestamptz,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- 같은 언어 안에서 같은 표제어 중복 방지 (휴지통에 있는 건 제외)
create unique index if not exists entries_unique_live
  on public.entries (user_id, lang, lower(term))
  where deleted_at is null;

create index if not exists entries_user_idx on public.entries (user_id, deleted_at);

create table if not exists public.examples (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  entry_id    uuid not null references public.entries(id) on delete cascade,
  text        text not null default '',
  translation text not null default '',
  sort_order  int  not null default 0,
  created_at  timestamptz not null default now()
);

create index if not exists examples_entry_idx on public.examples (entry_id);

create table if not exists public.links (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  from_id    uuid not null references public.entries(id) on delete cascade,
  to_id      uuid not null references public.entries(id) on delete cascade,
  kind       text not null check (kind in ('etym','syn','ant')),
  created_at timestamptz not null default now(),
  unique (from_id, to_id, kind)
);

create index if not exists links_from_idx on public.links (from_id);

-- ---------- 2. updated_at 자동 갱신 ----------

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists entries_touch on public.entries;
create trigger entries_touch before update on public.entries
  for each row execute function public.touch_updated_at();

-- ---------- 3. Data API 접근 권한 ----------
-- 프로젝트를 만들 때 "Automatically expose new tables"를 껐다면 이 부분이 꼭 필요합니다.
-- 켜뒀더라도 실행해서 손해 볼 것은 없습니다 (2026-10-30 이후를 대비).
-- 로그인한 사용자에게만 줍니다. 익명(anon) 역할에는 아무 권한도 주지 않습니다.

grant usage on schema public to authenticated;

grant select, insert, update, delete
  on public.entries, public.examples, public.links
  to authenticated;

-- ---------- 4. RLS (본인 데이터만) ----------

alter table public.entries  enable row level security;
alter table public.examples enable row level security;
alter table public.links    enable row level security;

drop policy if exists entries_own  on public.entries;
drop policy if exists examples_own on public.examples;
drop policy if exists links_own    on public.links;

create policy entries_own on public.entries
  for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy examples_own on public.examples
  for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy links_own on public.links
  for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------- 5. 녹음 파일 저장소 ----------

insert into storage.buckets (id, name, public)
values ('audio', 'audio', false)
on conflict (id) do nothing;

drop policy if exists audio_own on storage.objects;

create policy audio_own on storage.objects
  for all to authenticated
  using      (bucket_id = 'audio' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'audio' and (storage.foldername(name))[1] = auth.uid()::text);

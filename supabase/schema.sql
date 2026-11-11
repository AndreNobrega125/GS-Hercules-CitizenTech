-- Radar do Território: tabela de ocorrências (cole no SQL Editor do Supabase e rode).
-- O app usa só a chave pública (anon/publishable); quem protege os dados é o RLS abaixo.

create table if not exists public.occurrences (
  id             text primary key,
  profile_id     text not null check (char_length(profile_id) between 1 and 40),
  created_at     timestamptz not null default now(),
  type           text not null check (type in
                   ('flooding','waste','water','power','heatAir','other')),
  description    text not null check (char_length(description) between 1 and 500),
  neighborhood   text check (neighborhood is null or char_length(neighborhood) <= 80),
  territory_name text not null check (char_length(territory_name) <= 120),
  ibge_code      text not null check (ibge_code ~ '^[0-9]{7}$')
);

create index if not exists occurrences_profile_idx
  on public.occurrences (profile_id, created_at desc);

alter table public.occurrences enable row level security;

-- Só leitura e inclusão para a chave pública. Sem update e sem delete.
drop policy if exists occurrences_select on public.occurrences;
create policy occurrences_select on public.occurrences
  for select to anon using (true);

drop policy if exists occurrences_insert on public.occurrences;
create policy occurrences_insert on public.occurrences
  for insert to anon with check (true);

-- Limitação (demo): o login do app é simulado, então o Supabase não sabe quem é o
-- usuário. O filtro por perfil é feito pelo app; qualquer pessoa com a chave pública
-- consegue ler as ocorrências. Elas são anônimas (sem nome nem contato). Para isolar
-- de verdade, troque para Supabase Auth e use `auth.uid()` nas políticas.

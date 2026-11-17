-- Radar do Território: ocorrências REAIS (nov/2026) para a demonstração.
-- Cole no SQL Editor do Supabase e rode. Pode rodar mais de uma vez.
--
-- Origem: fatos publicados pela imprensa (resumidos; a fonte vai em cada descrição).
-- São ocorrências anônimas, sem nome nem contato. Horários aproximados quando a matéria
-- não informa. Ids começam com "real-".

-- 1) Limpa os dados de teste e os exemplos fictícios anteriores.
delete from public.occurrences
 where profile_id = 'teste-automatico' or id like 'mock-%';

-- 2) Ocorrências reais.
insert into public.occurrences
  (id, profile_id, created_at, type, description, neighborhood, territory_name, ibge_code)
values
  -- São Paulo e região (chuva de 12/11/2026)
  ('real-sp-01', 'sp', '2026-11-12 16:00:00-03', 'flooding',
   'Chuva forte alagou a Zona Leste, a região mais atingida (áreas de São Mateus, Cidade Tiradentes, Guaianases e Itaquera). Fonte: CNN Brasil, 12/11/2026.',
   'Zona Leste', 'São Paulo - SP', '3550308'),
  ('real-sp-02', 'sp', '2026-11-12 18:00:00-03', 'other',
   'Entre 12h e 20h10 a Defesa Civil/CGE somou 20 chamados por queda de árvores, 13 por enchentes e inundações e 2 por desabamentos na região. Fonte: CNN Brasil, 12/11/2026.',
   null, 'São Paulo - SP', '3550308'),
  ('real-sp-03', 'sp', '2026-11-12 17:00:00-03', 'flooding',
   'Pontos de alagamento na Via Anchieta, em São Bernardo do Campo. Fonte: CNN Brasil, 12/11/2026.',
   'Via Anchieta', 'São Bernardo do Campo - SP', '3548708'),
  ('real-sp-04', 'sp', '2026-11-12 17:30:00-03', 'flooding',
   'Carro ficou submerso na Avenida Capuava, em Santo André, sem informação de feridos. Fonte: CNN Brasil, 12/11/2026.',
   'Avenida Capuava', 'Santo André - SP', '3547809'),
  ('real-sp-05', 'sp', '2026-11-12 16:24:00-03', 'other',
   'A Linha 10-Turquesa da CPTM ficou interrompida das 16h24 às 16h56, entre Prefeito Celso Daniel–Santo André e Capuava, por causa da chuva. Fonte: CNN Brasil, 12/11/2026.',
   null, 'Santo André - SP', '3547809'),

  -- Rio de Janeiro (temporal de 05/11/2026 e chuva de 07/11/2026)
  ('real-rj-01', 'rj', '2026-11-05 05:00:00-03', 'flooding',
   'Temporal com raios: um carro foi arrastado pela enxurrada na Rocinha (São Conrado) e as ruas ficaram alagadas. Fonte: Correio da Manhã, 05/11/2026.',
   'Rocinha', 'Rio de Janeiro - RJ', '3304557'),
  ('real-rj-02', 'rj', '2026-11-05 05:30:00-03', 'flooding',
   'Bolsões d''água nas avenidas Borges de Medeiros e Epitácio Pessoa (Lagoa) e na Rua Jardim Botânico. Fonte: Correio da Manhã, 05/11/2026.',
   'Lagoa', 'Rio de Janeiro - RJ', '3304557'),
  ('real-rj-03', 'rj', '2026-11-05 05:45:00-03', 'flooding',
   'Avenida das Américas alagada em vários pontos, com bolsão d''água na altura do Terminal BRT Recreio. Choveu 73,6 mm na Barra/Riocentro e 50 mm no Recreio até as 5h45. Fonte: Correio da Manhã, 05/11/2026.',
   'Recreio dos Bandeirantes', 'Rio de Janeiro - RJ', '3304557'),
  ('real-rj-04', 'rj', '2026-11-05 06:00:00-03', 'other',
   'Estrada do Joá fechada nos dois sentidos, na altura do Mirante, e queda de árvores com a chuva e o vento. Fonte: Correio da Manhã, 05/11/2026.',
   'Joá', 'Rio de Janeiro - RJ', '3304557'),
  ('real-rj-05', 'rj', '2026-11-05 06:00:00-03', 'power',
   'Poste caiu e atingiu outra árvore na Rua Miguel Pereira, no Humaitá; técnicos da Light foram ao local. Fonte: Correio da Manhã, 05/11/2026.',
   'Humaitá', 'Rio de Janeiro - RJ', '3304557'),
  ('real-rj-06', 'rj', '2026-11-07 12:00:00-03', 'flooding',
   'A Defesa Civil estadual registrou alagamentos na Penha, zona norte da capital. Fonte: Brasil em Folhas, 07/11/2026.',
   'Penha', 'Rio de Janeiro - RJ', '3304557'),
  ('real-rj-07', 'rj', '2026-11-07 12:00:00-03', 'other',
   'Barracas de feira caíram com o vento forte em Duque de Caxias, na Baixada Fluminense. Fonte: Brasil em Folhas, 07/11/2026.',
   null, 'Duque de Caxias - RJ', '3301702')
on conflict (id) do nothing;

-- Conferência: deve mostrar rj = 7 e sp = 5, sem linhas de teste ou "mock".
select profile_id, count(*) as total from public.occurrences group by profile_id order by profile_id;

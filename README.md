<div align="center">

<!-- Banner: salve a imagem em assets/screenshots/banner.png e troque a linha abaixo pela tag de imagem -->
<!-- <img src="assets/screenshots/banner.png" alt="Radar do Território" width="100%"> -->

# 📡 Radar do Território

*Alertas explicáveis de clima, ar e risco para o seu município, com a decisão final sempre nas mãos de uma pessoa.*

![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.12-0175C2?logo=dart&logoColor=white)
![Plataformas](https://img.shields.io/badge/Android%20%7C%20Windows-teal)
![Testes](https://img.shields.io/badge/testes-55%20passando-brightgreen)
![Licença](https://img.shields.io/badge/uso-acad%C3%AAmico-lightgrey)

Global Solution 2026.2 · FIAP · Cross-Platform Application Development
Desafio *Territory Predictive Insights*

[🎬 Vídeo de demonstração](#-9-vídeo) · [▶️ Como executar](#-8-como-executar) · [📊 Dados e alertas](#-5-dados-e-alertas)

</div>

---

## 📑 Sumário

1. [Problema e público](#-1-problema-e-público)
2. [Integrantes](#-2-integrantes)
3. [Demonstração visual](#-3-demonstração-visual)
4. [Funcionalidades](#-4-funcionalidades)
5. [Dados e alertas](#-5-dados-e-alertas)
6. [Privacidade e inclusão](#-6-privacidade-e-inclusão)
7. [Tecnologias e decisões técnicas](#-7-tecnologias-e-decisões-técnicas)
8. [Como executar](#-8-como-executar)
9. [Vídeo](#-9-vídeo)
10. [Licença](#-10-licença)

---

## 🎯 1. Problema e público

| | |
|---|---|
| *Problema* | Chuva forte, calor extremo e ar poluído costumam ser percebidos tarde. Os dados existem em fontes públicas, mas estão espalhados e sem explicação do que significam para o município. |
| *Para quem* | Gestores municipais e equipes de defesa civil e saúde que acompanham um ou mais municípios, de um ou mais estados, e precisam decidir com antecedência. |
| *Impacto social esperado* | Dar dias de antecedência ao gestor e mostrar quantas pessoas vivem no município sob alerta (indicador de benefício social na visão geral), para priorizar a ação. |

## 👥 2. Integrantes

| Nome completo | RM |
|---|---|
| André Ayello de Nobrega | 561754 |
| Mirella Mascarenhas | 562092 |

## 🖼️ 3. Demonstração visual

> Imagens em assets/screenshots/. Cada print tem uma legenda curta.

### Acesso

| ![Login](assets/screenshots/01-login.png) | ![Consentimento](assets/screenshots/02-consentimento.png) |
|:--:|:--:|
| Login com perfis de demonstração | Consentimento de privacidade |

### Painéis

| ![Visão geral](assets/screenshots/03-visao-geral.png) | ![Clima](assets/screenshots/04-clima.png) | ![Ar](assets/screenshots/05-ar.png) | ![Riscos](assets/screenshots/06-riscos.png) |
|:--:|:--:|:--:|:--:|
| Visão geral e benefício social | Dashboard de clima | Qualidade do ar | Mapa de riscos |

### Alertas

| ![Alertas](assets/screenshots/07-alertas.png) | ![Detalhe](assets/screenshots/08-alerta-detalhe.png) | ![Município](assets/screenshots/09-municipio.png) |
|:--:|:--:|:--:|
| Lista de alertas | Justificativa, confiança e limitações | Estado, município e favoritos |

### Formulários e ajustes

| ![Limiares](assets/screenshots/10-limiares.png) | ![Ocorrências](assets/screenshots/11-ocorrencias.png) | ![Formulário](assets/screenshots/12-ocorrencia-nova.png) |
|:--:|:--:|:--:|
| Limiares com validação | Ocorrências anônimas | Formulário com erros de validação |

| ![Configurações](assets/screenshots/13-configuracoes.png) | ![Modo escuro](assets/screenshots/14-modo-escuro.png) |
|:--:|:--:|
| Configurações e perfil | Modo escuro |

## ✅ 4. Funcionalidades

*Navegação e acesso*
- [x] Rotas nomeadas e com parâmetros (go_router), com redirecionamento para consentimento e login
- [x] Login com e-mail e senha para dois perfis de demonstração, cada um com seus próprios dados
- [x] Qualquer estado e município do Brasil, com busca e favoritos

*Painéis e alertas*
- [x] Visão geral, clima (histórico e previsão), qualidade do ar e riscos (mapa com o contorno do município)
- [x] Gráficos e indicadores de tendência
- [x] Alertas por regras, por estatística e por avisos oficiais do INMET
- [x] Cada alerta traz justificativa, evidências, nível de confiança, limitações e recomendações
- [x] Aviso visível: os alertas *apoiam, mas não substituem, a decisão humana*
- [x] Indicador de benefício social (população coberta × alertas × antecedência)

*Dados e estado*
- [x] Estado global compartilhado (provider) com carregamento, erro (com nova tentativa) e lista vazia
- [x] Dados de APIs reais, com cache local por município: o app abre offline com o último dado baixado
- [x] Formulários com validação e mensagens de erro: limiares de alerta e registro de ocorrência

*Qualidade*
- [x] Tema claro, escuro e de alto contraste
- [x] Acessibilidade testada: fonte 2x, dois tamanhos de tela, contraste, alvos de toque e rótulos
- [x] Testes automatizados de alertas, estatística, validações, login e acessibilidade

## 📊 5. Dados e alertas

### Fontes (todas públicas, sem chave de API)

| Fonte | Uso |
|---|---|
| IBGE Localidades | estados e municípios |
| IBGE Malhas (GeoJSON) | contorno do município e coordenadas |
| IBGE SIDRA | população do município |
| Open-Meteo (previsão, histórico, qualidade do ar) | temperatura, chuva, PM2.5 e PM10 |
| INMET (avisos ativos) | avisos oficiais filtrados pelo município |

### Como os alertas são gerados

O motor fica em lib/domain/alert_engine.dart e combina três tipos de alerta:

| Tipo | Método | Métrica mostrada |
|---|---|---|
| *Regras* | limiares de chuva acumulada, temperatura máxima e PM2.5, ajustáveis por perfil e validados (o nível alto precisa ser maior que o de atenção) | valor, limiar e antecedência em dias |
| *Estatística* (Dart puro, lib/domain/stats.dart) | regressão linear sobre 30 dias (tendência de temperatura), z-score (dias previstos fora do padrão) e suavização exponencial dupla de Holt (projeção do PM2.5) | R², z-score e projeção |
| *Avisos oficiais* | avisos ativos do INMET para o município, com a fonte indicada | texto e vigência do aviso |

### ⚠️ Limitações, vieses e quando não confiar

- Alertas estatísticos *nunca* recebem confiança alta: é estatística simples sobre série curta, *não é aprendizado de máquina*, e não captura sazonalidade.
- Previsão de chuva e calor vem de modelo global e pode errar em escala de bairro.
- A qualidade do ar usa modelo, não medidor local; em cidades sem estação o erro tende a ser maior.
- Contorno e população são do município inteiro; riscos locais (encostas, alagamentos pontuais) não aparecem.
- Sem internet, o app mostra o último dado baixado, que pode estar desatualizado, e exibe o aviso "Modo offline".
- As ocorrências registradas ficam no aparelho e não alimentam os alertas.

## 🔒 6. Privacidade e inclusão

<details open>
<summary><strong>Privacidade</strong></summary>

- Tela de *consentimento* antes de qualquer uso; sem consentimento o app não avança.
- Ocorrências *anônimas*: o formulário bloqueia e-mail, telefone, CPF, CEP e sequências longas de dígitos, e não guarda nome, contato nem localização exata.
- Os dados ficam só no aparelho (shared_preferences), separados por perfil.
- O login é *simulado, apenas para demonstração*: não há servidor, hash nem segurança real. Só o identificador do perfil fica salvo na sessão; a senha não é gravada.
- Não há chaves de API, tokens nem arquivos .env no código.

</details>

<details open>
<summary><strong>Acessibilidade</strong></summary>

- Rótulos de leitor de tela (Semantics) em botões, cartões e gráficos.
- Texto legível com fonte ampliada em 2x, sem estouro de layout (testado).
- Contraste conforme WCAG AA nos temas claro e escuro, mais tema de alto contraste.
- Alvos de toque de pelo menos 48 px.
- Layout testado em celular (360x640) e tablet (800x1100).

</details>

## 🧰 7. Tecnologias e decisões técnicas

| Escolha | Por quê |
|---|---|
| *Flutter / Dart* | um código para Android e Windows, e boa cobertura de testes de widget |
| *provider* | estado simples e suficiente para os quatro estados globais (configurações, login, dados do usuário, território) |
| *go_router* | rotas nomeadas, parâmetros e redirecionamento (consentimento e login) |
| *dio* | cliente HTTP com tempo limite e tratamento de erro |
| *shared_preferences* | persistência local leve, com chaves por perfil (u_<perfil>_...) e cache por código IBGE |
| *fl_chart* | gráficos de linha e barras |
| *flutter_map + latlong2* | mapa do município sem chave de API |
| *intl* | datas e números em pt-BR |
| *mocktail* | testes com a API simulada |

### Arquitetura em camadas

text
lib/
├── app/      rotas
├── core/     tema, validadores, modelo de território
├── data/     modelos, serviço de API e repositórios (cache)
├── domain/   motor de alertas, estatística, indicador social
├── state/    providers
└── ui/       telas e widgets reutilizáveis


A lógica de alertas fica em domain/, sem depender de Flutter, o que permite testá-la isoladamente.

## ▶️ 8. Como executar

*Pré-requisito:* [Flutter](https://docs.flutter.dev/get-started/install) estável (testado com 3.44). Não é preciso configurar variáveis de ambiente nem chaves de API.

bash
git clone https://github.com/AndreNobrega125/GS-Hercules-CitizenTech.git
cd GS-Hercules-CitizenTech
flutter pub get
flutter run              # escolha o dispositivo ou emulador
flutter run -d windows   # ou, direto no Windows


*Testes e análise:*

bash
flutter analyze
flutter test


*Contas de demonstração* (senha das duas: gestor123):

| Perfil | E-mail |
|---|---|
| Gestora de São Paulo | gestora.sp@radar.demo |
| Gestor do Rio de Janeiro | gestor.rj@radar.demo |

> 📶 Cada município precisa de internet na primeira vez que é aberto. Depois disso, o app funciona offline com o último dado baixado.

## 🎬 9. Vídeo

<!-- Troque pelo link público (YouTube ou Drive) e, se quiser, por uma thumbnail clicável -->
*Link:* a incluir

## 📜 10. Licença

Projeto acadêmico, FIAP, Global Solution 2026.2.

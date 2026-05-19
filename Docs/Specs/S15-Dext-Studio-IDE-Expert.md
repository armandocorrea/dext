# S15: Dext Studio (IDE Expert) & Visual Scaffolding

## 1. Visão Geral (O Problema do DX)
Embora a ferramenta CLI `dext.exe` forneça um motor poderoso de AST para engenharia reversa, a Experiência do Desenvolvedor (DX) no Delphi é historicamente visual. Desenvolvedores Delphi esperam ferramentas integradas à IDE (RAD Studio) que permitam produtividade "point-and-click" combinada com arquitetura de ponta.

**Objetivo:** Criar o **Dext Studio**, um Expert (Plugin) para o Delphi (OTA - Open Tools API) que forneça uma interface visual rica para engenharia reversa de banco de dados, governança de mapeamento e geração de código via templates.

---

## 2. Inspirações de Mercado
- **Entity Framework Core Power Tools (.NET):** Interface visual no Visual Studio para engenharia reversa, seleção de tabelas, e gravação do estado em um arquivo `efpt.config.json`.
- **Prisma (TypeScript):** Uso de um arquivo declarativo (`schema.prisma`) como *Single Source of Truth* para versionamento e geração de código.
- **Hibernate Tools (Java):** Arquivos `reveng.xml` para definir estratégias de tipagem e filtros de mapeamento fino.

---

## 3. Arquitetura de Estado (O Padrão GitOps)

### O Debate: SQLite vs YAML
Embora usar um banco local (SQLite) para armazenar os metadados visuais pareça fácil, **YAML é a escolha correta para arquitetura corporativa**.
- **Por quê YAML?** Ele suporta *GitOps*. Arquivos YAML podem ser "comitados" e revisados em um Pull Request. Se um desenvolvedor renomear um mapeamento de coluna, o Arquiteto verá a mudança no Diff do GitHub/GitLab. Bancos SQLite são binários obscuros para versionamento.

### O Arquivo `dext-schema.yaml`
O Expert gerenciará este arquivo na raiz do projeto. Ele contém:
- Configurações de banco de dados (sem senhas, integrando com o `.env`).
- Dicionário de linguagem ubíqua e regras de Regex.
- A árvore de tabelas, colunas, visibilidades (incluir/ignorar) e tipos explícitos.

---

## 4. Funcionalidades da Interface Visual (Delphi Expert)

O Dext Studio será uma janela ancorável (*dockable*) ou um assistente (*Wizard*) no Delphi, contendo as seguintes abas:

### 4.1. Connection & Target
- Dropdown para selecionar Conexão (puxando do `appsettings.json` ou do Object Inspector).
- Opção para injetar um Action de importação (`Action: Sync from DB`).
- **Templates Target:** Combobox com opções:
  - `Smart Properties` (Padrão Dext)
  - `POCO Entity` + `Fluent Mapping`
  - `DTOs` (Para APIs)
  - `Repository Interfaces`

### 4.2. Visual Mapper Grid
Uma grid em formato *Master-Detail* (Árvore de Tabelas à esquerda, Propriedades à direita).
- **Checkboxes Globais:** Selecionar quais tabelas/views farão parte do Scaffolding.
- **Detalhamento da Tabela:**
  - Checkbox para incluir/ignorar colunas específicas (Ex: ignorar campos `SYS_SYNC`).
  - Coluna "DB Name" (Somente Leitura).
  - Coluna "Delphi Property" (Editável - sobrescreve a geração).
  - Dropdown "Delphi Type" (Permite forçar um tipo específico, ex: `TStream` em vez de `TBytes`).

### 4.3. Dicionário & Ubiquitous Language (Domain-Driven Design)
A aba de governança para Arquitetos de Software.
- **Regras de Limpeza (Regex):** Remover prefixos de legado (ex: `TB_`, `VW_`, `SYS_`).
- **Glossário de Tradução Corporativa:**
  - `CLI_NOME` -> `CustomerName`
  - `DT_NASC` -> `BirthDate`
- **Singularização/Pluralização:** Motor automático (Ex: `Customers` -> `TCustomer`).
- **Escape List (Palavras Reservadas):** Gestão visual de conflitos com Delphi (`Class`, `Unit`, `Begin` -> aplicam o prefixo `&` automaticamente).

### 4.4. Relationship Manager
- Deteção automática de relacionamentos via Foreign Keys (FKs).
- Visualização de cardinalidade (1:1, 1:N, N:N).
- Opção para renomear as *Navigation Properties* (Ex: Mudar de `FNavTB_GRUPO` para `UserGroup`).
- Toggles para `Lazy Loading` vs `Eager Loading`.

---

## 5. Fluxo de Trabalho Contínuo (Continuous Scaffolding)

O maior erro dos geradores de código é a "Geração Única". O Dext Studio implementará o fluxo **Update Model from Database**:

1. **Alteração Física:** O DBA cria uma nova coluna `Status` na tabela `Orders`.
2. **Sync Action:** O dev Delphi clica em "Refresh from DB" no Dext Studio.
3. **Smart Diff Viewer:** O Expert compara o banco atual com o `dext-schema.yaml` e mostra uma tela de "Review Changes":
   - 🟢 `Order`: Added column `Status`.
   - 🔴 `Customer`: Removed column `LegacyNote`.
4. **Approve & Generate:** O dev aprova. O YAML é atualizado e o código é regenerado *com segurança*.

### Geração Segura (Safe Regeneration)
Como o Delphi não possui classes parciais (`partial class` como o C#), a regeneração pode sobrescrever código customizado. O Dext resolve isso de duas formas:
1. **Atributos/Fluent Mapping:** As entidades geradas são POCOs puros ou usam Smart Properties. Regras de negócio **nunca** devem ficar na classe de entidade, e sim nos Services/Event Handlers.
2. **Entity Bases (Opcional):** Geração de `TCustomerBase` (gerado) e `TCustomer` (herda de Base, onde o dev codifica). *Configurável via dropdown de Templates.*

---

## 6. Arquitetura OTA (Delphi Open Tools API)
- **Menu Integração:** `Tools -> Dext Framework -> Dext Studio`.
- **Project Manager Context Menu (Menu de Contexto do Projeto):** Clique direito em um projeto no Project Manager -> expande para atalhos rápidos:
  - `Dext: Open Visual Mapper (Reverse Engineer)...` (Abre a interface visual do Scaffolding).
  - `Dext: Generate API Documentation...` (Executa silenciosamente o comando `dext.exe doc` para gerar a documentação HTML viva do projeto).
  - `Dext: Run Active Unit Tests...` (Executa a suíte de testes em background e exibe o resultado diretamente na aba "Messages" da IDE).
- **Comunicação:** O Expert (BPL) chamará internamente o `dext.exe` passando o arquivo `dext-schema.yaml` ou argumentos de linha de comando como um processo silencioso em segundo plano para realizar o trabalho pesado, mantendo a IDE leve, responsiva e livre de travamentos.

---
*Especificação elaborada para transformar o Dext Framework na experiência ORM mais moderna e produtiva do ecossistema Delphi.*

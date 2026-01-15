# Multi-Tenancy

Implemente aplicações SaaS com isolamento de dados transparente.

## Estratégias de Multi-Tenancy

O Dext suporta três estratégias principais:

1. **Banco de Dados Compartilhado (Isolamento por Coluna)**
2. **Schema Separado (PostgreSQL/SQL Server)**
3. **Banco de Dados Separado**

## Banco Compartilhado (Column-based)

Adicione a interface `ITenantAware` em suas entidades e o Dext aplicará filtros automáticos em todas as queries e preencherá o `TenantId` ao salvar.

```pascal
type
  [Table('orders')]
  TOrder = class(TObject, ITenantAware)
  private
    FTenantId: string;
    // ...
  public
    [PK] property Id: Integer;
    property TenantId: string read FTenantId write FTenantId; // Coluna de isolamento
    property Description: string;
  end;
```

> 💡 **Dica**: Você pode herdar de `TTenantEntity` para obter uma implementação padrão de `ITenantAware`.

## Auto-Preenchimento (Auto-Population)

Ao salvar uma nova entidade que implementa `ITenantAware`, o `DbContext` preenche automaticamente o `TenantId` usando o `ITenantProvider` atual:

1. A entidade é rastreada pelo `DbContext`.
2. Durante o `SaveChanges`, o framework detecta `ITenantAware`.
3. O `TenantId` do inquilino atual é atribuído à entidade.
4. O registro é persistido com o ID de isolamento correto.

Isso garante que, mesmo que você esqueça de setar o ID do tenant em sua lógica de negócio, os dados permanecerão isolados e seguros.

## Configuração do Tenant via Middleware

O framework resolve o tenant atual através da requisição (Header, Host, Query, etc):

```pascal
App.UseMultiTenancy(procedure(Options: TMultiTenancyOptions)
  begin
    // Resolver tenant a partir do header 'X-Tenant'
    Options.ResolveFromHeader('X-Tenant');
  end);
```

## Isolamento por Schema

Para maior segurança e performance, use schemas separados (ex: PostgreSQL `search_path`):

```pascal
App.UseMultiTenancy(procedure(Options: TMultiTenancyOptions)
  begin
    Options.Strategy := TTenancyStrategy.Schema;
    Options.ResolveFromHost; // Ex: customer1.meuapp.com
  end);
```

Quando uma conexão é aberta, o Dext executa automaticamente o comando para trocar o schema padrão baseado no tenant resolvido.

## Vantagens do Multi-Tenancy no Dext

- **Transparência**: Você escreve `Context.Users.ToList` e o framework adiciona `WHERE TenantId = 'abc'` automaticamente.
- **Segurança**: Previne vazamento de dados entre clientes no nível arquitetural.
- **Migrações**: O CLI `dext migrate:up` pode aplicar migrations em todos os schemas/bancos de tenants.

---

[← Scaffolding](scaffolding.md) | [Próximo: Database as API →](../06-database-as-api/README.md)

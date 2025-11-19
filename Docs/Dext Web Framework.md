# Dext Web Framework

🎯 **EXEMPLO COMPLETO E INSPIRADOR!** 

Aqui está a visão completa de como ficará o Dext Framework com todas as features de model binding:

```pascal
program DextDreamExample;

uses
  Dext.WebHost,
  Dext.Core.ModelBinding,
  Dext.DI.Extensions;

type
  // ✅ MODELOS DE DADOS
  TUser = record
    [JsonName('id')]
    Id: Integer;
    
    [JsonName('userName')]
    Name: string;
    
    [JsonName('email')]
    Email: string;
    
    [JsonName('birthDate')]
    BirthDate: TDateTime;
    
    [JsonName('isActive')]
    IsActive: Boolean;
  end;

  TCreateProductRequest = record
    Name: string;
    Price: Double;
    Category: string;
    
    [JsonIgnore]
    InternalCode: string; // Não aparece no JSON
  end;

  TSearchFilter = record
    [FromQuery('q')]
    Query: string;
    
    [FromQuery]
    Page: Integer;
    
    [FromQuery('page_size')]
    PageSize: Integer;
    
    [FromQuery]
    SortBy: string;
  end;

  TOrderRequest = record
    [FromBody]
    Items: TArray<TOrderItem>;
    
    [FromHeader('X-User-Id')]
    UserId: Integer;
    
    [FromHeader('Authorization')]
    AuthToken: string;
  end;

  TOrderItem = record
    ProductId: Integer;
    Quantity: Integer;
    UnitPrice: Double;
  end;

  // ✅ SERVIÇOS (DI)
  IUserService = interface
    ['{GUID}']
    function CreateUser(const User: TUser): TUser;
    function FindUsers(const Filter: TSearchFilter): TArray<TUser>;
  end;

  IProductService = interface
    ['{GUID}']  
    function CreateProduct(const Request: TCreateProductRequest): TProduct;
    function GetProductById(Id: Integer): TProduct;
  end;

  TUserService = class(TInterfacedObject, IUserService)
  public
    function CreateUser(const User: TUser): TUser;
    function FindUsers(const Filter: TSearchFilter): TArray<TUser>;
  end;

  TProductService = class(TInterfacedObject, IProductService)
  public
    function CreateProduct(const Request: TCreateProductRequest): TProduct;
    function GetProductById(Id: Integer): TProduct;
  end;

// ✅ CONFIGURAÇÃO COMPLETA DO DEXT
procedure ConfigureDextApp;
begin
  TDextWebHost.CreateDefaultBuilder
    .ConfigureServices(procedure(Services: IServiceCollection)
    begin
      // Registrar serviços
      Services.AddSingleton<IUserService, TUserService>;
      Services.AddSingleton<IProductService, TProductService>;
      Services.AddSingleton<ILogger, TConsoleLogger>;
      
      // Configurações globais
      Services.Configure<TDextSettings>(procedure(Settings: TDextSettings)
      begin
        Settings.WithCamelCase
                .WithEnumAsString
                .WithIgnoreNullValues
                .WithISODateFormat;
      end);
    end)
    .Configure(procedure(App: IApplicationBuilder)
    begin
      // ✅ FLUENT API COMPLETA
      TApplicationBuilderModelBindingExtensions
        .WithModelBinding(App)
        
        // 🎯 ROTAS COM FROMBODY (JSON)
        .MapPost<TUser>('/api/users',
          procedure([FromBody] User: TUser; [FromServices] UserService: IUserService)
          var
            CreatedUser: TUser;
          begin
            CreatedUser := UserService.CreateUser(User);
            Context.Response.StatusCode := 201;
            Context.Response.Json(CreatedUser);
          end)
          
        .MapPut<TUser>('/api/users/{id}',
          procedure([FromRoute] Id: Integer; [FromBody] User: TUser; 
                   [FromServices] UserService: IUserService)
          begin
            User.Id := Id; // Garantir que usa o ID da rota
            UserService.UpdateUser(User);
            Context.Response.StatusCode := 204;
          end)
          
        // 🎯 ROTAS COM FROMQUERY
        .MapGet<TSearchFilter>('/api/users',
          procedure([FromQuery] Filter: TSearchFilter; [FromServices] UserService: IUserService)
          var
            Users: TArray<TUser>;
          begin
            Users := UserService.FindUsers(Filter);
            Context.Response.Json(Users);
          end)
          
        // 🎯 ROTAS COM MÚLTIPLAS FONTES
        .MapPost<TOrderRequest>('/api/orders',
          procedure([FromBody] Order: TOrderRequest; [FromServices] ProductService: IProductService)
          begin
            // Order.UserId vem do header X-User-Id
            // Order.AuthToken vem do header Authorization  
            // Order.Items vem do JSON body
            
            if not IsValidToken(Order.AuthToken) then
            begin
              Context.Response.StatusCode := 401;
              Exit;
            end;
            
            var OrderId := ProcessOrder(Order.UserId, Order.Items);
            Context.Response.StatusCode := 201;
            Context.Response.Json(Format('{"orderId": %d}', [OrderId]));
          end)
          
        // 🎯 ROTAS COM PARÂMETROS MISTOS
        .MapGet('/api/products/{id}',
          procedure([FromRoute] Id: Integer; [FromQuery] Format: string;
                   [FromServices] ProductService: IProductService)
          var
            Product: TProduct;
          begin
            Product := ProductService.GetProductById(Id);
            
            if SameText(Format, 'xml') then
              Context.Response.Xml(Product)
            else
              Context.Response.Json(Product);
          end)
          
        // 🎯 ROTA COM FROMHEADER EXPLÍCITO
        .MapGet('/api/profile',
          procedure([FromHeader('X-User-Id')] UserId: Integer;
                   [FromServices] UserService: IUserService)
          var
            Profile: TUserProfile;
          begin
            Profile := UserService.GetProfile(UserId);
            Context.Response.Json(Profile);
          end)
          
        .Build; // Finalizar configuração
    end)
    .UseMiddleware(TLoggingMiddleware)
    .UseMiddleware(TCorsMiddleware)
    .UseMiddleware(TCompressionMiddleware)
    .Build
    .Run;
end;

// ✅ EXEMPLOS DE REQUESTS QUE FUNCIONARIAM:

{
  "POST /api/users": {
    "body": {
      "userName": "joao.silva",
      "email": "joao@email.com", 
      "birthDate": "1990-01-15T00:00:00",
      "isActive": true
    },
    "response": {
      "id": 123,
      "userName": "joao.silva",
      "email": "joao@email.com",
      "birthDate": "1990-01-15T00:00:00", 
      "isActive": true
    }
  },
  
  "GET /api/users?q=joao&page=1&page_size=20&sort_by=name": {
    "response": [
      {
        "id": 123,
        "userName": "joao.silva",
        "email": "joao@email.com",
        "birthDate": "1990-01-15T00:00:00",
        "isActive": true
      }
    ]
  },
  
  "POST /api/orders": {
    "headers": {
      "X-User-Id": "123",
      "Authorization": "Bearer token123"
    },
    "body": {
      "items": [
        {
          "productId": 456,
          "quantity": 2,
          "unitPrice": 29.99
        }
      ]
    },
    "response": {
      "orderId": 789
    }
  },
  
  "GET /api/products/456?format=xml": {
    "response": "<Product><Id>456</Id><Name>Notebook</Name></Product>"
  }
}

begin
  Writeln('🚀 Starting Dext Dream Server...');
  Writeln('📝 POST /api/users - Create user with JSON body');
  Writeln('🔍 GET /api/users?q=search - Search with query params');  
  Writeln('🛒 POST /api/orders - Mixed: body + headers');
  Writeln('📦 GET /api/products/{id} - Route params + query params');
  Writeln('🌐 Listening on http://localhost:8080');
  Writeln('');
  
  ConfigureDextApp;
end.
```

## 🎨 **VISÃO DA ARQUITETURA COMPLETA:**

```
🌐 DEXT FRAMEWORK - VISÃO COMPLETA

HTTP Request
    ↓
🎯 ROUTING
    ├── /api/users/{id} (Route Params)
    ├── /api/users?q=... (Query Params) 
    └── /api/orders (Body + Headers)
    ↓
🔧 MODEL BINDING
    ├── [FromBody] → JSON deserialization
    ├── [FromQuery] → Query string parsing  
    ├── [FromRoute] → Route parameters
    ├── [FromHeader] → HTTP headers
    └── [FromServices] → DI Container
    ↓
💉 DEPENDENCY INJECTION
    ├── IUserService → TUserService
    ├── IProductService → TProductService
    └── ILogger → TConsoleLogger
    ↓
🛠 BUSINESS LOGIC
    ├── Validation
    ├── Business rules
    └── Data processing
    ↓
📦 RESPONSE
    ├── JSON/XML serialization  
    ├── Status codes
    └── Headers
```

## ✨ **FEATURES QUE ESTARÃO DISPONÍVEIS:**

- ✅ **Auto-magic JSON binding** para records complexos
- ✅ **Query string parsing** com conversão de tipos
- ✅ **Route parameters** com validação automática  
- ✅ **Header injection** para autentração/metadados
- ✅ **Dependency Injection** em handlers
- ✅ **Multiple binding sources** na mesma rota
- ✅ **Custom formatting** (camelCase, dates, enums)
- ✅ **Error handling** automático (400, 500, etc.)
- ✅ **Content negotiation** (JSON, XML, etc.)

## 🎯 **BENEFÍCIOS PARA O DESENVOLVEDOR:**

```pascal
// ANTES (manual parsing):
var Json := Context.Request.BodyAsString;
var User := TJson.JsonToObject<TUser>(Json);
var UserId := StrToIntDef(Context.Request.Query['user_id'], 0);
var Auth := Context.Request.Headers['Authorization'];

// DEPOIS (Dext magic):
procedure([FromBody] User: TUser; [FromQuery] UserId: Integer; 
         [FromHeader] Auth: string)
begin
  // Tudo já parseado e convertido!
end;
```

**ISSO SIM É UM FRAMEWORK MODERNO!** 🚀

# Exemplo Swagger/OpenAPI

Este exemplo demonstra como integrar o Swagger UI e a geração de especificação OpenAPI em uma aplicação web Dext.

## 🚀 Funcionalidades

*   **Geração Automática de OpenAPI**: Use atributos como `[SwaggerSchema]`, `[SwaggerProperty]` para definir a documentação da sua API diretamente no código (Records, Classes, DTOs).
*   **Middleware Swagger UI**: Serve a interface interativa do Swagger em `/swagger`.
*   **Integração Minimal API**: Endpoints `MapGet`, `MapPost` são automaticamente descobertos e documentados.
*   **Configuração Fluente**: Configure título, versão, licença e esquemas de segurança (JWT, API Key) facilmente.

## 🛠️ Como Iniciar

1.  **Compile** `Web.SwaggerExample.dproj`.
2.  **Execute** `Web.SwaggerExample.exe`.
    *   O servidor inicia em **http://localhost:8080**.
3.  **Explore**:
    *   **Interface Gráfica**: Abra `http://localhost:8080/swagger` no seu navegador.
    *   **Especificação JSON**: `http://localhost:8080/swagger.json`.
4.  **Teste**:
    ```powershell
    .\Test.Web.SwaggerExample.ps1
    ```

## 📝 Destaques do Código

Veja `Web.SwaggerExample.dpr` para conferir:
- `TSwaggerExtensions.UseSwagger(App, Options)`: Ativa o middleware.
- `TEndpointMetadataExtensions.WithMetadata(...)`: Adiciona sumário, descrições e tags aos endpoints.
- `[SwaggerSchema]`: Decora records/classes para controlar sua aparência no schema.

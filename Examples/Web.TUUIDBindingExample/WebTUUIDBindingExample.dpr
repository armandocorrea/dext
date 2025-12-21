program WebTUUIDBindingExample;

{$APPTYPE CONSOLE}

uses
  Dext.MM,
  System.SysUtils,
  System.Classes,
  System.DateUtils,
  Dext,
  Dext.Web,
  Dext.Json,
  Dext.Types.UUID;

type
  // DTO with TUUID field
  TProductRequest = record
    Id: TUUID;
    Name: string;
    Price: Double;
  end;

function ReadBody(const Context: IHttpContext): string;
var
  Reader: TStreamReader;
begin
  if Context.Request.Body = nil then Exit('');
  Context.Request.Body.Position := 0;
  Reader := TStreamReader.Create(Context.Request.Body, TEncoding.UTF8, True, 1024);
  try
    Result := Reader.ReadToEnd;
  finally
    Reader.Free;
  end;
end;

begin
  try
    WriteLn('Web TUUID Binding Example Server');
    WriteLn('================================');
    WriteLn;
    
    var App: IWebApplication := TDextApplication.Create;
    var Builder := App.Builder;
    
    // Example 1: TUUID in URL (manual binding parsing)
    // GET /api/products/{id}
    Builder.MapGet('/api/products/{id}', 
      procedure(Context: IHttpContext)
      var
        IdStr: string;
        U: TUUID;
        Response: string;
      begin
        // TUUID binding from URL parameter
        IdStr := Context.Request.RouteParams['id'];
        
        try
          U := TUUID.FromString(IdStr);
          
          WriteLn('GET /api/products/' + IdStr);
          WriteLn('  Received UUID: ', U.ToString);
          WriteLn('  As TGUID: ', GUIDToString(U.ToGUID));
          
          Response := Format(
            '{"id": "%s", "name": "Product %s", "price": 99.99}',
            [U.ToString, U.ToString.Substring(0, 8)]);
          
          Context.Response.SetStatusCode(200);
          Context.Response.SetContentType('application/json');
          Context.Response.Write(Response);
        except
          on E: Exception do
          begin
            Context.Response.SetStatusCode(400);
            Context.Response.SetContentType('application/json');
            Context.Response.Write('{"error": "Invalid UUID: ' + E.Message + '"}');
          end;
        end;
      end);
    
    // Example 2: TUUID in request body (JSON deserialization)
    // POST /api/products
    // Body: {"id": "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11", "name": "New Product", "price": 149.99}
    Builder.MapPost('/api/products',
      procedure(Context: IHttpContext)
      var
        Product: TProductRequest;
        DbId: TGUID;
        Response: string;
        BodyStr: string;
      begin
        try
          // Deserialize JSON to DTO with TUUID
          BodyStr := ReadBody(Context);
          Product := TDextJson.Deserialize<TProductRequest>(BodyStr);
          
          WriteLn('POST /api/products');
          WriteLn('  Received Product:');
          WriteLn('    ID: ', Product.Id.ToString);
          WriteLn('    Name: ', Product.Name);
          WriteLn('    Price: ', Product.Price:0:2);
          
          // Convert to TGUID for database operations
          DbId := Product.Id.ToGUID;
          WriteLn('    DB GUID: ', GUIDToString(DbId));
          
          Response := TDextJson.Serialize<TProductRequest>(Product);
          
          Context.Response.SetStatusCode(201);
          Context.Response.SetContentType('application/json');
          // Context.Response.Headers.Add('Location', '/api/products/' + Product.Id.ToString); 
          Context.Response.Write(Response);
        except
          on E: Exception do
          begin
            Context.Response.SetStatusCode(400);
            Context.Response.SetContentType('application/json');
            Context.Response.Write('{"error": "Invalid request: ' + E.Message + '"}');
          end;
        end;
      end);
    
    // Example 3: TUUID in URL and body (validation)
    // PUT /api/products/{id}
    Builder.MapPut('/api/products/{id}',
      procedure(Context: IHttpContext)
      var
        IdStr: string;
        UrlId: TUUID;
        Product: TProductRequest;
        Response: string;
        BodyStr: string;
      begin
        IdStr := Context.Request.RouteParams['id'];
        
        try
          UrlId := TUUID.FromString(IdStr);
          BodyStr := ReadBody(Context);
          Product := TDextJson.Deserialize<TProductRequest>(BodyStr);
          
          WriteLn('PUT /api/products/' + IdStr);
          WriteLn('  URL ID: ', UrlId.ToString);
          WriteLn('  Body ID: ', Product.Id.ToString);
          
          // Validate IDs match (TUUID equality operator)
          if UrlId <> Product.Id then
          begin
            WriteLn('  ❌ ID mismatch!');
            Context.Response.SetStatusCode(400);
            Context.Response.SetContentType('application/json');
            Context.Response.Write('{"error": "URL ID does not match body ID"}');
            Exit;
          end;
          
          WriteLn('  ✅ IDs match');
          WriteLn('  Updating: ', Product.Name);
          
          Response := TDextJson.Serialize<TProductRequest>(Product);
          Context.Response.SetStatusCode(200);
          Context.Response.SetContentType('application/json');
          Context.Response.Write(Response);
        except
          on E: Exception do
          begin
            Context.Response.SetStatusCode(400);
            Context.Response.SetContentType('application/json');
            Context.Response.Write('{"error": "Invalid request: ' + E.Message + '"}');
          end;
        end;
      end);
    
    // Example 4: Generate UUID v7 and return as JSON
    // POST /api/products/generate-v7
    Builder.MapPost('/api/products/generate-v7',
      procedure(Context: IHttpContext)
      var
        NewId: TUUID;
        Product: TProductRequest;
      begin
        NewId := TUUID.NewV7;
        
        WriteLn('POST /api/products/generate-v7');
        WriteLn('  Generated UUID v7: ', NewId.ToString);
        
        Product.Id := NewId;
        Product.Name := 'Auto-generated Product';
        Product.Price := 0.0;
        
        Context.Response.SetStatusCode(200);
        Context.Response.SetContentType('application/json');
        Context.Response.Write(TDextJson.Serialize<TProductRequest>(Product));
      end);
    
    // Example 5: Test all UUID formats
    // GET /api/uuid/formats/{id}
    Builder.MapGet('/api/uuid/formats/{id}',
      procedure(Context: IHttpContext)
      var
        IdStr: string;
        U: TUUID;
        Response: string;
      begin
        IdStr := Context.Request.RouteParams['id'];
        
        try
          U := TUUID.FromString(IdStr);
          
          WriteLn('GET /api/uuid/formats/' + IdStr);
          WriteLn('  Input: ', IdStr);
          WriteLn('  Parsed as TUUID: ', U.ToString);
          
          Response := Format(
            '{"input": "%s", ' +
            '"canonical": "%s", ' +
            '"with_braces": "%s", ' +
            '"as_tguid": "%s"}',
            [IdStr,
             U.ToString,
             U.ToStringWithBraces,
             GUIDToString(U.ToGUID)]);
          
          Context.Response.SetStatusCode(200);
          Context.Response.SetContentType('application/json');
          Context.Response.Write(Response);
        except
           on E: Exception do
           begin
             Context.Response.SetStatusCode(400);
             Context.Response.SetContentType('application/json');
             Context.Response.Write('{"error": "Invalid UUID: ' + E.Message + '"}');
           end;
        end;
      end);
    
    WriteLn('Available endpoints:');
    WriteLn('──────────────────────────────────────────────────────────');
    WriteLn('  GET    /api/products/{id}             - Get by TUUID');
    WriteLn('  POST   /api/products                  - Create with TUUID (body)');
    WriteLn('  PUT    /api/products/{id}             - Update with TUUID (URL + body)');
    WriteLn('  POST   /api/products/generate-v7      - Generate UUID v7');
    WriteLn('  GET    /api/uuid/formats/{id}         - Test UUID format parsing');
    WriteLn;
    WriteLn('Example requests:');
    WriteLn('──────────────────────────────────────────────────────────');
    WriteLn('  curl http://localhost:8080/api/products/a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11');
    WriteLn('  curl -X POST http://localhost:8080/api/products -H "Content-Type: application/json" -d "{\"id\":\"a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11\",\"name\":\"Test\",\"price\":99.99}"');
    WriteLn('  curl -X POST http://localhost:8080/api/products/generate-v7');
    WriteLn('  curl http://localhost:8080/api/uuid/formats/a0eebc999c0b4ef8bb6d6bb9bd380a11');
    WriteLn('═══════════════════════════════════════════════════════════');
    WriteLn('Server listening on http://localhost:8080');
    WriteLn('Press Ctrl+C to stop');
    WriteLn;
    
    App.Run(8080);
  except
    on E: Exception do
      WriteLn('Error: ', E.Message);
  end;
end.

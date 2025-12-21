program WebUUIDExample;

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
  TProductDto = record
    Id: TGUID;
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
    WriteLn('Web UUID Example Server');
    WriteLn('=======================');
    WriteLn;
    
    var App: IWebApplication := TDextApplication.Create;
    var Builder := App.Builder;
    
    // Example 1: GET with UUID in URL path
    // GET /api/products/{id}
    Builder.MapGet('/api/products/{id}', 
      procedure(Context: IHttpContext)
      var
        IdStr: string;
        U: TUUID;
        ProductId: TGUID;
        Product: TProductDto;
      begin
        IdStr := Context.Request.RouteParams['id'];
        WriteLn('Received ID from URL: ', IdStr);
        
        try
          // Parse UUID from URL (accepts with or without braces/hyphens)
          U := TUUID.FromString(IdStr);
          ProductId := U.ToGUID;
          
          WriteLn('Parsed as GUID: ', GUIDToString(ProductId));
          WriteLn('Canonical UUID: ', U.ToString);
          
          // Simulate database lookup
          Product.Id := ProductId;
          Product.Name := 'Sample Product';
          Product.Price := 99.99;
          
          Context.Response.SetStatusCode(200);
          Context.Response.SetContentType('application/json');
          Context.Response.Write(TDextJson.Serialize<TProductDto>(Product));
        except
          on E: Exception do
          begin
            Context.Response.SetStatusCode(400);
            Context.Response.SetContentType('application/json');
            Context.Response.Write('{"error": "Invalid UUID format: ' + E.Message + '"}');
          end;
        end;
      end);
    
    // Example 2: POST with UUID in request body
    // POST /api/products
    // Body: {"id": "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11", "name": "New Product", "price": 49.99}
    Builder.MapPost('/api/products',
      procedure(Context: IHttpContext)
      var
        Dto: TProductDto;
        U: TUUID;
        BodyStr: string;
      begin
        try
          BodyStr := ReadBody(Context);
          Dto := TDextJson.Deserialize<TProductDto>(BodyStr);
          
          WriteLn('Received product from body:');
          WriteLn('  ID: ', GUIDToString(Dto.Id));
          WriteLn('  Name: ', Dto.Name);
          WriteLn('  Price: ', Dto.Price:0:2);
          
          // Convert to TUUID for database storage
          U := TUUID.FromGUID(Dto.Id);
          WriteLn('  UUID (for DB): ', U.ToString);
          
          // Simulate database insert
          WriteLn('Product created successfully!');
          
          Context.Response.SetStatusCode(201);
          Context.Response.SetContentType('application/json');
          // AddHeader 'Location' missing in interface? IHttpResponse usually has headers access?
          // I didn't see headers property writable in snippet, assume minimal API here.
          // Context.Response.Headers.AddOrSet('Location', ...)? 
          // Skipping header for now to ensure compilation.
          
          Context.Response.Write(TDextJson.Serialize<TProductDto>(Dto));
        except
          on E: Exception do
          begin
            Context.Response.SetStatusCode(400);
            Context.Response.SetContentType('application/json');
            Context.Response.Write('{"error": "Invalid request: ' + E.Message + '"}');
          end;
        end;
      end);
    
    // Example 3: PUT with UUID in both URL and body
    // PUT /api/products/{id}
    Builder.MapPut('/api/products/{id}',
      procedure(Context: IHttpContext)
      var
        IdStr: string;
        UrlId, BodyId: TUUID;
        Dto: TProductDto;
        BodyStr: string;
      begin
        IdStr := Context.Request.RouteParams['id'];
        
        try
          UrlId := TUUID.FromString(IdStr);
          BodyStr := ReadBody(Context);
          Dto := TDextJson.Deserialize<TProductDto>(BodyStr);
          BodyId := TUUID.FromGUID(Dto.Id);
          
          // Validate that URL ID matches body ID
          if UrlId <> BodyId then
          begin
            Context.Response.SetStatusCode(400);
            Context.Response.SetContentType('application/json');
            Context.Response.Write('{"error": "URL ID does not match body ID"}');
            Exit;
          end;
          
          WriteLn('Updating product: ', UrlId.ToString);
          WriteLn('  New Name: ', Dto.Name);
          WriteLn('  New Price: ', Dto.Price:0:2);
          
          Context.Response.SetStatusCode(200);
          Context.Response.SetContentType('application/json');
          Context.Response.Write(TDextJson.Serialize<TProductDto>(Dto));
        except
          on E: Exception do
          begin
            Context.Response.SetStatusCode(400);
            Context.Response.SetContentType('application/json');
            Context.Response.Write('{"error": "Invalid request: ' + E.Message + '"}');
          end;
        end;
      end);
    
    // Example 4: Generate new UUID v7
    // POST /api/products/generate
    Builder.MapPost('/api/products/generate',
      procedure(Context: IHttpContext)
      var
        U: TUUID;
        Product: TProductDto;
      begin
        U := TUUID.NewV7;
        
        WriteLn('Generated UUID v7: ', U.ToString);
        
        Product.Id := U.ToGUID;
        Product.Name := 'Auto-generated Product';
        Product.Price := 0.0;
        
        Context.Response.SetStatusCode(200);
        Context.Response.SetContentType('application/json');
        Context.Response.Write(TDextJson.Serialize<TProductDto>(Product));
      end);
    
    // Example 5: Test endpoint showing all formats
    // GET /api/uuid/test
    Builder.MapGet('/api/uuid/test',
      procedure(Context: IHttpContext)
      var
        U: TUUID;
        G: TGUID;
        Response: string;
      begin
        U := TUUID.NewV7;
        G := U.ToGUID;
        
        Response := Format(
          '{"uuid_v7": "%s", ' +
          '"with_braces": "%s", ' +
          '"tguid": "%s", ' +
          '"timestamp_ms": %d}',
          [U.ToString, U.ToStringWithBraces, GUIDToString(G), DateTimeToUnix(Now) * 1000]);
        
        Context.Response.SetStatusCode(200);
        Context.Response.SetContentType('application/json');
        Context.Response.Write(Response);
      end);
    
    WriteLn('Available endpoints:');
    WriteLn('  GET    /api/products/{id}         - Get product by UUID');
    WriteLn('  POST   /api/products              - Create product (UUID in body)');
    WriteLn('  PUT    /api/products/{id}         - Update product (UUID in URL and body)');
    WriteLn('  POST   /api/products/generate     - Generate new UUID v7');
    WriteLn('  GET    /api/uuid/test             - Test UUID formats');
    WriteLn;
    WriteLn('Example requests:');
    WriteLn('  curl http://localhost:8080/api/products/a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11');
    WriteLn('  curl -X POST http://localhost:8080/api/products -H "Content-Type: application/json" -d "{\"id\":\"a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11\",\"name\":\"Test\",\"price\":99.99}"');
    WriteLn('  curl -X POST http://localhost:8080/api/products/generate');
    WriteLn('  curl http://localhost:8080/api/uuid/test');
    WriteLn;
    WriteLn('Server listening on http://localhost:8080');
    WriteLn('Press Ctrl+C to stop');
    WriteLn;
    
    App.Run(8080);
  except
    on E: Exception do
      WriteLn('Error: ', E.Message);
  end;
end.

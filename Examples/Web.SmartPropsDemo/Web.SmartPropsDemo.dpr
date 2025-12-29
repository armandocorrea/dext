program Web.SmartPropsDemo;

{$APPTYPE CONSOLE}

uses
  Dext.MM,
  System.SysUtils,
  System.Classes,
  Dext.WebHost,
  Dext.Web,
  Dext.Web.Interfaces,
  Dext.Web.ApplicationBuilder.Extensions,
  Dext.DI.Interfaces,
  Dext.DI.Extensions,
  Dext.Web.Results,
  Dext.Entity,
  Dext.Json,
  Dext.Entity.Prototype,
  Dext.Core.SmartTypes,
  App.Entities in 'App.Entities.pas',
  App.Context in 'App.Context.pas';

var
  Builder: IWebHostBuilder;
  Host: IWebHost;

begin
  try
    if FileExists('smart_props.db') then
      DeleteFile('smart_props.db');

    Builder := TDextWebHost.CreateDefaultBuilder;

    // Configure Services
    Builder.ConfigureServices(
      procedure(Services: IServiceCollection)
      begin
        // Add DbContext
        // Use TPersistence helper directly
        TPersistence.AddDbContext<TAppDbContext>(Services,
          procedure(Options: TDbContextOptions)
          begin
            Options.UseSQLite('smart_props.db');
            Options.WithPooling(True);
          end);
      end);

    // Configure Application Pipeline
    Builder.Configure(
      procedure(App: IApplicationBuilder)
      begin
        // Seed Data
        WriteLn('Seeding database...');
        var ServiceProvider := App.GetServiceProvider;
        var Scope := ServiceProvider.CreateScope;
        try
          var Db := Scope.ServiceProvider.GetService(TServiceType.FromClass(TAppDbContext)) as TAppDbContext;
          // Access property to register entity in Context Cache before EnsureCreated
          var EnsureSet := Db.Products; 
          Db.EnsureCreated;
          
          var P1 := TProduct.Create;
          P1.Name := 'Gaming Laptop';
          P1.Price := 1999.99;
          P1.IsActive := True;
          Db.Products.Add(P1);

          var P2 := TProduct.Create;
          P2.Name := 'Wireless Mouse';
          P2.Price := 29.99;
          P2.IsActive := True;
          Db.Products.Add(P2);

          var P3 := TProduct.Create;
          P3.Name := 'Discontinued Phone';
          P3.Price := 499.00;
          P3.IsActive := False;
          Db.Products.Add(P3);

          Db.SaveChanges;
          WriteLn('Seeding complete.');
        finally
          Scope := nil; 
        end;

        // Endpoint: GET /products
        App.Map('/products',
          procedure(Context: IHttpContext)
          begin
            var Db := Context.Services.GetService(TServiceType.FromClass(TAppDbContext)) as TAppDbContext;

            // Smart Property Query: Price > 100 AND IsActive = True
            var u := Prototype.Entity<TProduct>;
            var List := Db.Products.Where(
              (u.Price > 100)
              // Note: 'and' operator must be supported by TFluentExpression
            ).ToList;
            
            // Filter by IsActive manually for now if 'and' is tricky or use separate Where
            // var ValidList := TList<TProduct>.Create; ...
            // Simplified for demo: Just Price > 100 filtering via SQL to test compilation.

            // Automatic JSON Serialization of List<TProduct>
            Context.Response.Json(TDextJson.Serialize(List));
          end);

        // Endpoint: POST /products (Test Model Binding)
        // Shows how to deserialize JSON body to Entity (Smart Properties aware)
        // Refactored to use Automatic Model Binding & DI
        // Use TDextAppBuilder wrapper to allow Generic Methods (Delphi limitation with Interface methods)
        var WebApp := TDextAppBuilder.Create(App);
        
        WebApp.MapPost<TAppDbContext, TProduct, IResult>('/products',
          function(Db: TAppDbContext; Product: TProduct): IResult
          begin
            if Product = nil then
              Exit(Results.BadRequest('Invalid product data'));
              
            try
              // Persist to Database to get ID
              Db.Products.Add(Product);
              Db.SaveChanges;
              
              // Echo back properly serialized with new ID
              Result := Results.Ok(Product);
            except
              on E: Exception do
                Result := Results.StatusCode(500, '{"error": "' + E.Message + '"}');
            end;
          end);

        App.Map('/', 
          procedure(C: IHttpContext) 
          begin 
            C.Response.Write('Smart Properties Demo Running. Go to http://localhost:5000/products');
          end);
      end);

    Host := Builder.Build;
    WriteLn('Server listening on http://localhost:5000');
    WriteLn('GET:  http://localhost:5000/products');
    WriteLn('POST: curl -X POST http://localhost:5000/products \');
    WriteLn('      -H "Content-Type: application/json" \');
    WriteLn('      -d "{\"Name\": \"New Gadget\", \"Price\": 99.99, \"IsActive\": true}"');
    Host.Run;
    Host.Stop;
  except
    on E: Exception do
      WriteLn(E.ClassName, ': ', E.Message);
  end;

  // Readln;
end.

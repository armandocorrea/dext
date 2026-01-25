unit Dext.Dashboard.Routes;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Generics.Collections,
  System.DateUtils,
  System.JSON,
  System.Types,
{$IFDEF MSWINDOWS}
  Winapi.Windows,
{$ENDIF}
  Dext.Web.Interfaces,
  Dext.Web.Routing,
  Dext.Web.Results,
  Dext.Web.StaticFiles,
  Dext.Web.Hubs.Extensions,
  // Note: These dependencies suggest the dashboard logic is tightly coupled with CLI infrastructure for now.
  // Ideally these should be moved to a shared Dext.Dashboard namespace in the future.
  Dext.Hosting.CLI.Hubs.Dashboard,
  Dext.Hosting.CLI.Registry,
  Dext.Hosting.CLI.Config,
  Dext.Hosting.CLI.Tools.CodeCoverage,
  Dext.Http.Parser,
  Dext.Http.Executor,
  Dext.Http.Request;

type
  TDashboardRoutes = class
  public
    class procedure Configure(App: IApplicationBuilder);
  end;

implementation

{$R 'Dext.Dashboard.res'}

{ TDashboardRoutes }

class procedure TDashboardRoutes.Configure(App: IApplicationBuilder);
begin
  // Map SignalR/WebSocket Hub
  THubExtensions.MapHub(App, '/hubs/dashboard', TDashboardHub);

  // Serve embedded dashboard HTML/CSS/JS
  App.Use(procedure(Ctx: IHttpContext; Next: TRequestDelegate)
    var
      Path, ResName, CT: string;
      RS: TResourceStream;
    begin
      Path := Ctx.Request.Path;
      ResName := '';
      CT := '';

      if (Path = '/') or (Path = '/index.html') then
      begin
        ResName := 'MAIN_HTML';
        CT := 'text/html; charset=utf-8';
      end
      else if Path = '/main.css' then
      begin
        ResName := 'MAIN_CSS';
        CT := 'text/css';
      end
      else if Path = '/main.js' then
      begin
        ResName := 'MAIN_JS';
        CT := 'text/javascript';
      end;

      if ResName <> '' then
      begin
        Ctx.Response.SetContentType(CT);
        RS := TResourceStream.Create(HInstance, ResName, RT_RCDATA);
        try
          Ctx.Response.SetContentLength(RS.Size);
          Ctx.Response.Write(RS);
        finally
          RS.Free;
        end;
        Exit;
      end;
      
      Next(Ctx);
    end);

  // Serve Test Reports
  App.Use(procedure(Ctx: IHttpContext; Next: TRequestDelegate)
    var
      Path, ReportPath, FilePath, CT: string;
      CP: TContentTypeProvider;
      FS: TFileStream;
    begin
      Path := Ctx.Request.Path;
      if Path.StartsWith('/reports/', True) or (Path = '/reports') then
      begin
         if Path = '/reports' then 
         begin
           Ctx.Response.StatusCode := 302;
           Ctx.Response.AddHeader('Location', '/reports/CodeCoverage_Summary.html');
           Exit;
         end;
         
         ReportPath := TPath.GetFullPath('TestOutput\report');
         if TDirectory.Exists(ReportPath) then
         begin
             FilePath := TPath.Combine(ReportPath, Path.Substring(9)); 
             
             if FileExists(FilePath) then
             begin
                 CP := TContentTypeProvider.Create;
                 try
                    if not CP.TryGetContentType(FilePath, CT) then CT := 'application/octet-stream';
                 finally
                    CP.Free;
                 end;
                 
                 Ctx.Response.SetContentType(CT);
                 FS := TFileStream.Create(FilePath, fmOpenRead or fmShareDenyWrite);
                 try
                    Ctx.Response.SetContentLength(FS.Size);
                    Ctx.Response.Write(FS);
                 finally
                    FS.Free;
                 end;
                 Exit;
             end;
         end;
      end;
      
      Next(Ctx);
    end);

  // API: Test Summary
  App.MapGet('/api/test/summary',
    procedure(Ctx: IHttpContext)
    var
      ReportDir, SummaryFile: string;
      Res: IResult;
      Content: string;
      P1, P2: Integer;
      Coverage: string;
    begin
       ReportDir := TPath.GetFullPath('TestOutput\report');
       SummaryFile := TPath.Combine(ReportDir, 'CodeCoverage_Summary.xml');
       
       if FileExists(SummaryFile) then
       begin
          Content := TFile.ReadAllText(SummaryFile);
          P1 := Content.IndexOf('percent="');
          if P1 > 0 then
          begin
             Inc(P1, 9);
             P2 := Content.IndexOf('"', P1);
             if P2 > P1 then
             begin
                Coverage := Content.Substring(P1, P2 - P1);
                Res := Results.Ok('{"available": true, "coverage": ' + Coverage.Replace(',', '.') + '}');
                Res.Execute(Ctx);
                Exit;
             end;
          end;
       end;
       
       Res := Results.Ok('{"available": false}');
       Res.Execute(Ctx);
    end);
    
  // API: Projects
  App.MapGet('/api/projects', 
    procedure(Ctx: IHttpContext)
    var
      Registry: TProjectRegistry;
      Projects: TArray<TProjectInfo>;
      SB: TStringBuilder;
      I: Integer;
      EscapedPath, EscapedName: string;
      Res: IResult;
    begin
       Registry := Ctx.Services.GetRequiredService(TProjectRegistry) as TProjectRegistry;
       Projects := Registry.GetAllProjects;
       
       SB := TStringBuilder.Create;
       try
         SB.Append('[');
         for I := 0 to High(Projects) do
         begin
           if I > 0 then SB.Append(',');
           EscapedPath := Projects[I].Path.Replace('\', '\\').Replace('"', '\"');
           EscapedName := Projects[I].Name.Replace('\', '\\').Replace('"', '\"');
           
           SB.Append('{');
           SB.Append('"path":"').Append(EscapedPath).Append('",');
           SB.Append('"name":"').Append(EscapedName).Append('",');
           SB.Append('"lastAccess":"').Append(DateToISO8601(Projects[I].LastAccess)).Append('"');
           SB.Append('}');
         end;
         SB.Append(']');
         Res := Results.Text(SB.ToString, 200);
         Res.Execute(Ctx);
       finally
         SB.Free;
       end;
    end);

  // API: Get Config
  App.MapGet('/api/config',
    procedure(Ctx: IHttpContext)
    var
      Config: TDextGlobalConfig;
      Json, EnvObj: TJSONObject;
      Arr, PlatArr: TJSONArray;
      Res: IResult;
      Env: TDextEnvironment;
      P: string;
      CovPath: string;
    begin
      Config := TDextGlobalConfig.Create;
      Json := TJSONObject.Create;
      try
        Config.Load;
        
        Json.AddPair('dextPath', Config.DextPath);
        if Config.DextPath.IsEmpty then Json.AddPair('dextPath', ParamStr(0));
        
        CovPath := Config.CoveragePath;
        if (CovPath = '') then
           CovPath := TCodeCoverageTool.FindPath(Config, 'Win32');

        Json.AddPair('coveragePath', CovPath);
        Json.AddPair('configPath', TPath.Combine(TPath.Combine(TPath.GetHomePath, '.dext'), 'config.yaml'));
        
        Arr := TJSONArray.Create;
        for Env in Config.Environments do
        begin
          EnvObj := TJSONObject.Create;
          EnvObj.AddPair('version', Env.Version);
          EnvObj.AddPair('name', Env.Name);
          EnvObj.AddPair('path', Env.Path);
          EnvObj.AddPair('isDefault', TJSONBool.Create(Env.IsDefault));
          
          PlatArr := TJSONArray.Create;
          for P in Env.Platforms do
            PlatArr.Add(P);
          EnvObj.AddPair('platforms', PlatArr);
          
          Arr.Add(EnvObj);
        end;
        Json.AddPair('environments', Arr);
        
        Res := Results.Text(Json.ToString, 200);
        Res.Execute(Ctx);
      finally
        Json.Free;
        Config.Free;
      end;
    end);

  // API: Save Config 
  App.MapPost('/api/config',
    procedure(Ctx: IHttpContext)
    var
      Body: string;
      Res: IResult;
      SR: TStreamReader;
      Json: TJSONObject;
      Config: TDextGlobalConfig;
    begin
      SR := TStreamReader.Create(Ctx.Request.Body);
      try
         Body := SR.ReadToEnd;
         Json := TJSONObject.ParseJSONValue(Body) as TJSONObject;
         if Json <> nil then
         try
            Config := TDextGlobalConfig.Create;
            try
              Config.Load;
              if Json.TryGetValue('dextPath', Body) then Config.DextPath := Body;
              if Json.TryGetValue('coveragePath', Body) then Config.CoveragePath := Body;
              Config.Save;
              
              Res := Results.Ok('{"status":"saved"}');
            finally
              Config.Free;
            end;
         finally
           Json.Free;
         end
         else
           Res := Results.BadRequest('Invalid JSON');
           
         Res.Execute(Ctx);
      finally
         SR.Free;
      end;
    end);
    
  // API: Scan Environments
  App.MapPost('/api/env/scan',
    procedure(Ctx: IHttpContext)
    var
      Scanner: TDextGlobalConfig;
      Res: IResult;
    begin
       Scanner := TDextGlobalConfig.Create;
       try
         Scanner.ScanEnvironments;
         Res := Results.Ok('{"status":"ok"}');
         Res.Execute(Ctx);
       finally
         Scanner.Free;
       end;
    end);

  // API: Install Code Coverage
  App.MapPost('/api/tools/codecoverage/install',
    procedure(Ctx: IHttpContext)
    var
      Path: string;
      Res: IResult;
    begin
       try
         TCodeCoverageTool.InstallLatest(Path);
         Res := Results.Ok('{"status":"ok", "path": "' + Path.Replace('\', '\\') + '"}');
         Res.Execute(Ctx);
       except
         on E: Exception do
         begin
           Res := Results.StatusCode(500, Format('{"error": "%s"}', [E.Message.Replace('"', '\"')]));
           Res.Execute(Ctx);
         end;
       end;
    end);

  // API: Set Default Environment
  App.MapPost('/api/env/default',
    procedure(Ctx: IHttpContext)
    var
      Body, Ver: string;
      Res: IResult;
      SR: TStreamReader;
      Json: TJSONObject;
      Config: TDextGlobalConfig;
      I: Integer;
      Updated: Boolean;
      E: TDextEnvironment;
      NewState: Boolean;
    begin
      SR := TStreamReader.Create(Ctx.Request.Body);
      try
         Body := SR.ReadToEnd;
         Json := TJSONObject.ParseJSONValue(Body) as TJSONObject;
         if (Json <> nil) and Json.TryGetValue('version', Ver) then
         try
            Config := TDextGlobalConfig.Create;
            try
              Config.Load;
              Updated := False;
              for I := 0 to Config.Environments.Count - 1 do
              begin
                 E := Config.Environments[I];
                 NewState := (E.Version = Ver);
                 if E.IsDefault <> NewState then
                 begin
                    E.IsDefault := NewState;
                    Config.Environments[I] := E; 
                    Updated := True;
                 end;
              end;
              
              if Updated then Config.Save;
              Res := Results.Ok('{"status":"updated"}');
            finally
              Config.Free;
            end;
         finally
           Json.Free;
         end
         else
           Res := Results.BadRequest('Invalid Request');
         Res.Execute(Ctx);
      finally
         SR.Free;
      end;
    end);

  // API: HTTP Client - Parse
  App.MapPost('/api/http/parse',
    procedure(Ctx: IHttpContext)
    var
      Body: string;
      Res: IResult;
      SR: TStreamReader;
      Json, ResJson: TJSONObject;
      Collection: THttpRequestCollection;
      ReqArr, VarArr: TJSONArray;
      ReqObj, VarObj: TJSONObject;
      I: Integer;
    begin
      SR := TStreamReader.Create(Ctx.Request.Body);
      try
        Body := SR.ReadToEnd;
        Json := TJSONObject.ParseJSONValue(Body) as TJSONObject;
        if (Json <> nil) then
        try
          if Json.TryGetValue('content', Body) then
          begin
            Collection := THttpRequestParser.Parse(Body);
            try
              ResJson := TJSONObject.Create;
              try
                ReqArr := TJSONArray.Create;
                for I := 0 to Collection.Requests.Count - 1 do
                begin
                  ReqObj := TJSONObject.Create;
                  ReqObj.AddPair('name', Collection.Requests[I].Name);
                  ReqObj.AddPair('method', Collection.Requests[I].Method);
                  ReqObj.AddPair('url', Collection.Requests[I].Url);
                  ReqObj.AddPair('lineNumber', TJSONNumber.Create(Collection.Requests[I].LineNumber));
                  ReqObj.AddPair('body', Collection.Requests[I].Body);
                  ReqArr.Add(ReqObj);
                end;
                ResJson.AddPair('requests', ReqArr);
                
                VarArr := TJSONArray.Create;
                for I := 0 to Collection.Variables.Count - 1 do
                begin
                  VarObj := TJSONObject.Create;
                  VarObj.AddPair('name', Collection.Variables[I].Name);
                  VarObj.AddPair('value', Collection.Variables[I].Value);
                  VarObj.AddPair('isEnvVar', TJSONBool.Create(Collection.Variables[I].IsEnvVar));
                  VarObj.AddPair('envVarName', Collection.Variables[I].EnvVarName);
                  VarArr.Add(VarObj);
                end;
                ResJson.AddPair('variables', VarArr);
                
                Res := Results.Text(ResJson.ToString, 200);
              finally
                ResJson.Free;
              end;
            finally
              Collection.Free;
            end;
          end
          else
            Res := Results.BadRequest('Missing content field');
        finally
          Json.Free;
        end
        else
          Res := Results.BadRequest('Invalid JSON');
        Res.Execute(Ctx);
      finally
        SR.Free;
      end;
    end);

  // API: HTTP Client - Execute
  App.MapPost('/api/http/execute',
    procedure(Ctx: IHttpContext)
    var
      Body: string;
      Res: IResult;
      SR: TStreamReader;
      Json, ResJson, HeadersObj: TJSONObject;
      Collection: THttpRequestCollection;
      RequestIndex: Integer;
      ExResult: THttpExecutionResult;
      Pair: TPair<string, string>;
    begin
      SR := TStreamReader.Create(Ctx.Request.Body);
      try
        Body := SR.ReadToEnd;
        Json := TJSONObject.ParseJSONValue(Body) as TJSONObject;
        if (Json <> nil) then
        try
          RequestIndex := 0;
          Json.TryGetValue('requestIndex', RequestIndex);
          
          if Json.TryGetValue('content', Body) then
          begin
            Collection := THttpRequestParser.Parse(Body);
            try
              if (RequestIndex >= 0) and (RequestIndex < Collection.Requests.Count) then
              begin
                ExResult := THttpExecutor.ExecuteSync(Collection.Requests[RequestIndex], Collection.Variables);
                
                ResJson := TJSONObject.Create;
                try
                  ResJson.AddPair('requestName', ExResult.RequestName);
                  ResJson.AddPair('requestMethod', ExResult.RequestMethod);
                  ResJson.AddPair('requestUrl', ExResult.RequestUrl);
                  ResJson.AddPair('statusCode', TJSONNumber.Create(ExResult.StatusCode));
                  ResJson.AddPair('statusText', ExResult.StatusText);
                  ResJson.AddPair('responseBody', ExResult.ResponseBody);
                  ResJson.AddPair('durationMs', TJSONNumber.Create(ExResult.DurationMs));
                  ResJson.AddPair('success', TJSONBool.Create(ExResult.Success));
                  ResJson.AddPair('errorMessage', ExResult.ErrorMessage);
                  
                  HeadersObj := TJSONObject.Create;
                  if ExResult.ResponseHeaders <> nil then
                    for Pair in ExResult.ResponseHeaders do
                      HeadersObj.AddPair(Pair.Key, Pair.Value);
                  ResJson.AddPair('responseHeaders', HeadersObj);
                  
                  Res := Results.Text(ResJson.ToString, 200);
                finally
                  ResJson.Free;
                end;
              end
              else
                Res := Results.BadRequest('Invalid request index');
            finally
              Collection.Free;
            end;
          end
          else
            Res := Results.BadRequest('Missing content field');
        finally
          Json.Free;
        end
        else
          Res := Results.BadRequest('Invalid JSON');
        Res.Execute(Ctx);
      finally
        SR.Free;
      end;
    end);

end;

end.

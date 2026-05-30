unit Dext.EF.Design.Expert;

interface

uses
  System.SysUtils,
  System.Classes,
  ToolsAPI,
  Vcl.Menus,
  Dext.Entity.DataProvider,
  Dext.EF.Design.Metadata;

type
  TDextModuleNotifier = class(TNotifierObject, IOTAModuleNotifier)
  public
    // IOTAModuleNotifier
    function CheckOverwrite: Boolean;
    procedure ModuleRenamed(const NewName: string);
    procedure AfterSave;
    procedure BeforeSave;
    procedure Destroyed;
    procedure Modified;
  end;

  TDextIDENotifier = class(TNotifierObject, IOTAIDENotifier)
  public
    // IOTAIDENotifier
    procedure FileNotification(NotifyCode: TOTAFileNotification; const FileName: string; var CanModify: Boolean);
    procedure BeforeCompile(const Project: IOTAProject; var CanCompile: Boolean); overload;
    procedure AfterCompile(Succeeded: Boolean); overload;
    procedure BeforeCompile(const Project: IOTAProject; IsCodeInsigth: Boolean; var CanCompile: Boolean); overload;
    procedure AfterCompile(Succeeded: Boolean; IsCodeInsight: Boolean); overload;
  end;

procedure RegisterExpert;

implementation

uses
  Dext.EF.Design.DocExpert,
  System.IOUtils,
  System.JSON,
  System.Net.HttpClient,
  System.StrUtils,
  Winapi.Windows,
  Winapi.ShellAPI,
  Vcl.Forms,
  Vcl.Dialogs;

var
  FNotifierIndex: Integer = -1;

type
  TDextSidecarSupervisor = class
  private
    class var FMenuAdded: Boolean;
    class var FMainMenu: TMenuItem;
    class function FindDextExe: string;
  public
    class function IsSidecarRunning: Boolean;
    class procedure StartSidecar;
    class procedure StopSidecar;
    class procedure RestartSidecar;
    class procedure OpenDashboard;
    class procedure SyncActiveProjects;
    class procedure SetupMenus;
    class procedure RemoveMenus;
    class procedure OnMenuClick(Sender: TObject);
  end;

{ TDextSidecarSupervisor }

class function TDextSidecarSupervisor.FindDextExe: string;
var
  Paths: TArray<string>;
  P: string;
  ActiveProject: IOTAProject;
  ProjDir: string;
  ModServices: IOTAModuleServices;
begin
  Result := 'dext.exe';
  ProjDir := '';
  if Assigned(BorlandIDEServices) then
  begin
    if Supports(BorlandIDEServices, IOTAModuleServices, ModServices) then
    begin
      ActiveProject := ModServices.CurrentModule as IOTAProject;
      if Assigned(ActiveProject) then
        ProjDir := ExtractFilePath(ActiveProject.FileName);
    end;
  end;

  Paths := [
    'C:\dev\Dext\DextRepository\Apps\dext.exe',
    TPath.Combine(ProjDir, '..\..\..\Apps\dext.exe'),
    TPath.Combine(ProjDir, '..\..\Apps\dext.exe')
  ];
  for P in Paths do
  begin
    if TFile.Exists(P) then
      Exit(P);
  end;
end;

class function TDextSidecarSupervisor.IsSidecarRunning: Boolean;
var
  Client: THTTPClient;
  Resp: IHTTPResponse;
begin
  Result := False;
  Client := THTTPClient.Create;
  try
    try
      // Timeout quickly
      Client.ConnectionTimeout := 500;
      Client.ResponseTimeout := 500;
      Resp := Client.Get('http://localhost:8080/health');
      Result := (Resp <> nil) and (Resp.StatusCode = 200);
    except
      // Silent fail (not running)
    end;
  finally
    Client.Free;
  end;
end;

class procedure TDextSidecarSupervisor.StartSidecar;
var
  DextExe: string;
  SI: TStartupInfo;
  PI: TProcessInformation;
  CmdLine: string;
begin
  if IsSidecarRunning then Exit;

  DextExe := FindDextExe;
  FillChar(SI, SizeOf(SI), 0);
  SI.cb := SizeOf(SI);
  SI.dwFlags := STARTF_USESHOWWINDOW;
  SI.wShowWindow := SW_HIDE;

  CmdLine := Format('"%s" sidecar', [DextExe]);
  UniqueString(CmdLine);

  if CreateProcess(nil, PChar(CmdLine), nil, nil, False, CREATE_NO_WINDOW, nil, PChar(ExtractFilePath(DextExe)), SI, PI) then
  begin
    CloseHandle(PI.hProcess);
    CloseHandle(PI.hThread);
    // Give it a moment to boot
    TThread.Sleep(500);
    SyncActiveProjects;
  end
  else
    MessageDlg('Failed to execute Dext Sidecar process at ' + DextExe, mtError, [mbOK], 0);
end;

class procedure TDextSidecarSupervisor.StopSidecar;
var
  Client: THTTPClient;
begin
  Client := THTTPClient.Create;
  try
    try
      Client.Post('http://localhost:8080/api/telemetry/flush', TStream(nil));
    except
    end;
  finally
    Client.Free;
  end;

  // Kill process
  ShellExecute(0, 'open', 'taskkill', '/f /im dext.exe', nil, SW_HIDE);
  TThread.Sleep(200);
end;

class procedure TDextSidecarSupervisor.RestartSidecar;
begin
  StopSidecar;
  StartSidecar;
end;

class procedure TDextSidecarSupervisor.OpenDashboard;
begin
  if not IsSidecarRunning then
    StartSidecar;
  ShellExecute(0, 'open', 'http://localhost:8080', nil, nil, SW_SHOWNORMAL);
end;

class procedure TDextSidecarSupervisor.SyncActiveProjects;
var
  ModuleServices: IOTAModuleServices;
  Group: IOTAProjectGroup;
  I: Integer;
  Proj: IOTAProject;
  JArr: TJSONArray;
  Client: THTTPClient;
  Source: TStringStream;
  Module: IOTAModule;
  GroupDir: string;
  PPath: string;
begin
  if not IsSidecarRunning then Exit;

  ModuleServices := BorlandIDEServices as IOTAModuleServices;
  if ModuleServices = nil then Exit;

  Group := nil;
  for I := 0 to ModuleServices.ModuleCount - 1 do
  begin
    Module := ModuleServices.Modules[I];
    if (Module <> nil) and Supports(Module, IOTAProjectGroup, Group) then
      Break;
  end;

  if Group <> nil then
  begin
    GroupDir := ExtractFilePath(Group.FileName);
    JArr := TJSONArray.Create;
    try
      for I := 0 to Group.ProjectCount - 1 do
      begin
        Proj := Group.Projects[I];
        if Proj <> nil then
        begin
          PPath := Proj.FileName;
          if not TPath.IsPathRooted(PPath) then
            PPath := TPath.Combine(GroupDir, PPath);
          PPath := TPath.GetFullPath(PPath);
          JArr.Add(PPath);
        end;
      end;

      Client := THTTPClient.Create;
      try
        Client.ContentType := 'application/json';
        Source := TStringStream.Create(JArr.ToJSON, TEncoding.UTF8);
        try
          Client.Post('http://localhost:8080/api/ide/projects', Source, nil);
        finally
          Source.Free;
        end;
      finally
        Client.Free;
      end;
    finally
      JArr.Free;
    end;
  end;
end;

class procedure TDextSidecarSupervisor.OnMenuClick(Sender: TObject);
var
  Tag: Integer;
begin
  if Sender is TMenuItem then
  begin
    Tag := TMenuItem(Sender).Tag;
    case Tag of
      1: StartSidecar;
      2: StopSidecar;
      3: RestartSidecar;
      4: OpenDashboard;
      5: SyncActiveProjects;
    end;
  end;
end;

class procedure TDextSidecarSupervisor.SetupMenus;
var
  NTAServices: INTAServices;
  MainMenu: TMainMenu;
  ToolsMenu: TMenuItem;
  SubItem: TMenuItem;
  I: Integer;
begin
  if FMenuAdded then Exit;
  if Supports(BorlandIDEServices, INTAServices, NTAServices) then
  begin
    MainMenu := NTAServices.MainMenu;
    if MainMenu <> nil then
    begin
      // Look for Tools menu
      ToolsMenu := nil;
      for I := 0 to MainMenu.Items.Count - 1 do
      begin
        if SameText(MainMenu.Items[I].Name, 'ToolsMenu') or ContainsText(MainMenu.Items[I].Caption, 'Tools') then
        begin
          ToolsMenu := MainMenu.Items[I];
          Break;
        end;
      end;

      if ToolsMenu = nil then ToolsMenu := MainMenu.Items[MainMenu.Items.Count - 1]; // Fallback

      FMainMenu := TMenuItem.Create(MainMenu);
      FMainMenu.Caption := 'Dext Sidecar';

      SubItem := TMenuItem.Create(MainMenu);
      SubItem.Caption := 'Start Sidecar';
      SubItem.Tag := 1;
      SubItem.OnClick := OnMenuClick;
      FMainMenu.Add(SubItem);

      SubItem := TMenuItem.Create(MainMenu);
      SubItem.Caption := 'Stop Sidecar';
      SubItem.Tag := 2;
      SubItem.OnClick := OnMenuClick;
      FMainMenu.Add(SubItem);

      SubItem := TMenuItem.Create(MainMenu);
      SubItem.Caption := 'Restart Sidecar';
      SubItem.Tag := 3;
      SubItem.OnClick := OnMenuClick;
      FMainMenu.Add(SubItem);

      FMainMenu.Add(TMenuItem.Create(MainMenu)); // Separator

      SubItem := TMenuItem.Create(MainMenu);
      SubItem.Caption := 'Open Dashboard';
      SubItem.Tag := 4;
      SubItem.OnClick := OnMenuClick;
      FMainMenu.Add(SubItem);

      SubItem := TMenuItem.Create(MainMenu);
      SubItem.Caption := 'Sync IDE Projects';
      SubItem.Tag := 5;
      SubItem.OnClick := OnMenuClick;
      FMainMenu.Add(SubItem);

      ToolsMenu.Add(FMainMenu);
      FMenuAdded := True;
    end;
  end;
end;

class procedure TDextSidecarSupervisor.RemoveMenus;
begin
  if not FMenuAdded then Exit;
  if FMainMenu <> nil then
  begin
    FMainMenu.Free;
    FMainMenu := nil;
  end;
  FMenuAdded := False;
end;

procedure RegisterExpert;
begin
  if FNotifierIndex = -1 then
    FNotifierIndex := (BorlandIDEServices as IOTAServices).AddNotifier(TDextIDENotifier.Create);
  RegisterDocExpert;
  TDextSidecarSupervisor.SetupMenus;
  // Try to start Sidecar on IDE launch
  TThread.CreateAnonymousThread(procedure
    begin
      TThread.Sleep(1000);
      TDextSidecarSupervisor.StartSidecar;
    end).Start;
end;

{ TDextModuleNotifier }

procedure TDextModuleNotifier.AfterSave;
var
  Module: IOTAModule;
  Editor: IOTAEditor;
  i, j, k: Integer;
  FormEditor: IOTAFormEditor;
  Component: IOTAComponent;
  Comp: TComponent;
begin
  // Get active module
  Module := (BorlandIDEServices as IOTAModuleServices).CurrentModule;
  if Module = nil then Exit;

  // Refresh all TEntityDataProvider in all open forms
  // Refresh all TEntityDataProvider in all open forms
  for i := 0 to (BorlandIDEServices as IOTAModuleServices).ModuleCount - 1 do
  begin
    Module := (BorlandIDEServices as IOTAModuleServices).Modules[i];
    if Module = nil then Continue;
    
    for j := 0 to Module.GetModuleFileCount - 1 do
    begin
      Editor := Module.GetModuleFileEditor(j);
      if Supports(Editor, IOTAFormEditor, FormEditor) then
      begin
        // Iterate components in the form using RootComponent
        if Assigned(FormEditor.GetRootComponent) then
        begin
          for k := 0 to FormEditor.GetRootComponent.GetComponentCount - 1 do
          begin
            Component := FormEditor.GetRootComponent.GetComponent(k);
            if Assigned(Component) then
            begin
              Comp := (Component as INTAComponent).GetComponent;
              if Comp is TEntityDataProvider then
              begin
                 RefreshProviderMetadata(TEntityDataProvider(Comp));
              end;
            end;
          end;
        end;
      end;
    end;
  end;
end;

procedure TDextModuleNotifier.BeforeSave;
begin
end;

function TDextModuleNotifier.CheckOverwrite: Boolean;
begin
  Result := True;
end;

procedure TDextModuleNotifier.Destroyed;
begin
end;

procedure TDextModuleNotifier.Modified;
begin
end;

procedure TDextModuleNotifier.ModuleRenamed(const NewName: string);
begin
end;

{ TDextIDENotifier }

procedure TDextIDENotifier.AfterCompile(Succeeded: Boolean);
begin
end;

procedure TDextIDENotifier.AfterCompile(Succeeded, IsCodeInsight: Boolean);
begin
end;

procedure TDextIDENotifier.BeforeCompile(const Project: IOTAProject; var CanCompile: Boolean);
begin
end;

procedure TDextIDENotifier.BeforeCompile(const Project: IOTAProject; IsCodeInsigth: Boolean; var CanCompile: Boolean);
begin
end;

procedure TDextIDENotifier.FileNotification(NotifyCode: TOTAFileNotification; const FileName: string; var CanModify: Boolean);
begin
  if (NotifyCode = ofnFileOpened) and SameText(ExtractFileExt(FileName), '.pas') then
  begin
    // Add module notifier if needed
  end;
  if NotifyCode = ofnActiveProjectChanged then
  begin
    TDextSidecarSupervisor.SyncActiveProjects;
  end;
end;

initialization

finalization
  if FNotifierIndex <> -1 then
    (BorlandIDEServices as IOTAServices).RemoveNotifier(FNotifierIndex);
  UnregisterDocExpert;
  TDextSidecarSupervisor.RemoveMenus;

end.

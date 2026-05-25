unit Dext.EF.Design.DocExpert;

interface

uses
  System.SysUtils,
  System.Classes,
  ToolsAPI;

type
  TDextDocProjectMenuItem = class(TNotifierObject, IOTALocalMenu, IOTAProjectManagerMenu)
  private
    FProject: IOTAProject;
    FPosition: Integer;
  public
    constructor Create(const AProject: IOTAProject);
    
    // IOTALocalMenu
    function GetCaption: string;
    function GetChecked: Boolean;
    function GetEnabled: Boolean;
    function GetHelpContext: Integer;
    function GetName: string;
    function GetParent: string;
    function GetPosition: Integer;
    function GetVerb: string;
    procedure SetCaption(const Value: string);
    procedure SetChecked(Value: Boolean);
    procedure SetEnabled(Value: Boolean);
    procedure SetHelpContext(Value: Integer);
    procedure SetName(const Value: string);
    procedure SetParent(const Value: string);
    procedure SetPosition(Value: Integer);
    procedure SetVerb(const Value: string);

    // IOTAProjectManagerMenu
    function GetIsMultiSelectable: Boolean;
    procedure SetIsMultiSelectable(Value: Boolean);
    procedure Execute(const MenuContextList: IInterfaceList);
    function PreExecute(const MenuContextList: IInterfaceList): Boolean;
    function PostExecute(const MenuContextList: IInterfaceList): Boolean;
  end;

  TDextDocProjectMenuCreator = class(TNotifierObject, IOTAProjectMenuItemCreatorNotifier)
  public
    // IOTAProjectMenuItemCreatorNotifier
    procedure AddMenu(const Project: IOTAProject; const IdentList: TStrings; 
      const ProjectManagerMenuList: IInterfaceList; IsMultiSelect: Boolean);
  end;

procedure RegisterDocExpert;
procedure UnregisterDocExpert;

implementation

uses
  System.IOUtils,
  System.JSON,
  System.Generics.Collections,
  System.Threading,
  System.UITypes,
  Vcl.Forms,
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.ComCtrls,
  Vcl.Dialogs,
  Vcl.FileCtrl,
  Winapi.Windows,
  Winapi.ShellAPI;

var
  FDocNotifierIndex: Integer = -1;

type
  TFileMetadata = record
    FileName: string;
    RelativePath: string;
    LastModified: TDateTime;
    SizeKB: Int64;
  end;

  TDocForm = class(TForm)
  private
    FProject: IOTAProject;
    FProjectDir: string;
    FConfigPath: string;
    FAllFiles: TList<TFileMetadata>;
    FCheckedFiles: TDictionary<string, Boolean>;
    FScanningTask: ITask;
    FIsUpdatingList: Boolean;

    // UI Controls
    FPanelTop: TPanel;
    FPanelBottom: TPanel;
    FEditTitle: TEdit;
    FEditSearchPath: TEdit;
    FBtnSearchPath: TButton;
    FEditOutputPath: TEdit;
    FBtnOutputPath: TButton;
    FChkOnlyProject: TCheckBox;
    FEditFilter: TEdit;
    FListViewFiles: TListView;
    FBtnSelectAll: TButton;
    FBtnUnselectAll: TButton;
    FStatusLabel: TLabel;
    FBtnGenerate: TButton;
    FBtnViewDocs: TButton;
    FBtnCancel: TButton;

    procedure InitializeUI;
    procedure LoadConfig;
    procedure SaveConfig;
    procedure StartFileScan;
    procedure FilterListView;
    procedure UpdateStatusText;
    procedure UpdateViewDocsButtonState;
    procedure OpenDocumentation;
    function FindDextExe: string;

    // Event Handlers
    procedure OnFormResize(Sender: TObject);
    procedure OnSearchPathExit(Sender: TObject);
    procedure OnOutputPathExit(Sender: TObject);
    procedure OnSearchPathClick(Sender: TObject);
    procedure OnOutputPathClick(Sender: TObject);
    procedure OnChkOnlyProjectClick(Sender: TObject);
    procedure OnFilterChange(Sender: TObject);
    procedure OnSelectAllClick(Sender: TObject);
    procedure OnUnselectAllClick(Sender: TObject);
    procedure OnGenerateClick(Sender: TObject);
    procedure OnViewDocsClick(Sender: TObject);
    procedure ListViewFilesItemChecked(Sender: TObject; Item: TListItem);
  public
    constructor Create(AOwner: TComponent; const AProject: IOTAProject); reintroduce;
    destructor Destroy; override;
  end;

// Helper to check if file starts with a directory path and return relative path
function CustomGetRelativePath(const BaseDir, FileName: string): string;
var
  Base: string;
begin
  Base := BaseDir;
  if not Base.EndsWith('\') then
    Base := Base + '\';
  if FileName.StartsWith(Base, True) then
    Result := FileName.Substring(Length(Base))
  else
    Result := FileName;
end;

// Helper to get file size in KB safely
function GetFileSizeInKB(const APath: string): Int64;
var
  FS: TFileStream;
begin
  Result := 0;
  if TFile.Exists(APath) then
  begin
    try
      FS := TFileStream.Create(APath, fmOpenRead or fmShareDenyNone);
      try
        Result := FS.Size div 1024;
      finally
        FS.Free;
      end;
    except
      // Ignore read errors
    end;
  end;
end;

// Synchronous process execution capturing execution failure/success
function RunDocProcess(const AExePath, AParams: string; out AErrorMsg: string): Boolean;
var
  SI: TStartupInfo;
  PI: TProcessInformation;
  CmdLine: string;
  ExitCode: DWORD;
begin
  Result := False;
  AErrorMsg := '';
  FillChar(SI, SizeOf(SI), 0);
  SI.cb := SizeOf(SI);
  SI.dwFlags := STARTF_USESHOWWINDOW;
  SI.wShowWindow := SW_HIDE;

  CmdLine := Format('"%s" %s', [AExePath, AParams]);
  UniqueString(CmdLine);

  if CreateProcess(nil, PChar(CmdLine), nil, nil, True, CREATE_NO_WINDOW, nil, nil, SI, PI) then
  begin
    WaitForSingleObject(PI.hProcess, INFINITE);
    if GetExitCodeProcess(PI.hProcess, ExitCode) then
    begin
      Result := (ExitCode = 0);
      if not Result then
        AErrorMsg := 'Process exited with code ' + IntToStr(ExitCode);
    end
    else
      AErrorMsg := 'Failed to get process exit code.';
    CloseHandle(PI.hProcess);
    CloseHandle(PI.hThread);
  end;
end;

// YAML Helper Functions
function UnescapeYamlString(const S: string): string;
var
  Trimmed: string;
begin
  Trimmed := S.Trim;
  if Trimmed.StartsWith('"') and Trimmed.EndsWith('"') then
  begin
    Trimmed := Trimmed.Substring(1, Trimmed.Length - 2);
    Result := Trimmed.Replace('\"', '"').Replace('\\', '\');
  end
  else if Trimmed.StartsWith('''') and Trimmed.EndsWith('''') then
  begin
    Trimmed := Trimmed.Substring(1, Trimmed.Length - 2);
    Result := Trimmed.Replace('''''', '''');
  end
  else
    Result := Trimmed;
end;

function EscapeYamlString(const S: string): string;
begin
  Result := S.Replace('\', '\\').Replace('"', '\"');
  Result := '"' + Result + '"';
end;

procedure LoadYamlConfig(const AFileName: string; out ATitle, ASearchPath, AOutputPath, ALastRun: string;
  out AOnlyProjectFiles: Boolean; const ASelectedFiles: TStrings);
var
  Lines: TStringList;
  I: Integer;
  Line: string;
  Key, Val: string;
  ColonPos: Integer;
  InSelectedFiles: Boolean;
  Content: string;
  JSON: TJSONObject;
  FilesArr: TJSONArray;
begin
  ATitle := '';
  ASearchPath := '';
  AOutputPath := '';
  AOnlyProjectFiles := True;
  ALastRun := '';
  if ASelectedFiles <> nil then
    ASelectedFiles.Clear;

  if not TFile.Exists(AFileName) then Exit;

  Content := TFile.ReadAllText(AFileName, TEncoding.UTF8).Trim;
  if Content.StartsWith('{') then
  begin
    try
      JSON := TJSONObject.ParseJSONValue(Content) as TJSONObject;
      if JSON <> nil then
      begin
        try
          if JSON.GetValue('title') <> nil then
            ATitle := JSON.GetValue('title').Value;
          if JSON.GetValue('search_path') <> nil then
            ASearchPath := JSON.GetValue('search_path').Value;
          if JSON.GetValue('output_path') <> nil then
            AOutputPath := JSON.GetValue('output_path').Value;
          if JSON.GetValue('only_project_files') <> nil then
            AOnlyProjectFiles := JSON.GetValue('only_project_files').Value.ToBoolean;
          if JSON.GetValue('last_run') <> nil then
            ALastRun := JSON.GetValue('last_run').Value;
            
          if JSON.GetValue('selected_files') <> nil then
            FilesArr := JSON.GetValue('selected_files') as TJSONArray
          else
            FilesArr := nil;
            
          if (FilesArr <> nil) and (ASelectedFiles <> nil) then
          begin
            for I := 0 to FilesArr.Count - 1 do
              ASelectedFiles.Add(FilesArr.Items[I].Value);
          end;
        finally
          JSON.Free;
        end;
      end;
    except
      // Ignore JSON parsing errors in fallback
    end;
    Exit;
  end;

  Lines := TStringList.Create;
  try
    Lines.Text := Content;
    InSelectedFiles := False;
    
    for I := 0 to Lines.Count - 1 do
    begin
      Line := Lines[I];
      
      if Line.Trim.IsEmpty or Line.Trim.StartsWith('#') then
        Continue;
        
      if InSelectedFiles then
      begin
        if not Line.StartsWith('  - ') and not Line.StartsWith('    - ') and (Line.Contains(':') or not Line.StartsWith(' ')) then
          InSelectedFiles := False;
      end;

      if InSelectedFiles then
      begin
        Val := Line.Trim;
        if Val.StartsWith('- ') then
        begin
          Val := Val.Substring(2);
          if ASelectedFiles <> nil then
            ASelectedFiles.Add(UnescapeYamlString(Val));
          Continue;
        end;
      end;
      
      ColonPos := Line.IndexOf(':');
      if ColonPos > 0 then
      begin
        Key := Line.Substring(0, ColonPos).Trim.ToLower;
        Val := Line.Substring(ColonPos + 1).Trim;
        
        if Key = 'title' then
          ATitle := UnescapeYamlString(Val)
        else if Key = 'search_path' then
          ASearchPath := UnescapeYamlString(Val)
        else if Key = 'output_path' then
          AOutputPath := UnescapeYamlString(Val)
        else if Key = 'only_project_files' then
          AOnlyProjectFiles := Val.ToLower = 'true'
        else if Key = 'last_run' then
          ALastRun := UnescapeYamlString(Val)
        else if Key = 'selected_files' then
          InSelectedFiles := True;
      end;
    end;
  finally
    Lines.Free;
  end;
end;

procedure SaveYamlConfig(const AFileName: string; const ATitle, ASearchPath, AOutputPath, ALastRun: string;
  const AOnlyProjectFiles: Boolean; const ASelectedFiles: TStrings);
var
  Lines: TStringList;
  I: Integer;
begin
  Lines := TStringList.Create;
  try
    Lines.Add('title: ' + EscapeYamlString(ATitle));
    Lines.Add('search_path: ' + EscapeYamlString(ASearchPath));
    Lines.Add('output_path: ' + EscapeYamlString(AOutputPath));
    if AOnlyProjectFiles then
      Lines.Add('only_project_files: true')
    else
      Lines.Add('only_project_files: false');
    Lines.Add('last_run: ' + EscapeYamlString(ALastRun));
    
    Lines.Add('selected_files:');
    if ASelectedFiles <> nil then
    begin
      for I := 0 to ASelectedFiles.Count - 1 do
      begin
        Lines.Add('  - ' + EscapeYamlString(ASelectedFiles[I]));
      end;
    end;
    TFile.WriteAllText(AFileName, Lines.Text, TEncoding.UTF8);
  finally
    Lines.Free;
  end;
end;

{ TDextDocProjectMenuItem }

constructor TDextDocProjectMenuItem.Create(const AProject: IOTAProject);
begin
  inherited Create;
  FProject := AProject;
  FPosition := 50; // Place it near search/build items
end;

procedure TDextDocProjectMenuItem.Execute(const MenuContextList: IInterfaceList);
var
  Form: TDocForm;
begin
  Form := TDocForm.Create(nil, FProject);
  try
    Form.ShowModal;
  finally
    Form.Free;
  end;
end;

function TDextDocProjectMenuItem.GetCaption: string;
begin
  Result := 'Dext: Generate/View API Docs...';
end;

function TDextDocProjectMenuItem.GetChecked: Boolean;
begin
  Result := False;
end;

function TDextDocProjectMenuItem.GetEnabled: Boolean;
begin
  Result := True;
end;

function TDextDocProjectMenuItem.GetHelpContext: Integer;
begin
  Result := 0;
end;

function TDextDocProjectMenuItem.GetIsMultiSelectable: Boolean;
begin
  Result := False;
end;

function TDextDocProjectMenuItem.GetName: string;
begin
  Result := 'dextDocProjectMenuItem';
end;

function TDextDocProjectMenuItem.GetParent: string;
begin
  Result := '';
end;

function TDextDocProjectMenuItem.GetPosition: Integer;
begin
  Result := FPosition;
end;

function TDextDocProjectMenuItem.GetVerb: string;
begin
  Result := 'DextDoc';
end;

function TDextDocProjectMenuItem.PostExecute(const MenuContextList: IInterfaceList): Boolean;
begin
  Result := True;
end;

function TDextDocProjectMenuItem.PreExecute(const MenuContextList: IInterfaceList): Boolean;
begin
  Result := True;
end;

procedure TDextDocProjectMenuItem.SetCaption(const Value: string); begin end;
procedure TDextDocProjectMenuItem.SetChecked(Value: Boolean); begin end;
procedure TDextDocProjectMenuItem.SetEnabled(Value: Boolean); begin end;
procedure TDextDocProjectMenuItem.SetHelpContext(Value: Integer); begin end;
procedure TDextDocProjectMenuItem.SetIsMultiSelectable(Value: Boolean); begin end;
procedure TDextDocProjectMenuItem.SetName(const Value: string); begin end;
procedure TDextDocProjectMenuItem.SetParent(const Value: string); begin end;
procedure TDextDocProjectMenuItem.SetPosition(Value: Integer); begin FPosition := Value; end;
procedure TDextDocProjectMenuItem.SetVerb(const Value: string); begin end;

{ TDextDocProjectMenuCreator }

procedure TDextDocProjectMenuCreator.AddMenu(const Project: IOTAProject;
  const IdentList: TStrings; const ProjectManagerMenuList: IInterfaceList;
  IsMultiSelect: Boolean);
begin
  if (Project <> nil) and not IsMultiSelect then
  begin
    ProjectManagerMenuList.Add(TDextDocProjectMenuItem.Create(Project));
  end;
end;

{ TDocForm }

constructor TDocForm.Create(AOwner: TComponent; const AProject: IOTAProject);
begin
  inherited CreateNew(AOwner);
  FProject := AProject;
  FProjectDir := ExtractFilePath(FProject.FileName);
  FConfigPath := TPath.Combine(FProjectDir, TPath.GetFileNameWithoutExtension(FProject.FileName) + '.dext');
  FAllFiles := TList<TFileMetadata>.Create;
  FCheckedFiles := TDictionary<string, Boolean>.Create;
  FIsUpdatingList := False;
  FScanningTask := nil;
  
  InitializeUI;
  LoadConfig;
  StartFileScan;
end;

destructor TDocForm.Destroy;
begin
  if FScanningTask <> nil then
  begin
    FScanningTask.Cancel;
  end;
  FAllFiles.Free;
  FCheckedFiles.Free;
  inherited;
end;

procedure TDocForm.InitializeUI;
var
  Lbl: TLabel;
begin
  Caption := 'Dext API Documentation';
  Width := 650;
  Height := 620;
  Position := poScreenCenter;
  Constraints.MinWidth := 550;
  Constraints.MinHeight := 450;

  // Top Panel
  FPanelTop := TPanel.Create(Self);
  FPanelTop.Parent := Self;
  FPanelTop.Align := alTop;
  FPanelTop.Height := 170;
  FPanelTop.BevelOuter := bvNone;

  // Project Title
  Lbl := TLabel.Create(Self);
  Lbl.Parent := FPanelTop;
  Lbl.Caption := 'Project Title:';
  Lbl.Left := 10;
  Lbl.Top := 15;

  FEditTitle := TEdit.Create(Self);
  FEditTitle.Parent := FPanelTop;
  FEditTitle.Left := 90;
  FEditTitle.Top := 12;

  // Search Path
  Lbl := TLabel.Create(Self);
  Lbl.Parent := FPanelTop;
  Lbl.Caption := 'Search Path:';
  Lbl.Left := 10;
  Lbl.Top := 45;

  FEditSearchPath := TEdit.Create(Self);
  FEditSearchPath.Parent := FPanelTop;
  FEditSearchPath.Left := 90;
  FEditSearchPath.Top := 42;
  FEditSearchPath.OnExit := OnSearchPathExit;

  FBtnSearchPath := TButton.Create(Self);
  FBtnSearchPath.Parent := FPanelTop;
  FBtnSearchPath.Caption := '...';
  FBtnSearchPath.Top := 41;
  FBtnSearchPath.Width := 30;
  FBtnSearchPath.Height := 23;
  FBtnSearchPath.OnClick := OnSearchPathClick;

  // Output Path
  Lbl := TLabel.Create(Self);
  Lbl.Parent := FPanelTop;
  Lbl.Caption := 'Output Path:';
  Lbl.Left := 10;
  Lbl.Top := 75;

  FEditOutputPath := TEdit.Create(Self);
  FEditOutputPath.Parent := FPanelTop;
  FEditOutputPath.Left := 90;
  FEditOutputPath.Top := 72;
  FEditOutputPath.OnExit := OnOutputPathExit;

  FBtnOutputPath := TButton.Create(Self);
  FBtnOutputPath.Parent := FPanelTop;
  FBtnOutputPath.Caption := '...';
  FBtnOutputPath.Top := 71;
  FBtnOutputPath.Width := 30;
  FBtnOutputPath.Height := 23;
  FBtnOutputPath.OnClick := OnOutputPathClick;

  // Checkbox Only Project Files
  FChkOnlyProject := TCheckBox.Create(Self);
  FChkOnlyProject.Parent := FPanelTop;
  FChkOnlyProject.Caption := 'Parse only files added to the project (.dpr/.dpk)';
  FChkOnlyProject.Left := 90;
  FChkOnlyProject.Top := 102;
  FChkOnlyProject.Width := 400;
  FChkOnlyProject.OnClick := OnChkOnlyProjectClick;

  // Filter Files
  Lbl := TLabel.Create(Self);
  Lbl.Parent := FPanelTop;
  Lbl.Caption := 'Filter files:';
  Lbl.Left := 10;
  Lbl.Top := 135;

  FEditFilter := TEdit.Create(Self);
  FEditFilter.Parent := FPanelTop;
  FEditFilter.Left := 90;
  FEditFilter.Top := 132;
  FEditFilter.TextHint := 'Type to filter files by name...';
  FEditFilter.OnChange := OnFilterChange;

  // Client ListView Files
  FListViewFiles := TListView.Create(Self);
  FListViewFiles.Parent := Self;
  FListViewFiles.Align := alClient;
  FListViewFiles.AlignWithMargins := True;
  FListViewFiles.Margins.Left := 10;
  FListViewFiles.Margins.Right := 10;
  FListViewFiles.ViewStyle := vsReport;
  FListViewFiles.Checkboxes := True;
  FListViewFiles.OnItemChecked := ListViewFilesItemChecked;

  with FListViewFiles.Columns.Add do
  begin
    Caption := 'File Name';
    Width := 150;
  end;
  with FListViewFiles.Columns.Add do
  begin
    Caption := 'Relative Path';
    Width := 220;
  end;
  with FListViewFiles.Columns.Add do
  begin
    Caption := 'Last Modified';
    Width := 130;
  end;
  with FListViewFiles.Columns.Add do
  begin
    Caption := 'Size';
    Width := 70;
  end;

  // Bottom Panel
  FPanelBottom := TPanel.Create(Self);
  FPanelBottom.Parent := Self;
  FPanelBottom.Align := alBottom;
  FPanelBottom.Height := 50;
  FPanelBottom.BevelOuter := bvNone;

  // Select Buttons
  FBtnSelectAll := TButton.Create(Self);
  FBtnSelectAll.Parent := FPanelBottom;
  FBtnSelectAll.Caption := 'Select All';
  FBtnSelectAll.Left := 10;
  FBtnSelectAll.Top := 10;
  FBtnSelectAll.Width := 80;
  FBtnSelectAll.Height := 30;
  FBtnSelectAll.OnClick := OnSelectAllClick;

  FBtnUnselectAll := TButton.Create(Self);
  FBtnUnselectAll.Parent := FPanelBottom;
  FBtnUnselectAll.Caption := 'Select None';
  FBtnUnselectAll.Left := 95;
  FBtnUnselectAll.Top := 10;
  FBtnUnselectAll.Width := 80;
  FBtnUnselectAll.Height := 30;
  FBtnUnselectAll.OnClick := OnUnselectAllClick;

  // Status Label
  FStatusLabel := TLabel.Create(Self);
  FStatusLabel.Parent := FPanelBottom;
  FStatusLabel.Left := 185;
  FStatusLabel.Top := 15;
  FStatusLabel.Width := 180;
  FStatusLabel.Caption := 'Files: 0';
  FStatusLabel.Font.Style := [fsBold];

  // Action Buttons
  FBtnCancel := TButton.Create(Self);
  FBtnCancel.Parent := FPanelBottom;
  FBtnCancel.Caption := 'Cancel';
  FBtnCancel.ModalResult := mrCancel;
  FBtnCancel.Width := 80;
  FBtnCancel.Height := 30;
  FBtnCancel.Top := 10;

  FBtnGenerate := TButton.Create(Self);
  FBtnGenerate.Parent := FPanelBottom;
  FBtnGenerate.Caption := 'Generate Docs';
  FBtnGenerate.Width := 120;
  FBtnGenerate.Height := 30;
  FBtnGenerate.Top := 10;
  FBtnGenerate.Default := True;
  FBtnGenerate.OnClick := OnGenerateClick;

  FBtnViewDocs := TButton.Create(Self);
  FBtnViewDocs.Parent := FPanelBottom;
  FBtnViewDocs.Caption := 'View Docs';
  FBtnViewDocs.Width := 100;
  FBtnViewDocs.Height := 30;
  FBtnViewDocs.Top := 10;
  FBtnViewDocs.OnClick := OnViewDocsClick;

  OnResize := OnFormResize;
end;

procedure TDocForm.LoadConfig;
var
  ProjName: string;
  LoadedTitle, LoadedSearchPath, LoadedOutputPath, LoadedLastRun: string;
  LoadedOnlyProject: Boolean;
  LoadedSelectedFiles: TStringList;
  I: Integer;
begin
  // Disable events during load
  FChkOnlyProject.OnClick := nil;
  FEditFilter.OnChange := nil;
  
  LoadedSelectedFiles := TStringList.Create;
  try
    ProjName := TPath.GetFileNameWithoutExtension(FProject.FileName);
    FEditTitle.Text := ProjName;
    FEditSearchPath.Text := FProjectDir;
    FEditOutputPath.Text := TPath.Combine(FProjectDir, 'docs');
    FChkOnlyProject.Checked := True;
    
    if TFile.Exists(FConfigPath) then
    begin
      try
        LoadYamlConfig(FConfigPath, LoadedTitle, LoadedSearchPath, LoadedOutputPath, LoadedLastRun,
          LoadedOnlyProject, LoadedSelectedFiles);
          
        if LoadedTitle <> '' then
          FEditTitle.Text := LoadedTitle;
        if LoadedSearchPath <> '' then
          FEditSearchPath.Text := LoadedSearchPath;
        if LoadedOutputPath <> '' then
          FEditOutputPath.Text := LoadedOutputPath;
        
        FChkOnlyProject.Checked := LoadedOnlyProject;
        
        FCheckedFiles.Clear;
        for I := 0 to LoadedSelectedFiles.Count - 1 do
          FCheckedFiles.AddOrSetValue(LoadedSelectedFiles[I], True);
      except
        // Ignore config loading errors, fall back to defaults
      end;
    end;
  finally
    LoadedSelectedFiles.Free;
    // Restore events
    FChkOnlyProject.OnClick := OnChkOnlyProjectClick;
    FEditFilter.OnChange := OnFilterChange;
  end;
  
  UpdateViewDocsButtonState;
end;

procedure TDocForm.SaveConfig;
var
  Pair: TPair<string, Boolean>;
  SelectedFilesList: TStringList;
begin
  SelectedFilesList := TStringList.Create;
  try
    for Pair in FCheckedFiles do
    begin
      if Pair.Value then
        SelectedFilesList.Add(Pair.Key);
    end;
    
    SaveYamlConfig(FConfigPath, FEditTitle.Text, FEditSearchPath.Text, FEditOutputPath.Text,
      DateTimeToStr(Now), FChkOnlyProject.Checked, SelectedFilesList);
  finally
    SelectedFilesList.Free;
  end;
end;

procedure TDocForm.StartFileScan;
var
  SearchPath: string;
  OnlyProjectFiles: Boolean;
begin
  if FScanningTask <> nil then Exit;

  SearchPath := FEditSearchPath.Text;
  OnlyProjectFiles := FChkOnlyProject.Checked;

  FStatusLabel.Caption := 'Scanning files...';
  FBtnGenerate.Enabled := False;
  FListViewFiles.Items.BeginUpdate;
  FListViewFiles.Items.Clear;
  FListViewFiles.Items.EndUpdate;

  FScanningTask := TTask.Run(
    procedure
    var
      FileList: TList<TFileMetadata>;
      Files: TArray<string>;
      FileName: string;
      FileInfo: TFileMetadata;
      ProjFiles: TDictionary<string, Boolean>;
      I: Integer;
      ModInfo: IOTAModuleInfo;
      FinishProc: TThreadProcedure;
    begin
      FileList := TList<TFileMetadata>.Create;
      ProjFiles := TDictionary<string, Boolean>.Create;
      try
        if OnlyProjectFiles and (FProject <> nil) then
        begin
          for I := 0 to FProject.GetModuleCount - 1 do
          begin
            ModInfo := FProject.GetModule(I);
            if (ModInfo <> nil) and (ModInfo.FileName <> '') then
              ProjFiles.AddOrSetValue(TPath.GetFullPath(ModInfo.FileName).ToLower, True);
          end;
        end;

        if TDirectory.Exists(SearchPath) then
        begin
          Files := TDirectory.GetFiles(SearchPath, '*.pas', TSearchOption.SoAllDirectories);
          for FileName in Files do
          begin
            if FileName.ToLower.Contains('\tests\') then
              Continue;
            if OnlyProjectFiles and not ProjFiles.ContainsKey(FileName.ToLower) then
              Continue;

            FileInfo.FileName := TPath.GetFileName(FileName);
            FileInfo.RelativePath := CustomGetRelativePath(SearchPath, FileName);
            FileInfo.LastModified := TFile.GetLastWriteTime(FileName);
            FileInfo.SizeKB := GetFileSizeInKB(FileName);
            FileList.Add(FileInfo);
          end;
        end;

        FinishProc := procedure
          var
            MD: TFileMetadata;
            FullPath: string;
          begin
            FAllFiles.Clear;
            for MD in FileList do
              FAllFiles.Add(MD);
            
            // By default, check all files if they aren't configured yet
            for MD in FAllFiles do
            begin
              FullPath := TPath.Combine(SearchPath, MD.RelativePath);
              if not FCheckedFiles.ContainsKey(FullPath) then
                FCheckedFiles.Add(FullPath, True);
            end;

            FScanningTask := nil;
            FStatusLabel.Caption := 'Scan complete.';
            FBtnGenerate.Enabled := True;
            
            FilterListView;
          end;

        TThread.Synchronize(nil, FinishProc);
      finally
        FileList.Free;
        ProjFiles.Free;
      end;
    end);
end;

procedure TDocForm.FilterListView;
var
  SearchTerm: string;
  MD: TFileMetadata;
  Item: TListItem;
  FullPath: string;
  CheckedVal: Boolean;
begin
  FIsUpdatingList := True;
  FListViewFiles.Items.BeginUpdate;
  try
    FListViewFiles.Items.Clear;
    SearchTerm := string(FEditFilter.Text).Trim.ToLower;
    
    for MD in FAllFiles do
    begin
      if (SearchTerm = '') or MD.FileName.ToLower.Contains(SearchTerm) or 
         MD.RelativePath.ToLower.Contains(SearchTerm) then
      begin
        Item := FListViewFiles.Items.Add;
        Item.Caption := MD.FileName;
        Item.SubItems.Add(MD.RelativePath);
        Item.SubItems.Add(DateTimeToStr(MD.LastModified));
        Item.SubItems.Add(Format('%d KB', [MD.SizeKB]));
        
        FullPath := TPath.Combine(FEditSearchPath.Text, MD.RelativePath);
        if FCheckedFiles.TryGetValue(FullPath, CheckedVal) then
          Item.Checked := CheckedVal
        else
          Item.Checked := True;
      end;
    end;
  finally
    FListViewFiles.Items.EndUpdate;
    FIsUpdatingList := False;
    UpdateStatusText;
  end;
end;

procedure TDocForm.UpdateStatusText;
var
  CheckedCount, TotalCount: Integer;
  Pair: TPair<string, Boolean>;
begin
  TotalCount := FAllFiles.Count;
  CheckedCount := 0;
  for Pair in FCheckedFiles do
  begin
    if Pair.Value then
      Inc(CheckedCount);
  end;
  FStatusLabel.Caption := Format('Files: %d total | %d selected', [TotalCount, CheckedCount]);
end;

procedure TDocForm.UpdateViewDocsButtonState;
begin
  FBtnViewDocs.Enabled := TFile.Exists(TPath.Combine(FEditOutputPath.Text, 'index.html'));
end;

procedure TDocForm.OpenDocumentation;
var
  IndexPath: string;
begin
  IndexPath := TPath.Combine(FEditOutputPath.Text, 'index.html');
  if TFile.Exists(IndexPath) then
    ShellExecute(0, 'open', PChar(IndexPath), nil, nil, SW_SHOWNORMAL);
end;

function TDocForm.FindDextExe: string;
var
  Paths: TArray<string>;
  P: string;
begin
  Result := 'dext.exe';
  Paths := [
    'C:\dev\Dext\DextRepository\Apps\dext.exe',
    TPath.Combine(FProjectDir, '..\..\..\Apps\dext.exe'),
    TPath.Combine(FProjectDir, '..\..\Apps\dext.exe')
  ];
  for P in Paths do
  begin
    if TFile.Exists(P) then
      Exit(P);
  end;
end;

procedure TDocForm.OnFormResize(Sender: TObject);
var
  W: Integer;
begin
  W := ClientWidth;

  FEditTitle.Width := W - FEditTitle.Left - 10;

  FEditSearchPath.Width := W - FEditSearchPath.Left - 10 - FBtnSearchPath.Width - 5;
  FBtnSearchPath.Left := FEditSearchPath.Left + FEditSearchPath.Width + 5;

  FEditOutputPath.Width := W - FEditOutputPath.Left - 10 - FBtnOutputPath.Width - 5;
  FBtnOutputPath.Left := FEditOutputPath.Left + FEditOutputPath.Width + 5;

  FEditFilter.Width := W - FEditFilter.Left - 10;

  FBtnCancel.Left := W - FBtnCancel.Width - 10;
  FBtnGenerate.Left := FBtnCancel.Left - FBtnGenerate.Width - 5;
  FBtnViewDocs.Left := FBtnGenerate.Left - FBtnViewDocs.Width - 5;
end;

procedure TDocForm.OnSearchPathExit(Sender: TObject);
begin
  StartFileScan;
end;

procedure TDocForm.OnOutputPathExit(Sender: TObject);
begin
  UpdateViewDocsButtonState;
end;

procedure TDocForm.OnSearchPathClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := FEditSearchPath.Text;
  if SelectDirectory('Select Search Folder', '', Dir) then
  begin
    FEditSearchPath.Text := Dir;
    FEditOutputPath.Text := TPath.Combine(Dir, 'docs');
    FCheckedFiles.Clear;
    StartFileScan;
    UpdateViewDocsButtonState;
  end;
end;

procedure TDocForm.OnOutputPathClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := FEditOutputPath.Text;
  if SelectDirectory('Select Output Folder', '', Dir) then
  begin
    FEditOutputPath.Text := Dir;
    UpdateViewDocsButtonState;
  end;
end;

procedure TDocForm.OnChkOnlyProjectClick(Sender: TObject);
begin
  StartFileScan;
end;

procedure TDocForm.OnFilterChange(Sender: TObject);
begin
  FilterListView;
end;

procedure TDocForm.OnSelectAllClick(Sender: TObject);
var
  I: Integer;
  FullPath: string;
begin
  FIsUpdatingList := True;
  FListViewFiles.Items.BeginUpdate;
  try
    for I := 0 to FListViewFiles.Items.Count - 1 do
    begin
      FListViewFiles.Items[I].Checked := True;
      FullPath := TPath.Combine(FEditSearchPath.Text, FListViewFiles.Items[I].SubItems[0]);
      FCheckedFiles.AddOrSetValue(FullPath, True);
    end;
  finally
    FListViewFiles.Items.EndUpdate;
    FIsUpdatingList := False;
    UpdateStatusText;
  end;
end;

procedure TDocForm.OnUnselectAllClick(Sender: TObject);
var
  I: Integer;
  FullPath: string;
begin
  FIsUpdatingList := True;
  FListViewFiles.Items.BeginUpdate;
  try
    for I := 0 to FListViewFiles.Items.Count - 1 do
    begin
      FListViewFiles.Items[I].Checked := False;
      FullPath := TPath.Combine(FEditSearchPath.Text, FListViewFiles.Items[I].SubItems[0]);
      FCheckedFiles.AddOrSetValue(FullPath, False);
    end;
  finally
    FListViewFiles.Items.EndUpdate;
    FIsUpdatingList := False;
    UpdateStatusText;
  end;
end;

procedure TDocForm.OnGenerateClick(Sender: TObject);
var
  DextExe: string;
  Params: string;
  ErrorMsg: string;
begin
  SaveConfig;
  DextExe := FindDextExe;
  Params := Format('doc --config "%s"', [FConfigPath]);

  Screen.Cursor := crHourGlass;
  FStatusLabel.Caption := 'Generating documentation...';
  FBtnGenerate.Enabled := False;
  FBtnCancel.Enabled := False;
  Application.ProcessMessages;
  try
    if RunDocProcess(DextExe, Params, ErrorMsg) then
    begin
      FStatusLabel.Caption := 'Generation successful!';
      UpdateViewDocsButtonState;
      if MessageDlg('Documentation generated successfully!' + sLineBreak + 
                     'Would you like to open it in your browser now?', 
                     mtInformation, [mbYes, mbNo], 0) = mrYes then
      begin
        OpenDocumentation;
      end;
    end
    else
    begin
      FStatusLabel.Caption := 'Generation failed.';
      MessageDlg('Error generating documentation: ' + ErrorMsg, mtError, [mbOK], 0);
    end;
  finally
    FBtnGenerate.Enabled := True;
    FBtnCancel.Enabled := True;
    Screen.Cursor := crDefault;
    UpdateStatusText;
  end;
end;

procedure TDocForm.OnViewDocsClick(Sender: TObject);
begin
  OpenDocumentation;
end;

procedure TDocForm.ListViewFilesItemChecked(Sender: TObject; Item: TListItem);
var
  FullPath: string;
begin
  if FIsUpdatingList then Exit;
  if Item <> nil then
  begin
    FullPath := TPath.Combine(FEditSearchPath.Text, Item.SubItems[0]);
    FCheckedFiles.AddOrSetValue(FullPath, Item.Checked);
  end;
  UpdateStatusText;
end;

{ Global registration routines }

procedure RegisterDocExpert;
var
  ProjectManager: IOTAProjectManager;
begin
  if FDocNotifierIndex = -1 then
  begin
    if Supports(BorlandIDEServices, IOTAProjectManager, ProjectManager) then
    begin
      FDocNotifierIndex := ProjectManager.AddMenuItemCreatorNotifier(TDextDocProjectMenuCreator.Create);
    end;
  end;
end;

procedure UnregisterDocExpert;
var
  ProjectManager: IOTAProjectManager;
begin
  if FDocNotifierIndex <> -1 then
  begin
    if Supports(BorlandIDEServices, IOTAProjectManager, ProjectManager) then
    begin
      ProjectManager.RemoveMenuItemCreatorNotifier(FDocNotifierIndex);
      FDocNotifierIndex := -1;
    end;
  end;
end;

end.

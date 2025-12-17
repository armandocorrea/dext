unit Dext.Tool.Scaffolding.CLI;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.IOUtils,
  System.Types,
  System.StrUtils;

type
  IConsoleCommand = interface
    ['{B1B2C3D4-E5F6-4789-0123-456789ABCDEF}']
    function GetName: string;
    function GetDescription: string;
    procedure Execute(const Args: TArray<string>);
  end;

  TDextScaffoldCLI = class
  private
    FCommands: TDictionary<string, IConsoleCommand>;
    procedure RegisterCommands;
  public
    constructor Create;
    destructor Destroy; override;
    procedure ShowHelp;
    function Run: Boolean;
  end;

  // --- Commands ---

  TScaffoldCommand = class(TInterfacedObject, IConsoleCommand)
  private
    function ParseEntityFile(const FilePath: string): TList<string>;
    procedure GenerateMetaUnit(const SourceFile: string; const Entities: TList<string>; const OutputDir: string);
    function ExtractTableName(const ClassDef: string): string;
  public
    function GetName: string;
    function GetDescription: string;
    procedure Execute(const Args: TArray<string>);
  end;

implementation

{ TDextScaffoldCLI }

constructor TDextScaffoldCLI.Create;
begin
  FCommands := TDictionary<string, IConsoleCommand>.Create;
  RegisterCommands;
end;

destructor TDextScaffoldCLI.Destroy;
begin
  FCommands.Free;
  inherited;
end;

procedure TDextScaffoldCLI.RegisterCommands;
begin
  var Cmd := TScaffoldCommand.Create;
  FCommands.Add(Cmd.GetName, Cmd);
end;

procedure TDextScaffoldCLI.ShowHelp;
begin
  WriteLn('Dext Scaffolding Tool (dext-gen)');
  WriteLn('--------------------------------');
  WriteLn('Usage: dext-gen <command> [args]');
  WriteLn('');
  WriteLn('Available Commands:');
  for var Cmd in FCommands.Values do
  begin
    WriteLn('  ' + Cmd.GetName.PadRight(20) + Cmd.GetDescription);
  end;
  WriteLn('');
end;

function TDextScaffoldCLI.Run: Boolean;
var
  CmdName: string;
  Cmd: IConsoleCommand;
  Args: TArray<string>;
  i: Integer;
begin
  if ParamCount = 0 then
    Exit(False);

  CmdName := ParamStr(1).ToLower;
  
  if (CmdName = 'help') or (CmdName = '--help') or (CmdName = '-h') then
  begin
    ShowHelp;
    Exit(True);
  end;

  if FCommands.TryGetValue(CmdName, Cmd) then
  begin
    SetLength(Args, ParamCount - 1);
    for i := 2 to ParamCount do
      Args[i - 2] := ParamStr(i);
      
    try
      Cmd.Execute(Args);
    except
      on E: Exception do
        WriteLn('Error executing command: ' + E.Message);
    end;
    Result := True;
  end
  else
  begin
    WriteLn('Unknown command: ' + CmdName);
    ShowHelp;
    Result := True;
  end;
end;

{ TScaffoldCommand }

function TScaffoldCommand.GetName: string;
begin
  Result := 'scaffold';
end;

function TScaffoldCommand.GetDescription: string;
begin
  Result := 'Scans .pas files for entities and generates TEntityType metadata. Usage: scaffold --source <path> [--out <path>]';
end;

procedure TScaffoldCommand.Execute(const Args: TArray<string>);
var
  i: Integer;
  SourcePath: string;
  OutputDir: string;
  Files: TStringDynArray;
  Entities: TList<string>;
begin
  // Default values
  OutputDir := '';
  
  // Parse args
  for i := 0 to High(Args) do
  begin
    if (Args[i] = '--source') or (Args[i] = '-s') then
    begin
      if i + 1 <= High(Args) then
        SourcePath := Args[i + 1];
    end
    else if (Args[i] = '--out') or (Args[i] = '-o') then
    begin
      if i + 1 <= High(Args) then
        OutputDir := Args[i + 1];
    end;
  end;

  if SourcePath = '' then
  begin
    WriteLn('Error: --source argument is required.');
    Exit;
  end;
  
  if OutputDir = '' then
    OutputDir := SourcePath; // Default to same directory

  SourcePath := TPath.GetFullPath(SourcePath);
  OutputDir := TPath.GetFullPath(OutputDir);
  
  WriteLn('Scanning: ' + SourcePath);
  
  if TDirectory.Exists(SourcePath) then
    Files := TDirectory.GetFiles(SourcePath, '*.pas', TSearchOption.soTopDirectoryOnly)
  else if TFile.Exists(SourcePath) then
    Files := [SourcePath]
  else
  begin
    WriteLn('Error: Source path not found.');
    Exit;
  end;

  for var F in Files do
  begin
    // Skip if it's already a meta file
    if F.EndsWith('.Meta.pas', True) then Continue;
    
    // Very naive parser!
    // In production we should use a proper Delphi parser or generic regex
    Entities := ParseEntityFile(F);
    try
      if Entities.Count > 0 then
      begin
        WriteLn('Found ' + Entities.Count.ToString + ' entities in ' + TPath.GetFileName(F));
        GenerateMetaUnit(F, Entities, OutputDir);
      end;
    finally
      Entities.Free;
    end;
  end;
end;

function TScaffoldCommand.ParseEntityFile(const FilePath: string): TList<string>;
var
  Lines: TStringList;
  Content: string;
  Line: string;
  ResultList: TList<string>;
begin
  ResultList := TList<string>.Create;
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(FilePath);
    
    // Simple line-by-line helper
    for Line in Lines do
    begin
      // Look for: TClassName = class
      // Improve regex later
      if (Line.Contains(' = class')) and (not Line.Trim.StartsWith('//')) then
      begin
        // Basic check for [Table] attribute on previous lines would be better
        // For now, let's assume anything looking like a class in standard format
        // We need to capture the class name: "  TUser = class" -> "TUser"
        var Parts := Line.Trim.Split([' ', '=']);
        if Length(Parts) > 0 then
        begin
          var ClassName := Parts[0];
          // Filter out obvious non-entities or TObject
          if (ClassName.StartsWith('T')) and (ClassName <> 'TObject') then
            ResultList.Add(ClassName);
        end;
      end;
    end;
  finally
    Lines.Free;
  end;
  Result := ResultList;
end;

function TScaffoldCommand.ExtractTableName(const ClassDef: string): string;
begin
  // TODO: parsing [Table('name')]
  Result := '';
end;

procedure TScaffoldCommand.GenerateMetaUnit(const SourceFile: string; const Entities: TList<string>; const OutputDir: string);
var
  UnitName: string;
  MetaUnitName: string;
  SB: TStringBuilder;
  SourceFileName: string;
begin
  SourceFileName := TPath.GetFileNameWithoutExtension(SourceFile);
  MetaUnitName := SourceFileName + '.Meta';
  
  SB := TStringBuilder.Create;
  try
    SB.AppendLine('unit ' + MetaUnitName + ';');
    SB.AppendLine('');
    SB.AppendLine('interface');
    SB.AppendLine('');
    SB.AppendLine('uses');
    SB.AppendLine('  Dext.Data.TypeSystem,');
    SB.AppendLine('  ' + SourceFileName + ';');
    SB.AppendLine('');
    SB.AppendLine('type');
    
    for var Entity in Entities do
    begin
      // TUser -> TUserType
      var EntityType := Entity + 'Type';
      
      SB.AppendLine('  ' + EntityType + ' = class(TEntityType<' + Entity + '>)');
      SB.AppendLine('  public');
      SB.AppendLine('    class constructor Create;');
      // TODO: We need real parsing to find properties!
      // For now this is a skeleton generator.
      SB.AppendLine('    // Scaffolding TODO: Add cached properties here');
      SB.AppendLine('    // class var Name: TProp<string>;');
      SB.AppendLine('  end;');
      SB.AppendLine('');
    end;

    SB.AppendLine('implementation');
    SB.AppendLine('');
    
    for var Entity in Entities do
    begin
      var EntityType := Entity + 'Type';
      SB.AppendLine('{ ' + EntityType + ' }');
      SB.AppendLine('');
      SB.AppendLine('class constructor ' + EntityType + '.Create;');
      SB.AppendLine('begin');
      SB.AppendLine('  inherited;');
      SB.AppendLine('  // Manual property init would go here');
      SB.AppendLine('end;');
      SB.AppendLine('');
    end;    

    SB.AppendLine('end.');
    
    var OutFile := TPath.Combine(OutputDir, MetaUnitName + '.pas');
    TFile.WriteAllText(OutFile, SB.ToString);
    WriteLn('Generated: ' + OutFile);
    
  finally
    SB.Free;
  end;
end;

end.

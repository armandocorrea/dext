program TestTypeConvertersDb;

{$APPTYPE CONSOLE}
{$TYPEINFO ON}
{$METHODINFO ON}

uses
  System.SysUtils,
  System.Classes,
  System.Rtti,
  System.TypInfo,
  System.Generics.Collections,
  Data.DB,
  FireDAC.Comp.Client,
  FireDAC.Phys.PG,
  FireDAC.Phys.PGDef,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.UI.Intf,
  FireDAC.Phys.Intf,
  FireDAC.Stan.Def,
  FireDAC.Stan.Pool,
  FireDAC.Stan.Async,
  FireDAC.Phys,
  Dext,
  Dext.Collections,
  Dext.Entity.Core,
  Dext.Entity.Attributes,
  Dext.Entity.Context,
  Dext.Entity.Drivers.Interfaces,
  Dext.Entity.Drivers.FireDAC,
  Dext.Entity.Mapping,
  Dext.Entity.TypeConverters,
  Dext.Entity.Dialects,
  Dext.Specifications.Interfaces,
  Dext.Specifications.Base;

type
  TUserRole = (urUser, urAdmin, urSuperAdmin);

  [Table('test_guid_entities')]
  TGuidEntity = class
  private
    FId: TGUID;
    FName: string;
  public
    [PK]
    property Id: TGUID read FId write FId;
    [Column('name')]
    property Name: string read FName write FName;
  end;

  [Table('test_enum_entities')]
  TEnumEntity = class
  private
    FId: Integer;
    FRole: TUserRole;
    FStatus: TUserRole;
  public
    [PK, AutoInc]
    property Id: Integer read FId write FId;
    [Column('role_int')]
    property Role: TUserRole read FRole write FRole;
    [Column('role_name'), EnumAsString]
    property Status: TUserRole read FStatus write FStatus;
  end;

  {$M+}
  {$RTTI EXPLICIT FIELDS([vcPrivate, vcPublic]) PROPERTIES([vcPublic, vcPublished])}
  TJsonMetadata = class
  private
    FName: string;
    FValue: Integer;
  public
    property Name: string read FName write FName;
    property Value: Integer read FValue write FValue;
  end;

  [Table('test_json_entities')]
  TJsonEntity = class
  private
    FId: Integer;
    FMetadata: TJsonMetadata;
  public
    constructor Create;
    destructor Destroy; override;
    [PK, AutoInc]
    property Id: Integer read FId write FId;
    [Column('metadata')]
    property Metadata: TJsonMetadata read FMetadata write FMetadata;
  end;

  TTestDbContext = class(TDbContext)
  private
    function GetGuidEntities: IDbSet<TGuidEntity>;
    function GetEnumEntities: IDbSet<TEnumEntity>;
    function GetJsonEntities: IDbSet<TJsonEntity>;
  public
    property GuidEntities: IDbSet<TGuidEntity> read GetGuidEntities;
    property EnumEntities: IDbSet<TEnumEntity> read GetEnumEntities;
    property JsonEntities: IDbSet<TJsonEntity> read GetJsonEntities;
  end;

{ TJsonEntity }

constructor TJsonEntity.Create;
begin
  FMetadata := TJsonMetadata.Create;
end;

destructor TJsonEntity.Destroy;
begin
  FMetadata.Free;
  inherited;
end;

{ TTestDbContext }

function TTestDbContext.GetGuidEntities: IDbSet<TGuidEntity>;
begin
  Result := Entities<TGuidEntity>;
end;

function TTestDbContext.GetEnumEntities: IDbSet<TEnumEntity>;
begin
  Result := Entities<TEnumEntity>;
end;

function TTestDbContext.GetJsonEntities: IDbSet<TJsonEntity>;
begin
  Result := Entities<TJsonEntity>;
end;

procedure EnsureDatabaseExists;
var
  Conn: TFDConnection;
  Qry: TFDQuery;
begin
  Conn := TFDConnection.Create(nil);
  try
    Conn.DriverName := 'PG';
    Conn.Params.Values['Server'] := 'localhost';
    Conn.Params.Values['Port'] := '5432';
    Conn.Params.Values['User_Name'] := 'postgres';
    Conn.Params.Values['Password'] := 'root';
    Conn.Params.Values['Database'] := 'postgres';
    
    try
      Conn.Connected := True;
      Qry := TFDQuery.Create(nil);
      try
        Qry.Connection := Conn;
        Qry.SQL.Text := 'SELECT 1 FROM pg_database WHERE datname = ''dext_test''';
        Qry.Open;
        if Qry.Eof then
        begin
          Conn.ExecSQL('CREATE DATABASE dext_test');
          WriteLn('  ✓ Database created');
        end;
      finally
        Qry.Free;
      end;
    except
      on E: Exception do WriteLn('  ⚠ Database failure: ', E.Message);
    end;
  finally
    Conn.Free;
  end;
end;

procedure RegisterConverters;
begin
  TTypeConverterRegistry.Instance.RegisterConverter(TGuidConverter.Create);
  TTypeConverterRegistry.Instance.RegisterConverter(TEnumConverter.Create(False));
  
  // JSON converter must be registered for specific types if not using [JsonColumn] (which is not implemented yet in DbSet logic)
  TTypeConverterRegistry.Instance.RegisterConverterForType(TypeInfo(TJsonMetadata), TJsonConverter.Create(True));
end;

procedure ExecSQL(Db: TDbContext; const SQL: string);
var
  Cmd: IDbCommand;
begin
  Cmd := Db.Connection.CreateCommand(SQL) as IDbCommand;
  Cmd.ExecuteNonQuery;
end;

procedure TestGuid(Db: TTestDbContext);
var
  TestGuid: TGUID;
  Entity: TGuidEntity;
  List: IList<TGuidEntity>;
  Loaded: TGuidEntity;
begin
  WriteLn('► Testing GUID...');
  WriteLn('  Step 1: Delete');
  ExecSQL(Db, 'DELETE FROM test_guid_entities');
  
  TestGuid := TGuid.NewGuid;
  Entity := TGuidEntity.Create;
  Entity.Id := TestGuid;
  Entity.Name := 'Isso eh um teste';
  
  WriteLn('  Step 2: Save');
  Db.GuidEntities.Add(Entity);
  Db.SaveChanges;
  
  WriteLn('  Step 3: Clear');
  Db.Clear; 
  
  WriteLn('  Step 4: List');
  List := Db.GuidEntities.List;
  
  WriteLn('  Step 5: Loaded count: ', List.Count);
  if List.Count > 0 then
  begin
    Loaded := List[0];
    WriteLn('  Original GUID: ', GUIDToString(TestGuid));
    WriteLn('  Loaded GUID:   ', GUIDToString(Loaded.Id));
    if not IsEqualGUID(TestGuid, Loaded.Id) then
    begin
       WriteLn('  Mismatch details:');
       WriteLn('    Org: ', GUIDToString(TestGuid));
       WriteLn('    Ld : ', GUIDToString(Loaded.Id));
       raise Exception.Create('GUID mismatch');
    end;
    WriteLn('  ✓ OK');
  end;
end;

procedure TestEnum(Db: TTestDbContext);
var
  Entity: TEnumEntity;
  List: IList<TEnumEntity>;
  Loaded: TEnumEntity;
begin
  WriteLn('► Testing Enum...');
  ExecSQL(Db, 'DELETE FROM test_enum_entities');
  Entity := TEnumEntity.Create;
  Entity.Role := urSuperAdmin;
  Entity.Status := urAdmin;
  Db.EnumEntities.Add(Entity);
  Db.SaveChanges;
  Db.Clear;
  List := Db.EnumEntities.List;
  if List.Count > 0 then
  begin
    Loaded := List[0];
    WriteLn('  Loaded Role: ' + GetEnumName(TypeInfo(TUserRole), Ord(Loaded.Role)));
    if Loaded.Role <> urSuperAdmin then raise Exception.Create('Enum mismatch');
    WriteLn('  ✓ OK');
  end;
end;

procedure TestJson(Db: TTestDbContext);
var
  Entity: TJsonEntity;
  List: IList<TJsonEntity>;
  Loaded: TJsonEntity;
begin
  WriteLn('► Testing JSON...');
  ExecSQL(Db, 'DELETE FROM test_json_entities');
  Entity := TJsonEntity.Create;
  Entity.Metadata.Name := 'Dext';
  Entity.Metadata.Value := 10;
  
  Db.JsonEntities.Add(Entity);
  Db.SaveChanges;
  Db.Clear;
  List := Db.JsonEntities.List;
  if List.Count > 0 then
  begin
    Loaded := List[0];
    WriteLn('  Loaded Name: "' + Loaded.Metadata.Name + '" Value: ' + IntToStr(Loaded.Metadata.Value));
    if Loaded.Metadata.Name <> 'Dext' then raise Exception.Create('JSON mismatch');
    WriteLn('  ✓ OK');
  end;
end;

var
  Db: TTestDbContext;
  Connection: IDbConnection;
  FDConn: TFDConnection;
  Dialect: ISQLDialect;
begin
  try
    EnsureDatabaseExists;
    
    // Direct configuration without DbConfig.pas
    FDConn := TFDConnection.Create(nil);
    FDConn.DriverName := 'PG';
    FDConn.Params.Values['Server'] := 'localhost';
    FDConn.Params.Values['Port'] := '5432';
    FDConn.Params.Values['Database'] := 'dext_test';
    FDConn.Params.Values['User_Name'] := 'postgres';
    FDConn.Params.Values['Password'] := 'root';
    FDConn.Params.Values['GUIDEndian'] := 'Big'; // Tentar Big ja que Little falhou e manteve inversao byte a byte
    
    
    Connection := TFireDACConnection.Create(FDConn, True); // Takes object
    
    Dialect := TPostgreSQLDialect.Create;

    RegisterConverters;
    
    Db := TTestDbContext.Create(Connection, Dialect);
    try
      // Force clean state by dropping tables
      var C: IInterface := Connection.CreateCommand('DROP TABLE IF EXISTS test_guid_entities');
      (C as IDbCommand).ExecuteNonQuery;
      
      C := Connection.CreateCommand('DROP TABLE IF EXISTS test_enum_entities');
      (C as IDbCommand).ExecuteNonQuery;
      
      C := Connection.CreateCommand('DROP TABLE IF EXISTS test_json_entities');
      (C as IDbCommand).ExecuteNonQuery;

      // Force initialization of DbSets so they are registered in the Context Cache
      // This is required for EnsureCreated to know which tables to create.
      if Db.GuidEntities <> nil then;
      if Db.EnumEntities <> nil then;
      if Db.JsonEntities <> nil then;
      
      Db.EnsureCreated;
      TestGuid(Db);
      TestEnum(Db);
      TestJson(Db);
      WriteLn('🎉 SUCCESS!');
    finally
      Db.Free;
    end;
  except
    on E: Exception do WriteLn('❌ FAILED: ' + E.Message);
  end;
  WriteLn('Done.');
  ReadLn;
end.

unit EntityDemo.Tests.Base;

interface

uses
  System.SysUtils,
  Data.DB,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.UI.Intf,
  FireDAC.Phys.Intf,
  FireDAC.Stan.Def,
  FireDAC.Stan.Pool,
  FireDAC.Stan.Async,
  FireDAC.Phys,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteWrapper.Stat,
  FireDAC.ConsoleUI.Wait,
  FireDAC.Comp.Client,
  FireDAC.DApt,
  Dext.Persistence,
  Dext.Entity.Drivers.FireDAC,
  Dext.Entity.Dialects,
  EntityDemo.Entities;

type
  TBaseTest = class
  protected
    FConn: TFDConnection;
    FContext: TDbContext;
    
    procedure Log(const Msg: string);
    procedure LogSuccess(const Msg: string);
    procedure LogError(const Msg: string);
    procedure AssertTrue(Condition: Boolean; const SuccessMsg, FailMsg: string);
    
    procedure Setup; virtual;
    procedure TearDown; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Run; virtual; abstract;
  end;

implementation

{ TBaseTest }

constructor TBaseTest.Create;
begin
  inherited;
  Setup;
end;

destructor TBaseTest.Destroy;
begin
  TearDown;
  inherited;
end;

procedure TBaseTest.Setup;
begin
  // 1. Setup FireDAC Connection (SQLite In-Memory)
  FConn := TFDConnection.Create(nil);
  FConn.DriverName := 'SQLite';
  FConn.Params.Database := ':memory:';
  FConn.LoginPrompt := False;
  FConn.Connected := True;

  // 2. Initialize Context
  FContext := TDbContext.Create(TFireDACConnection.Create(FConn, False), TSQLiteDialect.Create);
  
  // 3. Register Entities & Create Schema
  FContext.Entities<TAddress>;
  FContext.Entities<TUser>;
  FContext.Entities<TOrderItem>;
  FContext.Entities<TProduct>;
  FContext.EnsureCreated;
end;

procedure TBaseTest.TearDown;
begin
  FContext.Free;
  FConn.Free;
end;

procedure TBaseTest.Log(const Msg: string);
begin
  WriteLn(Msg);
end;

procedure TBaseTest.LogSuccess(const Msg: string);
begin
  WriteLn('   ✅ ' + Msg);
end;

procedure TBaseTest.LogError(const Msg: string);
begin
  WriteLn('   ❌ ' + Msg);
end;

procedure TBaseTest.AssertTrue(Condition: Boolean; const SuccessMsg, FailMsg: string);
begin
  if Condition then
    LogSuccess(SuccessMsg)
  else
    LogError(FailMsg);
end;

end.

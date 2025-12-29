unit TestUnit;

interface

procedure RunTest;

implementation

uses
  System.SysUtils,
  Data.DB,
  FireDAC.Comp.Client,
  FireDAC.Phys.SQLite,
  FireDAC.Stan.Def,
  FireDAC.Stan.Async,
  FireDAC.DApt,
  FireDAC.UI.Intf,
  FireDAC.ConsoleUI.Wait,
  Dext,
  Dext.Collections,
  Dext.Core.SmartTypes,
  Dext.Entity.Drivers.Interfaces,
  Dext.Entity.Core,
  Dext.Entity.Drivers.FireDAC,
  Dext.Entity.DbSet,
  Dext.Entity.Dialects,
  Dext.Entity.Attributes,
  Dext.Entity.Prototype,
  Dext.Entity;

type
  [Table('People')]
  TPerson = class
  private
    FId: Integer;
    FName: string;
    FAge: Integer;
  public
    [PK, AutoInc]
    property Id: Integer read FId write FId;
    property Name: string read FName write FName;
    property Age: Integer read FAge write FAge;
  end;

  [Table('SmartPeople')]
  TSmartPerson = class
  private
    FId: IntType;
    FName: StringType;
    FAge: IntType;
  public
    [PK, AutoInc]
    property Id: IntType read FId write FId;
    property Name: StringType read FName write FName;
    property Age: IntType read FAge write FAge;
  end;

procedure RunTest;
var
  FDConn: TFDConnection;
  Conn: IDbConnection;
  Ctx: TDbContext;
  SetPerson: IDbSet<TSmartPerson>;
  P: TSmartPerson;
  List: IList<TSmartPerson>;
begin
  Writeln('Starting Smart Properties Test...');
  
  FDConn := TFDConnection.Create(nil);
  try
    FDConn.DriverName := 'SQLite';
    FDConn.Params.Values['Database'] := ':memory:';
    FDConn.LoginPrompt := False;
    Conn := TFireDACConnection.Create(FDConn, True); 
    
    Ctx := TDbContext.Create(Conn, TSQLiteDialect.Create);
    try
      Conn.Connect;
      
      SetPerson := Ctx.Entities<TSmartPerson>;
      Ctx.EnsureCreated; 
      // EnsureCreated creates table based on entity. 
      // Prop<Integer> should be mapped to integer column type via TPropConverter logic?
      // Actually SQL Generator uses TypeInfo.
      // If TypeInfo is Prop<Integer>, it needs to know SQL type.
      // I might need to check if TSqlGenerator handles Prop<T>.
      
      Writeln('Table Created.');
      
      P := TSmartPerson.Create;
      P.Name := 'Smart John';
      P.Age := 30;
      
      SetPerson.Add(P);
      Ctx.SaveChanges;
      Writeln('Person Added. ID: ' + IntToStr(P.Id));

      // Test Smart Query using Prototype.Entity<T> - Cached API!
      // Prototypes are cached per type for performance.
      var u := Prototype.Entity<TSmartPerson>;
      
      // Simple Query
      List := SetPerson.Where(u.Age = 30).ToList;
      Writeln('Query (Age = 30) Result Count: ' + IntToStr(List.Count));
      if List.Count <> 1 then Writeln('ERROR: Expected 1 result');
      
      // Another Query
      List := SetPerson.Where(u.Age > 40).ToList;
      Writeln('Query (Age > 40) Result Count: ' + IntToStr(List.Count));
      if List.Count <> 0 then Writeln('ERROR: Expected 0 results');
      
      // Chaining
      List := SetPerson.Where(u.Age > 20)
                       .Where(u.Name = 'Smart John')
                       .ToList;
      Writeln('Chained Query Result Count: ' + IntToStr(List.Count));
      if List.Count <> 1 then Writeln('ERROR: Expected 1 result from chained query');
        
    finally
      // P is owned by the Context (IdentityMap) once added and saved.
      // Do not free P manually.
      Ctx.Free;
    end;
    
  except
    on E: Exception do
      Writeln('EXCEPTION: ' + E.ClassName + ': ' + E.Message);
  end;
end;

end.

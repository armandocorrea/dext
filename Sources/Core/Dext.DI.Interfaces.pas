unit Dext.DI.Interfaces;

interface

uses
  System.SysUtils,
  System.TypInfo;

type
  IServiceCollection = interface;
  IServiceProvider = interface;

  TServiceLifetime = (Singleton, Transient, Scoped);

  // Tipo para identificar serviços (pode ser TClass ou TGUID para interfaces)
  TServiceType = record
  private
    FTypeInfo: Pointer;
    FIsInterface: Boolean;
  public
    class function FromClass(AClass: TClass): TServiceType; overload; static;
    class function FromClass(ATypeInfo: PTypeInfo): TServiceType; overload; static;
    class function FromInterface(const AGuid: TGUID): TServiceType; static;

    function IsClass: Boolean;
    function IsInterface: Boolean;
    function AsClass: TClass;
    function AsInterface: TGUID;
    function ToString: string;

    class operator Equal(const A, B: TServiceType): Boolean;
  end;

  IServiceCollection = interface
    ['{A1F8C5D2-8B4E-4A7D-9C3B-6E8F4A2D1C7A}']

    function AddSingleton(const AServiceType: TServiceType;
                         const AImplementationClass: TClass;
                         const AFactory: TFunc<IServiceProvider, TObject> = nil): IServiceCollection; overload;

    function AddTransient(const AServiceType: TServiceType;
                          const AImplementationClass: TClass;
                          const AFactory: TFunc<IServiceProvider, TObject> = nil): IServiceCollection; overload;

    function AddScoped(const AServiceType: TServiceType;
                       const AImplementationClass: TClass;
                       const AFactory: TFunc<IServiceProvider, TObject> = nil): IServiceCollection; overload;

    function BuildServiceProvider: IServiceProvider;
  end;

  IServiceProvider = interface
    ['{B2E7D3F4-9C6E-4B8A-8D2C-7F5A1B3E8D9F}']
    function GetService(const AServiceType: TServiceType): TObject;
    function GetServiceAsInterface(const AServiceType: TServiceType): IInterface;
    function GetRequiredService(const AServiceType: TServiceType): TObject;
    function CreateScope: IInterface; // Returns IServiceScope
  end;

  /// <summary>
  ///   Represents a scope for service resolution.
  ///   Scoped services are created once per scope and shared within that scope.
  /// </summary>
  IServiceScope = interface
    ['{C3F8E4D5-7A9B-4C6D-8E2F-9A1B3C4D5E6F}']
    function GetServiceProvider: IServiceProvider;
    property ServiceProvider: IServiceProvider read GetServiceProvider;
  end;

  /// <summary>
  ///   Factory for creating service scopes.
  /// </summary>
  IServiceScopeFactory = interface
    ['{D4A9F5E6-8B1C-4D7E-9F3A-1B2C3D4E5F6A}']
    function CreateScope: IServiceScope;
  end;

  EDextDIException = class(Exception);

  TDextDIFactory = class
    class function CreateServiceCollection: IServiceCollection;
  end;

  /// <summary>
  ///   Fluent wrapper for IServiceCollection.
  /// </summary>
  TDextServices = record
  private
    FServices: IServiceCollection;
  public
    constructor Create(AServices: IServiceCollection);

    // Core DI
    function AddSingleton<T: class>(const AFactory: TFunc<IServiceProvider, TObject> = nil): TDextServices; overload;
    function AddTransient<T: class>(const AFactory: TFunc<IServiceProvider, TObject> = nil): TDextServices; overload;
    function AddScoped<T: class>(const AFactory: TFunc<IServiceProvider, TObject> = nil): TDextServices; overload;

    function AddSingleton<TService: IInterface; TImplementation: class>(const AFactory: TFunc<IServiceProvider, TObject> = nil): TDextServices; overload;
    function AddTransient<TService: IInterface; TImplementation: class>(const AFactory: TFunc<IServiceProvider, TObject> = nil): TDextServices; overload;
    function AddScoped<TService: IInterface; TImplementation: class>(const AFactory: TFunc<IServiceProvider, TObject> = nil): TDextServices; overload;

    // Non-generic overloads (forward to IServiceCollection)
    function AddSingleton(const AServiceType: TServiceType; const AImplementationClass: TClass; const AFactory: TFunc<IServiceProvider, TObject> = nil): TDextServices; overload;
    function AddTransient(const AServiceType: TServiceType; const AImplementationClass: TClass; const AFactory: TFunc<IServiceProvider, TObject> = nil): TDextServices; overload;
    function AddScoped(const AServiceType: TServiceType; const AImplementationClass: TClass; const AFactory: TFunc<IServiceProvider, TObject> = nil): TDextServices; overload;

    function BuildServiceProvider: IServiceProvider;
    function Unwrap: IServiceCollection;
    
    class operator Implicit(const A: TDextServices): IServiceCollection;
  end;

implementation

{ TDextServices }

constructor TDextServices.Create(AServices: IServiceCollection);
begin
  FServices := AServices;
end;

function TDextServices.AddSingleton<T>(const AFactory: TFunc<IServiceProvider, TObject>): TDextServices;
begin
  FServices.AddSingleton(TServiceType.FromClass(T), T, AFactory);
  Result := Self;
end;

function TDextServices.AddTransient<T>(const AFactory: TFunc<IServiceProvider, TObject>): TDextServices;
begin
  FServices.AddTransient(TServiceType.FromClass(T), T, AFactory);
  Result := Self;
end;

function TDextServices.AddScoped<T>(const AFactory: TFunc<IServiceProvider, TObject>): TDextServices;
begin
  FServices.AddScoped(TServiceType.FromClass(T), T, AFactory);
  Result := Self;
end;

function TDextServices.AddSingleton<TService, TImplementation>(const AFactory: TFunc<IServiceProvider, TObject>): TDextServices;
var
  Guid: TGUID;
begin
  Guid := GetTypeData(TypeInfo(TService))^.Guid;
  FServices.AddSingleton(TServiceType.FromInterface(Guid), TImplementation, AFactory);
  Result := Self;
end;

function TDextServices.AddTransient<TService, TImplementation>(const AFactory: TFunc<IServiceProvider, TObject>): TDextServices;
var
  Guid: TGUID;
begin
  Guid := GetTypeData(TypeInfo(TService))^.Guid;
  FServices.AddTransient(TServiceType.FromInterface(Guid), TImplementation, AFactory);
  Result := Self;
end;

function TDextServices.AddScoped<TService, TImplementation>(const AFactory: TFunc<IServiceProvider, TObject>): TDextServices;
var
  Guid: TGUID;
begin
  Guid := GetTypeData(TypeInfo(TService))^.Guid;
  FServices.AddScoped(TServiceType.FromInterface(Guid), TImplementation, AFactory);
  Result := Self;
end;

// Non-generic overloads
function TDextServices.AddSingleton(const AServiceType: TServiceType; const AImplementationClass: TClass; const AFactory: TFunc<IServiceProvider, TObject>): TDextServices;
begin
  FServices.AddSingleton(AServiceType, AImplementationClass, AFactory);
  Result := Self;
end;

function TDextServices.AddTransient(const AServiceType: TServiceType; const AImplementationClass: TClass; const AFactory: TFunc<IServiceProvider, TObject>): TDextServices;
begin
  FServices.AddTransient(AServiceType, AImplementationClass, AFactory);
  Result := Self;
end;

function TDextServices.AddScoped(const AServiceType: TServiceType; const AImplementationClass: TClass; const AFactory: TFunc<IServiceProvider, TObject>): TDextServices;
begin
  FServices.AddScoped(AServiceType, AImplementationClass, AFactory);
  Result := Self;
end;

function TDextServices.BuildServiceProvider: IServiceProvider;
begin
  Result := FServices.BuildServiceProvider;
end;

function TDextServices.Unwrap: IServiceCollection;
begin
  Result := FServices;
end;

class operator TDextServices.Implicit(const A: TDextServices): IServiceCollection;
begin
  Result := A.FServices;
end;


{ TServiceType }

//class function TServiceType.FromClass(AClass: TClass): TServiceType;
//begin
//  Result.FTypeInfo := AClass;
//  Result.FIsInterface := False;
//end;

class function TServiceType.FromClass(AClass: TClass): TServiceType;
begin
  Result.FIsInterface := False;
  Result.FTypeInfo := AClass.ClassInfo;  // ✅ Usar ClassInfo em vez de TypeInfo
end;

class function TServiceType.FromClass(ATypeInfo: PTypeInfo): TServiceType;
begin
  if (ATypeInfo.Kind <> tkClass) then
    raise EDextDIException.Create('TypeInfo must be for a class');

  Result.FIsInterface := False;
  Result.FTypeInfo := ATypeInfo;
end;

class function TServiceType.FromInterface(const AGuid: TGUID): TServiceType;
begin
  Result.FTypeInfo := AllocMem(SizeOf(TGUID));
  PGUID(Result.FTypeInfo)^ := AGuid;
  Result.FIsInterface := True;
end;

function TServiceType.IsClass: Boolean;
begin
  Result := not FIsInterface;
end;

function TServiceType.IsInterface: Boolean;
begin
  Result := FIsInterface;
end;

//function TServiceType.AsClass: TClass;
//begin
//  if not FIsInterface then
//    Result := TClass(FTypeInfo)
//  else
//    raise EDextDIException.Create('Service type is an interface, not a class');
//end;

function TServiceType.AsClass: TClass;
begin
  if not FIsInterface then
  begin
    // ✅ CORREÇÃO: Obter a classe do TypeInfo de forma segura
    var LTypeData := GetTypeData(FTypeInfo);
    if Assigned(LTypeData) then
      Result := LTypeData^.ClassType
    else
      raise EDextDIException.Create('Invalid class type info');
  end
  else
    raise EDextDIException.Create('Service type is an interface, not a class');
end;

function TServiceType.AsInterface: TGUID;
begin
  if FIsInterface then
    Result := PGUID(FTypeInfo)^
  else
    raise EDextDIException.Create('Service type is a class, not an interface');
end;

class operator TServiceType.Equal(const A, B: TServiceType): Boolean;
begin
  if A.FIsInterface <> B.FIsInterface then
    Exit(False);

  if A.FIsInterface then
    Result := IsEqualGUID(A.AsInterface, B.AsInterface)
  else
    Result := A.AsClass = B.AsClass;
end;

function TServiceType.ToString: string;
begin
  if FIsInterface then
    Result := 'I:' + GUIDToString(AsInterface)
  else
    Result := 'C:' + AsClass.ClassName;
end;

{ TDextDIFactory }

class function TDextDIFactory.CreateServiceCollection: IServiceCollection;
begin
  // Será implementado no Dext.DI.Core
  Result := nil;
end;

end.

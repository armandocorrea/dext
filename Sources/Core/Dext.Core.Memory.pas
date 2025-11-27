unit Dext.Core.Memory;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Internal interface to manage object lifetime via ARC.
  /// </summary>
  ILifetime<T: class> = interface
    function GetValue: T;
  end;

  /// <summary>
  ///   Implementation of lifetime manager.
  /// </summary>
  TLifetime<T: class> = class(TInterfacedObject, ILifetime<T>)
  private
    FValue: T;
  public
    constructor Create(AValue: T);
    destructor Destroy; override;
    function GetValue: T;
  end;

  /// <summary>
  ///   Interface for deferred actions.
  /// </summary>
  IDeferred = interface
    ['{D1E2F3A4-B5C6-4D7E-8F9A-0B1C2D3E4F5A}']
  end;

  /// <summary>
  ///   Implementation of deferred action.
  /// </summary>
  TDeferredAction = class(TInterfacedObject, IDeferred)
  private
    FAction: TProc;
  public
    constructor Create(AAction: TProc);
    destructor Destroy; override;
  end;

implementation

{ TLifetime<T> }

constructor TLifetime<T>.Create(AValue: T);
begin
  inherited Create;
  FValue := AValue;
end;

destructor TLifetime<T>.Destroy;
begin
  FValue.Free;
  inherited;
end;

function TLifetime<T>.GetValue: T;
begin
  Result := FValue;
end;

{ TDeferredAction }

constructor TDeferredAction.Create(AAction: TProc);
begin
  inherited Create;
  FAction := AAction;
end;

destructor TDeferredAction.Destroy;
begin
  if Assigned(FAction) then
    FAction();
  inherited;
end;

end.

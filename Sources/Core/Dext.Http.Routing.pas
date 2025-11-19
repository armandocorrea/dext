unit Dext.Http.Routing;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.RegularExpressions,
  Dext.Http.Interfaces;

type
  TRoutePattern = class
  private
    FPattern: string;
    FRegex: TRegEx;
    FParameterNames: TArray<string>;

    function BuildRegexPattern(const APattern: string): string;
    function ExtractParameterNames(const APattern: string): TArray<string>;
  public
    constructor Create(const APattern: string);

    function Match(const APath: string; out AParams: TDictionary<string, string>): Boolean;

    property Pattern: string read FPattern;
    property ParameterNames: TArray<string> read FParameterNames;
  end;

  // ✅ NOVO: Interface para Route Matcher
  IRouteMatcher = interface
    ['{A1B2C3D4-E5F6-4A7B-8C9D-0E1F2A3B4C5D}']
    function FindMatchingRoute(const APath: string;
      out AHandler: TRequestDelegate;
      out ARouteParams: TDictionary<string, string>): Boolean;
  end;

  // ✅ NOVO: Implementação do Route Matcher
  TRouteMatcher = class(TInterfacedObject, IRouteMatcher)
  private
    FMappedRoutes: TDictionary<string, TRequestDelegate>;
    FRoutePatterns: TDictionary<TRoutePattern, TRequestDelegate>;

    function CloneRoutes(ASource: TDictionary<string, TRequestDelegate>): TDictionary<string, TRequestDelegate>;
    function ClonePatterns(ASource: TDictionary<TRoutePattern, TRequestDelegate>): TDictionary<TRoutePattern, TRequestDelegate>;
  public
    constructor Create(AMappedRoutes: TDictionary<string, TRequestDelegate>;
      ARoutePatterns: TDictionary<TRoutePattern, TRequestDelegate>);
    destructor Destroy; override;

    function FindMatchingRoute(const APath: string;
      out AHandler: TRequestDelegate;
      out ARouteParams: TDictionary<string, string>): Boolean;
  end;

  ERouteException = class(Exception);

implementation

{ TRoutePattern }

constructor TRoutePattern.Create(const APattern: string);
begin
  inherited Create;
  FPattern := APattern;

  if APattern = '' then
    raise ERouteException.Create('Route pattern cannot be empty');

  FParameterNames := ExtractParameterNames(APattern);
  FRegex := TRegEx.Create(BuildRegexPattern(APattern), [roIgnoreCase]);
end;

function TRoutePattern.ExtractParameterNames(const APattern: string): TArray<string>;
var
  Matches: TMatchCollection;
  I: Integer;
begin
  var PatternRegex := TRegEx.Create('\{(.+?)\}');
  Matches := PatternRegex.Matches(APattern);

  SetLength(Result, Matches.Count);
  for I := 0 to Matches.Count - 1 do
  begin
    Result[I] := Matches[I].Groups[1].Value;

    if Result[I].IsEmpty then
      raise ERouteException.CreateFmt('Invalid parameter name in pattern: %s', [APattern]);
  end;
end;

function TRoutePattern.BuildRegexPattern(const APattern: string): string;
begin
  Result := APattern;
  Result := TRegEx.Replace(Result, '([.+?^=!:${}()|\[\]\\])', '\\$1');
  Result := TRegEx.Replace(Result, '\\\{([^}]+)\\\}', '([^/]+)');
  Result := '^' + Result + '$';
end;

function TRoutePattern.Match(const APath: string;
  out AParams: TDictionary<string, string>): Boolean;
var
  Match: TMatch;
  I: Integer;
begin
  AParams := nil;
  Result := False;

  Match := FRegex.Match(APath);

  if Match.Success then
  begin
    AParams := TDictionary<string, string>.Create;

    try
      for I := 0 to High(FParameterNames) do
      begin
        if I + 1 < Match.Groups.Count then
          AParams.Add(FParameterNames[I], Match.Groups[I + 1].Value);
      end;

      Result := True;

    except
      AParams.Free;
      raise;
    end;
  end;
end;

{ TRouteMatcher }

constructor TRouteMatcher.Create(AMappedRoutes: TDictionary<string, TRequestDelegate>;
  ARoutePatterns: TDictionary<TRoutePattern, TRequestDelegate>);
begin
  inherited Create;
  FMappedRoutes := CloneRoutes(AMappedRoutes);
  FRoutePatterns := ClonePatterns(ARoutePatterns);
end;

destructor TRouteMatcher.Destroy;
var
  RoutePattern: TRoutePattern;
begin
  FMappedRoutes.Free;

  for RoutePattern in FRoutePatterns.Keys do
    RoutePattern.Free;
  FRoutePatterns.Free;

  inherited Destroy;
end;

function TRouteMatcher.CloneRoutes(ASource: TDictionary<string, TRequestDelegate>): TDictionary<string, TRequestDelegate>;
var
  Path: string;
begin
  Result := TDictionary<string, TRequestDelegate>.Create;
  for Path in ASource.Keys do
    Result.Add(Path, ASource[Path]);
end;

function TRouteMatcher.ClonePatterns(ASource: TDictionary<TRoutePattern, TRequestDelegate>): TDictionary<TRoutePattern, TRequestDelegate>;
var
  Pattern: TRoutePattern;
begin
  Result := TDictionary<TRoutePattern, TRequestDelegate>.Create;
  for Pattern in ASource.Keys do
  begin
    var NewPattern := TRoutePattern.Create(Pattern.Pattern);
    Result.Add(NewPattern, ASource[Pattern]);
  end;
end;

function TRouteMatcher.FindMatchingRoute(const APath: string;
  out AHandler: TRequestDelegate; out ARouteParams: TDictionary<string, string>): Boolean;
var
  RoutePattern: TRoutePattern;
begin
  ARouteParams := nil;
  Result := False;

  if FMappedRoutes.TryGetValue(APath, AHandler) then
    Exit(True);

  for RoutePattern in FRoutePatterns.Keys do
  begin
    if RoutePattern.Match(APath, ARouteParams) then
    begin
      AHandler := FRoutePatterns[RoutePattern];
      Exit(True);
    end;
  end;
end;

end.

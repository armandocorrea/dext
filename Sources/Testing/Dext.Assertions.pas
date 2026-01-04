{***************************************************************************}
{                                                                           }
{           Dext Framework                                                  }
{                                                                           }
{           Copyright (C) 2025 Cesar Romero & Dext Contributors             }
{                                                                           }
{           Licensed under the Apache License, Version 2.0 (the "License"); }
{           you may not use this file except in compliance with the License.}
{           You may obtain a copy of the License at                         }
{                                                                           }
{               http://www.apache.org/licenses/LICENSE-2.0                  }
{                                                                           }
{           Unless required by applicable law or agreed to in writing,      }
{           software distributed under the License is distributed on an     }
{           "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,    }
{           either express or implied. See the License for the specific     }
{           language governing permissions and limitations under the        }
{           License.                                                        }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  Author:  Cesar Romero                                                    }
{  Created: 2026-01-03                                                      }
{                                                                           }
{  Dext.Assertions - Fluent assertions inspired by FluentAssertions.        }
{                                                                           }
{  Usage:                                                                   }
{    ShouldString(Value).Be('expected');                                    }
{    ShouldInteger(N).BeGreaterThan(0);                                     }
{    ShouldBoolean(B).BeTrue;                                               }
{    ShouldAction(MyProc).Throw<EInvalidOp>;                                }
{                                                                           }
{***************************************************************************}
unit Dext.Assertions;

interface

uses
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.DateUtils,
  System.IOUtils;

type
  /// <summary>
  ///   Exception raised when an assertion fails.
  /// </summary>
  EAssertionFailed = class(Exception);



  /// <summary>
  ///   Fluent assertions for DateTime.
  /// </summary>
  ShouldDateTime = record
  private
    FValue: TDateTime;
    FReason: string;
    procedure Fail(const Message: string);
  public
    constructor Create(Value: TDateTime);
    function Be(Expected: TDateTime): ShouldDateTime;
    function BeCloseTo(Expected: TDateTime; PrecisionMS: Int64 = 1000): ShouldDateTime;
    function BeAfter(Expected: TDateTime): ShouldDateTime;
    function BeBefore(Expected: TDateTime): ShouldDateTime;
    function BeSameDateAs(Expected: TDateTime): ShouldDateTime; // Ignores time
    function Because(const Reason: string): ShouldDateTime;
  end;

  /// <summary>
  ///   String-specific Should assertions.
  /// </summary>
  ShouldString = record
  private
    FValue: string;
    FReason: string;
    procedure Fail(const Message: string);
  public
    constructor Create(const Value: string);
    
    function Be(const Expected: string): ShouldString;
    function BeEquivalentTo(const Expected: string): ShouldString;
    function BeEmpty: ShouldString;
    function NotBeEmpty: ShouldString;
    function Contain(const Substring: string): ShouldString;
    function NotContain(const Substring: string): ShouldString;
    function StartWith(const Prefix: string): ShouldString;
    function EndWith(const Suffix: string): ShouldString;
    function HaveLength(Expected: Integer): ShouldString;
    function MatchSnapshot(const SnapshotName: string): ShouldString;
    function Because(const Reason: string): ShouldString;
  end;

  /// <summary>
  ///   Integer-specific Should assertions.
  /// </summary>
  ShouldInteger = record
  private
    FValue: Integer;
    FReason: string;
    procedure Fail(const Message: string);
  public
    constructor Create(Value: Integer);
    
    function Be(Expected: Integer): ShouldInteger;
    function NotBe(Unexpected: Integer): ShouldInteger;
    function BeGreaterThan(Expected: Integer): ShouldInteger;
    function BeGreaterOrEqualTo(Expected: Integer): ShouldInteger;
    function BeLessThan(Expected: Integer): ShouldInteger;
    function BeLessOrEqualTo(Expected: Integer): ShouldInteger;
    function BeInRange(Min, Max: Integer): ShouldInteger;
    function BePositive: ShouldInteger;
    function BeNegative: ShouldInteger;
    function BeZero: ShouldInteger;
    function Because(const Reason: string): ShouldInteger;
  end;

  /// <summary>
  ///   Boolean-specific Should assertions.
  /// </summary>
  ShouldBoolean = record
  private
    FValue: Boolean;
    FReason: string;
    procedure Fail(const Message: string);
  public
    constructor Create(Value: Boolean);
    
    function BeTrue: ShouldBoolean;
    function BeFalse: ShouldBoolean;
    function Be(Expected: Boolean): ShouldBoolean;
    function Because(const Reason: string): ShouldBoolean;
  end;

  /// <summary>
  ///   Action-specific Should assertions for exceptions.
  /// </summary>
  ShouldAction = record
  private
    FAction: TProc;
    FReason: string;
    FExceptionClass: ExceptClass;
    FExceptionMessage: string;
    procedure Fail(const Message: string);
  public
    constructor Create(const Action: TProc);
    
    function Throw<E: Exception>: ShouldAction;
    function ThrowWithMessage(const ExpectedMessage: string): ShouldAction;
    function NotThrow: ShouldAction;
    function Because(const Reason: string): ShouldAction;
  end;

  /// <summary>
  ///   Double/Float-specific Should assertions.
  /// </summary>
  ShouldDouble = record
  private
    FValue: Double;
    FReason: string;
    FPrecision: Double;
    procedure Fail(const Message: string);
  public
    constructor Create(Value: Double);
    
    function Be(Expected: Double): ShouldDouble;
    function BeApproximately(Expected, Tolerance: Double): ShouldDouble;
    function BeGreaterThan(Expected: Double): ShouldDouble;
    function BeLessThan(Expected: Double): ShouldDouble;
    function BeInRange(Min, Max: Double): ShouldDouble;
    function BePositive: ShouldDouble;
    function BeNegative: ShouldDouble;
    function Because(const Reason: string): ShouldDouble;
  end;

  /// <summary>
  ///   Generic object/interface Should assertions.
  /// </summary>
  ShouldObject = record
  private
    FValue: TObject;
    FReason: string;
    procedure Fail(const Message: string);
  public
    constructor Create(Value: TObject);
    
    function BeNil: ShouldObject;
    function NotBeNil: ShouldObject;
    function BeOfType<T: class>: ShouldObject;
    function BeAssignableTo<T: class>: ShouldObject;
    function BeEquivalentTo(Expected: TObject): ShouldObject; // Deep compare via JSON
    function MatchSnapshot(const SnapshotName: string): ShouldObject;
    function Because(const Reason: string): ShouldObject;
  end;

  /// <summary>
  ///   Interface-specific Should assertions.
  /// </summary>
  ShouldInterface = record
  private
    FValue: IInterface;
    FReason: string;
    procedure Fail(const Message: string);
  public
    constructor Create(const Value: IInterface);
    
    function BeNil: ShouldInterface;
    function NotBeNil: ShouldInterface;
    function BeEquivalentTo(const Expected: IInterface): ShouldInterface;
    function MatchSnapshot(const SnapshotName: string): ShouldInterface;
    function Because(const Reason: string): ShouldInterface;
  end;



  /// <summary>
  ///   Generic list/enumerable assertions.
  /// </summary>
  ShouldList<T> = record
  private
    FEnumerable: IEnumerable<T>;
    FArray: TArray<T>;
    FIsArray: Boolean;
    FReason: string;
    procedure Fail(const Message: string);
    function GetCount: Integer;
  public
    constructor Create(const Value: IEnumerable<T>); overload;
    constructor Create(const Value: TArray<T>); overload;
    
    function BeEmpty: ShouldList<T>;
    function NotBeEmpty: ShouldList<T>;
    function HaveCount(Expected: Integer): ShouldList<T>;
    function HaveCountGreaterThan(Expected: Integer): ShouldList<T>;
    function Contain(const Item: T): ShouldList<T>;
    function NotContain(const Item: T): ShouldList<T>;
    function AllSatisfy(const Predicate: TPredicate<T>): ShouldList<T>;
    function AnySatisfy(const Predicate: TPredicate<T>): ShouldList<T>;
    function Because(const Reason: string): ShouldList<T>;
  end;

  // Global helper functions for cleaner syntax
  function Should(const Value: string): ShouldString; overload;
  function Should(Value: Integer): ShouldInteger; overload;
  function Should(Value: Boolean): ShouldBoolean; overload;
  function Should(Value: Double): ShouldDouble; overload;
  function Should(const Action: TProc): ShouldAction; overload;
  function Should(const Value: TObject): ShouldObject; overload;
  function Should(const Value: IInterface): ShouldInterface; overload;
  function ShouldDate(Value: TDateTime): ShouldDateTime; overload;

implementation

uses
  System.RegularExpressions,
  Dext.Json;

procedure VerifySnapshot(const Content, SnapshotName: string);
var
  SnapshotPath: string;
  VerifyPath: string;
  ExistingContent: string;
  BaseDir: string;
begin
  if SnapshotName = '' then
    raise Exception.Create('Snapshot name cannot be empty');

  // Directory: .\Snapshots relative to EXE
  BaseDir := TPath.Combine(ExtractFilePath(ParamStr(0)), 'Snapshots');
  if not TDirectory.Exists(BaseDir) then
    TDirectory.CreateDirectory(BaseDir);

  SnapshotPath := TPath.Combine(BaseDir, SnapshotName + '.json');
  VerifyPath := TPath.Combine(BaseDir, SnapshotName + '.received.json');

  // UPDATE SNAPSHOT mode (env var or missing file)
  if (GetEnvironmentVariable('SNAPSHOT_UPDATE') = '1') or (not TFile.Exists(SnapshotPath)) then
  begin
    TFile.WriteAllText(SnapshotPath, Content, TEncoding.UTF8);
    // Delete received file if exists
    if TFile.Exists(VerifyPath) then
      TFile.Delete(VerifyPath);
    Exit;
  end;

  // Compare
  ExistingContent := TFile.ReadAllText(SnapshotPath, TEncoding.UTF8);
  if Content <> ExistingContent then
  begin
    // Write received
    TFile.WriteAllText(VerifyPath, Content, TEncoding.UTF8);
    raise EAssertionFailed.CreateFmt(
      'Snapshot mismatch for "%s"!' + sLineBreak +
      'Expected location: %s' + sLineBreak +
      'Received mismatch saved at: %s',
      [SnapshotName, SnapshotPath, VerifyPath]);
  end
  else
  begin
      // Cleanup previous failures
      if TFile.Exists(VerifyPath) then
        TFile.Delete(VerifyPath);
  end;
end;

{ ShouldString }

constructor ShouldString.Create(const Value: string);
begin
  FValue := Value;
  FReason := '';
end;

procedure ShouldString.Fail(const Message: string);
begin
  if FReason <> '' then
    raise EAssertionFailed.Create(Message + ' because ' + FReason)
  else
    raise EAssertionFailed.Create(Message);
end;

function ShouldString.Be(const Expected: string): ShouldString;
begin
  if FValue <> Expected then
    Fail(Format('Expected "%s" but was "%s"', [Expected, FValue]));
  Result := Self;
end;

function ShouldString.BeEquivalentTo(const Expected: string): ShouldString;
begin
  if not SameText(FValue, Expected) then
    Fail(Format('Expected "%s" (case insensitive) but was "%s"', [Expected, FValue]));
  Result := Self;
end;

function ShouldString.BeEmpty: ShouldString;
begin
  if FValue <> '' then
    Fail(Format('Expected empty string but was "%s"', [FValue]));
  Result := Self;
end;

function ShouldString.NotBeEmpty: ShouldString;
begin
  if FValue = '' then
    Fail('Expected non-empty string but was empty');
  Result := Self;
end;

function ShouldString.Contain(const Substring: string): ShouldString;
begin
  if not FValue.Contains(Substring) then
    Fail(Format('Expected "%s" to contain "%s"', [FValue, Substring]));
  Result := Self;
end;

function ShouldString.NotContain(const Substring: string): ShouldString;
begin
  if FValue.Contains(Substring) then
    Fail(Format('Expected "%s" to not contain "%s"', [FValue, Substring]));
  Result := Self;
end;

function ShouldString.StartWith(const Prefix: string): ShouldString;
begin
  if not FValue.StartsWith(Prefix) then
    Fail(Format('Expected "%s" to start with "%s"', [FValue, Prefix]));
  Result := Self;
end;

function ShouldString.EndWith(const Suffix: string): ShouldString;
begin
  if not FValue.EndsWith(Suffix) then
    Fail(Format('Expected "%s" to end with "%s"', [FValue, Suffix]));
  Result := Self;
end;

function ShouldString.MatchSnapshot(const SnapshotName: string): ShouldString;
begin
  VerifySnapshot(FValue, SnapshotName);
  Result := Self;
end;

function ShouldString.HaveLength(Expected: Integer): ShouldString;
begin
  if Length(FValue) <> Expected then
    Fail(Format('Expected length %d but was %d', [Expected, Length(FValue)]));
  Result := Self;
end;

function ShouldString.Because(const Reason: string): ShouldString;
begin
  Result := Self;
  Result.FReason := Reason;
end;

{ ShouldInteger }

constructor ShouldInteger.Create(Value: Integer);
begin
  FValue := Value;
  FReason := '';
end;

procedure ShouldInteger.Fail(const Message: string);
begin
  if FReason <> '' then
    raise EAssertionFailed.Create(Message + ' because ' + FReason)
  else
    raise EAssertionFailed.Create(Message);
end;

function ShouldInteger.Be(Expected: Integer): ShouldInteger;
begin
  if FValue <> Expected then
    Fail(Format('Expected %d but was %d', [Expected, FValue]));
  Result := Self;
end;

function ShouldInteger.NotBe(Unexpected: Integer): ShouldInteger;
begin
  if FValue = Unexpected then
    Fail(Format('Did not expect %d', [FValue]));
  Result := Self;
end;

function ShouldInteger.BeGreaterThan(Expected: Integer): ShouldInteger;
begin
  if FValue <= Expected then
    Fail(Format('Expected %d to be greater than %d', [FValue, Expected]));
  Result := Self;
end;

function ShouldInteger.BeGreaterOrEqualTo(Expected: Integer): ShouldInteger;
begin
  if FValue < Expected then
    Fail(Format('Expected %d to be greater than or equal to %d', [FValue, Expected]));
  Result := Self;
end;

function ShouldInteger.BeLessThan(Expected: Integer): ShouldInteger;
begin
  if FValue >= Expected then
    Fail(Format('Expected %d to be less than %d', [FValue, Expected]));
  Result := Self;
end;

function ShouldInteger.BeLessOrEqualTo(Expected: Integer): ShouldInteger;
begin
  if FValue > Expected then
    Fail(Format('Expected %d to be less than or equal to %d', [FValue, Expected]));
  Result := Self;
end;

function ShouldInteger.BeInRange(Min, Max: Integer): ShouldInteger;
begin
  if (FValue < Min) or (FValue > Max) then
    Fail(Format('Expected %d to be in range [%d, %d]', [FValue, Min, Max]));
  Result := Self;
end;

function ShouldInteger.BePositive: ShouldInteger;
begin
  if FValue <= 0 then
    Fail(Format('Expected positive value but was %d', [FValue]));
  Result := Self;
end;

function ShouldInteger.BeNegative: ShouldInteger;
begin
  if FValue >= 0 then
    Fail(Format('Expected negative value but was %d', [FValue]));
  Result := Self;
end;

function ShouldInteger.BeZero: ShouldInteger;
begin
  if FValue <> 0 then
    Fail(Format('Expected zero but was %d', [FValue]));
  Result := Self;
end;

function ShouldInteger.Because(const Reason: string): ShouldInteger;
begin
  Result := Self;
  Result.FReason := Reason;
end;

{ ShouldBoolean }

constructor ShouldBoolean.Create(Value: Boolean);
begin
  FValue := Value;
  FReason := '';
end;

procedure ShouldBoolean.Fail(const Message: string);
begin
  if FReason <> '' then
    raise EAssertionFailed.Create(Message + ' because ' + FReason)
  else
    raise EAssertionFailed.Create(Message);
end;

function ShouldBoolean.BeTrue: ShouldBoolean;
begin
  if not FValue then
    Fail('Expected True but was False');
  Result := Self;
end;

function ShouldBoolean.BeFalse: ShouldBoolean;
begin
  if FValue then
    Fail('Expected False but was True');
  Result := Self;
end;

function ShouldBoolean.Be(Expected: Boolean): ShouldBoolean;
begin
  if FValue <> Expected then
    Fail(Format('Expected %s but was %s', [BoolToStr(Expected, True), BoolToStr(FValue, True)]));
  Result := Self;
end;

function ShouldBoolean.Because(const Reason: string): ShouldBoolean;
begin
  Result := Self;
  Result.FReason := Reason;
end;

{ ShouldAction }

constructor ShouldAction.Create(const Action: TProc);
begin
  FAction := Action;
  FReason := '';
  FExceptionClass := nil;
  FExceptionMessage := '';
end;

procedure ShouldAction.Fail(const Message: string);
begin
  if FReason <> '' then
    raise EAssertionFailed.Create(Message + ' because ' + FReason)
  else
    raise EAssertionFailed.Create(Message);
end;

function ShouldAction.Throw<E>: ShouldAction;
var
  ThrewException: Boolean;
  WrongType: Boolean;
  ActualClassName: string;
  ActualMessage: string;
begin
  ThrewException := False;
  WrongType := False;
  ActualClassName := '';
  ActualMessage := '';
  
  try
    FAction();
  except
    on Ex: Exception do
    begin
      ThrewException := True;
      ActualClassName := Ex.ClassName;
      ActualMessage := Ex.Message;
      
      if Ex is E then
      begin
        FExceptionClass := E;
        FExceptionMessage := Ex.Message;
      end
      else
        WrongType := True;
    end;
  end;
  
  if not ThrewException then
    Fail(Format('Expected exception %s but none was thrown', [E.ClassName]));
    
  if WrongType then
    Fail(Format('Expected exception %s but got %s: %s',
      [E.ClassName, ActualClassName, ActualMessage]));
  
  Result := Self;
end;

function ShouldAction.ThrowWithMessage(const ExpectedMessage: string): ShouldAction;
begin
  if FExceptionMessage <> ExpectedMessage then
    Fail(Format('Expected exception message "%s" but was "%s"',
      [ExpectedMessage, FExceptionMessage]));
  Result := Self;
end;

function ShouldAction.NotThrow: ShouldAction;
begin
  try
    FAction();
  except
    on E: Exception do
      Fail(Format('Expected no exception but got %s: %s', [E.ClassName, E.Message]));
  end;
  Result := Self;
end;

function ShouldAction.Because(const Reason: string): ShouldAction;
begin
  Result := Self;
  Result.FReason := Reason;
end;

{ ShouldDouble }

constructor ShouldDouble.Create(Value: Double);
begin
  FValue := Value;
  FReason := '';
  FPrecision := 0.0001; // Default precision
end;

procedure ShouldDouble.Fail(const Message: string);
begin
  if FReason <> '' then
    raise EAssertionFailed.Create(Message + ' because ' + FReason)
  else
    raise EAssertionFailed.Create(Message);
end;

function ShouldDouble.Be(Expected: Double): ShouldDouble;
begin
  if Abs(FValue - Expected) > FPrecision then
    Fail(Format('Expected %g but was %g', [Expected, FValue]));
  Result := Self;
end;

function ShouldDouble.BeApproximately(Expected, Tolerance: Double): ShouldDouble;
begin
  if Abs(FValue - Expected) > Tolerance then
    Fail(Format('Expected %g to be approximately %g (tolerance: %g)', [FValue, Expected, Tolerance]));
  Result := Self;
end;

function ShouldDouble.BeGreaterThan(Expected: Double): ShouldDouble;
begin
  if FValue <= Expected then
    Fail(Format('Expected %g to be greater than %g', [FValue, Expected]));
  Result := Self;
end;

function ShouldDouble.BeLessThan(Expected: Double): ShouldDouble;
begin
  if FValue >= Expected then
    Fail(Format('Expected %g to be less than %g', [FValue, Expected]));
  Result := Self;
end;

function ShouldDouble.BeInRange(Min, Max: Double): ShouldDouble;
begin
  if (FValue < Min) or (FValue > Max) then
    Fail(Format('Expected %g to be in range [%g, %g]', [FValue, Min, Max]));
  Result := Self;
end;

function ShouldDouble.BePositive: ShouldDouble;
begin
  if FValue <= 0 then
    Fail(Format('Expected positive value but was %g', [FValue]));
  Result := Self;
end;

function ShouldDouble.BeNegative: ShouldDouble;
begin
  if FValue >= 0 then
    Fail(Format('Expected negative value but was %g', [FValue]));
  Result := Self;
end;

function ShouldDouble.Because(const Reason: string): ShouldDouble;
begin
  Result := Self;
  Result.FReason := Reason;
end;

{ ShouldObject }

constructor ShouldObject.Create(Value: TObject);
begin
  FValue := Value;
  FReason := '';
end;

procedure ShouldObject.Fail(const Message: string);
begin
  if FReason <> '' then
    raise EAssertionFailed.Create(Message + ' because ' + FReason)
  else
    raise EAssertionFailed.Create(Message);
end;

function ShouldObject.BeNil: ShouldObject;
begin
  if FValue <> nil then
    Fail(Format('Expected nil but was %s', [FValue.ClassName]));
  Result := Self;
end;

function ShouldObject.NotBeNil: ShouldObject;
begin
  if FValue = nil then
    Fail('Expected a value but was nil');
  Result := Self;
end;

function ShouldObject.BeOfType<T>: ShouldObject;
begin
  if FValue = nil then
    Fail(Format('Expected %s but was nil', [T.ClassName]))
  else if FValue.ClassType <> T then
    Fail(Format('Expected %s but was %s', [T.ClassName, FValue.ClassName]));
  Result := Self;
end;

function ShouldObject.BeAssignableTo<T>: ShouldObject;
begin
  if FValue = nil then
    Fail(Format('Expected assignable to %s but was nil', [T.ClassName]))
  else if not (FValue is T) then
    Fail(Format('Expected assignable to %s but was %s', [T.ClassName, FValue.ClassName]));
  Result := Self;
end;

function ShouldObject.BeEquivalentTo(Expected: TObject): ShouldObject;
var
  JsonA, JsonB: string;
begin
  if FValue = Expected then Exit(Self);
  
  if (FValue = nil) and (Expected <> nil) then
    Fail('Expected object to be equivalent but found nil')
  else if (FValue <> nil) and (Expected = nil) then
    Fail('Expected object to be nil but found instance');
    
  // Serialize both to JSON for deep comparison
  JsonA := TDextJson.Serialize(FValue);
  JsonB := TDextJson.Serialize(Expected);
  
  if JsonA <> JsonB then
    Fail('Expected objects to be equivalent but found differences.' + sLineBreak +
         'Expected: ' + JsonB + sLineBreak +
         'Found:    ' + JsonA);
         
  Result := Self;
end;

function ShouldObject.MatchSnapshot(const SnapshotName: string): ShouldObject;
begin
  if FValue = nil then
    VerifySnapshot('null', SnapshotName)
  else
    VerifySnapshot(TDextJson.Serialize(FValue), SnapshotName);
  Result := Self;
end;

function ShouldObject.Because(const Reason: string): ShouldObject;
begin
  FReason := Reason;
  Result := Self;
end;




{ ShouldInterface }

constructor ShouldInterface.Create(const Value: IInterface);
begin
  FValue := Value;
  FReason := '';
end;

procedure ShouldInterface.Fail(const Message: string);
begin
  if FReason <> '' then
    raise EAssertionFailed.Create(Message + ' because ' + FReason)
  else
    raise EAssertionFailed.Create(Message);
end;

function ShouldInterface.BeNil: ShouldInterface;
begin
  if FValue <> nil then
    Fail('Expected nil interface but was not nil');
  Result := Self;
end;

function ShouldInterface.NotBeNil: ShouldInterface;
begin
  if FValue = nil then
    Fail('Expected non-nil interface but was nil');
  Result := Self;
end;

function ShouldInterface.BeEquivalentTo(const Expected: IInterface): ShouldInterface;
var
  JsonA, JsonB: string;
begin
  if FValue = Expected then Exit(Self);
  
  if (FValue = nil) and (Expected <> nil) then
    Fail('Expected interface to be equivalent but found nil')
  else if (FValue <> nil) and (Expected = nil) then
    Fail('Expected interface to be nil but found instance');
    
  JsonA := TDextJson.Serialize(TValue.From(FValue));
  JsonB := TDextJson.Serialize(TValue.From(Expected));
  
  if JsonA <> JsonB then
    Fail('Expected interfaces to be equivalent but found differences.' + sLineBreak +
         'Expected: ' + JsonB + sLineBreak +
         'Found:    ' + JsonA);
         
  Result := Self;
end;

function ShouldInterface.MatchSnapshot(const SnapshotName: string): ShouldInterface;
begin
  if FValue = nil then
    VerifySnapshot('null', SnapshotName)
  else
    VerifySnapshot(TDextJson.Serialize(TValue.From(FValue)), SnapshotName);
  Result := Self;
end;

function ShouldInterface.Because(const Reason: string): ShouldInterface;
begin
  FReason := Reason;
  Result := Self;
end;

{ ShouldList<T> }

constructor ShouldList<T>.Create(const Value: IEnumerable<T>);
begin
  FEnumerable := Value;
  FIsArray := False;
  FArray := nil;
  FReason := '';
end;



constructor ShouldList<T>.Create(const Value: TArray<T>);
begin
  FEnumerable := nil;
  FIsArray := True;
  FArray := Value;
  FReason := '';
end;

procedure ShouldList<T>.Fail(const Message: string);
begin
  if FReason <> '' then
    raise EAssertionFailed.Create(Message + ' because ' + FReason)
  else
    raise EAssertionFailed.Create(Message);
end;

function ShouldList<T>.GetCount: Integer;
var
  Item: T;
  C: Integer;
begin
  if FIsArray then
    Result := Length(FArray)
  else if FEnumerable <> nil then
  begin
    C := 0;
    for Item in FEnumerable do
      Inc(C);
    Result := C;
  end
  else
    Result := 0; // nil list
end;

function ShouldList<T>.BeEmpty: ShouldList<T>;
var
  C: Integer;
begin
  C := GetCount;
  if C > 0 then
    Fail(Format('Expected empty list but found %d items', [C]));
  Result := Self;
end;

function ShouldList<T>.NotBeEmpty: ShouldList<T>;
begin
  if GetCount = 0 then
    Fail('Expected non-empty list but was empty');
  Result := Self;
end;

function ShouldList<T>.HaveCount(Expected: Integer): ShouldList<T>;
var
  C: Integer;
begin
  C := GetCount;
  if C <> Expected then
    Fail(Format('Expected count %d but was %d', [Expected, C]));
  Result := Self;
end;

function ShouldList<T>.HaveCountGreaterThan(Expected: Integer): ShouldList<T>;
var
  C: Integer;
begin
  C := GetCount;
  if C <= Expected then
    Fail(Format('Expected count greater than %d but was %d', [Expected, C]));
  Result := Self;
end;

function ShouldList<T>.Contain(const Item: T): ShouldList<T>;
var
  Found: Boolean;
  EnumItem: T;
  Comparer: IEqualityComparer<T>;
begin
  Found := False;
  Comparer := TEqualityComparer<T>.Default;
  
  if FIsArray then
  begin
    for EnumItem in FArray do
      if Comparer.Equals(EnumItem, Item) then
      begin
        Found := True;
        Break;
      end;
  end
  else if FEnumerable <> nil then
  begin
    for EnumItem in FEnumerable do
      if Comparer.Equals(EnumItem, Item) then
      begin
        Found := True;
        Break;
      end;
  end;
  
  if not Found then
    Fail('Expected list to contain item but it did not');
  Result := Self;
end;

function ShouldList<T>.NotContain(const Item: T): ShouldList<T>;
var
  Found: Boolean;
  EnumItem: T;
  Comparer: IEqualityComparer<T>;
begin
  Found := False;
  Comparer := TEqualityComparer<T>.Default;
  
  if FIsArray then
  begin
    for EnumItem in FArray do
      if Comparer.Equals(EnumItem, Item) then
      begin
        Found := True;
        Break;
      end;
  end
  else if FEnumerable <> nil then
  begin
    for EnumItem in FEnumerable do
      if Comparer.Equals(EnumItem, Item) then
      begin
        Found := True;
        Break;
      end;
  end;
  
  if Found then
    Fail('Expected list to NOT contain item but it did');
  Result := Self;
end;

function ShouldList<T>.AllSatisfy(const Predicate: TPredicate<T>): ShouldList<T>;
var
  EnumItem: T;
  AllMatch: Boolean;
begin
  AllMatch := True;
  
  if FIsArray then
  begin
    for EnumItem in FArray do
      if not Predicate(EnumItem) then
      begin
        AllMatch := False;
        Break;
      end;
  end
  else if FEnumerable <> nil then
  begin
    for EnumItem in FEnumerable do
      if not Predicate(EnumItem) then
      begin
        AllMatch := False;
        Break;
      end;
  end;
  
  if not AllMatch then
    Fail('Expected all items to satisfy predicate but some did not');
  Result := Self;
end;

function ShouldList<T>.AnySatisfy(const Predicate: TPredicate<T>): ShouldList<T>;
var
  EnumItem: T;
  AnyMatch: Boolean;
begin
  AnyMatch := False;
  
  if FIsArray then
  begin
    for EnumItem in FArray do
      if Predicate(EnumItem) then
      begin
        AnyMatch := True;
        Break;
      end;
  end
  else if FEnumerable <> nil then
  begin
    for EnumItem in FEnumerable do
      if Predicate(EnumItem) then
      begin
        AnyMatch := True;
        Break;
      end;
  end;
  
  if not AnyMatch then
    Fail('Expected at least one item to satisfy predicate but none did');
  Result := Self;
end;

function ShouldList<T>.Because(const Reason: string): ShouldList<T>;
begin
  Result := Self;
  Result.FReason := Reason;
end;



{ ShouldDateTime }

constructor ShouldDateTime.Create(Value: TDateTime);
begin
  FValue := Value;
  FReason := '';
end;

procedure ShouldDateTime.Fail(const Message: string);
var
  Msg: string;
begin
  Msg := Message;
  if FReason <> '' then
    Msg := Msg + ' because ' + FReason;
  raise EAssertionFailed.Create(Msg);
end;

function ShouldDateTime.Be(Expected: TDateTime): ShouldDateTime;
begin
  if not SameDateTime(FValue, Expected) then
    Fail(Format('Expected %s but found %s', [DateTimeToStr(Expected), DateTimeToStr(FValue)]));
  Result := Self;
end;

function ShouldDateTime.BeCloseTo(Expected: TDateTime; PrecisionMS: Int64): ShouldDateTime;
var
  Diff: Int64;
begin
  Diff := MilliSecondsBetween(FValue, Expected);
  if Diff > PrecisionMS then
    Fail(Format('Expected date to be close to %s (within %dms) but found %s (diff %dms)',
      [DateTimeToStr(Expected), PrecisionMS, DateTimeToStr(FValue), Diff]));
  Result := Self;
end;

function ShouldDateTime.BeAfter(Expected: TDateTime): ShouldDateTime;
begin
  if not (FValue > Expected) then
    Fail(Format('Expected date to be after %s but found %s', [DateTimeToStr(Expected), DateTimeToStr(FValue)]));
  Result := Self;
end;

function ShouldDateTime.BeBefore(Expected: TDateTime): ShouldDateTime;
begin
  if not (FValue < Expected) then
    Fail(Format('Expected date to be before %s but found %s', [DateTimeToStr(Expected), DateTimeToStr(FValue)]));
  Result := Self;
end;

function ShouldDateTime.BeSameDateAs(Expected: TDateTime): ShouldDateTime;
begin
  if not SameDate(FValue, Expected) then
    Fail(Format('Expected date to be %s but found %s (ignoring time)',
      [DateToStr(Expected), DateToStr(FValue)]));
  Result := Self;
end;

function ShouldDateTime.Because(const Reason: string): ShouldDateTime;
begin
  FReason := Reason;
  Result := Self;
end;


{ Global Helper Functions }


function Should(const Value: string): ShouldString;
begin
  Result := ShouldString.Create(Value);
end;

function Should(Value: Integer): ShouldInteger;
begin
  Result := ShouldInteger.Create(Value);
end;

function Should(Value: Boolean): ShouldBoolean;
begin
  Result := ShouldBoolean.Create(Value);
end;

function Should(Value: Double): ShouldDouble;
begin
  Result := ShouldDouble.Create(Value);
end;

function Should(const Action: TProc): ShouldAction;
begin
  Result := ShouldAction.Create(Action);
end;

function Should(const Value: TObject): ShouldObject;
begin
  Result := ShouldObject.Create(Value);
end;

function Should(const Value: IInterface): ShouldInterface;
begin
  Result := ShouldInterface.Create(Value);
end;



function ShouldDate(Value: TDateTime): ShouldDateTime;
begin
  Result := ShouldDateTime.Create(Value);
end;

end.

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
{  Dext.Mocks.Auto - Auto-mocking container for constructor injection.      }
{                                                                           }
{***************************************************************************}
unit Dext.Mocks.Auto;

interface

uses
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  System.Generics.Collections,
  Dext.Interception,
  Dext.Interception.Proxy,
  Dext.Interception.ClassProxy,
  Dext.Mocks,
  Dext.Mocks.Interceptor;

type
  /// <summary>
  ///   Container that automatically creates and injects mocks into the constructor
  ///   of the system under test (SUT).
  /// </summary>
  TAutoMocker = class
  private
    FInterceptors: TDictionary<PTypeInfo, IInterceptor>;
    FClassProxies: TObjectList<TObject>;
    FContext: TRttiContext;
    function GetMockInterceptor(TypeInfo: PTypeInfo): TMockInterceptor;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    ///   Creates an instance of T, automatically injecting mocks for all interface parameters.
    /// </summary>
    function CreateInstance<T: class>: T;

    /// <summary>
    ///   Retrieves the mock instance for a specific interface type used in injection.
    /// </summary>
    function GetMock<T>: Mock<T>;
  end;

implementation

{ TAutoMocker }

constructor TAutoMocker.Create;
begin
  FInterceptors := TDictionary<PTypeInfo, IInterceptor>.Create;
  FClassProxies := TObjectList<TObject>.Create(True); // Owns proxies
  FContext := TRttiContext.Create;
end;

destructor TAutoMocker.Destroy;
begin
  FClassProxies.Free;
  FInterceptors.Free;
  FContext.Free;
  inherited;
end;

function TAutoMocker.GetMockInterceptor(TypeInfo: PTypeInfo): TMockInterceptor;
var
  Intf: IInterceptor;
  Obj: TMockInterceptor;
begin
  if FInterceptors.TryGetValue(TypeInfo, Intf) then
    Exit(Intf as TMockInterceptor);

  // Create new interceptor with Loose behavior (returns defaults)
  Obj := TMockInterceptor.Create(TMockBehavior.Loose);
  Intf := Obj; // Interface reference needed for storage
  FInterceptors.Add(TypeInfo, Intf);
  Result := Obj;
end;

function TAutoMocker.GetMock<T>: Mock<T>;
var
  Info: PTypeInfo;
  Interceptor: TMockInterceptor;
begin
  Info := TypeInfo(T);
  if not (Info.Kind in [tkInterface, tkClass]) then
    raise Exception.Create('T must be an interface or class');

  Interceptor := GetMockInterceptor(Info);
  
  // This creates a new proxy instance connected to the same interceptor
  Result := Mock<T>.Create(Interceptor);
end;

function TAutoMocker.CreateInstance<T>: T;
var
  RttiType: TRttiType;
  Method: TRttiMethod;
  ConstructorMethod: TRttiMethod;
  Params: TArray<TRttiParameter>;
  Args: TArray<TValue>;
  I: Integer;
  ParamType: TRttiType;
  Interceptor: IInterceptor;
  ProxyObj: TInterfaceProxy;
  ProxyIntf: IInterface;
  ParamInfo: PTypeInfo;
  GuidValue: TGUID;
  ObjRef: Pointer;
begin
  RttiType := FContext.GetType(TypeInfo(T));
  if RttiType = nil then
    raise Exception.Create('Type not found in RTTI: ' + T.ClassName);

  // Find constructor with most parameters
  ConstructorMethod := nil;
  for Method in RttiType.GetMethods do
  begin
    if Method.IsConstructor then
    begin
      if (ConstructorMethod = nil) or (Length(Method.GetParameters) > Length(ConstructorMethod.GetParameters)) then
        ConstructorMethod := Method;
    end;
  end;

  if ConstructorMethod = nil then
    raise Exception.Create('No constructor found for ' + T.ClassName);

  Params := ConstructorMethod.GetParameters;
  SetLength(Args, Length(Params));

  for I := 0 to High(Params) do
  begin
    ParamType := Params[I].ParamType;
    if ParamType.TypeKind = tkInterface then
    begin
       ParamInfo := ParamType.Handle;
       Interceptor := GetMockInterceptor(ParamInfo);
       
       // Create Proxy manually
       ProxyObj := TInterfaceProxy.Create(ParamInfo, [Interceptor], TValue.Empty);
       
       // Get Interface
       GuidValue := ParamInfo.TypeData.Guid;
       if ProxyObj.QueryInterface(GuidValue, ProxyIntf) <> S_OK then
         raise Exception.Create('Failed to query interface for mock: ' + ParamType.Name);
         
       Args[I] := TValue.From(ParamInfo, ProxyIntf);
    end
    else if ParamType.TypeKind = tkClass then
    begin
       ParamInfo := ParamType.Handle;
       Interceptor := GetMockInterceptor(ParamInfo);
       
       // Create Class Proxy
       // OwnsInstance=False because usually SUT takes ownership of dependencies injected into constructor.
       var CProxy := TClassProxy.Create(ParamInfo.TypeData.ClassType, [Interceptor], False);
       FClassProxies.Add(CProxy);
       
       ObjRef := CProxy.Instance;
       TValue.Make(@ObjRef, ParamInfo, Args[I]);
    end
    else
    begin
       // Use default value for non-interface types
       Args[I] := TValue.FromOrdinal(ParamType.Handle, 0); 
    end;
  end;

  Result := ConstructorMethod.Invoke(RttiType.AsInstance.MetaclassType, Args).AsType<T>;
end;

end.

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
{  Dext.Interception.ClassProxy - Virtual Method Interception for Classes   }
{                                                                           }
{***************************************************************************}
unit Dext.Interception.ClassProxy;

interface

uses
  System.Rtti,
  System.SysUtils,
  System.TypInfo,
  Dext.Interception,
  Dext.Interception.Proxy;

type
  /// <summary>
  ///   Proxy for class types using TVirtualMethodInterceptor.
  /// </summary>
  TClassProxy = class
  private
    FVMI: TVirtualMethodInterceptor;
    FInstance: TObject;
    FInterceptors: TArray<IInterceptor>;
    FOwnsInstance: Boolean;
    
    procedure DoBefore(Instance: TObject; Method: TRttiMethod;
      const Args: TArray<TValue>; out DoInvoke: Boolean; out Result: TValue);
  public
    /// <summary>
    ///   Creates a class proxy. 
    ///   Note: This instantiates the class using basic TObject.Create behavior.
    ///   Constructors of the target class are NOT executed unless invoked manually via RTTI.
    /// </summary>
    constructor Create(AClass: TClass; const AInterceptors: TArray<IInterceptor>; AOwnsInstance: Boolean = True);
    destructor Destroy; override;
    
    property Instance: TObject read FInstance;
    property OwnsInstance: Boolean read FOwnsInstance write FOwnsInstance;
  end;

implementation

{ TClassProxy }

constructor TClassProxy.Create(AClass: TClass; const AInterceptors: TArray<IInterceptor>; AOwnsInstance: Boolean);
begin
  inherited Create;
  FInterceptors := AInterceptors;
  FOwnsInstance := AOwnsInstance;
  
  // Create instance (Allocates memory, VTable pointing to original class)
  FInstance := AClass.Create;
  
  // Create Interceptor for the class
  FVMI := TVirtualMethodInterceptor.Create(AClass);
  
  // Setup callbacks
  FVMI.OnBefore := DoBefore;
  
  // Install interceptor on specific instance
  // This overwrites the VTable pointer in FInstance to point to VMI's dynamic VTable
  FVMI.Proxify(FInstance);
end;

destructor TClassProxy.Destroy;
begin
  if FVMI <> nil then
  begin
    // Safely un-proxify before destruction?
    // Unproxify reverts VTable. Not strictly needed if instance acts as mock until death.
    FVMI.Free;
  end;
  
  if FOwnsInstance then
    FInstance.Free;
  inherited;
end;

procedure TClassProxy.DoBefore(Instance: TObject; Method: TRttiMethod;
  const Args: TArray<TValue>; out DoInvoke: Boolean; out Result: TValue);
var
  Invocation: IInvocation;
begin
  // Create invocation wrapper
  Invocation := TInvocation.Create(Method, Args, FInterceptors, Instance);
  
  // Execute interception chain
  Invocation.Proceed;
  
  // Set result
  Result := Invocation.Result;
  
  // Suppress original execution (Loose mock behavior)
  // TODO: Support CallBase via behavior config
  DoInvoke := False;
end;

end.

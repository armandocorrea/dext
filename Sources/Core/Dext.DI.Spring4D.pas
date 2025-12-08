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
{  Created: 2025-12-08                                                      }
{                                                                           }
{***************************************************************************}
// Dext.DI.Spring4D.pas
unit Dext.DI.Spring4D;

interface

uses
  Dext.DI.Interfaces,
  Spring.Container;

type
  TSpring4DServiceProvider = class(TInterfacedObject, IServiceProvider)
  private
    FContainer: TContainer;
  public
    constructor Create(AContainer: TContainer);
    function GetService(const AServiceType: TClass): TObject;
    function GetService<T: class>: T;
    function GetRequiredService(const AServiceType: TClass): TObject;
    function GetRequiredService<T: class>: T;
  end;

  TSpring4DServiceCollection = class(TInterfacedObject, IServiceCollection)
  private
    FContainer: TContainer;
  public
    constructor Create(AContainer: TContainer = nil);
    destructor Destroy; override;

    function AddSingleton(const AServiceType: TClass;
                         const AImplementationType: TClass = nil;
                         const AFactory: TFunc<IServiceProvider, TObject> = nil): IServiceCollection; overload;
    // ... implementar outros mÃ©todos

    function BuildServiceProvider: IServiceProvider;
  end;


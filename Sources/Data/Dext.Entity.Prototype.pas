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
{  Created: 2025-12-27                                                      }
{                                                                           }
{  Prototype - Creates "ghost entities" for query building.                 }
{                                                                           }
{  Prototypes are cached per type for performance (avoids RTTI overhead).   }
{  Since prototypes are readonly (only metadata), caching is safe.          }
{                                                                           }
{  Usage:                                                                   }
{    var u := Prototype.Entity<TSmartPerson>;                               }
{    List := SetPerson.Where(u.Age = 30).ToList;                            }
{                                                                           }
{***************************************************************************}
unit Dext.Entity.Prototype;

interface

uses
  System.Character,
  System.Generics.Collections,
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  Dext.Core.SmartTypes;

type
  /// <summary>
  ///   Factory class for creating and caching prototype entities.
  ///   Prototypes are cached per type for performance.
  /// </summary>
  Prototype = class
  private class var
    FCache: TDictionary<PTypeInfo, TObject>;
    class constructor Create;
    class destructor Destroy;
    class function CreatePrototype(ATypeInfo: PTypeInfo): TObject; static;
  public
    /// <summary>
    ///   Returns a cached prototype entity for query building.
    ///   Creates and caches the prototype on first call for each type.
    /// </summary>
    class function Entity<T>: T; static;
    
    /// <summary>
    ///   Clears the prototype cache. Useful for testing or hot-reload scenarios.
    /// </summary>
    class procedure ClearCache; static;
  end;

  // Backward compatibility alias
  Build = Prototype;

implementation

uses
  Dext.Entity.Core,
  Dext.Entity.Mapping;

{ Prototype }

class constructor Prototype.Create;
begin
  FCache := TDictionary<PTypeInfo, TObject>.Create;
end;

class destructor Prototype.Destroy;
var
  Obj: TObject;
begin
  if FCache <> nil then
  begin
    for Obj in FCache.Values do
      Obj.Free;
    FCache.Free;
  end;
end;

class procedure Prototype.ClearCache;
var
  Obj: TObject;
begin
  for Obj in FCache.Values do
    Obj.Free;
  FCache.Clear;
end;

class function Prototype.CreatePrototype(ATypeInfo: PTypeInfo): TObject;
var
  Ctx: TRttiContext;
  Typ: TRttiType;
  Fld: TRttiField;
  PropInfo: IPropInfo;
  MetaVal: TValue;
  RecType: TRttiRecordType;
  InfoField: TRttiField;
  InstancePtr: Pointer;
  PropertyName, ColumnName: string;
  EntityMap: TEntityMap;
  PropMap: TPropertyMap;
begin
  Ctx := TRttiContext.Create;
  try
    Typ := Ctx.GetType(ATypeInfo);
    if (Typ = nil) or (Typ.TypeKind <> tkClass) then
      raise Exception.Create('Prototype.Entity<T> only supports class types.');

    // Create Instance using RTTI
    var Method := Typ.GetMethod('Create');
    if Method <> nil then
    begin
      var Val := Method.Invoke(Typ.AsInstance.MetaclassType, []);
      Result := Val.AsObject;
    end
    else
    begin
      Result := Typ.AsInstance.MetaclassType.Create;
    end;
    
    InstancePtr := Result;

    EntityMap := TModelBuilder.Instance.GetMap(ATypeInfo);
    if EntityMap <> nil then
    begin
      for Fld in Typ.GetFields do
      begin
        if not Fld.FieldType.Name.StartsWith('Prop<') then
          Continue;

        PropertyName := Fld.Name;
        if (PropertyName.Length > 1) and 
           (PropertyName.Chars[0] = 'F') and 
           (PropertyName.Chars[1].IsUpper) then
          Delete(PropertyName, 1, 1);

        if EntityMap.Properties.TryGetValue(PropertyName, PropMap) then
          ColumnName := PropMap.ColumnName
        else
          ColumnName := PropertyName; 

        PropInfo := TPropInfo.Create(ColumnName);
        TValue.Make(@PropInfo, TypeInfo(IPropInfo), MetaVal);

        RecType := Fld.FieldType.AsRecord;
        InfoField := RecType.GetField('FInfo');

        if InfoField <> nil then
        begin
          InfoField.SetValue(
            Pointer(NativeInt(InstancePtr) + Fld.Offset), 
            MetaVal
          );
        end;
      end;
    end;
  finally
    Ctx.Free;
  end;
end;

class function Prototype.Entity<T>: T;
var
  TypeInfoPtr: PTypeInfo;
  Obj: TObject;
begin
  TypeInfoPtr := TypeInfo(T);
  
  // Runtime check for class type
  if PTypeInfo(TypeInfoPtr).Kind <> tkClass then
    raise Exception.Create('Prototype.Entity<T> only supports class types.');
  
  // Check cache first
  if FCache.TryGetValue(TypeInfoPtr, Obj) then
  begin
    // Use TValue to convert TObject to T without compile-time constraint
    Result := TValue.From(Obj).AsType<T>;
    Exit;
  end;
  
  // Create and cache new prototype
  Obj := CreatePrototype(TypeInfoPtr);
  FCache.Add(TypeInfoPtr, Obj);
  Result := TValue.From(Obj).AsType<T>;
end;

end.

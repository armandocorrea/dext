unit Dext.Entity.LazyLoading;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.Rtti,
  System.SysUtils,
  System.TypInfo,
  Dext.Entity.Core,
  Dext.Entity.Attributes,
  Dext.Types.Lazy,
  Dext.Specifications.Types,
  Dext.Specifications.Interfaces,
  Dext.Core.Activator;

type
  /// <summary>
  ///   Injects Lazy<T> logic into entities.
  /// </summary>
  TLazyInjector = class
  private
    class procedure InjectField(AContext: IDbContext; AEntity: TObject; AField: TRttiField);
  public
    class procedure Inject(AContext: IDbContext; AEntity: TObject);
  end;

  /// <summary>
  ///   Standard implementation of ILazy for Entity Framework.
  ///   Replaces the old TVirtualInterface-based approach.
  /// </summary>
  TLazyLoader = class(TInterfacedObject, ILazy)
  private
    FContextPtr: Pointer;
    FEntity: TObject;
    FPropName: string;
    FLoaded: Boolean;
    FValue: TValue;
    FIsCollection: Boolean;
    
    function GetDbContext: IDbContext;
    procedure LoadValue;
    
    // ILazy implementation
    function GetIsValueCreated: Boolean;
    function GetValue: TValue;
  public
    constructor Create(AContext: IDbContext; AEntity: TObject; const APropName: string; AIsCollection: Boolean);
    destructor Destroy; override;
  end;

implementation

{ Helper Functions }

/// <summary>
///   Unwraps Nullable<T> values and validates if FK is valid (non-zero for integers, non-empty for strings)
/// </summary>
function TryUnwrapAndValidateFK(var AValue: TValue; AContext: TRttiContext): Boolean;
var
  RType: TRttiType;
  TypeName: string;
  Fields: TArray<TRttiField>;
  HasValueField, ValueField: TRttiField;
  HasValue: Boolean;
  Instance: Pointer;
begin
  Result := False;
  
  // Handle Nullable<T> unwrapping
  if AValue.Kind = tkRecord then
  begin
    RType := AContext.GetType(AValue.TypeInfo);
    if RType <> nil then
    begin
      TypeName := RType.Name;
      
      // Check if it's a Nullable<T> by name (Delphi doesn't generate RTTI for generic record properties)
      if TypeName.StartsWith('Nullable<') or TypeName.StartsWith('TNullable') then
      begin
        // Access fields directly since GetProperty won't work for generic records
        Fields := RType.GetFields;
        HasValueField := nil;
        ValueField := nil;
        
        // Find fHasValue and fValue fields
        for var Field in Fields do
        begin
          if Field.Name.ToLower.Contains('hasvalue') then
            HasValueField := Field
          else if Field.Name.ToLower = 'fvalue' then
            ValueField := Field;
        end;
        
        if (HasValueField <> nil) and (ValueField <> nil) then
        begin
          Instance := AValue.GetReferenceToRawData;
          
          // Check HasValue - it can be a string (Spring4D) or Boolean
          var HasValueVal := HasValueField.GetValue(Instance);
          if HasValueVal.Kind = tkUString then
            HasValue := HasValueVal.AsString <> ''
          else if HasValueVal.Kind = tkEnumeration then
            HasValue := HasValueVal.AsBoolean
          else
            HasValue := False;
            
          if not HasValue then Exit; // Null, nothing to load
          
          // Get the actual value
          AValue := ValueField.GetValue(Instance);
        end
        else
          Exit; // Couldn't find fields, treat as invalid
      end;
    end;
  end;

  if AValue.IsEmpty then Exit;

  // Validate based on type
  if AValue.Kind in [tkInteger, tkInt64] then
    Result := AValue.AsInt64 <> 0
  else if AValue.Kind in [tkString, tkUString, tkWString, tkLString] then
    Result := AValue.AsString <> ''
  else
    Result := True; // For other types like GUID, assume valid if not empty
end;

{ TLazyInjector }

class procedure TLazyInjector.Inject(AContext: IDbContext; AEntity: TObject);
var
  Ctx: TRttiContext;
  Typ: TRttiType;
  Field: TRttiField;
begin
  Ctx := TRttiContext.Create;
  Typ := Ctx.GetType(AEntity.ClassType);
  
  for Field in Typ.GetFields do
  begin
    if Field.FieldType.Name.StartsWith('Lazy<') then
    begin
      InjectField(AContext, AEntity, Field);
    end;
  end;
end;

class procedure TLazyInjector.InjectField(AContext: IDbContext; AEntity: TObject; AField: TRttiField);
var
  LazyRecordType: TRttiRecordType;
  InstanceField: TRttiField;
  PropName: string;
  IsCollection: Boolean;
  Loader: TLazyLoader;
  LazyIntf: ILazy;
  LazyVal: TValue;
  IntfVal: TValue;
begin
  // 1. Determine Property Name from Field Name (FAddress -> Address)
  PropName := AField.Name;
  if PropName.StartsWith('F') then
    Delete(PropName, 1, 1);
    
  // 2. Determine if Collection
  IsCollection := False;
  if AField.FieldType.Name.Contains('TList<') or AField.FieldType.Name.Contains('TObjectList<') then
    IsCollection := True;

  // 3. Get Lazy<T> record structure
  LazyRecordType := AField.FieldType.AsRecord;
  InstanceField := LazyRecordType.GetField('FInstance');
  if InstanceField = nil then 
    Exit;
  
  // 4. Create Loader
  Loader := TLazyLoader.Create(AContext, AEntity, PropName, IsCollection);
  LazyIntf := Loader;

  // 5. Assign interface to Lazy<T>.FInstance
  LazyVal := AField.GetValue(AEntity);
  
  // Create TValue with ILazy type
  TValue.Make(@LazyIntf, TypeInfo(ILazy), IntfVal);
  
  // Set FInstance on the record
  InstanceField.SetValue(LazyVal.GetReferenceToRawData, IntfVal);
  
  // Set the record back to the entity
  AField.SetValue(AEntity, LazyVal);
end;

{ TLazyLoader }

constructor TLazyLoader.Create(AContext: IDbContext; AEntity: TObject; const APropName: string; AIsCollection: Boolean);
begin
  inherited Create;
  FContextPtr := Pointer(AContext);
  FEntity := AEntity;
  FPropName := APropName;
  FIsCollection := AIsCollection;
  FLoaded := False;
end;

destructor TLazyLoader.Destroy;
begin
  // WriteLn('DEBUG: TLazyLoader.Destroy (Collection=' + BoolToStr(FIsCollection, True) + ')');
  if FIsCollection and FLoaded and (not FValue.IsEmpty) then
  begin
    // If it's a collection, we own the TList/TObjectList created in LoadValue
    FValue.AsObject.Free;
  end;
  inherited;
end;

function TLazyLoader.GetDbContext: IDbContext;
begin
  Result := IDbContext(FContextPtr);
end;

function TLazyLoader.GetIsValueCreated: Boolean;
begin
  Result := FLoaded;
end;

function TLazyLoader.GetValue: TValue;
begin
  if not FLoaded then
    LoadValue;
  Result := FValue;
end;

procedure TLazyLoader.LoadValue;
var
  Ctx: TRttiContext;
  Prop: TRttiProperty;
  FKName: string;
  Attr: TCustomAttribute;
  TypeName: string;
  StartPos, EndPos: Integer;
  ItemTypeName: string;
  ItemType: TRttiType;
  ChildSet: IDbSet;
  ParentName: string;
  FKPropName: string;
  P: TRttiProperty;
  PKVal: string;
  PropHelper: TPropExpression;
  Expr: IExpression;
  ResList: TList<TObject>;
  ListObj: TObject;
  AddMethod: TRttiMethod;
  Obj: TObject;
  FKProp: TRttiProperty;
  FKVal: TValue;
  TargetType: PTypeInfo;
  TargetSet: IDbSet;
  LoadedObj: TObject;
  IntVal: Integer;
  ExpectedClass: TClass;
begin
  try
    Ctx := TRttiContext.Create;
    
    if FIsCollection then
    begin
        // Load Collection
        Prop := Ctx.GetType(FEntity.ClassType).GetProperty(FPropName);
        FKName := '';
        if Prop <> nil then
        begin
           for Attr in Prop.GetAttributes do
             if Attr is ForeignKeyAttribute then
             begin
               FKName := ForeignKeyAttribute(Attr).ColumnName;
               Break;
             end;
        end;
        
        TypeName := Prop.PropertyType.Name;
        StartPos := Pos('<', TypeName);
        EndPos := Pos('>', TypeName);
        
        if (StartPos > 0) and (EndPos > StartPos) then
        begin
            ItemTypeName := Copy(TypeName, StartPos + 1, EndPos - StartPos - 1);
            ItemType := Ctx.FindType(ItemTypeName);
            
            if ItemType <> nil then
            begin
                ChildSet := GetDbContext.DataSet(ItemType.Handle);
                
                ParentName := FEntity.ClassName;
                if ParentName.StartsWith('T') then Delete(ParentName, 1, 1);
                
                FKPropName := ParentName + 'Id'; 
                
                P := ItemType.GetProperty(FKPropName);
                if P <> nil then
                begin
                    PKVal := GetDbContext.DataSet(FEntity.ClassInfo).GetEntityId(FEntity);
                    
                    PropHelper := TPropExpression.Create(FKPropName);
                    
                    // Try to convert PK to Integer if possible, as most FKs are ints
                    if TryStrToInt(PKVal, IntVal) then
                       Expr := PropHelper = IntVal
                    else
                       Expr := PropHelper = PKVal;
                       
                    ResList := ChildSet.ListObjects(Expr);
                    try
                      // Check if it's TObjectList to pass OwnsObjects=True
                      if TypeName.Contains('TObjectList<') then
                        ListObj := TActivator.CreateInstance(Prop.PropertyType.AsInstance.MetaclassType, [True])
                      else
                        ListObj := TActivator.CreateInstance(Prop.PropertyType.AsInstance.MetaclassType, []);

                      if ListObj = nil then
                        Exit;
                        
                      AddMethod := Prop.PropertyType.GetMethod('Add');
                      if AddMethod = nil then
                        Exit;
                      
                      for Obj in ResList do
                      begin
                           if Obj = nil then 
                             Continue;
                           
                           try
                            // Check if object is instance of expected type
                            if ItemType.AsInstance <> nil then
                            begin
                              ExpectedClass := ItemType.AsInstance.MetaclassType;
                              if not (Obj is ExpectedClass) then
                                Continue;
                            end;
                            
                            AddMethod.Invoke(ListObj, [Obj]);
                          except
                            // Ignore errors adding individual items
                          end;
                      end;
                      
                      FValue := TValue.From(ListObj); // Correctly wrap the object
                    finally
                      ResList.Free;
                    end;
                end;
            end;
        end;
    end
    else
    begin
        // Load Reference
        FKPropName := FPropName + 'Id';
        FKProp := Ctx.GetType(FEntity.ClassType).GetProperty(FKPropName);
        if FKProp <> nil then
        begin
            FKVal := FKProp.GetValue(FEntity);
            
            // Unwrap Nullable<T> and validate FK value
            if TryUnwrapAndValidateFK(FKVal, Ctx) then
            begin
                Prop := Ctx.GetType(FEntity.ClassType).GetProperty(FPropName);
                TargetType := Prop.PropertyType.Handle;
                
                TargetSet := GetDbContext.DataSet(TargetType);
                LoadedObj := TargetSet.FindObject(FKVal.AsVariant);
                
                FValue := TValue.From(LoadedObj);
            end;
        end;
    end;
    
    FLoaded := True;
  except
    // If loading fails, we just mark as loaded to avoid infinite loops/retries
    // and let the value be default (nil/empty)
    FLoaded := True;
  end;
end;

end.

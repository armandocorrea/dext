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
{  Created: 2026-01-19                                                      }
{                                                                           }
{***************************************************************************}

/// <summary>
/// Dext.UI.Binder - RTTI-based binding engine for MVU pattern
///
/// Automatically discovers binding attributes on Frame controls and:
/// - Connects Model properties to control values (BindText, BindChecked, etc.)
/// - Wires control events to message dispatch (OnClickMsg, OnChangeMsg)
///
/// Usage:
///   FBinder := TMVUBinder<TMyModel, TMyMessage>.Create(MyFrame, DispatchProc);
///   FBinder.Render(Model);  // Updates all bound controls
/// </summary>
unit Dext.UI.Binder;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Rtti,
  System.TypInfo,
  System.Generics.Collections,
  Vcl.Controls,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Dext.UI.Attributes,
  Dext.UI.Message;

type
  /// <summary>
  /// Internal binding information
  /// </summary>
  TBindingInfo = record
    Control: TControl;
    PropertyPath: string;
    Format: string;
    BindingType: (btText, btChecked, btEnabled, btVisible, btItems);
    Invert: Boolean;
  end;
  
  /// <summary>
  /// Internal event wiring information
  /// </summary>
  TEventWiring = record
    Control: TControl;
    EventType: (etClick, etChange, etFocus);
    MessageClass: TClass;
  end;
  
  /// <summary>
  /// RTTI-based binder that connects UI controls to the MVU Model.
  /// Discovers binding attributes on Frame fields and automates updates.
  /// </summary>
  TMVUBinder<TModel; TMsg: TMessage> = class
  private
    FFrame: TComponent;
    FDispatch: TProc<TMsg>;
    FBindings: TList<TBindingInfo>;
    FWirings: TList<TEventWiring>;
    FContext: TRttiContext;
    
    procedure DiscoverBindings;
    procedure DiscoverEventsWiring;
    procedure ApplyBinding(const Binding: TBindingInfo; const Model: TModel);
    function GetPropertyValue(const Model: TModel; const PropertyPath: string): TValue;
    
    // Event handlers
    procedure HandleClick(Sender: TObject);
  public
    constructor Create(AFrame: TComponent; ADispatch: TProc<TMsg>);
    destructor Destroy; override;
    
    /// <summary>
    /// Updates all bound controls from the current Model state.
    /// Call this after every Update.
    /// </summary>
    procedure Render(const Model: TModel);
  end;

implementation

{ TMVUBinder<TModel, TMsg> }

constructor TMVUBinder<TModel, TMsg>.Create(AFrame: TComponent; ADispatch: TProc<TMsg>);
begin
  inherited Create;
  FFrame := AFrame;
  FDispatch := ADispatch;
  FBindings := TList<TBindingInfo>.Create;
  FWirings := TList<TEventWiring>.Create;
  FContext := TRttiContext.Create;
  
  DiscoverBindings;
  DiscoverEventsWiring;
end;

destructor TMVUBinder<TModel, TMsg>.Destroy;
begin
  FWirings.Free;
  FBindings.Free;
  FContext.Free;
  inherited;
end;

procedure TMVUBinder<TModel, TMsg>.DiscoverBindings;
var
  RttiType: TRttiType;
  Field: TRttiField;
  Attr: TCustomAttribute;
  Binding: TBindingInfo;
  Control: TControl;
begin
  RttiType := FContext.GetType(FFrame.ClassType);
  if RttiType = nil then Exit;
  
  for Field in RttiType.GetFields do
  begin
    // Check if field is a TControl
    if not Field.FieldType.IsInstance then Continue;
    if not Field.FieldType.AsInstance.MetaclassType.InheritsFrom(TControl) then Continue;
    
    Control := Field.GetValue(FFrame).AsObject as TControl;
    if Control = nil then Continue;
    
    // Check for binding attributes
    for Attr in Field.GetAttributes do
    begin
      if Attr is BindTextAttribute then
      begin
        Binding.Control := Control;
        Binding.PropertyPath := BindTextAttribute(Attr).PropertyPath;
        Binding.Format := BindTextAttribute(Attr).Format;
        Binding.BindingType := btText;
        Binding.Invert := False;
        FBindings.Add(Binding);
      end
      else if Attr is BindCheckedAttribute then
      begin
        Binding.Control := Control;
        Binding.PropertyPath := BindCheckedAttribute(Attr).PropertyPath;
        Binding.Format := '';
        Binding.BindingType := btChecked;
        Binding.Invert := False;
        FBindings.Add(Binding);
      end
      else if Attr is BindEnabledAttribute then
      begin
        Binding.Control := Control;
        Binding.PropertyPath := BindEnabledAttribute(Attr).PropertyPath;
        Binding.Format := '';
        Binding.BindingType := btEnabled;
        Binding.Invert := BindEnabledAttribute(Attr).Invert;
        FBindings.Add(Binding);
      end
      else if Attr is BindVisibleAttribute then
      begin
        Binding.Control := Control;
        Binding.PropertyPath := BindVisibleAttribute(Attr).PropertyPath;
        Binding.Format := '';
        Binding.BindingType := btVisible;
        Binding.Invert := BindVisibleAttribute(Attr).Invert;
        FBindings.Add(Binding);
      end;
    end;
  end;
end;

procedure TMVUBinder<TModel, TMsg>.DiscoverEventsWiring;
var
  RttiType: TRttiType;
  Field: TRttiField;
  Attr: TCustomAttribute;
  Wiring: TEventWiring;
  Control: TControl;
begin
  RttiType := FContext.GetType(FFrame.ClassType);
  if RttiType = nil then Exit;
  
  for Field in RttiType.GetFields do
  begin
    if not Field.FieldType.IsInstance then Continue;
    if not Field.FieldType.AsInstance.MetaclassType.InheritsFrom(TControl) then Continue;
    
    Control := Field.GetValue(FFrame).AsObject as TControl;
    if Control = nil then Continue;
    
    for Attr in Field.GetAttributes do
    begin
      if Attr is OnClickMsgAttribute then
      begin
        Wiring.Control := Control;
        Wiring.EventType := etClick;
        Wiring.MessageClass := OnClickMsgAttribute(Attr).MessageClass;
        FWirings.Add(Wiring);
        
        // Wire the event
        if Control is TButton then
          TButton(Control).OnClick := HandleClick
        else if Control is TPanel then
          TPanel(Control).OnClick := HandleClick
        else if Control is TLabel then
          TLabel(Control).OnClick := HandleClick;
          
        // Store message class reference in control's Tag
        Control.Tag := NativeInt(Wiring.MessageClass);
      end;
    end;
  end;
end;

procedure TMVUBinder<TModel, TMsg>.HandleClick(Sender: TObject);
var
  MessageClass: TClass;
  Msg: TMsg;
begin
  if not (Sender is TControl) then Exit;
  
  MessageClass := TClass(TControl(Sender).Tag);
  if MessageClass = nil then Exit;
  
  // Create message instance
  if MessageClass.InheritsFrom(TMessage) then
  begin
    Msg := TMessageClass(MessageClass).Create as TMsg;
    try
      FDispatch(Msg);
    finally
      Msg.Free;
    end;
  end;
end;

procedure TMVUBinder<TModel, TMsg>.Render(const Model: TModel);
var
  Binding: TBindingInfo;
begin
  for Binding in FBindings do
    ApplyBinding(Binding, Model);
end;

procedure TMVUBinder<TModel, TMsg>.ApplyBinding(const Binding: TBindingInfo; const Model: TModel);
var
  Value: TValue;
  StrValue: string;
  BoolValue: Boolean;
begin
  Value := GetPropertyValue(Model, Binding.PropertyPath);
  
  case Binding.BindingType of
    btText:
      begin
        if Binding.Format <> '' then
          StrValue := Format(Binding.Format, [Value.AsVariant])
        else if Value.Kind = tkInteger then
          StrValue := Value.AsInteger.ToString
        else if Value.Kind = tkInt64 then
          StrValue := Value.AsInt64.ToString
        else if Value.Kind = tkFloat then
          StrValue := FloatToStr(Value.AsExtended)
        else
          StrValue := Value.ToString;
          
        if Binding.Control is TLabel then
          TLabel(Binding.Control).Caption := StrValue
        else if Binding.Control is TEdit then
          TEdit(Binding.Control).Text := StrValue
        else if Binding.Control is TMemo then
          TMemo(Binding.Control).Text := StrValue;
      end;
      
    btChecked:
      begin
        BoolValue := Value.AsBoolean;
        if Binding.Control is TCheckBox then
          TCheckBox(Binding.Control).Checked := BoolValue;
      end;
      
    btEnabled:
      begin
        BoolValue := Value.AsBoolean;
        if Binding.Invert then BoolValue := not BoolValue;
        Binding.Control.Enabled := BoolValue;
      end;
      
    btVisible:
      begin
        BoolValue := Value.AsBoolean;
        if Binding.Invert then BoolValue := not BoolValue;
        Binding.Control.Visible := BoolValue;
      end;
  end;
end;

function TMVUBinder<TModel, TMsg>.GetPropertyValue(const Model: TModel; const PropertyPath: string): TValue;
var
  RttiType: TRttiType;
  Field: TRttiField;
  Prop: TRttiProperty;
begin
  Result := TValue.Empty;
  
  RttiType := FContext.GetType(TypeInfo(TModel));
  if RttiType = nil then Exit;
  
  // Try field first
  Field := RttiType.GetField(PropertyPath);
  if Field <> nil then
  begin
    Result := Field.GetValue(@Model);
    Exit;
  end;
  
  // Try property
  Prop := RttiType.GetProperty(PropertyPath);
  if Prop <> nil then
  begin
    // For records, we need to box it differently
    var RecValue := TValue.From<TModel>(Model);
    Result := Prop.GetValue(RecValue.GetReferenceToRawData);
  end;
end;

end.

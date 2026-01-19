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
/// Dext.UI - Facade unit for Dext UI Framework
///
/// This unit provides convenient aliases and re-exports for the
/// Model-View-Update (MVU) architecture components.
///
/// Usage:
///   uses Dext.UI;
/// </summary>
unit Dext.UI;

interface

uses
  Dext.UI.Attributes,
  Dext.UI.Binder,
  Dext.UI.Message,
  Dext.UI.Module,
  Dext.UI.State;

type
  // Binding Attributes
  BindText = Dext.UI.Attributes.BindTextAttribute;
  BindChecked = Dext.UI.Attributes.BindCheckedAttribute;
  BindEnabled = Dext.UI.Attributes.BindEnabledAttribute;
  BindVisible = Dext.UI.Attributes.BindVisibleAttribute;
  BindItems = Dext.UI.Attributes.BindItemsAttribute;
  OnClickMsg = Dext.UI.Attributes.OnClickMsgAttribute;
  OnChangeMsg = Dext.UI.Attributes.OnChangeMsgAttribute;
  
  // Core Types
  TMessage = Dext.UI.Message.TMessage;
  
  // Binder - use Dext.UI.Binder.TMVUBinder<TModel, TMsg> directly
  // (Delphi does not support generic type aliases)
  
  // State
  IStateStore = Dext.UI.State.IStateStore;
  TStateStore = Dext.UI.State.TStateStore;

implementation

end.

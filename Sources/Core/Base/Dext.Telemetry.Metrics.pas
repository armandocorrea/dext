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

unit Dext.Telemetry.Metrics;

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.JSON,
  System.Generics.Collections;

type
  TMetricType = (mtCounter, mtGauge, mtHistogram);

  TMetricValue = record
    MetricType: TMetricType;
    Value: Double;
    Count: Int64;
    Sum: Double;
    Min: Double;
    Max: Double;
  end;

  /// <summary>
  ///   Core static registry for application and framework performance metrics.
  /// </summary>
  TMetrics = class
  private
    class var FLock: TCriticalSection;
    class var FMetrics: TDictionary<string, TMetricValue>;
    class constructor Create;
    class destructor Destroy;
  public
    /// <summary>Increments a counter metric by a specified value.</summary>
    class procedure Increment(const AName: string; const AValue: Double = 1.0); static;
    
    /// <summary>Sets a gauge metric to a specified absolute value.</summary>
    class procedure Gauge(const AName: string; const AValue: Double); static;
    
    /// <summary>Records a value in a histogram metric (e.g. latency).</summary>
    class procedure Histogram(const AName: string; const AValue: Double); static;
    
    /// <summary>Flushes and aggregates the current metrics registry into a JSON array, clearing dynamic data.</summary>
    class function Flush: string; static;
  end;

var
  GActiveDbConnectionsFunc: function: Integer = nil;

implementation

{ TMetrics }

class constructor TMetrics.Create;
begin
  FLock := TCriticalSection.Create;
  FMetrics := TDictionary<string, TMetricValue>.Create;
end;

class destructor TMetrics.Destroy;
begin
  FMetrics.Free;
  FLock.Free;
end;

class procedure TMetrics.Increment(const AName: string; const AValue: Double);
var
  Val: TMetricValue;
begin
  FLock.Enter;
  try
    if not FMetrics.TryGetValue(AName, Val) then
    begin
      Val.MetricType := mtCounter;
      Val.Value := 0;
      Val.Count := 0;
      Val.Sum := 0;
      Val.Min := 0;
      Val.Max := 0;
    end;
    Val.Value := Val.Value + AValue;
    FMetrics.AddOrSetValue(AName, Val);
  finally
    FLock.Leave;
  end;
end;

class procedure TMetrics.Gauge(const AName: string; const AValue: Double);
var
  Val: TMetricValue;
begin
  FLock.Enter;
  try
    Val.MetricType := mtGauge;
    Val.Value := AValue;
    Val.Count := 1;
    Val.Sum := AValue;
    Val.Min := AValue;
    Val.Max := AValue;
    FMetrics.AddOrSetValue(AName, Val);
  finally
    FLock.Leave;
  end;
end;

class procedure TMetrics.Histogram(const AName: string; const AValue: Double);
var
  Val: TMetricValue;
begin
  FLock.Enter;
  try
    if not FMetrics.TryGetValue(AName, Val) then
    begin
      Val.MetricType := mtHistogram;
      Val.Value := AValue;
      Val.Count := 0;
      Val.Sum := 0;
      Val.Min := AValue;
      Val.Max := AValue;
    end;
    Val.Count := Val.Count + 1;
    Val.Sum := Val.Sum + AValue;
    if AValue < Val.Min then Val.Min := AValue;
    if AValue > Val.Max then Val.Max := AValue;
    FMetrics.AddOrSetValue(AName, Val);
  finally
    FLock.Leave;
  end;
end;

class function TMetrics.Flush: string;
var
  Arr: TJSONArray;
  JO: TJSONObject;
  Pair: TPair<string, TMetricValue>;
  Val: TMetricValue;
  Avg: Double;
  KeysToRemove: TList<string>;
  K: string;
begin
  Arr := TJSONArray.Create;
  FLock.Enter;
  try
    for Pair in FMetrics do
    begin
      Val := Pair.Value;
      JO := TJSONObject.Create;
      JO.AddPair('name', Pair.Key);
      case Val.MetricType of
        mtCounter:
        begin
          JO.AddPair('type', 'counter');
          JO.AddPair('value', TJSONNumber.Create(Val.Value));
        end;
        mtGauge:
        begin
          JO.AddPair('type', 'gauge');
          JO.AddPair('value', TJSONNumber.Create(Val.Value));
        end;
        mtHistogram:
        begin
          JO.AddPair('type', 'histogram');
          JO.AddPair('count', TJSONNumber.Create(Val.Count));
          JO.AddPair('sum', TJSONNumber.Create(Val.Sum));
          JO.AddPair('min', TJSONNumber.Create(Val.Min));
          JO.AddPair('max', TJSONNumber.Create(Val.Max));
          if Val.Count > 0 then
            Avg := Val.Sum / Val.Count
          else
            Avg := 0;
          JO.AddPair('avg', TJSONNumber.Create(Avg));
        end;
      end;
      Arr.AddElement(JO);
    end;
    
    // Clear dynamic metrics (counters and histograms) so we get metrics per interval.
    // Gauges are persisted across flushes.
    KeysToRemove := TList<string>.Create;
    try
      for Pair in FMetrics do
      begin
        if Pair.Value.MetricType <> mtGauge then
          KeysToRemove.Add(Pair.Key);
      end;
      for K in KeysToRemove do
        FMetrics.Remove(K);
    finally
      KeysToRemove.Free;
    end;
    
  finally
    FLock.Leave;
  end;
  
  Result := Arr.ToJSON;
  Arr.Free;
end;

end.

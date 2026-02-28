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
unit Dext.Collections.Raw;

interface

uses
  System.SysUtils,
  System.TypInfo,
  Dext.Collections.Memory;

type
  TRawCompareFunc = reference to function(A, B: Pointer): Integer;
  TRawEqualFunc = function(A, B: Pointer; Size: Integer): Boolean;
  TRawEqualityFunc = reference to function(A, B: Pointer): Boolean;
  TRawCollectionNotification = (rcnAdded, rcnRemoved, rcnExtracted);
  TRawNotifyEvent = procedure(Item: Pointer; Action: TRawCollectionNotification) of object;

  TRawIntArray = array[0..MaxInt div 4 - 1] of Integer;
  PRawIntArray = ^TRawIntArray;
  TRawInt64Array = array[0..MaxInt div 8 - 1] of Int64;
  PRawInt64Array = ^TRawInt64Array;
  TRawStrArray = array[0..MaxInt div SizeOf(string) - 1] of string;
  PRawStrArray = ^TRawStrArray;
  TRawDblArray = array[0..MaxInt div 8 - 1] of Double;
  PRawDblArray = ^TRawDblArray;

  TRawList = class
  private
    FData: PByte;
    FTypeInfo: PTypeInfo;
    FOnNotify: TRawNotifyEvent;
    FCount: Integer;
    FCapacity: Integer;
    FElementSize: Integer;
    FIsManaged: Boolean;
    FEqualFunc: TRawEqualFunc;
    procedure InternalDeleteComplex(Index: Integer);
    procedure InternalSortHybrid(L, R: Integer; AKind: TTypeKind);
    procedure InternalSortInt(L, R: Integer);
    procedure InternalSortInt64(L, R: Integer);
    procedure InternalSortDbl(L, R: Integer);
    procedure InternalSortStr(L, R: Integer);
    procedure InternalSortGeneric(L, R: Integer; CompareFunc: TRawCompareFunc);
    function GetData: PByte; inline;
    function GetCount: Integer; inline;
    function GetCapacity: Integer; inline;
    function GetElementSize: Integer; inline;
    function GetTypeInfo: PTypeInfo; inline;
    function GetIsManaged: Boolean; inline;
    function GetOnNotify: TRawNotifyEvent; inline;
    procedure SetOnNotify(const Value: TRawNotifyEvent); inline;
    procedure SetCapacity(ACapacity: Integer);
    procedure Grow;
    procedure DoNotify(Item: Pointer; Action: TRawCollectionNotification);
  public
    constructor Create(AElementSize: Integer; ATypeInfo: PTypeInfo; AIsManaged: Boolean = False);
    destructor Destroy; override;
    procedure GrowTo(AMinCapacity: Integer);
    function GetItemPtr(Index: Integer): Pointer; inline;
    function AddRaw(Value: Pointer): Integer; inline;
    procedure FastIncrementCount; inline;
    procedure FastDecrementCount; inline;
    procedure InsertRaw(Index: Integer; Value: Pointer); inline;
    procedure DeleteRaw(Index: Integer); inline;
    function RemoveRaw(Value: Pointer; EqualityFunc: TRawEqualityFunc): Integer;
    function ExtractRaw(Value: Pointer; EqualityFunc: TRawEqualityFunc): Integer;
    procedure Clear; inline;
    function IndexOfRaw(Value: Pointer; EqualityFunc: TRawEqualityFunc = nil): Integer;
    function ContainsRaw(Value: Pointer; EqualityFunc: TRawEqualityFunc): Boolean;
    procedure GetRawItem(Index: Integer; Dest: Pointer); inline;
    procedure SetRawItem(Index: Integer; Value: Pointer); inline;
    procedure GetRawData(Dest: Pointer);
    procedure ExchangeRaw(Index1, Index2: Integer);
    procedure SortRaw(CompareFunc: TRawCompareFunc); overload;
    procedure SortRaw(AKind: TTypeKind); overload;
    property Data: PByte read GetData;
    property Count: Integer read GetCount;
    property Capacity: Integer read GetCapacity write SetCapacity;
    property ElementSize: Integer read GetElementSize;
    property TypeInfo: PTypeInfo read GetTypeInfo;
    property IsManaged: Boolean read GetIsManaged;
    property OnNotify: TRawNotifyEvent read GetOnNotify write SetOnNotify;
  end;

implementation

const INITIAL_CAPACITY = 8;

function DefaultRawEqual(A, B: Pointer; Size: Integer): Boolean;
begin Result := CompareMem(A, B, Size); end;

function FastEqual4(A, B: Pointer; Size: Integer): Boolean;
begin Result := PCardinal(A)^ = PCardinal(B)^; end;

function FastEqual8(A, B: Pointer; Size: Integer): Boolean;
begin Result := PUInt64(A)^ = PUInt64(B)^; end;

{ TRawList }

constructor TRawList.Create(AElementSize: Integer; ATypeInfo: PTypeInfo; AIsManaged: Boolean);
begin
  inherited Create;
  FElementSize := AElementSize;
  FTypeInfo := ATypeInfo;
  FIsManaged := AIsManaged;
  case AElementSize of
    4: FEqualFunc := @FastEqual4;
    8: FEqualFunc := @FastEqual8;
  else FEqualFunc := @DefaultRawEqual;
  end;
end;

destructor TRawList.Destroy;
begin
  Clear;
  if FData <> nil then FreeMem(FData);
  inherited;
end;

function TRawList.GetData: PByte; begin Result := FData; end;
function TRawList.GetCount: Integer; begin Result := FCount; end;
function TRawList.GetCapacity: Integer; begin Result := FCapacity; end;
function TRawList.GetElementSize: Integer; begin Result := FElementSize; end;
function TRawList.GetTypeInfo: PTypeInfo; begin Result := FTypeInfo; end;
function TRawList.GetIsManaged: Boolean; begin Result := FIsManaged; end;
function TRawList.GetOnNotify: TRawNotifyEvent; begin Result := FOnNotify; end;
procedure TRawList.SetOnNotify(const Value: TRawNotifyEvent); begin FOnNotify := Value; end;
procedure TRawList.FastIncrementCount; begin Inc(FCount); end;
procedure TRawList.FastDecrementCount; begin Dec(FCount); end;

function TRawList.GetItemPtr(Index: Integer): Pointer;
begin Result := FData + (Index * FElementSize); end;

procedure TRawList.SetCapacity(ACapacity: Integer);
var NewData: PByte;
begin
  if ACapacity = FCapacity then Exit;
  if ACapacity < FCount then raise EArgumentOutOfRangeException.Create('TRawList: Capacity too small');
  if ACapacity = 0 then begin
    if FData <> nil then FreeMem(FData);
    FData := nil; FCapacity := 0; Exit;
  end;
  if not FIsManaged then begin
    ReallocMem(FData, ACapacity * FElementSize);
  end else begin
    GetMem(NewData, ACapacity * FElementSize);
    if FData <> nil then begin
      System.Move(FData^, NewData^, FCount * FElementSize);
      FillChar(FData^, FCount * FElementSize, 0);
      FreeMem(FData);
    end;
    FillChar((NewData + FCount * FElementSize)^, (ACapacity - FCount) * FElementSize, 0);
    FData := NewData;
  end;
  FCapacity := ACapacity;
end;

procedure TRawList.Grow;
begin if FCapacity = 0 then SetCapacity(INITIAL_CAPACITY) else SetCapacity(FCapacity * 2); end;

procedure TRawList.GrowTo(AMinCapacity: Integer);
var NewCap: Integer;
begin
  NewCap := FCapacity; if NewCap = 0 then NewCap := INITIAL_CAPACITY;
  while NewCap < AMinCapacity do NewCap := NewCap * 2;
  SetCapacity(NewCap);
end;

procedure TRawList.DoNotify(Item: Pointer; Action: TRawCollectionNotification);
begin if Assigned(FOnNotify) then FOnNotify(Item, Action); end;

function TRawList.AddRaw(Value: Pointer): Integer;
var Dest: Pointer;
begin
  if FCount >= FCapacity then Grow;
  Result := FCount; Dest := FData + (Result * FElementSize);
  if FIsManaged then System.CopyArray(Dest, Value, FTypeInfo, 1)
  else System.Move(Value^, Dest^, FElementSize);
  Inc(FCount);
  if Assigned(FOnNotify) then FOnNotify(Dest, rcnAdded);
end;

procedure TRawList.InsertRaw(Index: Integer; Value: Pointer);
var Src, Dest: Pointer; MoveCount: Integer;
begin
  if FCount >= FCapacity then Grow;
  MoveCount := FCount - Index;
  if MoveCount > 0 then begin
    Src := FData + (Index * FElementSize); Dest := FData + ((Index + 1) * FElementSize);
    System.Move(Src^, Dest^, MoveCount * FElementSize);
    if FIsManaged then FillChar(Src^, FElementSize, 0);
  end;
  if FIsManaged then System.CopyArray(FData + (Index * FElementSize), Value, FTypeInfo, 1)
  else System.Move(Value^, (FData + (Index * FElementSize))^, FElementSize);
  Inc(FCount); DoNotify(FData + (Index * FElementSize), rcnAdded);
end;

procedure TRawList.DeleteRaw(Index: Integer);
var LSize, LCount: Integer; LData: PByte;
begin
  LCount := FCount;
  if (not FIsManaged) and (not Assigned(FOnNotify)) then begin
    if Index < LCount - 1 then begin
      LSize := FElementSize; LData := FData;
      System.Move((LData + (Index + 1) * LSize)^, (LData + Index * LSize)^, (LCount - Index - 1) * LSize);
    end;
    FCount := LCount - 1; Exit;
  end;
  InternalDeleteComplex(Index);
end;

procedure TRawList.InternalDeleteComplex(Index: Integer);
var ItemPtr: Pointer; MoveCount: Integer; TempBuf: array[0..127] of Byte; TempPtr: Pointer;
begin
  ItemPtr := FData + (Index * FElementSize);
  TempPtr := nil;
  if Assigned(FOnNotify) then begin
    if FElementSize <= SizeOf(TempBuf) then TempPtr := @TempBuf[0] else GetMem(TempPtr, FElementSize);
    System.Move(ItemPtr^, TempPtr^, FElementSize);
  end;
  if FIsManaged then System.FinalizeArray(ItemPtr, FTypeInfo, 1);
  MoveCount := FCount - Index - 1;
  if MoveCount > 0 then begin
    System.Move((FData + (Index + 1) * FElementSize)^, ItemPtr^, MoveCount * FElementSize);
    if FIsManaged then FillChar((FData + (FCount - 1) * FElementSize)^, FElementSize, 0);
  end else if FIsManaged then FillChar(ItemPtr^, FElementSize, 0);
  Dec(FCount);
  if TempPtr <> nil then begin
    DoNotify(TempPtr, rcnRemoved);
    if TempPtr <> @TempBuf[0] then FreeMem(TempPtr);
  end;
end;

procedure TRawList.InternalSortInt(L, R: Integer);
var I, J, Pivot, T: Integer; PData: PRawIntArray;
begin
  PData := PRawIntArray(FData);
  repeat
    I := L; J := R; Pivot := PData^[(L + R) div 2];
    repeat
      while PData^[I] < Pivot do Inc(I); while PData^[J] > Pivot do Dec(J);
      if I <= J then begin T := PData^[I]; PData^[I] := PData^[J]; PData^[J] := T; Inc(I); Dec(J); end;
    until I > J;
    if L < J then InternalSortInt(L, J); L := I;
  until I >= R;
end;

procedure TRawList.InternalSortInt64(L, R: Integer);
var I, J: Integer; Pivot, T: Int64; PData: PRawInt64Array;
begin
  PData := PRawInt64Array(FData);
  repeat
    I := L; J := R; Pivot := PData^[(L + R) div 2];
    repeat
      while PData^[I] < Pivot do Inc(I); while PData^[J] > Pivot do Dec(J);
      if I <= J then begin T := PData^[I]; PData^[I] := PData^[J]; PData^[J] := T; Inc(I); Dec(J); end;
    until I > J;
    if L < J then InternalSortInt64(L, J); L := I;
  until I >= R;
end;

procedure TRawList.InternalSortDbl(L, R: Integer);
var I, J: Integer; Pivot, T: Double; PData: PRawDblArray;
begin
  PData := PRawDblArray(FData);
  repeat
    I := L; J := R; Pivot := PData^[(L + R) div 2];
    repeat
      while PData^[I] < Pivot do Inc(I); while PData^[J] > Pivot do Dec(J);
      if I <= J then begin T := PData^[I]; PData^[I] := PData^[J]; PData^[J] := T; Inc(I); Dec(J); end;
    until I > J;
    if L < J then InternalSortDbl(L, J); L := I;
  until I >= R;
end;

procedure TRawList.InternalSortStr(L, R: Integer);
var I, J: Integer; Pivot, T: string; PData: PRawStrArray;
begin
  PData := PRawStrArray(FData);
  repeat
    I := L; J := R; Pivot := PData^[(L + R) div 2];
    repeat
      while PData^[I] < Pivot do Inc(I); while PData^[J] > Pivot do Dec(J);
      if I <= J then begin T := PData^[I]; PData^[I] := PData^[J]; PData^[J] := T; Inc(I); Dec(J); end;
    until I > J;
    if L < J then InternalSortStr(L, J); L := I;
  until I >= R;
end;

procedure TRawList.InternalSortHybrid(L, R: Integer; AKind: TTypeKind);
var I, J: Integer;
begin
  if R - L < 1 then Exit;
  if R - L < 24 then begin
    case AKind of
      tkInteger: begin
        var PArr := PRawIntArray(FData);
        for I := L + 1 to R do begin
          var V := PArr^[I]; J := I;
          while (J > L) and (PArr^[J-1] > V) do begin PArr^[J] := PArr^[J-1]; Dec(J); end;
          PArr^[J] := V;
        end;
      end;
      tkFloat: begin
        var PArr := PRawDblArray(FData);
        for I := L + 1 to R do begin
          var V := PArr^[I]; J := I;
          while (J > L) and (PArr^[J-1] > V) do begin PArr^[J] := PArr^[J-1]; Dec(J); end;
          PArr^[J] := V;
        end;
      end;
      tkUString: begin
        var PArr := PRawStrArray(FData);
        for I := L + 1 to R do begin
          var V := PArr^[I]; J := I;
          while (J > L) and (PArr^[J-1] > V) do begin PArr^[J] := PArr^[J-1]; Dec(J); end;
          PArr^[J] := V;
        end;
      end;
    end;
    Exit;
  end;
  case AKind of
    tkInteger: InternalSortInt(L, R);
    tkInt64: InternalSortInt64(L, R);
    tkFloat: InternalSortDbl(L, R);
    tkUString: InternalSortStr(L, R);
  end;
end;

function TRawList.RemoveRaw(Value: Pointer; EqualityFunc: TRawEqualityFunc): Integer;
begin Result := IndexOfRaw(Value, EqualityFunc); if Result >= 0 then DeleteRaw(Result); end;

function TRawList.ExtractRaw(Value: Pointer; EqualityFunc: TRawEqualityFunc): Integer;
var ItemPtr: Pointer; MoveCount: Integer;
begin
  Result := IndexOfRaw(Value, EqualityFunc); if Result < 0 then Exit;
  ItemPtr := FData + (Result * FElementSize); DoNotify(ItemPtr, rcnExtracted);
  MoveCount := FCount - Result - 1;
  if MoveCount > 0 then begin
    System.Move((FData + (Result + 1) * FElementSize)^, ItemPtr^, MoveCount * FElementSize);
    if FIsManaged then FillChar((FData + (FCount - 1) * FElementSize)^, FElementSize, 0);
  end else if FIsManaged then FillChar(ItemPtr^, FElementSize, 0);
  Dec(FCount);
end;

procedure TRawList.Clear;
var I: Integer;
begin
  if FCount = 0 then Exit;
  if Assigned(FOnNotify) then for I := FCount - 1 downto 0 do DoNotify(FData + (I * FElementSize), rcnRemoved);
  if FIsManaged then System.FinalizeArray(FData, FTypeInfo, FCount);
  FCount := 0;
end;

function TRawList.IndexOfRaw(Value: Pointer; EqualityFunc: TRawEqualityFunc): Integer;
var I: Integer; ItemPtr: PByte; Size: Integer;
begin
  Size := FElementSize; ItemPtr := FData;
  if Assigned(EqualityFunc) then begin
    for I := 0 to FCount - 1 do begin if EqualityFunc(ItemPtr, Value) then Exit(I); Inc(ItemPtr, Size); end;
  end else begin
    for I := 0 to FCount - 1 do begin if FEqualFunc(ItemPtr, Value, Size) then Exit(I); Inc(ItemPtr, Size); end;
  end;
  Result := -1;
end;

function TRawList.ContainsRaw(Value: Pointer; EqualityFunc: TRawEqualityFunc): Boolean;
begin Result := IndexOfRaw(Value, EqualityFunc) >= 0; end;

procedure TRawList.GetRawItem(Index: Integer; Dest: Pointer);
begin
  if FIsManaged then System.CopyArray(Dest, FData + (Index * FElementSize), FTypeInfo, 1)
  else System.Move((FData + (Index * FElementSize))^, Dest^, FElementSize);
end;

procedure TRawList.SetRawItem(Index: Integer; Value: Pointer);
var Dest: Pointer;
begin
  Dest := FData + (Index * FElementSize); DoNotify(Dest, rcnRemoved);
  if FIsManaged then begin System.FinalizeArray(Dest, FTypeInfo, 1); System.CopyArray(Dest, Value, FTypeInfo, 1); end
  else System.Move(Value^, Dest^, FElementSize);
  DoNotify(Dest, rcnAdded);
end;

procedure TRawList.GetRawData(Dest: Pointer);
begin if FCount > 0 then if FIsManaged then System.CopyArray(Dest, FData, FTypeInfo, FCount) else System.Move(FData^, Dest^, FCount * FElementSize); end;

procedure TRawList.ExchangeRaw(Index1, Index2: Integer);
var P1, P2: Pointer; TBuf: array[0..127] of Byte; TPtr: Pointer;
begin
  if Index1 = Index2 then Exit; P1 := FData + (Index1 * FElementSize); P2 := FData + (Index2 * FElementSize);
  if FElementSize <= SizeOf(TBuf) then TPtr := @TBuf[0] else GetMem(TPtr, FElementSize);
  System.Move(P1^, TPtr^, FElementSize); System.Move(P2^, P1^, FElementSize); System.Move(TPtr^, P2^, FElementSize);
  if TPtr <> @TBuf[0] then FreeMem(TPtr);
end;

procedure TRawList.InternalSortGeneric(L, R: Integer; CompareFunc: TRawCompareFunc);
var
  I, J: Integer;
  PivotPtr: Pointer;
  P1, P2: PByte;
  TempBuf: array[0..255] of Byte;
  NeedsFree: Boolean;
begin
  if R - L < 1 then Exit;

  // Hybrid: Insertion Sort for small partitions
  if R - L < 16 then
  begin
    NeedsFree := FElementSize > SizeOf(TempBuf);
    if NeedsFree then GetMem(PivotPtr, FElementSize) else PivotPtr := @TempBuf[0];
    try
      for I := L + 1 to R do
      begin
        P1 := FData + (I * FElementSize);
        System.Move(P1^, PivotPtr^, FElementSize);
        J := I - 1;
        while (J >= L) do
        begin
          P2 := FData + (J * FElementSize);
          if CompareFunc(P2, PivotPtr) <= 0 then Break;
          System.Move(P2^, (P2 + FElementSize)^, FElementSize);
          Dec(J);
        end;
        System.Move(PivotPtr^, (FData + (J + 1) * FElementSize)^, FElementSize);
      end;
    finally
      if NeedsFree then FreeMem(PivotPtr);
    end;
    Exit;
  end;

  // QuickSort with Median-of-Three
  I := L; J := R;
  var Mid := (L + R) div 2;
  if CompareFunc(FData + (L * FElementSize), FData + (Mid * FElementSize)) > 0 then ExchangeRaw(L, Mid);
  if CompareFunc(FData + (L * FElementSize), FData + (R * FElementSize)) > 0 then ExchangeRaw(L, R);
  if CompareFunc(FData + (Mid * FElementSize), FData + (R * FElementSize)) > 0 then ExchangeRaw(Mid, R);

  NeedsFree := FElementSize > SizeOf(TempBuf);
  if NeedsFree then GetMem(PivotPtr, FElementSize) else PivotPtr := @TempBuf[0];
  try
    System.Move((FData + (Mid * FElementSize))^, PivotPtr^, FElementSize);
    repeat
      while CompareFunc(FData + (I * FElementSize), PivotPtr) < 0 do Inc(I);
      while CompareFunc(FData + (J * FElementSize), PivotPtr) > 0 do Dec(J);
      if I <= J then
      begin
        ExchangeRaw(I, J);
        Inc(I); Dec(J);
      end;
    until I > J;
  finally
    if NeedsFree then FreeMem(PivotPtr);
  end;

  if L < J then InternalSortGeneric(L, J, CompareFunc);
  if I < R then InternalSortGeneric(I, R, CompareFunc);
end;

procedure TRawList.SortRaw(CompareFunc: TRawCompareFunc);
begin
  if FCount > 1 then InternalSortGeneric(0, FCount - 1, CompareFunc);
end;

procedure TRawList.SortRaw(AKind: TTypeKind);
begin if FCount > 1 then InternalSortHybrid(0, FCount - 1, AKind); end;

end.

program TestJsonUUID;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Dext.Types.UUID,
  Dext.Json;

type
  TTestRecord = record
    Id: TUUID;
    Name: string;
  end;

procedure TestRecordSerialization;
var
  Rec: TTestRecord;
  Json: string;
begin
  WriteLn('► Testing Record Serialization...');
  
  Rec.Id := TUUID.FromString('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11');
  Rec.Name := 'Test Item';
  
  Json := TDextJson.Serialize(Rec);
  WriteLn('  Serialized: ', Json);
  
  // Minimal check (Case Insensitive)
  if Pos('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', LowerCase(Json)) = 0 then
    raise Exception.Create('UUID value missing in JSON');
    
  WriteLn('  ✓ Record Serialization OK');
end;

procedure TestRecordDeserialization;
var
  Json: string;
  Rec: TTestRecord;
begin
  WriteLn('► Testing Record Deserialization...');
  
  Json := '{"Id": "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11", "Name": "Restored Item"}';
  Rec := TDextJson.Deserialize<TTestRecord>(Json);
  
  WriteLn('  Deserialized ID: ', Rec.Id.ToString);
  WriteLn('  Deserialized Name: ', Rec.Name);
  
  if LowerCase(Rec.Id.ToString) <> 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11' then
    raise Exception.Create('UUID deserialization mismatch (Expected lowercase)');
    
  WriteLn('  ✓ Record Deserialization OK');
end;

procedure TestArraySerialization;
var
  Arr: TArray<TUUID>;
  Json: string;
begin
  WriteLn('► Testing Array Serialization...');
  
  Arr := [TUUID.FromString('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'), 
          TUUID.FromString('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22')];
          
  Json := TDextJson.Serialize<TArray<TUUID>>(Arr);
  WriteLn('  Serialized Array: ', Json);
  
  if Pos('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', LowerCase(Json)) = 0 then
    raise Exception.Create('First UUID missing');
  if Pos('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', LowerCase(Json)) = 0 then
    raise Exception.Create('Second UUID missing');
    
  WriteLn('  ✓ Array Serialization OK');
end;

procedure TestArrayDeserialization;
var
  Json: string;
  Arr: TArray<TUUID>;
begin
  WriteLn('► Testing Array Deserialization...');
  
  Json := '["a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11", "b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22"]';
  Arr := TDextJson.Deserialize<TArray<TUUID>>(Json);
  
  WriteLn('  Length: ', Length(Arr));
  if Length(Arr) <> 2 then
    raise Exception.Create('Array length mismatch');
    
  if LowerCase(Arr[0].ToString) <> 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11' then
    raise Exception.Create('First element mismatch');
  
  if LowerCase(Arr[1].ToString) <> 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22' then
    raise Exception.Create('Second element mismatch');
    
  WriteLn('  ✓ Array Deserialization OK');
end;

begin
  try
    WriteLn('═══════════════════════════════════════════════════════════');
    WriteLn('  Dext.Json + TUUID Integration Test');
    WriteLn('═══════════════════════════════════════════════════════════');
    WriteLn;
    
    TestRecordSerialization;
    WriteLn;
    
    TestRecordDeserialization;
    WriteLn;
    
    TestArraySerialization;
    WriteLn;
    
    TestArrayDeserialization;
    WriteLn;
    
    WriteLn('═══════════════════════════════════════════════════════════');
    WriteLn('🎉 ALL TESTS PASSED!');
    WriteLn('═══════════════════════════════════════════════════════════');
  except
    on E: Exception do
    begin
      WriteLn;
      WriteLn('❌ TEST FAILED: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.

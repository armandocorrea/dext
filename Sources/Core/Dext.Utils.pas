unit Dext.Utils;

interface

uses
  WinApi.Windows;

procedure DebugLog(const AMessage: string);

implementation

procedure DebugLog(const AMessage: string);
begin
  OutputDebugString(PChar(AMessage + sLineBreak));
  Writeln(AMessage);
end;

end.

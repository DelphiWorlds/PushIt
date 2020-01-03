unit PI.Types;

interface

type
  TAPIKeyMRU = TArray<string>;

  TDeviceInfo = record
    ChannelId: string;
    DeviceID: string;
    Token: string;
    OS: string;
    LastSeen: TDateTime;
    function Equals(const ADeviceInfo: TDeviceInfo): Boolean;
  end;

  TDeviceInfos = TArray<TDeviceInfo>;

  TDeviceInfosHelper = record helper for TDeviceInfos
  public
    function Add(const ADeviceInfo: TDeviceInfo): Boolean;
    function Count: Integer;
    procedure Delete(const AIndex: Integer);
    function Expire(const ASeconds: Integer): Boolean;
    function IndexOf(const ADeviceID: string): Integer;
  end;

  TDeviceBroadcastEvent = procedure(Sender: TObject; const DeviceInfo: TDeviceInfo) of object;

implementation

uses
  // RTL
  System.SysUtils, System.DateUtils;

{ TDeviceInfo }

function TDeviceInfo.Equals(const ADeviceInfo: TDeviceInfo): Boolean;
begin
  Result := DeviceID.Equals(ADeviceInfo.DeviceID) and Token.Equals(ADeviceInfo.Token) and OS.Equals(ADeviceInfo.OS);
end;

{ TDeviceInfosHelper }

function TDeviceInfosHelper.Add(const ADeviceInfo: TDeviceInfo): Boolean;
var
  LIndex: Integer;
begin
  Result := True;
  LIndex := IndexOf(ADeviceInfo.DeviceID);
  if LIndex = -1 then
  begin
    SetLength(Self, Count + 1);
    LIndex := Count - 1;
    Self[LIndex] := ADeviceInfo;
  end
  else if not Self[LIndex].Equals(ADeviceInfo) then
    Self[LIndex] := ADeviceInfo
  else
    Result := False;
  if LIndex > -1 then
    Self[LIndex].LastSeen := Now;
end;

function TDeviceInfosHelper.Count: Integer;
begin
  Result := Length(Self);
end;

procedure TDeviceInfosHelper.Delete(const AIndex: Integer);
begin
  if (AIndex >= 0) and (AIndex < Count) then
    System.Delete(Self, AIndex, 1);
end;

function TDeviceInfosHelper.Expire(const ASeconds: Integer): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := Count - 1 downto 0 do
  begin
    if SecondsBetween(Now, Self[I].LastSeen) >= ASeconds then
    begin
      Delete(I);
      Result := True;
    end;
  end;
end;

function TDeviceInfosHelper.IndexOf(const ADeviceID: string): Integer;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    if Self[I].DeviceID.Equals(ADeviceID) then
      Exit(I);
  end;
  Result := -1;
end;

end.

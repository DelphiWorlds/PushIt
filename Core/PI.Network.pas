unit PI.Network;

interface

uses
  // RTL
  System.SysUtils, System.Classes,
  // Indy
  IdBaseComponent, IdComponent, IdUDPBase, IdUDPServer, IdGlobal, IdSocketHandle,
  // PushIt
  PI.Types;

type
  TNetwork = class(TDataModule)
    UDPServer: TIdUDPServer;
    procedure UDPServerUDPRead(AThread: TIdUDPListenerThread; const AData: TIdBytes; ABinding: TIdSocketHandle);
  private
    FOnDeviceBroadcast: TDeviceBroadcastEvent;
  public
    property OnDeviceBroadcast: TDeviceBroadcastEvent read FOnDeviceBroadcast write FOnDeviceBroadcast;
  end;

var
  Network: TNetwork;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

uses
  // RTL
  System.JSON;

procedure TNetwork.UDPServerUDPRead(AThread: TIdUDPListenerThread; const AData: TIdBytes; ABinding: TIdSocketHandle);
var
  LJSON: TJSONObject;
  LDeviceInfo: TDeviceInfo;
begin
  if not Assigned(FOnDeviceBroadcast) then
    Exit; // <======
  LJSON := TJSONObject.ParseJSONValue(BytesToString(AData)) as TJSONObject;
  if LJSON <> nil then
  try
    LJSON.TryGetValue('deviceid', LDeviceInfo.DeviceID);
    LJSON.TryGetValue('token', LDeviceInfo.Token);
    LJSON.TryGetValue('os', LDeviceInfo.OS);
    FOnDeviceBroadcast(Self, LDeviceInfo);
  finally
    LJSON.Free;
  end;
end;

end.

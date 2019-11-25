unit PI.View.Devices;

interface

uses
  // RTL
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  // FMX
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts, FMX.ListBox, FMX.Controls.Presentation, FMX.StdCtrls,
  // PushIt
  PI.Types;

type
  TDevicesView = class(TForm)
    ListBox: TListBox;
    BottomLayout: TLayout;
    CancelButton: TButton;
    UseButton: TButton;
    DeviceTimer: TTimer;
    procedure UseButtonClick(Sender: TObject);
    procedure DeviceTimerTimer(Sender: TObject);
    procedure ListBoxItemClick(const Sender: TCustomListBox; const Item: TListBoxItem);
  private
    FDeviceInfos: TDeviceInfos;
    FSelectedDeviceInfo: TDeviceInfo;
    FOnDevicesChange: TNotifyEvent;
    procedure DeviceBroadcastHandler(Sender: TObject; const ADeviceInfo: TDeviceInfo);
    procedure DeviceSelected;
    function GetIsMonitoring: Boolean;
    procedure ItemDblClickHandler(Sender: TObject);
    procedure SetIsMonitoring(const Value: Boolean);
    procedure UpdateDeviceInfoViews;
  public
    constructor Create(AOwner: TComponent); override;
    property DeviceInfos: TDeviceInfos read FDeviceInfos;
    property IsMonitoring: Boolean read GetIsMonitoring write SetIsMonitoring;
    property SelectedDeviceInfo: TDeviceInfo read FSelectedDeviceInfo;
    property OnDevicesChange: TNotifyEvent read FOnDevicesChange write FOnDevicesChange;
  end;

var
  DevicesView: TDevicesView;

implementation

{$R *.fmx}

uses
  // PushIt
  PI.Resources, PI.Network, PI.View.DeviceInfo;

type
  TDeviceInfoItem = class(TListBoxItem)
  private
    FView: TDeviceInfoView;
    procedure ViewClickHandler(Sender: TObject);
    procedure ViewDblClickHandler(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    property View: TDeviceInfoView read FView;
  end;

{ TDeviceInfoItem }

constructor TDeviceInfoItem.Create(AOwner: TComponent);
begin
  inherited;
  FView := TDeviceInfoView.Create(Self);
  Height := FView.Height;
  FView.OnClick := ViewClickHandler;
  FView.OnDblClick := ViewDblClickHandler;
  FView.Align := TAlignLayout.Client;
  FView.Parent := Self;
end;

procedure TDeviceInfoItem.ViewClickHandler(Sender: TObject);
begin
  ListBox.OnItemClick(ListBox, Self);
end;

procedure TDeviceInfoItem.ViewDblClickHandler(Sender: TObject);
begin
  OnDblClick(Self);
end;

{ TDevicesView }

constructor TDevicesView.Create(AOwner: TComponent);
begin
  inherited;
  Network.OnDeviceBroadcast := DeviceBroadcastHandler;
end;

procedure TDevicesView.DeviceBroadcastHandler(Sender: TObject; const ADeviceInfo: TDeviceInfo);
begin
  if FDeviceInfos.Add(ADeviceInfo) then
    UpdateDeviceInfoViews;
end;

procedure TDevicesView.DeviceSelected;
begin
  FSelectedDeviceInfo := TDeviceInfoItem(ListBox.ListItems[ListBox.ItemIndex]).View.DeviceInfo;
  ModalResult := mrOk;
end;

procedure TDevicesView.DeviceTimerTimer(Sender: TObject);
begin
  if FDeviceInfos.Expire(2) then
    UpdateDeviceInfoViews;
end;

function TDevicesView.GetIsMonitoring: Boolean;
begin
  Result := Network.UDPServer.Active;
end;

procedure TDevicesView.ItemDblClickHandler(Sender: TObject);
begin
  DeviceSelected;
end;

procedure TDevicesView.ListBoxItemClick(const Sender: TCustomListBox; const Item: TListBoxItem);
begin
  UseButton.Enabled := True;
end;

procedure TDevicesView.SetIsMonitoring(const Value: Boolean);
begin
  Network.UDPServer.Active := Value;
end;

procedure TDevicesView.UseButtonClick(Sender: TObject);
begin
  DeviceSelected;
end;

procedure TDevicesView.UpdateDeviceInfoViews;
var
  I: Integer;
  LItem: TDeviceInfoItem;
begin
  ListBox.Clear;
  for I := 0 to FDeviceInfos.Count - 1 do
  begin
    LItem := TDeviceInfoItem.Create(Self);
    LItem.View.DeviceInfo := FDeviceInfos[I];
    ListBox.ItemHeight := LItem.View.Height;
    LItem.OnDblClick := ItemDblClickHandler;
    LItem.Parent := ListBox;
  end;
  if ListBox.Items.Count = 0 then
    UseButton.Enabled := False;
  if Assigned(FOnDevicesChange) then
    FOnDevicesChange(Self);
end;

end.

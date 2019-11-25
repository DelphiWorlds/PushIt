unit PI.View.DeviceInfo;

interface

uses
  // RTL
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  // FMX
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls, FMX.Objects, FMX.Layouts,
  FMX.Controls.Presentation, FMX.Edit, FMX.ImgList,
  // PushIt
  PI.Types;

type
  TDeviceInfoView = class(TFrame)
    DetailsLayout: TLayout;
    DeviceIDLabel: TLabel;
    DeviceIDEdit: TEdit;
    TokenLabel: TLabel;
    TokenEdit: TEdit;
    OSImage: TGlyph;
    procedure ControlClickHandler(Sender: TObject);
  private
    FDeviceInfo: TDeviceInfo;
    procedure SetDeviceInfo(const ADeviceInfo: TDeviceInfo);
  public
    property DeviceInfo: TDeviceInfo read FDeviceInfo write SetDeviceInfo;
  end;

implementation

{$R *.fmx}

uses
  // PushIt
  PI.Resources;

{ TDeviceInfoView }

procedure TDeviceInfoView.ControlClickHandler(Sender: TObject);
begin
  OnClick(Self);
end;

procedure TDeviceInfoView.SetDeviceInfo(const ADeviceInfo: TDeviceInfo);
begin
  FDeviceInfo := ADeviceInfo;
  DeviceIDEdit.Text := FDeviceInfo.DeviceID;
  TokenEdit.Text := FDeviceInfo.Token;
  if FDeviceInfo.OS.Equals('Android') then
    OSImage.ImageIndex := 0
  else if FDeviceInfo.OS.Equals('IOS') then
    OSImage.ImageIndex := 1;
end;

end.

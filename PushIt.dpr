program PushIt;

{$I Styles.inc}

uses
  System.StartUpCopy,
  FMX.Forms,
  PI.View.Main in 'Views\PI.View.Main.pas' {MainView},
  PI.Consts in 'Core\PI.Consts.pas',
  PI.Config in 'Core\PI.Config.pas',
  PI.Resources in 'Core\PI.Resources.pas' {Resources: TDataModule},
  PI.Network in 'Core\PI.Network.pas' {Network: TDataModule},
  PI.Types in 'Core\PI.Types.pas',
  PI.View.Devices in 'Views\PI.View.Devices.pas' {DevicesView},
  PI.View.DeviceInfo in 'Views\PI.View.DeviceInfo.pas' {DeviceInfoView: TFrame};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TNetwork, Network);
  Application.CreateForm(TResources, Resources);
  Application.CreateForm(TMainView, MainView);
  Application.Run;
end.

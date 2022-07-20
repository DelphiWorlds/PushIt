unit PI.View.Main;

interface

uses
  // RTL
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, System.Actions, System.Json,
  // FMX
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo, FMX.StdCtrls, FMX.TabControl,
  FMX.Layouts, FMX.Edit, FMX.Objects, FMX.ComboEdit, FMX.ListBox, FMX.Memo.Types, FMX.ActnList,
  // DW
  DW.FCMSender,
  // PushIt
  PI.Types, PI.View.Devices, PI.Config;

type
  TMainView = class(TForm)
    ResponseMemo: TMemo;
    ResponseLabel: TLabel;
    TabControl: TTabControl;
    JSONTab: TTabItem;
    JSONMemo: TMemo;
    BottomLayout: TLayout;
    SendButton: TButton;
    MessageTab: TTabItem;
    MessageLayout: TLayout;
    TitleEdit: TEdit;
    BodyLabel: TLabel;
    BodyMemo: TMemo;
    ChannelLabel: TLabel;
    ChannelIDEdit: TEdit;
    TitleLabel: TLabel;
    TokenEdit: TEdit;
    ClearTokenEditButton: TClearEditButton;
    MessageButtonsLayout: TLayout;
    ClearMessageFieldsButton: TButton;
    ClearChannelIDEditButton: TClearEditButton;
    SeparatorLine: TLine;
    ClearAllFieldsButton: TButton;
    SubtitleLabel: TLabel;
    SubtitleEdit: TEdit;
    BadgeLabel: TLabel;
    BadgeEdit: TEdit;
    MessageFieldsLayout: TLayout;
    MessageTextLayout: TLayout;
    MessagePropsLayout: TLayout;
    SoundLabel: TLabel;
    SoundEdit: TEdit;
    ClickActionLabel: TLabel;
    ClickActionEdit: TEdit;
    DevicesButton: TButton;
    PriorityLabel: TLabel;
    PriorityComboBox: TComboBox;
    ContentAvailableCheckBox: TCheckBox;
    ImageURLLabel: TLabel;
    ImageURLEdit: TEdit;
    BigPictureCheckBox: TCheckBox;
    BigTextCheckBox: TCheckBox;
    ActionList: TActionList;
    SendAction: TAction;
    SelectServiceAccountJSONFileAction: TAction;
    ServiceAccountOpenDialog: TOpenDialog;
    ServiceAccountJSONLabel: TLabel;
    ServiceAccountJSONFileNameEdit: TEdit;
    ServiceAccountJSONFileButton: TEllipsesEditButton;
    LogCheckBox: TCheckBox;
    TokenTopicLayout: TLayout;
    TokenRadioButton: TRadioButton;
    TopicRadioButton: TRadioButton;
    ServiceAccountLayout: TLayout;
    DataOnlyCheckBox: TCheckBox;
    procedure JSONMemoChangeTracking(Sender: TObject);
    procedure MessageFieldChange(Sender: TObject);
    procedure ClearMessageFieldsButtonClick(Sender: TObject);
    procedure ClearAllFieldsButtonClick(Sender: TObject);
    procedure TabControlChange(Sender: TObject);
    procedure BadgeEditKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure BadgeEditChangeTracking(Sender: TObject);
    procedure DevicesButtonClick(Sender: TObject);
    procedure MessageTypeRadioButtonClick(Sender: TObject);
    procedure ContentAvailableCheckBoxClick(Sender: TObject);
    procedure PriorityComboBoxChange(Sender: TObject);
    procedure SelectServiceAccountJSONFileActionExecute(Sender: TObject);
    procedure ServiceAccountJSONFileNameEditChangeTracking(Sender: TObject);
    procedure SendActionExecute(Sender: TObject);
    procedure SendActionUpdate(Sender: TObject);
  private
    FConfig: TPushItConfig;
    FDevicesView: TDevicesView;
    FFCMSender: TFCMSender;
    FIsJSONModified: Boolean;
    FIsMessageModified: Boolean;
    FJSONDumpFolder: string;
    function CanSend: Boolean;
    procedure ConfirmUpdateJSON;
    procedure DevicesChangeHandler(Sender: TObject);
    procedure DumpJSON(const AJSON: string);
    procedure FCMSend;
    procedure FCMSenderErrorHandler(Sender: TObject; const AError: TFCMSenderError);
    procedure FCMSenderResponseHandler(Sender: TObject; const AResponse: TFCMSenderResponse);
    function GetMessageJSON: string;
    function HasMinRequiredFields: Boolean;
    function IsJSONValid: Boolean;
    procedure ParseServiceAccount;
    procedure ResponseReceived(const AResponse: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  MainView: TMainView;

implementation

{$R *.fmx}

uses
  // RTL
  System.Character, System.Net.HttpClient, System.Net.URLClient, System.NetConsts, System.IOUtils,
  REST.Types,
  // FMX
  FMX.DialogService,
  // DW
  DW.Classes.Helpers, DW.JSON,
  // PushIt
  PI.Consts, PI.Resources;

{ TMainView }

constructor TMainView.Create(AOwner: TComponent);
begin
  inherited;
  FJSONDumpFolder := TPath.Combine(TPath.GetTempPath, 'PushIt');
  ForceDirectories(FJSONDumpFolder);
  TabControl.ActiveTab := MessageTab;
  FFCMSender := TFCMSender.Create;
  FFCMSender.OnError := FCMSenderErrorHandler;
  FFCMSender.OnResponse := FCMSenderResponseHandler;
  FDevicesView := TDevicesView.Create(Application);
  FDevicesView.OnDevicesChange := DevicesChangeHandler;
  FDevicesView.IsMonitoring := True;
  FConfig := TPushItConfig.Current;
  ServiceAccountJSONFileNameEdit.Text := FConfig.ServiceAccountFileName;
  TokenEdit.Text := FConfig.Token;
end;

destructor TMainView.Destroy;
begin
  FFCMSender.Free;
  inherited;
end;

procedure TMainView.DevicesButtonClick(Sender: TObject);
begin
  if FDevicesView.ShowModal = mrOk then
  begin
    TokenEdit.Text := FDevicesView.SelectedDeviceInfo.Token;
    ChannelIDEdit.Text := FDevicesView.SelectedDeviceInfo.ChannelId;
  end;
end;

procedure TMainView.DevicesChangeHandler(Sender: TObject);
begin
  DevicesButton.Enabled := FDevicesView.DeviceInfos.Count > 0;
end;

procedure TMainView.DumpJSON(const AJSON: string);
var
  LFileName: string;
begin
  LFileName := TPath.Combine(FJSONDumpFolder, Format('Message-%s.json', [FormatDateTime('yyyy-mm-dd-hh-nn-ss-zzz', Now)]));
  TFile.WriteAllText(LFileName, TJsonHelper.Tidy(AJSON));
end;

procedure TMainView.BadgeEditChangeTracking(Sender: TObject);
begin
  if StrToIntDef(BadgeEdit.Text, -1) = -1 then
    BadgeEdit.Text := ''
  else
    MessageFieldChange(Sender);
end;

procedure TMainView.BadgeEditKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  if not (Key in [vkBack, vkDelete, vkLeft, vkRight]) and not KeyChar.IsDigit then
  begin
    Key := 0;
    KeyChar := #0;
  end;
end;

function TMainView.CanSend: Boolean;
begin
  Result := not TokenEdit.Text.Trim.IsEmpty and FFCMSender.ServiceAccount.IsValid and (HasMinRequiredFields or IsJSONValid);
end;

function TMainView.HasMinRequiredFields: Boolean;
begin
  Result := not TitleEdit.Text.Trim.IsEmpty and not BodyMemo.Text.Trim.IsEmpty;
end;

function TMainView.IsJSONValid: Boolean;
var
  LJSON: TJSONValue;
begin
  Result := False;
  if not JSONMemo.Text.IsEmpty then
  begin
    LJSON := TJSONObject.ParseJSONValue(JSONMemo.Text);
    if LJSON <> nil then
    begin
      Result := True;
      LJSON.Free;
    end;
  end;
end;

procedure TMainView.ClearAllFieldsButtonClick(Sender: TObject);
begin
  TokenEdit.Text := '';
  ChannelIDEdit.Text := '';
  ClearMessageFieldsButtonClick(ClearMessageFieldsButton);
  FIsMessageModified := False;
end;

procedure TMainView.ClearMessageFieldsButtonClick(Sender: TObject);
begin
  TitleEdit.Text := '';
  SubtitleEdit.Text := '';
  BodyMemo.Text := '';
  PriorityComboBox.ItemIndex := 0;
  ContentAvailableCheckBox.IsChecked := False;
  SoundEdit.Text := '';
  BadgeEdit.Text := '';
  ClickActionEdit.Text := '';
end;

procedure TMainView.ServiceAccountJSONFileNameEditChangeTracking(Sender: TObject);
begin
  ParseServiceAccount;
end;

procedure TMainView.FCMSend;
var
  LJSON: string;
begin
  if TabControl.ActiveTab = MessageTab then
    LJSON := GetMessageJSON
  else
    LJSON := JSONMemo.Text;
  DumpJSON(LJSON);
  if LogCheckBox.IsChecked then
    ResponseMemo.Lines.Add('Sending..');
  TDo.Run(
    procedure
    begin
      FFCMSender.Post(LJSON);
    end
  );
end;

procedure TMainView.FCMSenderErrorHandler(Sender: TObject; const AError: TFCMSenderError);
var
  LResponse: string;
begin
  LResponse := Format('Error - %s: %s - %s', [AError.Kind.ToString, AError.ErrorMessage, AError.Content]);
  TThread.Queue(nil, procedure begin ResponseReceived(LResponse) end);
end;

procedure TMainView.FCMSenderResponseHandler(Sender: TObject; const AResponse: TFCMSenderResponse);
begin
  TThread.Queue(nil, procedure begin ResponseReceived(AResponse.Response) end);
end;

procedure TMainView.JSONMemoChangeTracking(Sender: TObject);
begin
  FIsJSONModified := True;
end;

procedure TMainView.MessageFieldChange(Sender: TObject);
begin
  FIsMessageModified := True;
end;

procedure TMainView.MessageTypeRadioButtonClick(Sender: TObject);
begin
  FIsMessageModified := True;
end;

procedure TMainView.ParseServiceAccount;
begin
  if FFCMSender.LoadServiceAccount(ServiceAccountJSONFileNameEdit.Text) then
  begin
    FConfig.ServiceAccountFileName := ServiceAccountJSONFileNameEdit.Text;
    FConfig.Save;
  end;
end;

procedure TMainView.PriorityComboBoxChange(Sender: TObject);
begin
  FIsMessageModified := True;
end;

procedure TMainView.ContentAvailableCheckBoxClick(Sender: TObject);
begin
  FIsMessageModified := True;
end;

procedure TMainView.ResponseReceived(const AResponse: string);
begin
  ResponseMemo.Text := AResponse;
end;

function TMainView.GetMessageJSON: string;
var
  LMessage: TFCMMessage;
begin
  LMessage := TFCMMessage.Create;
  try
    LMessage.IsDataOnly := DataOnlyCheckBox.IsChecked;
    LMessage.Title := TitleEdit.Text;
    // LMessage.Subtitle := SubtitleEdit.Text;
    LMessage.Body := BodyMemo.Text;
    LMessage.ImageURL := ImageURLEdit.Text;
    if BigTextCheckBox.IsChecked then
      LMessage.Options := LMessage.Options + [TFCMMessageOption.BigText];
    if not LMessage.ImageURL.IsEmpty and BigPictureCheckBox.IsChecked then
      LMessage.Options := LMessage.Options + [TFCMMessageOption.BigImage];
    if ContentAvailableCheckBox.IsChecked then
      LMessage.Options := LMessage.Options + [TFCMMessageOption.ContentAvailable];
    case PriorityComboBox.ItemIndex of
      0:
        LMessage.Priority := TFCMMessagePriority.None;
      1:
        LMessage.Priority := TFCMMessagePriority.Normal;
      2:
        LMessage.Priority := TFCMMessagePriority.High;
    end;
    LMessage.SoundName := SoundEdit.Text;
    LMessage.BadgeCount := StrToIntDef(BadgeEdit.Text, 0);
    LMessage.ClickAction := ClickActionEdit.Text;
    if TokenRadioButton.IsChecked then
      Result := LMessage.GetTokenPayload(TokenEdit.Text)
    else
      Result := LMessage.GetTopicPayload(TokenEdit.Text);
  finally
    LMessage.Free;
  end;
end;

procedure TMainView.SelectServiceAccountJSONFileActionExecute(Sender: TObject);
begin
  if ServiceAccountOpenDialog.Execute then
  begin
    ServiceAccountJSONFileNameEdit.Text := ServiceAccountOpenDialog.FileName;
    ParseServiceAccount;
  end;
end;

procedure TMainView.SendActionExecute(Sender: TObject);
begin
  ResponseMemo.Text := '';
  FConfig.Token := TokenEdit.Text;
  FConfig.Save;
  FCMSend;
end;

procedure TMainView.SendActionUpdate(Sender: TObject);
begin
  SendAction.Enabled := CanSend;
end;

procedure TMainView.ConfirmUpdateJSON;
begin
  TDialogService.MessageDialog('Message fields have changed. Update JSON?', TMsgDlgType.mtConfirmation, mbYesNo, TMsgDlgBtn.mbNo, 0,
    procedure(const AResult: TModalResult)
    begin
      if AResult = mrYes then
      begin
        JSONMemo.Text := TJsonHelper.Tidy(GetMessageJSON);
        FIsMessageModified := False;
      end;
    end
  );
end;

procedure TMainView.TabControlChange(Sender: TObject);
begin
  if FIsMessageModified and (TabControl.ActiveTab = JSONTab) then
    ConfirmUpdateJSON;
end;

end.

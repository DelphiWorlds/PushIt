unit PI.View.Main;

interface

uses
  // RTL
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  // FMX
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo, FMX.StdCtrls, FMX.TabControl,
  FMX.Layouts, FMX.Edit, FMX.Objects, FMX.ComboEdit, FMX.ListBox, FMX.Memo.Types,
  // PushIt
  PI.Types, PI.View.Devices;

type
  TMainView = class(TForm)
    ResponseMemo: TMemo;
    ResponseLabel: TLabel;
    TabControl: TTabControl;
    JSONTab: TTabItem;
    JSONMemo: TMemo;
    BottomLayout: TLayout;
    SendButton: TButton;
    APIKeyLabel: TLabel;
    MessageTab: TTabItem;
    TokenLabel: TLabel;
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
    APIKeyEdit: TComboEdit;
    DevicesButton: TButton;
    PriorityLabel: TLabel;
    PriorityComboBox: TComboBox;
    ContentAvailableCheckBox: TCheckBox;
    MessageTypeLayout: TLayout;
    MessageTypeRadioLayout: TLayout;
    MessageTypeNotificationRadioButton: TRadioButton;
    MessageTypeDataRadioButton: TRadioButton;
    MessageTypeBothRadioButton: TRadioButton;
    MessageTypeLabel: TLabel;
    ImageURLLabel: TLabel;
    ImageURLEdit: TEdit;
    procedure SendButtonClick(Sender: TObject);
    procedure JSONMemoChangeTracking(Sender: TObject);
    procedure MessageFieldChange(Sender: TObject);
    procedure ClearMessageFieldsButtonClick(Sender: TObject);
    procedure ClearAllFieldsButtonClick(Sender: TObject);
    procedure TabControlChange(Sender: TObject);
    procedure BadgeEditKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure BadgeEditChangeTracking(Sender: TObject);
    procedure APIKeyEditClosePopup(Sender: TObject);
    procedure APIKeyEditPopup(Sender: TObject);
    procedure DevicesButtonClick(Sender: TObject);
    procedure MessageTypeRadioButtonClick(Sender: TObject);
    procedure ContentAvailableCheckBoxClick(Sender: TObject);
    procedure PriorityComboBoxChange(Sender: TObject);
  private
    FAPIKey: string;
    FDevicesView: TDevicesView;
    FIsJSONModified: Boolean;
    FIsMessageModified: Boolean;
    procedure ConfirmUpdateJSON;
    procedure DevicesChangeHandler(Sender: TObject);
    procedure FCMPost(const ARequest: TStream);
    procedure FCMSend(const AJSON: string);
    function GetMessageJSON: string;
    procedure ResponseReceived(const AResponse: string);
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  MainView: TMainView;

implementation

{$R *.fmx}

uses
  // RTL
  System.Json, System.Character, System.Net.HttpClient, System.Net.URLClient, System.NetConsts, REST.Types, REST.Json,
  // DW
  DW.Classes.Helpers, DW.REST.Json.Helpers,
  // PushIt
  PI.Consts, PI.Config, PI.Resources;

{ TMainView }

constructor TMainView.Create(AOwner: TComponent);
begin
  inherited;
  FDevicesView := TDevicesView.Create(Application);
  FDevicesView.OnDevicesChange := DevicesChangeHandler;
  FDevicesView.IsMonitoring := True;
  APIKeyEdit.Items.AddStrings(TPushItConfig.Current.APIKeyMRU);
  if APIKeyEdit.Items.Count > 0 then
    APIKeyEdit.ItemIndex := 0;
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

procedure TMainView.APIKeyEditClosePopup(Sender: TObject);
var
  LKey: string;
begin
  if (APIKeyEdit.ItemIndex > -1) and (APIKeyEdit.Tag <> APIKeyEdit.ItemIndex) then
  begin
    LKey := APIKeyEdit.Items[APIKeyEdit.ItemIndex];
    APIKeyEdit.Items.Delete(APIKeyEdit.ItemIndex);
    APIKeyEdit.Items.Insert(0, LKey);
    APIKeyEdit.ItemIndex := APIKeyEdit.Items.IndexOf(LKey);
    TPushItConfig.UpdateAPIKeyMRU(APIKeyEdit.Items.ToStringArray);
  end;
end;

procedure TMainView.APIKeyEditPopup(Sender: TObject);
begin
  APIKeyEdit.Tag := APIKeyEdit.Items.IndexOf(APIKeyEdit.Text);
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

procedure TMainView.FCMPost(const ARequest: TStream);
var
  LHTTP: THTTPClient;
  LResponse: IHTTPResponse;
  LContent: string;
begin
  LHTTP := THTTPClient.Create;
  try
    LHTTP.Accept := CONTENTTYPE_APPLICATION_JSON;
    LHTTP.ContentType := CONTENTTYPE_APPLICATION_JSON;
    LHTTP.CustomHeaders['Authorization'] := 'key=' + FAPIKey;
    LResponse := LHTTP.Post(cFCMSendURL, ARequest);
    LContent := LResponse.ContentAsString;
    TDo.SyncMain(
      procedure
      begin
        ResponseReceived(LContent);
      end
    );
  finally
    LHTTP.Free;
  end;
end;

procedure TMainView.FCMSend(const AJSON: string);
begin
  FAPIKey := APIKeyEdit.Text;
  TDo.Run(
    procedure
    var
      LRequest: TStream;
    begin
      LRequest := TStringStream.Create(AJSON);
      try
        FCMPost(LRequest);
      finally
        LRequest.Free;
      end;
    end
  );
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
  LJSON, LNotification: TJSONObject;
begin
  LJSON := TJSONObject.Create;
  try
    LJSON.AddPair('to', TokenEdit.Text);
    if ContentAvailableCheckBox.IsChecked then
      LJSON.AddPair('content_available', TJSONBool.Create(True));
    LNotification := TJSONObject.Create;
    if not ChannelIDEdit.Text.Trim.IsEmpty then
      LNotification.AddPair('android_channel_id', ChannelIDEdit.Text);
    LNotification.AddPair('title', TitleEdit.Text);
    if not SubtitleEdit.Text.Trim.IsEmpty then
      LNotification.AddPair('subtitle', SubtitleEdit.Text);
    if not BodyMemo.Text.Trim.IsEmpty then
      LNotification.AddPair('body', BodyMemo.Text);
    if PriorityComboBox.ItemIndex > 0 then
      LNotification.AddPair('priority', PriorityComboBox.Items[PriorityComboBox.ItemIndex].ToLower);
    if not SoundEdit.Text.Trim.IsEmpty then
      LNotification.AddPair('sound', SoundEdit.Text);
    if not BadgeEdit.Text.Trim.IsEmpty then
      LNotification.AddPair('badge', BadgeEdit.Text);
    if not ClickActionEdit.Text.Trim.IsEmpty then
      LNotification.AddPair('click_action', ClickActionEdit.Text);
    if not ImageURLEdit.Text.Trim.IsEmpty then
    begin
      LNotification.AddPair('image', ImageURLEdit.Text);
      //  Required for iOS
      LNotification.AddPair('mutable_content', TJSONBool.Create(True));
    end;
    if MessageTypeNotificationRadioButton.IsChecked then
      LJSON.AddPair('notification', LNotification)
    else if MessageTypeDataRadioButton.IsChecked then
      LJSON.AddPair('data', LNotification)
    else if MessageTypeBothRadioButton.IsChecked then
    begin
      LJSON.AddPair('notification', LNotification);
      LJSON.AddPair('data', TJSONObject(LNotification.Clone));
    end;
    Result := LJSON.ToJSON;
  finally
    LJSON.Free;
  end;
end;

procedure TMainView.SendButtonClick(Sender: TObject);
begin
  ResponseMemo.Text := '';
  if APIKeyEdit.Items.IndexOf(APIKeyEdit.Text) = -1 then
  begin
    APIKeyEdit.Items.Insert(0, APIKeyEdit.Text);
    TPushItConfig.UpdateAPIKeyMRU(APIKeyEdit.Items.ToStringArray);
  end;
  if TabControl.ActiveTab = MessageTab then
    FCMSend(GetMessageJSON)
  else
    FCMSend(JSONMemo.Text);
end;

procedure TMainView.ConfirmUpdateJSON;
begin
  if MessageDlg('Message fields have changed. Update JSON?', TMsgDlgType.mtConfirmation, mbYesNo, 0) = mrYes then
  begin
    JSONMemo.Text := TJson.Tidy(GetMessageJSON);
    FIsMessageModified := False;
  end;
end;

procedure TMainView.TabControlChange(Sender: TObject);
begin
  if FIsMessageModified and (TabControl.ActiveTab = JSONTab) then
    ConfirmUpdateJSON;
end;

end.

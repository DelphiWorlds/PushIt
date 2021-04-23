unit PI.View.Main;

interface

uses
  // RTL
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, System.Actions, System.Json,
  // FMX
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo, FMX.StdCtrls, FMX.TabControl,
  FMX.Layouts, FMX.Edit, FMX.Objects, FMX.ComboEdit, FMX.ListBox, FMX.Memo.Types, FMX.ActnList,
  // PushIt
  PI.Types, PI.View.Devices, PI.Config, PI.OAuth2;

type
  TServiceAccount = record
    AuthURI: string;
    ClientEmail: string;
    ClientID: string;
    IsValid: Boolean;
    PrivateKey: string;
    ProjectID: string;
    TokenURI: string;
    function ParseJSON(const AJSON: string): Boolean;
  end;

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
    BigPictureCheckBox: TCheckBox;
    BigTextCheckBox: TCheckBox;
    APILayout: TLayout;
    LegacyHTTPAPIRadioButton: TRadioButton;
    HTTPv1APIRadioButton: TRadioButton;
    ActionList: TActionList;
    SendAction: TAction;
    SelectServiceAccountJSONFileAction: TAction;
    ServiceAccountOpenDialog: TOpenDialog;
    ServiceAccountJSONLabel: TLabel;
    ServiceAccountJSONFileNameEdit: TEdit;
    ServiceAccountJSONFileButton: TEllipsesEditButton;
    APIInfoLayout: TLayout;
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
    procedure SelectServiceAccountJSONFileActionExecute(Sender: TObject);
    procedure ServiceAccountJSONFileNameEditChangeTracking(Sender: TObject);
    procedure SendActionExecute(Sender: TObject);
    procedure SendActionUpdate(Sender: TObject);
    procedure LegacyHTTPAPIRadioButtonChange(Sender: TObject);
  private
    FAPIKey: string;
    FConfig: TPushItConfig;
    FDevicesView: TDevicesView;
    FIsJSONModified: Boolean;
    FIsMessageModified: Boolean;
    FJSONDumpFolder: string;
    FOAuth2: TPushItOAuth2;
    FServiceAccount: TServiceAccount;
    function CanSendLegacy: Boolean;
    function CanSendNonLegacy: Boolean;
    procedure ConfirmUpdateJSON;
    procedure DevicesChangeHandler(Sender: TObject);
    procedure DumpJSON(const AJSON: string);
    procedure FCMPost(const ARequest: TStream);
    procedure FCMSend;
    function GetAndroidJSONValue: TJSONValue;
    function GetAndroidNotificationJSONValue: TJSONValue;
    function GetAPNSJSONValue: TJSONValue;
    function GetDataJSONValue: TJSONValue;
    function GetMessageJSONLegacy: string;
    function GetMessageJSONNonLegacy: string;
    function HasMinRequiredFields: Boolean;
    procedure OAuth2AuthenticateCompleteHandler(const ASuccess: Boolean; const AMsg: string);
    procedure ParseServiceAccount;
    procedure ResponseReceived(const AResponse: string);
    function UseLegacyAPI: Boolean;
    procedure UseLegacyAPIChanged;
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
  REST.Types, REST.Json,
  // FMX
  FMX.DialogService,
  // DW
  DW.Classes.Helpers, DW.REST.Json.Helpers,
  // PushIt
  PI.Consts, PI.Resources;

{ TServiceAccount }

function TServiceAccount.ParseJSON(const AJSON: string): Boolean;
var
  LJSONValue: TJSONValue;
begin
  Result := False;
  IsValid := False;
  ClientID := '';
  ClientEmail := '';
  ProjectID := '';
  PrivateKey := '';
  AuthURI := '';
  TokenURI := '';
  if not AJSON.IsEmpty then
  begin
    LJSONValue := TJsonObject.ParseJSONValue(AJSON);
    if LJSONValue <> nil then
    try
      IsValid := LJSONValue.TryGetValue('client_id', ClientID)
        and LJSONValue.TryGetValue('client_email', ClientEmail)
        and LJSONValue.TryGetValue('private_key', PrivateKey)
        and LJSONValue.TryGetValue('project_id', ProjectID)
        and LJSONValue.TryGetValue('auth_uri', AuthURI)
        and LJSONValue.TryGetValue('token_uri', TokenURI);
      Result := IsValid;
    finally
      LJSONValue.Free;
    end;
  end;
end;

{ TMainView }

constructor TMainView.Create(AOwner: TComponent);
begin
  inherited;
  FJSONDumpFolder := TPath.Combine(TPath.GetTempPath, 'PushIt');
  ForceDirectories(FJSONDumpFolder);
  TabControl.ActiveTab := MessageTab;
  FOAuth2 := TPushItOAuth2.Create;
  FDevicesView := TDevicesView.Create(Application);
  FDevicesView.OnDevicesChange := DevicesChangeHandler;
  FDevicesView.IsMonitoring := True;
  FConfig := TPushItConfig.Current;
  ServiceAccountJSONFileNameEdit.Text := FConfig.ServiceAccountFileName;
  APIKeyEdit.Items.AddStrings(TPushItConfig.Current.APIKeyMRU);
  if APIKeyEdit.Items.Count > 0 then
    APIKeyEdit.ItemIndex := 0;
  TokenEdit.Text := FConfig.Token;
  UseLegacyAPIChanged;
end;

destructor TMainView.Destroy;
begin
  FOAuth2.Free;
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
  TFile.WriteAllText(LFileName, TJson.Tidy(AJSON));
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
    FConfig.UpdateAPIKeyMRU(APIKeyEdit.Items.ToStringArray);
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

function TMainView.CanSendLegacy: Boolean;
begin
  // Needs Server Key, Token...
  Result := not APIKeyEdit.Text.Trim.IsEmpty and not TokenEdit.Text.Trim.IsEmpty;
end;

function TMainView.CanSendNonLegacy: Boolean;
begin
  // Needs token plus OAuth2 stuff...
  Result := not TokenEdit.Text.Trim.IsEmpty and FServiceAccount.IsValid;
end;

function TMainView.HasMinRequiredFields: Boolean;
begin
  Result := not TitleEdit.Text.Trim.IsEmpty and not BodyMemo.Text.Trim.IsEmpty;
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

procedure TMainView.FCMPost(const ARequest: TStream);
var
  LHTTP: THTTPClient;
  LResponse: IHTTPResponse;
  LContent, LURL: string;
begin
  LHTTP := THTTPClient.Create;
  try
    LHTTP.Accept := CONTENTTYPE_APPLICATION_JSON;
    LHTTP.ContentType := CONTENTTYPE_APPLICATION_JSON;
    if UseLegacyAPI then
    begin
      LURL := cFCMLegacyHTTPSendURL;
      LHTTP.CustomHeaders['Authorization'] := 'key=' + FAPIKey;
    end
    else
    begin
      LURL := Format(cFCMHTTPv1SendURL, [FServiceAccount.ProjectID]);
      LHTTP.CustomHeaders['Authorization'] := 'Bearer ' + FOAuth2.AccessToken;
    end;
    LResponse := LHTTP.Post(LURL, ARequest);
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

procedure TMainView.OAuth2AuthenticateCompleteHandler(const ASuccess: Boolean; const AMsg: string);
begin
  if ASuccess then
    FCMSend
  else
    ResponseMemo.Text := AMsg;
end;

procedure TMainView.FCMSend;
var
  LJSON: string;
begin
  if UseLegacyAPI or not FOAuth2.NeedsAuthentication then
  begin
    if UseLegacyAPI then
      FAPIKey := APIKeyEdit.Text;
    if TabControl.ActiveTab = MessageTab then
    begin
      if UseLegacyAPI then
        LJSON := GetMessageJSONLegacy
      else
        LJSON := GetMessageJSONNonLegacy;
    end
    else
      LJSON := JSONMemo.Text;
    DumpJSON(LJSON);
    TDo.Run(
      procedure
      var
        LRequest: TStream;
      begin
        LRequest := TStringStream.Create(LJSON);
        try
          FCMPost(LRequest);
        finally
          LRequest.Free;
        end;
      end
    );
  end
  else if not UseLegacyAPI and FOAuth2.NeedsAuthentication then
    FOAuth2.Authenticate(OAuth2AuthenticateCompleteHandler);
end;

procedure TMainView.JSONMemoChangeTracking(Sender: TObject);
begin
  FIsJSONModified := True;
end;

procedure TMainView.LegacyHTTPAPIRadioButtonChange(Sender: TObject);
begin
  UseLegacyAPIChanged;
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
var
  LJSON: string;
begin
  FOAuth2.Clear;
  LJSON := '';
  if TFile.Exists(ServiceAccountJSONFileNameEdit.Text) then
    LJSON := TFile.ReadAllText(ServiceAccountJSONFileNameEdit.Text);
  if FServiceAccount.ParseJSON(LJSON) then
  begin
    FOAuth2.AuthURI := FServiceAccount.AuthURI;
    FOAuth2.TokenURI := FServiceAccount.TokenURI;
    FOAuth2.PrivateKey := FServiceAccount.PrivateKey;
    FOAuth2.ClientID := FServiceAccount.ClientID;
    FOAuth2.ClientEmail := FServiceAccount.ClientEmail;
    FConfig.ServiceAccountFileName := ServiceAccountJSONFileNameEdit.Text;
    FConfig.Save;
  end;
  UseLegacyAPIChanged;
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

function TMainView.GetMessageJSONLegacy: string;
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
    if BigTextCheckBox.IsChecked then
      LNotification.AddPair('big_text', TJSONNumber.Create(1));
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
      if BigPictureCheckBox.IsChecked then
        LNotification.AddPair('big_image', TJSONNumber.Create(1));
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

function TMainView.GetAndroidNotificationJSONValue: TJSONValue;
var
  LNotification: TJSONObject;
begin
  Result := nil;
  LNotification := TJSONObject.Create;
  if not ClickActionEdit.Text.Trim.IsEmpty then
    LNotification.AddPair('click_action', ClickActionEdit.Text);
  if not ChannelIDEdit.Text.Trim.IsEmpty then
    LNotification.AddPair('channel_id', ChannelIDEdit.Text);
  if not ImageURLEdit.Text.Trim.IsEmpty then
    LNotification.AddPair('image', ImageURLEdit.Text);
  if not SoundEdit.Text.Trim.IsEmpty then
    LNotification.AddPair('sound', SoundEdit.Text);
  Result := LNotification;
end;

function TMainView.GetDataJSONValue: TJSONValue;
var
  LData: TJSONObject;
  LHasData: Boolean;
begin
  Result := nil;
  LHasData := False;
  LData := TJSONObject.Create;
  try
    LData.AddPair('something', 'bloop');
    LHasData := LData.Count > 0;
  finally
    if LHasData then
      Result := LData
    else
      LData.Free;
  end;
end;

function TMainView.GetAndroidJSONValue: TJSONValue;
var
  LAndroid: TJSONObject;
  LData, LNotification: TJSONValue;
begin
  LAndroid := TJSONObject.Create;
  if PriorityComboBox.ItemIndex > 0 then
    LAndroid.AddPair('priority', PriorityComboBox.Items[PriorityComboBox.ItemIndex].ToLower);
  LData := GetDataJSONValue;
  if LData <> nil then
    LAndroid.AddPair('data', LData);
  LNotification := GetAndroidNotificationJSONValue;
  if LNotification <> nil then
    LAndroid.AddPair('notification', LNotification);
  Result := LAndroid;
end;

// Reference for aps member: https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/generating_a_remote_notification?language=objc
// Do not put title and body in here - they are set in the notification member
function TMainView.GetAPNSJSONValue: TJSONValue;
var
  LAPNS, LPayload, LAPS: TJSONObject;
  LHasAPS: Boolean;
begin
  Result := nil;
  LHasAPS := False;
  LAPNS := TJSONObject.Create;
  try
    LPayload := TJSONObject.Create;
    LAPNS.AddPair('payload', LPayload);
    LAPS := TJSONObject.Create;
    LPayload.AddPair('aps', LAPS);
    if not SoundEdit.Text.Trim.IsEmpty then
      LAPS.AddPair('sound', SoundEdit.Text);
    if not BadgeEdit.Text.Trim.IsEmpty then
      LAPS.AddPair('badge', BadgeEdit.Text);
    if ContentAvailableCheckBox.IsChecked then
      LAPS.AddPair('content-available', TJSONBool.Create(True));
    // Add this LAST
    if LAPS.Count > 0 then
      LAPS.AddPair('mutable-content', TJSONBool.Create(True));
    LHasAPS := LAPS.Count > 0;
  finally
    if LHasAPS then
      Result := LAPNS
    else
      LAPNS.Free;
  end;
end;

// https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages

function TMainView.GetMessageJSONNonLegacy: string;
var
  LJSON, LMessage, LNotification: TJSONObject;
  LData, LAndroid, LAPNS: TJSONValue;
begin
  LJSON := TJSONObject.Create;
  try
    LMessage := TJSONObject.Create;
    LJSON.AddPair('message', LMessage);
    LMessage.AddPair('token', TokenEdit.Text);
    LNotification := TJSONObject.Create;
    LMessage.AddPair('notification', LNotification);
    LNotification.AddPair('title', TitleEdit.Text);
    if not BodyMemo.Text.Trim.IsEmpty then
      LNotification.AddPair('body', BodyMemo.Text);
    if not ImageURLEdit.Text.Trim.IsEmpty then
      LNotification.AddPair('image', ImageURLEdit.Text);
    LAndroid := GetAndroidJSONValue;
    if LAndroid <> nil then
      LMessage.AddPair('android', LAndroid);
    LAPNS := GetAPNSJSONValue;
    if LAPNS <> nil then
      LMessage.AddPair('apns', LAPNS);
    Result := LJSON.ToJSON;
  finally
    LJSON.Free;
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
  if APIKeyEdit.Items.IndexOf(APIKeyEdit.Text) = -1 then
  begin
    APIKeyEdit.Items.Insert(0, APIKeyEdit.Text);
    FConfig.UpdateAPIKeyMRU(APIKeyEdit.Items.ToStringArray);
  end;
  FConfig.Token := TokenEdit.Text;
  FConfig.Save;
  FCMSend;
end;

procedure TMainView.SendActionUpdate(Sender: TObject);
begin
  SendAction.Enabled := (UseLegacyAPI and CanSendLegacy) or (not UseLegacyAPI and CanSendNonLegacy);
end;

procedure TMainView.ConfirmUpdateJSON;
begin
  TDialogService.MessageDialog('Message fields have changed. Update JSON?', TMsgDlgType.mtConfirmation, mbYesNo, TMsgDlgBtn.mbNo, 0,
    procedure(const AResult: TModalResult)
    begin
      if AResult = mrYes then
      begin
        if UseLegacyAPI then
          JSONMemo.Text := TJson.Tidy(GetMessageJSONLegacy)
        else
          JSONMemo.Text := TJson.Tidy(GetMessageJSONNonLegacy);
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

function TMainView.UseLegacyAPI: Boolean;
begin
  Result := LegacyHTTPAPIRadioButton.IsChecked;
end;

procedure TMainView.UseLegacyAPIChanged;
begin
  ServiceAccountJSONFileNameEdit.Enabled := HTTPv1APIRadioButton.IsChecked;
  APIKeyEdit.Enabled := LegacyHTTPAPIRadioButton.IsChecked;
  MessageTypeRadioLayout.Enabled := LegacyHTTPAPIRadioButton.IsChecked;
end;

end.

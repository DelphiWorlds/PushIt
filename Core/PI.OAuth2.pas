unit PI.OAuth2;

// VERY basic OAuth2 implementation, purely for Google

interface

type
  TBearerToken = record
  public
    access_token: string;
    expires_in: Integer;
    ext_expires_in: Integer;
    id_token: string;
    refresh_token: string;
    scope: string;
    token_type: string;
    TokenDateTime: TDateTime;
    function IsExpired: Boolean;
    procedure Parse(const AJSON: string);
    procedure Reset;
    function ToJSON: string;
  end;

  TAuthenticateCompleteProc = reference to procedure(const Success: Boolean; const Msg: string);

  TPushItOAuth2 = class(TObject)
  private
    FAuthURI: string;
    FBearerToken: TBearerToken;
    FClientID: string;
    FClientEmail: string;
    FPrivateKey: string;
    FTokenURI: string;
    function GetAccessToken: string;
    procedure InternalAuthenticate(const ACompleteHandler: TAuthenticateCompleteProc);
  public
    procedure Authenticate(const ACompleteHandler: TAuthenticateCompleteProc);
    procedure Clear;
    function NeedsAuthentication: Boolean;
    property AccessToken: string read GetAccessToken;
    property AuthURI: string read FAuthURI write FAuthURI;
    property ClientEmail: string read FClientEmail write FClientEmail;
    property ClientID: string read FClientID write FClientID;
    property PrivateKey: string read FPrivateKey write FPrivateKey;
    property TokenURI: string read FTokenURI write FTokenURI;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.JSON, System.DateUtils, System.Net.HttpClient, System.NetEncoding,
  REST.Types,
  PI.JWT;

const
  cOAuth2AccessTokenRequestTemplate = 'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=%s';

{ TBearerToken }

procedure TBearerToken.Parse(const AJSON: string);
var
  LDateTime: string;
  LValue: TJSONValue;
begin
  Reset;
  LValue := TJSONObject.ParseJSONValue(AJSON);
  if LValue <> nil then
  try
    LValue.TryGetValue('access_token', access_token);
    LValue.TryGetValue('expires_in', expires_in);
    LValue.TryGetValue('ext_expires_in', ext_expires_in);
    LValue.TryGetValue('id_token', id_token);
    LValue.TryGetValue('refresh_token', refresh_token);
    LValue.TryGetValue('scope', scope);
    LValue.TryGetValue('token_type', token_type);
    // Note: this is *not* returned by the server - it is used for determining whether or not the token has expired
    if LValue.TryGetValue('token_datetime', LDateTime) then
      TokenDateTime := ISO8601ToDate(LDateTime, False)
    else
      TokenDateTime := Now;
  finally
    LValue.Free;
  end;
end;

function TBearerToken.IsExpired: Boolean;
begin
  Result := access_token.IsEmpty or (SecondsBetween(Now, TokenDateTime) > expires_in);
end;

procedure TBearerToken.Reset;
begin
  access_token := '';
  expires_in := 0;
  ext_expires_in := 0;
  id_token := '';
  refresh_token := '';
  scope := '';
  token_type := '';
  TokenDateTime := 0;
end;

function TBearerToken.ToJSON: string;
var
  LJSON: TJSONObject;
begin
  LJSON := TJSONObject.Create;
  try
    LJSON.AddPair('access_token', access_token);
    LJSON.AddPair('expires_in', expires_in.ToString);
    LJSON.AddPair('ext_expires_in', ext_expires_in.ToString);
    LJSON.AddPair('id_token', id_token);
    LJSON.AddPair('refresh_token', refresh_token);
    LJSON.AddPair('scope', scope);
    LJSON.AddPair('token_type', token_type);
    LJSON.AddPair('token_datetime', DateToISO8601(TokenDateTime, False));
    Result := LJSON.ToJSON;
  finally
    LJSON.Free;
  end;
end;

{ TPushItOAuth2 }

procedure TPushItOAuth2.Clear;
begin
  FAuthURI := '';
  FClientID := '';
  FPrivateKey := '';
  FTokenURI := '';
end;

function TPushItOAuth2.GetAccessToken: string;
begin
  Result := FBearerToken.access_token;
end;

function TPushItOAuth2.NeedsAuthentication: Boolean;
begin
  Result := FBearerToken.IsExpired;
end;

procedure TPushItOAuth2.Authenticate(const ACompleteHandler: TAuthenticateCompleteProc);
begin
  TThread.CreateAnonymousThread(procedure begin InternalAuthenticate(ACompleteHandler) end).Start;
end;

procedure TPushItOAuth2.InternalAuthenticate(const ACompleteHandler: TAuthenticateCompleteProc);
var
  LHTTP: THTTPClient;
  LResponse: IHTTPResponse;
  LRequest: TStringStream;
  LContent, LResponseString, LMessage: string;
  LJWT: TGoogleJWT;
begin
  LMessage := '';
  LJWT.Claim.Iss := FClientEmail;
  // LContent := Format(cOAuth2AccessTokenRequestTemplate, [LJWT.GenerateToken(FPrivateKey)]);
  LContent := Format(cOAuth2AccessTokenRequestTemplate, [TNetEncoding.URL.EncodeForm(LJWT.GenerateToken(FPrivateKey))]);
  LResponse := nil;
  LHTTP := THTTPClient.Create;
  try
    LHTTP.ContentType := CONTENTTYPE_APPLICATION_X_WWW_FORM_URLENCODED;
    LRequest := TStringStream.Create(LContent);
    try
      LResponse := LHTTP.Post(FTokenURI, LRequest);
    finally
      LRequest.Free;
    end;
  finally
    LHTTP.Free;
  end;
  LResponseString := LResponse.ContentAsString;
  if LResponse.StatusCode = 200 then
    FBearerToken.Parse(LResponseString)
  else
    LMessage := Format('Authentication failed - %d: %s'#13#10'%s', [LResponse.StatusCode, LResponse.StatusText, LResponseString]);
  TThread.Synchronize(nil, procedure begin ACompleteHandler(LResponse.StatusCode = 200, LMessage) end);
end;

end.

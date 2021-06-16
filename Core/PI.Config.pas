unit PI.Config;

interface

uses
  // PushIt
  PI.Types;

type
  TPushItConfig = class(TObject)
  private
    class var FCurrent: TPushItConfig;
    class destructor DestroyClass;
    class function GetCurrent: TPushItConfig; static;
    class function GetFileName: string;
  private
    FAPIKeyMRU: TAPIKeyMRU;
    FServiceAccountFileName: string;
    FToken: string;
  public
    class property Current: TPushItConfig read GetCurrent;
  public
    procedure Save;
    procedure UpdateAPIKeyMRU(const AMRU: TArray<string>);
    property APIKeyMRU: TAPIKeyMRU read FAPIKeyMRU write FAPIKeyMRU;
    property ServiceAccountFileName: string read FServiceAccountFileName write FServiceAccountFileName;
    property Token: string read FToken write FToken;
  end;

implementation

uses
  // RTL
  System.IOUtils, System.SysUtils,
  // REST
  REST.Json;

{ TPushItConfig }

class destructor TPushItConfig.DestroyClass;
begin
  FCurrent.Free;
end;

class function TPushItConfig.GetCurrent: TPushItConfig;
begin
  if FCurrent = nil then
  begin
    if TFile.Exists(GetFileName) then
      FCurrent := TJson.JsonToObject<TPushItConfig>(TFile.ReadAllText(GetFileName))
    else
      FCurrent := TPushItConfig.Create;
  end;
  Result := FCurrent;
end;

class function TPushItConfig.GetFileName: string;
begin
  Result := TPath.Combine(TPath.GetDocumentsPath, 'PushIt\Config.json');
  ForceDirectories(TPath.GetDirectoryName(Result));
end;

procedure TPushItConfig.Save;
begin
  TFile.WriteAllText(GetFileName, TJson.ObjectToJsonString(Self));
end;

procedure TPushItConfig.UpdateAPIKeyMRU(const AMRU: TArray<string>);
begin
  Current.APIKeyMRU := AMRU;
  Current.Save;
end;

end.

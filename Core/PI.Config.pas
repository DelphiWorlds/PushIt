unit PI.Config;

interface

uses
  // PushIt
  PI.Types;

type
  TPushItConfig = class(TObject)
  private
    class var FCurrent: TPushItConfig;
    class function GetCurrent: TPushItConfig; static;
    class function GetFileName: string;
  private
    FAPIKeyMRU: TAPIKeyMRU;
  public
    class procedure UpdateAPIKeyMRU(const AMRU: TArray<string>);
    class property Current: TPushItConfig read GetCurrent;
  public
    procedure Save;
    property APIKeyMRU: TAPIKeyMRU read FAPIKeyMRU write FAPIKeyMRU;
  end;

implementation

uses
  // RTL
  System.IOUtils, System.SysUtils,
  // REST
  REST.Json;

{ TPushItConfig }

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
end;

procedure TPushItConfig.Save;
begin
  TFile.WriteAllText(GetFileName, TJson.ObjectToJsonString(Self));
end;

class procedure TPushItConfig.UpdateAPIKeyMRU(const AMRU: TArray<string>);
begin
  ForceDirectories(TPath.GetDirectoryName(GetFileName));
  Current.APIKeyMRU := AMRU;
  Current.Save;
end;

end.

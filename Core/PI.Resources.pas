unit PI.Resources;

interface

uses
  // RTL
  System.SysUtils, System.Classes, System.ImageList,
  // FMX
  FMX.Types, FMX.Controls, FMX.ImgList;

type
  TResources = class(TDataModule)
    StyleBook: TStyleBook;
    ImageList: TImageList;
  private
    procedure LoadStyle;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  Resources: TResources;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

uses
  // RTL
  System.Types;

const
  cApplicationStyleResourceName = 'Application';

{ TResources }

constructor TResources.Create(AOwner: TComponent);
begin
  inherited;
  LoadStyle;
end;

procedure TResources.LoadStyle;
var
  LStream: TStream;
begin
  if FindResource(HInstance, PChar(cApplicationStyleResourceName), RT_RCDATA) > 0 then
  begin
    LStream := TResourceStream.Create(HInstance, cApplicationStyleResourceName, RT_RCDATA);
    try
      StyleBook.LoadFromStream(LStream);
    finally
      LStream.Free;
    end;
  end;
end;

end.

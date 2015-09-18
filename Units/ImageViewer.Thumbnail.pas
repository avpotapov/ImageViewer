
unit ImageViewer.Thumbnail;

interface

uses
  System.SysUtils,
  System.Classes,
  Winapi.ShlObj,
  Vcl.Graphics;

type
  IThumbnail = interface
    ['{C8F45F3A-D736-4ECF-8A7F-0DC5C89E7010}']
    function GetBitmap: TBitmap;
    function GetPidl: PItemIdList;
    procedure SetPidl(const APidl: PItemIdList);
    procedure SetBitmap(const ABitmap: TBitmap);

    property Pidl: PItemIdList read GetPidl write SetPidl;
    property Bitmap: TBitmap read GetBitmap write SetBitmap;

  end;

  TThumbnail = class(TInterfacedObject, IThumbnail)
  private
    FPidl  : PItemIdList;
    FBitmap: TBitmap;
  private
    function GetPidl: PItemIdList;
    procedure SetPidl(const APidl: PItemIdList);
    function GetBitmap: TBitmap;
    procedure SetBitmap(const ABitmap: TBitmap);
  public
    constructor Create(const APidl: PItemIdList; const ABitmap: TBitmap);
    destructor Destroy; override;
  end;

implementation

constructor TThumbnail.Create(const APidl: PItemIdList; const ABitmap: TBitmap);
begin
  FPidl   := APidl;
  FBitmap := ABitmap;
end;

destructor TThumbnail.Destroy;
begin
  FreeAndNil(FBitmap);
  inherited;
end;

function TThumbnail.GetBitmap: TBitmap;
begin
  Result := FBitmap;
end;

function TThumbnail.GetPidl: PItemIdList;
begin
  Result := FPidl;
end;

procedure TThumbnail.SetBitmap(const ABitmap: TBitmap);
begin
  FBitmap := ABitmap;
end;

procedure TThumbnail.SetPidl(const APidl: PItemIdList);
begin
  FPidl := APidl;
end;

end.

unit ImageViewer.ShlExt;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.ShlObj,
  Winapi.ShellApi,
  Winapi.ActiveX,
  System.Win.ComObj,
  System.SysUtils,
  System.Variants,
  System.Classes;

const
  {$EXTERNALSYM IID_IThumbnailProvider}
  IID_IThumbnailProvider: TGUID = '{e357fccd-a995-4576-b01f-234630154e96}';

type

  {$EXTERNALSYM IThumbnailProvider}
  IThumbnailProvider = interface(IUnknown)
    ['{e357fccd-a995-4576-b01f-234630154e96}']
    function GetThumbnail(cx : uint; out hBitmap : HBITMAP; out bitmapType : dword):HRESULT;stdcall;
  end;



  TShlExt = class
  private
    class var DesktopFolder: IShellFolder;
  private
    class var Malloc: IMalloc;
  public
    class procedure Initialize;
    class function GetShellFolder(const APidl: PItemIdList): IShellFolder;
    class function GetRootPidl(const ACsidl: DWord = CSIDL_DRIVES): PItemIdList;
    class procedure FreePidl(out APidl: PItemIdList);
    class function GetFileInfo(const APidl: PItemIdList): TShFileInfo;
    class function HasFolder(const APidl: PItemIdList; const AParentPidl: PItemIdList = nil): Boolean;
    class function GetFolderList(const APidl: PItemIdList): IEnumIdList;
    class function GetFileList(const APidl: PItemIdList): IEnumIdList;
    class function GetThumbnailProvider(const APidl: PItemIdList): IThumbnailProvider;
    class function GetExtractImage(APidl, AParentPidl: PItemIdList): IExtractImage;
  end;

implementation

class procedure TShlExt.Initialize;
begin
  OleCheck(SHGetDesktopFolder(DesktopFolder));
  OleCheck(ShGetMalloc(Malloc));
{$REGION 'Debug'}
{$IFDEF DEBUG}
  Assert(DesktopFolder <> nil, 'DesktopFolder not nil');
  Assert(Malloc <> nil, 'Malloc not nil');
{$ENDIF}
{$ENDREGION}
end;

class procedure TShlExt.FreePidl(out APidl: PItemIdList);
begin
{$REGION 'Debug'}
{$IFDEF DEBUG}
  Assert(Malloc <> nil, 'Malloc not nil');
{$ENDIF}
{$ENDREGION}
  Malloc.Free(APidl);
  APidl := nil;
end;

class function TShlExt.GetExtractImage(APidl, AParentPidl: PItemIdList): IExtractImage;
var
  RelPidl: PItemIdList;
  ShellFolder: IShellFolder;
begin
{$REGION 'Debug'}
{$IFDEF DEBUG}
  Assert(APidl <> nil, 'APidl not nil');
  Assert(AParentPidl <> nil, 'APidl not nil');
{$ENDIF}
{$ENDREGION}
  RelPidl := ILFindLastId(APidl);
  ShellFolder := GetShellFolder(AParentPidl);
  if ShellFolder <> nil then
    ShellFolder.GetUIObjectOf(0, 1, RelPidl, IExtractImage, nil, Result);
end;

class function TShlExt.GetFileInfo(const APidl: PItemIdList): TShFileInfo;
var
  Flags: DWord;
begin
{$REGION 'Debug'}
{$IFDEF DEBUG}
  Assert(APidl <> nil, 'APidl not nil');
{$ENDIF}
{$ENDREGION}
  FillChar(Result, SizeOf(Result), #0);
  Flags := SHGFI_DISPLAYNAME or SHGFI_PIDL or SHGFI_SMALLICON or SHGFI_SYSICONINDEX;
  SHGetFileInfo(PChar(APidl), 0, Result, SizeOf(Result), Flags);
end;

class function TShlExt.GetFileList(const APidl: PItemIdList): IEnumIdList;
var
  Flags: Cardinal;
begin
{$REGION 'Debug'}
{$IFDEF DEBUG}
  Assert(APidl <> nil, 'APidl not nil');
{$ENDIF}
{$ENDREGION}
  // Получить интерфейс перечислителя Pidl текушей папки
  Flags := SHCONTF_NONFOLDERS;
  OleCheck(GetShellFolder(APidl).EnumObjects(0, Flags, Result));
end;

class function TShlExt.GetFolderList(const APidl: PItemIdList): IEnumIdList;
var
  Flags: Cardinal;
begin
{$REGION 'Debug'}
{$IFDEF DEBUG}
  Assert(APidl <> nil, 'APidl not nil');
{$ENDIF}
{$ENDREGION}
  // Получить интерфейс перечислителя Pidl текушей папки
  Flags := SHCONTF_FOLDERS;
  OleCheck(GetShellFolder(APidl).EnumObjects(0, Flags, Result));
end;

class function TShlExt.GetRootPidl(const ACsidl: DWord): PItemIdList;
begin
  OleCheck(SHGetSpecialFolderLocation(0, ACsidl, Result));
{$REGION 'Debug'}
{$IFDEF DEBUG}
  Assert(Result <> nil, 'Result not nil');
{$ENDIF}
{$ENDREGION}
end;

class function TShlExt.GetShellFolder(const APidl: PItemIdList): IShellFolder;
begin
{$REGION 'Debug'}
{$IFDEF DEBUG}
  Assert(DesktopFolder <> nil, 'DesktopFolder not nil');
  Assert(APidl <> nil, 'APidl not nil');
{$ENDIF}
{$ENDREGION}
  // Получение интерфейса текущей папки
  OleCheck(DesktopFolder.BindToObject(APidl, nil, IShellFolder, Result));
end;

class function TShlExt.GetThumbnailProvider(const APidl: PItemIdList): IThumbnailProvider;
var
  ShellItem: IShellItem;
begin
  Result := nil;
  // Получить интерфейс IShellItem
  if Succeeded(SHCreateItemFromIDList(APidl, IShellItem, ShellItem)) then
    ShellItem.BindToHandler(nil, BHID_ThumbnailHandler, IID_IThumbnailProvider, Result);

end;

class function TShlExt.HasFolder(const APidl, AParentPidl: PItemIdList): Boolean;
var
  Flags       : DWord;
  RelPidl: PItemIdList;
begin
  Flags  := SFGAO_HASSUBFOLDER;
{$REGION 'Debug'}
{$IFDEF DEBUG}
  Assert(DesktopFolder <> nil, 'DesktopFolder not nil');
  Assert(APidl <> nil, 'APidl not nil');
{$ENDIF}
{$ENDREGION}
  // Не требуется освобождения указателя!
  RelPidl := ILFindLastId(APidl);
{$REGION 'Debug'}
{$IFDEF DEBUG}
  Assert(RelPidl <> nil, 'RelPidl not nil');
{$ENDIF}
{$ENDREGION}
  // Получить аттрибуты папки
  if AParentPidl = nil then
    OleCheck(DesktopFolder.GetAttributesOf(1, RelPidl, Flags))
  else
    OleCheck(GetShellFolder(AParentPidl).GetAttributesOf(1, RelPidl, Flags));
  Result := (Flags and SFGAO_HASSUBFOLDER) = SFGAO_HASSUBFOLDER;
end;

end.

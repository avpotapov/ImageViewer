unit ImageViewer.FolderNode;

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
  System.Classes,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.ComCtrls;

type
  TFolderNode = class(TTreeNode)
  private
    FPidl: PItemIdList;
  public
    destructor Destroy; override;
  public
    // PItemIdList текущей папки
    property Pidl: PItemIdList read FPidl write FPidl;
  end;

implementation


uses
  ImageViewer.ShlExt;



destructor TFolderNode.Destroy;
begin
  TShlExt.FreePidl(FPidl);
  inherited;
end;



end.

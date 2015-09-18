unit ImageViewer.FolderTreeHelper;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.ShellApi,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.ComCtrls,
  Winapi.ShlObj;

type

  TFolderNode = class(TTreeNode)
  private
    FPidl: PItemIdList;
  private
    procedure SetPidl(const APidl: PItemIdList);
  public
    destructor Destroy; override;
  public
    function GetParentPidl: PItemIdList;
    // PItemIdList ������� �����
    property Pidl: PItemIdList read FPidl write SetPidl;
  end;

  TFolderItemsHelper = class Helper for TTreeNodes
  private
    function AddFolderNode(const AParentNode: TTreeNode = nil; const APidl: PItemIdList = nil): TFolderNode;
  public
    function AddRootNode: TFolderNode;
    procedure AddFolders(const ANode: TTreeNode);
  end;

implementation

uses
  ImageViewer.ShellAdaptor;

procedure TFolderNode.SetPidl(const APidl: PItemIdList);
var
  FolderInfo: TShFileInfo;
begin
  if FPidl = APidl then
    Exit;

  FPidl := APidl;

  // ������� ���������� � �����, ����� ��� ����� �� Pidl
  FolderInfo := TTShellAdaptor.GetFileInfo(FPidl);

  // ������ �����
  Text := FolderInfo.szDisplayName;
  // ������ ��������� ������
  ImageIndex    := FolderInfo.iIcon;
  SelectedIndex := FolderInfo.iIcon;
  // ������ ��������� �����
  HasChildren := TTShellAdaptor.HasFolder(FPidl, GetParentPidl);
end;

function TFolderNode.GetParentPidl: PItemIdList;
begin
  Result := nil;
  if Parent is TFolderNode then
    Result := TFolderNode(Parent).Pidl;
end;

destructor TFolderNode.Destroy;
begin
  // ������� Pidl
  TTShellAdaptor.FreePidl(FPidl);
  inherited;
end;

function TFolderItemsHelper.AddFolderNode(const AParentNode: TTreeNode; const APidl: PItemIdList): TFolderNode;
begin
  Result := TFolderNode(AddChild(AParentNode, ''));

  if APidl = nil then
    // ������� PIDL ��� �������� ����� (�� ��������� '��� ���������')
    Result.Pidl := TTShellAdaptor.GetRootPidl
  else
    Result.Pidl := APidl;
end;

procedure TFolderItemsHelper.AddFolders(const ANode: TTreeNode);
var
  FolderList      : IEnumIdList;
  AbsPidl, RelPidl: PItemIdList;
  Fetched         : Cardinal;
begin
  if ANode = nil then
    Exit;

  // �������� ������ ��������� �����
  FolderList := TTShellAdaptor.GetFolderList(TFolderNode(ANode).Pidl);

  // ������� ���� ��������� �����
  while FolderList.Next(1, RelPidl, Fetched) = NOERROR do
    try
      // �������� ����� �����
      AbsPidl := IlCombine(TFolderNode(ANode).Pidl, RelPidl);
      AddFolderNode(ANode, AbsPidl);
    finally
      TTShellAdaptor.FreePidl(RelPidl);
    end;
end;

function TFolderItemsHelper.AddRootNode: TFolderNode;
begin
  Result := AddFolderNode;
end;

end.

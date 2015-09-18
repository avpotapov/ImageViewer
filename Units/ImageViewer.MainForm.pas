unit ImageViewer.MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellApi, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.ComCtrls, System.Win.ComObj, Winapi.ShlObj,
  System.ImageList, Vcl.ImgList, CommCtrl,
  Vcl.StdCtrls, ImageViewer.Thumbnail, ImageViewer.ThumbnailCreator,
  Vcl.Menus;

type
  TMainForm = class(TForm)

    FolderTree: TTreeView;
    ThumbnailView: TListView;
    Splitter: TSplitter;
    FolderIconList: TImageList;
    ThumbnailPanel: TPanel;
    ImageList: TImageList;
    SizerPanel: TPanel;
    SizerBox: TComboBox;
    MainMenu: TMainMenu;
    ExitMenu: TMenuItem;
    AboutMenu: TMenuItem;
    procedure FolderTreeCreateNodeClass(Sender: TCustomTreeView; var NodeClass: TTreeNodeClass);
    procedure FormCreate(Sender: TObject);
    procedure FolderTreeExpanding(Sender: TObject; Node: TTreeNode; var AllowExpansion: Boolean);
    procedure FolderTreeCollapsed(Sender: TObject; Node: TTreeNode);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ThumbnailViewAdvancedCustomDrawItem(Sender: TCustomListView; Item: TListItem; State: TCustomDrawState;
      Stage: TCustomDrawStage; var DefaultDraw: Boolean);
    procedure ExitMenuClick(Sender: TObject);
    procedure AboutMenuClick(Sender: TObject);
  private
    FThumbnailCreator: TThumbnailCreator;
    FThumbnailCache  : TList<IThumbnail>;
    procedure AddThumbNail(AThumbFile: IThumbnail);
    procedure LoadFiles(Sender: TObject);
    procedure ChangeThumbnailCache(Sender: TObject; const Item: IThumbnail; Action: TCollectionNotification);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  ImageViewer.ShellAdaptor,
  ImageViewer.FolderTreeHelper,
  ImageViewer.About;

const
  ThumbnailSizes: array [0 .. 6] of Integer = (16, 32, 64, 128, 256, 512, 1024);

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FreeAndNil(FThumbnailCreator);
  FreeAndNil(FThumbnailCache);
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  FileInfo: TShFileInfo;
begin
  // ������������� COM-�������� shell.dll
  TTShellAdaptor.Initialize;
  // ��������� ��������� ������ � FolderIconList
  FolderIconList.Handle := SHGetFileInfo('.txt', FILE_ATTRIBUTE_NORMAL, FileInfo, SizeOf(FileInfo),
    SHGFI_SYSICONINDEX or SHGFI_SMALLICON or SHGFI_USEFILEATTRIBUTES);
  // �������� ��������� ���� �������� �������
  FolderTree.Items.AddRootNode();
  // �������� ������ ��� ������ �����
  FolderTree.OnClick := LoadFiles;

  // ��������� ��������
  FThumbnailCreator                    := TThumbnailCreator.Create;
  FThumbnailCreator.OnThumbnailExtract := AddThumbNail;

  // ������������ ������ ��� ��������� ������� ��������
  SizerBox.ItemIndex := 3;
  SizerBox.OnChange  := LoadFiles;

  // ��� �������� ������� �����
  FThumbnailCache          := TList<IThumbnail>.Create;
  FThumbnailCache.OnNotify := ChangeThumbnailCache;

end;

procedure TMainForm.LoadFiles(Sender: TObject);
begin
  if Assigned(FolderTree.Selected) and Assigned(FThumbnailCreator) then
  begin
    // ������ ��������
    ImageList.SetSize(ThumbnailSizes[SizerBox.ItemIndex], ThumbnailSizes[SizerBox.ItemIndex]);
    FThumbnailCreator.Size := ThumbnailSizes[SizerBox.ItemIndex];

    // �������� ������ � ���������� ��������
    FThumbnailCreator.AddFiles(TTShellAdaptor.GetFileList(TFolderNode(FolderTree.Selected).Pidl),
      TFolderNode(FolderTree.Selected).Pidl);
  end;
  // �� �������� �������� ���
  FThumbnailCache.Clear;
end;

procedure TMainForm.FolderTreeCreateNodeClass(Sender: TCustomTreeView; var NodeClass: TTreeNodeClass);
begin
  // �������������� ����� ���� TTreeView
  NodeClass := TFolderNode;
end;

procedure TMainForm.FolderTreeExpanding(Sender: TObject; Node: TTreeNode; var AllowExpansion: Boolean);
begin
  // �������� ��������� �����
  Node.Owner.AddFolders(Node);
end;

procedure TMainForm.ChangeThumbnailCache(Sender: TObject; const Item: IThumbnail; Action: TCollectionNotification);
begin
  // ���������� �������� �� ������ ������������� ���������� � ����
  ThumbnailView.Items.Count := TList<IThumbnail>(Sender).Count;
end;

procedure TMainForm.ExitMenuClick(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.FolderTreeCollapsed(Sender: TObject; Node: TTreeNode);
begin
  // ������� ��������� �����
  Node.DeleteChildren;
  Node.HasChildren := True;
end;

procedure TMainForm.AboutMenuClick(Sender: TObject);
var
  AboutBox: TAboutBox;
begin
  AboutBox := TAboutBox.Create(Self);
  try
    AboutBox.ShowModal;
  finally
    AboutBox.Release;
  end;
end;

procedure TMainForm.AddThumbNail(AThumbFile: IThumbnail);
begin
  // �������� ��������� � ���
  FThumbnailCache.Add(AThumbFile);
end;

procedure TMainForm.ThumbnailViewAdvancedCustomDrawItem(Sender: TCustomListView; Item: TListItem;
  State: TCustomDrawState; Stage: TCustomDrawStage; var DefaultDraw: Boolean);
var
  Text    : String;
  IconRect: TRect;
  TextRect: TRect;
  Bitmap  : TBitmap;
begin
  Sender.Canvas.Font.Size := 8;
  TextRect                := Item.DisplayRect(TDisplayCode.drLabel);
  Text                    := TTShellAdaptor.GetFileInfo(FThumbnailCache[Item.Index].Pidl).szDisplayName;
  Sender.Canvas.TextWidth(Text);
  // ������� �������� ����� �� ������
  TextRect.Left := TextRect.Left + ((TextRect.Width - Sender.Canvas.TextWidth(Text)) shr 1);
  Sender.Canvas.TextRect(TextRect, Text);

  // ������ ����� ��� ������
  IconRect := Item.DisplayRect(TDisplayCode.drIcon);
  Bitmap   := FThumbnailCache[Item.Index].Bitmap;

  // ����� ��� ���������
  Sender.Canvas.Pen.Color := clMedGray;
  Sender.Canvas.RoundRect(IconRect, IconRect.Height shr 2, IconRect.Width shr 2);

  // ��������� ��������� �� ������
  Sender.Canvas.Draw(IconRect.Left + ((IconRect.Width - Bitmap.Width) shr 1),
    IconRect.Top + ((IconRect.Height - Bitmap.Height) shr 1), FThumbnailCache[Item.Index].Bitmap);
end;

end.

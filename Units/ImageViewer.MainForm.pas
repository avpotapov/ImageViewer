unit ImageViewer.MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellApi, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.ComCtrls, System.Win.ComObj, Winapi.ShlObj,
  System.ImageList, Vcl.ImgList, CommCtrl, ImageViewer.ThumbExtractor,
  Vcl.StdCtrls;

const
  ThumbnailSizes: array [0 .. 5] of Integer = (16, 32, 64, 128, 256, 512);

type
  TMainForm = class(TForm)
    FolderTree: TTreeView;
    ThumbnailList: TListView;
    Splitter: TSplitter;
    FolderIconList: TImageList;
    ThumbnailSizer: TTrackBar;
    ThumbnailPanel: TPanel;
    ImageList: TImageList;
    procedure FolderTreeCreateNodeClass(Sender: TCustomTreeView; var NodeClass: TTreeNodeClass);
    procedure FormCreate(Sender: TObject);
    procedure FolderTreeExpanding(Sender: TObject; Node: TTreeNode; var AllowExpansion: Boolean);
    procedure FolderTreeCollapsed(Sender: TObject; Node: TTreeNode);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FolderTreeChange(Sender: TObject; Node: TTreeNode);
    procedure ThumbnailListAdvancedCustomDrawItem(Sender: TCustomListView; Item: TListItem; State: TCustomDrawState;
      Stage: TCustomDrawStage; var DefaultDraw: Boolean);
    procedure ThumbnailSizerChange(Sender: TObject);
  private
    FThumbExtractor: TThumbExtractor;
    FThumbFileList : TList<IThumbFile>;
    procedure AddThumbNail(AThumbFile: IThumbFile);
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  ImageViewer.ShlExt,
  ImageViewer.FolderTreeHelper,
  ImageViewer.ThumbnailListHelper;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FreeAndNil(FThumbExtractor);
  FreeAndNil(FThumbFileList);
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  FileInfo: TShFileInfo;
begin
  // Инициализация COM-объектов shell.dll
  TShlExt.Initialize;
  // Загрузить системные иконки в FolderIconList
  FolderIconList.Handle := SHGetFileInfo('.txt', FILE_ATTRIBUTE_NORMAL, FileInfo, SizeOf(FileInfo),
    SHGFI_SYSICONINDEX or SHGFI_SMALLICON or SHGFI_USEFILEATTRIBUTES);
  // Создание корневого узла файловой системы
  FolderTree.Items.AddRootNode();
  //
  FThumbExtractor                := TThumbExtractor.Create;
  FThumbExtractor.OnThumbExtract := AddThumbNail;
  FThumbExtractor.Size           := ThumbnailSizes[ThumbnailSizer.Position];
  FThumbFileList                 := TList<IThumbFile>.Create;
  ImageList.SetSize(ThumbnailSizes[ThumbnailSizer.Position], ThumbnailSizes[ThumbnailSizer.Position]);
end;

procedure TMainForm.ThumbnailListAdvancedCustomDrawItem(Sender: TCustomListView; Item: TListItem;
  State: TCustomDrawState; Stage: TCustomDrawStage; var DefaultDraw: Boolean);
var
  Text    : String;
  IconRect: TRect;
  TextRect: TRect;
begin
  Sender.Canvas.Font.Size := 10;
  TextRect                := Item.DisplayRect(TDisplayCode.drLabel);
  Text                    := TShlExt.GetFileInfo(FThumbFileList[Item.Index].Pidl).szDisplayName;
  Sender.Canvas.TextRect(TextRect, Text);

  IconRect := Item.DisplayRect(TDisplayCode.drIcon);
  Sender.Canvas.Draw(IconRect.Left, IconRect.Top, FThumbFileList[Item.Index].Bitmap);

end;

procedure TMainForm.ThumbnailSizerChange(Sender: TObject);
begin
  FThumbExtractor.Stop;
  ThumbnailList.Items.Clear;
    ImageList.SetSize(ThumbnailSizes[ThumbnailSizer.Position], ThumbnailSizes[ThumbnailSizer.Position]);
  FThumbFileList.Clear;
  FThumbExtractor.Size           := ThumbnailSizes[ThumbnailSizer.Position];
  // Получить миниатюры файлов
  if Assigned(FolderTree.Selected) and Assigned(FThumbExtractor) then
    FThumbExtractor.AddFiles(TShlExt.GetFileList(TFolderNode(FolderTree.Selected).Pidl), TFolderNode(FolderTree.Selected).Pidl);
end;

procedure TMainForm.FolderTreeCreateNodeClass(Sender: TCustomTreeView; var NodeClass: TTreeNodeClass);
begin
  // Переопределить класс узла TTreeView
  NodeClass := TFolderNode;
end;

procedure TMainForm.FolderTreeExpanding(Sender: TObject; Node: TTreeNode; var AllowExpansion: Boolean);
begin
  // Добавить вложенные папки
  Node.Owner.AddFolders(Node);
end;

procedure TMainForm.FolderTreeChange(Sender: TObject; Node: TTreeNode);
begin
  FThumbExtractor.Stop;
  ThumbnailList.Items.Clear;
  FThumbFileList.Clear;

  // Получить миниатюры файлов
  if Assigned(Node) and Assigned(FThumbExtractor) then
    FThumbExtractor.AddFiles(TShlExt.GetFileList(TFolderNode(Node).Pidl), TFolderNode(Node).Pidl);

end;

procedure TMainForm.FolderTreeCollapsed(Sender: TObject; Node: TTreeNode);
begin
  // Удалить вложенные папки
  Node.DeleteChildren;
  Node.HasChildren := True;
end;

procedure TMainForm.AddThumbNail(AThumbFile: IThumbFile);
begin
  FThumbFileList.Add(AThumbFile);
  ThumbnailList.Items.Count := ThumbnailList.Items.Count + 1;
end;

end.

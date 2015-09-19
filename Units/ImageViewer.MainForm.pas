unit ImageViewer.MainForm;

interface

uses
  Winapi.Windows,
  Winapi.ShellApi,

  System.SysUtils,
  System.Variants,
  System.Classes,
  System.ImageList,
  System.Generics.Collections,

  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.ComCtrls,
  Vcl.ImgList,
  Vcl.StdCtrls,
  Vcl.Menus,

  ImageViewer.Thumbnail,
  ImageViewer.ThumbnailCreator;

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
  ImageViewer.ThumbnailViewHelper,
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
  // Инициализация COM-объектов shell.dll
  TTShellAdaptor.Initialize;

  // Загрузить системные иконки в FolderIconList
  FolderIconList.Handle := SHGetFileInfo('.txt', FILE_ATTRIBUTE_NORMAL, FileInfo, SizeOf(FileInfo),
    SHGFI_SYSICONINDEX or SHGFI_SMALLICON or SHGFI_USEFILEATTRIBUTES);
  // Создание корневого узла файловой системы
  FolderTree.Items.AddRootNode();
  // Загрузка файлов при выборе папки
  FolderTree.OnClick := LoadFiles;

  // Создатель миниатюр
  FThumbnailCreator                    := TThumbnailCreator.Create;
  FThumbnailCreator.OnThumbnailExtract := AddThumbNail;

  // Перезегрузка файлов при изменении размера миниатюр
  SizerBox.ItemIndex := 3;
  SizerBox.OnChange  := LoadFiles;

  // Кэш миниатюр текущей папки
  FThumbnailCache          := TList<IThumbnail>.Create;
  // Связываем изменение количества миниатюр в кеше с их выводом в ThumbnailView
  FThumbnailCache.OnNotify := ChangeThumbnailCache;

end;

procedure TMainForm.LoadFiles(Sender: TObject);
begin
  if Assigned(FolderTree.Selected) and Assigned(FThumbnailCreator) then
  begin
    // Размер миниатюр
    ImageList.SetSize(ThumbnailSizes[SizerBox.ItemIndex], ThumbnailSizes[SizerBox.ItemIndex]);
    FThumbnailCreator.Size := ThumbnailSizes[SizerBox.ItemIndex];

    // Загрузка файлов в экстрактор миниатюр
    FThumbnailCreator.AddFiles(TTShellAdaptor.GetFileList(TFolderNode(FolderTree.Selected).Pidl),
      TFolderNode(FolderTree.Selected).Pidl);
  end;
  // Не забываем очистить кеш
  FThumbnailCache.Clear;
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

procedure TMainForm.ChangeThumbnailCache(Sender: TObject; const Item: IThumbnail; Action: TCollectionNotification);
begin
  // Колечество миниатюр на экране соответствует количеству в кеше
  ThumbnailView.Items.Count := TList<IThumbnail>(Sender).Count;
end;

procedure TMainForm.FolderTreeCollapsed(Sender: TObject; Node: TTreeNode);
begin
  // Удалить вложенные папки
  Node.DeleteChildren;
  Node.HasChildren := True;
end;

procedure TMainForm.AddThumbNail(AThumbFile: IThumbnail);
begin
  // Добавить миниатюру в кеш
  FThumbnailCache.Add(AThumbFile);
end;

procedure TMainForm.ThumbnailViewAdvancedCustomDrawItem(Sender: TCustomListView; Item: TListItem;
  State: TCustomDrawState; Stage: TCustomDrawStage; var DefaultDraw: Boolean);
begin
  // Название файла по центру
  Sender.DrawText(Item.DisplayRect(TDisplayCode.drLabel),
    TTShellAdaptor.GetFileInfo(FThumbnailCache[Item.Index].Pidl).szDisplayName);

  // Рамка для миниатюры
   Sender.DrawFrame(Item.DisplayRect(TDisplayCode.drIcon), clMedGray);

  // Разместим миниатюру по центру
  Sender.DrawThumbnail(Item.DisplayRect(TDisplayCode.drIcon),
    FThumbnailCache[Item.Index].Bitmap);
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

procedure TMainForm.ExitMenuClick(Sender: TObject);
begin
  Close;
end;

end.

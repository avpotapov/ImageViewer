unit ImageViewer.ThumbnailCreator;

interface

uses
  Winapi.Windows,
  Winapi.ShellApi,
  Winapi.ShlObj,
  Winapi.ActiveX,

  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.Generics.Collections,

  Vcl.Graphics,

  ImageViewer.ShellAdaptor,
  ImageViewer.Thumbnail;

type
  TThumbnailExtractEvent = procedure(Thumbnail: IThumbnail) of object;

  TThumbnailCreator = class
  const
    QUEUE_DEEP  = 100;
    POP_TIMEOUT = 100;
  private
    // Потокобезопасная очередь
    FQueue: TThreadedQueue<IThumbnail>;
    // Поток получения миниатюры
    FThread            : TThread;
    // Событие получения миниатюры
    FOnThumbnailExtract: TThumbnailExtractEvent;
    // Размер миниатюры
    FSize: Integer;
  private
    function GetSize: Integer;
    procedure SetSize(const ASize: Integer);
    procedure Start;
    procedure Stop;
    procedure ExtractThumbnail(AThumbnail: IThumbnail);
  public
    constructor Create;
    destructor Destroy; override;
  public
    procedure AddFiles(const AFiles: IEnumIdList; const AParentPidl: PItemIdList);
    property OnThumbnailExtract: TThumbnailExtractEvent read FOnThumbnailExtract write FOnThumbnailExtract;
    property Size: Integer read GetSize write SetSize;
  end;

implementation

constructor TThumbnailCreator.Create;
begin
  FQueue := TThreadedQueue<IThumbnail>.Create(QUEUE_DEEP, INFINITE, POP_TIMEOUT);
end;

destructor TThumbnailCreator.Destroy;
begin
  Stop;
  FreeAndNil(FQueue);
  inherited;
end;

procedure TThumbnailCreator.SetSize(const ASize: Integer);
begin
  InterlockedExchange(FSize, ASize);
end;

function TThumbnailCreator.GetSize: Integer;
begin
  Result := InterlockedCompareExchange(FSize, 0, 0)
end;

procedure TThumbnailCreator.Start;
var
  Thumbnail: IThumbnail;
begin
  FThread := TThread.CreateAnonymousThread(
    procedure
    begin
      Coinitialize(nil);
      try
        while not TThread.Current.CheckTerminated do
          if FQueue.PopItem(Thumbnail) = TWaitResult.wrSignaled then
            ExtractThumbnail(Thumbnail);
      finally
        CoUninitialize;
      end;
    end);
  FThread.FreeOnTerminate := False;
  FThread.Start;
end;

procedure TThumbnailCreator.Stop;
var
  Thumbnail: IThumbnail;
begin
  FreeAndNil(FThread);
  // Очистить очередь
  while (FQueue.PopItem(Thumbnail) = TWaitResult.wrSignaled) do;
{$REGION 'Debug'}
{$IFDEF DEBUG}
  Assert(FQueue.QueueSize = 0);
  Assert(FThread = nil);
{$ENDIF}
{$ENDREGION}
end;

procedure TThumbnailCreator.AddFiles(const AFiles: IEnumIdList; const AParentPidl: PItemIdList);
var
  AbsPidl, RelPidl: PItemIdList;
  Fetched         : Cardinal;
  Capacity        : Integer;
begin
  // Restart;
  Stop;
  Start;

  Capacity := QUEUE_DEEP;

  // Перебор всех вложенных папок
  while AFiles.Next(1, RelPidl, Fetched) = NOERROR do
    try
      AbsPidl := IlCombine(AParentPidl, RelPidl);

      // Динамический рост размера очереди
      if FQueue.QueueSize = Capacity then
      begin
        Capacity := Capacity + Capacity shr 1;
        FQueue.Grow(Capacity);
      end;

      FQueue.PushItem(TThumbnail.Create(AbsPidl, TBitmap.Create) as IThumbnail);

    finally
      TTShellAdaptor.FreePidl(RelPidl);
    end;


end;

procedure TThumbnailCreator.ExtractThumbnail(AThumbnail: IThumbnail);
var
  ThumbnailProvider: IThumbnailProvider;
  BmpType          : DWord;
  HBmp             : HBitmap;
begin
  ThumbnailProvider := TTShellAdaptor.GetThumbnailProvider(AThumbnail.Pidl);
  if ThumbnailProvider <> nil then
  begin

    ThumbnailProvider.GetThumbnail(Size, HBmp, BmpType);
    AThumbnail.Bitmap.Handle := HBmp;

    if Assigned(FOnThumbnailExtract) then
      TThread.Queue(TThread.CurrentThread,
        procedure
        begin
          FOnThumbnailExtract(AThumbnail);
        end);

  end;
end;

end.

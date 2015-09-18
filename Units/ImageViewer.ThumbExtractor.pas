unit ImageViewer.ThumbExtractor;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.ShellApi,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Winapi.ShlObj,
  System.Generics.Collections,
  System.SyncObjs,
  ImageViewer.ShlExt,
  Vcl.Graphics,
  Winapi.ActiveX;

const
  MAX_THREADS = 5;
  QUEUE_DEEP  = 100;

type

  TThumbFile = class;
  IThumbFile = interface;
  TThumbExtractEvent = procedure(ThumbFile: IThumbFile) of object;

  TThumbExtractor = class
  private
    // Потокобезопасная очередь из файлов и их миниатюр
    FFileQueue: TThreadedQueue<IThumbFile>;
    // Примитив синхронизации
    FCountdownEvent: TCountdownEvent;
    // Флаг прерывания выполнения потоков
    FIsRunning: Integer;
    // Пул потоков
    FThreads: array [0 .. MAX_THREADS - 1] of TThread;
  private
    FSize          : Integer;
    FOnThumbExtract: TThumbExtractEvent;
    // Очистить очередь
    procedure FileQueueClear;
    // Получить миниатюру
    procedure ExtractThrumbnail(ThrumbFile: IThumbFile);
  public
    constructor Create;
    destructor Destroy; override;
  public
    procedure Start;
    procedure Stop;
    procedure AddFiles(const AFiles: IEnumIdList; const AParentPidl: PItemIdList);
    property Size: Integer read FSize write FSize;
    property OnThumbExtract: TThumbExtractEvent read FOnThumbExtract write FOnThumbExtract;
  end;

  IThumbFile = interface
  ['{C8F45F3A-D736-4ECF-8A7F-0DC5C89E7010}']
    function GetBitmap: TBitmap;
    function GetPidl: PItemIdList;
    procedure SetPidl(const Value: PItemIdList);
    procedure SetBitmap(const Value: TBitmap);
    property Pidl: PItemIdList read GetPidl write SetPidl;
    property Bitmap: TBitmap read GetBitmap write SetBitmap;

  end;

  TThumbFile = class(TInterfacedObject, IThumbFile)
  private
    FPidl  : PItemIdList;
    FBitmap: TBitmap;
  public
    constructor Create(const APidl: PItemIdList; const ABitmap: TBitmap); reintroduce;
    destructor Destroy; override;
  public
    function GetPidl: PItemIdList;
    procedure SetPidl(const Value: PItemIdList);
    function GetBitmap: TBitmap;
    procedure SetBitmap(const Value: TBitmap);
    property Pidl  : PItemIdList read GetPidl write SetPidl;
    property Bitmap: TBitmap read GetBitmap write SetBitmap;
  end;

implementation

{ TThumbExtractor }

procedure TThumbExtractor.FileQueueClear;
var
  ThumbFile: IThumbFile;
begin
  while FFileQueue.QueueSize > 0 do
    FFileQueue.PopItem(ThumbFile);
end;

procedure TThumbExtractor.AddFiles(const AFiles: IEnumIdList; const AParentPidl: PItemIdList);
var
  AbsPidl, RelPidl: PItemIdList;
  Fetched         : Cardinal;
  Capacity        : Integer;
begin
  Start;
  Capacity := QUEUE_DEEP;
  // Перебор всех вложенных папок
  while AFiles.Next(1, RelPidl, Fetched) = NOERROR do
    try
      // Добавить новую папку
      AbsPidl := IlCombine(AParentPidl, RelPidl);
      if FFileQueue.QueueSize = Capacity then
      begin
        Capacity := Capacity + Capacity shr 1;
        FFileQueue.Grow(Capacity);
      end;
      FFileQueue.PushItem(TThumbFile.Create(AbsPidl, TBitmap.Create) as IThumbFile);

    finally
      TShlExt.FreePidl(RelPidl);
    end;
end;

constructor TThumbExtractor.Create;
begin
  inherited;
  // Потокобезопасная очередь
  FFileQueue := TThreadedQueue<IThumbFile>.Create(QUEUE_DEEP, INFINITE, 50);
end;

destructor TThumbExtractor.Destroy;
begin
  // Дождаться закрытия пула потоков
  Stop;
  FreeAndNil(FFileQueue);
  inherited;
end;

procedure TThumbExtractor.Start;
var
  I: Integer;
begin
  if Assigned(FCountdownEvent) then
    Stop;

  // Инициализироватьсчетчик
  FCountdownEvent := TCountdownEvent.Create;
  // Флаг остановки
  InterlockedExchange(FIsRunning, 1);

  for I := 0 to MAX_THREADS - 1 do
  begin
    FThreads[I] := TThread.CreateAnonymousThread(
      procedure
      var
        ThumbFile: IThumbFile;
      begin
        CoInitialize(nil);
        try
          FCountdownEvent.AddCount;
          try
            while (InterlockedCompareExchange(FIsRunning, 0, 0) = 1) do
            begin
              if FFileQueue.PopItem(ThumbFile) = TWaitResult.wrSignaled then
              begin
                ExtractThrumbnail(ThumbFile);
              end;
              Sleep(100);
            end;
          finally
            FCountdownEvent.Signal;
          end;
        finally
          CoUninitialize;
        end;
      end);
    FThreads[I].Start;
  end;

end;

procedure TThumbExtractor.Stop;
begin
  if Assigned(FCountdownEvent) then
  begin
    // Флаг остановки
    InterlockedExchange(FIsRunning, 0);
    // Дождаться завершения потоков
    FCountdownEvent.Signal;
    FCountdownEvent.WaitFor;
    FreeAndNil(FCountdownEvent);
  end;
  FileQueueClear;

end;

procedure TThumbExtractor.ExtractThrumbnail(ThrumbFile: IThumbFile);
var
  ThumbnailProvider: IThumbnailProvider;
  BmpType          : DWord;
  HBmp             : HBitmap;
begin
  ThumbnailProvider := TShlExt.GetThumbnailProvider(ThrumbFile.Pidl);
  if ThumbnailProvider <> nil then
  begin
    ThrumbFile.Bitmap.SetSize(Size, Size);
    ThumbnailProvider.GetThumbnail(Size, HBmp, BmpType);
    ThrumbFile.Bitmap.Handle := HBmp;
    if Assigned(FOnThumbExtract) then
      TThread.Queue(TThread.CurrentThread,
        procedure
        begin
          FOnThumbExtract(ThrumbFile);
        end);

  end;
end;

{ TThumbFile }

constructor TThumbFile.Create(const APidl: PitemIdList;
  const ABitmap: TBitmap);
begin

  FPidl := APidl;
  FBitmap := ABitmap;
end;

destructor TThumbFile.Destroy;
begin
  FreeAndNil(FBitmap);
  inherited;
end;

function TThumbFile.GetBitmap: TBitmap;
begin
  Result := FBitmap;
end;

function TThumbFile.GetPidl: PItemIdList;
begin
  Result := FPIdl;
end;

procedure TThumbFile.SetBitmap(const Value: TBitmap);
begin
  FBitmap := Value;
end;

procedure TThumbFile.SetPidl(const Value: PItemIdList);
begin
  FPidl := Value;
end;

end.

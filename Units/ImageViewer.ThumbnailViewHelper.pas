unit ImageViewer.ThumbnailViewHelper;

interface

uses
  Winapi.Windows,
  Vcl.Graphics,
  Vcl.ComCtrls;

type
  TThumbnailViewHelper = class Helper for TCustomListView
  public
    procedure DrawText(ATextRect: TRect; AText: string);
    procedure DrawThumbnail(AIconRect: TRect; ABitmap: TBitmap);
    procedure DrawFrame(AIconRect: TRect; const AColor: TColor);
  end;

implementation

procedure TThumbnailViewHelper.DrawFrame(AIconRect: TRect;
  const AColor: TColor);
begin
  Canvas.Pen.Color := AColor;
  Canvas.RoundRect(AIconRect, AIconRect.Height shr 2, AIconRect.Width shr 2);
end;

procedure TThumbnailViewHelper.DrawText(ATextRect: TRect; AText: string);
var
  Offset: Integer;
begin
  Canvas.Font.Size := 8;
  // Коррекция левой границы вывода с учетом размера текста
  Offset := (ATextRect.Width - Canvas.TextWidth(AText)) shr 1;
  ATextRect.Left := ATextRect.Left + Offset;
  // Выводим название файла по центру
  Canvas.TextRect(ATextRect, AText);
end;

procedure TThumbnailViewHelper.DrawThumbnail(AIconRect: TRect; ABitmap: TBitmap);
var
  LeftOffset, TopOffset: Integer;
begin
  // Разместим миниатюру по центру
  LeftOffset := (AIconRect.Width - ABitmap.Width) shr 1;
  TopOffset :=  (AIconRect.Height - ABitmap.Height) shr 1;
  Canvas.Draw(AIconRect.Left + LeftOffset, AIconRect.Top + TopOffset, ABitmap);
end;

end.

program ImageViewer;

uses
  Vcl.Forms,
  ImageViewer.MainForm in 'Units\ImageViewer.MainForm.pas' {MainForm},
  ImageViewer.ShlExt in 'Units\ImageViewer.ShlExt.pas',
  ImageViewer.FolderTreeHelper in 'Units\ImageViewer.FolderTreeHelper.pas',
  ImageViewer.ThumbnailListHelper in 'Units\ImageViewer.ThumbnailListHelper.pas',
  ImageViewer.ThumbExtractor in 'Units\ImageViewer.ThumbExtractor.pas';

{$R *.res}

begin
  Application.Initialize;
   ReportMemoryLeaksOnShutdown := True;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.

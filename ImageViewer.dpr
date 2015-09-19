program ImageViewer;

uses
  Vcl.Forms,
  ImageViewer.MainForm in 'Units\ImageViewer.MainForm.pas' {MainForm},
  ImageViewer.About in 'Units\ImageViewer.About.pas',
  ImageViewer.ShellAdaptor in 'Units\ImageViewer.ShellAdaptor.pas',
  ImageViewer.FolderTreeHelper in 'Units\ImageViewer.FolderTreeHelper.pas',
  ImageViewer.ThumbnailCreator in 'Units\ImageViewer.ThumbnailCreator.pas',
  ImageViewer.Thumbnail in 'Units\ImageViewer.Thumbnail.pas',
  ImageViewer.ThumbnailViewHelper in 'Units\ImageViewer.ThumbnailViewHelper.pas';

{$R *.res}

begin
  Application.Initialize;
{$REGION 'Debug'}
{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
{$ENDIF}
{$ENDREGION}
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.

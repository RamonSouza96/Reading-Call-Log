program pCallLOG;

uses
  System.StartUpCopy,
  FMX.Forms,
  uMain in 'uMain.pas' {FrmMain},
  Android.SystemBars in 'Android.SystemBars.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.

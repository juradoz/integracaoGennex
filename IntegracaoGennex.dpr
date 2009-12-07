program IntegracaoGennex;

uses
  Forms,
  uMain in 'uMain.pas' {frmIntegracaoGennex},
  uClienteGennex in 'uClienteGennex.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmIntegracaoGennex, frmIntegracaoGennex);
  Application.Run;
end.

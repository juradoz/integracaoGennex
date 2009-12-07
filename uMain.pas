unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, uClienteGennex, StdCtrls;

type
  TfrmIntegracaoGennex = class(TForm)
    edtUsuario: TEdit;
    edtSenha: TEdit;
    edtGrupo: TEdit;
    btnLogar: TButton;
    btnDeslogar: TButton;
    btnPausar: TButton;
    btnDespausar: TButton;
    btnFinalizarClerical: TButton;
    edtTelefone: TEdit;
    btnDiscar: TButton;
    memoLog: TMemo;
    btnAbortarSaida: TButton;
    btnDesligar: TButton;
    lblDestino: TLabel;
    lblUsuario: TLabel;
    lblSenha: TLabel;
    lblGrupo: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure btnLogarClick(Sender: TObject);
    procedure btnDeslogarClick(Sender: TObject);
    procedure btnPausarClick(Sender: TObject);
    procedure btnDespausarClick(Sender: TObject);
    procedure btnFinalizarClericalClick(Sender: TObject);
    procedure btnDiscarClick(Sender: TObject);
    procedure btnAbortarSaidaClick(Sender: TObject);
    procedure btnDesligarClick(Sender: TObject);
  private
    clienteGennex : TClienteGennex;
    fIdMakeCall : Integer;
    procedure DoOnDiscarConf(const chave, servidor : AnsiString; const idMakeCall : Integer);
    procedure DoOnDadosChamada(const servidor, canal, telefone, chave : AnsiString; const idMakeCall : Integer);
    procedure DoOnFimChamada(const servidor, canal : AnsiString; const idMakeCall, codigoDesligamento : Integer; const chave : AnsiString);
    procedure DoOnDiscandoAgp(const chave : AnsiString);
    procedure DoOnFimDiscandoAgp();
  public
    { Public declarations }
  end;

var
  frmIntegracaoGennex: TfrmIntegracaoGennex;

implementation

{$R *.dfm}

procedure TfrmIntegracaoGennex.FormCreate(Sender: TObject);
begin
fIdMakeCall := 0;
clienteGennex := TClienteGennex.Create('10.10.3.6', 22000);
clienteGennex.OnDiscarConf := DoOnDiscarConf;
clienteGennex.OnDadosChamada := DoOnDadosChamada;
clienteGennex.OnFimChamada := DoOnFimChamada;
clienteGennex.OnDiscandoAgp := DoOnDiscandoAgp;
clienteGennex.OnFimDiscandoAgp := DoOnFimDiscandoAgp;
end;

procedure TfrmIntegracaoGennex.btnLogarClick(Sender: TObject);
begin
if not clienteGennex.conectado or not clienteGennex.pronto then
  begin
  memoLog.Lines.Add('Nao conectado/Pronto');
  exit;
  end;
if not clienteGennex.logar(edtUsuario.Text, edtSenha.Text, edtGrupo.Text) then
  begin
  memoLog.Lines.Add('Erro: ' + clienteGennex.getLastError);
  exit;
  end;
memoLog.Lines.Add('Logado com sucesso!');
end;

procedure TfrmIntegracaoGennex.btnDeslogarClick(Sender: TObject);
begin
if not clienteGennex.conectado or not clienteGennex.pronto then
  begin
  memoLog.Lines.Add('Nao conectado/Pronto');
  exit;
  end;
if not clienteGennex.deslogar(edtUsuario.Text, edtGrupo.Text) then
  begin
  memoLog.Lines.Add('Erro: ' + clienteGennex.getLastError);
  exit;
  end;
memoLog.Lines.Add('Deslogado com sucesso!');
end;

procedure TfrmIntegracaoGennex.btnPausarClick(Sender: TObject);
begin
if not clienteGennex.conectado or not clienteGennex.pronto then
  begin
  memoLog.Lines.Add('Nao conectado/Pronto');
  exit;
  end;
if not clienteGennex.pausar(edtUsuario.Text, edtGrupo.Text) then
  begin
  memoLog.Lines.Add('Erro: ' + clienteGennex.getLastError);
  exit;
  end;
memoLog.Lines.Add('Pausado com sucesso!');
end;

procedure TfrmIntegracaoGennex.btnDespausarClick(Sender: TObject);
begin
if not clienteGennex.conectado or not clienteGennex.pronto then
  begin
  memoLog.Lines.Add('Nao conectado/Pronto');
  exit;
  end;
if not clienteGennex.despausar(edtUsuario.Text, edtGrupo.Text) then
  begin
  memoLog.Lines.Add('Erro: ' + clienteGennex.getLastError);
  exit;
  end;
memoLog.Lines.Add('Despausado com sucesso!');
end;

procedure TfrmIntegracaoGennex.btnFinalizarClericalClick(Sender: TObject);
begin
if not clienteGennex.conectado or not clienteGennex.pronto then
  begin
  memoLog.Lines.Add('Nao conectado/Pronto');
  exit;
  end;
if not clienteGennex.finalizarClerical(edtUsuario.Text) then
  begin
  memoLog.Lines.Add('Erro: ' + clienteGennex.getLastError);
  exit;
  end;
memoLog.Lines.Add('Clerical finalizado com sucesso!');
end;

procedure TfrmIntegracaoGennex.btnDiscarClick(Sender: TObject);
var
  ddd, telefone : AnsiString;
begin
if not clienteGennex.conectado or not clienteGennex.pronto then
  begin
  memoLog.Lines.Add('Nao conectado/Pronto');
  exit;
  end;

ddd := '11';
telefone := edtTelefone.Text;
if Length(telefone) > 8 then
  begin
  while(Copy(telefone, 1, 1)='0') do
    telefone := Copy(telefone, 2, Length(telefone));
  ddd := Copy(telefone, 1, 2);
  telefone := Copy(telefone, 3, length(telefone));
  end;

if not clienteGennex.discar('90909090', ddd, telefone, '10', '0202', 'DAC', 40000, edtUsuario.Text) then
  begin
  memoLog.Lines.Add('Erro: ' + clienteGennex.getLastError);
  exit;
  end;
memoLog.Lines.Add('Discando com sucesso!');
end;

procedure TfrmIntegracaoGennex.DoOnDiscarConf(const chave, servidor: AnsiString;
  const idMakeCall: Integer);
begin
fIdMakeCall := idMakeCall;
memoLog.Lines.Add(Format('DiscarConf: chave: %s, servidor: %s, idMakeCall: %d',
  [chave, servidor, idMakecall]));
end;

procedure TfrmIntegracaoGennex.DoOnDadosChamada(const servidor, canal, telefone,
  chave: AnsiString; const idMakeCall: Integer);
begin
memoLog.Lines.Add(Format('DadosChamada: servidor: %s, canal: %s, telefone: %s, chave: %s, idMakeCall: %d',
  [ servidor, canal, telefone, chave, idMakeCall ]));
end;

procedure TfrmIntegracaoGennex.DoOnFimChamada(const servidor, canal: AnsiString;
  const idMakeCall, codigoDesligamento: Integer; const chave: AnsiString);
begin
memoLog.Lines.Add(Format('FimChamada: servidor: %s, canal: %s, idMakeCall: %d, codigoDesligamento: %d, chave: %s',
  [servidor, canal, idMakeCall, codigoDesligamento, chave]));
end;

procedure TfrmIntegracaoGennex.DoOnDiscandoAgp(const chave: AnsiString);
begin
memoLog.Lines.Add(Format('DiscandoAgp: chave: %s',
  [chave]));
end;

procedure TfrmIntegracaoGennex.DoOnFimDiscandoAgp;
begin
memoLog.Lines.Add('FimDiscandoAgp');
end;

procedure TfrmIntegracaoGennex.btnAbortarSaidaClick(Sender: TObject);
begin
if not clienteGennex.conectado or not clienteGennex.pronto then
  begin
  memoLog.Lines.Add('Nao conectado/Pronto');
  exit;
  end;
if not clienteGennex.abortarSaida(fIdMakeCall) then
  begin
  memoLog.Lines.Add('Erro: ' + clienteGennex.getLastError);
  exit;
  end;
memoLog.Lines.Add(Format('Chamada %d abortada', [fIdMakeCall] ));
end;

procedure TfrmIntegracaoGennex.btnDesligarClick(Sender: TObject);
begin
if not clienteGennex.conectado or not clienteGennex.pronto then
  begin
  memoLog.Lines.Add('Nao conectado/Pronto');
  exit;
  end;
if not clienteGennex.desligarChamada then
  begin
  memoLog.Lines.Add('Erro: ' + clienteGennex.getLastError);
  exit;
  end;
memoLog.Lines.Add('Chamada desligada');
end;

end.

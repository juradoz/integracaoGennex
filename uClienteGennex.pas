unit uClienteGennex;

interface

uses Classes, SyncObjs;

type
  TComandoTCP = class(TObject)
  private
    fMensagem : AnsiString;
  public
    constructor Create(mensagem : AnsiString);
    function getComando : AnsiString;
    procedure getParametros(var parametros : TStringList);
    function getMensagem : AnsiString;
  end;

  TEstadoSocket = (esNotReady, esIdle, esErro, esLogar, esLogarErro,
    esLogarConf, esDeslogar, esDeslogarErro, esDeslogarConf, esDespausar,
    esDespausarErro, esDespausarConf, esPausar, esPausarErro, esPausarConf,
    esFinalizarClerical, esFinalizarClericalErro, esFinalizarClericalConf,
    esDiscar, esDiscarErro, esDiscarConf);

  TOnDiscarConf = procedure(const chave, servidor : AnsiString; const idMakeCall : Integer) of object;

  // Equivalente ao popup (OnReceivedCall)
  TOnDadosChamada = procedure(const servidor, canal, telefone, chave : AnsiString; const idMakeCall : Integer) of object;

  // Notifica o fim da chamada
  TOnFimChamada = procedure(const servidor, canal : AnsiString; const idMakeCall, codigoDesligamento : Integer; const chave : AnsiString) of object;

  // Avisa o operador que o discador está realizando uma agenda pessoal
  TOnDiscandoAgp = procedure(const chave : AnsiString) of object;

  // Avisa o operador que o discador terminou uma agenda pessoal
  TOnFimDiscandoAgp = procedure() of object;

  TClienteGennex = class(TThread)
  private
    fSocket : Integer;
    host : String;
    port : Integer;
    fEstadoSocket : TEstadoSocket;
    fEntrada : AnsiString;
    fTratadoresComandoTCP : TStringList;
    fLastError : AnsiString;
    fOnDiscarConf: TOnDiscarConf;
    fOnDadosChamada: TOnDadosChamada;
    fOnFimChamada: TOnFimChamada;
    fOnDiscandoAgp: TOnDiscandoAgp;
    fOnFimDiscandoAgp: TOnFimDiscandoAgp;

    procedure processaEntrada;
    procedure processaComandoTCP(comandoTCP : TComandoTCP);
    function sendBuffer(_NumSocket: Integer; Buffer: PChar; iBytes: Integer): Integer;
    function getConectado: Boolean;
    function sendText(t: AnsiString): Boolean;
    function getEstadoSocket() : TEstadoSocket;
    procedure setEstadoSocket(novoEstado : TEstadoSocket);
    function getPronto: Boolean;
    function GetLocalHostName: AnsiString;

  public
    constructor Create(const fHost : String; const fPort : Integer);
    destructor Destroy;override;
    procedure Execute;override;
    procedure disconnect();

    function getLastError() : AnsiString;

    function logar(usuario, senha, grupo : AnsiString) : Boolean;
    function deslogar(usuario, grupo : AnsiString) : Boolean;
    function pausar(usuario, grupo : AnsiString;
      motivo : Integer = 0; submotivo : Integer = 0) : Boolean;
    function despausar(usuario, grupo : AnsiString) : Boolean;
    function finalizarClerical(usuario : AnsiString) : Boolean;
    function abortarSaida(idMakeCall : Integer) : Boolean;
    function desligarChamada() : Boolean;
    function discar(chave, ddd, telefone, rota, grupo, aplicacao : AnsiString;
      tempoMaximoChamando : Cardinal; usuario : AnsiString = '') : Boolean;

  published
    property conectado : Boolean read getConectado;
    property pronto : Boolean read getPronto;

    property OnDiscarConf : TOnDiscarConf read fOnDiscarConf write fOnDiscarConf;
    property OnDadosChamada : TOnDadosChamada read fOnDadosChamada write fOnDadosChamada;
    property OnFimChamada : TOnFimChamada read fOnFimChamada write fOnFimChamada;
    property OnDiscandoAgp : TOnDiscandoAgp read fOnDiscandoAgp write fOnDiscandoAgp;
    property OnFimDiscandoAgp : TOnFimDiscandoAgp read fOnFimDiscandoAgp write fOnFimDiscandoAgp;
  end;

implementation

uses StrUtils, SysUtils, Winsock, Windows, DateUtils, Forms;

const
  //2009-12-07 Primeira versao
  VERSAO = '1.0.0';

  DELIMITADOR_COMANDOS = #13#10;
  DELIMITADOR_PARAMETROS = ';';
  TIMEOUT_COMANDO = 10000;

  type
  ITratadorComandoTCP = class
    private
      fSocketManager : TClienteGennex;
    public
      constructor Create(socketClient : TClienteGennex);
      procedure TrataComando(comandoTCP : TComandoTCP);virtual;abstract;
    end;

  TTratadorConexaoAceita = class(ITratadorComandoTCP)
    public
      procedure TrataComando(comandoTCP : TComandoTCP);override;
    end;

  TTratadorResultLogar = class(ITratadorComandoTCP)
    public
      procedure TrataComando(comandoTCP : TComandoTCP);override;
    end;

  TTratadorResultDeslogar = class(ITratadorComandoTCP)
    public
      procedure TrataComando(comandoTCP : TComandoTCP);override;
    end;

  TTratadorResultPausar = class(ITratadorComandoTCP)
    public
      procedure TrataComando(comandoTCP : TComandoTCP);override;
    end;

  TTratadorResultDespausar = class(ITratadorComandoTCP)
    public
      procedure TrataComando(comandoTCP : TComandoTCP);override;
    end;

  TTratadorResultFinalizarClerical = class(ITratadorComandoTCP)
    public
      procedure TrataComando(comandoTCP : TComandoTCP);override;
    end;

  TTratadorRespFazerChamada = class(ITratadorComandoTCP)
    public
      procedure TrataComando(comandoTCP : TComandoTCP);override;
    end;

  TTratadorDadosChamada = class(ITratadorComandoTCP)
    public
      procedure TrataComando(comandoTCP : TComandoTCP);override;
    end;

  TTratadorFimChamada = class(ITratadorComandoTCP)
    public
      procedure TrataComando(comandoTCP : TComandoTCP);override;
    end;

  TTratadorDiscandoAgp = class(ITratadorComandoTCP)
    public
      procedure TrataComando(comandoTCP : TComandoTCP);override;
    end;

  TTratadorFimDiscandoAgp = class(ITratadorComandoTCP)
    public
      procedure TrataComando(comandoTCP : TComandoTCP);override;
    end;

{ TComandoTCP }

constructor TComandoTCP.Create(mensagem: AnsiString);
begin
fMensagem := mensagem;
end;

function TComandoTCP.getComando: AnsiString;
var
  I : Integer;
begin
I := Pos('(', fMensagem);
if I <= 0 then
  begin
  Result := fMensagem;
  exit;
  end;

Result := Copy(fMensagem, 1, I-1);
end;

function TComandoTCP.getMensagem: AnsiString;
begin
Result := fMensagem;
end;

procedure TComandoTCP.getParametros(var parametros: TStringList);
var
  I, F : Integer;
  trechoParametros : AnsiString;
begin
if not Assigned(parametros) then
  begin
  //LogaEvento('StringList nao criada!');
  exit;
  end;

I := Pos('(', fMensagem);
if I <= 0 then
  exit
else
  Inc(I);

F := Pos(')', fMensagem);
if F <= 0 then
  F := Length(fMensagem);

trechoParametros := Copy(fMensagem, I, F-I);

parametros.Text := AnsiReplaceStr(trechoParametros, DELIMITADOR_PARAMETROS, DELIMITADOR_COMANDOS);
end;

{ TClienteGennex }

function TClienteGennex.abortarSaida(idMakeCall: Integer): Boolean;
var
  comando : AnsiString;
begin
comando := Format('AbortarSaida(%d)', [idMakeCall]);
sendText(comando + DELIMITADOR_COMANDOS);
Result := true;
end;

constructor TClienteGennex.Create(const fHost: String;
  const fPort: Integer);
begin
inherited Create(true);
FreeOnTerminate := True;
host := fhost;
port := fPort;
fSocket := INVALID_SOCKET;
fLastError := EmptyStr;
setEstadoSocket(esNotReady);

Randomize;

fTratadoresComandoTCP := TStringList.Create;
fTratadoresComandoTCP.Sorted := True;
fTratadoresComandoTCP.AddObject('ConexaoAceita', TTratadorConexaoAceita.Create(self));
fTratadoresComandoTCP.AddObject('ResultLogar', TTratadorResultLogar.Create(self));
fTratadoresComandoTCP.AddObject('ResultDeslogar', TTratadorResultDeslogar.Create(self));
fTratadoresComandoTCP.AddObject('ResultPausar', TTratadorResultPausar.Create(self));
fTratadoresComandoTCP.AddObject('ResultDespausar', TTratadorResultDespausar.Create(self));
fTratadoresComandoTCP.AddObject('ResultFinalizarClerical', TTratadorResultFinalizarClerical.Create(self));
fTratadoresComandoTCP.AddObject('RespFazerChamada', TTratadorRespFazerChamada.Create(self));
fTratadoresComandoTCP.AddObject('DadosChamada', TTratadorDadosChamada.Create(self));
fTratadoresComandoTCP.AddObject('DiscandoAgp', TTratadorDiscandoAgp.Create(self));
fTratadoresComandoTCP.AddObject('FimDiscandoAgp', TTratadorDiscandoAgp.Create(self));
fTratadoresComandoTCP.AddObject('FimChamada', TTratadorFimChamada.Create(self));

resume;
end;

function TClienteGennex.desligarChamada: Boolean;
begin
sendText('DesligarChamada(1)' + DELIMITADOR_COMANDOS);
Result := true;
end;

function TClienteGennex.deslogar(usuario, grupo: AnsiString): Boolean;
var
  instante : TDateTime;
  comando : AnsiString;
begin
comando := Format('Deslogar(%s;%s)', [usuario, grupo]);
instante := Now();
setEstadoSocket(esDeslogar);
try
  sendText(comando + DELIMITADOR_COMANDOS);
  while (getEstadoSocket() <> esErro) and
    (getEstadoSocket() <> esDeslogarConf) and
    (getEstadoSocket() <> esDeslogarErro) and
    (MilliSecondsBetween(Now, instante) < TIMEOUT_COMANDO) do
    begin
    Application.ProcessMessages;
    Sleep(10);
    end;

  Result := getEstadoSocket = esDeslogarConf;
finally
  setEstadoSocket(esIdle);
end;
end;

function TClienteGennex.despausar(usuario, grupo: AnsiString): Boolean;
var
  instante : TDateTime;
  comando : AnsiString;
begin
comando := Format('Despausar(%s;%s)', [usuario, grupo]);
instante := Now();
setEstadoSocket(esDespausar);
try
  sendText(comando + DELIMITADOR_COMANDOS);
  while (getEstadoSocket() <> esErro) and
    (getEstadoSocket() <> esDespausarConf) and
    (getEstadoSocket() <> esDespausarErro) and
    (MilliSecondsBetween(Now, instante) < TIMEOUT_COMANDO) do
    begin
    Application.ProcessMessages;
    Sleep(10);
    end;

  Result := getEstadoSocket = esDespausarConf;
finally
  setEstadoSocket(esIdle);
end;
end;

destructor TClienteGennex.Destroy;
var
  I : Integer;
begin
Terminate;
if fSocket <> INVALID_SOCKET then
  disconnect;
for I := 0 to fTratadoresComandoTCP.Count - 1 do
  fTratadoresComandoTCP.Objects[I].Free;
FreeAndNil(fTratadoresComandoTCP);
inherited;
end;

function TClienteGennex.discar(chave, ddd, telefone, rota, grupo,
  aplicacao: AnsiString; tempoMaximoChamando: Cardinal;
  usuario: AnsiString): Boolean;
var
  instante : TDateTime;
  comando : AnsiString;
begin
comando := Format('Discar(%s;%s;%s;%s;%s;%s;%s;%s;%d;%s;%s;%s;TRUE)',
  [chave, ddd, telefone, '', rota, grupo, chave, aplicacao, tempoMaximoChamando,
  '', usuario, chave]);
instante := Now();
setEstadoSocket(esDiscar);
try
  sendText(comando + DELIMITADOR_COMANDOS);
  while (getEstadoSocket() <> esErro) and
    (getEstadoSocket() <> esDiscarConf) and
    (getEstadoSocket() <> esDiscarErro) and
    (MilliSecondsBetween(Now, instante) < TIMEOUT_COMANDO) do
    begin
    Application.ProcessMessages;
    Sleep(10);
    end;

  Result := getEstadoSocket = esDiscarConf;
finally
  setEstadoSocket(esIdle);
end;
end;

procedure TClienteGennex.disconnect;
begin
if fSocket=INVALID_SOCKET then
  exit;

closesocket(fSocket);
fSocket := INVALID_SOCKET;
end;

procedure TClienteGennex.Execute;
var
  return, lidos : Integer;
  Buff: Array [0..1024] of Char;
  wVersionRequested: WORD;
  wWSAData: WSAData;
  mysocket : TSockAddr;
begin
wVersionRequested := MAKEWORD( 1, 0 );
WSAStartup(wVersionRequested, wWSAData);
try
  repeat
    if fSocket = INVALID_SOCKET then
      begin
      mysocket.sin_family := AF_INET;
      mysocket.sin_port := htons(port);
      mysocket.sin_addr.S_addr := inet_addr(pchar(host));

      fSocket := Socket(PF_INET,SOCK_STREAM,IPPROTO_IP);

      if fSocket = INVALID_SOCKET then
        begin
        //LogaEvento('Erro na abertura do socket.');
        Sleep(1 + Random(10000));
        continue;
        end;

      return := connect(fSocket,mysocket,sizeof(mysocket));

      if return < 0 then
        begin
        //LogaEvento(Format('Erro na conexao a %s:%d.', [fHost, fPorta]));
        closesocket(fSocket);
        fSocket := INVALID_SOCKET;
        Sleep(1+Random(10000));
        continue;
        end;
      //LogaEvento(Format('Conectado a %s:%d', [fHost, fPorta]));
      fEntrada := EmptyStr;
      FillChar(Buff, SizeOf(Buff), 0);
      sendText(Format('OndeLogar(;%s)', [GetLocalHostName]) + DELIMITADOR_COMANDOS);
      end;

    lidos := recv(fSocket, Buff[0], SizeOf(Buff), 0);
    if lidos <= 0 then
      begin
      //LogaEvento('Desconectado.');
      closesocket(fSocket);
      fSocket := INVALID_SOCKET;
      continue;
      end;

    fEntrada := fEntrada + String(Buff);
    FillChar(Buff, SizeOf(Buff), 0);
    processaEntrada;

  until Terminated;
finally
  WSACleanup;
end;
end;

function TClienteGennex.finalizarClerical(usuario: AnsiString): Boolean;
var
  instante : TDateTime;
  comando : AnsiString;
begin
comando := Format('FinalizarClerical(%s)', [usuario]);
instante := Now();
setEstadoSocket(esFinalizarClerical);
try
  sendText(comando + DELIMITADOR_COMANDOS);
  while (getEstadoSocket() <> esErro) and
    (getEstadoSocket() <> esFinalizarClericalConf) and
    (getEstadoSocket() <> esFinalizarClericalErro) and
    (MilliSecondsBetween(Now, instante) < TIMEOUT_COMANDO) do
    begin
    Application.ProcessMessages;
    Sleep(10);
    end;

  Result := getEstadoSocket = esFinalizarClericalConf;
finally
  setEstadoSocket(esIdle);
end;
end;

function TClienteGennex.getConectado: Boolean;
begin
result := (fSocket <> INVALID_SOCKET);
end;

function TClienteGennex.getEstadoSocket: TEstadoSocket;
begin
result := fEstadoSocket;
end;

function TClienteGennex.getLastError: AnsiString;
begin
Result := fLastError;
fLastError := EmptyStr;
end;

function TClienteGennex.GetLocalHostName: AnsiString;
var
  HN: PChar;
begin
HN := AllocMem(100);
GetHostName(HN, 50);
Result := HN;
FreeMem(HN);
end;

function TClienteGennex.getPronto: Boolean;
begin
Result := getEstadoSocket()=esIdle;
end;

function TClienteGennex.logar(usuario, senha, grupo: AnsiString): Boolean;
var
  instante : TDateTime;
  comando : AnsiString;
begin
comando := Format('OndeLogar(;%s)', [GetLocalHostName]);
sendText(comando + DELIMITADOR_COMANDOS);
comando := Format('Logar(%s;%s;%s)', [usuario, senha, grupo]);
instante := Now();
setEstadoSocket(esLogar);
try
  sendText(comando + DELIMITADOR_COMANDOS);
  while (getEstadoSocket() <> esErro) and
    (getEstadoSocket() <> esLogarConf) and
    (getEstadoSocket() <> esLogarErro) and
    (MilliSecondsBetween(Now, instante) < TIMEOUT_COMANDO) do
    begin
    Application.ProcessMessages;
    Sleep(10);
    end;

  Result := getEstadoSocket = esLogarConf;
finally
  setEstadoSocket(esIdle);
end;
end;

function TClienteGennex.pausar(usuario, grupo: AnsiString; motivo,
  submotivo: Integer): Boolean;
var
  instante : TDateTime;
  comando : AnsiString;
begin
comando := Format('Pausar(%s;%s;%d;%d)', [usuario, grupo, motivo, submotivo]);
instante := Now();
setEstadoSocket(esPausar);
try
  sendText(comando + DELIMITADOR_COMANDOS);
  while (getEstadoSocket() <> esErro) and
    (getEstadoSocket() <> esPausarConf) and
    (getEstadoSocket() <> esPausarErro) and
    (MilliSecondsBetween(Now, instante) < TIMEOUT_COMANDO) do
    begin
    Application.ProcessMessages;
    Sleep(10);
    end;

  Result := getEstadoSocket = esPausarConf;
finally
  setEstadoSocket(esIdle);
end;
end;

procedure TClienteGennex.processaComandoTCP(comandoTCP: TComandoTCP);
var
  I : Integer;
begin
if fTratadoresComandoTCP.Find(UpperCase(comandoTCP.getComando), I) then
  try
    ITratadorComandoTCP( fTratadoresComandoTCP.Objects[I] ).TrataComando(comandoTCP)
  except
    on E : Exception do
      begin
      //LogaEvento(Format( 'Erro no tratamento do comando %s : %s',
      //  [comandoTCP.getMensagem, e.Message] ));
      end;
  end
else
  //LogaEvento(Format('Comando nao tratado: %s', [comandoTCP.getMensagem]));
end;

procedure TClienteGennex.processaEntrada;
var
  I : Integer;
  comandoTCP : TComandoTCP;
  entrada : AnsiString;
begin
I := Pos(DELIMITADOR_COMANDOS, fEntrada);
if I <= 0 then
  exit;

repeat
  entrada := Copy(fEntrada, 1, I - 1);
  entrada := Trim(entrada);

  fEntrada := Copy(fEntrada, I + Length(DELIMITADOR_COMANDOS), Length(fEntrada));

  //LogaEvento('Recebido: ' + entrada);

  comandoTCP := TComandoTCP.Create(entrada);
  try
    processaComandoTCP(comandoTCP);
  finally
    comandoTCP.Free;
  end;
  I := Pos(DELIMITADOR_COMANDOS, fEntrada);
until I <= 0;
end;

function TClienteGennex.sendBuffer(_NumSocket: Integer; Buffer: PChar;
  iBytes: Integer): Integer;
var
   CodEnvio, Enviados, Tentativas, Enviar: Integer;
begin
Tentativas := 0;
Enviados := 0;
while Enviados < iBytes do
   begin
   Inc(Tentativas);
   Enviar := iBytes-Enviados;
   if Enviar > 0 then
      begin
      CodEnvio := send(_NumSocket, Buffer[Enviados], Enviar, 0);
      if CodEnvio = SOCKET_ERROR then
         begin
         CodEnvio := Windows.GetLastError;
         case CodEnvio of
            WSAEWOULDBLOCK:
               begin
               Sleep(1+Random(100));
               end;
            else
               begin
               BREAK;
               end;
            end;
         end
      else
         begin
         Enviados := Enviados + CodEnvio;
         end;
      end;
   if Tentativas > 10 then
      begin
      break;
      end;
   end;
Result := Enviados;
end;

function TClienteGennex.sendText(t: AnsiString): Boolean;
var
 iTamanho : Integer;
begin
//LogaEvento('Enviado: ' + Trim(t));
iTamanho := Length(t);
Result := False;
try
   Result := SendBuffer(fSocket, PChar(t), iTamanho) = iTamanho;
   except
   end;
end;

procedure TClienteGennex.setEstadoSocket(novoEstado: TEstadoSocket);
begin
fEstadoSocket := novoEstado;
end;

{ ITratadorComandoTCP }

constructor ITratadorComandoTCP.Create(socketClient: TClienteGennex);
begin
fSocketManager := socketClient;
end;

{ TTratadorConexaoAceita }

procedure TTratadorConexaoAceita.TrataComando(comandoTCP: TComandoTCP);
begin
fSocketManager.setEstadoSocket(esIdle);
end;

{ TTratadorRespLogar }

procedure TTratadorResultLogar.TrataComando(comandoTCP: TComandoTCP);
var
  I : Integer;
  parametros : TStringList;
  codigo : Integer;
  usuario, mensagem : AnsiString;
begin
codigo := 0;
parametros := TStringList.Create;
try
  comandoTCP.getParametros(parametros);
  if parametros.Count < 4 then
    begin
    exit;
    end;

  for I := 0 to parametros.Count - 1 do
    begin
    case I of
      0 : usuario := parametros.Strings[I];
      2 : codigo := StrToIntDef(parametros.Strings[I], 0);
      3 : mensagem := parametros.Strings[I];
    end;
    end;

  if codigo <> 1 then
    begin
    fSocketManager.fLastError := mensagem;
    fSocketManager.setEstadoSocket(esLogarErro);
    exit;
    end;

  fSocketManager.setEstadoSocket(esLogarConf);

finally
  parametros.Free;
end;
end;

{ TTratadorResultDeslogar }

procedure TTratadorResultDeslogar.TrataComando(comandoTCP: TComandoTCP);
var
  I : Integer;
  parametros : TStringList;
  codigo : Integer;
  usuario, mensagem : AnsiString;
begin
codigo := 0;
parametros := TStringList.Create;
try
  comandoTCP.getParametros(parametros);
  if parametros.Count < 4 then
    begin
    exit;
    end;

  for I := 0 to parametros.Count - 1 do
    begin
    case I of
      0 : usuario := parametros.Strings[I];
      2 : codigo := StrToIntDef(parametros.Strings[I], 0);
      3 : mensagem := parametros.Strings[I];
    end;
    end;

  if codigo <> 1 then
    begin
    fSocketManager.fLastError := mensagem;
    fSocketManager.setEstadoSocket(esDeslogarErro);
    exit;
    end;

  fSocketManager.setEstadoSocket(esDeslogarConf);

finally
  parametros.Free;
end;
end;

{ TTratadorResultPausar }

procedure TTratadorResultPausar.TrataComando(comandoTCP: TComandoTCP);
var
  I : Integer;
  parametros : TStringList;
  codigo : Integer;
  usuario, mensagem : AnsiString;
begin
codigo := 0;
parametros := TStringList.Create;
try
  comandoTCP.getParametros(parametros);
  if parametros.Count < 4 then
    begin
    exit;
    end;

  for I := 0 to parametros.Count - 1 do
    begin
    case I of
      0 : usuario := parametros.Strings[I];
      2 : codigo := StrToIntDef(parametros.Strings[I], 0);
      3 : mensagem := parametros.Strings[I];
    end;
    end;

  if codigo <> 1 then
    begin
    fSocketManager.fLastError := mensagem;
    fSocketManager.setEstadoSocket(esPausarErro);
    exit;
    end;

  fSocketManager.setEstadoSocket(esPausarConf);

finally
  parametros.Free;
end;
end;

{ TTratadorResultDespausar }

procedure TTratadorResultDespausar.TrataComando(comandoTCP: TComandoTCP);
var
  I : Integer;
  parametros : TStringList;
  codigo : Integer;
  usuario, mensagem : AnsiString;
begin
codigo := 0;
parametros := TStringList.Create;
try
  comandoTCP.getParametros(parametros);
  if parametros.Count < 4 then
    begin
    exit;
    end;

  for I := 0 to parametros.Count - 1 do
    begin
    case I of
      0 : usuario := parametros.Strings[I];
      2 : codigo := StrToIntDef(parametros.Strings[I], 0);
      3 : mensagem := parametros.Strings[I];
    end;
    end;

  if codigo <> 1 then
    begin
    fSocketManager.fLastError := mensagem;
    fSocketManager.setEstadoSocket(esDespausarErro);
    exit;
    end;

  fSocketManager.setEstadoSocket(esDespausarConf);

finally
  parametros.Free;
end;
end;

{ TTratadorResultFinalizarClerical }

procedure TTratadorResultFinalizarClerical.TrataComando(
  comandoTCP: TComandoTCP);
var
  I : Integer;
  parametros : TStringList;
  codigo : Integer;
  usuario, mensagem : AnsiString;
begin
codigo := 0;
parametros := TStringList.Create;
try
  comandoTCP.getParametros(parametros);
  if parametros.Count < 4 then
    begin
    exit;
    end;

  for I := 0 to parametros.Count - 1 do
    begin
    case I of
      0 : usuario := parametros.Strings[I];
      2 : codigo := StrToIntDef(parametros.Strings[I], 0);
      3 : mensagem := parametros.Strings[I];
    end;
    end;

  if codigo <> 1 then
    begin
    fSocketManager.fLastError := mensagem;
    fSocketManager.setEstadoSocket(esFinalizarClericalErro);
    exit;
    end;

  fSocketManager.setEstadoSocket(esFinalizarClericalConf);

finally
  parametros.Free;
end;
end;

{ TTratadorRespFazerChamada }

procedure TTratadorRespFazerChamada.TrataComando(comandoTCP: TComandoTCP);
var
  I : Integer;
  parametros : TStringList;
  idMakeCall, codigo : Integer;
  chave, servidor, mensagem : AnsiString;
begin
idMakeCall := 0;
codigo := 0;
parametros := TStringList.Create;
try
  comandoTCP.getParametros(parametros);
  if parametros.Count < 5 then
    begin
    exit;
    end;

  for I := 0 to parametros.Count - 1 do
    begin
    case I of
      0 : chave := parametros.Strings[I];
      1 : servidor := parametros.Strings[I];
      2 : idMakeCall := StrToIntDef(parametros.Strings[I], 0);
      3 : codigo := StrToIntDef(parametros.Strings[I], 0);
      4 : mensagem := parametros.Strings[I];
    end;
    end;

  if codigo <> 1 then
    begin
    fSocketManager.fLastError := mensagem;
    fSocketManager.setEstadoSocket(esDiscarErro);
    exit;
    end;

  fSocketManager.setEstadoSocket(esDiscarConf);

  if Assigned(fSocketManager.fOnDiscarConf) then
    try
      fSocketManager.fOnDiscarConf(chave, servidor, idMakeCall);
    except
    end;
finally
  parametros.Free;
end;
end;

{ TTratadorDadosChamada }

procedure TTratadorDadosChamada.TrataComando(comandoTCP: TComandoTCP);
var
  I : Integer;
  parametros : TStringList;
  idMakeCall : Integer;
  servidor, canal, telefone, chave : AnsiString;
begin
idMakeCall := 0;
parametros := TStringList.Create;
try
  comandoTCP.getParametros(parametros);
  if parametros.Count < 4 then
    begin
    exit;
    end;

  for I := 0 to parametros.Count - 1 do
    begin
    case I of
      0 : servidor := parametros.Strings[I];
      1 : canal := parametros.Strings[I];
      2 : telefone := parametros.Strings[I];
      3 : chave := parametros.Strings[I];
      4 : idMakeCall := StrToIntDef(parametros.Strings[I], 0);
    end;
    end;

  if Assigned(fSocketManager.fOnDadosChamada) then
    try
      fSocketManager.fOnDadosChamada(servidor, canal, telefone, chave, idMakeCall);
    except
    end;
finally
  parametros.Free;
end;
end;

{ TTratadorFimChamada }

procedure TTratadorFimChamada.TrataComando(comandoTCP: TComandoTCP);
var
  I : Integer;
  parametros : TStringList;
  idMakeCall, codigo : Integer;
  servidor, canal, chave : AnsiString;
begin
idMakeCall := 0;
codigo := 0;
parametros := TStringList.Create;
try
  comandoTCP.getParametros(parametros);
  if parametros.Count < 4 then
    begin
    exit;
    end;

  for I := 0 to parametros.Count - 1 do
    begin
    case I of
      0 : servidor := parametros.Strings[I];
      1 : canal := parametros.Strings[I];
      2 : idMakeCall := StrToIntDef(parametros.Strings[I], 0);
      3 : codigo := StrToIntDef(parametros.Strings[I], 0);
      4 : chave := parametros.Strings[I];
    end;
    end;

  if Assigned(fSocketManager.fOnFimChamada) then
    try
      fSocketManager.fOnFimChamada(servidor, canal, idMakeCall, codigo, chave);
    except
    end;
finally
  parametros.Free;
end;
end;

{ TTratadorDiscandoAgp }

procedure TTratadorDiscandoAgp.TrataComando(comandoTCP: TComandoTCP);
var
  I : Integer;
  parametros : TStringList;
  chave : AnsiString;
begin
parametros := TStringList.Create;
try
  comandoTCP.getParametros(parametros);
  if parametros.Count < 1 then
    begin
    exit;
    end;

  for I := 0 to parametros.Count - 1 do
    begin
    case I of
      1 : chave := parametros.Strings[I];
    end;
    end;

  if Assigned(fSocketManager.fOnDiscandoAgp) then
    try
      fSocketManager.fOnDiscandoAgp(chave);
    except
    end;
finally
  parametros.Free;
end;
end;

{ TTratadorFimDiscandoAgp }

procedure TTratadorFimDiscandoAgp.TrataComando(comandoTCP: TComandoTCP);
begin
if not Assigned(fSocketManager.fOnFimDiscandoAgp) then
  exit;

try
  fSocketManager.fOnFimDiscandoAgp();
except
end;
end;

end.

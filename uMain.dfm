object frmIntegracaoGennex: TfrmIntegracaoGennex
  Left = 436
  Top = 197
  Width = 433
  Height = 500
  Caption = 'frmIntegracaoGennex'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object lblDestino: TLabel
    Left = 16
    Top = 136
    Width = 36
    Height = 13
    Caption = 'Destino'
  end
  object lblUsuario: TLabel
    Left = 16
    Top = 16
    Width = 46
    Height = 13
    Caption = 'lblUsuario'
  end
  object lblSenha: TLabel
    Left = 144
    Top = 16
    Width = 41
    Height = 13
    Caption = 'lblSenha'
  end
  object lblGrupo: TLabel
    Left = 272
    Top = 16
    Width = 39
    Height = 13
    Caption = 'lblGrupo'
  end
  object edtUsuario: TEdit
    Left = 16
    Top = 32
    Width = 121
    Height = 21
    TabOrder = 0
    Text = '44444'
  end
  object edtSenha: TEdit
    Left = 144
    Top = 32
    Width = 121
    Height = 21
    TabOrder = 1
    Text = '44444'
  end
  object edtGrupo: TEdit
    Left = 272
    Top = 32
    Width = 121
    Height = 21
    TabOrder = 2
    Text = '0202'
  end
  object btnLogar: TButton
    Left = 16
    Top = 64
    Width = 75
    Height = 25
    Caption = 'btnLogar'
    TabOrder = 3
    OnClick = btnLogarClick
  end
  object btnDeslogar: TButton
    Left = 16
    Top = 96
    Width = 75
    Height = 25
    Caption = 'btnDeslogar'
    TabOrder = 4
    OnClick = btnDeslogarClick
  end
  object btnPausar: TButton
    Left = 96
    Top = 64
    Width = 75
    Height = 25
    Caption = 'btnPausar'
    TabOrder = 5
    OnClick = btnPausarClick
  end
  object btnDespausar: TButton
    Left = 96
    Top = 96
    Width = 75
    Height = 25
    Caption = 'btnDespausar'
    TabOrder = 6
    OnClick = btnDespausarClick
  end
  object btnFinalizarClerical: TButton
    Left = 176
    Top = 64
    Width = 97
    Height = 25
    Caption = 'btnFinalizarClerical'
    TabOrder = 7
    OnClick = btnFinalizarClericalClick
  end
  object edtTelefone: TEdit
    Left = 56
    Top = 128
    Width = 121
    Height = 21
    TabOrder = 8
    Text = '36188585'
  end
  object btnDiscar: TButton
    Left = 16
    Top = 160
    Width = 75
    Height = 25
    Caption = 'btnDiscar'
    TabOrder = 9
    OnClick = btnDiscarClick
  end
  object memoLog: TMemo
    Left = 16
    Top = 200
    Width = 385
    Height = 249
    TabOrder = 10
  end
  object btnAbortarSaida: TButton
    Left = 96
    Top = 160
    Width = 97
    Height = 25
    Caption = 'btnAbortarSaida'
    TabOrder = 11
    OnClick = btnAbortarSaidaClick
  end
  object btnDesligar: TButton
    Left = 176
    Top = 96
    Width = 75
    Height = 25
    Caption = 'btnDesligar'
    TabOrder = 12
    OnClick = btnDesligarClick
  end
end

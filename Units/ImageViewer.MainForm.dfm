object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'ImageViewer'
  ClientHeight = 450
  ClientWidth = 730
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter: TSplitter
    Left = 265
    Top = 0
    Height = 450
    ExplicitLeft = 368
    ExplicitTop = 160
    ExplicitHeight = 100
  end
  object FolderTree: TTreeView
    Left = 0
    Top = 0
    Width = 265
    Height = 450
    Align = alLeft
    Images = FolderIconList
    Indent = 19
    TabOrder = 0
    OnCollapsed = FolderTreeCollapsed
    OnCreateNodeClass = FolderTreeCreateNodeClass
    OnExpanding = FolderTreeExpanding
  end
  object ThumbnailPanel: TPanel
    Left = 268
    Top = 0
    Width = 462
    Height = 450
    Align = alClient
    Caption = 'ThumbnailPanel'
    TabOrder = 1
    object ThumbnailView: TListView
      Left = 1
      Top = 22
      Width = 460
      Height = 427
      Align = alClient
      Columns = <>
      DoubleBuffered = True
      LargeImages = ImageList
      OwnerData = True
      ReadOnly = True
      ParentDoubleBuffered = False
      SmallImages = ImageList
      TabOrder = 0
      OnAdvancedCustomDrawItem = ThumbnailViewAdvancedCustomDrawItem
    end
    object SizerPanel: TPanel
      Left = 1
      Top = 1
      Width = 460
      Height = 21
      HelpContext = 21
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 1
      object SizerBox: TComboBox
        Left = 315
        Top = 0
        Width = 145
        Height = 22
        Align = alRight
        Style = csOwnerDrawFixed
        TabOrder = 0
        Items.Strings = (
          '16'#1093'16'
          '32'#1093'32'
          '64'#1093'64'
          '128'#1093'128'
          '256'#1093'256'
          '512'#1093'512'
          '1024'#1093'1024')
      end
    end
  end
  object FolderIconList: TImageList
    Left = 176
    Top = 64
  end
  object ImageList: TImageList
    Height = 128
    Width = 128
    Left = 320
    Top = 64
  end
  object MainMenu: TMainMenu
    Left = 16
    Top = 8
    object ExitMenu: TMenuItem
      Caption = 'Exit'
      OnClick = ExitMenuClick
    end
    object AboutMenu: TMenuItem
      Caption = 'About...'
      OnClick = AboutMenuClick
    end
  end
end

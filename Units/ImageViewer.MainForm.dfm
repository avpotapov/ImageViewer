object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'MainForm'
  ClientHeight = 582
  ClientWidth = 730
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter: TSplitter
    Left = 265
    Top = 0
    Height = 582
    ExplicitLeft = 368
    ExplicitTop = 160
    ExplicitHeight = 100
  end
  object FolderTree: TTreeView
    Left = 0
    Top = 0
    Width = 265
    Height = 582
    Align = alLeft
    Images = FolderIconList
    Indent = 19
    TabOrder = 0
    OnChange = FolderTreeChange
    OnCollapsed = FolderTreeCollapsed
    OnCreateNodeClass = FolderTreeCreateNodeClass
    OnExpanding = FolderTreeExpanding
  end
  object ThumbnailPanel: TPanel
    Left = 268
    Top = 0
    Width = 462
    Height = 582
    Align = alClient
    Caption = 'ThumbnailPanel'
    TabOrder = 1
    object ThumbnailList: TListView
      Left = 1
      Top = 1
      Width = 460
      Height = 535
      Align = alClient
      Columns = <>
      DoubleBuffered = True
      LargeImages = ImageList
      OwnerData = True
      ParentDoubleBuffered = False
      SmallImages = ImageList
      TabOrder = 0
      OnAdvancedCustomDrawItem = ThumbnailListAdvancedCustomDrawItem
    end
    object ThumbnailSizer: TTrackBar
      Left = 1
      Top = 536
      Width = 460
      Height = 45
      Align = alBottom
      Max = 5
      TabOrder = 1
      OnChange = ThumbnailSizerChange
    end
  end
  object FolderIconList: TImageList
    Left = 112
    Top = 40
  end
  object ImageList: TImageList
    Height = 128
    Width = 128
    Left = 320
    Top = 64
  end
end

object Network: TNetwork
  OldCreateOrder = False
  Height = 371
  Width = 608
  object UDPServer: TIdUDPServer
    Bindings = <>
    DefaultPort = 64220
    OnUDPRead = UDPServerUDPRead
    Left = 220
    Top = 108
  end
end

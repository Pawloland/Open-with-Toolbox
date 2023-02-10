Set WshShell = CreateObject("WScript.Shell") 
WshShell.Run """" & WScript.Arguments.Item(0) &"""" & " "& """" &WScript.Arguments.Item(1) &"""",0
' , 0
Set WshShell = Nothing

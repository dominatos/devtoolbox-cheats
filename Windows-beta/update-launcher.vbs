Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

strLocalAppData = objShell.ExpandEnvironmentStrings("%LOCALAPPDATA%")
strScriptPath = strLocalAppData & "\devtoolbox-cheats\update-cheats.ps1"

If objFSO.FileExists(strScriptPath) Then
    objShell.Run "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & strScriptPath & """", 0, False
End If

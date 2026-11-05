Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
currentDir = fso.GetParentFolderName(WScript.ScriptFullName)
psScript = fso.BuildPath(currentDir, "daemon-override-win-v.ps1")
WshShell.Run "powershell -NoProfile -ExecutionPolicy Bypass -File """ & psScript & """", 0, False

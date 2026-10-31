' ==========================================================
'  Anki Portable - silent launcher (no console window)
'  Sets ANKI_BASE to .\Data so the folder stays self-contained.
'  If Windows Script Host is disabled on your machine,
'  just use "启动 Anki.bat" instead.
' ==========================================================
Option Explicit

Dim fso, sh, here, dataDir, exePath, q

Set fso = CreateObject("Scripting.FileSystemObject")
Set sh  = CreateObject("WScript.Shell")

here    = fso.GetParentFolderName(WScript.ScriptFullName)
dataDir = here & "\Data"
exePath = here & "\App\Anki.exe"
q       = Chr(34)

If Not fso.FileExists(exePath) Then
    MsgBox "App\Anki.exe was not found." & vbCrLf & vbCrLf & _
           "Please unzip the whole folder first, and keep the" & vbCrLf & _
           "App / Data / launcher structure untouched.", _
           vbCritical, "Anki Portable"
    WScript.Quit 1
End If

If Not fso.FolderExists(dataDir) Then fso.CreateFolder(dataDir)

On Error Resume Next
sh.Environment("PROCESS")("ANKI_BASE") = dataDir
sh.CurrentDirectory = here
sh.Run q & exePath & q & " --base " & q & dataDir & q, 1, False
If Err.Number <> 0 Then
    MsgBox "Failed to start Anki:" & vbCrLf & Err.Description & vbCrLf & vbCrLf & _
           "Please try ""启动 Anki.bat"" instead.", _
           vbCritical, "Anki Portable"
End If

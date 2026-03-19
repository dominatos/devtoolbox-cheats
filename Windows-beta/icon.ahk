#NoEnv
SetBatchLines, -1

; Change this path if you want to browse shell32.dll instead
FileToBrowse := "C:\Windows\System32\imageres.dll"

Gui, Add, Text,, Browsing: %FileToBrowse%
Gui, Add, ListView, r20 w300 vMyListView, Index|Icon Sample
ImageListID := IL_Create(300, 10, 1) 
LV_SetImageList(ImageListID, 1) 

Loop, 300 {
    ; Add icon from the DLL to the internal ImageList
    if !IL_Add(ImageListID, FileToBrowse, A_Index)
        break
    
    ; Add row: "Icon" followed by the index in the ImageList
    LV_Add("Icon" . A_Index, A_Index, "      <-- ID " . A_Index)
}

LV_ModifyCol(1, 60)
LV_ModifyCol(2, 200)
Gui, Show,, Icon Browser 1.1
return

GuiClose:
ExitApp

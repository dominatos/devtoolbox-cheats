#NoEnv
#SingleInstance Force
#Persistent
SetWorkingDir %A_ScriptDir%


; ============= Config =============
EnvGet, UserProfile, USERPROFILE
CHEATS_DIR := UserProfile . "\cheats.d"
LOG_FILE := UserProfile . "\cheats_debug.log"

; ============= Debug Log =============
FileDelete, %LOG_FILE%
FileAppend, Script started`n, %LOG_FILE%

; ============= Tray Setup =============
Menu, Tray, Tip, Dev Toolbox Cheats

; Check for custom icon in cheats.d, fallback to system icon if missing
CustomIcon := CHEATS_DIR . "\icon.ico"
if FileExist(CustomIcon) {
    Menu, Tray, Icon, %CustomIcon%
} else {
    Menu, Tray, Icon, imageres.dll, 110 ; Default gear icon
}

; ============= Group Icons (Encoding-safe) =============
GROUP_ICONS := { "Basics": Chr(0x1F4DA)
    , "Network": Chr(0x1F4E1)
    , "Storage & FS": Chr(0x1F4BF)
    , "Backups & S3": Chr(0x1F5C4)
    , "Files & Archives": Chr(0x1F4E6)
    , "Text & Parsing": Chr(0x1F4DD)
    , "Kubernetes & Containers": Chr(0x2638)
    , "System & Logs": Chr(0x1F6E0)
    , "Web Servers": Chr(0x1F310)
    , "Databases": Chr(0x1F5C3)
    , "Package Managers": Chr(0x1F4E6)
    , "Security & Crypto": Chr(0x1F512)
    , "Dev & Tools": Chr(0x1F9EC)
    , "Misc": Chr(0x1F9E9)
    , "Diagnostics": Chr(0x1F50E)
    , Monitoring: Chr(0x1F4C8)
    , Cloud: Chr(0x2601)
    , "Infrastructure Management": Chr(0x1F527)
    , "Identity Management": Chr(0x1FAAA)
    , Virtualization: Chr(0x1F4BB) }

; Global state
CHEATS_DATA := []
MENU_MAP := {} ; Maps "MenuName|ItemName" to file path

IndexCheats()
BuildMenus()

FileAppend, All menus built dynamically`n, %LOG_FILE%

; ============= Hotkeys =============
; Ctrl+Shift+S to show search
^+s::GoSub, ShowSearchGui

return

; ============= Logic =============

IndexCheats() {
    global CHEATS_DIR, CHEATS_DATA, LOG_FILE
    CHEATS_DATA := []
    
    FileEncoding, UTF-8 ; Ensure UTF-8 is used for reading metadata
    
    Loop, Files, %CHEATS_DIR%\*.md, R
    {
        file := A_LoopFileFullPath
        relPath := SubStr(file, StrLen(CHEATS_DIR) + 2)
        
        ; Default metadata
        title := A_LoopFileName
        title := StrReplace(title, ".md", "")
        
        ; Get group from parent folder
        SplitPath, relPath,, parentDir
        group := parentDir ? parentDir : "Misc"
        
        icon := ""
        order := 9999
        
        ; Read first 80 lines for front-matter (force UTF-8)
        FileRead, content, *P65001 %file%
        loop, parse, content, `n, `r
        {
            if (A_Index > 80)
                break
            
            if RegExMatch(A_LoopField, "i)^Title:\s*(.*)", match)
                title := Trim(match1)
            else if RegExMatch(A_LoopField, "i)^Group:\s*(.*)", match)
                group := Trim(match1)
            else if RegExMatch(A_LoopField, "i)^Icon:\s*(.*)", match)
                icon := Trim(match1)
            else if RegExMatch(A_LoopField, "i)^Order:\s*(\d+)", match)
                order := match1
        }
        
        CHEATS_DATA.Push({"path": file, "title": title, "group": group, "icon": icon, "order": order})
        FileAppend, Indexed: %title% in %group% (%order%)`n, %LOG_FILE%
    }
}

BuildMenus() {
    global CHEATS_DATA, MENU_MAP, GROUP_ICONS, CHEATS_DIR
    
    groups := {}
    for index, cheat in CHEATS_DATA {
        gName := cheat.group
        if !groups.HasKey(gName)
            groups[gName] := []
        groups[gName].Push(cheat)
    }
    
    groupNames := []
    for gName in groups
        groupNames.Push(gName)
    
    for i, gName in groupNames {
        cheats := groups[gName]
        SortCheats(cheats)
        
        safeGroupName := RegExReplace(gName, "[^\w]", "_")
        
        for j, cheat in cheats {
            label := StrReplace(cheat.title, "&", "&&")
            if (cheat.icon != "" && !InStr(label, cheat.icon))
                label := cheat.icon . " " . label
                
            Menu, %safeGroupName%, Add, %label%, OpenFile
            MENU_MAP[safeGroupName . "|" . label] := cheat.path
        }
        
        ; Add to Tray Menu
        icon := GROUP_ICONS.HasKey(gName) ? GROUP_ICONS[gName] : Chr(0x1F9E9)
        mainLabel := icon . " " . StrReplace(gName, "&", "&&")
        Menu, Tray, Add, %mainLabel%, :%safeGroupName%
    }
    
    Menu, Tray, Add
    Menu, Tray, Add, % Chr(0x1F50D) . " Search cheats (Ctrl+Shift+S)", ShowSearchGui
    Menu, Tray, Add, % Chr(0x1F4C2) . " Open cheats folder", OpenFolder
    Menu, Tray, Add, % Chr(0x1F310) . " Online Version", OpenOnlineVersion
    Menu, Tray, Add, % Chr(0x1F419) . " GitHub Repository", OpenGitHub
    Menu, Tray, Add, % Chr(0x274C) . " Exit", ExitApp
}

SortCheats(ByRef cheats) {
    n := cheats.Length()
    loop, % n-1 {
        i := A_Index
        loop, % n-i {
            j := A_Index
            if (cheats[j].order > cheats[j+1].order) {
                tmp := cheats[j]
                cheats[j] := cheats[j+1]
                cheats[j+1] := tmp
            }
        }
    }
}

OpenFile:
    menuName := A_ThisMenu
    itemName := A_ThisMenuItem
    path := MENU_MAP[menuName . "|" . itemName]
    if (path != "") {
        Run, %path%
    }
return

OpenFolder:
    Run, %CHEATS_DIR%
return

OpenOnlineVersion:
    Run, https://cheats.alteron.net/
return

OpenGitHub:
    Run, https://github.com/dominatos/devtoolbox-cheats/
return

ExitApp:
    ExitApp
return

; ============= Search GUI =============

ShowSearchGui:
    Gui, Search:New, +AlwaysOnTop +Resize, Search Cheats
    Gui, Search:Font, s11, Segoe UI
    Gui, Search:Add, Text,, Type to search (Title or Group):
    Gui, Search:Add, Edit, vSearchQuery gUpdateSearch w500
    Gui, Search:Add, ListView, vSearchResult r20 w500 gSelectResult +Grid, Icon|Title|Group
    Gui, Search:Add, Button, x-100 y-100 Default gSelectResult, OK ; Hidden default button for Enter key
    
    ; Populate initially
    UpdateSearch()
    
    Gui, Search:Show
return

UpdateSearch() {
    global CHEATS_DATA
    Gui, Search:Default
    GuiControlGet, SearchQuery
    
    LV_Delete()
    GuiControl, -Redraw, SearchResult
    for index, cheat in CHEATS_DATA {
        if (SearchQuery = "" 
            || InStr(cheat.title, SearchQuery) 
            || InStr(cheat.group, SearchQuery)) {
            LV_Add("", cheat.icon, cheat.title, cheat.group)
        }
    }
    LV_ModifyCol(1, "AutoHdr")
    LV_ModifyCol(2, "AutoHdr")
    LV_ModifyCol(3, "AutoHdr")
    GuiControl, +Redraw, SearchResult
}

SelectResult:
    if (A_GuiEvent = "DoubleClick" || (A_GuiEvent = "Normal" && GetKeyState("Enter", "P"))) {
        LV_GetText(selTitle, A_EventInfo, 2)
        LV_GetText(selGroup, A_EventInfo, 3)
        
        for index, cheat in CHEATS_DATA {
            if (cheat.title = selTitle && cheat.group = selGroup) {
                Run, % cheat.path
                Gui, Search:Hide
                break
            }
        }
    }
return

SearchGuiEscape:
    Gui, Search:Hide
return

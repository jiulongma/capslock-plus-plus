global HyperSettings := {"Keymap":{}
    , "Tab":{}
    , "Switch":{}
    , "Basic":{}
    , "Trans":{}
    , "Notify":{}
    , "Ignore":[]
    , "SettingSections":["Basic", "Trans", "Notify", "Tab", "Ignore", "Keymap"]
    , "ScriptDir":["lib", "script"]
    , "Includer":"lib\Includer.ahk"
    , "SettingIni":["HyperSettings.ini", "HyperSwitchSettings.ini"]
    , "RunTime":{"Notifications":[]
        , "DoubleClickTrans":0
        , "SettingChange":0
        , "ScriptChange":0
        , "StartTime":A_MM . "/" . A_DD . " " . A_Hour . ":" . A_Min}}

#Include lib/BasicFunc.ahk
#Include lib/Gui.ahk
#Include lib/WindowUtil.ahk

; main 
InitSettings()

if not FileExist(HyperSettings.Includer)
{
    HyperReload()
}
SuccessMsg("Start Capslock++")

; this must be put at last , because userscript may stuck
#Include *i lib/Includer.ahk

; end

; functions for init settings
InitSettings()
{
    ; main settings
    if FileExist("HyperSettings.ini")
    {
        ReadSettings()
    }
    else
    {
        InfoMsg("HyperSettings.ini not found, using default")
        DefaultSettings()
        SaveSettings()
    }

    ; for hyper switch
    if FileExist("HyperSwitchSettings.ini")
    {
        ReadSwitchSettings()
    }
    else
    {
        InfoMsg("HyperSwitchSettings.ini not found, using default")
        DefaultSwitchSettings()
        SaveSwitchSettings()
    }
    LoadSettings()
}
LoadSettings()
{
    ; switch key load
    MapSwitchKey()
    ; basic load
    Basic := HyperSettings.Basic
    ;; startup 
    if (Basic.StartUp = 1)
    {
        autostartLnk:=A_Startup . "\capsLock++.lnk"
        if FileExist(autostartLnk)
        {
            FileGetShortcut, %autostartLnk%, lnkTarget
            if(lnkTarget!=A_ScriptFullPath)
            {
                InfoMsg("Create autostartLnk")
                FileCreateShortcut, %A_ScriptFullPath%, %autostartLnk%, %A_ScriptDir%
            }
                
        }
        else
        {
            InfoMsg("Create autostartLnk")
            FileCreateShortcut, %A_ScriptFullPath%, %autostartLnk%, %A_ScriptDir%
        }
    }
    else
    {
        autostartLnk:=A_Startup . "\capsLock++.lnk"
        if FileExist(autostartLnk)
        {
            InfoMsg("Delete autostartLnk")
            FileDelete, %autostartLnk%
        }
    }
    ;; admin
    if (Basic.Admin = 1)
    {
        if not A_IsAdmin ;running by administrator
        {
        Run *RunAs "%A_ScriptFullPath%" 
        ExitApp
        }   
    }
    ;; settingmonitor
    if (Basic.SettingMonitor = 1)
    {
        SetTimer, SettingMonitor, 1000
    }
    else
    {
        SetTimer, SettingMonitor, off
    }
    ;; scriptmonitor
    if (Basic.ScriptMonitor = 1)
    {
        SetTimer, ScriptMonitor, 1000
    }
    else 
    {
        SetTimer, ScriptMonitor, off
    }
     
    ;; notification
    Notify := HyperSettings.Notify
    if (Notify.Enable = 1)
    {
        SetTimer, NotificationMonitor, 250
    }
    else
    {
        SetTimer, NotificationMonitor, off
    }
    
}
ScriptMonitor()
{
    static timestamps := {}
    static firsttime := 1

    lst := []
    for index, dir in HyperSettings.ScriptDir
    {
        lst.Push(FileList(dir)*)
    }
    lst.Push(A_ScriptName)
    ;msgbox %A_ScriptName%
    
    ; at first put all filename into timestamps
    if firsttime
    {
        for index, filename in lst
        {
            ;Msgbox %filename% record timestamp %temp%
            FileGetTime, temp, %filename%
            timestamps[filename] := temp
        }
        firsttime := 0
        return
    }

    ; first check if missing some file
    old_num := timestamps.count()
    new_num := lst.count()
    ;msgbox %old_num%, %new_num%
    ; check if deleted
    for filename, value in timestamps
    {
        if not IsStrInArray(filename, lst)
        {
            InfoMsg(filename . " has been deleted`nPress Capslock + Alt + r to reload")
            HyperSettings.Runtime.ScriptChange := 1
            timestamps.delete(filename)
        }
    }

    ; timestamp and new file check
    for index, filename in lst
    {
        FileGetTime, temp, %filename%
        if not timestamps.haskey(filename)
        {
            InfoMsg("New file " . filename . " detected`n Press Capslock + Alt + r to reload")
            HyperSettings.Runtime.ScriptChange := 1
            timestamps[filename] := temp
        }
        else if timestamps[filename] != temp
        {
            ;old := timestamps[filename]
            ;msgbox %old% -> %temp%
            InfoMsg(filename . " changed`n Press Capslock + Alt + r to reload")
            HyperSettings.Runtime.ScriptChange := 1
            timestamps[filename] := temp
        }
    }
}

GenIncluder(dirs, dst_file)
{
    ;msgbox includer works
    lst := []
    
    for index, dir in dirs
    {
        lst.Push(FileList(dir)*)
    }

    
    content := "; auto generated, don't touch me`n"
    for index, filename in lst
    {
        if (StrEq(filename,  dst_file))
        {
            ;ignore self
            Continue
        }
            
        line := Format("#Include *i {1}`n", filename)
        content .= line
    }
    ; msgbox write to %dst_file%
    FileRead, old_content, %dst_file%
    if not StrEq(old_content, content)
    {
        ;msgbox not eq
        ;msgbox old: %old_content% 
        DebugMsg("write to " . dst_file)
        f := FileOpen(dst_file, "w")
        f.Write(content)
        f.Close()
    }
    
}

SettingMonitor()
{
    static timestamps := {}
    for index, filename in HyperSettings.SettingIni
    {
        FileGetTime, temp, %filename%
        if not timestamps.haskey(filename)
        {
            timestamps[filename] := temp
            Continue
        }
        else if (temp != timestamps[filename])
        {
            ;last := timestamps[filename]
            ;MsgBox %last%->%temp%
            InfoMsg(filename . " changed`nPress Capslock + Alt + r to read settings")
            HyperSettings.Runtime.SettingChange := 1
            timestamps[filename] := temp
        }
    }
}

NotificationMonitor()
{
    if (HyperSettings.Notify.Enable = 0)
    {
        SetTimer, NotificationMonitor, off
        return
    }
    if (HyperSettings.Notify.DisableOnFullScreen = 1)
    {
        if IsWindowFullScreen("A")
            return
    }
    noti := HyperSettings.RunTime.Notifications.pop()
    if noti
    {
        WinNotification(noti.msg, noti.title, noti.delay)
    }
}
; functions for HyperSetting.ini
ReadSettings()
{
    for index, sec in HyperSettings.SettingSections
    {
        ReadSetting(sec)
    }
}
ReadSetting(sec)
{
    IniRead, var, HyperSettings.ini, %sec%
    lst := StrSplit(var, "`n")
    for index, line in lst
    {
        pair := StrSplit(line, "=")
        key := pair[1]
        val := pair[2]
        AssignSetting(key, val, sec)
    }
}
SaveSettings()
{
    for index, sec in HyperSettings.SettingSections
    {
        SaveSetting(sec)
    }
}
SaveSetting(sec)
{
    for key, val in HyperSettings[sec]
    {
        IniWrite, % val, HyperSettings.ini, %sec%, % key
    }
}
AssignSetting(key, val, sec)
{
    section := HyperSettings[sec]
    old_val := section[key]
    if (old_val && old_val != val)
    {
        MsgBox Duplicate %sec%: %key%`nold value: %old_val%`nnew value: %val%
    }
    ;msgbox %key%, %val%
    section[key] := val
    HyperSettings[sec] := section
}
; functions for HyperWinSetting.ini

ReadSwitchSettings()
{
    IniRead, OutputVarSectionNames, HyperSwitchSettings.ini
    OutputVarSectionNames := StrSplit(OutputVarSectionNames, "`n")
    for index, appname in OutputVarSectionNames
    {
        IniRead, typ, HyperSwitchSettings.ini, %appname%, typ
        IniRead, key, HyperSwitchSettings.ini, %appname%, key
        IniRead, exe, HyperSwitchSettings.ini, %appname%, exe
        IniRead, id, HyperSwitchSettings.ini, %appname%, id
        ;msgbox %appname%, %typ%, %key%, %exe%, %id%
        HyperSettings.Switch[appname] := {"typ":typ
            ,"key":key
            ,"exe":exe
            ,"id":id}
    }
}
SaveSwitchSettings()
{
    for name, content in HyperSettings.Switch
    {
        for key, val in content
        {
            IniWrite, % val, HyperSwitchSettings.ini, %name%, % key
        }
    }
}
MapSwitchKey()
{
    for appname, value in HyperSettings.Switch
    {
        key := "hyper_" . value["key"]
        func_name := Format("Window{1}(""{2}"",""{3}"")", value["typ"], value["id"], value["exe"])
        ; msgbox %key%, %funcname%
        AssignSetting(key, func_name, "Keymap")
    }
    ;test := HyperSettings.Keymap["hyper_a"]
    ;msgbox %test%
}




; default setting
DefaultSwitchSettings()
{
    HyperSettings.Switch := {"Chrome":{"key":"a"
                                ,"typ":"B"
                                ,"id":"ahk_class Chrome_WidgetWin_1 ahk_exe chrome.exe"
                                ,"exe":"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"}

                            , "NotePad":{"key":"w"
                                ,"typ":"A"
                                ,"id":"ahk_class Notepad++"
                                ,"exe":"C:\Program Files\Notepad++\notepad++"}
                                
                            , "Qdir":{"key":"e"
                                ,"typ":"A"
                                ,"id":"ahk_class ATL:0000000140163FE0"
                                ,"exe":"D:\Tools\Q-Dir\Q-Dir_x64.exe"}

                            , "Msys2":{"key":"r"
                                ,"typ":"A"
                                ,"id":"ahk_class mintty"
                                ,"exe":"D:\Tools\msys2\msys2.exe"}

                            , "YoudaoNote":{"key":"q"
                                ,"typ":"A"
                                ,"id":"ahk_class NeteaseYoudaoYNoteMainWnd"
                                ,"exe":"C:\Program Files (x86)\Youdao\YoudaoNote\YoudaoNote.exe"}}
}
DefaultSettings()
{
    ;keymap
    HyperSettings.Keymap.hyper_wheelup := "VolumeUp"
    HyperSettings.Keymap.hyper_wheeldown := "VolumeDown"

    HyperSettings.Keymap.hyper_up := "VolumeUp"
    HyperSettings.Keymap.hyper_down := "VolumeDown"
    HyperSettings.Keymap.hyper_left := "PrevDesktop"
    HyperSettings.Keymap.hyper_right := "NextDesktop"

    HyperSettings.Keymap.hyper_c := "UnixCopy"
    HyperSettings.Keymap.hyper_v := "UnixPaste"

    HyperSettings.Keymap.hyper_h := "MoveLeft"
    HyperSettings.Keymap.hyper_j := "MoveDown"
    HyperSettings.Keymap.hyper_k := "MoveUp"
    HyperSettings.Keymap.hyper_l := "MoveRight"

    HyperSettings.Keymap.hyper_i := "MoveHome"
    HyperSettings.Keymap.hyper_o := "MoveEnd"
    HyperSettings.Keymap.hyper_u := "PageUp"
    HyperSettings.Keymap.hyper_p := "PageDown"

    ;HyperSettings.Keymap.hyper_esc := "SuspendScript" ;changed to alt+esc
    HyperSettings.Keymap.hyper_backquote := "ToggleCapsLock"

    HyperSettings.Keymap.hyper_space := "WindowToggleOnTop"
    HyperSettings.Keymap.hyper_g := "WindowKill"

    HyperSettings.Keymap.hyper_1 := "WindowC(1)"
    HyperSettings.Keymap.hyper_2 := "WindowC(2)"
    HyperSettings.Keymap.hyper_3 := "WindowC(3)"
    HyperSettings.Keymap.hyper_4 := "WindowC(4)"
    HyperSettings.Keymap.hyper_5 := "WindowC(5)"
    HyperSettings.Keymap.hyper_minus := "WindowCClear"

    HyperSettings.Keymap.hyper_tab := "HyperTab"

    HyperSettings.Keymap.hyper_s := "HyperSearch"
    HyperSettings.Keymap.hyper_t := "TransSel"

    HyperSettings.Keymap.hyper_alt_1 := "switchDesktopByNumber(1)"
    HyperSettings.Keymap.hyper_alt_2 := "switchDesktopByNumber(2)"
    HyperSettings.Keymap.hyper_alt_3 := "switchDesktopByNumber(3)"

    HyperSettings.Keymap.hyper_alt_r := "HyperReload"

    HyperSettings.Keymap.hyper_double_click := "TransDoubleClick"
    HyperSettings.Keymap.hyper_alt_t := "TransDoubleClick(1)"

    HyperSettings.Keymap.hyper_alt_w := "WindowMove(A, top)"
    HyperSettings.Keymap.hyper_alt_s := "WindowMove(A, bottom)"
    HyperSettings.Keymap.hyper_alt_a := "WindowMove(A, left)"
    HyperSettings.Keymap.hyper_alt_d := "WindowMove(A, right)"
    HyperSettings.Keymap.hyper_alt_q := "WindowMax(A)"
    HyperSettings.Keymap.hyper_alt_e := "WindowMin(A)"

    ;basic
    HyperSettings.Basic.StartUp := 1
    HyperSettings.Basic.Admin := 0
    HyperSettings.Basic.SettingMonitor := 1
    HyperSettings.Basic.ScriptMonitor := 1
    HyperSettings.Basic.DisableOnFullScreen := 1

    ;notify
    HyperSettings.Notify.Enable := 1
    HyperSettings.Notify.Style := "slide" ; fade/none/slide
    HyperSettings.Notify.MsgLevel := 1  ;0 for debug, 1 for info, 2 for succ/warning
    HyperSettings.Notify.Max := 5
    HyperSettings.Notify.DisableOnFullScreen := 1

    ;tab
    HyperSettings.Tab["sample"] := "this is a Tab sample"
    HyperSettings.Tab["date1"] := "<GetDateTime>"
    HyperSettings.Tab["date2"] := "<GetDateTime(yyyy-M-d)>"
    HyperSettings.Tab["cmain"] := "int main(int argc, char **argv)"

    ;trans
    HyperSettings.Trans.SourceLanguage := "auto"
    HyperSettings.Trans.TargetLanguage := "zh"
    HyperSettings.Trans.TransSelBackend := "google"
    HyperSettings.Trans.TransWordBackend := "cgdict"

    ;ignore
    HyperSettings.Ignore["Code.exe"] := 0

}

; reload function
HyperReload()
{
    if (HyperSettings.RunTime.SettingChange = 1 && HyperSettings.RunTime.ScriptChange = 0)
    {
        InfoMsg("Reload Settings")
        ReadSettings()
        ReadSwitchSettings()
        LoadSettings()
        HyperSettings.RunTime.SettingChange := 0
    }
    else
    {
        SetTimer ScriptMonitor, off
        GenIncluder(HyperSettings.ScriptDir, HyperSettings.Includer)
        Reload
    }
}
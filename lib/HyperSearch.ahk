#Include lib/BasicFunc.ahk
#Include lib/Gui.ahk
#Include lib/HyperTrans.ahk

HyperSearch()
{
    sel := GetSelText()
    typ := CheckStrType(sel)
    if (StrEq(typ, "file") || StrEq(typ, "folder"))
    {
        if FileExist(sel)
            Run %sel%
        else
            WarningMsg("File " . sel . " not exist")
    }
        
    if StrEq(typ, "web")
        Run %sel%
    if (StrEq(typ, "word") || StrEq(typ, "sentence"))
    {
        GoogleTransToolTip(sel)
    }
    if (StrEq(typ, "number"))
    {
        OnMouseToolTip(Format("number -> hex`n{:d} 0x{:x}", sel, sel))
    }
    if (StrEq(typ, "hex"))
    {
        OnMouseToolTip(Format("hex -> number`n{} {:d}", sel, sel))
    }
        
}

CheckStrType(str)
{

    if (RegExMatch(str,"iS)^[a-z]:\\.+\..+$"))
        return "file"
    if (RegExMatch(str,"iS)^[a-z]:\\[^.]*$"))
        return "folder"
    
    if (RegExMatch(str,"iS)^((https?:\/\/)|www\.)([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?|(https?:\/\/)?([\da-z\.-]+)\.(com|net|org)(\W[\/\w \.-]*)*\/?$"))
        return "web"
    if (RegExMatch(str, "i)^ftp://"))
        return "ftp"

    if (RegExMatch(str, "i)^\d+$"))
        return "number"
    if (RegExMatch(str, "i)^0x\d+"))
        return "hex"
    if (RegExMatch(str, "i)^\w+$"))
        return "word"
    else if (RegExMatch(str, "i)^[\w\.,?!'\$:\s]*$"))
        return "sentence"
    
    return "unknown"
}
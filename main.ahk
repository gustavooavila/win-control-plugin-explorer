;#Include, explorer/explorer.ahk
#Include, explorer/icons.ahk

explorer_path = C:\Windows\explorer.exe

listExplorerOpenDirs()
{
    hwnds := []
    explorerPaths := []
    
    WinGet, winId, List, ahk_exe %explorer_path%
    if(winId > 0)
    {
        Loop %winId%
        {
            hwnds.Push(winId%A_Index%)
        }
    }
    
    for oWin in ComObjCreate("Shell.Application").Windows
    {
        if (oWin.hwnd in hwnds)
        {
            explorer := {path: oWin.Document.Folder.Self.Path, hwnd: oWin.hwnd}
            explorerPaths.Push(explorer)
        }
        oWin := ""
    }
    return explorerPaths
}

getFolderContents(hwnd)
{
    for oWin in ComObjCreate("Shell.Application").Windows
    {
        if (oWin.hwnd = hwnd)
        {
            itemList := {}
            oItems := oWin.Document.Folder.Items()
            for FolderItem in oItems
            {
                item := {}
                
                item.name := FolderItem.Name
                item.size := FolderItem.Size
                item.type := FolderItem.Type
                item.isLink := FolderItem.IsLink == -1 ? 1 : 0
                item.isDir := FolderItem.IsFolder == -1 ? 1 : 0
                item.ext := !item.isDir && InStr(item.name, ".") ? StrSplit(item.name, ".").Pop() : ""
                item.icon := ""
                
                test := new IconExtraction(FolderItem.Path)
                
                itemList[FolderItem.Path] := item
            }
            return itemList
        }
    }
}

getOpenExplorerFiles(data)
{
    data := data.data
    explorerHwnd := data.hwnd
    NodeJS.dispatchEvent("explorer_contents", getFolderContents(explorerHwnd))
}

/*
    setExplorerPath(data)
    {
    explorerHwnd := data.explorerHwnd
    newPath := data.path
    
    ;JEE_ExpWinSetDir(explorerHwnd, newPath)
    }
*/

getOpenExplorers()
{
    NodeJS.dispatchEvent("explorer_open", listExplorerOpenDirs())
}

NodeJS.addEventListener("explorer_getOpenExplorers", "getOpenExplorers")
NodeJS.addEventListener("explorer_getExplorerFiles", "getOpenExplorerFiles")

;NodeJS.addEventListener("explorer_navigate", "setExplorerPath")
    /*
    pToken := Gdip_Startup()
    ;getFileIcon("C:\Users\Shadownrun\Documents\ahk\accpack\Acc.ahk")
    Gdip_Shutdown(pToken)
*/

class explorer
{
    shellEvent(Hwnd, wTitle, wClass, wExe, Event)
    {
        NodeJS.dispatchEvent("switch_plugin", "/explorer#" wTitle ";" Hwnd)
    }
}

WinHook.Shell.Add(ObjBindMethod(explorer, "shellEvent"),,, "Explorer.EXE", 1) ; explorer window created
WinHook.Shell.Add(ObjBindMethod(explorer, "shellEvent"),,, "Explorer.EXE", 32772) ; explorer window created
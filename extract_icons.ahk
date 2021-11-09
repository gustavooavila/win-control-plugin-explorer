#SingleInstance, Off
#NoTrayIcon

#Include, lib\ahk\Graphics.ahk
#Include, lib\ahk\Gdip_All.ahk

HBITMAPFromFile(pathImage, size := 256)
{
    static IID_IShellItemImageFactory := "{bcc18b79-ba16-442f-80c4-8a59c30c463b}"
    VarSetCapacity(RIID_IShellItemImageFactory, 16)
    if DllCall("Ole32.dll\CLSIDFromString", "WStr", IID_IShellItemImageFactory, "Ptr", &RIID_IShellItemImageFactory)
    throw "GUID IShellItemImageFactory fail, last error: " A_LastError
    
    if err := DllCall("Shell32.dll\SHCreateItemFromParsingName"
    , "WStr", pathImage
    , "Ptr", 0
    , "Ptr", &RIID_IShellItemImageFactory
    , "Ptr*", IShellItemImageFactory)
    throw "SHCreateItemFromParsingName fail: " err ", last error: " A_LastError
    
    if DllCall(NumGet(NumGet(IShellItemImageFactory+0, 0, "Ptr"), 3 * A_PtrSize, "Ptr")
    , "Ptr", IShellItemImageFactory
    , "UInt64",  size
    , "UInt",    0x00000100 ;  | SIIGBF_SCALEUP
    , "Ptr*", hBitmap)
    {
        ObjRelease(IShellItemImageFactory)
        throw "IShellItemImageFactory::GetImage fail, last error: " A_LastError
    }
    
    ObjRelease(IShellItemImageFactory)
    
    return hBitmap ; caller deletes
}

Gdip_EncodeBitmapTo64string(pBitmap, ext, Quality=75) {
    if Ext not in BMP,DIB,RLE,JPG,JPEG,JPE,JFIF,GIF,TIF,TIFF,PNG
    return -1
    Extension := "." Ext
    
    DllCall("gdiplus\GdipGetImageEncodersSize", "uint*", nCount, "uint*", nSize)
    VarSetCapacity(ci, nSize)
    DllCall("gdiplus\GdipGetImageEncoders", "uint", nCount, "uint", nSize, Ptr, &ci)
    if !(nCount && nSize)
    return -2
    
    
    
    Loop, %nCount%
    {
        sString := StrGet(NumGet(ci, (idx := (48+7*A_PtrSize)*(A_Index-1))+32+3*A_PtrSize), "UTF-16")
        if !InStr(sString, "*" Extension)
        continue
        
        pCodec := &ci+idx
        break
    }
    
    
    if !pCodec
    return -3
    
    if (Quality != 75)
    {
        Quality := (Quality < 0) ? 0 : (Quality > 100) ? 100 : Quality
        if Extension in .JPG,.JPEG,.JPE,.JFIF
        {
            DllCall("gdiplus\GdipGetEncoderParameterListSize", Ptr, pBitmap, Ptr, pCodec, "uint*", nSize)
            VarSetCapacity(EncoderParameters, nSize, 0)
            DllCall("gdiplus\GdipGetEncoderParameterList", Ptr, pBitmap, Ptr, pCodec, "uint", nSize, Ptr, &EncoderParameters)
            Loop, % NumGet(EncoderParameters, "UInt")
            {
                elem := (24+(A_PtrSize ? A_PtrSize : 4))*(A_Index-1) + 4 + (pad := A_PtrSize = 8 ? 4 : 0)
                if (NumGet(EncoderParameters, elem+16, "UInt") = 1) && (NumGet(EncoderParameters, elem+20, "UInt") = 6)
                {
                    p := elem+&EncoderParameters-pad-4
                    NumPut(Quality, NumGet(NumPut(4, NumPut(1, p+0)+20, "UInt")), "UInt")
                    break
                }
            }
        }
    }
    
    DllCall("ole32\CreateStreamOnHGlobal", "ptr",0, "int",true, "ptr*",pStream)
    DllCall("gdiplus\GdipSaveImageToStream", "ptr",pBitmap, "ptr",pStream, "ptr",pCodec, "uint",p ? p : 0)
    
    DllCall("ole32\GetHGlobalFromStream", "ptr",pStream, "uint*",hData)
    pData := DllCall("GlobalLock", "ptr",hData, "uptr")
    nSize := DllCall("GlobalSize", "uint",pData)
    
    VarSetCapacity(Bin, nSize, 0)
    DllCall("RtlMoveMemory", "ptr",&Bin , "ptr",pData , "uint",nSize)
    DllCall("GlobalUnlock", "ptr",hData)
    DllCall(NumGet(NumGet(pStream + 0, 0, "uptr") + (A_PtrSize * 2), 0, "uptr"), "ptr",pStream)
    DllCall("GlobalFree", "ptr",hData)
    
    DllCall("Crypt32.dll\CryptBinaryToString", "ptr",&Bin, "uint",nSize, "uint",0x01, "ptr",0, "uint*",base64Length)
    VarSetCapacity(base64, base64Length*2, 0)
    DllCall("Crypt32.dll\CryptBinaryToString", "ptr",&Bin, "uint",nSize, "uint",0x01, "ptr",&base64, "uint*",base64Length)
    Bin := ""
    VarSetCapacity(Bin, 0)
    VarSetCapacity(base64, -1)
    
    return base64
}

getAttributes(sPath)
{
    FS := ComObjCreate("Scripting.FileSystemObject")
    isLink := False
    isFolder := FS.FolderExists(sPath) = -1 ? True : False
    if(isFolder){
        Folder := FS.GetFolder(sPath)
        isLink := Folder.Attributes & 0x400 ? True : False
    }
    else if(FS.FileExists(sPath))
    {
        File := FS.GetFile(sPath)
        isLink := File.Attributes & 0x400 ? True : False       
    }
    
    return {isFolder: isFolder, isLink: isLink, isFile: isFile}
}

getFolder(sPath)
{    
    hBitmap := HBITMAPFromFile(sPath)
    pBitmap := Graphics.ImageRenderer.toBitmap("hBitmap", hBitmap)
    bs64 := Gdip_EncodeBitmapTo64string(pBitmap, "PNG")
    DeleteObject(hBitmap)
    result := "data:image/png;base64,"
    
    Loop, Parse, bs64, `n, `r
    {
        result .= A_LoopField
    }
    
    return result
}

getIcon(sPath, isLink)
{    
    SplitPath, sPath, sFilename,, sExt
    sFilename := StrSplit(sFilename, ".")[1]
    sFilename := sExt == "lnk" || sExt == "exe" ? sFilename : sExt
    sOutput := sOutDir "\" sFilename ".png"
    
    if(FileExist(sOutput))
    {
        return sFilename ".png"
    }
    
    hBitmap := HBITMAPFromFile(sPath)
    pBitmap := Graphics.ImageRenderer.toBitmap("hBitmap", hBitmap)
    Gdip_SaveBitmapToFile(pBitmap, sOutput)
    DeleteObject(hBitmap)
    return sFilename ".png"
}


sPath := A_Args[1]

SplitPath, sPath, sFilename,, sExt
attributes := getAttributes(sPath)

sOutDir := A_WorkingDir "\explorer\icons"
if(!InStr(FileExist(sOutDir), "D"))
{
    FileCreateDir, % sOutDir
}

stdout := FileOpen(A_Args[2], "w")

pToken := Gdip_Startup()
if(attributes.isFolder)
{
    folderIcon := getFolder(sPath)
    stdout.Write(folderIcon)
}
else if(attributes.isFile)
{
    getIcon(sPath, attributes.isLink)
}
stdout.Close()
Gdip_Shutdown(pToken)

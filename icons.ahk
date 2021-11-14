class IconExtraction
{
    static Queue := []
    static Shells := []
    
    static Running := False
    static maxShellOpen := 2
    
    static Timer := IconExtraction.Next.Bind(IconExtraction)
    
    __New(sPath)
    {
        IconExtraction.Queue.Push(sPath)
        
        
        if(!IconExtraction.Running)
        {
            IconExtraction.Next()
            IconExtraction.Running := True
            timer := IconExtraction.Timer
            interval := 500
            SetTimer % timer, % interval
        }
    }
    
    Next()
    {
        shellsInUse := 0
        shellCount := IconExtraction.Shells.Length()
        if(shellCount = IconExtraction.maxShellOpen)
        {
            Loop, %shellCount%
            {
                Shell := IconExtraction.Shells[A_Index]
                if(Shell.checkCompletionAndDispatch())
                {
                    if(IconExtraction.Queue.Length() > 0)
                    {
                        sPath := IconExtraction.Queue.RemoveAt(1)
                        IconExtraction.Shells[A_Index] := new Runner(sPath, A_Index)
                        shellsInUse++
                    }
                    else
                    {
                        shellsInUse--
                    }
                }
            }
        }
        else 
        {
            if(IconExtraction.Queue.Length() > 0)
            {
                sPath := IconExtraction.Queue.RemoveAt(1)
                IconExtraction.Shells.Push(new Runner(sPath, IconExtraction.Shells.Length()+1))
                shellsInUse++
            }
            
            Loop, %shellCount%
            {
                Shell := IconExtraction.Shells[A_Index]
                
                if(Shell.checkCompletionAndDispatch())
                {
                    shellsInUse--
                }
            }
        }
        
        if(shellsInUse < 0 && IconExtraction.Queue.Length() = 0)
        {
            timer := IconExtraction.Timer
            SetTimer % timer, Off
            IconExtraction.Running := False
        }
    }
}

class Runner
{
    ; we will use a file as an pipe,
    ; since I can't for the life of me get real pipes to work
    __new(sPath, pipeName)
    {
        this.path := sPath
        this.pipePath := A_WorkingDir "\explorer\icons\" pipeName ".txt"
        
        SplitPath, sPath, sFilename,, sExt
        this.ext := sExt
        this.filename := sFilename
        
        this.shell := ComObjCreate("WScript.Shell")
        command := A_AhkPath " " chr(34) A_WorkingDir "\explorer\extract_icons.ahk" chr(34) " " chr(34) this.path chr(34) " " chr(34) this.pipePath chr(34)
        this.exec := this.shell.Exec(command)
    }
    
    checkCompletionAndDispatch()
    {
        if(this.exec.Status)
        {
            ;console.log(this.exec.ExitCode)
            if(this.exec.ExitCode)
            {
                return True
            }
            sOutput := this.readPipeContent()
            if(sOutput = "")
            {
                sOutput := "icons/" this.ext ".png"
            }
            Nodejs.dispatchEvent("icon_Loaded", {path: this.path, icon: sOutput, ext: this.ext})
        }
        return this.exec.Status
    }
    
    readPipeContent()
    {
        file := FileOpen(this.pipePath, "r")
        contents := file.Read()
        file.Close()
        return contents
    }
    
}    
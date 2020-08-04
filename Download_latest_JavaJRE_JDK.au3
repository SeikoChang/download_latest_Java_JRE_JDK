#include <FileConstants.au3>
#include <StringConstants.au3>
#include <InetConstants.au3>
#include <Array.au3>
#include <WinAPIFiles.au3>
#include "WinHttp.au3"
#include <File.au3>
#include <Inet.au3>
#include <String.au3>


Opt("MustDeclareVars", 1)
FileChangeDir(@ScriptDir)

; Switch Debug mode
Global $__bDebug = False ; False by default
Global $__sDebugTimeOut = 0 ; Set Debug TimeOut, zero equel to infinity, 0 by default
Dim Const $t1 = TimerInit()
Dim Const $sJavaDownloadPage = "https://www.oracle.com/java/technologies/javase-downloads.html"
Dim Const $sJavaCookie = "oraclelicense=accept-securebackup-cookie"
Dim Const $sJavaURL = "https://www.oracle.com"

DownloadLatestJAVA()


Func DownloadLatestJAVA($bDownload = Default, $sFolder = Default, $bReplace = Default, $bProgress = Default, $sFunc = Default)
    Local $aJavaDownloadURI = _GetJavaJREJDKDownloadPage($sJavaDownloadPage)
    If $__bDebug == True Then _ArrayDisplay($aJavaDownloadURI, "$aJavaDownloadURI", $__sDebugTimeOut)

    For $i = 0 To UBound($aJavaDownloadURI) -1
        Global $sJavaMain = $sJavaURL & $aJavaDownloadURI[$i]
        ConsoleWrite("$sJavaMain = " & $sJavaMain & @CRLF)
        Global $aURI = _DownloadLatestJAVA($bDownload, $sFolder, $bReplace, $bProgress, $sFunc) ; by default, it only get a array of all download links. You will donwload all JAVA by UDF in this script if you assign True for first parameter
        If $__bDebug == True Then _ArrayDisplay($aURI, "$aURI", $__sDebugTimeOut)

        For $j = 0 To UBound($aURI) -1
            Local $sDDLRURL = $aURI[$j][0]
            Local $sDDLLSFN = $aURI[$j][1]
            ConsoleWrite($sDDLRURL & @CRLF)
            ConsoleWrite($sDDLLSFN & @CRLF)
;~             InetGetDownload($sDDLRURL, $sDDLLSFN) ; You can replace this by other downloader script here.
        Next

    Next

    Local $vResult = 0
    ConsoleWrite(StringFormat("Result:\t%s\nSize:\t%u\nError:\t%u\nTimer:\t%u\n", $vResult, @extended, @error, TimerDiff($t1)))
EndFunc


Func WinHttpDownloadWithCookie($sRefURI, $sCookie, $sURI, $sFilePath)
    Local $oHTTP = ObjCreate("WinHttp.WinHttpRequest.5.1")

    ; get cookie
    $oHTTP.Open("GET", $sRefURI)
    $oHTTP.Send()
    Local $rh = $oHTTP.GetAllResponseHeaders()
    Local $cookie = $sCookie
    If $__bDebug == True Then msgbox(0,"", $cookie, $__sDebugTimeOut)

    ; then download
    $oHTTP.Open("GET", $sURI)
    $oHTTP.setRequestHeader("Cookie", $cookie)
    $oHTTP.Send()
    Local $sData = $oHTTP.ResponseBody()
    If $__bDebug == True Then ConsoleWrite($sData & @CRLF)

    ; Open the file for writing (append to the end of a file) and store the handle to a variable.
    Local $hFileOpen = FileOpen($sFilePath, $FO_OVERWRITE + $FO_CREATEPATH + $FO_BINARY)
    If $hFileOpen = -1 Then
        If $__bDebug == True Then MsgBox($MB_SYSTEMMODAL, "", "An error occurred whilst writing the temporary file.", $__sDebugTimeOut)
        Return False
    EndIf

    FileWrite($hFileOpen, $sData)

    ; Close the handle returned by FileOpen.
    FileClose($hFileOpen)

    ; Delete the temporary file.
;~     FileDelete($sFilePath)

EndFunc


Func WinHttpDownload($sSource, $sFilePath, $bReplace = False, $bProgress = False)
    ; Skip file download if file already exists
    If InetFileSizeCompare($sSource, $sFilePath) And ($bReplace == False) Then Return True

    Local $sDrive = "", $sDir = "", $sFileName = "", $sExtension = ""
    Local $aPathSplit = _PathSplit($sFilePath, $sDrive, $sDir, $sFileName, $sExtension)
    If $__bDebug == True Then _ArrayDisplay($aPathSplit, "_PathSplit of " & $sFilePath, $__sDebugTimeOut)

    Dim $szProtocol, $szDomain, $szPath, $szFile
    Local $TestPath = URLSplit($sSource, $szProtocol, $szDomain, $szPath, $szFile)
    If $__bDebug == True Then _ArrayDisplay($TestPath, 'URLSplit()', $__sDebugTimeOut)

#cs
    ; Initialize and get session handle
    Local $hOpen = _WinHttpOpen()
    ; Get connection handle
    Local $hConnect = _WinHttpConnect($hOpen, $szDomain)
    ; Request
    Local $hRequest = _WinHttpSimpleSendRequest($hConnect, Default, $aPathSplit[3] & $aPathSplit[4])

    Local $iErr = @error ; collect error

    ; Download to file (it's in the same folder as your script)
    Local $hFileOpen = FileOpen($sFilePath, $FO_OVERWRITE + $FO_CREATEPATH + $FO_BINARY)
    FileWrite($hFileOpen, _WinHttpSimpleReadData($hRequest))
    FileClose($hFileOpen)

    ; Close handles
    _WinHttpCloseHandle($hRequest)
    _WinHttpCloseHandle($hConnect)
    _WinHttpCloseHandle($hOpen)
#ce

    ; Initialize
    Local $iErr = 0
    Local $hOpen = _WinHttpOpen()

    If @error Then
        If $__bDebug == True Then MsgBox(48, "Error", "Error initializing the usage of WinHTTP functions.", $__sDebugTimeOut)
        $iErr = 1
    EndIf

    ; Specify what to connect to
    Local $hConnect = _WinHttpConnect($hOpen, $szDomain)
    If @error Then
        If $__bDebug == True Then MsgBox(48, "Error", "Error specifying the initial target server of an HTTP request.", $__sDebugTimeOut)
        $iErr = 2
    EndIf

    ; Create request
    Local $hRequest = _WinHttpOpenRequest($hConnect, "GET", $szPath & $szFile, "HTTP/1.1", $WINHTTP_NO_REFERER, $WINHTTP_DEFAULT_ACCEPT_TYPES, $WINHTTP_FLAG_ESCAPE_DISABLE)
    If @error Then
        If $__bDebug == True Then MsgBox(48, "Error", "Error creating an HTTP request handle.", $__sDebugTimeOut)
        $iErr = 3
    EndIf

    ; Send it
    _WinHttpSendRequest($hRequest)
    If @error Then
        If $__bDebug == True Then MsgBox(48, "Error", "Error sending specified request.", $__sDebugTimeOut)
        $iErr = 4
    EndIf

    ; Wait for the response
    _WinHttpReceiveResponse($hRequest)
    If @error Then
        If $__bDebug == True Then MsgBox(48, "Error", "Error waiting for the response from the server.", $__sDebugTimeOut)
        $iErr = 5
    EndIf

    ; See if there is data to read
    Local $sChunk, $sData, $sHeader, $sReceivedBytes
    Local $sContentRange
    Local $iTotalReceivedBytes = 0, $iDownloadSize = 0, $vParam = $sFilePath, $nPer

    If _WinHttpQueryDataAvailable($hRequest) Then
        If $__bDebug == True Then MsgBox(64, "Info", "Data from '" & $szDomain & "'" & " is available!", $__sDebugTimeOut)
        $sHeader = _WinHttpQueryHeaders($hRequest)
        $sContentRange = StringRegExp($sHeader, "(Content-Length: .*)", 3)
        If $__bDebug == True Then _ArrayDisplay($sContentRange, "$sContentRange", $__sDebugTimeOut)
        $sContentRange = $sContentRange[0]
        ConsoleWrite("$sContentRange = " & $sContentRange & @CRLF)
        $iDownloadSize = StringRegExp($sContentRange, "^Content-Length: (.*)$", 3)
        $iDownloadSize = $iDownloadSize[0]
        ConsoleWrite(StringFormat("$sContentRange = %u\n$iDownloadSize = %u\n", $sContentRange, $iDownloadSize))
        ConsoleWrite($sHeader & @CRLF & @CRLF)
        ; Create a File handle to Download File
        Local $hFileOpen = FileOpen($sFilePath, BitOR($FO_OVERWRITE, $FO_CREATEPATH, $FO_BINARY))
        ; Read
        While (True)
            $sChunk = _WinHttpReadData($hRequest, 2)
            If @error Then
                $iErr = 6
                If $bProgress Then SplashOff()
                ExitLoop
            EndIf
            ; File flush
            FileWrite($hFileOpen, $sChunk)
            $sReceivedBytes = BinaryLen($sChunk)
            $iTotalReceivedBytes += $sReceivedBytes

            If $bProgress Then
                $nPer = Round((($iTotalReceivedBytes) / ($iDownloadSize +1)) * 100 ,0 )
                SplashTextOn("Downloading...", _
                    "File Name : " & StringRegExpReplace($sFilePath, '^.*\\', '') & @CRLF & _
                    "File Size : " & "0/" & $iDownloadSize & " bytes"& @CRLF & _
                    "Percentage : " & $nPer & "%" & @CRLF _
                    , 400, 75, @DesktopWidth-400-5, @DesktopHeight-75-40, 4+16, "",10, 1000)
            EndIf
;~             If @error Then MsgBox(64, "_WinHttpReadData Error", @error)

            If (BytesReceived($sReceivedBytes, $iTotalReceivedBytes, $iDownloadSize, $sSource, $bProgress) = False) Then
                $iErr = 7
                If $bProgress Then SplashOff()
                ExitLoop
            EndIf
        WEnd
        ConsoleWrite("Total Size of Binary : = " & BinaryLen($sData) & @CRLF) ; print to consol
    Else
        MsgBox(48, "Error", "Site is experiencing problems.")
    EndIf

    ; Close handles when they are not needed any more
    If $hRequest Then _WinHttpCloseHandle($hRequest)
    If $hConnect Then _WinHttpCloseHandle($hConnect)
    If $hOpen Then _WinHttpCloseHandle($hOpen)

    ; Close file handle
    FileClose($hFileOpen)

    ; Return whatever the result
    ConsoleWrite("Final Err : " & $iErr & @CRLF)
    Return SetError($iErr, 0, $sFilePath)
EndFunc


Func GetAllHREFfromHTML($sFilePath)
    ; Read the file.
    Local $hFileOpen = FileOpen($sFilePath, $FO_READ)
    If $hFileOpen = -1 Then
        If $__bDebug == True Then MsgBox($MB_SYSTEMMODAL, "", "An error occurred when reading the file.", $__sDebugTimeOut)
        Return False
    EndIf

    ; loop through each line of the file
    Local $sLineRead, $aArray, $sURI
    While 1
       ; read each line from a file
       $sLineRead = FileReadLine($hFileOpen)
       ; exit the loop if end of file
       If @error Then ExitLoop
       ; show the line read (just for testing)
       If $__bDebug == True Then ConsoleWrite($sLineRead & @CRLF)
       If StringRegExp($sLineRead, '<a href=".*">(.*)</a>') Then
           If $__bDebug == True Then ConsoleWrite($sLineRead & @CRLF)
           $aArray = StringRegExp($sLineRead, '<a href=".*">(.*)</a>', 3)
           If $__bDebug == True Then _ArrayDisplay($aArray, "$aArray", $__sDebugTimeOut)
           For $i = 0 To UBound($aArray) - 1
               If $__bDebug == True Then ConsoleWrite("RegExp Test with Option 3 - " & $aArray[$i] & @CRLF)
           Next
           $sURI = $aArray[0]
           If $__bDebug == True Then ConsoleWrite($sURI & @CRLF)
       EndIf
    WEnd

    ; Close the handle returned by FileOpen.
    FileClose($hFileOpen)

    ; Delete the file.
;~     FileDelete($sFilePath)

    Return $sURI
EndFunc


Func InetGetDownload($sSource, $sFilePath, $bReplace = False, $bProgress = False)
    ; Skip file download if file already exists
    Local $iErr = 0
    If InetFileSizeCompare($sSource, $sFilePath) And ($bReplace == False) Then Return SetError($iErr, 0, $sFilePath)

    ; Download the file in the background with the selected option of 'force a reload from the remote site.'
    Local $hDownload = InetGet($sSource, $sFilePath, $INET_FORCERELOAD + $INET_IGNORESSL + $INET_BINARYTRANSFER, $INET_DOWNLOADBACKGROUND)

    If $bProgress Then
        Local $nPer = "", $nRSize
        SplashTextOn("Downloading...", _
            "File Name : " & StringRegExpReplace($sFilePath, '^.*\\', '') & @CRLF & _
            "File Size : " & "0/" & $nRSize & " bytes"& @CRLF & _
            "Percentage : " & $nPer & "%" & @CRLF _
            , 400, 75, @DesktopWidth-400-5, @DesktopHeight-75-40, 4+16, "",10, 1000)
    EndIf

    ; Wait for the download to complete by monitoring when the 2nd index value of InetGetInfo returns True.
    Do
        Sleep(250)
        ; Get all information.
        Local $aData = InetGetInfo($hDownload)
        ConsoleWrite("Bytes read: " & $aData[0] & @CRLF & _
            "Size: " & $aData[1] & @CRLF & _
        "Complete?: " & $aData[2] & @CRLF & _
        "Successful?: " & $aData[3] & @CRLF & _
        "@error: " & $aData[4] & @CRLF & _
        "@extended: " & $aData[5] & @CRLF)

        Local $nPer = Round((($aData[0]) / ($aData[1] +1)) * 100 ,0 )
        consolewrite($nPer &"%" &@CRLF )

        If $bProgress Then
            ControlSetText("Downloading..." ,"", "Static1" , _
            "File Name : " & StringRegExpReplace($sFilePath, '^.*\\', '') & @CRLF & _
            "File Size : " & $aData[0] & "/" & $aData[1] & " bytes" & @CRLF & _
            "Percentage : " & $nPer & "%" & @CRLF)
        EndIf

    Until InetGetInfo($hDownload, $INET_DOWNLOADCOMPLETE)    ; Check if the download is complete.

    ; Retrieve details about the download file.
    Local $aData = InetGetInfo($hDownload)
    $iErr = @error
    If @error Then
        ConsoleWrite("InetGetInfo @Error = " & @error)
;~         InetClose($hDownload)
;~         FileDelete($sFilePath)
;~         Return SetError($iErr, 0, $sFilePath) ; If an error occurred then return from the function and delete the file.
    EndIf

    ; Close the handle returned by InetGet.
    InetClose($hDownload)
    SplashOff()

    ; Return whatever the result
    ConsoleWrite("Final Err : " & $iErr & @CRLF)
    Return SetError($iErr, 0, $sFilePath)
EndFunc


Func _DownloadLatestJAVA($bDownload = Default, $sFolder = Default, $bReplace = Default, $bProgress = Default, $sFunc = Default)
    Local $sMatchString = "data-file='//(download.oracle.com)/(otn(-pub)?/java/jdk)/(.*)/([A-Za-z0-9]{32})/(server-)?((jre|jdk)-.*\.(rpm|exe|dmg))' data-license=.*"
    Local $sMajorVersion = "1.8.0"
    If ($bDownload == Default Or $bDownload == -1) Then $bDownload = True
    If ($sFolder == Default Or $sFolder == -1) Then $sFolder = @ScriptDir
    If ($bReplace == Default Or $bReplace == -1) Then $bReplace = False
    If ($bProgress == Default Or $bProgress == -1) Then $bProgress = False
    If ($sFunc == Default Or $sFunc == -1) Then
        $sFunc = WinHttpDownload
    Else
        If (IsFunc($sFunc) == 0) Then Return SetError(1, 0, 0)
    EndIf
    ConsoleWrite("$bDownload = " & $bDownload & @CRLF)
    ConsoleWrite("$sFolder = " & $sFolder & @CRLF)
    ConsoleWrite("$bReplace = " & $bReplace & @CRLF)
    ConsoleWrite("$bProgress = " & $bProgress & @CRLF)
    ConsoleWrite("$sFunc = " & $sFunc & @CRLF)

    ; Save the downloaded file to the temporary folder.
    Local $sFilePath = _WinAPI_GetTempFileName(@TempDir)
    Local $aURI[0][2]
    ; Download html content by InetGet()
    InetGetDownload($sJavaMain, $sFilePath)

    ; Read the file.
    Local $hFileOpen = FileOpen($sFilePath, $FO_READ)
    If $hFileOpen = -1 Then
        MsgBox($MB_SYSTEMMODAL, "", "An error occurred when reading the file.")
        Return False
    EndIf

    ; loop through each line of the file
    Local $sLineRead, $aArray, $sProcessURL, $sFile, $sURI
    Local $sDomain, $sVersion, $sSecretPath, $sFilename, $aArray2
    Local $sPlatform, $sMinorVersion
    While 1
        ; read each line from a file
        $sLineRead = FileReadLine($hFileOpen)
        ; exit the loop if end of file
        If @error Then ExitLoop
        ; show the line read (just for testing)
        If $__bDebug == True Then ConsoleWrite($sLineRead & @CRLF)
        If StringRegExp($sLineRead, $sMatchString) Then
            If $__bDebug == True Then ConsoleWrite($sLineRead & @CRLF)
            $aArray = StringRegExp($sLineRead, $sMatchString, 3)
            If $__bDebug == True Then _ArrayDisplay($aArray, "$aArray")
            For $i = 0 To UBound($aArray) - 1
                If $__bDebug == True Then ConsoleWrite("RegExp Test with Option 3 - " & $aArray[$i] & @CRLF)
            Next
            $sDomain = $aArray[0]
            $sVersion = $aArray[3]
            $sSecretPath = $aArray[4]
            $sFilename = $aArray[6]
            $sProcessURL = "https://" & $sDomain & "/" & "otn-pub/java/jdk" & "/" & $sVersion & "/" & $sSecretPath & "/" & $sFilename
            ConsoleWrite("$sProcessURL = " & $sProcessURL & @CRLF)
            $sFile = $sFolder & "\" & $sFilename
            ConsoleWrite("$sFile = " & $sFile & @CRLF)
            Local $sJAVAHTML = $sFile & ".html"
            ConsoleWrite("$sJAVAHTML = " & $sJAVAHTML & @CRLF)
            WinHttpDownloadWithCookie($sJavaMain, $sJavaCookie, $sProcessURL, $sJAVAHTML)
            $sURI = StringReplace(GetAllHREFfromHTML($sJAVAHTML), "&#43;", "+")
            ConsoleWrite("$sURI = " & $sURI & @CRLF)
            Local $aTmp[1][2]
            $aTmp[0][0] = $sURI
            $aTmp[0][1] = $sFile
            If $__bDebug == True Then _ArrayDisplay($aTmp, "$aTmp")
            _ArrayAdd($aURI, $aTmp)
            If $__bDebug == True Then _ArrayDisplay($aURI, "$aURI")

            ; Download real file here
            If ($bDownload) and (Not InetFileSizeCompare($sURI, $sFile) or $bReplace) Then
                Local $sResult = $sFunc($sURI, $sFile, $bReplace, $bProgress)
                If @error Then ; Try Methond 2, start from 8u261
                    $sMinorVersion = StringTrimLeft($sVersion, 2)
                    If StringInStr($sFilename, "windows") Then
                        $sPlatform = "windows-i586"
                    ElseIf StringInStr($sFilename, "osx") Then
                        $sPlatform = "unix-i586"
                    Else
                        $sPlatform = "linux-i586"
                    EndIf

                    $sURI = StringFormat("https://javadl.oracle.com/webapps/download/GetFile/%s_%s/%s/%s/%s", $sMajorVersion, $sMinorVersion, $sSecretPath, $sPlatform, $sFilename)
                    ConsoleWrite("$sURI = " & $sURI & @CRLF)
                    If (Not InetFileSizeCompare($sURI, $sFile) or $bReplace) Then
                        $sFunc($sURI, $sFile, $bReplace, $bProgress)
                    EndIf
                EndIf
            EndIf

           ; Delete the target JAVA html for each distribution.
           FileDelete($sJAVAHTML)
        EndIf
    WEnd

    ; Close the handle of JAVA main html returned by FileOpen.
    FileClose($hFileOpen)

    ; Delete the main JAVA html file.
    FileDelete($sFilePath)

    Return $aURI
EndFunc   ;==>Example


Func URLSplit($szUrl, ByRef $szProtocol, ByRef $szDomain, ByRef $szPath, ByRef $szFile)
    Local $sSREPattern = '^(?s)(?i)(http|ftp|https|file)://(.*?/|.*$)(.*/){0,}(.*)$'
    Local $aUrlSRE = StringRegExp($szUrl, $sSREPattern, 2)
    If Not IsArray($aUrlSRE) Or UBound($aUrlSRE) - 1 <> 4 Then Return SetError(1, 0, 0)
    If StringRight($aUrlSRE[2], 1) = '/' Then
        $aUrlSRE[2] = StringTrimRight($aUrlSRE[2], 1)
        $aUrlSRE[3] = '/' & $aUrlSRE[3]
    EndIf
    $szProtocol = $aUrlSRE[1]
    $szDomain = $aUrlSRE[2]
    $szPath = $aUrlSRE[3]
    $szFile = $aUrlSRE[4]
    Return $aUrlSRE
EndFunc   ;==>URLSplit


Func InetFileSizeCompare($sURL, $sFilePath)
    ; Check if file already exists
    ; Retrieve the number of total bytes received and the filesize.
    Local $bRtv = False
    Local $nRSize = InetGetSize($sURL, 1)
    Local $nLSize = FileGetSize($sFilePath)
    ConsoleWrite("Inter File Size = "& $nRSize & @CRLF)
    ConsoleWrite("Local File Size = "& $nLSize & @CRLF)
    If ($nRSize <> 0) And ($nRSize == $nLSize) Then
        If $__bDebug == True Then MsgBox(0, $sFilePath, "file already exists and have the same size", $__sDebugTimeOut)
        $bRtv = True
    EndIf
    Return $bRtv
EndFunc


Func BytesReceived($iReceivedBytes = 0, $iTotalReceivedBytes = 0, $iDownloadSize = 0, $sSource = "", $bProgress = False)
    ConsoleWrite(StringFormat("%u bytes received.\n%u/%u\nFileSource: %s\n\n", $iReceivedBytes, $iTotalReceivedBytes, $iDownloadSize, $sSource))
    Local $nPer = Round((($iTotalReceivedBytes) / ($iDownloadSize +1)) * 100 ,0 )
    If $bProgress Then
        ControlSetText("Downloading..." ,"", "Static1" , _
            "File Name : " & StringRegExpReplace($sSource, '^.*\\', '') & @CRLF & _
            "File Size : " & $iTotalReceivedBytes & "/" & $iDownloadSize & " bytes" & @CRLF & _
            "Percentage : " & $nPer & "%" & @CRLF)
    EndIf
    If $iTotalReceivedBytes == $iDownloadSize Then
        Return False ;Stop downloading
    EndIf
    Return True ;Continue downloading
 EndFunc


Func _GetJavaJREJDKDownloadPage($sJavaDownloadPage)
    Local $sMathString = "javase-(server-)?(jre|jdk|amc)[0-9]?[1-9]?-downloads.html$"
    Local $sHTML = _INetGetSource($sJavaDownloadPage)
    If $__bDebug == True Then ConsoleWrite($sHTML & @CRLF)
    Local $aURIAll = _StringBetween($sHTML, "href='", "'>", $STR_ENDNOTSTART)
    $aURIAll = _ArrayUnique($aURIAll)
    If $__bDebug == True Then _ArrayDisplay($aURIAll, "All href link", $__sDebugTimeOut)

    Local $aURIindex = _ArrayFindAll($aURIAll, $sMathString, Default, Default, Default, 3, Default, Default)
    If $__bDebug == True Then _ArrayDisplay($aURIindex, "All herf link index with 'download' string", $__sDebugTimeOut)

    Local $aURI[0]
    For $i = 0 To UBound($aURIindex) -1
        If $__bDebug == True Then ConsoleWrite($aURIAll[$aURIindex[$i]] & @CRLF)
        _ArrayAdd($aURI, $aURIAll[$aURIindex[$i]])
    Next
    If $__bDebug == True Then _ArrayDisplay($aURI, "All herf link with 'jre/jdk download' string", $__sDebugTimeOut)

    Return $aURI
 EndFunc


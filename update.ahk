
#include meta.ahk

IfExist, updater.exe
{
	FileDelete, updater.exe
}

IniRead, lastUpdate, setting.ini, update, last, 0
IniRead, autoUpdate, setting.ini, update, autoupdate, 1
IniRead, updateMirror, setting.ini, update, mirror, 1
IniWrite, % updateMirror, setting.ini, update, mirror
mirrorList:=["https://github.com"
,"https://ghproxy.com/https://github.com"
,"https://download.fastgit.org"
,"https://github.com.cnpmjs.org"]
updatemirrorTried:=Array()
today:=A_MM . A_DD
if(autoUpdate) {
	if(lastUpdate!=today) {
		; MsgBox,,Update,Getting Update,2
		get_latest_version()
	} else {
		IniRead, version_str, setting.ini, update, ver, "0"
		if(version_str!=version) {
			IniWrite, % version, setting.ini, update, ver
			; MsgBox, % version "`nUpdate log`n`n" update_log
		}
	}
} else {
	TrayTip, Update,Update Skiped`n跳过升级`n`nCurrent version`n当前版本`nv%version%
	; MsgBox,,Update,Update Skiped`n`nCurrent version`nv%version%,2
}

get_latest_version(){
	global
	req := ComObjCreate("MSXML2.ServerXMLHTTP")
	updateMirror:=updateMirror+0
	if(updateMirror > mirrorList.Length() or updateMirror <= 0) {
		updateMirror := 1
	}
	updateSite:=mirrorList[updateMirror]
	updateReqDone:=0
	req.open("GET", updateSite downloadUrl versionFilename, true)
	req.onreadystatechange := Func("updateReady")
	req.send()
	SetTimer, updateTimeout, -10000
	Return
	updateTimeout:
	tryNextUpdate()
	Return
}
tryNextUpdate()
{
	global mirrorList, updateMirror, updatemirrorTried
	updatemirrorTried.Push(updateMirror)
	SetTimer, updateTimeout, Off
	For k, v in mirrorList
	{
		tested:=False
		for _, p in updatemirrorTried
		{
			if(p=k) {
				tested:=True
				break
			}
		}
		if not tested {
			updateMirror:=k
			get_latest_version()
			Return
		}
	}
	TrayTip, , % "Update failed`n`n更新失败",, 0x3
}

; with MSXML2.ServerXMLHTTP method, there would be multiple callback called
updateReady(){
	global req, version, updateReqDone, updateSite, downloadUrl, downloadFilename
	; log("update req.readyState=" req.readyState, 1)
    if (req.readyState != 4){  ; Not done yet.
        return
	}
	if(updateReqDone){
		; log("state already changed", 1)
		Return
	}
	updateReqDone := 1
	; log("update req.status=" req.status, 1)
    if (req.status == 200){ ; OK.
		SetTimer, updateTimeout, Off
        ; MsgBox % "Latest version: " req.responseText
		RegExMatch(version, "(\d+)\.(\d+)\.(\d+)", verNow)
		RegExMatch(req.responseText, "^(\d+)\.(\d+)\.(\d+)$", verNew)
		if((verNew1>verNow1)
		|| (verNew1==verNow1 && ((verNew2>verNow2)
			|| (verNew2==verNow2 && verNew3>verNow3)))){
			MsgBox, 0x24, Download, % "Found new version " req.responseText ", download?`n`n发现新版本 " req.responseText " 是否下载?"
			IfMsgBox Yes
			{
				try {
					UrlDownloadToFile, % updateSite downloadUrl downloadFilename, % "./" downloadFilename
					MsgBox, ,, % "Download finished`n更新下载完成`n`nProgram will restart now`n软件即将重启", 3
					IniWrite, % A_MM A_DD, setting.ini, update, last
					FileInstall, updater.exe, updater.exe, 1
					Run, updater.exe
					ExitApp
				} catch e {
					MsgBox, 16,, % "Upgrade failed`nAn exception was thrown!`nSpecifically: " e
				}
			}
		} else {
			; MsgBox, ,, % "Current version: v" version "`n`nIt is the latest version`n`n软件已是最新版本", 2
			IniWrite, % A_MM A_DD, setting.ini, update, last
		}
	} else {
		tryNextUpdate()
        ; MsgBox, 16,, % "Update failed`n`n更新失败`n`nStatus=" req.status
	}
}

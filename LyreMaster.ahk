
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance ignore
#include meta.ahk

SetKeyDelay, 1, 1 
SendMode event

outputVersion()
if A_IsCompiled
debug:=0
Else
debug:=1
UAC()

; q w e r t y u
; a s d f g h j
; z x c v b n m
#include update.ahk
menu()
OnExit, trueExit

hotkey_list:="qwertyuasdfghjzxcvbnm"
isBtn1Playing:=0
chord_keydown:=0
#Include gui.ahk
Return

genshin_window_exist()
{
	genshinHwnd := WinExist("ahk_exe GenshinImpact.exe")
	if not genshinHwnd
	{
		genshinHwnd := WinExist("ahk_exe YuanShen.exe")
	}
	return genshinHwnd
}

genshin_window_active(hwnd)
{
	WinActivate, ahk_id %hwnd%
	Return hwnd
}

titleMove:
PostMessage 0xA1, 2
Return

func_btn_play:
if(isBtn1Playing=0)
{
	Gosub, main_start
}
Else
{
	Gosub, main_stop
}
Return

func_btn_exit:
Exit:
ExitApp

winMove:
PostMessage, 0xA1, 2
Return

main_start:
Gosub, resolve
Gosub, hotkey_enable
Return

main_stop:
Gosub, hotkey_disable
Return

key_scan:
_keydown:=0
Loop, Parse, hotkey_list
{
	_keydown+=GetKeyState(A_LoopField, "P")
}
chord_keydown:=_keydown
if(chord_key_wait_up)
{
	if not chord_keydown
	{
		genshin_play_p+=1
		SetTimer, key_scan, Off
		key_scan_enable:=0
		chord_key_wait_up:=0
	}
	Return
}
if(chord_keydown=StrLen(genshin_play_array[genshin_play_p]))
{
	chord_key_wait_up:=1
	SendInput, % genshin_play_array[genshin_play_p]
}
Return

note_key_down:
; 硬核模式下，追踪已按下的键的状态
; 确保按下和弦相同的按键数量后才发送按键
_thishotkey:=A_ThisHotkey
if (ishardcore=1) and StrLen(genshin_play_array[genshin_play_p])>1
{
	if not key_scan_enable
	{
		key_scan_enable:=1
		SetTimer, key_scan, 10
	}
}
Else
{
	SendInput, % genshin_play_array[genshin_play_p]
	genshin_play_p+=1
	KeyWait, % SubStr(_thishotkey, 0)
}
if(genshin_play_p >= genshin_play_array.Length())
{
	; 演奏结束
	; 取消热键绑定
	Gosub, hotkey_disable
}
Return

hotkey_enable:
hgame:=genshin_window_exist()
if(!hgame){
	MsgBox, 0x41010,,Genshin is not running!!!
	Return
	Return
}
isBtn1Playing:=1
btn1update()
genshin_play_p := 1
Hotkey, IfWinActive, ahk_id %hgame%
Loop, Parse, hotkey_list
{
	Hotkey, % "$" A_LoopField, note_key_down, on
}
Hotkey, If
Return

hotkey_disable:
isBtn1Playing:=0
btn1update()
Hotkey, IfWinActive, ahk_id %hgame%
Loop, Parse, hotkey_list
{
	Hotkey, % "$" A_LoopField, Off
}
Hotkey, If
Return

dms_parser(v)
{
	comment:=""
	sheet:=""
	isSheet:=0
	Loop, Parse, v, `n, `r
	{
		IfInString, A_LoopField, ======
		{
			isSheet:=1
			Continue
		}
		if isSheet=0
		{
			comment.=A_LoopField "`r`n"
		}
		Else
		{
			sheet.=A_LoopField "`r`n"
		}
	}
	if isSheet=0
	{
		Return ["", comment]
	}
	Return [comment, sheet]
}

resolve:
Gui, submit, NoHide
ishardcore:=hardcore
StringLower, txt, editer

parse_content:=dms_parser(txt)[2]

genshin_play_array:={}
chord:=0
Loop, Parse, parse_content, `n,%A_Space%%A_Tab%	;逐行解析
{
	currentLine:=A_LoopField
	Loop, Parse, currentLine, ,%A_Space%%A_Tab%
	{
		If(RegExMatch(A_LoopField,"iS)[qwertyuasdfghjzxcvbnm]",notes))	;解析音符
		{
			If chord=0
			{
				genshin_play_array.Push(notes)
			}
			Else
			{
				chord_buffer.=notes
			}
		}
		If(RegExMatch(A_LoopField,"iS)(\(|\))",mark))	;解析括号
		{
			If(mark1="(" And chord=0)
			{
				chord:=1
				chord_buffer:=""
			}
			Else If(mark1=")" And chord=1)
			{
				chord:=0
				genshin_play_array.Push(chord_buffer)
			}
		}
	}
}
Return

GuiClose:
ExitApp
trueExit:
ExitApp

#If debug
F5::ExitApp
F6::Reload
#If
F9::Gosub, main_start
F8::Gosub, main_stop

free(ByRef var)
{
	VarSetCapacity(var, 0)
}

UAC()
{
	full_command_line := DllCall("GetCommandLine", "str")
	if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)"))
	{
		try
		{
			if A_IsCompiled
				Run *RunAs "%A_ScriptFullPath%" /restart
			else
				Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%"
		}
		ExitApp
	}
}
#Include menu.ahk

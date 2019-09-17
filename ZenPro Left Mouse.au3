#RequireAdmin
#include <AutoItConstants.au3>

HotKeySet("z", "LClick")
HotKeySet("x", "RClick")

Global $Toggle = False
Global Const $VK_SCROLL = 0x91

Main()

Func LClick()
	If $Toggle Then
		MouseClick($MOUSE_CLICK_LEFT)
	Else
		Send("z", $SEND_RAW)
	EndIf
EndFunc

Func RClick()
	If $Toggle Then
		MouseClick($MOUSE_CLICK_RIGHT)
	Else
		Send("x", $SEND_RAW)
	EndIf
EndFunc

Func _GetScrollLock()
    Local $ret
    $ret = DllCall("user32.dll","long","GetKeyState","long",$VK_SCROLL)
    Return $ret[0]
EndFunc   ;==>_GetScrollLock

Func Main()
	While 1
		$Toggle = _GetScrollLock()
	WEnd
EndFunc

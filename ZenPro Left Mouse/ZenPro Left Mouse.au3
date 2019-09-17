#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=C:\Program Files (x86)\AutoIt3\Aut2Exe\Icons\AutoIt_Main_v11_256x256_RGB-A.ico
#AutoIt3Wrapper_Res_Description=Allows using the Z and X keys on the keyboard as left and right click respectively when Scroll Lock is enabled.
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_ProductName=ZenPro Left Mouse
#AutoIt3Wrapper_Res_ProductVersion=1.0.0.0
#AutoIt3Wrapper_Res_LegalCopyright=Robert Maehl (rcmaehl)
#AutoIt3Wrapper_Res_Language=1033
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <Misc.au3>
#include <AutoItConstants.au3>

Main()

Func _GetScrollLock()
    Local $ret
	Local Const $VK_SCROLL = 0x91
    $ret = DllCall("user32.dll","long","GetKeyState","long",$VK_SCROLL)
    Return $ret[0]
EndFunc   ;==>_GetScrollLock

Func NullFunc()
EndFunc

Func Main()

	Local $hDLL = DllOpen("user32.dll")
	Local $aKey[2] = [False,False]

	While 1
		If _GetScrollLock() Then
			; Block Text Being Sent to Inputs
			HotKeySet("z", "NullFunc")
			HotKeySet("x", "NullFunc")

			; Handle Z Press for Left Clickz
			If _IsPressed("5A", $hDLL) Then
				If Not $aKey[0] Then
					$aKey[0] = True
					MouseDown("Left")
				EndIf
			Else
				If $aKey[0] Then MouseUp("Left")
				$aKey[0] = False
			EndIf

			; Handle X Press for Right Click
			If _IsPressed("58", $hDLL) Then
				If Not $aKey[1] Then
					$aKey[1] = True
					MouseDown("Right")
				EndIf
			Else
				If $aKey[1] Then MouseUp("Right")
				$aKey[1] = False
			EndIf

		Else
			; Unblock Text Sending
			HotKeySet("z")
			HotKeySet("x")
		EndIf

	WEnd
	DllClose($hDLL)
EndFunc
#RequireAdmin
#include ".\Includes\_GetSteam.au3"

#include <Process.au3>
#include <WinAPIProc.au3>
#include <GuiListView.au3>
#include <TrayConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <ListViewConstants.au3>

Opt("SendKeyDelay", 0)
Opt("TrayIconHide", 1)
Opt("TrayMenuMode", 1)
Opt("TrayAutoPause", 0)
Opt("GUICloseOnESC", 0)
Opt("GUIResizeMode", $GUI_DOCKALL)

Main()

Func Main()

	Local $aApp[2]
	Local $hLibrary = ""

	Local $hGUI = GUICreate("Steam Update Freeze", 640, 320, -1, -1, BitOr($WS_MINIMIZEBOX, $WS_CAPTION, $WS_SYSMENU))

	#Region ; File Menu
	Local $hMenu1 = GUICtrlCreateMenu("File")
;	GUICtrlCreateMenuItem("", $hMenu1)
	Local $hQuit = GUICtrlCreateMenuItem("Quit", $hMenu1)
	#EndRegion


	#Region ; Dummy Controls
	Local $hRefresh = GUICtrlCreateDummy()
	Local $hInterrupt = GUICtrlCreateDummy()
	#EndRegion

	Local $aHotkeys[3][2] = [["{F5}", $hRefresh], ["{PAUSE}", $hInterrupt], ["{BREAK}", $hInterrupt]]
	GUISetAccelerators($aHotkeys)

	#Region ; Games List
	GUICtrlCreateGroup("Game Selection", 0, 0, 400, 280)
	GUICtrlCreateTabItem("Steam Games")
	Local $hGames = GUICtrlCreateListView("AppID" & @TAB & "|" & "Game Name", 0, 15, 400, 280, $LVS_REPORT+$LVS_SINGLESEL, $LVS_EX_GRIDLINES+$LVS_EX_FULLROWSELECT+$LVS_EX_DOUBLEBUFFER)
		_GUICtrlListView_RegisterSortCallBack($hGames)
		GUICtrlSetTip(-1, "Refresh", "Press F5 to Refresh")

	_GetSteamGames($hGames, $hLibrary)
	_GUICtrlListView_SortItems($hGames, 1)
	#EndRegion

	#Region ; Update Freezes
	GUICtrlCreateGroup("Update Prevention Tools", 400, 0, 240, 320)

	$hOfflineM = GUICtrlCreateButton("Patch Steam Config and Launch Steam in Offline Mode"             , 410,  15, 220, 40, $BS_MULTILINE)
	$hSkipMode = GUICtrlCreateButton("Launch Steam Console and Enable Update Skipping for this Session", 410,  60, 220, 40, $BS_MULTILINE)
	$hCloneApp = GUICtrlCreateButton("Clone Game Files and Launch Game Clone"                          , 410, 105, 220, 40, $BS_MULTILINE)
	$hManifest = GUICtrlCreateButton("Patch Game Manifest File and Launch Game"                        , 410, 150, 220, 40, $BS_MULTILINE)

	#EndRegion

	GUISetAccelerators($aHotkeys)

	GUISetState(@SW_SHOW, $hGUI)

	While 1

		$hMsg = GUIGetMsg()
		$hTMsg = TrayGetMsg()

		Select

			Case $hMsg = $GUI_EVENT_CLOSE or $hMsg = $hQuit
				_GUICtrlListView_UnRegisterSortCallBack($hGames)
				GUIDelete($hGUI)
				Exit

			Case $hMsg = $hInterrupt
				$bInterrupt = True

			Case $hMsg = $GUI_EVENT_MINIMIZE
				Opt("TrayIconHide", 0)
				TraySetToolTip("Steam Update Freeze")
				GUISetState(@SW_HIDE, $hGUI)

			Case $hTMsg = $TRAY_EVENT_PRIMARYUP
				Opt("TrayIconHide", 1)
				GUISetState(@SW_SHOW, $hGUI)

			Case $hMsg = $hGames
				_GetSteamGames($hGames, $hLibrary)
				_GUICtrlListView_SortItems($hGames, GUICtrlGetState($hGames))

			Case $hMsg = $hRefresh
				_GetSteamGames($hGames, $hLibrary)
				_GUICtrlListView_SortItems($hGames, 1)

			Case $hMsg = $hOfflineM ; https://gaming.stackexchange.com/questions/19234/is-there-any-way-to-start-steam-in-offline-mode-without-logging-in-first
				ProcessClose("Steam.exe")
				ProcessClose("SteamService.exe")
				ProcessClose("SteamWebHelper.exe")

			Case $hMsg = $hSkipMode ; https://steamcommunity.com/sharedfiles/filedetails/?id=885555151
				ShellExecute("steam://open/console")
				WinWaitActive("Steam")
				BlockInput(True)
				Send("@AllowSkipGameUpdate 1{Enter}")
				ShellExecute("steam://open/games")
				BlockInput(False)

			Case $hMsg = $hCloneApp
				$aApp = StringSplit(GUICtrlRead(GUICtrlRead($hGames)), "|", $STR_NOCOUNT)
				If $aApp[0] = "0" Then
					;;;
				Else
					;;; Add File Cloning Functionality Here
				EndIf
				$aApp = ""

			Case $hMsg = $hManifest ; https://steamcommunity.com/sharedfiles/filedetails/?id=885555151
				$aApp = StringSplit(GUICtrlRead(GUICtrlRead($hGames)), "|", $STR_NOCOUNT)
				If $aApp[0] = "0" Then
					;;;
				Else
					;;; Add Manifest Patching Functionality Here
					ShellExecute("steam://rungameid/" & $aApp[0])
				EndIf
				$aApp = ""

		EndSelect
	WEnd
EndFunc

Func _GetSteamGames($hControl, $hLibrary)

	_GUICtrlListView_DeleteAllItems($hControl)

	If $hLibrary = "" Then
		Local $aSteamLibraries = _GetSteamLibraries()
	Else
		Local $aSteamLibraries = _GetSteamLibraries($hLibrary)
	EndIf
	Local $aSteamGames
	For $iLoop1 = 1 To $aSteamLibraries[0] Step 1
		$aSteamGames = _SteamGetGamesFromLibrary($aSteamLibraries[$iLoop1])
		If $aSteamGames[0][0] = 0 Then ContinueLoop
		$aSteamGames[0][1] = $aSteamGames[0][0]
		Do
			$iDelete = _ArraySearch($aSteamGames, "")
			If $iDelete = -1 Then
				;;;
			Else
				$aSteamGames[0][0] = $aSteamGames[0][0] - 1
			EndIf
			_ArrayDelete($aSteamGames, $iDelete)
		Until _ArraySearch($aSteamGames, "") = -1
		For $iLoop2 = 1 To $aSteamGames[0][0] Step 1
			GUICtrlCreateListViewItem($aSteamGames[$iLoop2][0] & "|" & $aSteamGames[$iLoop2][1], $hControl)
		Next
	Next
	_ArrayDelete($aSteamGames, 0)
	For $i = 0 To _GUICtrlListView_GetColumnCount($hControl) Step 1
		_GUICtrlListView_SetColumnWidth($hControl, $i, $LVSCW_AUTOSIZE_USEHEADER)
	Next

EndFunc

Func _IsChecked($idControlID)
	Return BitAND(GUICtrlRead($idControlID), $GUI_CHECKED) = $GUI_CHECKED
EndFunc   ;==>_IsChecked
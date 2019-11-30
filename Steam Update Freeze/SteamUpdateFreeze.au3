#include ".\Includes\_GetSteam.au3"

Opt("TrayIconHide", 1)
Opt("TrayMenuMode", 1)
Opt("TrayAutoPause", 0)
Opt("GUICloseOnESC", 0)
Opt("GUIResizeMode", $GUI_DOCKALL)

Main()

Func Main()

	Local $hLibrary = ""

	Local $hGUI = GUICreate("Steam Update Freeze", 640, 480, -1, -1, BitOr($WS_MINIMIZEBOX, $WS_CAPTION, $WS_SYSMENU))

	#Region ; Dummy Controls
	Local $hRefresh = GUICtrlCreateDummy()
	Local $hInterrupt = GUICtrlCreateDummy()
	#EndRegion

	$hQuickTabs = GUICreate("", 360, 300, 280, 0, $WS_POPUP, $WS_EX_MDICHILD, $hGUI)

	Local $aHotkeys[3][2] = [["{F5}", $hRefresh], ["{PAUSE}", $hInterrupt], ["{BREAK}", $hInterrupt]]
	GUISetAccelerators($aHotkeys)

	$hTabs = GUICtrlCreateTab(0, 0, 360, 300)

	#Region ; Process List
	GUICtrlCreateTabItem($_sLang_RunningTab)
	Local $bPHidden = False
	Local $hProcesses = GUICtrlCreateListView($_sLang_ProcessList & "|" & $_sLang_ProcessTitle, 0, 20, 360, 280, $LVS_REPORT+$LVS_SINGLESEL, $LVS_EX_GRIDLINES+$LVS_EX_FULLROWSELECT+$LVS_EX_DOUBLEBUFFER+$LVS_EX_FLATSB)
		_GUICtrlListView_RegisterSortCallBack($hProcesses)
		GUICtrlSetTip(-1, $_sLang_RefreshTip, $_sLang_Usage)

	_GetProcessList($hProcesses)
	_GUICtrlListView_SortItems($hProcesses, 0)
	#EndRegion

	#Region ; Games List
	GUICtrlCreateTabItem($_sLang_GamesTab)
	Local $hGames = GUICtrlCreateListView($_sLang_GameID & "|" & $_sLang_GameName, 0, 20, 360, 280, $LVS_REPORT+$LVS_SINGLESEL, $LVS_EX_GRIDLINES+$LVS_EX_FULLROWSELECT+$LVS_EX_DOUBLEBUFFER)
		_GUICtrlListView_RegisterSortCallBack($hGames)
		GUICtrlSetTip(-1, $_sLang_RefreshTip, $_sLang_Usage)

	_GetSteamGames($hGames, $hLibrary)
	_GUICtrlListView_SortItems($hGames, 1)
	#EndRegion
  
  	#Region ; Exclusion List
	GUICtrlCreateTabItem($_sLang_ExclusionsTab)
	Local $hExclusions = GUICtrlCreateListView($_sLang_ProcessList, 0, 20, 360, 280, $LVS_REPORT+$LVS_SINGLESEL, $LVS_EX_GRIDLINES+$LVS_EX_FULLROWSELECT+$LVS_EX_DOUBLEBUFFER)
		_GUICtrlListView_RegisterSortCallBack($hExclusions)
		GUICtrlSetTip(-1, $_sLang_RefreshTip, $_sLang_Usage)

	$aExclusions = _GetExclusionsList($hExclusions)
	_GUICtrlListView_SortItems($hExclusions, 0)
	#EndRegion

	GUICtrlCreateTabItem("")
	GUISwitch($hGUI)

	GUISetAccelerators($aHotkeys)

	WinMove($hGUI, "", Default, Default, 285, 345, 1)
	GUISetState(@SW_SHOW, $hGUI)

	While 1

		$hMsg = GUIGetMsg()
		$hTMsg = TrayGetMsg()

		Select

			Case $hMsg = $GUI_EVENT_CLOSE or $hMsg = $hQuit
				_GUICtrlListView_UnRegisterSortCallBack($hGames)
				_GUICtrlListView_UnRegisterSortCallBack($hProcesses)
				_GUICtrlListView_UnRegisterSortCallBack($hExclusions)
				GUIDelete($hQuickTabs)
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

			Case $hMsg = $hProcesses
				_GetProcessList($hProcesses)
				_GUICtrlListView_SortItems($hProcesses, GUICtrlGetState($hProcesses))

			Case $hMsg = $hGames
				_GetSteamGames($hGames, $hLibrary)
				_GUICtrlListView_SortItems($hGames, GUICtrlGetState($hGames))

			Case $hMsg = $hExclusions
				$aExclusions = _GetExclusionsList($hExclusions)
				_GUICtrlListView_SortItems($hExclusions, GUICtrlGetState($hExclusions))

			Case $hMsg = $hRefresh
				Switch GUICtrlRead($hTabs)
					Case 0
						_GetProcessList($hProcesses)
						_GUICtrlListView_SortItems($hProcesses, 0)
					Case 1
						_GetSteamGames($hGames, $hLibrary)
						_GUICtrlListView_SortItems($hGames, 1)
					Case 2
						$aExclusions = _GetExclusionsList($hExclusions)
				EndSwitch

		EndSelect
	WEnd
EndFunc

Func _GetProcessList($hControl)

	_GUICtrlListView_DeleteAllItems($hControl)
	Local $aWindows = WinList()
	Do
		$iDelete = _ArraySearch($aWindows, "Default IME")
		_ArrayDelete($aWindows, $iDelete)
	Until _ArraySearch($aWindows, "Default IME") = -1
	Do
		$iDelete = _ArraySearch($aWindows, "")
		_ArrayDelete($aWindows, $iDelete)
	Until _ArraySearch($aWindows, "") = -1
	$aWindows[0][0] = UBound($aWindows)
	For $Loop = 1 To $aWindows[0][0] - 1
		$aWindows[$Loop][1] = _ProcessGetName(WinGetProcess($aWindows[$Loop][1]))
		GUICtrlCreateListViewItem($aWindows[$Loop][1] & "|" & $aWindows[$Loop][0], $hControl)
	Next
	_ArrayDelete($aWindows, 0)
	For $i = 0 To _GUICtrlListView_GetColumnCount($hControl) Step 1
		_GUICtrlListView_SetColumnWidth($hControl, $i, $LVSCW_AUTOSIZE_USEHEADER)
	Next
;	_GUICtrlListView_SortItems($hControl, GUICtrlGetState($hControl))

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

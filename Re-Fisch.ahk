;====================================================================================================;
;
;   Re:Fisch  -  Alpha 2.3
;   A fishing macro for Fisch (Roblox). Made by bai. Personal use.
;
;   CREDITS  (also shown in the About tab)
;     - The special-rod handlers are adapted from DeepFish by Yato. DeepFish's licence allows reusing parts of
;       it in another project as long as "Yato" is credited visibly in that project's interface,
;       which Re:Fisch does on its About tab. Those parts stay under Yato's terms, reproduced
;       below.
;     - Precision / Lines steering: the method (PD control with velocity tracking and a stopping
;       distance) is AsphaltCake's, from IRUS IDIOTPROOF / IRUS COMET (youtube.com/@AsphaltCake),
;       shared under AsphaltCake's terms with attribution; Re:Fisch's code for it is its own.
;     - New in Re:Fisch: the fishing cycle (start, setup, cast, perfect cast, shake), the timing
;       helpers and the screen-capture layer, reel detection (bar, fish, arrow, the UI-edge
;       gate), the reel minigame loop and its steering, the live reel display, the interface, settings
;       and profile store, the drawn interface (sidebar, rounded tabs / cards / buttons), live dashboard, status overlay, Auto Totem, Auto Appraise (Windows OCR helper),
;       session stats, Kitty Keys skin support and the x64 speed kernels.
;
;   Automating a game may break its rules. You use this at your own risk.
;
;====================================================================================================;
;
;   Licence of the parts adapted from DeepFish, kept verbatim:
;====================================================================================================;
;
;   DeepFish BETA
;   Copyright (c) 2026 Yato. All rights reserved.
;
;   YOU MAY:
;     - Use this macro for your own personal use.
;     - Read the source and reuse PARTS of it in your own projects, provided that "Yato" is
;       credited visibly somewhere in that project's user interface.
;
;   YOU MAY NOT:
;     - Redistribute this macro, modified or unmodified, in whole or in substantial part.
;     - Publish a modified build of it, or present it as your own work.
;     - Remove, hide or alter the credits shown in the About tab.
;     - Sell it, or put it behind payment, subscription or paid access of any kind.
;
;   PORTIONS FROM OTHER PROJECTS
;     Precision/Lines mode's control method (PD steering with velocity tracking and stopping
;     distance) is adapted from IRUS IDIOTPROOF, IRUS COMET by AsphaltCake.
;       Source:  https://www.youtube.com/@AsphaltCake
;     Those portions remain subject to AsphaltCake's own terms, which permit sharing
;     modifications with attribution. The restrictions above apply to Yato's original work
;     and cannot and do not override AsphaltCake's terms for their part.
;
;     Changes made to that method in this macro: reimplemented in AutoHotkey v1; driven by
;     this macro's own GDI capture and color-calibration code; extended with an arrow-based
;     fallback for when the bar itself is not visible.
;
;   NO WARRANTY
;     Provided "as is", without warranty of any kind. Automating a game may breach its rules.
;     You use this at your own risk, and the author accepts no responsibility for any
;     consequence to your account.
;
;====================================================================================================;

#SingleInstance Force
#MaxThreadsPerHotkey 2

DFBetaVersion := "1.1.7-refisch-r10.3-ui-restore"
RfVersion := "Alpha 2.3"          ; shown in the sidebar, About, logs; the updater compares it (RfVerCmp)

setkeydelay, -1
setmousedelay, -1
setbatchlines, -1
SetTitleMatchMode 2

CoordMode, Tooltip, Relative
CoordMode, Pixel, Client
CoordMode, Mouse, Client


DllCall("QueryPerformanceFrequency", "Int64*", QpcFreq)
if (!QpcFreq)
	QpcFreq := 10000000
LineHitsFn()


RfDataDir := A_ScriptDir . "\Re-Fisch"
ProfilesDir := RfDataDir . "\profiles"
SettingsFile := RfDataDir . "\settings.ini"
DefaultProfileFile := ProfilesDir . "\Default.ini"

ProfileFields := []
ProfileFields.Push( ["General","AutoLowerGraphics","true","bool"]
                  , ["General","AutoGraphicsDelay","50","num"]
                  , ["General","AutoZoomInCamera","true","bool"]
                  , ["General","AutoZoomDelay","50","num"]
                  , ["General","AutoEnableCameraMode","true","bool"]
                  , ["General","AutoCameraDelay","5","num"]
                  , ["General","AutoLookDownCamera","true","bool"]
                  , ["General","AutoLookDelay","200","num"]
                  , ["General","AutoBlurCamera","false","bool"]
                  , ["General","AutoBlurDelay","50","num"]
                  , ["General","RestartDelay","1000","num"]
                  , ["General","HoldRodCastDuration","1000","num"]
                  , ["General","WaitForBobberDelay","1000","num"]
                  , ["General","NavigationKey","\","str"]
                  , ["General","RodSlotKey","1","str"]
                  , ["General","BagSlotKey","2","str"]
                  , ["General","UnstickAfter","2","num"] )
ProfileFields.Push( ["Cast","CastMode","Normal","castmode"]
                  , ["Cast","PerfectGreenColor","0x60AA4A","str"]
                  , ["Cast","PerfectWhiteColor","0xFFFEF3","str"]
                  , ["Cast","PerfectGreenTolerance","0","num"]
                  , ["Cast","PerfectWhiteTolerance","0","num"]
                  , ["Cast","PerfectFailTimeout","20","num"]
                  , ["Cast","PerfectReleaseTiming","0","num"]
                  , ["Cast","PerfectWaitCycles","0","num"] )
ProfileFields.Push( ["Shake","ShakeMode","Navigation","shakemode"]
                  , ["Shake","FishBarColorTolerance","3","num"]
                  , ["Shake","ShakeAreaLeftPct","21","num"]
                  , ["Shake","ShakeAreaRightPct","79","num"]
                  , ["Shake","ShakeAreaTopPct","25","num"]
                  , ["Shake","ShakeAreaBottomPct","88","num"]
                  , ["Shake","NavigationShakeFailsafe","30","num"]
                  , ["Shake","NavigationSpamDelay","10","num"] )
ProfileFields.Push( ["Minigame","ControlMode","Precision","controlmode"]
                  , ["Minigame","BarCalculationFailsafe","60","num"]
                  , ["Minigame","FishColor","0x434B5B","str"]
                  , ["Minigame","BarLeftColor","0xF1F1F1","str"]
                  , ["Minigame","BarRightColor","0xF1F1F1","str"]
                  , ["Minigame","BarColorTolerance","3","num"]
                  , ["Minigame","ArrowColor","0x848587","str"]
                  , ["Minigame","ArrowColorTolerance","3","num"]
                  , ["Minigame","StabilizerLoop","10","num"]
                  , ["Minigame","SideBarRatio","0.8","num"]
                  , ["Minigame","SideBarWaitMultiplier","4.5","num"]
                  , ["Minigame","SpecialRod","None","specialrod"]
                  , ["Minigame","RemembranceMode","Living","remembrancemode"]
                  , ["Minigame","NoteColor","0xB2CFFF","str"]
                  , ["Minigame","NoteColorTolerance","15","num"]
                  , ["Minigame","NoteBias","100","num"]
                  , ["Minigame","NoteRegionHeight","1000","num"]
                  , ["Minigame","NoteHandoff","50","num"]
                  , ["Minigame","LullRadiusPct","16","num"]
                  , ["Minigame","LullPivotUp","26","num"]
                  , ["Minigame","LullLightLum","90","num"]
                  , ["Minigame","LullArmDelta","45","num"]
                  , ["Minigame","LullTrigPct","10","num"]
                  , ["Minigame","LullClearMs","100","num"]
                  , ["Minigame","LullMinDeg","4","num"]
                  , ["Minigame","ReelMinHold","200","num"]
                  , ["Minigame","ReelMinRelease","200","num"]
                  , ["Minigame","ManiaLead","45","num"] )
ProfileFields.Push( ["Rods","TryhardBarColors","","str"]
				  , ["Rods","TryhardBarTol","20","num"]
				  , ["Rods","TryhardFishColors","","str"]
				  , ["Rods","TryhardFishTol","14","num"]
				  , ["Rods","TryhardTrackColors","","str"]
				  , ["Rods","TryhardTrackTol","20","num"]
				  , ["Rods","CastboundBarColors","","str"]
				  , ["Rods","CastboundBarTol","20","num"]
				  , ["Rods","CastboundFishColors","0x5522A3","str"]
				  , ["Rods","CastboundFishTol","20","num"]
				  , ["Rods","CastboundTrackColors","","str"]
				  , ["Rods","CastboundTrackTol","20","num"]
				  , ["Rods","HalibutPlayMinigame","true","bool"]
				  , ["Rods","SwClickSigns","true","bool"]
				  , ["Rods","SwFastClicks","false","bool"]
				  , ["Rods","SwRetryClicks","false","bool"]
				  , ["Rods","StellarBarColors","0x55446D","str"]
				  , ["Rods","StellarBarTol","26","num"]
				  , ["Rods","StellarFishColors","0xAFDAE8","str"]
				  , ["Rods","StellarFishTol","22","num"]
				  , ["Rods","StellarHeadColors","0xFFFFFF","str"]
				  , ["Rods","StellarHeadTol","30","num"] )
ProfileFields.Push( ["Rods","StellarSkin","Default","stellarskin"]
                  , ["Rods","KittyKeysEnabled","false","bool"]
                  , ["Rods","KittyClickSigns","true","bool"]
                  , ["Rods","KittyRimTol","35","num"]
                  , ["Rods","KittySignColors","0x9677B9","str"]
                  , ["Rods","KittySignTol","24","num"]
                  , ["Rods","KittyShapeMin","55","num"]
                  , ["Rods","KittyShapeMargin","10","num"]
                  , ["Rods","KittyConfirmMs","80","num"]
                  , ["Rods","KittyClickSpeed","Fast","kittyspeed"] )
ProfileFields.Push( ["Tuning","StableRightMultiplier","2.1","num"]
                  , ["Tuning","StableRightDivision","1.4","num"]
                  , ["Tuning","StableLeftMultiplier","1.1","num"]
                  , ["Tuning","StableLeftDivision","1.0","num"]
                  , ["Tuning","UnstableRightMultiplier","2.4","num"]
                  , ["Tuning","UnstableRightDivision","1.5","num"]
                  , ["Tuning","UnstableLeftMultiplier","1.3","num"]
                  , ["Tuning","UnstableLeftDivision","1.1","num"]
                  , ["Tuning","RightAnkleBreakMultiplier","1","num"]
                  , ["Tuning","LeftAnkleBreakMultiplier","0.9","num"]
                  , ["Tuning","Kp","0.5","num"]
                  , ["Tuning","Kd","0.3","num"]
                  , ["Tuning","VelocitySmoothing","0.2","num"]
                  , ["Tuning","StoppingDistanceMultiplier","3.0","num"]
                  , ["Tuning","HumanClicks","false","bool"]
                  , ["Tuning","HumanCps","8","num"] )
ProfileFields.Push( ["Keeper","KeeperAuto","false","bool"]
                  , ["Keeper","KeeperEveryCatches","20","num"]
                  , ["Keeper","KeeperRecharges","1","num"]
                  , ["Keeper","KeeperRelicKey","","str"]
                  , ["Keeper","KeeperInvKey","g","str"]
                  , ["Keeper","KeeperEnchantX","0","num"]
                  , ["Keeper","KeeperEnchantY","0","num"]
                  , ["Keeper","KeeperConfirmX","0","num"]
                  , ["Keeper","KeeperConfirmY","0","num"]
                  , ["Keeper","KeeperBetweenDelay","2000","num"]
                  , ["Keeper","KeeperStepDelay","100","num"]
                  , ["Keeper","KeeperOpenDelay","100","num"] )
ProfileFields.Push( ["Aquarium","AquariumAuto","false","bool"]
                  , ["Aquarium","AquariumEveryMin","63","num"]
                  , ["Aquarium","AquariumFoodCount","12","num"]
                  , ["Aquarium","AquariumMaxBuys","8","num"]
                  , ["Aquarium","AquariumStepDelay","320","num"]
                  , ["Aquarium","AquariumOpenDelay","1500","num"]
                  , ["Aquarium","AquariumScrollSteps","14","num"] )
ProfileFields.Push( ["Totem","TotemAuto","false","bool"]
                  , ["Totem","TotemPollSec","20","num"]
                  , ["Totem","TotemActDelay","2500","num"]
                  , ["Totem","TotemKeySundial","","str"]
                  , ["Totem","TotemKeyClearcast","","str"]
                  , ["Totem","TotemKeyTempest","","str"]
                  , ["Totem","TotemKeyWindset","","str"]
                  , ["Totem","TotemKeySmokescreen","","str"]
                  , ["Totem","TotemKeyEclipse","","str"]
                  , ["Totem","TotemKeyAurora","","str"]
                  , ["Totem","TotemKeyStarfall","","str"]
                  , ["Totem","TotemKeyShiny","","str"]
                  , ["Totem","TotemKeySparkling","","str"]
                  , ["Totem","TotemKeyMutation","","str"]
                  , ["Totem","TotemSel1","Aurora","totemsel"]
                  , ["Totem","TotemSel2","None","totemsel"]
                  , ["Totem","TotemSel3","None","totemsel"] )

gosub, EnsureConfigFiles
gosub, LoadSettingsFile
gosub, LoadActiveProfile
gosub, RfUtilitiesOff

ReFishSpaceDown := false
OnExit("ReFishExit")
ReFishTipSeen := {}
SetTimer, ReFishThemeTips, 200
KittyLogBuffer := ""
SetTimer, ReFishLogTimer, 500
SetTimer, ReFishInputWatchdog, 20
MacroRunning := false
MacroPaused := false
NoteNeeded := false
NoteFresh := true
NoteBlitAt := 0
NoteRefreshMs := 55
NoteMissAt := 0
NoteMissN := 0
TargetIsNote := false
CastHolding := false
MgInPlay := false
MacroPreview := false
RunKeysArmed := false
SectionBuilt := {}
ControlModeDdl := 0
NoteIndep := false
NoteOriginX := 0
NoteOriginY := 0
MgScore := 0
MgConf := 0
MgSawBar := false
MgSawFish := false
MgSawArrow := false
RfHudReset()
BarWTrust := 0
; ==============================================================================================
TargetSection := ""
MgBlocks := {}
MgVisible := {}
MgAllCtrls := []
AllManaged := []
VisibleCtrls := []
CtrlBaseX := {}
CtrlBaseY := {}
CtrlW := {}
CtrlH := {}
CtrlRgnR := {}
CtrlClip := {}
SbTrack := 0
SbThumb := 0
SbTrackH := 0
SbThumbH := 0
SbShown := -1
ContentTopEdge := 120
SecTopEdge := 120
DpiF := (A_ScreenDPI > 0) ? (A_ScreenDPI / 96) : 1
SecScroll := {}
SecMaxScroll := 0
DetTesting := false
CardRects := []
hRunStatus := 0

CMTargetKeys := ["FishColor","BarLeftColor","BarRightColor","ArrowColor","NoteColor","PerfectGreenColor","PerfectWhiteColor"]
CMTargetLabel := {FishColor: "Fish line", BarLeftColor: "Bar - left end", BarRightColor: "Bar - right end"
	, ArrowColor: "Bar arrow", NoteColor: "Falling note", PerfectGreenColor: "Cast bar - green", PerfectWhiteColor: "Cast bar - white"}
CMTargetSection := {FishColor: "Minigame", BarLeftColor: "Minigame", BarRightColor: "Minigame"
	, ArrowColor: "Minigame", NoteColor: "Minigame", PerfectGreenColor: "Cast", PerfectWhiteColor: "Cast"}
CMTargetHint := {FishColor: "The thin marker that slides along the bar —`nthe fish you are chasing."
	, BarLeftColor: "The LEFT end of the reeling bar.`nAdd every shade it takes if the bar`nchanges color as it fills."
	, BarRightColor: "The RIGHT end of the reeling bar.`nAdd every shade it takes if the bar`nchanges color as it fills."
	, ArrowColor: "The small arrow drawn inside the`nreeling bar."
	, NoteColor: "A falling note.`nPinions Aria only."
	, PerfectGreenColor: "The green perfect-cast marker on`nthe cast power bar."
	, PerfectWhiteColor: "The white fill of the cast power bar."}
CMShortLabel := {FishColor: "Fish line", BarLeftColor: "Bar left", BarRightColor: "Bar right"
	, ArrowColor: "Arrow", NoteColor: "Note", PerfectGreenColor: "Cast green", PerfectWhiteColor: "Cast white"}
CMSel := "FishColor"
CMRowMax := 9
CMTargetLabel.TryhardBarColors := "Tryhard bar"
CMTargetLabel.TryhardFishColors := "Tryhard fish"
CMTargetLabel.TryhardTrackColors := "Tryhard track"
CMTargetLabel.CastboundBarColors := "Castbound bar"
CMTargetLabel.CastboundFishColors := "Castbound sword"
CMTargetLabel.CastboundTrackColors := "Castbound track"
CMShortLabel.TryhardBarColors := "Bar"
CMShortLabel.TryhardFishColors := "Fish"
CMShortLabel.TryhardTrackColors := "Track"
CMShortLabel.CastboundBarColors := "Bar"
CMShortLabel.CastboundFishColors := "Sword"
CMShortLabel.CastboundTrackColors := "Track"
for CMk, CMv in ["TryhardBarColors","TryhardFishColors","TryhardTrackColors","CastboundBarColors","CastboundFishColors","CastboundTrackColors"]
	CMTargetSection[CMv] := "Rods"
CMTargetHint.TryhardBarColors := "Only if the bar is never picked up. Click the`nbar while the fish is inside it (bright red)`nand while it is outside (dark red)."
CMTargetHint.TryhardFishColors := "Only if the fish is never found. Click the`ndark marker that sticks out above the bar."
CMTargetHint.TryhardTrackColors := "Only if the bar is still not found. Click`nthe dark red track beside the bar."
CMTargetHint.CastboundBarColors := "Only helps if the bar looks very dark on`nyour screen. Pick the track and the sword`nfirst."
CMTargetHint.CastboundFishColors := "Only if the fish is never found. Click the`npurple sword marker. 0x5522A3 is the normal`ncolor and changes nothing."
CMTargetHint.CastboundTrackColors := "Only if the minigame is never detected.`nClick the purple track the bar slides on."
CMTargetLabel.StellarBarColors := "Stellarwave bar"
CMTargetLabel.StellarFishColors := "Stellarwave fish"
CMTargetLabel.StellarHeadColors := "Stellarwave fish head"
CMShortLabel.StellarBarColors := "Bar"
CMShortLabel.StellarFishColors := "Fish"
CMShortLabel.StellarHeadColors := "Fish head"
for CMk, CMv in ["StellarBarColors","StellarFishColors","StellarHeadColors"]
	CMTargetSection[CMv] := "Rods"
CMTargetHint.StellarBarColors := "The thin dark purple frame around the bar,`nnot the colorful inside. 0x55446D is the`nnormal color."
CMTargetHint.StellarFishColors := "The light blue line of the fish on the bar.`n0xAFDAE8 is the normal color."
CMTargetHint.StellarHeadColors := "The white note head of the fish, just above`nthe bar. 0xFFFFFF is the normal color."
gosub, CMApplyTargets
MiniTab := "Setup"
MiniTop := 162
MiniTabSetupH := 0
MiniTabColorsH := 0
StellarSkinCtrls := []
FreezeActive := false
FreezeTarget := ""
FreezeMode := "add"
FreezePicked := ""

NoteNextX := -1
NoteNextY := -1
NoteLockY := -1
BarWidthTrusted := true
CastBarL := -1
CastBarW := 0
CastFishX := -1
CastScanned := false
CastPrevL := -1
CastPrevW := -1
CastPrevF := -1
CastSameN := 0
CastSameT := 0
CastStatic := false
RemWhiteX := -1
RemBlackX := -1
RemTargetX := -1
RemScanned := false
RemFound := false
RemBarScanned := false
RemBarFound := false
RemBarL := -1
RemBarW := 0
RemBarRing := []
MiguFishX := -1
MiguLastX := -1
MiguScanned := false
MiguFound := false
MiguBarScanned := false
MiguBarFound := false
MiguBarL := -1
MiguBarW := 0
TryScanned := false
TryFound := false
TryFishX := -1
TryBarL := -1
TryBarW := 0
if (RemembranceMode = "")
	RemembranceMode := "Living"
CastFound := false
NoteHoldX := -1
LullFrames := 0
LullCalN := 0
LullR := 0
LullSecN := 0
LullCalLt := []
LullCalDk := []
LullCalLs := []
LullBg := []
LullSecA := []
LullSecB := []
LullArmA := []
LullClrT := []
LullActive := false
LullSeen := false
LullGoneN := 0
LullClicks := 0
LullHitSec := 0
NoteAllX := []
NoteAllY := []
NoteAllN := 0
TotemEvt := []
TotemCool := {}
TotemAssume := {}
TotemAssumeMiss := {}
TotemAssumeSlot := {}
TotemAssumeCnt := {}
TotemAssumeSrc := {}
TotemAssumeAt := {}
TotemTaken := {}
TotemLastPop := ""
TotemLastPopSigs := ""
TotemLastPopUntil := 0
TotemCyclePopped := ","
TotemCheckNo := 0
TotemTime := ""
TotemWeather := ""
AqNextTick := 0
KbCatches := 0
KbBusy := false
KbStatus := "idle"
KbLastResult := ""
AqBusy := false
AqHoverOk := false
AqStatus := "idle"
AqLastResult := ""
AqBtnN := 0
AqBtnCX := []
AqBtnCY := []
AqBtnKind := []
AqBuys := 0
AqUses := 0
AqCardPitch := 0
TotemEvents := ""
TotemEvtSigs := ""
TotemDbg := ""
TotemLastCheck := 0
TotemWantTime := ""
WhStartTick := 0
WhCatches := 0
WhLastCatchTick := 0
WhLastSummary := 0
WhStalled := false
PausedMs := 0
AutoRefocus := true
LastAutoStop := 0
PCLastGoodY := -1
HotkeysArmed := false
CastFailCount := 0
DarkHoldN := 0
DarkFlashing := false
TqResetAll()
BelPrevF := [0,0]
BelPrevB := [0,0]
BelPrevT := [0,0]
BelVel := [0,0]
BelBVel := [0,0]
BelDown := [false,false]
BelSide := [0,0]
BelAcc := [0,0]
BelBias := [0,0]
BelA := [0,0]
BelB := [0,0]
BelF := [-1,-1]
BelOK := [false,false]
DarkAcc := 0
SetTimer, RfKeysWatch, 500

Hotkey, % "$" . StartStopKey, RfKeyStart, Off
Hotkey, % "$" . ReloadKey, RfKeyReload, Off
Hotkey, % "$" . ExitKey, RfKeyExit, Off
ForceReEquip := false
RodEquippedOnce := false
Hotkey, $F9, FreezePickHotkey, On

DllCall("shell32\SetCurrentProcessExplicitAppUserModelID", "WStr", "bai.ReFisch.Macro", "UInt")
Menu, Tray, Tip, Re:Fisch
ReFishIcoPath := A_ScriptDir . "\ReFisch-logo.ico"
ReFishEnsureIcon(ReFishIcoPath) ; writes the red/black hook logo next to the script if missing
if (FileExist(ReFishIcoPath))
    Menu, Tray, Icon, %ReFishIcoPath%
Menu, Tray, Add, Show Re:Fisch, ShowGuiFromTray
Menu, Tray, Default, Show Re:Fisch
Menu, Tray, Click, 1

KittyDiagStage := "ready / not started"
KittyDiagScanN := 0
KittyDiagClickN := 0
KittyDiagFindN := 0
KittyDiagIssuedN := 0
KittyDiagAckN := 0
KittyDiagRetryN := 0
FileDelete, %A_ScriptDir%\KittyKeys_diagnostic.log
FileAppend, % "Re:Fisch " . RfVersion . " session`r`n", %A_ScriptDir%\KittyKeys_diagnostic.log, UTF-8
SetTimer, KittyDiagTick, 500
KittyMouseStage := 0
KittyMouseDown := false
; AHK v1 checks timers in creation order. A priority-2 timer leaves that priority
; active for the rest of the dispatch pass, skipping later priority-0 timers.
; Keep this short stage tick at the same priority as the UI and deferred edits.
SetTimer, KittyMouseTimer, 10, 0
KittyMcReady() ; load + self-test the Kitty Keys speed kernels now, not mid-fight
gosub, RfBuildGui
if (UpdateAuto)
	SetTimer, RfUpdAutoTimer, -3000          ; Alpha 2.2: once the window is up (RfUpdCheck)

return

;====================================================================================================;

;====================================================================================================;
;   Re:Fisch engine  (new in Alpha 0.2, written for Re:Fisch)
;
;   Three states, shown by the sidebar chip and the overlay:
;     idle      nothing armed, the main window is open
;     ready     the start key is armed and Re:Fisch waits in Roblox        (MacroPreview)
;     fishing   cast -> bite -> reel, over and over                        (MacroRunning)
;
;   The reel minigame (RfReel, new in Alpha 0.8) is played after a bite, from RfReelRun; after
;   every fight it goes on at RestartMacro, or at Idle once fishing has stopped.
;====================================================================================================;

; ---- Roblox window -------------------------------------------------------------------------------

; The Roblox game window: found by its program first, by its exact title second.
RfFindRoblox() {
	global RobloxHwnd
	RobloxHwnd := WinExist("ahk_exe RobloxPlayerBeta.exe")
	if (!RobloxHwnd)
		{
		SetTitleMatchMode, 3
		RobloxHwnd := WinExist("Roblox")
		SetTitleMatchMode, 2
		}
	return RobloxHwnd
}

; Roblox in front and maximised (the screen areas below assume the full client area).
RfFrontRoblox() {
	global RobloxHwnd
	WinActivate, ahk_id %RobloxHwnd%
	WinWaitActive, ahk_id %RobloxHwnd%, , 2
	WinMaximize, ahk_id %RobloxHwnd%
}

; ---- screen areas --------------------------------------------------------------------------------
; Where things sit on Fisch's screen, as fractions of the Roblox client area, turned into the pixel
; rectangles the detection code reads. Rods whose minigame sits elsewhere get their own reel area.
RfMeasure() {
	global
	local w, h, a, sh
	if (!RobloxHwnd)
		RfFindRoblox()
	RfClientArea(RobloxHwnd, WindowLeft, WindowTop, WindowWidth, WindowHeight)
	w := WindowWidth, h := WindowHeight
	; reel area                     left     top      right    bottom
	a := [0.30157, 0.84239, 0.69847, 0.86866]
	if (SpecialRod = "Bellona's Waraxe")
		a[1] := 0.05, a[3] := 0.95
	if (SpecialRod = "Remembrance")
		a[2] := 0.81182, a[4] := 0.84303
	if (SpecialRod = "Stellarwave Melody")
		a := [0.22, 0.795, 0.78, 0.945]
	if (KittyMode())
		a := [0.12, 0.78, 0.88, 0.995]
	FishBarLeft := w * a[1], FishBarTop := h * a[2], FishBarRight := w * a[3], FishBarBottom := h * a[4]
	; the track the fish moves along (narrower than the frame on Stellarwave)
	TrackLeft := FishBarLeft, TrackRight := FishBarRight
	if (SpecialRod = "Stellarwave Melody")
		TrackLeft := w * 0.245, TrackRight := w * 0.755
	FishBarTooltipHeight := h * 0.94109
	; where the shake button can appear (from the Shake area settings, in percent)
	sh := [RfClampNum(ShakeAreaLeftPct, 0, 99), RfClampNum(ShakeAreaTopPct, 0, 99)
		, RfClampNum(ShakeAreaRightPct, 1, 100), RfClampNum(ShakeAreaBottomPct, 1, 100)]
	ClickShakeLeft := w * sh[1] / 100, ClickShakeTop := h * sh[2] / 100
	ClickShakeRight := Max(w * sh[3] / 100, ClickShakeLeft + 1)
	ClickShakeBottom := Max(h * sh[4] / 100, ClickShakeTop + 1)
	; the camera-mode button in the bottom bar
	CameraCheckLeft := w * 0.35157, CameraCheckRight := w * 0.64847
	CameraCheckTop := h * 0.78125, CameraCheckBottom := h
	; where the cursor rests: centred, a quarter of the way down
	LookDownX := w / 2, LookDownY := h / 4
	; the reel code's tuning was made at 2560 px wide
	ResolutionScaling := 2560 / w
	RfCapSetup()
}

RfClampNum(v, lo, hi) {
	if v is not number
		return lo
	return (v < lo) ? lo : (v > hi) ? hi : v
}

; ---- keys ----------------------------------------------------------------------------------------
; The start key is armed while Re:Fisch is ready or fishing; the reload and exit keys follow it.
RfArmKeys() {
	global
	if (!HotkeysArmed)
		{
		Hotkey, % "$" . StartStopKey, On
		HotkeysArmed := true
		}
	RfSyncRunKeys()
}

RfDisarmKeys() {
	global
	if (HotkeysArmed)
		{
		Hotkey, % "$" . StartStopKey, Off
		HotkeysArmed := false
		}
	RfSyncRunKeys()
}

RfSyncRunKeys() {
	global
	local want, i, k
	want := (HotkeysArmed or MacroRunning) ? true : false
	if (want = RunKeysArmed)
		return
	for i, k in [ReloadKey, ExitKey]
		Hotkey, % "$" . k, % want ? "On" : "Off"
	RunKeysArmed := want
}

; Every half second: whenever the main window is closed the keys are armed.
RfKeysWatch:
if (!FreezeActive and !DllCall("IsWindowVisible", "Ptr", GuiHwnd))
	RfArmKeys()
else
	RfSyncRunKeys()
return

; True while the main window is in front and nothing runs: keys typed there are for its fields.
RfTypingInMain() {
	global MacroRunning, GuiHwnd
	return (!MacroRunning and WinActive("ahk_id " . GuiHwnd))
}

; Start key: start fishing, or stop and go back to ready. It also stops Auto Appraise.
RfKeyStart:
if (RfApRunning)
	{
	RfApRunning := false
	return
	}
if (RfTypingInMain())
	return
if (MacroRunning)
	{
	RfStopFishing()
	return
	}
goto RfFishStart

RfKeyReload:
if (!RfTypingInMain())
	gosub, DoReload
return

RfKeyExit:
if (!RfTypingInMain())
	gosub, DoExit
return

DoReload:
RfEngQuit()
Reload
return

DoExit:
RfEngQuit()
ExitApp
return

; Before a reload or exit: let go of every input and keep the session numbers.
RfEngQuit() {
	global
	MacroRunning := false
	RfApRunning := false
	RfReleaseInputs()
	RfSessionEnd()
	RfSesSave()
}

; ---- states --------------------------------------------------------------------------------------

; Start button in the main window: idle -> ready, ready -> idle, fishing -> stop.
RfStartButton:
if (MacroRunning)
	RfStopFishing()
else if (MacroPreview)
	RfGoIdle()
else
	RfGoReady()
return

RfGoReady() {
	global
	if (!RfFindRoblox())
		{
		MsgBox, 4144, Re:Fisch, Roblox is not running, or its window could not be found.`nStart Roblox, then press Start again.
		return false
		}
	MacroPreview := true
	if (!GuiKeepOpen)
		Gui, 1:Hide
	RfFrontRoblox()
	gosub, RfUiTick          ; "ready" shows at once; measuring can take a moment
	RfMeasure()
	RfArmKeys()
	gosub, RfUiTick
	return true
}

RfGoIdle() {
	global
	MacroPreview := false
	RfDisarmKeys()
	gosub, RefreshRunChip
}

; Start key while fishing: stop and wait for the key again. The fishing loop sees MacroRunning
; go false and ends in Idle, which keeps the "ready" state because of RfStopWait.
RfStopFishing() {
	global
	MacroRunning := false
	MacroPreview := true
	RfStopWait := true
	RfReleaseInputs()
	RfArmKeys()
	gosub, RefreshRunChip
	SetTimer, RfFocusGuard, Off
	SetTimer, RfReelFailsafe, Off
	RfClearSweep()
	RfSesSave()
}

; Every stop ends here: the cast and bite steps come here, and so does the reel minigame once
; MacroRunning is false. Back to "ready" after the start key, to "idle" after anything else.
Idle:
RfEngHalt()
return

RfEngHalt() {
	global
	RfReleaseInputs()
	RfSessionEnd()
	RfRodsLetGo("stop")
	PrecisionDown := false
	MgInPlay := false
	MacroPreview := RfStopWait ? true : false
	RfStopWait := false
	SetTimer, RfFocusGuard, Off
	SetTimer, RfReelFailsafe, Off
	gosub, RefreshRunChip
	RfClearSweep()
}

; Lets go of the mouse buttons, Shift and the Space steering key.
RfReleaseInputs() {
	ReFishSpaceRelease()
	Send, {LButton up}
	Send, {RButton up}
	Send, {Shift up}
}

; Rod-specific leftovers from the last fight (a Stellarwave press or a parked cursor).
RfRodsLetGo(why) {
	global
	if (why = "stop")
		KittyDiagStage := "stopped"
	if (SwPressK)
		SwPressEnd()
	SwWantK := 0
	if (SwPreK)
		SwPreEnd(why)
}

; Rod state that has to start fresh for every fight.
RfRodsNewFight() {
	global SpecialRod
	if (SpecialRod = "Tranquility")
		TqResetAll()
	if (SpecialRod = "Stellarwave Melody")
		SwFightReset()
}

; ---- status lines --------------------------------------------------------------------------------

; What the overlay shows: the task and one line of detail.
RfSay(task, note := "") {
	global RfTip7, RfTip8
	RfTip7 := (task = "") ? "" : "Current Task: " . task
	RfTip8 := (note = "") ? "" : "Action: " . note
}

; After a stop the reel code can still write a line or two: keep them cleared for 1.5 s.
RfClearSweep() {
	global RfSweepEnd
	RfSweepEnd := A_TickCount + 1500
	SetTimer, RfStatusSweep, 25
	gosub, RfStatusSweep
}

RfStatusSweep:
Loop, 14
	RfTipClear(A_Index + 6)
RfHudHide()
if (A_TickCount >= RfSweepEnd)
	SetTimer, RfStatusSweep, Off
return

; Sleeps ms milliseconds in short steps; false as soon as fishing stops.
RfWait(ms) {
	global MacroRunning
	t := A_TickCount + ms
	while (MacroRunning and A_TickCount < t)
		Sleep, % Min(50, Max(1, t - A_TickCount))
	return MacroRunning
}

; While fishing, Roblox has to stay in front (keys and clicks go to the active window). If it is
; not, every held input is let go and Roblox is brought back, or waited for if it was closed.
RfFocusGuard:
if (!MacroRunning)
	return
if (WinActive("ahk_id " . RobloxHwnd))
	{
	RfEngHold := ""
	RfMouseHome(false)          ; a cursor that wandered off Roblox is brought back
	return
	}
RfReleaseInputs()
PrecisionDown := false
MacroPaused := true
while (MacroRunning and !WinActive("ahk_id " . RobloxHwnd))
	{
	if (!WinExist("ahk_id " . RobloxHwnd) and !RfFindRoblox())
		{
		RfEngHold := "Waiting for Roblox to open again"
		Sleep, 1000
		continue
		}
	RfEngHold := "Bringing Roblox back to the front"
	RfMouseHome(true)
	WinActivate, ahk_id %RobloxHwnd%
	WinWaitActive, ahk_id %RobloxHwnd%, , 1
	}
MacroPaused := false
RfEngHold := ""
RfMouseHome(true)
return

; Keeps the cursor inside Roblox while fishing. Clicks land on whatever window is under the cursor,
; so a cursor left on another window or screen would click there instead of in Roblox.
; force: put it at the rest point even if it is inside.
RfMouseHome(force) {
	global RobloxHwnd
	VarSetCapacity(rc, 16, 0), VarSetCapacity(pt, 8, 0)
	if (!DllCall("GetClientRect", "Ptr", RobloxHwnd, "Ptr", &rc) or !DllCall("ClientToScreen", "Ptr", RobloxHwnd, "Ptr", &pt))
		return
	rx := NumGet(pt, 0, "Int"), ry := NumGet(pt, 4, "Int"), rw := NumGet(rc, 8, "Int"), rh := NumGet(rc, 12, "Int")
	if (rw < 10 or rh < 10)
		return
	VarSetCapacity(cp, 8, 0)
	DllCall("GetCursorPos", "Ptr", &cp)
	mx := NumGet(cp, 0, "Int"), my := NumGet(cp, 4, "Int")
	if (force or mx < rx or my < ry or mx >= rx + rw or my >= ry + rh)
		DllCall("SetCursorPos", "Int", rx + rw // 2, "Int", ry + rh // 4)
}

; ---- fishing -------------------------------------------------------------------------------------

; Start key from "ready": a new session, then the cast loop.
RfFishStart:
MacroRunning := true
MacroPreview := false
RodEquippedOnce := false
gosub, RefreshRunChip
KittyDiagStage := "starting"
RfSessionBegin()
if (!RfEngPrepare())
	{
	MacroRunning := false
	MsgBox, 4144, Re:Fisch, Roblox is not running, or its window could not be found.`nStart Roblox, then press Start again.
	goto Idle
	}
if (!RfSetupSteps())
	goto Idle

; One cast. The reel minigame comes back here after every fight.
RestartMacro:
KittyDiagStage := "casting"
if (!RfEngCast())
	goto Idle
if (ShakeMode = "Disabled")
	goto RfReelRun
KittyDiagStage := "waiting for a bite"
RfBite := RfEngAwaitBite()
if (RfBite = "reel")
	goto RfReelRun
if (RfBite = "retry")
	goto RestartMacro
goto Idle

; One fight (RfReel), then the next cast, or Idle once fishing has stopped.
RfReelRun:
if (RfReel() = "stop")
	goto Idle
goto RestartMacro

; Session start: Roblox in front, maximised and measured, old status lines gone, focus guard on.
RfEngPrepare() {
	global
	local n
	RfReleaseInputs()
	if (!RfFindRoblox())
		return false
	RfFrontRoblox()
	RfMeasure()
	Loop, 14
		{
		n := A_Index + 6
		RfTip%n% := ""
		}
	RfEngHold := ""
	RfPcNoTop := false          ; perfect cast: measure the top of the meter again this run
	SetTimer, RfFocusGuard, 250
	return true
}

; Game setup on start, each step only when its switch is on. A stop during a step ends the setup
; (Shift is never left held down).
RfSetupSteps() {
	global
	local d, i, k
	if (AutoLowerGraphics)
		{
		; Shift+F10 lowers Roblox's graphics quality one step; 20 steps reach the lowest
		d := AutoGraphicsDelay
		RfSay("Lowering graphics", "Shift + F10")
		Send, {Shift}
		if (!RfWait(d))
			return false
		Send, {Shift down}
		Loop, 20
			{
			RfSay("Lowering graphics", "Shift + F10  ·  " . A_Index . " / 20")
			Send, {F10}
			if (!RfWait(d))
				break
			}
		Send, {Shift up}
		if (!RfWait(d))
			return false
		}
	if (AutoZoomInCamera and CastMode != "Perfect")
		{
		; all the way in, then one step back out
		d := AutoZoomDelay
		if (!RfWait(d))
			return false
		Loop, 20
			{
			RfSay("Zooming in", A_Index . " / 20")
			Send, {WheelUp}
			if (!RfWait(d))
				return false
			}
		RfSay("Zooming in", "one step back")
		Send, {WheelDown}
		if (!RfWait(d * 5))
			return false
		}
	CamModeOn := AutoEnableCameraMode ? true : false
	if (CamModeOn)
		{
		; only when the camera-mode button is on screen: equip slot 2 then 1 (the rod), open UI
		; navigation, walk right to the camera-mode button and press it
		PixelSearch, , , CameraCheckLeft, CameraCheckTop, CameraCheckRight, CameraCheckBottom, 0xFFFFFF, 0, Fast
		if (ErrorLevel = 0)
			{
			d := AutoCameraDelay
			for i, k in ["2", "1", NavigationKey]
				{
				RfSay("Turning on camera mode", "press " . k)
				if (!RfWait(d))
					return false
				Send, {%k%}
				}
			Loop, 10
				{
				RfSay("Turning on camera mode", "right " . A_Index . " / 10")
				if (!RfWait(d))
					return false
				Send, {Right}
				}
			if (!RfWait(d))
				return false
			Send, {Enter}
			if (!RfWait(d))
				return false
			}
		}
	if (AutoBlurCamera)
		{
		; M opens Fisch's settings menu, whose blur stays on the game once the first cast closes it.
		; Done once per session: pressed on every cast, the menu opened at the start of each cycle.
		d := AutoBlurDelay
		RfSay("Blurring the camera", "M")
		if (!RfWait(d))
			return false
		Send, {m}
		if (!RfWait(d))
			return false
		}
	return true
}

; One cast: tidy up after the last fight, look down, blur, re-equip if needed, use totems, cast,
; and wait for the bobber to land. False = fishing stopped.
RfEngCast() {
	global
	if (!MacroRunning)
		return false
	RfRodsLetGo("restart")
	Send, {LButton up}
	Send, {RButton up}
	while (SwParkAt and SwParkWait())
		Sleep, 5
	if (AutoLookDownCamera and !RfLookDown())
		return false
	if (!RfEquipCheck())
		return false
	if (!RfTotemRun())
		return false
	return RfThrowLine()
}

; Drag the camera to look straight down at the water (right button held, mouse pulled down), then
; rest the cursor in the upper middle of the screen.
RfLookDown() {
	global
	local d
	d := AutoLookDelay
	RfSay("Looking down")
	Send, {RButton up}
	MouseMove, LookDownX, LookDownY, 0
	if (!RfWait(d))
		return false
	Send, {RButton down}
	if (RfWait(d))
		{
		DllCall("mouse_event", "UInt", 0x0001, "Int", 0, "Int", 10000, "UInt", 0, "UPtr", 0)
		RfWait(d)
		}
	Send, {RButton up}
	if (!RfWait(d))
		return false
	MouseMove, LookDownX, LookDownY, 0
	return RfWait(d)
}

; Re-equip the rod on the first cast (unless camera mode equipped it) and after UnstickAfter
; failed casts in a row (a stuck bobber): to the bag (or the rod key twice) and back to the rod.
RfEquipCheck() {
	global
	local k
	if (RodSlotKey = "")
		return true
	if (!CamModeOn and !RodEquippedOnce)
		ForceReEquip := true
	if (!ForceReEquip and !(UnstickAfter > 0 and CastFailCount >= UnstickAfter))
		return true
	RfSay("Re-equipping the rod", ForceReEquip ? "" : CastFailCount . " casts in a row failed")
	Send, {LButton up}
	Send, {RButton up}
	if (!RfWait(120))
		return false
	k := (BagSlotKey != "") ? BagSlotKey : RodSlotKey
	Send, {%k%}
	if (!RfWait(400))
		return false
	Send, {%RodSlotKey%}
	if (!RfWait(600))
		return false
	CastFailCount := 0
	ForceReEquip := false
	RodEquippedOnce := true
	return true
}

; The cast itself: hold the left button (Normal: for HoldRodCastDuration; Perfect: until the
; power bar is on green), then wait for the bobber. Counts the cast for the session numbers.
RfThrowLine() {
	global
	RfSay("Casting", (CastMode = "Perfect") ? "perfect cast" : "holding " . HoldRodCastDuration . " ms")
	RfSesCasts += 1
	CastHolding := true
	Send, {LButton down}
	if (CastMode = "Perfect")
		{
		RfPerfectCast()
		if (!PCReleased)
			Send, {LButton up}
		}
	else
		{
		RfWait(HoldRodCastDuration)
		Send, {LButton up}
		}
	CastHolding := false
	if (!MacroRunning)
		return false
	RfSay("Waiting for the bobber", WaitForBobberDelay . " ms")
	return RfWait(WaitForBobberDelay)
}

; Between the cast and the reel: press Enter (Fisch's shake button is picked with UI navigation)
; until the reel minigame shows. Returns "reel", "retry" (no reel within the time limit, counted
; as a failed cast) or "stop".
RfEngAwaitBite() {
	global
	local t0, presses, seen, up
	RfSay("Shaking")
	MgInPlay := false
	RfRodsNewFight()
	ForceReset := false
	MgScore := 0, MgConf := 0
	t0 := A_TickCount, presses := 0, seen := 0
	Loop
		{
		if (!MacroRunning)
			return "stop"
		if (A_TickCount - t0 >= NavigationShakeFailsafe * 1000)
			{
			CastFailCount += 1
			RfStat("shakefail")
			return "retry"
			}
		if (!RfWait(NavigationSpamDelay))
			return "stop"
		if (SpecialRod = "Splitbranch Twig")
			gosub, TwigMaybePick
		up := RfReelShowing(seen)
		if (up and RfReelReady())
			return "reel"
		if (!up)
			RfGate.phantomAt := 0
		presses += 1
		RfSay("Shaking", presses . " presses  ·  " . ((A_TickCount - t0) // 1000) . " / " . NavigationShakeFailsafe . " s")
		Send, {Enter}
		}
}

; Is the reel minigame on screen? The fish line counts at once; the minigame frame alone has to
; show on two reads in a row (one read can be a passing UI element). Tranquility has its own UI.
RfReelShowing(ByRef seen) {
	global SpecialRod
	RfCapFrame()
	if (SpecialRod = "Tranquility")
		{
		seen := ManiaVisible() ? seen + 1 : 0
		return (seen >= 2)
		}
	if (RfFishLineSeen())
		{
		seen := 0
		return true
		}
	seen := RfReelVisible(6) ? seen + 1 : 0
	return (seen >= 2)
}

; Most rods wait until the reel UI has finished sliding in; these start at once.
RfReelReady() {
	global SpecialRod
	if SpecialRod in Tranquility,Lullaby,Stellarwave Melody
		return true
	return RfReelSettled()
}

;====================================================================================================;

;====================================================================================================;
;   Perfect cast  (new in Alpha 0.3, written for Re:Fisch)
;
;   While the left button is held, Fisch shows a vertical power meter: a short green marker on top
;   and a white fill that rises toward it, falls back and rises again. Re:Fisch finds the marker,
;   follows the fill in a thin column under it, and lets go in the middle of the fill's stay at
;   the top.
;   Alpha 0.6: up to 0.5 the release was aimed at the moment the fill reached the marker, the very
;   start of its short stay at the top, so a frame of jitter let go before it (Amazing / Good).
;   Now the stay is measured on screen (how long the fill sits within 2 % of the target; the first
;   perfect cast of a run watches one top for it, up to 2.5 s) and the release aims at its middle.
;   Settings: Perfect green / white colours and tolerances, Give up after (s), Wait cycles (full
;   swings to watch before releasing) and Release timing (ms: + lets go earlier, - later; the
;   release goes out 18 ms + this much before the aim, see lag below).
;====================================================================================================;

; Holds the cast until the meter says "now" (the caller has pressed the button). Sets PCReleased
; when it let go itself; on a stop or after the time limit the caller lets go.
RfPerfectCast() {
	global
	local t0, now, fill, last, hist, eta, lag, lost, need, frameDt, n, msg, hiRun, loRun, high, swings
	local slow, lastScan, zone, tIn, prev, tOut, hold, aim, measuring, tMeter
	PCReleased := false
	tMeter := 0                                    ; when the meter was first found this cast
	RfPcReset()
	need := Round(RfClampNum(PerfectWaitCycles, 0, 5))
	lag := 0.018 + RfClampNum(PerfectReleaseTiming, -200, 200) / 1000.0
	zone := RfPcTarget - 2                         ; "at the top": within 2 % of the target
	hist := [], lost := 0, frameDt := 0.03, last := -1, tIn := 0
	hiRun := 0, loRun := 0, high := false, swings := 0
	t0 := A_TickCount, lastScan := A_TickCount     ; the first 0.4 s: fast searches only
	Loop
		{
		if (!MacroRunning)
			return
		if (A_TickCount - t0 > RfClampNum(PerfectFailTimeout, 1, 120) * 1000)
			{
			RfSay("Casting", "perfect cast: no meter in time, released")
			return
			}
		if (RfPcBar.y < 0)
			{
			; the slow scan at most every 0.4 s, so the fast searches keep watching in between;
			; after 1.5 s a green marker is accepted without checking the meter under it
			slow := (A_TickCount - lastScan >= 400)
			if (slow)
				lastScan := A_TickCount
			if (!RfMeterFind(A_TickCount - t0 > 1500, slow))
				{
				RfSay("Casting", "perfect cast: looking for the meter")
				continue
				}
			if (!tMeter)
				tMeter := A_TickCount
			hist := [], lost := 0, last := -1, tIn := 0
			}
		fill := RfMeterRead()
		if (fill < 0)
			{
			lost += 1
			if (lost >= 6)
				RfPcBar.y := -1
			continue
			}
		lost := 0
		if (fill != last)                  ; a new frame from the game
			{
			last := fill
			; swings: the top (88% or more) and then the bottom (12% or less), each on two reads in
			; a row, so one odd frame does not count as a swing
			hiRun := (fill >= 88) ? hiRun + 1 : 0
			loRun := (fill <= 12) ? loRun + 1 : 0
			if (hiRun >= 2)
				high := true
			if (high and loRun >= 2)
				swings += 1, high := false
			; the current rise: a fall clears it; samples older than 0.25 s drop off
			n := hist.Length()
			prev := n ? hist[n] : ""
			if (n and fill < prev.f - 2)
				hist := []
			hist.Push({t: RfPcBar.t, f: fill})
			while (hist.Length() > 2 and (RfPcBar.t - hist[1].t) / QpcFreq > 0.25)
				hist.RemoveAt(1)
			n := hist.Length()
			if (n >= 2)
				frameDt := Min(0.1, (hist[n].t - hist[n - 1].t) / QpcFreq)
			; the stay at the top: when the fill came into the zone and when it left, each placed
			; between the frame before and this one on a straight line; every stay measured goes
			; into RfPcDwell
			if (fill >= zone and !tIn)
				tIn := (IsObject(prev) and prev.f < zone and fill > prev.f)
					? prev.t + (RfPcBar.t - prev.t) * (zone - prev.f) / (fill - prev.f) : RfPcBar.t
			else if (fill < zone and tIn)
				{
				tOut := (IsObject(prev) and prev.f >= zone and prev.f > fill)
					? prev.t + (RfPcBar.t - prev.t) * (prev.f - zone) / (prev.f - fill) : RfPcBar.t
				RfPcDwellAdd((tOut - tIn) / QpcFreq)
				tIn := 0
				}
			msg := "perfect cast: " . Round(fill) . "% of " . Round(RfPcTarget) . "%"
			if (swings < need)
				msg .= "  ·  watching swing " . (swings + 1) . " / " . need
			else if (RfPcDwell = "" and !RfPcNoTop)
				msg .= "  ·  measuring the top"
			RfSay("Casting", msg)
			}
		; release only after the swings to watch, and once the stay at the top has been measured.
		; If that has not happened within 2.5 s, a 12 ms hold stands in (the old aim) and later
		; casts of this run do not wait for it again (RfPcNoTop)
		; Alpha 1.1: the 2.5 s count from when the meter was found (they counted from the button
		; press, so a slow search left no time to measure), and RfPcNoTop is cleared at every Start
		; (RfEngPrepare; it used to stay set until the script was reloaded)
		measuring := (RfPcDwell = "" and !RfPcNoTop)
		if (measuring and tMeter and A_TickCount - tMeter >= 2500)
			RfPcNoTop := true, measuring := false
		if (swings < need or measuring)
			continue
		hold := (RfPcDwell != "") ? RfPcDwell / 2 : 0.012
		; the aim: hold seconds after the fill came into the top zone; before it gets there, the
		; entry is read off a straight line through the rise (RfPcAim), but only while the newest
		; frame still rises (just past the top, the line still points up)
		n := hist.Length()
		if (tIn)
			aim := tIn + hold * QpcFreq
		else if (fill >= 50 and n >= 3 and hist[n].f > hist[n - 1].f
			and (hist[n].t - hist[1].t) / QpcFreq >= 0.03 and hist[n].f - hist[1].f >= 5)
			aim := RfPcAim(hist, zone, hold)
		else
			continue
		if (aim < 0)
			continue
		; the release goes out lag seconds early (the game takes that long to see it)
		DllCall("QueryPerformanceCounter", "Int64*", now)
		eta := (aim - now) / QpcFreq - lag
		if (eta > Max(frameDt * 1.5, 0.03))
			continue                  ; another frame will come before then
		if (eta < -0.02)
			continue                  ; this stay is nearly over (found late): wait for the next
		if (eta > 0)
			RfSpinUntil(now + eta * QpcFreq)
		Send, {LButton up}
		PCReleased := true
		RfPcLastY := RfPcBar.y
		RfSay("Casting", "perfect cast: released " . (tIn ? "at the top" : "on the way up")
			. ", aimed " . Round(hold * 1000) . " ms into its stay there")
		return
		}
}

; When to let go (a performance-counter time), before the fill has reached the top zone (zone %):
; its entry read off a straight line through the last 80 ms of the rise h (at least 3 samples),
; plus hold seconds. -1 when the line does not rise.
RfPcAim(h, zone, hold) {
	global QpcFreq
	n := h.Length(), tn := h[n].t
	recent := []
	for i, p in h
		if ((tn - p.t) / QpcFreq <= 0.08)
			recent.Push(p)
	if (recent.Length() < 3)
		recent := [h[n - 2], h[n - 1], h[n]]
	q := RfLineSlope(recent, "")
	if (q = "" or q.m <= 0)
		return -1
	; the line's value at the newest sample (smooths a pixel of jitter), then on to the zone
	return tn + (Max(0, (zone - (q.b + q.m * (tn - recent[1].t) / QpcFreq)) / q.m) + hold) * QpcFreq
}

; One measured stay at the top, in seconds. The last five are kept (for as long as the script
; runs); RfPcDwell is their median, "" until the first one. A sharp top that falls between two
; frames measures only a few ms, so anything from 3 ms counts.
RfPcDwellAdd(d) {
	global RfPcDwells, RfPcDwell
	if (d < 0.003 or d > 0.3)
		return
	if (!IsObject(RfPcDwells))
		RfPcDwells := []
	RfPcDwells.Push(d)
	if (RfPcDwells.Length() > 5)
		RfPcDwells.RemoveAt(1)
	RfPcDwell := RfMedian(RfPcDwells)
}

; Fresh state for a cast: colours from the settings, meter not found yet.
RfPcReset() {
	global
	RfPcBar := {y: -1, x: -1, run: 0, cx: -1, t: 0}
	RfPcG := RfPcColour(PerfectGreenColor, "0x60AA4A", PerfectGreenTolerance)
	RfPcW := RfPcColour(PerfectWhiteColor, "0xFFFEF3", PerfectWhiteTolerance)
	RfPcTarget := 98.5                     ; the white about 2 px under the marker
	if RfPcLastY is not number
		RfPcLastY := -1, RfPcLastX := -1
}

; The first colour of a colour setting as {r, g, b, t (tolerance), c (0xRRGGBB)}.
RfPcColour(setting, fallback, tol) {
	if (!RegExMatch(setting, "i)0x([0-9a-f]{6})", m))
		RegExMatch(fallback, "i)0x([0-9a-f]{6})", m)
	c := "0x" . m1
	c += 0
	return {r: (c >> 16) & 0xFF, g: (c >> 8) & 0xFF, b: c & 0xFF, t: RfClampNum(tol, 0, 255), c: c}
}

; Least-squares line through samples {t (performance counter), f (%)}: slope m in % per second,
; b the value at the first sample's time. "" when there are fewer than 3 samples.
RfLineSlope(h, unused) {
	global QpcFreq
	n := h.Length()
	if (n < 3)
		return ""
	t0 := h[1].t, st := 0.0, sf := 0.0, stt := 0.0, stf := 0.0
	for i, p in h
		{
		x := (p.t - t0) / QpcFreq
		st += x, sf += p.f, stt += x * x, stf += x * p.f
		}
	d := n * stt - st * st
	if (d <= 0)
		return ""
	m := (n * stf - st * sf) / d
	return {m: m, b: (sf - m * st) / n, q: QpcFreq}
}

; Waits until the performance counter reaches tq: short sleeps while far, a spin at the end.
RfSpinUntil(tq) {
	global QpcFreq
	Loop
		{
		DllCall("QueryPerformanceCounter", "Int64*", n)
		left := (tq - n) / QpcFreq
		if (left <= 0)
			return
		if (left > 0.016)
			DllCall("Sleep", "UInt", 1)
		}
}

; ---- finding the meter ---------------------------------------------------------------------------
; The marker's green changes with the lighting (#63AF4C on a bright beach, #8BBA79 in another
; scene), so the fast native PixelSearch is run for a few greens: the one last seen on the meter,
; the calibrated one, and two that cover the light and dark shades. It looks near where the meter
; was last time first. The slow scan (any clearly green pixel, read by AutoHotkey) covers only the
; middle of the screen and only runs when the caller allows it, because it takes a while.
; slow: true = fast searches, then the slow scan; false = fast searches only; "near" = fast
; searches near the last place only (anywhere if the meter was never seen).
; A hit only counts if it is a short horizontal green band (6 to 59 px) with the meter under it;
; a loose search skips that check.
RfMeterFind(loose, slow := true) {
	global
	local top, bot, bands, i, b, cols, c, j
	top := Round(WindowHeight * 0.13), bot := Round(WindowHeight * 0.90)
	bands := []
	if (RfPcLastY >= 0)
		bands.Push([Max(top, RfPcLastY - 70), Min(bot, RfPcLastY + 70)
			, Max(0, RfPcLastX - 200), Min(WindowWidth - 1, RfPcLastX + 200)])
	if (slow = "near")
		{
		; quick check: near the last place; if the meter was never seen, the middle of the screen
		; with two greens only
		if (!bands.Length())
			bands.Push([top, bot, Round(WindowWidth * 0.20), Round(WindowWidth * 0.80)])
		}
	else
		bands.Push([top, bot, 0, WindowWidth - 1])
	cols := []
	if (RfPcSeen != "")
		cols.Push([RfPcSeen, 30])
	cols.Push([RfPcG.c, Max(RfPcG.t, 40)])
	cols.Push([0x8CBA78, 40])                ; light marker green
	if (!(slow = "near" and RfPcLastY < 0))
		cols.Push([0x5A9E46, 40])            ; dark marker green
	for i, b in bands
		for j, c in cols
			if (RfMeterSearch(b[1], b[2], b[3], b[4], c[1], c[2], loose))
				return true
	if (slow = true)
		return RfMeterScan(top, bot, loose)
	return false
}

; Fast path: PixelSearch for one green (col, variation var) inside x0..x1, y0..y1.
RfMeterSearch(y0, y1, x0, x1, col, var, loose) {
	global
	local y, xs, yb, fx, fy, el
	y := y0, xs := x0
	Loop, 30
		{
		if (y > y1)
			break
		yb := (xs > x0) ? Min(y + 2, y1) : y1
		PixelSearch, fx, fy, %xs%, %y%, %x1%, %yb%, %col%, %var%, Fast RGB
		el := ErrorLevel
		if (el)
			{
			if (xs = x0)
				break                       ; nothing of that green left in the area
			xs := x0, y := yb + 1           ; the rest of those rows is clear: go on below
			continue
			}
		if (RfMeterCheck(fx, fy, loose))
			return true
		xs := fx + 1, y := fy               ; a false hit: look right of it on the same rows
		if (xs >= x1)
			xs := x0, y := fy + 3
		}
	return false
}

; Slow path: the middle 60% of the screen read once, every 4th pixel of every 3rd row tested for
; any clearly green pixel. Up to 40 candidates are checked.
RfMeterScan(y0, y1, loose) {
	global
	local s, x0, w, h, p, row, x, y, px, g, tries
	x0 := Round(WindowWidth * 0.20), w := Round(WindowWidth * 0.60), h := y1 - y0 + 1
	s := RfGrab("meterscan", x0, y0, w, h)
	if (!IsObject(s))
		return false
	p := s.p, tries := 0, y := 0
	while (y < h)
		{
		row := p + y * w * 4
		x := 0
		while (x < w)
			{
			px := NumGet(row + 0, x * 4, "UInt")
			g := (px >> 8) & 0xFF
			if (g > 80 and g - ((px >> 16) & 0xFF) > 22 and g - (px & 0xFF) > 22)
				{
				; step back to the left edge of the green band
				while (x > 0 and RfIsGreen(NumGet(row + 0, (x - 1) * 4, "UInt")))
					x -= 1
				if (RfMeterCheck(x0 + x, y0 + y, loose))
					return true
				if (++tries >= 40)
					return false
				x += 64                     ; past this band
				continue
				}
			x += 4
			}
		y += 3
		}
	return false
}

; Is the green pixel at (x, y) the meter's marker? Measures the green band on that row and looks
; at the bar under it. Fisch's bar has a dark 1 px edge (at least one side is near-black, whatever
; is behind it; the inside is see-through and takes the colour of the scene), so: a dark edge and
; a clearly lighter middle. A dark-or-white middle with a visible side edge also counts.
RfMeterCheck(x, y, loose) {
	global
	local s, gap, i, run, depth, fr, sy, ok, seen, mid, lb, rb
	s := RfGrab("meterrow", x, y, 72, 1)
	if (!IsObject(s))
		return false
	run := 0, gap := 0, i := 0
	while (i < 72)
		{
		if (RfIsGreen(RfPx(s, i, 0)))
			run := i + 1, gap := 0
		else if (++gap > 2)
			break
		i += 1
		}
	if (run < 6 or run >= 60)
		return false
	if (!loose)
		{
		depth := Round(WindowHeight * 0.20)
		s := RfGrab("metercol", x - 6, y, run + 12, depth)
		if (!IsObject(s))
			return false
		ok := 0, seen := 0
		for i, fr in [0.020, 0.040, 0.070, 0.100, 0.145, 0.190]
			{
			sy := Round(WindowHeight * fr)
			if (sy >= depth)
				break
			seen += 1
			mid := RfLum(RfPx(s, 6 + run // 2, sy))
			lb := RfEdgeLum(s, 6, sy)               ; around x - 1 .. x + 1
			rb := RfEdgeLum(s, run + 5, sy)         ; around x + run - 2 .. x + run
			if (Min(lb, rb) < 60 and mid >= Min(lb, rb) + 40)
				ok += 1
			else if (RfIsNeutral(RfPx(s, 6 + run // 2, sy))
				and (Abs(RfLum(RfPx(s, 7, sy)) - RfLum(RfPx(s, 1, sy))) >= 25
				or Abs(RfLum(RfPx(s, 4 + run, sy)) - RfLum(RfPx(s, run + 10, sy))) >= 25))
				ok += 1
			}
		; fewer than 3 samples fit on screen: all of them must pass; otherwise at least 3
		if ((seen < 3 and (ok = 0 or ok < seen)) or (seen >= 3 and ok < 3))
			return false
		}
	RfPcBar.y := y, RfPcBar.x := x, RfPcBar.run := run, RfPcBar.cx := x + run // 2
	RfPcLastY := y, RfPcLastX := x
	; the marker's green as it looks now, searched first next time
	s := RfGrab("meterrow", x, y, 72, 1)
	if (IsObject(s))
		RfPcSeen := RfPx(s, run // 2, 0) & 0xFFFFFF
	return true
}

; The darkest of three neighbouring pixels (columns c - 1 .. c + 1) of row y.
RfEdgeLum(s, c, y) {
	return Min(RfLum(RfPx(s, c - 1, y)), RfLum(RfPx(s, c, y)), RfLum(RfPx(s, c + 1, y)))
}

; ---- reading the meter ---------------------------------------------------------------------------
; One frame: the bar under the marker (its width plus a pixel or two either side), from just above
; the marker down the screen. The marker's top and bottom rows, the bar's bottom (where its dark
; edge ends), and the top of the white fill give the fill: 0 = empty, 100 = the white touches
; the marker. Returns -1 when the marker is gone.
RfMeterRead() {
	global
	local s, x0, w, y0, h, cx, gy, gb, y, top, bot, gap, t
	if (RfPcBar.run < 3)
		return -1
	x0 := RfPcBar.x - 2, w := RfPcBar.run + 4
	y0 := Max(0, RfPcBar.y - 8)
	h := Round(WindowHeight * 0.97) - y0
	if (h < 24)
		return -1
	DllCall("QueryPerformanceCounter", "Int64*", t)
	s := RfGrab("meter", x0, y0, w, h)
	if (!IsObject(s))
		return -1
	RfPcBar.t := t
	cx := 2 + RfPcBar.run // 2
	; the marker: the first green row in the middle column near where it was (it can move a few
	; pixels), then down to its last green row
	gy := -1, y := 0
	while (y < 17 and y < h)
		{
		if (RfIsGreen(RfPx(s, cx, y)))
			{
			gy := y
			break
			}
		y += 1
		}
	if (gy < 0)
		return -1
	gb := gy
	while (gb + 1 < h and RfIsGreen(RfPx(s, cx, gb + 1)))
		gb += 1
	RfPcBar.y := y0 + gy
	; the bar's bottom: follow its dark edge (whichever side is dark) down from its first dark row
	; under the marker
	y := gb + 1
	while (y < gb + 14 and y < h and Min(RfEdgeLum(s, 1, y), RfEdgeLum(s, RfPcBar.run + 2, y)) >= 60)
		y += 1
	bot := -1, gap := 0
	while (y < h)
		{
		if (Min(RfEdgeLum(s, 1, y), RfEdgeLum(s, RfPcBar.run + 2, y)) < 60)
			bot := y, gap := 0
		else if (++gap > 3)
			break
		y += 1
		}
	; the white fill: its first row under the marker
	top := -1, y := gb + 1
	while (y < h)
		{
		if (RfWhiteRow(s, cx, y))
			{
			top := y
			break
			}
		y += 1
		}
	if (bot - gb < 20 or (top >= 0 and bot < top + 2))
		{
		; no dark edge (or one that stops at the fill): the end of the white fill is the bottom,
		; allowing gaps of up to 16 rows
		if (top < 0)
			return -1
		bot := top, gap := 0, y := top
		while (++y < h)
			{
			if (RfWhiteRow(s, cx, y))
				bot := y, gap := 0
			else if (++gap > 16)
				break
			}
		if (bot - gb < 20)
			return -1
		}
	if (top < 0 or top > bot)
		return 0
	return Max(0, Min(100, 100.0 * (bot - top) / (bot - gb)))
}

; A row of the bar counts as white when at least two of the three middle pixels are (the fill
; is shaded from left to right, so only the middle is used).
RfWhiteRow(s, cx, y) {
	return (RfIsWhite(RfPx(s, cx - 1, y)) + RfIsWhite(RfPx(s, cx, y)) + RfIsWhite(RfPx(s, cx + 1, y)) >= 2)
}


; ---- pixels --------------------------------------------------------------------------------------
; Copies a rectangle of the Roblox client area (x, y from its corner at WindowLeft, WindowTop)
; into a surface kept per slot name (RfSurface, in the screen-capture section). Returns the
; surface {p, w, h, ...} (pixel x, y: RfPx) or "" when it could not be made.
RfGrab(slot, x, y, w, h) {
	global WindowLeft, WindowTop
	static slots := {}
	if (w < 1 or h < 1)
		return ""
	s := slots[slot]
	if (!RfSurface(s, w, h))
		{
		slots.Delete(slot)
		return ""
		}
	slots[slot] := s
	RfBlit(s, WindowLeft + x, WindowTop + y, s.w, s.h)
	return s
}

RfPx(s, x, y) {
	return NumGet(s.p + 0, (y * s.w + x) * 4, "UInt")
}

; Clearly green, or the calibrated marker green within its tolerance.
RfIsGreen(px) {
	global RfPcG
	b := px & 0xFF, g := (px >> 8) & 0xFF, r := (px >> 16) & 0xFF
	if (g > 80 and g - r > 22 and g - b > 22)
		return true
	return (Abs(r - RfPcG.r) <= RfPcG.t and Abs(g - RfPcG.g) <= RfPcG.t and Abs(b - RfPcG.b) <= RfPcG.t)
}

; Near-white (bright and colourless), or the calibrated fill white within its tolerance.
RfIsWhite(px) {
	global RfPcW
	b := px & 0xFF, g := (px >> 8) & 0xFF, r := (px >> 16) & 0xFF
	if (Min(r, g, b) > 200 and Max(r, g, b) - Min(r, g, b) < 32)
		return true
	return (Abs(r - RfPcW.r) <= RfPcW.t and Abs(g - RfPcW.g) <= RfPcW.t and Abs(b - RfPcW.b) <= RfPcW.t)
}

; Colourless and either dark or bright: what the meter's column looks like, empty or full.
RfIsNeutral(px) {
	b := px & 0xFF, g := (px >> 8) & 0xFF, r := (px >> 16) & 0xFF
	hi := Max(r, g, b), lo := Min(r, g, b)
	return (hi - lo < 45 and (hi < 100 or lo > 150))
}

RfLum(px) {
	return ((px & 0xFF) + ((px >> 8) & 0xFF) + ((px >> 16) & 0xFF)) // 3
}

; After a fight with the left button still down: is the cast meter up (a cast began charging)?
; RfReelOver then has the next cast re-equip first. The reel runs this whenever the bar is
; missing for a frame (often during Stellarwave's star phase), so it must be quick: only the fast
; searches, and only near where the meter was seen (anywhere only if it was never seen).
CastChargeCheck:
if (MgCastCharged or WindowHeight < 100)
	return
RfPcReset()
Loop, 2
	{
	if (A_Index = 2)
		Sleep, 40
	RfPcBar.y := -1
	if (!RfMeterFind(false, "near") or RfMeterRead() <= 0)
		return
	}
MgCastCharged := true
return

TwigMaybePick:
if (!MacroRunning)
	return
DllCall("QueryPerformanceCounter", "Int64*", TwigNow)
if (TwigLastCheck and ((TwigNow - TwigLastCheck) / QpcFreq) < 0.30)
	return
TwigLastCheck := TwigNow
if (!TwigPrompt(TwigLX, TwigRX, TwigLabY))
	return
RfTip8 = Action: Splitbranch Twig - choosing a fish
MouseGetPos, TwigSaveX, TwigSaveY
TwigIconY := Round(WindowHeight * 0.493)
for TwigI, TwigT in [[TwigLX, TwigIconY], [TwigRX, TwigIconY], [TwigLX, TwigLabY], [TwigRX, TwigLabY]]
	{
	if (!MacroRunning)
		break
	TwigCX := TwigT[1]
	TwigCY := TwigT[2]
	MouseMove, %TwigCX%, %TwigCY%, 0
	sleep 40
	send {lbutton down}
	sleep 40
	send {lbutton up}
	sleep 260
	if (!TwigPrompt(TwigLX, TwigRX, TwigLabY))
		break
	}
MouseMove, %TwigSaveX%, %TwigSaveY%, 0
DllCall("QueryPerformanceCounter", "Int64*", TwigLastCheck)
return

;====================================================================================================;
;   The reel minigame  (new in Alpha 0.8, written for Re:Fisch)
;
;   RfReel plays one fight after a bite and says how fishing goes on: "restart" (cast again) or
;   "stop" (MacroRunning went false). RfReelRun, in the engine, calls it.
;     1. RfReelBegin       fresh state for this bite; Tranquility goes straight to the loop
;     2. RfReelMeasure     waits for the bar (and for the reel UI to settle), then takes its width:
;                          the median of up to 9 reads over about 100 ms
;     3. RfReelFightStart  fresh fight state, the edge gate starts learning, the track's no-go sides
;     4. RfReelLoop        RfReelFrame once per frame until the fight is over (RfReelOver)
;   A frame: stop checks, the capture, the edge gate, the rods with a minigame of their own
;   (Lullaby, Tranquility, Bellona's Waraxe), the bar, the fish (and notes), then one steering
;   step: Precision (RfSteer*: PD control with velocity tracking and a stopping distance, the
;   method of AsphaltCake's IRUS) for the Precision and Lines modes and Requiem, or pulses
;   (RfPulse*) for the Normal mode.
;   The failsafe timer (RfReelFailsafe) counts seconds from the bite, and again from the fight's
;   start: after BarCalculationFailsafe of them the fight is given up (ForceReset).
;   The fight's own state is in RfFight; what the rest of Re:Fisch reads stays global (FishX,
;   WhiteBarSize, BarWTrust, MaxLeftBar / MaxRightBar, PrecisionDown and its times, ...).
;====================================================================================================;

RfReel() {
	global
	local r
	if (RfReelBegin() = "measure")
		{
		r := RfReelMeasure()
		if (r != "fight")
			return r
		RfReelFightStart()
		}
	return RfReelLoop()
}

; Fresh state for this bite. "measure" normally; "loop" for Tranquility, whose notes start at once.
RfReelBegin() {
	global
	local now
	KittyDiagStage := "calibrating fishing bar"
	MgInPlay := true
	; Dreambreaker's inversion watch lives as long as the bite: first bar place and time, when it
	; first moved, and whether the controls have flipped
	RfFight := {dbX0: -1, dbSeen: 0, dbMove: 0, dbFlip: false, lost: 0}
	if (SpecialRod = "Stellarwave Melody" and ShakeMode == "Disabled")
		SwFightReset()
	RfGateReset()
	RfBarForget("widths")
	RemBarRing := [], RfHud.widths := [], RfHud.wMed := 0
	CastFailCount := 0
	if (SpecialRod = "Tranquility")
		{
		RfTip7 := "Current Task: Playing Notes", RfTip8 := "", RfTip10 := ""
		ForceReset := false
		DllCall("QueryPerformanceCounter", "Int64*", now)
		TqResetFight(now / QpcFreq)
		RfFightStart()
		return "loop"
		}
	RfTip7 := "Current Task: Calculating Bar Size", RfTip8 := "Bar Size: Not Found"
	RfTip10 := "Failsafe: 0/" . BarCalculationFailsafe
	ForceReset := false, BarCalcFailsafeCounter := 0, MgFightMode := false, MgOverWhy := ""
	SetTimer, RfReelFailsafe, 1000
	if (SpecialRod = "Noiseform")
		NoiseBiteState()
	return "measure"
}

; Waits for the bar. Once it shows (and, except on Stellarwave, the reel UI has settled), reads it 8
; more times 12 ms apart; with 3 or more reads (and on Noiseform a fresh fish on 2 of them) their
; median is the bar's width (WhiteBarSize). "fight", or "stop" / "restart" (failsafe).
RfReelMeasure() {
	global
	local widths, fresh, now
	Loop
		{
		if (!MacroRunning)
			return "stop"
		if (SpecialRod = "Splitbranch Twig")
			gosub, TwigMaybePick
		if (ForceReset == true)
			{
			RfTip10 := ""
			return "restart"
			}
		RfCapFrame()
		if (RfBarFind() and (SpecialRod = "Stellarwave Melody" or RfReelSettled()))
			{
			if (SpecialRod = "Dreambreaker" and !RfFight.dbSeen)
				DllCall("QueryPerformanceCounter", "Int64*", now), RfFight.dbSeen := now
			widths := [RunWidth], fresh := NoiseFishFresh ? 1 : 0
			Loop, 8
				{
				if (!MacroRunning)
					return "stop"
				Sleep, 12
				RfCapFrame()
				if (RfBarFind())
					widths.Push(RunWidth)
				if (NoiseFishFresh)
					fresh += 1
				}
			if (widths.Length() >= 3 and (SpecialRod != "Noiseform" or fresh >= 2))
				{
				WhiteBarSize := RfMedian(widths), BarWTrust := WhiteBarSize
				return "fight"
				}
			}
		Sleep, 1
		}
}

; The fight starts: fresh fight and rod state, the edge gate learning, the no-go sides of the track
; and the live display.
RfReelFightStart() {
	global
	KittyDiagStage := "playing fishing bar"
	RfFightStart()
	MgFightMode := true, BarCalcFailsafeCounter := 0, MgCastCharged := false
	RfGateStart()
	RfTip7 := "Current Task: Playing Bar Minigame", RfTip8 := "Bar Size: " . WhiteBarSize
	HalfBarSize := WhiteBarSize / 2
	; the fight's own state: losing the bar (lost frames, since when, the display hidden), the
	; no-fish timer, the pulse method's memory, the width ring (RfReelWidthPush), the steering's
	; memory (RfSteerTrack) and its duty accumulators, and the duty the fish needs (duty)
	RfFight.lost := 0, RfFight.lostAt := 0, RfFight.hudHidden := false, RfFight.noFishAt := 0
	RfFight.sawBar := false, RfFight.cal := WhiteBarSize
	RfFight.widths := [], RfFight.wMed := 0, RfFight.wOutN := 0, RfFight.wOutFirst := 0
	RfFight.prevBar := -1, RfFight.prevFish := -1, RfFight.prevT := 0, RfFight.barVel := 0.0, RfFight.fishVel := 0.0
	RfFight.trackSource := "", RfSteerDt := 0, RfCapAt := 0
	RfFight.ctrAcc := 0, RfFight.ctrBias := 0, RfFight.noteAcc := 0, RfFight.blindAcc := 0, RfFight.duty := 0.5
	RfFight.castBlind := 0
	; for the reel log: when the fight started, frames, frames with the bar / the fish / the fish on
	; the bar, frames with bar and line both lost, frames let go by the gate
	RfFight.t0 := A_TickCount, RfFight.nF := 0, RfFight.nBar := 0, RfFight.nFish := 0, RfFight.nOn := 0
	RfFight.nLostF := 0, RfFight.nLet := 0, RfFight.letting := false, RfFight.nStale := 0, RfFight.nHeld := 0
	RfFight.eSum := 0.0, RfFight.eW := 0.0, RfFight.eN := 0, RfFight.eMid := 0
	; frame times (RfReelTime); PfPrev cleared so the first frame does not count the time since
	; the last fight
	RfFight.dtSum := 0.0, RfFight.dtN := 0, RfFight.dtMax := 0, RfFight.nSlow := 0
	PfPrev := 0
	RfReelLogStart()
	SideDelay := 0, AnkleBreakDelay := 0, DirectionalToggle := "Disabled"
	MaxLeftToggle := false, MaxRightToggle := false
	LastFishX := -1, RfBarMode := "", BarWidthTrusted := true
	RfBarForget("ends"), RfBarForget("live")
	PrecisionDown := false, PrecisionResendAt := 0
	RfHud.widths := [], RfHud.wMed := 0
	RodFightState()
	RfReelZones()
	RfHudShow()
	RfHudUpdate()
}

; The sides of the track the bar's centre cannot reach (SideBarRatio of the bar's width, at most
; 40 % of the track): MaxLeftBar and MaxRightBar.
RfReelZones() {
	global
	local inset
	inset := WhiteBarSize * SideBarRatio
	if (inset > (TrackRight - TrackLeft) * 0.4)
		inset := (TrackRight - TrackLeft) * 0.4
	MaxLeftBar := TrackLeft + inset, MaxRightBar := TrackRight - inset
}

RfReelLoop() {
	global
	local r
	Loop
		{
		r := RfReelFrame()
		if (r = "over")
			return RfReelOver()
		if (r != "")
			{
			RfReelLogEnd((r = "stop") ? "stopped" : "restart")
			return r
			}
		}
}

; Ends the fight: why, for the session numbers and the log.
RfReelEnd(why) {
	global MgOverWhy
	MgOverWhy := why
	return "over"
}

; ---- the reel log (new in Alpha 1.0) -------------------------------------------------------------
; One block per fight in Re-Fisch\reel.log: the bar's width, what the edge gate learned, every time
; the reel let go of the bar and why, and how the fight ended with how well it tracked. Written when
; the fight ends; past about 1 MB the file moves to reel.old.log and a new one starts.

RfReelLogStart() {
	global
	RfReelLogBuf .= "`r`n" . A_YYYY . "-" . A_MM . "-" . A_DD . " " . A_Hour . ":" . A_Min . ":" . A_Sec . "  " . RfVersion
		. "  rod " . SpecialRod . ", " . ControlMode . " mode, bar " . Round(WhiteBarSize) . " px wide`r`n"
}

; One line, stamped with the seconds since the fight started.
RfReelLog(line) {
	global RfReelLogBuf, RfFight
	t := (IsObject(RfFight) and RfFight.t0) ? (A_TickCount - RfFight.t0) / 1000.0 : 0
	RfReelLogBuf .= Format("  {:6.2f} s  {}", t, line) . "`r`n"
}

; Counts one frame: the bar found, the fish found, the fish inside the bar. Alpha 1.1: the fish
; counts only when it was found on this frame (RfFishFresh); before, its last place counted too,
; so both fish figures read high.
RfReelCount(found) {
	global RfFight, FishX, RunLeft, RunWidth, RfFishFresh, RfBarStale
	m := RfFight
	m.nF += 1
	if (found)
		m.nBar += 1
	if (found and RfBarStale = 1)
		m.nStale += 1
	else if (found and RfBarStale = 2)
		m.nHeld += 1
	if (RfFishFresh)
		m.nFish += 1
	if (found and RfFishFresh and FishX >= RunLeft and FishX <= RunLeft + RunWidth)
		m.nOn += 1
	; Alpha 1.9: how close the fish stays to the bar's middle (left edge + width / 2)
	if (found and RfFishFresh and RunWidth > 0)
		{
		e := Abs(FishX - (RunLeft + RunWidth / 2))
		m.eSum := m.eSum + e, m.eW := m.eW + e / RunWidth, m.eN += 1
		if (e <= RunWidth / 6)
			m.eMid += 1
		}
}

; Alpha 1.6, for the reel log: frames per Pinions planner reason, numbers stripped ("go 120px"
; and "go 40px" count together). "go" and "cover both" happen once per note taken.
RfPnCount(why) {
	global RfFight
	m := RfFight
	if (!IsObject(m) or why = "")
		return
	k := Trim(RegExReplace(why, "-?[\d.]+\s*(px|s|%)?", ""))
	k := RegExReplace(RegExReplace(k, " +", " "), " :", ":")
	k := RTrim(k, " :")
	if (!IsObject(m.pn))
		m.pn := {}
	m.pn[k] := (m.pn.HasKey(k) ? m.pn[k] : 0) + 1
}

; One frame's time (ms since the last one), for the log's frame-time line.
RfReelTime(dt) {
	global RfFight
	m := RfFight
	if (!IsObject(m) or !m.t0 or dt <= 0)
		return
	m.dtSum := m.dtSum + dt, m.dtN += 1, m.nSlow += (dt >= 40)
	if (dt > m.dtMax)
		m.dtMax := dt
}

; The gate has (on) or no longer has the reel let go of the bar.
RfReelLetGo(on) {
	global RfFight
	if (on)
		RfFight.nLet += 1
	else if (RfFight.letting)
		RfReelLog("steering again")
	RfFight.letting := on
}

; The fight's last line (how it ended and how it tracked), then the block goes to the file.
RfReelLogEnd(why) {
	global RfFight
	static says := {uigone: "ended: the reel UI went", barlost: "ended: bar and fish line lost for 0.75 s"
		, nofishline: "ended: no fish for 8 s", nofish60: "ended: Noiseform lost the fish", forcereset: "ended: failsafe time"
		, stopped: "fishing stopped", restart: "ended: Tranquility never started", "lullaby-done": "ended: Lullaby done"}
	m := RfFight
	if (IsObject(m) and m.t0)
		RfReelLog(Format("{}. {} frames: bar found {}%, fish found {}%, fish on the bar {}%; bar and line lost {} frames, let go {} frames"
			, says.HasKey(why) ? says[why] : "ended" . (why = "" ? "" : ": " . why), m.nF + m.nLostF
			, Round(100 * m.nBar / Max(1, m.nF)), Round(100 * m.nFish / Max(1, m.nF)), Round(100 * m.nOn / Max(1, m.nF)), m.nLostF, m.nLet))
	; Alpha 1.9: centring (frames with the bar and a fresh fish)
	if (IsObject(m) and m.t0 and m.eN)
		RfReelLog(Format("centring: fish {:.1f} px from the bar's middle on average ({}% of the bar's width), in its middle third {}% of frames"
			, m.eSum / m.eN, Round(100 * m.eW / m.eN), Round(100 * m.eMid / m.eN)))
	; Pinions Aria: what the planner did, in frames (go / cover both: once per note taken)
	if (IsObject(m) and m.t0 and IsObject(m.pn))
		{
		pnTxt := ""
		for pnK, pnV in m.pn
			pnTxt .= (pnTxt = "" ? "" : ", ") . pnK . " " . pnV
		RfReelLog("Pinions planner, frames: " . pnTxt)
		}
	; Lines mode (Pinions Aria): how much of "bar found" was an old bar position
	if (IsObject(m) and m.t0 and (m.nStale or m.nHeld))
		RfReelLog(Format("bar not really seen: old position reused {}% of frames (up to 12 frames old), kept only by the fish line {}%"
			, Round(100 * m.nStale / Max(1, m.nF)), Round(100 * m.nHeld / Max(1, m.nF))))
	if (IsObject(m) and m.t0 and m.dtN)
		RfReelLog(Format("frame time: average {:.1f} ms ({} fps), worst {:.1f} ms, {} frames took 40 ms or more"
			, m.dtSum / m.dtN, Round(1000.0 * m.dtN / m.dtSum), m.dtMax, m.nSlow))
	RfReelLogFlush()
}

RfReelLogFlush() {
	global RfReelLogBuf, RfDataDir
	if (RfReelLogBuf = "")
		return
	f := RfDataDir . "\reel.log"
	FileGetSize, size, %f%
	if (size > 1000000)
		FileMove, %f%, %RfDataDir%\reel.old.log, 1
	FileAppend, %RfReelLogBuf%, %f%, UTF-8
	RfReelLogBuf := ""
}

; One frame of the fight: "" to go on, "over", "stop" or "restart".
RfReelFrame() {
	global
	local found, seen, now
	if (!MacroRunning)
		return "stop"
	if (ForceReset == true)
		return RfReelEnd("forcereset")
	; frame timing for the dashboard: PfDt (ms since the last frame) and PfCap (the capture)
	DllCall("QueryPerformanceCounter", "Int64*", now)
	PfDt := PfPrev ? Round((now - PfPrev) * 1000.0 / QpcFreq, 1) : 0
	PfPrev := now
	RfReelTime(PfDt)
	Sleep, 0
	if (SwPressK)
		SwPressTick()
	DllCall("QueryPerformanceCounter", "Int64*", now)
	RfCapFrame()
	PfCap := RfMsSince(now)
	if (!RfOwnReelUi() and RfGateTick() = "gone")
		return RfReelEnd("uigone")
	if (RfHandsOff(false))
		{
		RfReelLetGo(true)
		Sleep, 10
		return ""
		}
	RfReelLetGo(false)
	if (SpecialRod = "Lullaby")
		return RfReelLullaby()
	if (SpecialRod = "Tranquility")
		return RfReelMania()
	if (SpecialRod = "Bellona's Waraxe")
		return RfReelBellona()
	found := RfReelBarSeen(seen)
	if (!found and !seen)
		return RfReelLost()
	RfReelBack()
	if (found and RunWidth > 0)
		RfReelWidth()
	FishX := RfFishFind()
	RfReelCount(found)
	if (SpecialRod = "Stellarwave Melody")
		SwClickStep()
	if (RfReelNoFish())
		return RfReelEnd("nofishline")
	RfReelTarget()
	if (DarkFlashing)
		{
		; Darkheart's flashes: no picture, so hold for the share of time the fish needed lately
		DarkAcc := DarkAcc + RfFight.duty       ; (not "+=": on its own line that is AutoHotkey's
		if (DarkAcc >= 1)                        ;  old EnvAdd, which keeps only 6 decimals)
			DarkAcc -= 1, RfPress(true)
		else
			RfPress(false)
		return ""
		}
	if (FishX >= 0 and RunWidth > 0)
		RfReelDuty()
	if (FishX < 0 and SpecialRod = "Noiseform")
		return RfReelNoiseLost()
	if (SpecialRod = "Noiseform")
		NoiseLostN := 0
	if (FishX < 0)
		RfPress(RfDutyStep("blindAcc", RfFight.duty))     ; no fish: the duty guess
	else if (ControlMode = "Precision" or ControlMode = "Lines" or SpecialRod = "Requiem")
		RfSteer(found)
	else
		RfPulse(found)
	return ""
}

; Milliseconds since performance-counter time t, to 0.1.
RfMsSince(t) {
	global QpcFreq
	DllCall("QueryPerformanceCounter", "Int64*", now)
	return Round((now - t) * 1000.0 / QpcFreq, 1)
}

; Rods that draw their own reel UI (the edge gate does not watch them).
RfOwnReelUi() {
	global SpecialRod
	return (SpecialRod = "Tranquility" or SpecialRod = "Lullaby" or SpecialRod = "Stellarwave Melody")
}

; The bar (true when found and not a sliver under 20 % of the measured width, on rods that use
; the plain bar) and, through seen, whether the minigame still shows: the fish line, or on most
; rods the arrow.
RfReelBarSeen(ByRef seen) {
	global
	local found
	found := RfBarFind()
	if (found and (SpecialRod = "None" or SpecialRod = "Splitbranch Twig") and RfFight.cal > 0 and RunWidth < RfFight.cal * 0.2)
		found := false
	; On a normal Precision rod a found bar already establishes visibility. Other
	; scanners (including Lines) can update rod state, so keep those calls.
	seen := (found and SpecialRod = "None" and ControlMode != "Lines") ? true : RfFishLineSeen()
	if (!found and !seen and SpecialRod != "Remembrance" and SpecialRod != "MiguRod" and SpecialRod != "Halibut Harpoon"
		and SpecialRod != "Tryhard Rod" and SpecialRod != "Stellarwave Melody")
		seen := (RfArrowFind() >= 0)
	return found
}

; Neither bar nor fish line: let go of everything on the first such frame (and check whether a
; cast began charging), hide the display after 150 ms, give up after 750 ms.
RfReelLost() {
	global
	local now, ms
	NoiseFoundStreak := 0
	RfFight.lost += 1, RfFight.nLostF += 1
	if (RfFight.lost = 1)
		{
		RfReelLog("bar and fish line both missing: let go")
		ReFishSpaceRelease()
		if (RfGate.state != "armed" and !SwPressK and !(KittyMode() and KittyMouseStage))
			gosub, CastChargeCheck
		if (!SwPressK and !(KittyMode() and KittyMouseStage))
			Send, {LButton up}
		SwWantK := 0, PrecisionDown := false
		DllCall("QueryPerformanceCounter", "Int64*", now)
		RfFight.lostAt := now, RfFight.hudHidden := false
		}
	DllCall("QueryPerformanceCounter", "Int64*", now)
	ms := (now - RfFight.lostAt) * 1000.0 / QpcFreq
	if (!RfFight.hudHidden and RfFight.lostAt and ms > 150)
		{
		RfHudHide()
		RfFight.hudHidden := true
		}
	if (RfFight.lostAt and ms > 750)
		return RfReelEnd("barlost")
	return ""
}

; Seen again after a loss: the display back.
RfReelBack() {
	global
	if (RfFight.lost and RfHud.built and RfFight.hudHidden)
		RfHudShow()
	if (RfFight.lost)
		RfReelLog("seen again after " . RfFight.lost . " lost frames")
	RfFight.hudHidden := false, RfFight.lost := 0, RfFight.lostAt := 0
	NoiseFoundStreak += 1
}

; The bar's width over the fight. Trusted reads not far over the measured width go into a ring of
; 5 (RfReelWidthPush; its median is the width) when within 25 % of the median; 4 reads in a row that
; agree with each other (within 15 %) but not with the median start the ring over. The width in use
; (WhiteBarSize, and the no-go sides) follows when it moves by more than 20 %.
RfReelWidth() {
	global
	local m, size
	m := RfFight
	if (BarWidthTrusted and !(m.cal > 0 and RunWidth > m.cal * 1.3))
		{
		if (m.wMed <= 0 or Abs(RunWidth - m.wMed) <= m.wMed * 0.25)
			{
			RfReelWidthPush(RunWidth)
			m.wOutN := 0, m.wOutFirst := 0
			}
		else
			{
			if (m.wOutN > 0 and m.wOutFirst > 0 and Abs(RunWidth - m.wOutFirst) <= m.wOutFirst * 0.15)
				m.wOutN += 1
			else
				m.wOutFirst := RunWidth, m.wOutN := 1
			if (m.wOutN >= 4)
				{
				RfReelWidthsForget()
				RfReelWidthPush(RunWidth)
				}
			}
		}
	size := (m.wMed > 0) ? m.wMed : RunWidth
	if (SpecialRod = "Noiseform" and NoiseWCal >= 40)
		size := NoiseWCal
	if (!RfHud.zones and RfHud.built and (SpecialRod != "Noiseform" or NoiseWCal >= 40))
		RfHud.zones := true, RfHud.dirty := true
	BarWTrust := (m.wMed > 0 and Abs(RunWidth - m.wMed) <= m.wMed * 0.25) ? RunWidth : size
	if (BarWidthTrusted and Abs(size - WhiteBarSize) > WhiteBarSize * 0.2)
		{
		WhiteBarSize := size, HalfBarSize := WhiteBarSize / 2
		RfReelZones()
		RfHudUpdate()
		}
}

; Adds a width to the ring (the last 5); wMed becomes its middle value (the upper one of two).
RfReelWidthPush(w) {
	global RfFight
	m := RfFight
	m.widths.Push(w)
	if (m.widths.Length() > 5)
		m.widths.RemoveAt(1)
	k := m.widths.Length() // 2 + 1
	for i, x in m.widths
		{
		below := 0, upTo := 0
		for j, y in m.widths
			below += (y < x), upTo += (y <= x)
		if (below < k and upTo >= k)
			{
			m.wMed := x
			break
			}
		}
}

; Empties the width ring (also when Kitty Keys starts a new sign set).
RfReelWidthsForget() {
	global RfFight
	if (IsObject(RfFight))
		RfFight.widths := [], RfFight.wMed := 0, RfFight.wOutN := 0, RfFight.wOutFirst := 0
}

; No fish for 8 s ends the fight (not on rods that lose the fish between notes).
RfReelNoFish() {
	global
	if (SpecialRod = "Tranquility" or SpecialRod = "Lullaby" or SpecialRod = "Noiseform")
		return false
	if (FishX >= 0)
		RfFight.noFishAt := 0
	else if (!RfFight.noFishAt)
		RfFight.noFishAt := A_TickCount
	else if (A_TickCount - RfFight.noFishAt > 8000)
		return true
	return false
}

; Notes: rods with notes (Pinions Aria, Noiseform, Halibut Harpoon) steer toward a note instead of,
; or blended with, the fish (NoteBias %). Sets FishX and TargetIsNote; draws the markers.
RfReelTarget() {
	global
	local note, w
	note := NoteTarget()
	TargetIsNote := false
	RfHudNote(DarkFlashing ? FishX : ((SpecialRod = "Pinions Aria" and note < 0 and NoteBias >= 100) ? NoteHoldX : note))
	if (SpecialRod = "Remembrance")
		RfHudNote(RemBlackX)
	RfHudNote((SpecialRod = "Pinions Aria" and !DarkFlashing) ? NoteNextX : -1, true)
	if (FishX >= 0)
		RfHudFish(FishX)
	if (SpecialRod = "Pinions Aria")
		{
		FishX := PinionPlan(FishX, note, TargetIsNote)
		RfPnCount(PnWhy)
		PinionTip()
		return
		}
	if (note < 0)
		return
	w := (SpecialRod = "Noiseform" or SpecialRod = "Halibut Harpoon") ? 100 : NoteBias
	w := (w < 0) ? 0 : (w > 100) ? 100 : w
	if (SpecialRod = "Halibut Harpoon" and FishX >= 0 and RunWidth > 0)
		note := Min(Max(note, FishX - RunWidth * 0.42), FishX + RunWidth * 0.42)
	if (FishX >= 0)
		FishX := ((note * w) + (FishX * (100 - w))) / 100
	else if (SpecialRod != "Noiseform" and SpecialRod != "Halibut Harpoon")
		FishX := note
	TargetIsNote := (w >= 60)
}

; The share of time the button was down while the fish sat on the bar (within 30 px, or the note
; zone) is learned slowly: duty, used when there is no picture to steer by.
RfReelDuty() {
	global
	local near
	near := TargetIsNote ? NoteHoldZone(RunWidth) : 30
	if (near < 30)
		near := 30
	if (Abs(FishX - (RunLeft + RunWidth / 2)) < near)
		RfFight.duty := RfFight.duty * 0.9 + (PrecisionDown ? 0.1 : 0)
}

; Noiseform without a fish: let go; after 60 frames and 2 s, over.
RfReelNoiseLost() {
	global
	NoiseLostN += 1
	if (NoiseLostN = 1)
		NoiseLostAt := A_TickCount
	RfPress(false)
	if (NoiseLostN >= 60 and A_TickCount - NoiseLostAt >= 2000)
		return RfReelEnd("nofish60")
	return ""
}

; A duty accumulator in RfFight (name): adds add; true (hold this frame) each time it passes 1.
RfDutyStep(name, add) {
	global RfFight
	RfFight[name] += add
	if (RfFight[name] < 1)
		return false
	RfFight[name] -= 1
	return true
}

; ---- rods with a reel minigame of their own ------------------------------------------------------

; Lullaby: click on each light sector its scanner calls; over 25 frames after its UI goes.
RfReelLullaby() {
	global
	if (LullScan())
		{
		Send, {LButton down}
		Sleep, 20
		Send, {LButton up}
		LullClicks += 1
		RfTip9 := "Lullaby: " . LullSecN . " light sector(s), hits " . LullClicks . " (last #" . LullHitSec . ")"
		}
	if (LullActive)
		LullSeen := true, LullGoneN := 0
	else if (LullSeen)
		{
		LullGoneN += 1
		if (LullGoneN >= 25)
			return RfReelEnd("lullaby-done")
		}
	return ""
}

; Tranquility: its note game step by step. When it ends: over, or, if it never started in time,
; a failed cast and a fresh one (no fight-over handling).
RfReelMania() {
	global
	local now
	DllCall("QueryPerformanceCounter", "Int64*", now)
	if (ManiaStep(now / QpcFreq))
		return ""
	if (!TqExpired)
		return "over"
	CastFailCount += 1, ForceReEquip := true, RfTip10 := ""
	return "restart"
}

; Bellona's Waraxe: two bars driven by its own code. Lost 8 frames, or no strong read for 150, is
; over.
RfReelBellona() {
	global
	local r
	r := BellonaScan()
	BelNoStrong := (r = 2) ? 0 : BelNoStrong + 1
	if (r = 0)
		{
		RfFight.lost += 1
		if (RfFight.lost = 1)
			BellonaRelease()
		return (RfFight.lost >= 8) ? "over" : ""
		}
	RfFight.lost := 0
	if (BelNoStrong >= 150)
		{
		BellonaRelease()
		return "over"
		}
	BellonaDrive(1), BellonaDrive(2)
	if (BelOK[1])
		{
		if (BelF[1] >= 0)
			RfHudFish(FishBarLeft + BelF[1])
		RfHudBarSpan(FishBarLeft + BelA[1], BelB[1] - BelA[1])
		}
	if (BelOK[2])
		{
		if (BelF[2] >= 0)
			RfHudFish(FishBarLeft + BelF[2], true)
		RfHudBar2Span(FishBarLeft + BelA[2], BelB[2] - BelA[2])
		}
	if (RfHud.note >= 0)
		RfHudNote(-1)
	if (RfHud.note2 >= 0)
		RfHudNote(-1, true)
	if (RfHud.zones)
		RfHud.zones := false, RfHud.dirty := true
	return ""
}

; ---- the fight is over -----------------------------------------------------------------------------

; Lets go of everything (twice over, for a release Roblox may miss), notes the result, re-equips
; next time if a cast had begun charging, waits RestartDelay ms. Returns "restart".
RfReelOver() {
	global
	ReFishSpaceRelease()
	RfFightEnd(MgOverWhy)
	RfReelLogEnd(MgOverWhy)
	if (SwPressK)
		SwPressEnd()
	SwWantK := 0
	RfBarForget("live")
	if (!MgCastCharged and GetKeyState("LButton"))
		gosub, CastChargeCheck
	Send, {LButton up}
	Send, {RButton up}
	PrecisionDown := false, MgInPlay := false
	SetTimer, RfReelFailsafe, Off
	Send, {LButton up}
	Send, {RButton up}
	if (MgCastCharged)
		{
		MgCastCharged := false
		if (RodSlotKey != "")
			ForceReEquip := true
		}
	RfTip10 := "", RfTip11 := "", RfTip12 := "", RfTip13 := "", RfTip15 := ""
	RfHudHide()
	Sleep, % RestartDelay
	return "restart"
}

; Once a second from the bite: after BarCalculationFailsafe seconds, a failed cast (re-equip
; next time) and the fight given up.
RfReelFailsafe:
BarCalcFailsafeCounter += 1
RfTip10 := "Failsafe: " . BarCalcFailsafeCounter . "/" . BarCalculationFailsafe
if (BarCalcFailsafeCounter >= BarCalculationFailsafe)
	{
	SetTimer, RfReelFailsafe, Off
	CastFailCount += 1, ForceReEquip := true, ForceReset := true
	RfStat("barfail")
	}
return

; ---- Precision steering ------------------------------------------------------------------------------
; The method is AsphaltCake's (IRUS): PD control on the bar's error from the fish, with velocities
; tracked over frames and a stopping distance. Per frame it decides "button down" or "up" (RfPress).

; One steering step (Precision / Lines mode, and Requiem). found: the bar was found this frame.
RfSteer(found) {
	global
	local m, ax, barX, err, rel, steady, stop, lo, hi, rs, zoneE, hold, want, barLeft, barWidth, source
	m := RfFight
	barLeft := RunLeft, barWidth := RunWidth, source := "bar"
	if (!found)
		{
		; no bar: Castbound guesses by the learned duty for 40 frames; rods that need their bar let go;
		; the rest steer by the arrow
		if (SpecialRod = "Castbound" and m.castBlind < 40)
			{
			m.castBlind += 1
			return RfSteerApply(RfDutyStep("noteAcc", m.duty))
			}
		if (SpecialRod = "Remembrance" or SpecialRod = "MiguRod" or SpecialRod = "Halibut Harpoon"
			or SpecialRod = "Tryhard Rod" or SpecialRod = "Stellarwave Melody")
			return RfPress(false)
		ax := RfArrowFind()
		if (ax < 0)
			return RfPress(false)
		RfHudBarC(ax)
		if (SpecialRod != "None")
			return RfSteerApply((ax > FishX) ? false : true)
		barWidth := (WhiteBarSize > 0) ? WhiteBarSize : m.cal
		if (barWidth <= 0)
			return RfPress(false)
		barLeft := ax - barWidth / 2, source := "arrow"
		}
	barX := barLeft + barWidth / 2
	m.castBlind := 0
	if (found)
		RfHudBarSpan(RunLeft, RunWidth)
	if (SpecialRod = "Dreambreaker" and !m.dbFlip)
		RfDreamWatch(barX)
	RfSteerTrack(barX, source)
	err := barX - FishX, rel := m.barVel - m.fishVel
	steady := (TargetIsNote and SpecialRod != "Halibut Harpoon")     ; a note holds still
	if (SpecialRod = "Noiseform")
		stop := RfClampTo(Abs(rel) * StoppingDistanceMultiplier * 0.04, CaptureW * 0.01, barWidth * 0.5)
	else
		stop := Abs(rel) * StoppingDistanceMultiplier
	if (steady and SpecialRod != "Noiseform")
		stop := stop * 1.6
	; where the bar's centre can go, and the centre zone (close and slow: hold it there by duty)
	lo := TrackLeft + barWidth / 2, hi := TrackRight - barWidth / 2
	rs := (ResolutionScaling > 0) ? ResolutionScaling : 1
	zoneE := 36 / rs
	if (zoneE > barWidth * 0.35)
		zoneE := barWidth * 0.35
	hold := (SpecialRod != "Requiem" and !steady and Abs(err) <= zoneE and Abs(rel) <= 120 / rs)
	if (SpecialRod = "Noiseform" and (FishX < barLeft or FishX > barLeft + barWidth))
		{
		if (NoiseFishFresh)
			NoiseStaleN := 0
		NoiseStuckN := 0, NoiseStuckRel := 0, NoiseLastBarX := Round(barX)
		}
	if (SpecialRod = "Castbound" and CastStatic and barLeft > FishBarLeft + 2 and barLeft + barWidth < FishBarRight - 2
		and Abs(err) <= barWidth * 0.5)
		want := RfDutyStep("noteAcc", 0.5)        ; Castbound's bar standing still: half duty
	else if (FishX < lo)
		want := false
	else if (FishX > hi)
		want := true
	else if (hold)
		want := RfSteerCentre(err, rel, rs)
	else if (SpecialRod = "Pinions Aria" and (PnState = 1 or PnRes) and Abs(err) > NoteHoldZone(barWidth))
		want := RfPinTravel(err, rel)
	else if (SpecialRod = "Castbound")
		want := RfSteerSigma(err + (rel * Abs(rel)) / (2 * 1000.0 * (3.0 / ((StoppingDistanceMultiplier <= 0) ? 3.0 : StoppingDistanceMultiplier))))
	else if (SpecialRod = "Halibut Harpoon" and TargetIsNote)
		want := RfSteerSigma(err + rel * 0.55)
	else if (FishX >= barLeft and FishX <= barLeft + barWidth)
		want := RfSteerInside(err, rel, barX, stop, steady)
	else
		want := RfSteerOutside(err, rel, steady)
	return RfSteerApply(want)
}

; Alpha 1.7: Pinions Aria travelling to a note. Holds (or lets go) all the way and switches only
; where the bar can just brake onto the target: err + v|v| / 2A, plus 60 ms of lag. Measured on
; video (2026-11-09) this bar speeds up at about 1200 px/s² at 1920 px (0.63 window widths/s²);
; A is set lower (0.45) so it overshoots less. The PD rule it replaces lets go once the speed in
; px/s passes the distance in px (with Kp = Kd), so long moves crawled with rapid clicks: in a
; simulation 300 px took 1.6 s that way and 0.7 s this way.
RfPinTravel(err, rel) {
	global WindowWidth
	a := ((WindowWidth > 0) ? WindowWidth : 1920) * 0.45
	return ((err + rel * Abs(rel) / (2 * a) + rel * 0.06) > 0) ? false : true
}

; v held to lo .. hi, the low limit applied first. Returned as an expression: AutoHotkey v1 hands
; back a plain variable's decimal number as 6-digit text, and these values feed accumulators.
RfClampTo(v, lo, hi) {
	if (v < lo)
		v := lo
	if (v > hi)
		v := hi
	return v + 0.0
}

; Bar and fish velocities (px per s), timed at capture rather than after scanning.
; Switching between the bar and its arrow, or a gap over 100 ms, starts a fresh
; derivative: source offsets and stale observations must not become velocity spikes.
RfSteerTrack(barX, source := "bar") {
	global
	local m, now, vb, vf, a, dt
	m := RfFight
	now := RfCapAt
	if (!now)
		DllCall("QueryPerformanceCounter", "Int64*", now)
	dt := m.prevT ? (now - m.prevT) / QpcFreq : 0
	if (m.prevT <= 0 or m.trackSource != source or dt > 0.1 or dt < 0)
		{
		m.prevBar := barX, m.prevFish := FishX, m.prevT := now, m.trackSource := source
		m.barVel := 0.0, m.fishVel := 0.0, RfSteerDt := 0
		return
		}
	if (dt <= 0.0005)
		return
	RfSteerDt := dt
	vb := (barX - m.prevBar) / dt, vf := (FishX - m.prevFish) / dt
	if (Abs(FishX - m.prevFish) > 100 or TargetIsNote)
		vf := 0, m.fishVel := 0
	a := VelocitySmoothing
	if (SpecialRod = "Noiseform" and NoiseRate > 1 and a > 0 and a < 1)
		a := 1 - ((1 - a) ** NoiseRate)
	if (SpecialRod != "Noiseform" and a < 0.6)
		a := 0.6
	m.barVel := a * vb + (1 - a) * m.barVel, m.fishVel := a * vf + (1 - a) * m.fishVel
	m.prevBar := barX, m.prevFish := FishX, m.prevT := now
}

; Close to the fish and slow: hold by duty, 46.3 % plus a slowly learned bias, less a P and D share
; of the error (gains scaled for the resolution).
RfSteerCentre(err, rel, rs) {
	global RfFight, RfSteerDt
	kp := 0.0122 * rs, kd := 0.00488 * rs
	if (RfSteerDt > 0 and RfSteerDt < 0.1)
		RfFight.ctrBias := RfClampTo(RfFight.ctrBias - (0.25 * kp * err * RfSteerDt), -0.2, 0.2)
	return RfDutyStep("ctrAcc", RfClampTo(0.463 + RfFight.ctrBias - (kp * err) - (kd * rel), 0, 1))
}

; Bang-bang on a switching value with a dead band of 2 % of the bar (2 px at least): past it on
; the right, let go; on the left, hold; inside, keep the button as it is.
RfSteerSigma(sigma) {
	global RunWidth, PrecisionDown
	dead := RunWidth * 0.02
	if (dead < 2)
		dead := 2
	return (sigma > dead) ? false : (sigma < -dead) ? true : PrecisionDown
}

; The fish is on the bar.
RfSteerInside(err, rel, barX, stop, steady) {
	global
	local zone, look
	if (SpecialRod = "Noiseform")
		return RfSteerNoise(err, rel, barX)
	if (steady and Abs(err) <= NoteHoldZone(RunWidth))
		{
		; on a note: hold by duty, less a share of the error and of the bar's speed
		zone := NoteHoldZone(RunWidth)
		return RfDutyStep("noteAcc", RfClampTo(RfFight.duty - (err / (zone * 5.4)) - (RfFight.barVel * 0.0016), 0, 1))
		}
	if (err < -stop)
		return true
	if (err > stop)
		return false
	; within the stopping distance: aim where the bar will be a moment ahead (Kd / Kp s)
	RfFight.noteAcc := 0
	look := RfClampTo((Kp > 0) ? (Kd / Kp) : 0.12, 0.02, steady ? 0.25 : 1.50)
	return ((err + (rel * look)) > 0) ? false : true
}

; The fish is off the bar: PD on the error.
RfSteerOutside(err, rel, steady) {
	global Kp, Kd, SpecialRod
	if (SpecialRod = "Noiseform")
		out := Kp * err + Kd * rel * 0.60
	else if (steady)
		out := Kp * (err + (rel * RfClampTo((Kp > 0) ? (Kd / Kp) : 0.12, 0.02, 0.25)))
	else
		out := Kp * err + Kd * rel
	return (out > 0) ? false : true
}

; Noiseform with the fish on the bar: counts stale fish reads and a bar stuck while held (both
; feed RfSteerApply), then steers by a small zone around its target or by PD.
RfSteerNoise(err, rel, barX) {
	global
	local bx, slack
	if (NoiseFishFresh)
		NoiseStaleN := 0
	else
		NoiseStaleN += 1
	bx := Round(barX)
	if (PrecisionDown and Abs(bx - NoiseLastBarX) <= 2 and Abs(err) > 100)
		NoiseStuckN += 1
	else if (Abs(bx - NoiseLastBarX) > 2)
		NoiseStuckN := 0, NoiseLastBarX := bx
	if (NoiseStuckN >= NoiseN6 and !PrecisionDown)
		{
		NoiseStuckRel += 1
		if (NoiseStuckRel >= 12)
			NoiseStuckN := 0, NoiseStuckRel := 0, NoiseLastBarX := bx
		}
	else
		NoiseStuckRel := 0
	slack := (NoiseZoneTgt >= 0) ? Round(CaptureW * 0.030) : 0
	NoiseOnZoneN := (NoiseZoneTgt >= 0 and slack > 0 and Abs(err) <= slack) ? NoiseOnZoneN + 1 : 0
	if (slack > 0 and Abs(err) <= slack)
		return ((err + (rel * 0.12)) > 0) ? false : true
	return ((Kp * err + Kd * rel * 0.60) > 0) ? false : true
}

; Dreambreaker flips the controls partway through a fight: when the bar first moved (by more than
; 6 px, scaled), and when it was first seen.
RfDreamWatch(barX) {
	global
	local now
	DllCall("QueryPerformanceCounter", "Int64*", now)
	if (RfFight.dbX0 < 0)
		{
		RfFight.dbX0 := barX
		if (!RfFight.dbSeen)
			RfFight.dbSeen := now
		}
	else if (!RfFight.dbMove and Abs(barX - RfFight.dbX0) > Max(6, 12 * WindowHeight / 1440))
		RfFight.dbMove := now
}

; The decision, after the rods' vetoes: Noiseform holds off until the fish has been found 6 frames
; running, while the bar is stuck, and (15 frames at a time) on stale fish reads; Dreambreaker
; inverts it 1.4 s after the bar first moved or 3.1 s after it was first seen.
RfSteerApply(want) {
	global
	local now
	if (SpecialRod = "Noiseform" and want and !PrecisionDown and NoiseFoundStreak < NoiseN6)
		want := false
	if (SpecialRod = "Noiseform" and NoiseStuckN >= NoiseN6)
		want := false
	if (SpecialRod = "Noiseform" and want and !PrecisionDown and NoiseStaleN >= NoiseN6 and !(NoiseZoneTgt >= 0 and NoiseZOK))
		{
		NoiseStaleBlk += 1
		if (NoiseStaleBlk < NoiseN15)
			want := false
		else
			NoiseStaleBlk := 0
		}
	else
		NoiseStaleBlk := 0
	if (SpecialRod = "Dreambreaker" and !RfFight.dbFlip and RfFight.dbSeen)
		{
		DllCall("QueryPerformanceCounter", "Int64*", now)
		if ((RfFight.dbMove and (now - RfFight.dbMove) / QpcFreq >= 1.4) or (now - RfFight.dbSeen) / QpcFreq >= 3.1)
			RfFight.dbFlip := true
		}
	if (SpecialRod = "Dreambreaker" and RfFight.dbFlip)
		want := !want
	RfHumanNow := true          ; Alpha 2.1: only steering presses keep the human-like minimum (RfPress)
	RfPress(want)
	RfHumanNow := false
}

; The reel button down or up. Kitty Keys steers with Space (ReFishSteer). A held button is sent
; again when Windows lost it, and every 400 ms. Requiem (and Stellarwave while it clicks) keep a
; minimum time between changes; Stellarwave's own clicks and parked cursor come first.
RfPress(down) {
	global
	local now, gap
	if (KittyMode())
		return ReFishSteer(down)
	if (down)
		{
		if (SpecialRod = "Stellarwave Melody" and (SwPressK or SwWantK))
			return
		if (!PrecisionDown)
			{
			gap := (SpecialRod = "Requiem") ? ReelMinRelease : ((SpecialRod = "Stellarwave Melody" and SwPhase) ? SwMinRelease() : 0)
			if (gap <= 0 and HumanClicks and RfHumanNow)
				gap := RfHumanGap
			if (gap > 0 and PrecisionUpAt)
				{
				DllCall("QueryPerformanceCounter", "Int64*", now)
				if ((now - PrecisionUpAt) * 1000.0 / QpcFreq < gap)
					return
				}
			}
		else
			{
			DllCall("QueryPerformanceCounter", "Int64*", now)
			if (GetKeyState("LButton") and (now - PrecisionResendAt) * 1000.0 / QpcFreq < 400)
				return
			}
		if (SwPreK)
			return SwPreEnd("reel")
		if (SwParkAt and SwParkWait())
			return
		Send, {LButton down}
		if (PrecisionDown)
			{
			PrecisionResendAt := now        ; a resend
			return
			}
		PrecisionDown := true
		DllCall("QueryPerformanceCounter", "Int64*", PrecisionDownAt)
		PrecisionResendAt := PrecisionDownAt
		RfHumanNext()
		return
		}
	if (!PrecisionDown)
		{
		if (GetKeyState("LButton") and !SwPressK)
			Send, {LButton up}
		return
		}
	gap := (SpecialRod = "Requiem") ? ReelMinHold : ((SpecialRod = "Stellarwave Melody" and SwPhase) ? 250 : 0)
	if (gap <= 0 and HumanClicks and RfHumanNow)
		gap := RfHumanGap
	if (gap > 0 and PrecisionDownAt)
		{
		DllCall("QueryPerformanceCounter", "Int64*", now)
		if ((now - PrecisionDownAt) * 1000.0 / QpcFreq < gap)
			return
		}
	Send, {LButton up}
	PrecisionDown := false
	DllCall("QueryPerformanceCounter", "Int64*", PrecisionUpAt)
	RfHumanNext()
}

; Alpha 2.1, "Human-like clicking" (Fishing tab, Reel): every press and every release lasts at
; least half a click at HumanCps clicks per second (1 to 20; 8 gives 62 ms), each time varied at
; random from 80 % to 125 % so the rhythm is not machine-even. Picks the next minimum (ms) into
; RfHumanGap after each change. In a simulation 8 per second kept the fish on the bar as often as
; no limit (99.8 % on the pearl video's fish), a few px further from the middle; under 6 it slips.
RfHumanNext() {
	global HumanClicks, HumanCps, RfHumanGap
	if (!HumanClicks)
		return
	cps := HumanCps + 0
	cps := (cps < 1) ? 1 : (cps > 20) ? 20 : cps
	Random, f, 0.80, 1.25
	RfHumanGap := 500.0 / cps * f
}

; ---- the pulse method (Normal control mode) ----------------------------------------------------------
; Pushes the bar toward the fish in timed pulses: hold (right) or let go (left) for a time scaled to
; the distance, stopping early once the bar reaches the fish (RfHoldTrack), then a counter-pulse and
; a burst of clicks to settle it. Reversing direction first waits out an "ankle break" delay that
; builds up while moving one way. Near the ends of the track (MaxLeftBar / MaxRightBar) it only
; pushes once toward the wall.

RfPulse(found) {
	global
	local barX, ax, d
	if (FishX < MaxLeftBar or FishX > MaxRightBar)
		return RfPulseWall(FishX < MaxLeftBar)
	MaxLeftToggle := false, MaxRightToggle := false
	if (found)
		{
		RfFight.sawBar := true
		barX := RunLeft + RunWidth / 2
		RfHudBarSpan(RunLeft, RunWidth)
		if (barX > FishX)
			d := Abs(barX - FishX) * ResolutionScaling * StableLeftMultiplier, RfPulseSide("Left", d, d / StableLeftDivision, false)
		else
			d := Abs(barX - FishX) * ResolutionScaling * StableRightMultiplier, RfPulseSide("Right", d, d / StableRightDivision, false)
		return
		}
	RfTip9 := "Bar NOT FOUND"
	if (!RfFight.sawBar)
		{
		; never seen the bar this fight: a tap keeps the reel alive while the minigame shows
		if (RfFishLineSeen() or RfArrowFind() >= 0)
			ReFishBarInput(true), ReFishBarInput(false)
		return
		}
	; steer by the arrow, half a bar's push at a time
	ax := RfArrowFind()
	if (ax < 0)
		ax := RfFindColourBgr(0x878584, ArrowColorTolerance)
	if (ax < 0)
		return
	RfHudBarC(ax)
	if (ax > FishX)
		d := HalfBarSize * UnstableLeftMultiplier, RfPulseSide("Left", d, d / UnstableLeftDivision, true)
	else
		d := HalfBarSize * UnstableRightMultiplier, RfPulseSide("Right", d, d / UnstableRightDivision, true)
}

; The fish is past a no-go side: one push toward that wall (let go for the left one, hold for the
; right), then the waiting side delay; nothing more until the fish comes back.
RfPulseWall(left) {
	global
	if (left ? MaxLeftToggle : MaxRightToggle)
		return
	RfHudBarSpan(RunLeft, RunWidth)
	DirectionalToggle := left ? "Right" : "Left"
	if (left)
		MaxLeftToggle := true
	else
		MaxRightToggle := true
	ReFishBarInput(!left)
	Sleep, 1
	ReFishBarInput(!left)
	Sleep, % SideDelay
	AnkleBreakDelay := 0, SideDelay := 0
}

; One pulse toward dir ("Left": let go, "Right": hold) for up to ms, then the counter-pulse.
RfPulseSide(dir, ms, counter, byArrow) {
	global
	local left, mult
	left := (dir = "Left")
	ReFishBarInput(!left)
	if (DirectionalToggle == (left ? "Right" : "Left"))
		{
		; reversing: the delay built up while going the other way
		Sleep, % AnkleBreakDelay
		AnkleBreakDelay := 0
		}
	else
		{
		mult := left ? LeftAnkleBreakMultiplier : RightAnkleBreakMultiplier
		AnkleBreakDelay := AnkleBreakDelay + (ms - counter) * mult
		SideDelay := AnkleBreakDelay / mult * SideBarWaitMultiplier
		}
	RfHoldTrack(ms, dir, byArrow)
	counter := counter * HeldFraction
	RfCapFrame()
	FishX := RfFishFind()
	if (RfHandsOff(true) or (left ? FishX < MaxLeftBar : FishX > MaxRightBar))
		return
	ReFishBarInput(left)
	Sleep, % counter
	RfPulseSettle()
	DirectionalToggle := dir
}

; After a counter-pulse: StabilizerLoop quick clicks, when the minigame still shows.
RfPulseSettle() {
	global
	if (KittyMode() or SpecialRod = "Requiem" or (SpecialRod = "Stellarwave Melody" and SwPhase))
		return
	RfCapFrame()
	if (!RfBarFind() and !RfFishLineSeen() and RfArrowFind() < 0)
		return
	if (RfHandsOff(true))
		return
	Loop, % StabilizerLoop
		{
		Send, {LButton down}
		Send, {LButton up}
		}
}


;====================================================================================================;
;   Rod state for the reel loop: DeepFish code moved out of the old reel loop in Alpha 0.8, to be
;   rewritten with each rod in section 3.
;====================================================================================================;

; Noiseform, at each bite (before the bar is measured).
NoiseBiteState() {
	global
	NoiseWCal := 0
	NoiseWCnt := {}
	NoiseWVote := 0
	NoisePrevC := -1
	NoisePrevT := 0
	NoiseVelC := 0
	NoiseCoastN := 0
	NoiseStillX := -1
	NoiseStillC := 0
	NoiseLostN := 0
	NoiseEHist := []
	NoiseBandT := -99
	NoiseBandB := -99
	NoiseRlW := 0
	NoiseRlN := 0
	NoiseFishPrev := -1
	NoiseFishT := 0
	NoiseFoundStreak := 0
	NoiseJumpHold := 0
	NoiseStuckN := 0
	NoiseStuckRel := 0
	NoiseStaleN := 0
	NoiseStaleBlk := 0
	NoiseOnZoneN := 0
	NoiseLastBarX := -1
	NoiseAltW := 0
	NoiseAltN := 0
	NoiseZSeenT := 0
	NoiseRate := 1
	NoiseRateT := 0
	NoiseN6 := 6
	NoiseN8 := 8
	NoiseN15 := 15
	NoiseN45 := 45
	RfHud.zones := false, RfHud.dirty := true
}

; Every rod's per-fight state (Bellona's Waraxe, Noiseform, Darkheart, notes, Pinions Aria, Lullaby,
; Lines mode, Castbound, Remembrance, MiguRod) and the second bar's display markers.
RodFightState() {
	global
	local DkI
	BelNoStrong := 0
	BelPrevT := [0,0]
	BelVel := [0,0]
	BelBVel := [0,0]
	BelSide := [0,0]
	BelAcc := [0,0]
	BelBias := [0,0]
	RfHud.fish2 := {tgt: -1, cur: -1}, RfHud.bar2 := {tgt: -1, cur: -1, w: 0}
	NoisePrevC := -1
	NoisePrevT := 0
	NoiseFishPrev := -1
	NoiseFishT := 0
	NoiseStillX := -1
	NoiseStillC := 0
	NoiseWCal := 0
	NoiseJumpN := 0
	NoiseJumpHold := 0
	NoiseStuckN := 0
	NoiseStuckRel := 0
	NoiseStaleN := 0
	NoiseStaleBlk := 0
	NoiseOnZoneN := 0
	NoiseLastBarX := -1
	NoiseRate := 1
	NoiseRateT := 0
	NoiseN6 := 6
	NoiseN8 := 8
	NoiseN15 := 15
	NoiseN45 := 45
	NoiseAltW := 0
	NoiseAltN := 0
	NoiseZSeenT := 0
	NoiseWCnt := {}
	NoiseWVote := 0
	NoiseLastD := 0
	NoiseOscN := 0
	NoiseVelC := 0
	NoiseLostN := 0
	NoiseRowOff := 0
	NoiseCoastN := 0
	NoiseWBase := 0
	NoiseWBaseML := 0
	NoiseWDthr := 6
	NoiseZoneTgt := -1
	NoiseZoneT := 0
	NoiseZoneKind := ""
	NoiseZScanT := 0
	NoiseZFreshT := 0
	NoisePendKind := ""
	NoisePendT := 0
	NoiseWNow := ""
	NoiseWBlk := 0
	NoiseDkRing := []
	NoiseMlRing := []
	NoiseD6Ring := []
	NoiseDkIdx := 0
	NoiseDkN := 0
	NoiseWGT := 0
	DkI := 0
	while (DkI < 32)
		{
		NoiseDkRing[DkI] := -1
		NoiseMlRing[DkI] := -1
		NoiseD6Ring[DkI] := -1
		DkI := DkI + 1
		}
	NoiseMissN := 0
	NoiseMissT := 0
	WMissN := 0
	WMissT := 0
	WRW := 0
	WRH := 0
	WRN := 0
	WRIdx := 0
	WRSkip := 0
	NoiseZWx := -1
	NoiseZGx := -1
	NoiseZKx := -1
	NoiseZOK := false
	NfPW := -1
	NfPG := -1
	NfPK := -1
	NfCW := -1
	NfCG := -1
	NfCK := -1
	NfIconN := 0
	NfGoneN := 0
	NfLatchKind := ""
	NfLatchT := 0
	NfRingN := 0
	NfRingIdx := 0
	NfWhy := ""
	NoiseEHist := []
	NoiseBandT := -99
	NoiseBandB := -99
	NoiseRlW := 0
	NoiseRlN := 0
	DarkAcc := 0
	DarkHoldN := 0
	DarkFlashing := false
	NoteLockX := -1
	NoteLockN := 0
	NoteNextX := -1
	NoteNextY := -1
	NoteLockY := -1
	NoteHoldX := -1
	PnState := 0
	PnChase := false
	PnIconAt := 0
	PnFall := 0
	PnFallN := 0
	PnRes := 0
	PnGlueAt := 0
	PnGlueLo := 0
	PnGlueHi := 0
	PnAwayAt := 0
	PnTwoN := 0
	PnResBlockUntil := 0
	PnPrevT := 0
	PnPrevY := -1
	PnPrevX := -1
	PnProg := -1
	PnNoteX := -1
	PnCoverX := -1
	PnImpactAt := 0
	PnWhy := ""
	PnSeenY := -1
	PnSeenAt := 0
	PnLandAt := 0
	PnLeaveAt := 0
	PnGone := false
	PnTipAt := 0
	LullFrames := 0
	LullCalN := 0
	LullR := 0
	LullSecN := 0
	LullCalLt := []
	LullCalDk := []
	LullCalLs := []
	LullBg := []
	LullSecA := []
	LullSecB := []
	LullArmA := []
	LullClrT := []
	LullActive := false
	LullSeen := false
	LullGoneN := 0
	LullClicks := 0
	NoteAllN := 0
	LineBarW := -1
	LineBarAge := 99
	CastPrevL := -1
	CastPrevW := -1
	CastPrevF := -1
	CastSameN := 0
	CastSameT := 0
	CastStatic := false
	RemWhiteX := -1
	RemBlackX := -1
	RemTargetX := -1
	MiguLastX := -1
	NoiseFoundStreak := 0
}

; Pinions Aria's status line (progress and why), at most every 0.2 s.
PinionTip() {
	global
	DllCall("QueryPerformanceCounter", "Int64*", PnTipNow)
	if (!PnTipAt or ((PnTipNow - PnTipAt) / QpcFreq) >= 0.2)
		{
		PnTipAt := PnTipNow
		PnTipTxt := "Pinions: progress "
		if (PnProg >= 0)
			PnTipTxt .= Round(PnProg * 100) . "%"
		else
			PnTipTxt .= "?"
		PnTipTxt .= "  |  " . PnWhy
		RfTip13 = %PnTipTxt%
		}
}

; Stellarwave Melody's minimum time with the reel button up before pressing again, while it clicks.
SwMinRelease() {
	global
	return (SwDwell and (SwRetryClicks ? (SwPressN + SwRetry < 3 and SwClickSlot != SwOverS) : !SwPressN)) ? 500 : (SwPreK ? 320 : (SwFastClicks ? 250 : 100))
}


;====================================================================================================;

;====================================================================================================;

LoadActiveProfile:

ConfigWarnings := ""

for i, f in ProfileFields
	{
	sec := f[1]
	key := f[2]
	def := f[3]
	type := f[4]
	SrcFile := (sec = "Aquarium" or sec = "Keeper" or (TotemGlobal and sec = "Totem")) ? SettingsFile : ActiveProfileFile
	IniRead, val, %SrcFile%, %sec%, %key%, %def%
	if (val = "ERROR" and def = "")
		val := ""
	if (val = "" and def != "")
		val := def
	if (!ProfFieldOk(type, val))
		{
		ConfigWarnings .= key . "`n"
		val := def
		IniWrite, %val%, %SrcFile%, %sec%, %key%
		}
	if (type = "bool")
		val := (val = "true") ? true : false
	%key% := val
	}

KittyShapeMin := Max(55, KittyShapeMin)
KittyShapeMargin := Max(10, KittyShapeMargin)
if (KittyKeysEnabled and StellarSkin = "Default")
    StellarSkin := "Kitty Keys" ; migrate the previous personal build
gosub, RfUtilitiesOff
if (ConfigWarnings != "")
	msgbox, 4144, Re:Fisch - Config Notice, One or more settings in "%ActiveProfile%.ini" were invalid and have been reset to defaults:`n`n%ConfigWarnings%

gosub, AstraMigrateColours
gosub, RefreshControlModes

return

;====================================================================================================;

ProfFieldOk(type, ByRef val) {
	if (type = "bool")
		return (val = "true" or val = "false")
	if (type = "shakemode")
		{
		if (val = "Click")
			val := "Navigation"
		return (val = "Navigation" or val = "Disabled")
		}
	if (type = "stellarskin")
		return (val = "Default" or val = "Kitty Keys")
	if (type = "kittyspeed")
		return (val = "Normal" or val = "Fast" or val = "Turbo")
	if (type = "specialrod")
		{
		if (val = "Pinion Aria")
			val := "Pinions Aria"
		return (val = "None" or val = "Pinions Aria" or val = "Requiem" or val = "Darkheart" or val = "Bellona's Waraxe" or val = "Dreambreaker" or val = "Tranquility" or val = "Noiseform" or val = "Verdant Oath" or val = "Lullaby" or val = "Castbound" or val = "Remembrance" or val = "MiguRod" or val = "Halibut Harpoon" or val = "Splitbranch Twig" or val = "Astraenus Serenade" or val = "Tryhard Rod" or val = "Chasm Stalker" or val = "Stellarwave Melody")
		}
	if (type = "remembrancemode")
		return (val = "Living" or val = "Departed")
	if (type = "controlmode")
		{
		if (val = "Classic")
			val := "Manual"
		return (val = "Manual" or val = "Precision" or val = "Lines")
		}
	if (type = "castmode")
		return (val = "Normal" or val = "Perfect")
	if (type = "totemsel")
		return (val = "None" or val = "Day" or val = "Night" or val = "Clearcast" or val = "Aurora" or val = "Starfall" or val = "Eclipse" or val = "Tempest" or val = "Windset" or val = "Smokescreen" or val = "Shiny" or val = "Sparkling" or val = "Mutation")
	if (type = "num")
		{
		if val is number
			return true
		return false
		}
	return true
}

BuildDefaultProfile:

for i, f in ProfileFields
	{
	sec := f[1]
	key := f[2]
	val := f[3]
	IniWrite, %val%, %DefaultProfileFile%, %sec%, %key%
	}

return






; ---- pixel finder -------------------------------------------------------------------------------------

PcSetPrm(ByRef prm, rgbHex, tol, mode, inv) {
	bgr := RfBgr(RfColFirst(rgbHex))
	VarSetCapacity(prm, 24, 0)
	NumPut((bgr >> 16) & 0xFF, prm, 0, "Int")
	NumPut((bgr >> 8) & 0xFF, prm, 4, "Int")
	NumPut(bgr & 0xFF, prm, 8, "Int")
	NumPut(tol, prm, 12, "Int")
	NumPut(mode, prm, 16, "Int")
	NumPut(inv, prm, 20, "Int")
}

PcFind(p, n, stride, ByRef prm) {
	if (n <= 0)
		return -1
	pFn := PcFindPixFn()
	if (pFn)
		return DllCall(pFn, "Ptr", p, "Int", n, "Int", stride, "Ptr", &prm, "Int")
	return PcFindPixAhk(p, n, stride, NumGet(prm, 0, "Int"), NumGet(prm, 4, "Int"), NumGet(prm, 8, "Int"), NumGet(prm, 12, "Int"), NumGet(prm, 16, "Int"), NumGet(prm, 20, "Int"))
}





TwigPrompt(ByRef lcx, ByRef rcx, ByRef labY) {
	global WindowLeft, WindowTop, WindowWidth, WindowHeight
	global hTwigDC, hTwigBM, pTwigBits, TwigW, TwigH, hTwigOld
	w := Round(WindowWidth * 0.20)
	h := Round(WindowHeight * 0.41)
	if (w < 60 or h < 60)
		return false
	x0 := Round(WindowWidth * 0.40)
	y0 := Round(WindowHeight * 0.17)
	if (TwigW != w or TwigH != h or !hTwigDC)
		{
		if (hTwigDC)
			{
			DllCall("SelectObject", "Ptr", hTwigDC, "Ptr", hTwigOld)
			DllCall("DeleteObject", "Ptr", hTwigBM)
			DllCall("DeleteDC", "Ptr", hTwigDC)
			}
		hSD := DllCall("GetDC", "Ptr", 0, "Ptr")
		hTwigDC := DllCall("CreateCompatibleDC", "Ptr", hSD, "Ptr")
		VarSetCapacity(bi, 40, 0)
		NumPut(40, bi, 0, "UInt")
		NumPut(w, bi, 4, "Int")
		NumPut(-h, bi, 8, "Int")
		NumPut(1, bi, 12, "UShort")
		NumPut(32, bi, 14, "UShort")
		NumPut(0, bi, 16, "UInt")
		hTwigBM := DllCall("CreateDIBSection", "Ptr", hTwigDC, "Ptr", &bi, "UInt", 0, "Ptr*", pTwigBits, "Ptr", 0, "UInt", 0, "Ptr")
		hTwigOld := DllCall("SelectObject", "Ptr", hTwigDC, "Ptr", hTwigBM, "Ptr")
		DllCall("ReleaseDC", "Ptr", 0, "Ptr", hSD)
		TwigW := w
		TwigH := h
		}
	hSD2 := DllCall("GetDC", "Ptr", 0, "Ptr")
	DllCall("BitBlt", "Ptr", hTwigDC, "Int", 0, "Int", 0, "Int", w, "Int", h
		, "Ptr", hSD2, "Int", WindowLeft + x0, "Int", WindowTop + y0, "UInt", 0x00CC0020)
	DllCall("ReleaseDC", "Ptr", 0, "Ptr", hSD2)

	pbH := Round(h * 0.17)
	white := 0
	y := 0
	while (y < pbH)
		{
		p := pTwigBits + (y * w * 4)
		x := 0
		while (x < w)
			{
			px := NumGet(p + 0, x * 4, "UInt")
			b := px & 0xFF
			g := (px >> 8) & 0xFF
			r := (px >> 16) & 0xFF
			mx := (r > g) ? ((r > b) ? r : b) : ((g > b) ? g : b)
			mn := (r < g) ? ((r < b) ? r : b) : ((g < b) ? g : b)
			if (mn > 225 and (mx - mn) < 30)
				white++
			x += 2
			}
		y += 2
		}
	if (white * 4 < (pbH * w) * 0.04)
		return false

	yb := Round(h * 0.878)
	half := w // 2
	lN := 0
	rN := 0
	lSum := 0
	rSum := 0
	ySum := 0
	y := yb
	while (y < h)
		{
		p := pTwigBits + (y * w * 4)
		x := 3
		while (x < w - 3)
			{
			px := NumGet(p + 0, x * 4, "UInt")
			b := px & 0xFF
			g := (px >> 8) & 0xFF
			r := (px >> 16) & 0xFF
			mx := (r > g) ? ((r > b) ? r : b) : ((g > b) ? g : b)
			if (mx > 185)
				{
				dark := false
				d := 1
				while (d <= 3)
					{
					q := NumGet(p + 0, (x - d) * 4, "UInt")
					if ((q & 0xFF) < 70 and ((q >> 8) & 0xFF) < 70 and ((q >> 16) & 0xFF) < 70)
						dark := true
					q := NumGet(p + 0, (x + d) * 4, "UInt")
					if ((q & 0xFF) < 70 and ((q >> 8) & 0xFF) < 70 and ((q >> 16) & 0xFF) < 70)
						dark := true
					d++
					}
				if (dark)
					{
					if (x < half)
						{
						lN++
						lSum += x
						}
					else
						{
						rN++
						rSum += x
						}
					ySum += y
					}
				}
			x += 2
			}
		y += 2
		}
	slot := ((h - yb) * half) * 0.035
	if (lN * 4 < slot or rN * 4 < slot)
		return false
	lcx := x0 + Round(lSum / lN)
	rcx := x0 + Round(rSum / rN)
	labY := y0 + Round(ySum / (lN + rN))
	return true
}

PcFindPixAhk(p, n, stride, tB, tG, tR, tol, mode, inv) {
	i := 0
	while (i < n)
		{
		px := NumGet(p + i * stride, 0, "UInt"), b := px & 0xFF, g := (px >> 8) & 0xFF, r := (px >> 16) & 0xFF
		hit := (Abs(b - tB) <= tol and Abs(g - tG) <= tol and Abs(r - tR) <= tol)
		if (!hit and mode = 1 and g > 80 and g - r > 22 and g - b > 22)
			hit := true
		if (!hit and mode = 2 and r > 200 and g > 200 and b > 200)
			{
			mx := r > g ? (r > b ? r : b) : (g > b ? g : b)
			mn := r < g ? (r < b ? r : b) : (g < b ? g : b)
			if (mx - mn < 32)
				hit := true
			}
		if ((hit ? 1 : 0) != inv)
			return i
		i++
		}
	return -1
}

PcFindPixFn() {
	static pFn := "", Hex := "5356575531C04889CE4D63C039D00F8D180100000FB61E0FB66E010FB67E024189DA452B11790341F7DA453B510C0F8F310000004189EA452B5104790341F7DA453B510C0F8F1B0000004189FA452B5108790341F7DA453B510C0F8F05000000E9A2000000458B51104183FA010F852E00000083FD500F8E9B0000004189EA4129FA4183FA160F8E8B0000004189EA4129DA4183FA160F8E7B000000E9660000004183FA020F856C00000081FFC80000000F8E6000000081FDC80000000F8E5400000081FBC80000000F8E480000004189DA4189DB4439D57E034189EA4439DD7D034189EB4439D77E034189FA4439DF7D034189FB4529DA4183FA200F8D15000000E90000000041837914000F841F000000E90B00000041837914000F850F000000FFC04C01C6E9E0FEFFFFB8FFFFFFFF5D5F5E5BC3"
	if (pFn != "")
		return pFn
	pFn := 0
	if (A_PtrSize != 8)
		return 0
	n := StrLen(Hex) // 2
	p := DllCall("VirtualAlloc", "Ptr", 0, "Ptr", n, "UInt", 0x3000, "UInt", 0x04, "Ptr")
	if (!p)
		return 0
	Loop, %n%
		NumPut("0x" . SubStr(Hex, 2 * A_Index - 1, 2), p + 0, A_Index - 1, "UChar")
	if (!DllCall("VirtualProtect", "Ptr", p, "Ptr", n, "UInt", 0x20, "UIntP", oldProt))
		{
		DllCall("VirtualFree", "Ptr", p, "Ptr", 0, "UInt", 0x8000)
		return 0
		}
	tw := 240
	VarSetCapacity(tBits, tw * 4, 0)
	seed := 4242
	Loop, %tw%
		{
		seed := Mod(seed * 1103515245 + 12345, 2147483648)
		v := (seed >> 8) & 0xFFFFFF
		m := Mod(A_Index, 23)
		if (m = 3)
			v := 0x61AC4A
		else if (m = 9)
			v := 0xF8FCFF
		else if (m = 14)
			v := 0x30C030
		else if (m = 19)
			v := 0xE0FFE0
		NumPut(v, tBits, (A_Index - 1) * 4, "UInt")
		}
	VarSetCapacity(prm, 24, 0)
	same := true
	sawHit := false
	sawMiss := false
	for i, pt in [[0x4A,0xAC,0x61,20,1,0], [0x4A,0xAC,0x61,20,1,1], [0xF3,0xFE,0xFF,25,2,0], [0xF3,0xFE,0xFF,25,2,1], [0x4A,0xAC,0x61,5,0,0], [0x10,0x20,0x30,0,0,0]]
		{
		Loop, 6
			NumPut(pt[A_Index], prm, (A_Index - 1) * 4, "Int")
		for j, S in [[0, 4], [tw - 1, -4], [5, 12]]
			{
			Loop, 8
				{
				st := S[1] + ((S[2] > 0) ? (A_Index - 1) * 5 : -(A_Index - 1) * 5)
				c := (S[2] > 0) ? ((tw - 1 - st) // (S[2] // 4) + 1) : (st + 1)
				a := DllCall(p, "Ptr", &tBits + st * 4, "Int", c, "Int", S[2], "Ptr", &prm, "Int")
				b := PcFindPixAhk(&tBits + st * 4, c, S[2], pt[1], pt[2], pt[3], pt[4], pt[5], pt[6])
				if (a != b)
					same := false
				if (a >= 0)
					sawHit := true
				else
					sawMiss := true
				}
			}
		}
	if (!same or !sawHit or !sawMiss)
		{
		DllCall("VirtualFree", "Ptr", p, "Ptr", 0, "UInt", 0x8000)
		return 0
		}
	pFn := p
	return pFn
}




;====================================================================================================;


;   Screen capture  (new in Alpha 0.6, written for Re:Fisch)
;
;   The reel code reads two copies of the screen, refreshed once per reel frame:
;     - the reel band: the reel area with 18 rows above it (the UI-edge checks) and 20 below
;       (plus CapExtra rows of room on Pinions Aria). pCaptureBits points at the reel area's top
;       row and pUiEdgeBits 18 rows higher; CaptureW pixels a row, 32-bit, top row first.
;     - the note area (pNoteBits, NoteW pixels a row) for rods that read above or around the reel.
;   How they are taken depends on the rod; RfCapSetup picks the plan once per session:
;     "reel"     no note area needed: one copy of the reel band.
;     "stacked"  the note area sits right on top of the reel band and is as wide: one tall copy,
;                and the reel band is a pointer into it.
;     "apart"    the note area is somewhere else (Pinions Aria reads its shake area): copied at
;                most every 45 ms (80 ms while a note is locked), the reel band every frame.
;     "around"   the note area holds the whole reel band (Stellarwave Melody): one copy, and the
;                band is copied out of it.
;   Both copies are RfSurface bitmaps, the same kind RfGrab keeps for the perfect cast.
;====================================================================================================;

; Sizes the reel band and the note area for the current rod and screen, and makes their surfaces.
; Called by RfMeasure at the start of every session.
RfCapSetup() {
	global
	CaptureW := Max(1, Round(FishBarRight - FishBarLeft))
	CaptureH := Max(1, Round(FishBarBottom - FishBarTop) + 1)
	CapExtra := (SpecialRod = "Pinions Aria") ? Round(WindowHeight * 0.035) : 0
	PinionCapPrep()
	RfGateSetup()
	RfCapNoteArea()
	if (!NoteNeeded)
		RfCapPlan := "reel"
	else if (!NoteIndep)
		RfCapPlan := "stacked"
	else
		RfCapPlan := (NoteFullH > NoteH) ? "around" : "apart"
	; the note surface is made for every rod: some scanners look at pNoteBits whatever the rod
	RfSurface(RfCapNote, NoteW, NoteFullH)
	RfSurface(RfCapBand, CaptureW, CaptureH + 38 + CapExtra)
	pNoteBits := RfCapNote.p
	if (RfCapPlan = "stacked")
		pCaptureBits := pNoteBits + NoteH * NoteW * 4
	else
		pCaptureBits := RfCapBand.p + 18 * CaptureW * 4
	pUiEdgeBits := pCaptureBits - 18 * CaptureW * 4
	NoteBlitAt := 0
}

; Where the note area is for the current rod: NoteOriginX / NoteOriginY (client pixels, its
; top-left corner), NoteW x NoteH, NoteTop, NoteIndep (true when it is not right on top of the
; reel band) and NoteFullH (the rows copied: on the stacked plan the note area plus the reel band
; under it).
RfCapNoteArea() {
	global
	local fbTop, nf, sx, sy, sw, sh, k
	fbTop := Round(FishBarTop)
	NoteNeeded := false
	if SpecialRod in Pinions Aria,Noiseform,Tranquility,Lullaby,Halibut Harpoon,Stellarwave Melody
		NoteNeeded := true
	; usually a band right on top of the reel area, as wide as it and NoteRegionHeight tall: taller
	; on Tranquility and Noiseform, a thin strip on Halibut Harpoon
	NoteH := Round(RfClampNum(NoteRegionHeight, 0, 100000))
	if (SpecialRod = "Tranquility")
		NoteH := Max(NoteH, Round(WindowHeight * 0.55))
	else if (SpecialRod = "Noiseform")
		NoteH := Max(NoteH, Round(WindowHeight * 0.50))
	else if (SpecialRod = "Halibut Harpoon")
		NoteH := Round(WindowHeight * 0.075)
	NoteH := RfClampNum(NoteH, 20, 1400)
	NoteTop := fbTop - NoteH
	if (NoteTop < 0)
		NoteTop := 0, NoteH := Max(20, fbTop)
	if (SpecialRod = "Noiseform")
		{
		; Noiseform's band starts 2 px above 38.44 % of the height, unless that is too close to
		; the reel area
		nf := Round(WindowHeight * 0.5194) - Round(WindowHeight * 0.135) - 2
		if (nf > NoteTop and nf < fbTop - 80)
			NoteTop := nf, NoteH := fbTop - nf
		}
	NoteW := CaptureW, NoteOriginX := Round(FishBarLeft), NoteOriginY := NoteTop
	NoteIndep := false
	if (SpecialRod = "Pinions Aria")
		{
		; the shake area, cut off where the reel area starts
		sx := Round(ClickShakeLeft), sy := Round(ClickShakeTop)
		sw := Round(ClickShakeRight - ClickShakeLeft)
		sh := Min(Round(ClickShakeBottom - ClickShakeTop), fbTop - sy)
		if (sw >= 20 and sh >= 40)
			NoteIndep := true, NoteOriginX := sx, NoteOriginY := sy, NoteW := sw, NoteH := sh
		}
	else if (SpecialRod = "Stellarwave Melody")
		{
		; the star and piano rows above the reel (wider and taller with the Kitty Keys skin)
		k := KittyMode()
		NoteIndep := true
		NoteOriginX := Round(WindowWidth * (k ? 0.14 : 0.20)), NoteOriginY := Round(WindowHeight * 0.69)
		NoteW := Round(WindowWidth * (k ? 0.72 : 0.60))
		NoteH := Max(20, Round(WindowHeight * (k ? 0.22 : 0.10)))
		}
	NoteFullH := NoteIndep ? NoteH : NoteH + CaptureH + 20 + CapExtra
	; Stellarwave: when its area spans the reel band sideways and starts above it, copy on down to
	; the band's last row so the band can be taken out of that one copy
	if (SpecialRod = "Stellarwave Melody" and fbTop - 18 >= NoteOriginY and Round(FishBarLeft) >= NoteOriginX
		and Round(FishBarLeft) - NoteOriginX + CaptureW <= NoteW)
		NoteFullH := Max(NoteH, fbTop - 18 + CaptureH + 38 + CapExtra - NoteOriginY)
}

; One frame for the reel code: the copies, then every scanner's "already read this frame" flag
; cleared.
RfCapFrame() {
	global
	RfCapGrab()
	LineScanned := NoiseScanned := CastScanned := RemScanned := RemBarScanned := false
	MiguScanned := MiguBarScanned := HaliBarScanned := TryScanned := SwScanned := false
}

; The copies alone, as the plan says (RfHoldTrack calls this between its reads; the scanners'
; flags stay as they are there).
RfCapGrab() {
	global RobloxHwnd, RfCapPlan, RfCapBand, RfCapNote, FishBarLeft, FishBarTop, CaptureW, CaptureH
	global CapExtra, NoteOriginX, NoteOriginY, NoteTop, NoteW, NoteFullH, NoteFresh, NoteBlitAt
	global NoteRefreshMs, NoteLockX, QpcFreq, RfCapAt
	RfClientArea(RobloxHwnd, cx, cy)
	bx := cx + Round(FishBarLeft), by := cy + Round(FishBarTop) - 18, bh := CaptureH + 38 + CapExtra
	if (RfCapPlan = "reel")
		{
		DllCall("QueryPerformanceCounter", "Int64*", RfCapAt)
		return RfBlit(RfCapBand, bx, by, CaptureW, bh)
		}
	if (RfCapPlan = "stacked")
		{
		DllCall("QueryPerformanceCounter", "Int64*", RfCapAt)
		return RfBlit(RfCapNote, bx, cy + NoteTop, NoteW, NoteFullH)
		}
	DllCall("QueryPerformanceCounter", "Int64*", now)
	if (RfCapPlan = "around")
		{
		NoteFresh := true, NoteBlitAt := now, RfCapAt := now
		RfBlit(RfCapNote, cx + NoteOriginX, cy + NoteOriginY, NoteW, NoteFullH)
		DllCall("BitBlt", "Ptr", RfCapBand.dc, "Int", 0, "Int", 0, "Int", CaptureW, "Int", bh
			, "Ptr", RfCapNote.dc, "Int", Round(FishBarLeft) - NoteOriginX
			, "Int", Round(FishBarTop) - 18 - NoteOriginY, "UInt", 0x00CC0020)
		return
		}
	; apart
	NoteRefreshMs := (NoteLockX >= 0) ? 80 : 45
	NoteFresh := (!NoteBlitAt or (now - NoteBlitAt) * 1000.0 / QpcFreq >= NoteRefreshMs)
	if (NoteFresh)
		NoteBlitAt := now, RfBlit(RfCapNote, cx + NoteOriginX, cy + NoteOriginY, NoteW, NoteFullH)
	DllCall("QueryPerformanceCounter", "Int64*", RfCapAt)
	RfBlit(RfCapBand, bx, by, CaptureW, bh)
}

; ---- surfaces --------------------------------------------------------------------------------------
; A surface is a 32-bit top-down bitmap in memory with its own DC: {dc, bm, old, p (its first
; pixel), w, h}. RfSurface makes it, or makes it again when the size changed; false when Windows
; could not (s.p is then 0).
RfSurface(ByRef s, w, h) {
	w := Max(1, Round(w)), h := Max(1, Round(h))
	if (IsObject(s) and s.p and s.w = w and s.h = h)
		return true
	RfSurfaceFree(s)
	VarSetCapacity(bi, 40, 0)
	NumPut(40, bi, 0, "UInt"), NumPut(w, bi, 4, "Int"), NumPut(-h, bi, 8, "Int")
	NumPut(1, bi, 12, "UShort"), NumPut(32, bi, 14, "UShort")
	dc := DllCall("CreateCompatibleDC", "Ptr", 0, "Ptr"), p := 0
	bm := DllCall("CreateDIBSection", "Ptr", dc, "Ptr", &bi, "UInt", 0, "Ptr*", p, "Ptr", 0, "UInt", 0, "Ptr")
	if (!bm)
		{
		DllCall("DeleteDC", "Ptr", dc)
		s := {p: 0, w: 0, h: 0}
		return false
		}
	s := {dc: dc, bm: bm, p: p, w: w, h: h}
	s.old := DllCall("SelectObject", "Ptr", dc, "Ptr", bm, "Ptr")
	return true
}

RfSurfaceFree(ByRef s) {
	if (IsObject(s) and s.dc)
		{
		DllCall("SelectObject", "Ptr", s.dc, "Ptr", s.old)
		DllCall("DeleteObject", "Ptr", s.bm)
		DllCall("DeleteDC", "Ptr", s.dc)
		}
	s := ""
}

; Copies w x h screen pixels from (sx, sy) into the top-left corner of surface s.
RfBlit(s, sx, sy, w, h) {
	static screen := 0
	if (!screen)
		screen := DllCall("GetDC", "Ptr", 0, "Ptr")
	if (s.dc)
		DllCall("BitBlt", "Ptr", s.dc, "Int", 0, "Int", 0, "Int", w, "Int", h
			, "Ptr", screen, "Int", sx, "Int", sy, "UInt", 0x00CC0020)
}

; The Roblox client area on screen: x, y of its top-left corner, w and h. When Windows cannot say,
; the window's outer rectangle and false.
RfClientArea(hwnd, ByRef x, ByRef y, ByRef w := "", ByRef h := "") {
	; WINDOWINFO: cbSize, rcWindow, then rcClient (screen coordinates) at byte 20
	VarSetCapacity(wi, 60, 0), NumPut(60, wi, 0, "UInt")
	if (!hwnd or !DllCall("GetWindowInfo", "Ptr", hwnd, "Ptr", &wi))
		{
		WinGetPos, x, y, w, h, ahk_id %hwnd%
		return false
		}
	x := NumGet(wi, 20, "Int"), y := NumGet(wi, 24, "Int")
	w := NumGet(wi, 28, "Int") - x, h := NumGet(wi, 32, "Int") - y
	return true
}

; Pinions Aria reads its progress row inside the band's extra rows, and its white / purple
; pixel finders are set up here. (Pinions code: rewritten with Pinions Aria in section 3.)
PinionCapPrep() {
	global
	PnProgRow := Round(WindowHeight * 0.9111) - Round(FishBarTop)
	if (!CapExtra or PnProgRow < 4 or PnProgRow + 4 >= CaptureH + 20 + CapExtra)
		PnProgRow := -1
	PcSetPrm(PnPrmW, "0xDEE4FA", 28, 2, 0)
	PcSetPrm(PnPrmWI, "0xDEE4FA", 28, 2, 1)
	PcSetPrm(PnPrmP, "0x998FE4", 30, 0, 0)
	PcSetPrm(PnPrmPI, "0x998FE4", 30, 0, 1)
}

;====================================================================================================;

;====================================================================================================;
;   The live reel display  (new in Alpha 0.9, written for Re:Fisch)
;
;   A click-through strip under the reel while a fight runs: the track, the sides the bar cannot
;   reach (amber), the bar at its true width (blue), notes (pink) and the fish (green). The reel
;   loop sets where things should be (RfHudFish, RfHudBarSpan, RfHudBarC, RfHudBar2Span,
;   RfHudNote); a timer (RfHudTick, every 16 ms, 33 or 50 ms when drawing is slow) eases the
;   markers there over about 30 ms and redraws only when something visible changed.
;   Drawn with GDI+ on a layered window, with the status overlay's helpers (RfGdipStart,
;   RfGdipRoundPath) on an RfSurface bitmap.
;   RfHud holds it all: built / ok (window and surface made), w / h, gui, surf, the markers fish,
;   fish2, bar, bar2 ({tgt, cur}, bar2 also w), note / note2 (x or -1), zones (show the sides),
;   dirty / key (redraw needed / what was drawn last), the timer's prevT, avg, tickMs, tickN, and
;   the ring of bar widths (widths, wMed) the display uses for the bar's size.
;====================================================================================================;

; Fresh display state (at start-up and from RfHudBuild).
RfHudReset() {
	global RfHud
	if (!IsObject(RfHud))
		RfHud := {built: false, ok: false, h: 34, surf: ""}
	h := RfHud
	h.fish := {tgt: -1, cur: -1}, h.fish2 := {tgt: -1, cur: -1}
	h.bar := {tgt: -1, cur: -1}, h.bar2 := {tgt: -1, cur: -1, w: 0}
	h.note := -1, h.note2 := -1, h.zones := false, h.widths := [], h.wMed := 0
	h.dirty := true, h.key := "", h.prevT := 0
}

; The window (hidden) and its drawing surface, as wide as the track (40 px at least).
RfHudBuild() {
	global RfHud, TrackLeft, TrackRight, BarWTrust, hRfHudGui
	h := RfHud
	RfHudSurfaceFree()
	if (h.built)
		Gui, RfHud:Destroy
	h.w := Max(40, Round(TrackRight - TrackLeft)), h.h := 34
	Gui, RfHud:New, +AlwaysOnTop -Caption +ToolWindow +E0x80020 +HwndhRfHudGui
	Gui, RfHud:Color, 010101
	Gui, RfHud:Margin, 0, 0
	Gui, RfHud:Show, NoActivate Hide, Re:FischHud
	h.gui := hRfHudGui, h.built := true
	h.ok := RfHudSurface(h.w, h.h)
	RfHudReset()
	BarWTrust := 0
}

; A w x h surface with a GDI+ graphics on it (anti-aliased, half-pixel offset). False on failure.
RfHudSurface(w, h) {
	global RfHud
	RfHudSurfaceFree()
	if (!RfGdipStart() or !RfSurface(s, w, h))
		return false
	RfHud.surf := s, bmp := 0, g := 0
	if (DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", w, "Int", h, "Int", w * 4, "Int", 0xE200B, "Ptr", s.p, "Ptr*", bmp) != 0)
		return false
	s.bmp := bmp
	if (DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", bmp, "Ptr*", g) != 0)
		return false
	s.gfx := g
	DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", g, "Int", 4)
	DllCall("gdiplus\GdipSetPixelOffsetMode", "Ptr", g, "Int", 2)
	return true
}

RfHudSurfaceFree() {
	global RfHud
	s := RfHud.surf
	if (!IsObject(s))
		return
	if (s.gfx)
		DllCall("gdiplus\GdipDeleteGraphics", "Ptr", s.gfx)
	if (s.bmp)
		DllCall("gdiplus\GdipDisposeImage", "Ptr", s.bmp)
	RfSurfaceFree(s)
	RfHud.surf := ""
}

; Shows the display under the reel (made first if needed, again if the track's width changed)
; and starts its timer.
RfHudShow() {
	global RfHud, TrackLeft, TrackRight, RobloxHwnd, FishBarTooltipHeight
	h := RfHud
	if (!h.built)
		RfHudBuild()
	w := Max(40, Round(TrackRight - TrackLeft))
	if (w != (IsObject(h.surf) ? h.surf.w : 0) or !h.ok)
		h.w := w, h.ok := RfHudSurface(w, h.h)
	RfClientArea(RobloxHwnd, cx, cy)
	x := cx + Round(TrackLeft), y := cy + Round(FishBarTooltipHeight) - 11
	Gui, RfHud:Show, % "x" . x . " y" . y . " w" . h.w . " h" . h.h . " NoActivate"
	h.dirty := true, h.key := "", h.prevT := 0, h.avg := 0, h.tickMs := 33, h.tickN := 0
	SetTimer, RfHudTick, 33
}

RfHudHide() {
	global RfHud
	SetTimer, RfHudTick, Off
	if (RfHud.built)
		Gui, RfHud:Cancel
}

; Something the drawing depends on changed (the bar's width, the sides): redraw on the next tick.
RfHudUpdate() {
	global RfHud
	if (RfHud.built)
		RfHud.dirty := true
}

; The timer: eases each marker toward where it should be (1 - e^(-dt / 30 ms) of the way, dt at
; most 0.1 s), redraws when what is shown changed, and every 30 draws picks the timer's pace from
; the average drawing time (over 4 ms: 50 ms, else 33 ms). Steering still runs every frame.
RfHudTick() {
	global RfHud, QpcFreq, RunWidth, MaxLeftBar, MaxRightBar
	h := RfHud
	if (!h.built or !h.ok)
		return
	DllCall("QueryPerformanceCounter", "Int64*", now)
	dt := h.prevT ? (now - h.prevT) / QpcFreq : 0.008
	h.prevT := now
	ease := 1 - Exp(-Min(dt, 0.1) / 0.030)
	for i, m in [h.fish, h.bar, h.fish2, h.bar2]
		if (m.tgt >= 0)
			m.cur := (m.cur < 0) ? m.tgt : m.cur + ((m.tgt - m.cur) * ease)
	key := Round(h.fish.cur) . "|" . Round(h.bar.cur) . "|" . Round(h.note) . "|" . Round(h.note2) . "|" . Round(RunWidth)
		. "|" . (h.zones ? Round(MaxLeftBar) . "," . Round(MaxRightBar) : "-") . "|" . Round(h.fish2.cur) . "|" . Round(h.bar2.cur)
		. "|" . Round(h.bar2.w)
	if (!h.dirty and key = h.key)
		return
	h.key := key, h.dirty := false
	DllCall("QueryPerformanceCounter", "Int64*", t0)
	RfHudDraw()
	DllCall("QueryPerformanceCounter", "Int64*", t1)
	ms := (t1 - t0) * 1000.0 / QpcFreq
	h.avg := (h.avg > 0) ? (h.avg * 0.9) + (ms * 0.1) : ms
	h.tickN += 1
	if (Mod(h.tickN, 30))
		return
	want := (h.avg > 4.0) ? 50 : 33
	if (want != h.tickMs)
		{
		h.tickMs := want
		SetTimer, RfHudTick, % want
		}
}

; ---- the markers -------------------------------------------------------------------------------------

; The fish (second: Bellona's second fish) at client x. A jump of over 150 px is not eased.
RfHudFish(x, second := false) {
	global RfHud
	m := second ? RfHud.fish2 : RfHud.fish
	if (!RfHud.built or x < 0)
		return
	m.tgt := x
	if (m.cur < 0 or Abs(x - m.cur) > 150)
		m.cur := x
}

; A note at client x (second: the next note), -1 to clear. Moves under 2 px are ignored.
RfHudNote(x, second := false) {
	global RfHud
	if (!RfHud.built)
		return
	v := (x < 0) ? -1 : x
	if (v >= 0 and (second ? RfHud.note2 : RfHud.note) >= 0 and Abs(v - (second ? RfHud.note2 : RfHud.note)) < 2)
		return
	if (second)
		RfHud.note2 := v
	else
		RfHud.note := v
	RfHud.dirty := true
}

; Bellona's second bar, left end l and width w (client pixels).
RfHudBar2Span(l, w) {
	global RfHud
	b := RfHud.bar2
	if (!RfHud.built or l < 0 or w <= 0)
		return
	b.w := w, b.tgt := l + (w / 2)
	if (b.cur < 0)
		b.cur := b.tgt
}

; The bar, left end l and width w: the width goes into the display's width ring; a width more than
; 60 % off that ring's median is a misread and moves nothing.
RfHudBarSpan(l, w) {
	global RfHud
	if (l < 0 or w <= 0)
		return
	RfHudWidthPush(w)
	if (RfHud.wMed > 0 and Abs(w - RfHud.wMed) > (RfHud.wMed * 0.6))
		return
	RfHudBarC(l + (w / 2))
}

; The bar's centre at client x: kept where a bar of its width fits on the track, and moved at most
; 15 % of the track per call (so one misread cannot fling it across).
RfHudBarC(x) {
	global RfHud, TrackLeft, TrackRight
	b := RfHud.bar
	if (!RfHud.built or x < 0)
		return
	bw := RfHudBarWidth()
	lo := TrackLeft + (bw / 2), hi := TrackRight - (bw / 2)
	if (hi < lo)
		hi := lo
	x := (x < lo) ? lo : (x > hi) ? hi : x
	step := (TrackRight - TrackLeft) * 0.15
	if (b.cur >= 0 and step > 8)
		x := (x > b.cur + step) ? b.cur + step : (x < b.cur - step) ? b.cur - step : x
	b.tgt := x
	if (b.cur < 0)
		b.cur := x
}

; The last 5 bar widths the display saw (positive ones); wMed is their middle value (the upper of
; two).
RfHudWidthPush(w) {
	global RfHud
	if (w <= 0)
		return
	r := RfHud.widths
	r.Push(w)
	if (r.Length() > 5)
		r.RemoveAt(1)
	k := r.Length() // 2 + 1
	for i, x in r
		{
		below := 0, upTo := 0
		for j, y in r
			below += (y < x), upTo += (y <= x)
		if (below < k and upTo >= k)
			{
			RfHud.wMed := x
			break
			}
		}
}

; The width to draw the bar at: the ring's median once it holds 3 widths, else the measured width,
; else the last trusted read, else this frame's (8 px at least).
RfHudBarWidth() {
	global RfHud, WhiteBarSize, BarWTrust, RunWidth
	if (RfHud.wMed > 8 and RfHud.widths.Length() >= 3)
		{
		v := RfHud.wMed          ; handed back from a variable, as the drawing always got it
		return v
		}
	if (WhiteBarSize > 8)
		return WhiteBarSize
	if (BarWTrust > 8)
		return BarWTrust
	return (RunWidth > 8) ? RunWidth : 8
}

; ---- drawing -----------------------------------------------------------------------------------------

; Draws the strip and puts it on screen. The track is 16 px high at y 9 of the 34 px strip.
RfHudDraw() {
	global RfHud, TrackLeft, MaxLeftBar, MaxRightBar
	h := RfHud, s := h.surf
	if (!h.built or !h.ok or !IsObject(s) or !s.gfx)
		return
	g := s.gfx, stripW := s.w, stripH := s.h            ; (not W / H: names ignore case, h is RfHud)
	DllCall("gdiplus\GdipSetCompositingMode", "Ptr", g, "Int", 1)          ; clear to see-through
	DllCall("gdiplus\GdipGraphicsClear", "Ptr", g, "UInt", 0x00000000)
	DllCall("gdiplus\GdipSetCompositingMode", "Ptr", g, "Int", 0)
	; the track, with a faint rim
	RfHudShape(g, 0, 9, stripW, 16, 8, 0xDC0A0D13)
	RfHudShape(g, 0.75, 9.75, stripW - 1.5, 14.5, 8, 0x8C3A465A, 1.5)
	if (h.zones)
		{
		; the sides the bar's centre cannot reach, each with a brighter edge line
		zl := Round(MaxLeftBar - TrackLeft), zr := Round(MaxRightBar - TrackLeft)
		if (zl > 2)
			RfHudShape(g, 0, 9, zl, 16, 8, 0x4DF59E0B), RfHudShape(g, zl - 1.25, 7, 2.5, 20, 1.25, 0xE6FBB63C)
		if (zr < stripW - 2)
			RfHudShape(g, zr, 9, stripW - zr, 16, 8, 0x4DF59E0B), RfHudShape(g, zr - 1.25, 7, 2.5, 20, 1.25, 0xE6FBB63C)
		}
	if (h.bar.cur >= 0)
		RfHudDrawBar(g, h.bar.cur, RfHudBarWidth(), stripW)
	if (h.bar2.cur >= 0 and h.bar2.w > 0)
		RfHudDrawBar(g, h.bar2.cur, h.bar2.w, stripW)
	if (h.note2 >= 0)
		x := RfClampTo(Round(h.note2 - TrackLeft), 0, stripW), RfHudShape(g, x - 1.5, 10, 3, 14, 1.5, 0xCC8C1856)
	if (h.note >= 0)
		x := RfClampTo(Round(h.note - TrackLeft), 0, stripW), RfHudShape(g, x - 2, 8, 4, 18, 2, 0xF2FF2D9B)
	for i, f in [h.fish, h.fish2]
		if (f.cur >= 0)
			RfHudDrawFish(g, RfClampTo(f.cur - TrackLeft, 0, stripW))
	; onto the layered window, per-pixel alpha
	DllCall("gdiplus\GdipFlush", "Ptr", g, "Int", 0)
	VarSetCapacity(sz, 8), NumPut(stripW, sz, 0, "Int"), NumPut(stripH, sz, 4, "Int")
	VarSetCapacity(src, 8, 0)
	DllCall("UpdateLayeredWindow", "Ptr", h.gui, "Ptr", 0, "Ptr", 0, "Ptr", &sz, "Ptr", s.dc, "Ptr", &src
		, "UInt", 0, "UInt*", 0x01FF0000, "UInt", 2)
}

; The bar centred at client x, w wide (kept on the strip): a soft blue body 22 px high, its outline
; and a faint centre line.
RfHudDrawBar(g, x, w, stripW) {
	global TrackLeft
	if (w > stripW)
		w := stripW
	bx := Round(x - TrackLeft - (w / 2))
	if (bx < 0)
		bx := 0
	if (bx + w > stripW)
		bx := stripW - w
	RfHudShape(g, bx, 6, w, 22, 11, 0x4C5EA6FF)
	RfHudShape(g, bx + 1, 7, w - 2, 20, 10, 0xE64EA1F7, 1.6)
	RfHudShape(g, bx + (w / 2) - 0.5, 10, 1, 14, 0.5, 0x805EA6FF)
}

; The fish at strip x: two soft green halos, a tall line, a bright dot with a small highlight.
RfHudDrawFish(g, x) {
	RfHudDisc(g, x, 17, 11, 0x2622C55E)
	RfHudDisc(g, x, 17, 6.5, 0x4D22C55E)
	RfHudShape(g, x - 1.5, 4, 3, 26, 1.5, 0xE622C55E)
	RfHudDisc(g, x, 17, 3.6, 0xFF34D96F)
	RfHudDisc(g, x - 1, 17 - 1.2, 1.2, 0xB3FFFFFF)
}

; A rounded rectangle, filled in argb, or outlined thick px wide when thick is given. Corners 1 px
; across at least, as the display always drew them.
RfHudShape(g, x, y, w, ht, r, argb, thick := 0) {
	if (w <= 0 or ht <= 0)
		return
	path := RfGdipRoundPath(x, y, w, ht, r, 1), br := 0
	if (thick)
		{
		DllCall("gdiplus\GdipCreatePen1", "UInt", argb, "Float", thick, "Int", 2, "Ptr*", br)
		DllCall("gdiplus\GdipDrawPath", "Ptr", g, "Ptr", br, "Ptr", path)
		DllCall("gdiplus\GdipDeletePen", "Ptr", br)
		}
	else
		{
		DllCall("gdiplus\GdipCreateSolidFill", "UInt", argb, "Ptr*", br)
		DllCall("gdiplus\GdipFillPath", "Ptr", g, "Ptr", br, "Ptr", path)
		DllCall("gdiplus\GdipDeleteBrush", "Ptr", br)
		}
	DllCall("gdiplus\GdipDeletePath", "Ptr", path)
}

; A filled circle of radius r at (x, y).
RfHudDisc(g, x, y, r, argb) {
	br := 0
	DllCall("gdiplus\GdipCreateSolidFill", "UInt", argb, "Ptr*", br)
	DllCall("gdiplus\GdipFillEllipse", "Ptr", g, "Ptr", br, "Float", x - r, "Float", y - r, "Float", r * 2, "Float", r * 2)
	DllCall("gdiplus\GdipDeleteBrush", "Ptr", br)
}


NoteParseColors() {
	global NoteColor, NoteColorCached, NoteColR, NoteColG, NoteColB, NoteColN
	if (NoteColor = NoteColorCached)
		return NoteColN
	NoteColorCached := NoteColor
	NoteColR := []
	NoteColG := []
	NoteColB := []
	NoteColN := 0
	Loop, Parse, NoteColor, `,; , %A_Space%%A_Tab%
		{
		s := A_LoopField
		if (s = "")
			continue
		if (SubStr(s, 1, 2) = "0x")
			s := SubStr(s, 3)
		if (!RegExMatch(s, "^[0-9a-fA-F]{6}$"))
			continue
		v := "0x" . s
		NoteColN := NoteColN + 1
		NoteColR.Push((v >> 16) & 0xFF)
		NoteColG.Push((v >> 8) & 0xFF)
		NoteColB.Push(v & 0xFF)
		}
	return NoteColN
}

NoteScanFind(lockX) {
	global pNoteBits, NoteW, NoteH, NoteColorTolerance
	global NoteColR, NoteColG, NoteColB, NoteColN
	global NoteDbgPx, NoteDbgRun, NoteDbgBest
	NoteDbgPx := 0
	NoteDbgRun := 0
	NoteDbgBest := "-"
	if (!pNoteBits)
		return -1
	if (NoteParseColors() < 1)
		return -1
	tol := NoteColorTolerance
	if (tol < 6)
		tol := 6
	if (tol > 25)
		tol := 25
	yStep := (lockX >= 0) ? 8 : 16
	xFrom := 0
	xTo := NoteW
	if (lockX >= 0)
		{
		xFrom := Round(lockX) - 80
		xTo := Round(lockX) + 80
		if (xFrom < 0)
			xFrom := 0
		if (xTo > NoteW)
			xTo := NoteW
		}
	y := NoteH - 13
	while (y >= 0)
		{
		off := y * NoteW * 4
		runs := []
		runStart := -1
		x := xFrom
		while (x < xTo)
			{
			v := NumGet(pNoteBits + 0, off + (x*4), "UInt")
			b := v & 0xFF
			g := (v >> 8) & 0xFF
			r := (v >> 16) & 0xFF
			ok := false
			ci := 1
			while (ci <= NoteColN)
				{
				if (Abs(r - NoteColR[ci]) <= tol and Abs(g - NoteColG[ci]) <= tol and Abs(b - NoteColB[ci]) <= tol)
					{
					ok := true
					break
					}
				ci++
				}
			if (ok)
				{
				NoteDbgPx := NoteDbgPx + 1
				if (runStart < 0)
					runStart := x
				}
			else if (runStart >= 0)
				{
				if (x - runStart > NoteDbgRun)
					{
					NoteDbgRun := x - runStart
					NoteDbgBest := "x" . runStart . "y" . y
					}
				if (x - runStart >= 8)
					runs.Push(runStart, x - 1)
				runStart := -1
				}
			x += 4
			}
		if (runStart >= 0 and xTo - runStart >= 8)
			runs.Push(runStart, xTo - 1)

		n := runs.Length() // 2
		if (n > 0)
			{
			gi := 1
			while (gi <= n)
				{
				gl := runs[(gi-1)*2 + 1]
				gr := runs[(gi-1)*2 + 2]
				gj := gi + 1
				while (gj <= n)
					{
					nl := runs[(gj-1)*2 + 1]
					if (nl - gr > 45)
						break
					gr := runs[(gj-1)*2 + 2]
					gj++
					}
				w := gr - gl + 1
				if (w >= 8 and w <= 120)
					{
					cx := gl + (w / 2)
					if (lockX < 0 or Abs(cx - lockX) <= 55)
						return cx
					}
				gi := gj
				}
			}
		y -= yStep
		}
	return -1
}

LullRing(rr) {
	global pNoteBits, NoteW, NoteFullH, NoteTop, FishBarTop, CaptureW, LullPivotUp
	out := []
	if (!pNoteBits or rr < 20)
		return out
	bx := Round(CaptureW / 2)
	by := Round((FishBarTop - LullPivotUp) - NoteTop)
	d := 180
	while (d <= 360)
		{
		th := d * 0.01745329252
		x := Round(bx + (rr * Cos(th)))
		y := Round(by + (rr * Sin(th)))
		if (x >= 0 and x < NoteW and y >= 0 and y < NoteFullH)
			{
			px := NumGet(pNoteBits + 0, ((y * NoteW) + x) * 4, "UInt")
			out[d] := ((px & 0xFF) + ((px >> 8) & 0xFF) + ((px >> 16) & 0xFF)) // 3
			}
		else
			out[d] := -1
		d := d + 2
		}
	return out
}

LullCalStep() {
	global CaptureW, LullCalN, LullCalLt, LullCalDk, LullCalLs, LullRadiusPct
	i := 0
	while (i < 14)
		{
		rr := Round(CaptureW * (7 + (i * 1.2)) / 100)
		v := LullRing(rr)
		d := 180
		while (d <= 360)
			{
			if (v[d] != "" and v[d] >= 0)
				{
				ky := (i * 1000) + d
				if (v[d] >= 140)
					{
					LullCalLt[ky] := ((LullCalLt[ky] = "") ? 0 : LullCalLt[ky]) + 1
					LullCalLs[ky] := ((LullCalLs[ky] = "") ? 0 : LullCalLs[ky]) + v[d]
					}
				else if (v[d] < 40)
					LullCalDk[ky] := ((LullCalDk[ky] = "") ? 0 : LullCalDk[ky]) + 1
				}
			d := d + 2
			}
		i := i + 1
		}
	LullCalN := LullCalN + 1
}

LullPickRadius() {
	global CaptureW, LullCalLt, LullCalDk, LullCalLs, LullR, LullBg, LullLightLum
	bestSc := -1
	bestI := -1
	i := 0
	while (i < 14)
		{
		nl := 0
		nd := 0
		nt := 0
		d := 180
		while (d <= 360)
			{
			ky := (i * 1000) + d
			lt := (LullCalLt[ky] = "") ? 0 : LullCalLt[ky]
			dk := (LullCalDk[ky] = "") ? 0 : LullCalDk[ky]
			if (lt > 0 or dk > 0)
				{
				nt := nt + 1
				if (lt > dk)
					nl := nl + 1
				else if (dk > lt)
					nd := nd + 1
				}
			d := d + 2
			}
		if (nt >= 30 and nd > bestSc)
			{
			bestSc := nd
			bestI := i
			}
		i := i + 1
		}
	if (bestI >= 0)
		{
		nl2 := 0
		d := 180
		while (d <= 360)
			{
			ky := (bestI * 1000) + d
			if (LullCalLt[ky] != "" and LullCalLt[ky] > 0)
				nl2 := nl2 + 1
			d := d + 2
			}
		if (nl2 < 2)
			bestI := -1
		}
	if (bestI < 0)
		{
		LullR := Round(CaptureW * LullRadiusPct / 100)
		return 0
		}
	LullR := Round(CaptureW * (7 + (bestI * 1.2)) / 100)
	LullBg := []
	d := 180
	while (d <= 360)
		{
		ky := (bestI * 1000) + d
		lt := (LullCalLt[ky] = "") ? 0 : LullCalLt[ky]
		dk := (LullCalDk[ky] = "") ? 0 : LullCalDk[ky]
		if (lt > dk and lt > 0)
			LullBg[d] := LullCalLs[ky] / lt
		else
			LullBg[d] := 0
		d := d + 2
		}
	return LullR
}

LullFindSectors() {
	global LullBg, LullSecN, LullSecA, LullSecB, LullLightLum, LullMinDeg
	ll := LullLightLum
	if (ll < 30)
		ll := 30
	if (ll > 220)
		ll := 220
	md := LullMinDeg
	if (md < 2)
		md := 2
	if (md > 60)
		md := 60
	LullSecN := 0
	LullSecA := []
	LullSecB := []
	runS := -1
	d := 180
	while (d <= 362)
		{
		lit := false
		if (d <= 360 and LullBg[d] != "")
			lit := (LullBg[d] >= ll)
		if (lit)
			{
			if (runS < 0)
				runS := d
			}
		else if (runS >= 0)
			{
			if (((d - 2) - runS) >= (md - 2))
				{
				LullSecN := LullSecN + 1
				LullSecA[LullSecN] := runS
				LullSecB[LullSecN] := d - 2
				}
			runS := -1
			}
		d := d + 2
		}
	return LullSecN
}

LullScan() {
	global LullFrames, LullCalN, LullR, LullBg, LullSecN, LullSecA, LullSecB
	global LullArmA, LullClrT, LullActive, LullHitSec
	global LullArmDelta, LullTrigPct, LullClearMs, LullRadiusPct, CaptureW
	LullHitSec := 0
	probe := (LullR > 0) ? LullR : Round(CaptureW * LullRadiusPct / 100)
	v := LullRing(probe)
	vmn := 999
	vmx := -1
	d := 180
	while (d <= 360)
		{
		if (v[d] != "" and v[d] >= 0)
			{
			if (v[d] < vmn)
				vmn := v[d]
			if (v[d] > vmx)
				vmx := v[d]
			}
		d := d + 2
		}
	if (vmx < 0 or vmx < 120)
		{
		LullActive := false
		return false
		}
	LullActive := true
	LullFrames := LullFrames + 1
	if (LullR <= 0)
		{
		LullCalStep()
		if (LullCalN >= 26)
			{
			LullPickRadius()
			LullFindSectors()
			}
		return false
		}
	dv := LullArmDelta
	if (dv < 15)
		dv := 15
	if (dv > 200)
		dv := 200
	tp := LullTrigPct
	if (tp < 3)
		tp := 3
	if (tp > 90)
		tp := 90
	cm := LullClearMs
	if (cm < 20)
		cm := 20
	if (cm > 2000)
		cm := 2000
	now := A_TickCount
	hit := false
	i := 1
	while (i <= LullSecN)
		{
		ka := LullSecA[i]
		dk := 0
		n := 0
		d := ka
		while (d <= LullSecB[i])
			{
			if (v[d] != "" and v[d] >= 0 and LullBg[d] != "")
				{
				n := n + 1
				if (Abs(v[d] - LullBg[d]) >= dv)
					dk := dk + 1
				}
			d := d + 2
			}
		if (n > 0 and (dk * 100) >= (n * tp))
			{
			LullClrT[ka] := 0
			if (LullArmA[ka] = "" or LullArmA[ka])
				{
				LullArmA[ka] := false
				LullHitSec := i
				hit := true
				}
			}
		else
			{
			if (LullClrT[ka] = "" or LullClrT[ka] = 0)
				LullClrT[ka] := now
			if ((now - LullClrT[ka]) >= cm)
				LullArmA[ka] := true
			}
		i := i + 1
		}
	return hit
}

; Alpha 1.8, Pinions Aria: a note-coloured shape in the band just above the reel (the bottom 10%
; of the window height of the note area) is not taken as a note when it sits over the fish or
; inside the bar. Seen on video (2026-11-09): in the mode where the fish follows the bar, a small
; double-note icon in exactly the note colour floats about 70 px (at 1080p) above the fish, and
; the bright bar's glow matches the note colour too. The scan works up from the reel and keeps
; two shapes, so the icon became "the note" and the bar stayed on the fish while real notes fell
; elsewhere. A real note in that band lands within about 0.15 s, when the bar has already gone
; for it. The icon (narrow, over the fish) also marks that mode: PnIconAt is when it was seen.
RfNoteNearBar(cx, y, w) {
	global SpecialRod, NoteH, NoteOriginX, WindowHeight, WindowWidth, LastFishX, RunLeft, RunWidth, PnIconAt
	if (SpecialRod != "Pinions Aria" or WindowHeight <= 0 or y < NoteH - WindowHeight * 0.10)
		return false
	ax := NoteOriginX + cx
	if (LastFishX >= 0 and Abs(ax - LastFishX) <= WindowWidth * 0.03)
		{
		if (w <= WindowWidth * 0.05)
			DllCall("QueryPerformanceCounter", "Int64*", PnIconAt)
		return true
		}
	return (RunWidth > 0 and ax >= RunLeft and ax <= RunLeft + RunWidth)
}

NoteScanAll() {
	global pNoteBits, NoteW, NoteH, NoteColorTolerance
	global NoteColR, NoteColG, NoteColB, NoteColN
	global NoteAllX, NoteAllY, NoteAllN
	NoteAllX := []
	NoteAllY := []
	NoteAllN := 0
	sumX := []
	cntX := []
	if (!pNoteBits)
		return 0
	if (NoteParseColors() < 1)
		return 0
	tol := NoteColorTolerance
	if (tol < 6)
		tol := 6
	if (tol > 25)
		tol := 25
	c1r := NoteColR[1]
	c1g := NoteColG[1]
	c1b := NoteColB[1]
	r1lo := c1r - tol
	r1hi := c1r + tol
	g1lo := c1g - tol
	g1hi := c1g + tol
	b1lo := c1b - tol
	b1hi := c1b + tol
	multi := (NoteColN > 1)
	y := NoteH - 13
	while (y >= 0)
		{
		off := y * NoteW * 4
		runs := []
		runStart := -1
		x := 0
		while (x < NoteW)
			{
			v := NumGet(pNoteBits + 0, off + (x*4), "UInt")
			b := v & 0xFF
			ok := false
			if (b >= b1lo and b <= b1hi)
				{
				g := (v >> 8) & 0xFF
				if (g >= g1lo and g <= g1hi)
					{
					r := (v >> 16) & 0xFF
					ok := (r >= r1lo and r <= r1hi)
					}
				}
			if (!ok and multi)
				{
				g := (v >> 8) & 0xFF
				r := (v >> 16) & 0xFF
				ci := 2
				while (ci <= NoteColN)
					{
					if (Abs(r - NoteColR[ci]) <= tol and Abs(g - NoteColG[ci]) <= tol and Abs(b - NoteColB[ci]) <= tol)
						{
						ok := true
						break
						}
					ci++
					}
				}
			if (ok)
				{
				if (runStart < 0)
					runStart := x
				}
			else if (runStart >= 0)
				{
				if (x - runStart >= 8)
					runs.Push(runStart, x - 1)
				runStart := -1
				}
			x += 4
			}
		if (runStart >= 0 and NoteW - runStart >= 8)
			runs.Push(runStart, NoteW - 1)
		n := runs.Length() // 2
		if (n > 0)
			{
			gi := 1
			while (gi <= n)
				{
				gl := runs[(gi-1)*2 + 1]
				gr := runs[(gi-1)*2 + 2]
				gj := gi + 1
				while (gj <= n)
					{
					nl := runs[(gj-1)*2 + 1]
					if (nl - gr > 45)
						break
					gr := runs[(gj-1)*2 + 2]
					gj++
					}
				w := gr - gl + 1
				if (w >= 8 and w <= 120 and !RfNoteNearBar(gl + (w / 2), y, w))
					{
					cx := gl + (w / 2)
					dup := false
					di := 1
					while (di <= NoteAllN)
						{
						if (Abs(cx - NoteAllX[di]) <= 55 and (NoteAllY[di] - y) <= 120)
							{
							sumX[di] := sumX[di] + cx
							cntX[di] := cntX[di] + 1
							NoteAllX[di] := sumX[di] / cntX[di]
							dup := true
							break
							}
						di++
						}
					if (!dup and NoteAllN < 2)
						{
						NoteAllN++
						NoteAllX[NoteAllN] := cx
						NoteAllY[NoteAllN] := y
						sumX[NoteAllN] := cx
						cntX[NoteAllN] := 1
						}
					}
				gi := gj
				}
			}
		if (NoteAllN >= 2)
			break
		y -= 16
		}
	return NoteAllN
}

NoteScan(refX) {
	global FishBarLeft, FishBarRight, NoteOriginX, NoteLockX, NoteLockN, LastNoteX, NoteDbgCalls, NoteMissN
	global NoteFresh, NoteIndep, NoteMissAt, QpcFreq
	global NoteAllX, NoteAllY, NoteAllN, NoteH, NoteHandoff
	global NoteNextX, NoteLockY, NoteNextY
	NoteDbgCalls := NoteDbgCalls + 1
	if (NoteIndep and !NoteFresh and NoteLockX >= 0)
		{
		LastNoteX := NoteLockX
		return NoteLockX
		}
	LastNoteX := -1
	NoteNextX := -1
	NoteNextY := -1
	if (NoteScanAll() < 1)
		{
		DllCall("QueryPerformanceCounter", "Int64*", NoteMissNow)
		if (!NoteMissAt)
			NoteMissAt := NoteMissNow
		if (NoteLockX >= 0 and ((NoteMissNow - NoteMissAt) * 1000.0 / QpcFreq) <= 260)
			{
			LastNoteX := NoteLockX
			return NoteLockX
			}
		NoteLockX := -1
		NoteLockN := 0
		NoteLockY := -1
		NoteMissAt := 0
		return -1
		}
	NoteMissAt := 0
	sel := 1
	matched := false
	if (NoteLockX >= 0)
		{
		i := 1
		while (i <= NoteAllN)
			{
			if (Abs((NoteOriginX + NoteAllX[i]) - NoteLockX) <= 55
				and (NoteLockY < 0 or NoteAllY[i] <= NoteLockY + 100))
				{
				sel := i
				matched := true
				break
				}
			i++
			}
		}
	hoff := NoteHandoff
	if (hoff < 0)
		hoff := 0
	if (hoff > 200)
		hoff := 200
	if (NoteAllN > sel and hoff > 0 and NoteAllY[sel] > (NoteH - 13 - hoff))
		{
		sel := sel + 1
		matched := false
		}
	newX := NoteOriginX + NoteAllX[sel]
	if (newX < FishBarLeft)
		newX := FishBarLeft
	if (newX > FishBarRight)
		newX := FishBarRight
	if (!matched)
		{
		NoteLockX := newX
		NoteLockN := 1
		}
	else
		{
		NoteLockN := NoteLockN + 1
		nAvg := (NoteLockN < 8) ? NoteLockN : 8
		NoteLockX := NoteLockX + ((newX - NoteLockX) / nAvg)
		}
	NoteLockY := NoteAllY[sel]
	LastNoteX := NoteLockX
	if (NoteAllN > sel)
		{
		NoteNextX := NoteOriginX + NoteAllX[sel + 1]
		if (NoteNextX < FishBarLeft)
			NoteNextX := FishBarLeft
		if (NoteNextX > FishBarRight)
			NoteNextX := FishBarRight
		NoteNextY := NoteAllY[sel + 1]
		}
	return NoteLockX
}

; Is Fisch's bright mint green (green 240 or more, red and blue 140 to 170) in the bottom-left
; corner of the client area (left 4.5 %, bottom 10 %)? Three pixels of it on a 3 px grid say yes.
; (New in Alpha 0.6: reads the corner through RfGrab.)
RfGreenCorner() {
	global RobloxHwnd, WindowLeft, WindowTop
	RfClientArea(RobloxHwnd, cx, cy, cw, ch)      ; where the window is now (RfGrab counts from WindowLeft / WindowTop)
	w := Max(8, Round(cw * 0.045)), h := Max(8, Round(ch * 0.10))
	s := RfGrab("greencorner", cx - WindowLeft, cy - WindowTop + Round(ch * 0.90), w, h)
	if (!IsObject(s))
		return false
	hits := 0
	Loop, % Ceil(h / 3)
		{
		y := (A_Index - 1) * 3
		Loop, % Ceil(w / 3)
			{
			px := RfPx(s, (A_Index - 1) * 3, y)
			if ((px >> 8 & 0xFF) >= 240 and Abs((px >> 16 & 0xFF) - 155) <= 15 and Abs((px & 0xFF) - 155) <= 15)
				if (++hits >= 3)
					return true
			}
		}
	return false
}

;====================================================================================================;
;   Timing, maths and colour helpers  (new in Alpha 0.6, written for Re:Fisch)
;====================================================================================================;

; Waits ms milliseconds on the performance counter: short sleeps while far off, a spin for the
; last 16 ms (RfSpinUntil). Used where a click or hover must last an exact time.
RfSpinFor(ms) {
	global QpcFreq
	if (ms <= 0)
		return
	DllCall("QueryPerformanceCounter", "Int64*", now)
	RfSpinUntil(now + ms * QpcFreq / 1000.0)
}

; Keeps the reel key the caller just pressed down for up to ms while the reel goes on being read
; (fish position and the live display), and stops early once the bar has reached the fish on the
; side it moves to (dir "Left" or "Right"; useArrow: the arrow stands in for the bar).
; HeldFraction = the share of ms that was held (1 when the full time ran).
; Holds of 15 ms or less, and the last 20 ms of a longer one, are a plain Sleep: the reel tuning
; was made with that timing.
RfHoldTrack(ms, dir := "", useArrow := false) {
	global MacroRunning, FishX, QpcFreq, RunLeft, RunWidth, HeldFraction
	HeldFraction := 1.0
	if (ms <= 15)
		{
		Sleep, % Max(0, Round(ms))
		return
		}
	DllCall("QueryPerformanceCounter", "Int64*", t0)
	while (MacroRunning)
		{
		DllCall("QueryPerformanceCounter", "Int64*", t)
		held := (t - t0) * 1000.0 / QpcFreq
		if (held >= ms - 20)
			{
			if (held < ms)
				Sleep, % Round(ms - held)
			return
			}
		RfCapGrab()
		if (RfHandsOff(true))
			return
		x := RfFishFind()
		if (x >= 0)
			FishX := x, RfHudFish(x)
		if (dir = "")
			continue
		if (useArrow)
			{
			x := RfArrowFind()
			if (x >= 0)
				RfHudBarC(x)
			}
		else
			{
			x := (RfBarFind() and RunWidth > 0) ? RunLeft + RunWidth / 2 : -1   ; BarPresent sets RunLeft / RunWidth
			if (x >= 0)
				RfHudBarSpan(RunLeft, RunWidth)
			}
		if (x >= 0 and ((dir = "Left") ? (x <= FishX) : (x >= FishX)))
			{
			HeldFraction := held / ms
			return
			}
		}
}

; The median of an array of numbers; 0 for an empty one. Middle values are found by rank
; (RfRankAt) rather than by sorting; the arrays here hold 25 values at most.
RfMedian(arr) {
	v := []
	for i, x in arr
		v.Push(x)
	n := v.Length()
	if (!n)
		return 0
	lo := RfRankAt(v, (n + 1) // 2)
	return (n & 1) ? lo : (lo + RfRankAt(v, n // 2 + 1)) / 2.0
}

; The k-th smallest value of v (k counted from 1): the one with fewer than k values below it and
; at least k at or below it.
RfRankAt(v, k) {
	for i, x in v
		{
		below := 0, upTo := 0
		for j, y in v
			below += (y < x), upTo += (y <= x)
		if (below < k and upTo >= k)
			return x
		}
	return ""
}

; Red and blue swapped: 0xRRGGBB (a number or "0x..." text) to the 0xBBGGRR order Windows' GDI
; uses, and back. Blank for anything that is not one number (a colour list, say).
RfBgr(c) {
	if c is not integer
		return ""
	c += 0
	return (c & 0x00FF00) | (c >> 16 & 0xFF) | (c << 16 & 0xFF0000)
}

; The same for a theme colour written as six hex digits without 0x ("EDEDED").
RfBgrHex(hex) {
	return RfBgr("0x" . hex)
}

;====================================================================================================;

ColSpread(x0, x1, fishX) {
	global pCaptureBits, CaptureW, CaptureH
	if (x0 < 0)
		x0 := 0
	if (x1 > CaptureW)
		x1 := CaptureW
	loR := 999999, hiR := -1, loG := 999999, hiG := -1, loB := 999999, hiB := -1
	n := 0
	x := x0
	while (x < x1)
		{
		if (Abs(x - fishX) > 14)
			{
			sR := 0, sG := 0, sB := 0
			y := (CaptureH < 22) ? (CaptureH // 3) : 8
			while (y < ((CaptureH < 22) ? CaptureH : 22))
				{
				px := NumGet(pCaptureBits + 0, (y*CaptureW + x)*4, "UInt")
				sB += px & 0xFF
				sG += (px >> 8) & 0xFF
				sR += (px >> 16) & 0xFF
				y += 2
				}
			if (sR < loR)
				loR := sR
			if (sR > hiR)
				hiR := sR
			if (sG < loG)
				loG := sG
			if (sG > hiG)
				hiG := sG
			if (sB < loB)
				loB := sB
			if (sB > hiB)
				hiB := sB
			n++
			}
		x += 2
		}
	if (n < 10)
		return -1
	return ((hiR - loR) + (hiG - loG) + (hiB - loB)) / 7
}

TqResetAll() {
	global TqHitY, TqRingTop, TqRef
	TqHitY := -1
	TqRingTop := -1
	TqRef := [[89.0, 217.0, 221.0], [119.0, 92.0, 221.0], [227.0, 222.0, 153.0], [211.0, 105.0, 169.0]]
	TqResetFight(0)
}

TqResetFight(t0) {
	global TqV, TqVs, TqNoteD, TqDs, TqNotes, TqLastRing, TqLastLive, TqStarted, TqT0, TqExpired, TqPrevT, TqDl, WindowHeight
	TqV := 0.645 * WindowHeight
	TqVs := []
	TqNoteD := 0.098 * WindowHeight
	TqDs := []
	TqNotes := [[], [], [], []]
	TqLastRing := -1
	TqLastLive := -1
	TqStarted := false
	TqT0 := t0
	TqExpired := false
	TqPrevT := -1
	TqDl := 0
}

TqRing(cx, ByRef cc, ByRef rtop, ByRef pr, ByRef pg, ByRef pb) {
	global pNoteBits, NoteW, NoteH, WindowHeight
	hh := WindowHeight
	expect := NoteH - (hh * 0.0767)
	win := (hh * 0.0625) + (hh * 0.08)
	ya := Round(expect - win)
	yb := Round(expect + win)
	if (ya < 0)
		ya := 0
	if (yb > NoteH - 1)
		yb := NoteH - 1
	smin := hh * 0.004
	smax := (hh * 0.02 > 24) ? hh * 0.02 : 24
	gmin := hh * 0.045
	gmax := (hh * 0.12 > 150) ? hh * 0.12 : 150
	base := pNoteBits + (cx * 4)
	rowb := NoteW * 4
	rs := []
	re := []
	st := -1
	y := ya
	while (y <= yb)
		{
		v := NumGet(base + 0, y * rowb, "UInt")
		cb := v & 0xFF
		cg := (v >> 8) & 0xFF
		cr := (v >> 16) & 0xFF
		mx := (cr > cg) ? ((cr > cb) ? cr : cb) : ((cg > cb) ? cg : cb)
		mn := (cr < cg) ? ((cr < cb) ? cr : cb) : ((cg < cb) ? cg : cb)
		if (mx > 90 and (mx - mn) > 35)
			{
			if (st < 0)
				st := y
			}
		else if (st >= 0)
			{
			rs.Push(st)
			re.Push(y - 1)
			st := -1
			}
		y++
		}
	if (st >= 0)
		{
		rs.Push(st)
		re.Push(yb)
		}
	i := 1
	while (i < rs.Length())
		{
		s1 := rs[i]
		e1 := re[i]
		s2 := rs[i + 1]
		e2 := re[i + 1]
		h1 := e1 - s1 + 1
		h2 := e2 - s2 + 1
		gp := s2 - e1 - 1
		if (h1 >= smin and h1 <= smax and h2 >= smin and h2 <= smax and gp >= gmin and gp <= gmax)
			{
			nd := 0
			y := e1 + 1
			while (y < s2)
				{
				v := NumGet(base + 0, y * rowb, "UInt")
				cb := v & 0xFF
				cg := (v >> 8) & 0xFF
				cr := (v >> 16) & 0xFF
				mx := (cr > cg) ? ((cr > cb) ? cr : cb) : ((cg > cb) ? cg : cb)
				if (mx < 70)
					nd++
				y++
				}
			if (nd * 4 >= gp * 3)
				{
				c0 := (s1 + e2) / 2.0
				if (Abs(c0 - expect) <= hh * 0.0625)
					{
					v := NumGet(base + 0, ((s1 + e1) // 2) * rowb, "UInt")
					pb := v & 0xFF
					pg := (v >> 8) & 0xFF
					pr := (v >> 16) & 0xFF
					cc := c0
					rtop := s1
					return true
					}
				}
			}
		i++
		}
	return false
}

TqRings(ByRef agree) {
	global NoteW, TqHitY, TqRingTop, TqRef
	static fr := [0.1230, 0.3740, 0.6220, 0.8750]
	cs := []
	tops := []
	lns := []
	prs := []
	pgs := []
	pbs := []
	li := 1
	while (li <= 4)
		{
		if (TqRing(Round(NoteW * fr[li]), cc, rtop, pr, pg, pb))
			{
			cs.Push(cc)
			tops.Push(rtop)
			lns.Push(li)
			prs.Push(pr)
			pgs.Push(pg)
			pbs.Push(pb)
			}
		li++
		}
	agree := 0
	n := cs.Length()
	if (n >= 1)
		{
		md := RfMedian(cs)
		ac := []
		at := []
		for i, c0 in cs
			{
			if (Abs(c0 - md) <= 8)
				{
				ac.Push(c0)
				at.Push(tops[i])
				}
			}
		agree := ac.Length()
		if (agree >= 2)
			{
			c0 := RfMedian(ac)
			tp := RfMedian(at)
			TqHitY := (TqHitY < 0) ? c0 : ((TqHitY * 0.8) + (c0 * 0.2))
			TqRingTop := (TqRingTop < 0) ? tp : ((TqRingTop * 0.8) + (tp * 0.2))
			for i, c0 in cs
				{
				if (Abs(c0 - md) <= 8)
					{
					rf := TqRef[lns[i]]
					rf[1] := (rf[1] * 0.8) + (prs[i] * 0.2)
					rf[2] := (rf[2] * 0.8) + (pgs[i] * 0.2)
					rf[3] := (rf[3] * 0.8) + (pbs[i] * 0.2)
					}
				}
			}
		}
	return n
}

ManiaVisible() {
	global pNoteBits, NoteH
	if (!pNoteBits or NoteH < 120)
		return false
	TqRings(agree)
	return (agree >= 3)
}

ManiaStep(t) {
	global pNoteBits, NoteW, NoteH, WindowHeight, ManiaLead, BarCalculationFailsafe
	global TqHitY, TqRingTop, TqV, TqVs, TqNoteD, TqDs, TqNotes, TqRef, TqLastRing, TqLastLive, TqStarted, TqT0
	global TqExpired, TqPrevT, TqDl
	static fr := [0.1230, 0.3740, 0.6220, 0.8750]
	static keys := ["d", "f", "j", "k"]
	gapT := (TqPrevT >= 0) ? (t - TqPrevT) : 0.0
	TqPrevT := t
	if (gapT > 0 and gapT < 0.1)
		TqDl := (TqDl <= 0) ? gapT : ((TqDl * 0.9) + (gapT * 0.1))
	ts := t
	if (gapT > 0 and gapT < 0.1)
		ts := t - (((gapT < 1.0 / 60) ? gapT : (1.0 / 60)) / 2.0)
	if (!pNoteBits or NoteH < 120)
		{
		if (!TqStarted and (t - TqT0) > BarCalculationFailsafe)
			{
			TqExpired := true
			return false
			}
		return true
		}
	hh := WindowHeight
	nring := TqRings(agree)
	if (!TqStarted)
		{
		if (agree < 3)
			{
			if ((t - TqT0) > BarCalculationFailsafe)
				{
				TqExpired := true
				return false
				}
			return true
			}
		TqStarted := true
		TqLastRing := t
		TqLastLive := t
		if (TqDs.Length() = 0 and TqRingTop >= 0 and TqHitY >= 0)
			TqNoteD := 2.0 * (TqHitY - TqRingTop)
		}
	if (nring >= 1)
		{
		TqLastRing := t
		TqLastLive := t
		}
	hitY := (TqHitY >= 0) ? TqHitY : (NoteH - (hh * 0.0767))
	ringR := (TqRingTop >= 0) ? (hitY - TqRingTop) : (hh * 0.049)
	top := hitY - (1.6 * ringR) - 3
	rd := 2.0 * ringR
	minH := TqNoteD * 0.5
	maxOne := TqNoteD * 1.35
	lead := ManiaLead / 1000.0
	rowb := NoteW * 4
	moving := false
	li := 1
	while (li <= 4)
		{
		base := pNoteBits + (Round(NoteW * fr[li]) * 4)
		rf := TqRef[li]
		sr := rf[1] + rf[2] + rf[3]
		mb := []
		mh := []
		st := -1
		y := 0
		while (y <= NoteH)
			{
			colp := false
			if (y < NoteH)
				{
				v := NumGet(base + 0, y * rowb, "UInt")
				cb := v & 0xFF
				cg := (v >> 8) & 0xFF
				cr := (v >> 16) & 0xFF
				mx := (cr > cg) ? ((cr > cb) ? cr : cb) : ((cg > cb) ? cg : cb)
				mn := (cr < cg) ? ((cr < cb) ? cr : cb) : ((cg < cb) ? cg : cb)
				colp := (mx > 90 and (mx - mn) > 35)
				}
			if (colp)
				{
				if (st < 0)
					st := y
				}
			else if (st >= 0)
				{
				ye := y - 1
				rh := ye - st + 1
				if (ye < top and rh >= minH)
					{
					yc := Floor(ye - (TqNoteD / 2.0))
					if (yc < st)
						yc := st
					v := NumGet(base + 0, yc * rowb, "UInt")
					pb := v & 0xFF
					pg := (v >> 8) & 0xFF
					pr := (v >> 16) & 0xFF
					sp := pr + pg + pb
					if (sp > 0 and sr > 0)
						{
						kr := sp / sr
						dmax := Abs((pr / sp) - (rf[1] / sr))
						dg := Abs((pg / sp) - (rf[2] / sr))
						db := Abs((pb / sp) - (rf[3] / sr))
						if (dg > dmax)
							dmax := dg
						if (db > dmax)
							dmax := db
						if (kr >= 0.35 and kr <= 0.90 and dmax <= 0.06)
							{
							if (rh <= maxOne)
								{
								mb.Push(ye + 0.0)
								mh.Push(rh)
								}
							else
								{
								kk := Round(rh / TqNoteD)
								if (kk < 2)
									kk := 2
								j := 0
								while (j < kk)
									{
									mb.Push(ye - ((rh - TqNoteD) * j / (kk - 1)))
									mh.Push(0)
									j++
									}
								}
							}
						}
					}
				st := -1
				}
			y++
			}
		i := 2
		while (i <= mb.Length())
			{
			xb := mb[i]
			xh := mh[i]
			j := i - 1
			while (j >= 1 and mb[j] < xb)
				{
				mb[j + 1] := mb[j]
				mh[j + 1] := mh[j]
				j--
				}
			mb[j + 1] := xb
			mh[j + 1] := xh
			i++
			}
		lane := TqNotes[li]
		used := []
		Loop, % lane.Length()
			used.Push(false)
		for mi, bot in mb
			{
			rh := mh[mi]
			best := 0
			bd := 1000000000.0
			i := 1
			while (i <= lane.Length())
				{
				if (!used[i])
					{
					nt := lane[i]
					dtt := t - nt.tb
					d := Abs(bot - (nt.bot + (TqV * dtt)))
					win := hh * 0.012
					if (0.3 * TqV * dtt > win)
						win := 0.3 * TqV * dtt
					win += TqV / 30.0
					if (d <= win and d < bd)
						{
						best := i
						bd := d
						}
					}
				i++
				}
			if (!best)
				{
				anc := (rh > 0 and rh >= rd * 0.85 and rh <= rd * 1.15)
				lane.Push({bot: bot, tb: ts, ta: ts + ((hitY + (TqNoteD / 2.0) - bot) / TqV), n: 1, nm: 0, fired: false, b0: (anc ? bot : -1.0), t0: (anc ? ts : -1.0)})
				used.Push(true)
				continue
				}
			used[best] := true
			nt := lane[best]
			dt := ts - nt.tb
			disp := bot - nt.bot
			nt.n := nt.n + 1
			if (Abs(disp) < 1)
				continue
			single := (rh > 0 and rh >= rd * 0.85 and rh <= rd * 1.15)
			if (single and nt.t0 < 0)
				{
				nt.b0 := bot
				nt.t0 := ts
				}
			else if (single and ts - nt.t0 >= 0.25)
				{
				vs := (bot - nt.b0) / (ts - nt.t0)
				if (vs >= hh * 0.25 and vs <= hh * 1.6)
					{
					TqVs.Push(vs)
					if (TqVs.Length() > 25)
						TqVs.RemoveAt(1)
					if (TqVs.Length() >= 3)
						TqV := RfMedian(TqVs)
					}
				}
			if (rh > 0 and rh >= rd * 0.6 and rh <= rd * 1.4)
				{
				TqDs.Push(rh)
				if (TqDs.Length() > 25)
					TqDs.RemoveAt(1)
				if (TqDs.Length() >= 5)
					TqNoteD := RfMedian(TqDs)
				}
			if (dt > 0.004 and disp >= (0.7 * TqV * dt) - 3 and disp <= (1.3 * TqV * dt) + 3)
				{
				nt.nm := nt.nm + 1
				if (nt.nm >= 2)
					moving := true
				}
			nt.bot := bot
			nt.tb := ts
			if (!nt.fired)
				nt.ta := ts + ((hitY + (TqNoteD / 2.0) - bot) / TqV)
			}
		i := 2
		while (i <= lane.Length())
			{
			x := lane[i]
			j := i - 1
			while (j >= 1 and lane[j].ta > x.ta)
				{
				lane[j + 1] := lane[j]
				j--
				}
			lane[j + 1] := x
			i++
			}
		half := (TqDl < 0.05) ? (TqDl / 2.0) : 0.0
		for i, nt in lane
			{
			if (!nt.fired and nt.nm >= 2 and t + half >= nt.ta - lead)
				{
				send % "{" . keys[li] . "}"
				nt.fired := true
				break
				}
			}
		kept := []
		for i, nt in lane
			{
			if (nt.ta < t - 0.30)
				continue
			if (!nt.fired and (t - nt.tb) > 0.15)
				{
				pp := nt.bot + (TqV * (t - nt.tb))
				if (pp < top)
					{
					dup := false
					for j, o in lane
						{
						if (o.tb = ts and Abs(pp - o.bot) <= TqNoteD)
							{
							dup := true
							break
							}
						}
					if (dup)
						continue
					}
				}
			kept.Push(nt)
			}
		TqNotes[li] := kept
		li++
		}
	if (moving)
		TqLastLive := t
	return ((t - TqLastLive) <= 0.5 and (t - TqLastRing) <= 2.0)
}

NoiseHasMark(arr, n, x, tol) {
	i := 1
	while (i <= n)
		{
		if (Abs(arr[i] - x) <= tol)
			return true
		i++
		}
	return false
}

NoiseScan() {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft, QpcFreq, FishColor, FishBarColorTolerance
	global NoiseBarL, NoiseBarW, NoiseFishX, NoiseFound, NoiseScanned, NoiseFishFresh
	global NoisePrevC, NoisePrevT, NoiseFishPrev, NoiseFishT, NoiseStillX, NoiseStillC, NoiseWCal, NoiseJumpN
	global NoiseWCnt, NoiseWVote, NoiseZOK, NoiseZoneTgt
	global NoiseLastD, NoiseOscN, NoiseVelC
	global NoiseRowOff
	global NoiseCoastN
	global NoiseEHist
	global NoiseJumpHold
	global NoiseRate, NoiseRateT, NoiseN6, NoiseN8, NoiseN15, NoiseN45
	global NoiseAltW, NoiseAltN, NoiseZSeenT
	global NoiseBandT, NoiseBandB, NoiseRlW, NoiseRlN
	if (NoiseScanned)
		return NoiseFound
	NoiseScanned := true
	DllCall("QueryPerformanceCounter", "Int64*", rtnow)
	rdt := (NoiseRateT > 0) ? ((rtnow - NoiseRateT) / QpcFreq) : 0
	NoiseRateT := rtnow
	if (rdt > 0 and rdt < 0.25)
		{
		rnow := rdt / 0.040
		if (rnow < 1)
			rnow := 1
		NoiseRate := (NoiseRate * 0.8) + (rnow * 0.2)
		}
	if (NoiseRate < 1)
		NoiseRate := 1
	NoiseN6 := (NoiseRate <= 1) ? 6 : Max(2, Round(6 / NoiseRate))
	NoiseN8 := (NoiseRate <= 1) ? 8 : Max(2, Round(8 / NoiseRate))
	NoiseN15 := (NoiseRate <= 1) ? 15 : Max(3, Round(15 / NoiseRate))
	NoiseN45 := (NoiseRate <= 1) ? 45 : Max(8, Round(45 / NoiseRate))
	NoiseFound := false
	NoiseFishX := -1
	NoiseFishFresh := false
	y0 := Round(CaptureH * 0.10)
	y1 := Round(CaptureH * 0.35)
	if (y1 - y0 < 2)
		{
		y0 := 0
		y1 := CaptureH
		}
	step := 1
	ncol := CaptureW // step
	if (ncol < 40)
		return false
	bmWmax := Round(CaptureW * 0.008) + 2
	bvStep := CaptureH // 13
	if (bvStep < 1)
		bvStep := 1
	bvTot := 0
	byq := 0
	while (byq < CaptureH)
		{
		bvTot++
		byq += bvStep
		}
	bvNeed := Round(bvTot * 0.60)
	if (bvNeed < 3)
		bvNeed := 3
	bmN := 0
	bmX := []
	if (NoiseBandT > -99)
		{
		bT0 := pCaptureBits + (NoiseBandT * CaptureW * 4)
		bT2 := bT0 + (2 * CaptureW * 4)
		bB0 := pCaptureBits + ((NoiseBandB - 4) * CaptureW * 4)
		bRow := CaptureW * 4
		brun := -1
		bx := 0
		while (bx <= CaptureW)
			{
			bIsEdge := false
			if (bx < CaptureW)
				{
				v := NumGet(bT2 + 0, bx*4, "UInt")
				if (!(v & 0xF0F0F0) and (v & 0xFF) <= 6 and ((v >> 8) & 0xFF) <= 10 and ((v >> 16) & 0xFF) <= 6)
					{
					tMiss := 0
					bMiss := 0
					bk := 0
					while (bk < 5)
						{
						if (bk != 2)
							{
							v := NumGet(bT0 + 0, (bk*bRow) + bx*4, "UInt")
							if !(!(v & 0xF0F0F0) and (v & 0xFF) <= 6 and ((v >> 8) & 0xFF) <= 10 and ((v >> 16) & 0xFF) <= 6)
								tMiss++
							}
						v := NumGet(bB0 + 0, (bk*bRow) + bx*4, "UInt")
						if !(!(v & 0xF0F0F0) and (v & 0xFF) <= 6 and ((v >> 8) & 0xFF) <= 10 and ((v >> 16) & 0xFF) <= 6)
							bMiss++
						if (tMiss > 1 or bMiss > 1)
							break
						bk++
						}
					if (bk >= 5)
						bIsEdge := true
					}
				}
			if (bIsEdge)
				{
				if (brun < 0)
					brun := bx
				}
			else if (brun >= 0)
				{
				if (bx - brun <= bmWmax)
					{
					bmN++
					bmX[bmN] := (brun + bx - 1) // 2
					}
				brun := -1
				}
			bx++
			}
		}
	if (bmN = 0)
		{
		brun := -1
		bx := 0
		while (bx <= CaptureW)
			{
			bIsEdge := false
			if (bx < CaptureW)
				{
				bHit := 0
				bSeen := 0
				by2 := 0
				while (by2 < CaptureH)
					{
					v := NumGet(pCaptureBits + 0, (by2*CaptureW + bx)*4, "UInt")
					bSeen++
					if (!(v & 0xF0F0F0) and (v & 0xFF) <= 6 and ((v >> 8) & 0xFF) <= 10 and ((v >> 16) & 0xFF) <= 6)
						bHit++
					if ((bHit + (bvTot - bSeen)) < bvNeed)
						break
					by2 += bvStep
					}
				if (bHit >= bvNeed)
					bIsEdge := true
				}
			if (bIsEdge)
				{
				if (brun < 0)
					brun := bx
				}
			else if (brun >= 0)
				{
				if (bx - brun <= bmWmax)
					{
					bmN++
					bmX[bmN] := (brun + bx - 1) // 2
					}
				brun := -1
				}
			bx++
			}
		if (bmN >= 2)
			{
			lmid := CaptureH // 2
			lPT := -99
			lPB := -99
			lHit := false
			li := 1
			while (li <= bmN and !lHit)
				{
				lx := bmX[li]
				v := NumGet(pCaptureBits + 0, (lmid*CaptureW + lx)*4, "UInt")
				if (!(v & 0xF0F0F0) and (v & 0xFF) <= 6 and ((v >> 8) & 0xFF) <= 10 and ((v >> 16) & 0xFF) <= 6)
					{
					lt := lmid
					while (lt > -18)
						{
						v := NumGet(pCaptureBits + ((lt - 1)*CaptureW + lx)*4, 0, "UInt")
						if !(!(v & 0xF0F0F0) and (v & 0xFF) <= 6 and ((v >> 8) & 0xFF) <= 10 and ((v >> 16) & 0xFF) <= 6)
							break
						lt--
						}
					lb := lmid
					while (lb < CaptureH + 19)
						{
						v := NumGet(pCaptureBits + ((lb + 1)*CaptureW + lx)*4, 0, "UInt")
						if !(!(v & 0xF0F0F0) and (v & 0xFF) <= 6 and ((v >> 8) & 0xFF) <= 10 and ((v >> 16) & 0xFF) <= 6)
							break
						lb++
						}
					if (lt > -18 and lt < 0 and lb >= CaptureH and lb < CaptureH + 19 and (lb - lt + 1) >= CaptureH * 1.2 and (lb - lt + 1) <= CaptureH * 1.7)
						{
						if (lPT > -99 and Abs(lt - lPT) <= 1 and Abs(lb - lPB) <= 1)
							{
							NoiseBandT := Max(lt, lPT)
							NoiseBandB := Min(lb, lPB)
							lHit := true
							}
						lPT := lt
						lPB := lb
						}
					}
				li++
				}
			}
		}
	NoiseEHist.Push(bmX.Clone())
	if (NoiseEHist.Length() > 20)
		NoiseEHist.RemoveAt(1)
	if (bmN >= 2 and NoiseEHist.Length() >= 20)
		{
		sN := 0
		sKeep := []
		si := 1
		while (si <= bmN)
			{
			sx := bmX[si]
			scnt := 0
			sh := 1
			while (sh <= NoiseEHist.Length())
				{
				harr := NoiseEHist[sh]
				sj := 1
				while (sj <= harr.Length())
					{
					if (Abs(harr[sj] - sx) <= 2)
						{
						scnt++
						break
						}
					sj++
					}
				sh++
				}
			if (scnt < 18 or (NoisePrevC >= 0 and NoiseWCal >= 40 and (Abs(sx - (NoisePrevC - (NoiseWCal / 2))) <= 4 or Abs(sx - (NoisePrevC + (NoiseWCal / 2))) <= 4)))
				{
				sN++
				sKeep[sN] := sx
				}
			si++
			}
		if (sN >= 2)
			{
			bmN := sN
			bmX := sKeep
			}
		}
	if (bmN >= 2 and !NoiseZOK and bmX[1] > 3 and bmX[bmN] < CaptureW - 4)
		{
		wobs := bmX[bmN] - bmX[1]
		if (wobs >= CaptureW * 0.15 and wobs <= CaptureW * 0.45)
			{
			wq := (wobs // 4) * 4
			if (!NoiseWCnt.HasKey(wq))
				NoiseWCnt[wq] := 0
			if (NoiseWCnt[wq] < 40)
				NoiseWCnt[wq] := NoiseWCnt[wq] + 1
			if (NoiseWCal >= 40 and wq != NoiseWCal)
				{
				if (!NoiseWCnt.HasKey(NoiseWCal))
					NoiseWCnt[NoiseWCal] := 0
				if (NoiseWCnt[NoiseWCal] > 0)
					NoiseWCnt[NoiseWCal] := NoiseWCnt[NoiseWCal] - 1
				}
			wLead := 0
			if (NoiseWCal >= 40 and NoiseWCnt.HasKey(NoiseWCal))
				wLead := NoiseWCnt[NoiseWCal]
			if (NoiseWCal < 40 or NoiseWCnt[wq] > wLead)
				{
				NoiseWVote := NoiseWCnt[wq]
				NoiseWCal := wq
				}
			}
		}
	wexp := (NoiseWCal >= 40) ? NoiseWCal : (CaptureW * 0.303)
	wtol := Round(CaptureW * 0.016)
	if (wtol < 10)
		wtol := 10
	pairOK := false
	pi := 1
	while (pi <= bmN)
		{
		pj := pi + 1
		while (pj <= bmN)
			{
			if (Abs((bmX[pj] - bmX[pi]) - wexp) <= wtol)
				pairOK := true
			pj++
			}
		pi++
		}
	arwOK := false
	if (!pairOK)
		{
		ay0 := Round(CaptureH * 0.46)
		ay1 := Round(CaptureH * 0.87)
		if (ay1 <= ay0 + 1)
			{
			ay0 := CaptureH // 2
			ay1 := ay0 + 2
			}
		acnt := []
		astep := 2
		ax := 0
		while (ax < CaptureW)
			{
			cc := 0
			ay := ay0
			while (ay < ay1)
				{
				v := NumGet(pCaptureBits + 0, (ay*CaptureW + ax)*4, "UInt")
				if (((((v & 0xFF) + ((v >> 8) & 0xFF) + ((v >> 16) & 0xFF)) // 3)) <= 12)
					cc++
				ay += 4
				}
			acnt[ax] := cc
			ax += astep
			}
		awmin := Round(CaptureW * 0.019)
		awmax := Round(CaptureW * 0.09)
		bestAw := 0
		bestAa := -1
		bestAb := -1
		ra := -1
		ax := 0
		while (ax <= CaptureW)
			{
			isa := (ax < CaptureW and acnt[ax] >= 1)
			if (isa)
				{
				if (ra < 0)
					ra := ax
				}
			else if (ra >= 0)
				{
			rb := ax - astep
				aw := rb - ra + 1
				if (aw >= awmin and aw <= awmax and aw > bestAw)
					{
					bestAw := aw
					bestAa := ra
					bestAb := rb
					}
				ra := -1
				}
		ax += astep
			}
		if (bestAw > 0)
			{
			th := bestAw // 3
			if (th < 1)
				th := 1
			lsum := 0
			rsum := 0
			kk := 0
			while (kk < th)
				{
				lsum += acnt[bestAa + kk]
				rsum += acnt[bestAb - kk]
				kk++
				}
		useW := (NoiseWCal >= 40) ? NoiseWCal : (CaptureW * 0.30)
			ains := Round(useW * 0.125)
			acx := (bestAa + bestAb) // 2
			if (rsum > lsum)
				{
				barRp := acx + ains
			barLp := barRp - Round(useW)
				}
			else
				{
				barLp := acx - ains
			barRp := barLp + Round(useW)
				}
			if (barLp < 0)
			barLp := barLp
			if (barRp > CaptureW - 1)
			barRp := barRp
			if (barRp - barLp >= 40)
				{
				arwL := barLp
				arwR := barRp
				arwOK := true
				}
			}
		}
	wexp := (NoiseWCal >= 40) ? NoiseWCal : (CaptureW * 0.303)
	wtol := Round(CaptureW * 0.016)
	if (wtol < 10)
		wtol := 10
	nrun := 0
	if (!pairOK and !arwOK)
		{
		lum := []
		gex := []
		hist := []
		bi := 0
		while (bi < 64)
			{
			hist[bi] := 0
			bi++
			}
		i := 0
		while (i < ncol)
			{
			x := i * step
			s := 0
			sg := 0
			smx := 0
			c := 0
			y := y0
			while (y < y1)
				{
				v := NumGet(pCaptureBits + 0, (y*CaptureW + x)*4, "UInt")
				pb := (v & 0xFF)
				pg := ((v >> 8) & 0xFF)
				pr := ((v >> 16) & 0xFF)
				s += (pr + pg + pb) // 3
				sg += pg
				smx += (pr > pb) ? pr : pb
				c++
				y += 2
				}
			if (c < 1)
				c := 1
			lv := s // c
			lum[i] := lv
			gex[i] := (sg - smx) // c
			bi := lv // 4
			if (bi > 63)
				bi := 63
			if (bi < 0)
				bi := 0
			hist[bi] := hist[bi] + 1
			i++
			}
		need := Round(ncol * 0.20)
		acc := 0
		bg := 0
		bi := 0
		while (bi < 64)
			{
			acc += hist[bi]
			if (acc >= need)
				{
				bg := bi * 4
				break
				}
			bi++
			}
		need := Round(ncol * 0.98)
		acc := 0
		pk := 255
		bi := 0
		while (bi < 64)
			{
			acc += hist[bi]
			if (acc >= need)
				{
				pk := bi * 4
				break
				}
			bi++
			}
		if (pk - bg < 40)
			return false
		thr := bg + ((pk - bg) * 0.45)
		gapmax := Round(ncol * 0.025)
		if (gapmax < 5)
			gapmax := 5
		minw := Round(ncol * 0.22)
		if (minw < 20)
			minw := 20
		rs := -1
		re := -1
		gap := 0
		nrun := 0
		rA := []
		rB := []
		i := 0
		while (i <= ncol)
			{
			isb := (i < ncol and lum[i] >= thr)
			if (isb)
				{
				if (rs < 0)
					rs := i
				re := i
				gap := 0
				}
			else if (rs >= 0)
				{
				gap++
				if (gap > gapmax or i = ncol)
					{
					gsum := 0
					gn := 0
					gi := rs
					while (gi <= re)
						{
						gsum += gex[gi]
						gn++
						gi++
						}
					if (gn < 1)
						gn := 1
					if (re - rs + 1 >= minw and (gsum // gn) >= 25)
						{
						nrun++
						rA[nrun] := rs
						rB[nrun] := re
						}
					rs := -1
					gap := 0
					}
				}
			i++
			}
		}
	gotBar := (nrun >= 1)
	bs := -99999
	be := -1
	DllCall("QueryPerformanceCounter", "Int64*", tnow)
	fresh := (NoisePrevT > 0 and ((tnow - NoisePrevT) / QpcFreq) < 0.6)
	if (gotBar)
		{
		bestI := 0
		bestSc := -999999
		k := 1
		while (k <= nrun)
			{
			w := rB[k] - rA[k] + 1
			cx := ((rA[k] + rB[k]) * step) // 2
			sc := w
			if (fresh)
				sc := w - (Abs(cx - NoisePrevC) // step)
			if (sc > bestSc)
				{
				bestSc := sc
				bestI := k
				}
			k++
			}
		bs := rA[bestI]
		be := rB[bestI]
		if (NoiseWCal < 40 and rA[bestI] > 0 and rB[bestI] < ncol - 1)
			NoiseWCal := (be - bs + 1) * step
		}
	bdL := 0
	bdOK := false
	bdR := -1
	bdBest := 999999
	bdPair := false
	bdFresh := (NoisePrevT > 0 and NoisePrevC >= 0 and ((tnow - NoisePrevT) / QpcFreq) < 0.8)
	arwC := arwOK ? ((arwL + arwR) // 2) : -99999
	mirL := NoisePrevC - (wexp / 2)
	mirR := NoisePrevC + (wexp / 2)
	mirTol := Round(CaptureW * 0.03)
	if (mirTol < 12)
		mirTol := 12
	bi2 := 1
	while (bi2 <= bmN)
		{
		bj := bi2 + 1
		while (bj <= bmN)
			{
			sep := bmX[bj] - bmX[bi2]
			isMirror := (bdFresh and ((Abs(bmX[bj] - mirL) <= mirTol and bmX[bi2] < mirL - (wexp / 2))
				or (Abs(bmX[bi2] - mirR) <= mirTol and bmX[bj] > mirR + (wexp / 2))))
			if (Abs(sep - wexp) <= wtol and !isMirror)
				{
				cc := (bmX[bi2] + bmX[bj]) // 2
				scr := Abs(sep - wexp) * 2
				if (bdFresh)
					scr += Abs(cc - NoisePrevC)
				else if (arwOK)
					scr += Abs(cc - arwC)
				if (scr < bdBest)
					{
					bdBest := scr
					bdL := bmX[bi2]
					bdOK := true
					bdR := bmX[bj]
					bdPair := true
					}
				}
			bj++
			}
		bi2++
		}
	if (bdPair and arwOK and !bdFresh and Abs(((bdL + bdR) // 2) - arwC) > Round(CaptureW * 0.07))
		{
		bdOK := false
		bdPair := false
		}
	DllCall("QueryPerformanceCounter", "Int64*", altNow)
	if (NoiseZOK)
		NoiseZSeenT := altNow
	altWin := (!NoiseZOK and NoiseZSeenT > 0 and ((altNow - NoiseZSeenT) / QpcFreq) < 4.0)
	if (bdPair or !altWin)
		NoiseAltN := 0
	else if (NoiseWCal >= 40)
		{
		altBest := -1
		altL := 0
		altR := 0
		ai := 1
		while (ai <= bmN)
			{
			aj := ai + 1
			while (aj <= bmN)
				{
				asep := bmX[aj] - bmX[ai]
				arat := (asep * 100) // NoiseWCal
				if ((arat >= 50 and arat <= 92) or (arat >= 108 and arat <= 150))
					{
					if (NoiseAltW > 0)
						asc := Abs(asep - NoiseAltW)
					else if (NoiseFishPrev >= 0)
						asc := Abs(((bmX[ai] + bmX[aj]) // 2) - NoiseFishPrev)
					else
						asc := 0
					if (altBest < 0 or asc < altBest)
						{
						altBest := asc
						altL := bmX[ai]
						altR := bmX[aj]
						}
					}
				aj++
				}
			ai++
			}
		if (altBest < 0)
			{
			NoiseAltN := 0
			NoiseAltW := 0
			}
		else if (NoiseAltW > 0 and Abs((altR - altL) - NoiseAltW) <= 4)
			NoiseAltN := NoiseAltN + 1
		else
			{
			NoiseAltW := altR - altL
			NoiseAltN := 1
			}
		if (NoiseAltN >= 3)
			{
			NoiseWCal := altR - altL
			NoiseWCnt := {}
			NoiseWVote := 0
			NoiseJumpN := 0
			NoiseOscN := 0
			NoiseCoastN := 0
			NoiseAltN := 0
			NoiseAltW := 0
			bdL := altL
			bdR := altR
			bdOK := true
			bdPair := true
			bdFresh := false
			wexp := NoiseWCal
			}
		}
	if (!bdPair and NoiseWCal >= 40 and bmN >= 2)
		{
		rlN := 0
		ri := 1
		while (ri < bmN)
			{
			rj := ri + 1
			while (rj <= bmN)
				{
				rsep := bmX[rj] - bmX[ri]
				if (rsep >= CaptureW * 0.15 and rsep <= CaptureW * 0.45)
					{
					rlN++
					rlL := bmX[ri]
					rlR := bmX[rj]
					}
				rj++
				}
			ri++
			}
		if (rlN = 1 and Abs((rlR - rlL) - NoiseWCal) > wtol and (NoisePrevC < 0 or Abs(((rlL + rlR) // 2) - NoisePrevC) <= CaptureW * 0.3))
			{
			if (NoiseRlW > 0 and Abs((rlR - rlL) - NoiseRlW) <= 3)
				NoiseRlN := NoiseRlN + 1
			else
				{
				NoiseRlW := rlR - rlL
				NoiseRlN := 1
				}
			if (NoiseRlN >= 2)
				{
				NoiseWCal := rlR - rlL
				NoiseWCnt := {}
				NoiseWVote := 0
				NoiseJumpN := 0
				NoiseOscN := 0
				NoiseCoastN := 0
				NoiseRlN := 0
				NoiseRlW := 0
				bdL := rlL
				bdR := rlR
				bdOK := true
				bdPair := true
				bdFresh := false
				wexp := NoiseWCal
				}
			}
		else
			NoiseRlN := 0
		}
	if (!bdOK)
		{
		bi2 := 1
		while (bi2 <= bmN)
			{
			cLx := bmX[bi2]
			cRx := Round(bmX[bi2] + wexp)
			cc := (cLx + cRx) // 2
			scr := bdFresh ? Abs(cc - NoisePrevC) : (arwOK ? Abs(cc - arwC) : 40)
			if (cRx < CaptureW - 3 and !(NoiseFishPrev >= 0 and Abs(cRx - NoiseFishPrev) <= 12) and !NoiseHasMark(bmX, bmN, cRx, wtol))
				scr += CaptureW // 2
			if (NoiseWCal >= 40 and cRx > CaptureW + (CaptureW // 60))
				scr += CaptureW
			if (scr < bdBest)
				{
				bdBest := scr
				bdL := cLx
				bdOK := true
				bdR := cRx
				}
			cRx := bmX[bi2]
			cLx := Round(bmX[bi2] - wexp)
			cc := (cLx + cRx) // 2
			scr := bdFresh ? Abs(cc - NoisePrevC) : (arwOK ? Abs(cc - arwC) : 60)
			if (cLx > 2 and !(NoiseFishPrev >= 0 and Abs(cLx - NoiseFishPrev) <= 12) and !NoiseHasMark(bmX, bmN, cLx, wtol))
				scr += CaptureW // 2
			if (NoiseWCal >= 40 and cLx < -(CaptureW // 60))
				scr += CaptureW
			if (scr < bdBest)
				{
				bdBest := scr
				bdL := cLx
				bdOK := true
				bdR := cRx
				}
			bi2++
			}
		}
	if (!bdOK and arwOK and NoiseWCal >= 40)
		{
		bdL := arwL
		bdOK := true
		bdR := arwR
		}
	if (bdOK and bdFresh and NoiseCoastN = 0)
		{
		ccF := (bdL + bdR) // 2
		if (Abs(ccF - NoisePrevC) > Round(CaptureW * 0.12 * NoiseRate))
			{
			NoiseJumpN := NoiseJumpN + 1
			if (NoiseJumpN < NoiseN8)
				bdOK := false
			else
				NoiseJumpN := 0
			}
		}
	if (bdOK and bdR - bdL >= 40)
		{
		bs := bdL // step
		be := bdR // step
		gotBar := true
		if (bdPair and NoiseWVote < 2)
			{
			if (NoiseWCal < 40)
				NoiseWCal := bdR - bdL
			else if (Abs((bdR - bdL) - NoiseWCal) <= NoiseWCal * 0.10)
				NoiseWCal := (NoiseWCal * 0.90) + ((bdR - bdL) * 0.10)
			}
		}
	if (gotBar and bs >= 0 and bdFresh and NoiseCoastN = 0)
		{
		ccF2 := ((bs + be) * step) // 2
		if (Abs(ccF2 - NoisePrevC) > Round(CaptureW * 0.12 * NoiseRate))
			{
			NoiseJumpN := NoiseJumpN + 1
			if (NoiseJumpN < NoiseN15)
				gotBar := false
			else
				NoiseJumpN := 0
			}
		else
			NoiseJumpN := 0
		}
	if (gotBar and bdFresh and NoisePrevC >= 0)
		{
		ccF3 := ((bs + be) * step) // 2
		dNow := ccF3 - NoisePrevC
		if (NoiseLastD != 0 and (dNow * NoiseLastD) < 0 and Abs(dNow) > Round(CaptureW * 0.02 * NoiseRate) and NoiseOscN < NoiseN6)
			{
			NoiseOscN := NoiseOscN + 1
			oHalf := (be - bs) // 2
			bs := (NoisePrevC // step) - oHalf
			be := (NoisePrevC // step) + oHalf
			}
		else
			{
			NoiseOscN := 0
			NoiseLastD := dNow
			NoiseVelC := ((NoiseVelC * 6) + (dNow * 4)) // 10
			}
		}
	if (gotBar and NoiseWCal >= 40)
		{
		cwid := (be - bs + 1) * step
		if (Abs(cwid - NoiseWCal) > (NoiseWCal // 4))
			gotBar := false
		}
	if (!gotBar)
		{
		if (NoisePrevC >= 0 and NoiseWCal >= 40 and NoiseCoastN < NoiseN6)
			{
			NoiseCoastN := NoiseCoastN + 1
			cstep := NoiseVelC
			cmax := Round(CaptureW * 0.035 * NoiseRate)
			if (cmax < 25)
				cmax := 25
			if (cstep > cmax)
				cstep := cmax
			if (cstep < -cmax)
				cstep := -cmax
			predC := NoisePrevC + cstep
			if (predC < 0)
				predC := 0
			if (predC > CaptureW)
				predC := CaptureW
			bs := Round((predC - (NoiseWCal / 2)) / step)
			be := Round((predC + (NoiseWCal / 2)) / step)
			gotBar := true
			}
		else
			return false
		}
	else
		NoiseCoastN := 0
	NoiseBarL := FishBarLeft + (bs * step)
	NoiseBarW := (be - bs + 1) * step
	NoiseFound := true
	NoisePrevC := ((bs + be) * step) // 2
	NoisePrevT := tnow
	if (Abs(NoisePrevC - NoiseStillX) <= 2)
		NoiseStillC := NoiseStillC + 1
	else
		{
		NoiseStillC := 0
		NoiseStillX := NoisePrevC
		}
	if (NoiseStillC >= NoiseN45)
		{
		NoisePrevT := 0
		NoiseStillC := 0
		}
	fbgr := RfBgr(RfColFirst(FishColor))
	ftB := (fbgr >> 16) & 0xFF
	ftG := (fbgr >> 8) & 0xFF
	ftR := fbgr & 0xFF
	ftol := FishBarColorTolerance
	if (ftol < 6)
		ftol := 6
	frow := CaptureH // 2
	fneed := (NoiseZOK or NoiseZoneTgt >= 0) ? 3 : 4
	fwmax := Round(CaptureW * 0.028)
	if (fwmax < 8)
		fwmax := 8
	edgeM := Round(CaptureW * 0.016)
	if (edgeM < 10)
		edgeM := 10
	barA := bs * step
	barB := be * step
	nf := 0
	fX := []
	fx2 := 0
	while (fx2 < CaptureW)
		{
		pv := NumGet(pCaptureBits + 0, (frow*CaptureW + fx2)*4, "UInt")
		if ((Abs((pv & 0xFF) - ftB) <= ftol and Abs(((pv >> 8) & 0xFF) - ftG) <= ftol and Abs(((pv >> 16) & 0xFF) - ftR) <= ftol) or (((pv >> 8) & 0xFF) >= 34 and ((pv >> 8) & 0xFF) <= 104 and ((pv >> 16) & 0xFF) <= 52 and (pv & 0xFF) <= 76 and ((pv >> 8) & 0xFF) >= ((pv >> 16) & 0xFF) + 10 and ((pv >> 8) & 0xFF) >= (pv & 0xFF) + 4 and ((((pv >> 16) & 0xFF) + ((pv >> 8) & 0xFF) + (pv & 0xFF)) // 3) >= 14 and ((((pv >> 16) & 0xFF) + ((pv >> 8) & 0xFF) + (pv & 0xFF)) // 3) <= 74))
			{
			fst := fx2
			while (fx2 < CaptureW)
				{
				pv := NumGet(pCaptureBits + 0, (frow*CaptureW + fx2)*4, "UInt")
				if !((Abs((pv & 0xFF) - ftB) <= ftol and Abs(((pv >> 8) & 0xFF) - ftG) <= ftol and Abs(((pv >> 16) & 0xFF) - ftR) <= ftol) or (((pv >> 8) & 0xFF) >= 34 and ((pv >> 8) & 0xFF) <= 104 and ((pv >> 16) & 0xFF) <= 52 and (pv & 0xFF) <= 76 and ((pv >> 8) & 0xFF) >= ((pv >> 16) & 0xFF) + 10 and ((pv >> 8) & 0xFF) >= (pv & 0xFF) + 4 and ((((pv >> 16) & 0xFF) + ((pv >> 8) & 0xFF) + (pv & 0xFF)) // 3) >= 14 and ((((pv >> 16) & 0xFF) + ((pv >> 8) & 0xFF) + (pv & 0xFF)) // 3) <= 74))
					break
				fx2++
				}
			fw := fx2 - fst
			if (fw >= 3 and fw <= fwmax)
				{
				fcx := fst + (fw // 2)
				fhits := 0
				fk := 1
				while (fk <= 5)
					{
					fy := Floor(CaptureH * (fk*2 - 1) / 10)
					if (fy >= CaptureH)
						fy := CaptureH - 1
					pv := NumGet(pCaptureBits + 0, (fy*CaptureW + fcx)*4, "UInt")
					if (NoiseIsCore(pv, ftB, ftG, ftR, ftol))
						fhits++
					fk++
					}
				if (fhits >= fneed and Abs(fcx - barA) > edgeM and Abs(fcx - barB) > edgeM)
					{
					gSum := 0
					gN := 0
					fy := 2
					while (fy < CaptureH - 2)
						{
						v := NumGet(pCaptureBits + 0, (fy*CaptureW + fcx)*4, "UInt")
						gSum += ((v >> 8) & 0xFF)
						gN++
						fy++
						}
					if (gN < 1)
						gN := 1
					ownG := gSum // gN
					maxL := 0
					maxR := 0
					kk := 1
					while (kk <= 4)
						{
						xx := fst - kk
						if (xx < 0)
							xx := 0
						v := NumGet(pCaptureBits + 0, (frow*CaptureW + xx)*4, "UInt")
						gv := (v >> 8) & 0xFF
						if (gv > maxL)
							maxL := gv
						xx := fx2 - 1 + kk
						if (xx > CaptureW - 1)
							xx := CaptureW - 1
						v := NumGet(pCaptureBits + 0, (frow*CaptureW + xx)*4, "UInt")
						gv := (v >> 8) & 0xFF
						if (gv > maxR)
							maxR := gv
						kk++
						}
					if (maxL >= ownG + 80 and maxR >= ownG + 80)
						{
						nf++
						fX[nf] := fcx
						}
					}
				}
			}
		else
			fx2++
		}
	if (NoiseBandT > -99)
		{
		pTop := Max(-17, NoiseBandT - Round(CaptureH * 0.41) + 1)
		pBot := NoiseBandT - 2
		if (pBot - pTop >= 4)
			{
			pr0 := pCaptureBits + (((pTop + pBot) // 2) * CaptureW * 4)
			pr1 := pCaptureBits + ((pTop + 1) * CaptureW * 4)
			pr2 := pCaptureBits + ((pBot - 1) * CaptureW * 4)
			nc := 0
			cX := []
			fk := 1
			while (fk <= nf)
				{
				pv := NumGet(pr0 + 0, fX[fk]*4, "UInt")
				if ((pv & 0xFF) <= 52 and ((pv >> 16) & 0xFF) <= 12 and ((pv >> 8) & 0xFF) >= 40 and ((pv >> 8) & 0xFF) <= 80 and ((pv >> 8) & 0xFF) >= (pv & 0xFF) + 8)
					{
					pv := NumGet(pr1 + 0, fX[fk]*4, "UInt")
					if ((pv & 0xFF) <= 52 and ((pv >> 16) & 0xFF) <= 12 and ((pv >> 8) & 0xFF) >= 40 and ((pv >> 8) & 0xFF) <= 80 and ((pv >> 8) & 0xFF) >= (pv & 0xFF) + 8)
						{
						pv := NumGet(pr2 + 0, fX[fk]*4, "UInt")
						if ((pv & 0xFF) <= 52 and ((pv >> 16) & 0xFF) <= 12 and ((pv >> 8) & 0xFF) >= 40 and ((pv >> 8) & 0xFF) <= 80 and ((pv >> 8) & 0xFF) >= (pv & 0xFF) + 8)
							{
							nc++
							cX[nc] := fX[fk]
							}
						}
					}
				fk++
				}
			if (nc >= 1)
				{
				fX := cX
				nf := nc
				}
			else
				{
				mN := 0
				mX := []
				mx2 := 0
				while (mx2 < CaptureW)
					{
					pv := NumGet(pr0 + 0, mx2*4, "UInt")
					if ((pv & 0xFF) <= 52 and ((pv >> 16) & 0xFF) <= 12 and ((pv >> 8) & 0xFF) >= 40 and ((pv >> 8) & 0xFF) <= 80 and ((pv >> 8) & 0xFF) >= (pv & 0xFF) + 8)
						{
						mst := mx2
						while (mx2 < CaptureW)
							{
							pv := NumGet(pr0 + 0, mx2*4, "UInt")
							if !((pv & 0xFF) <= 52 and ((pv >> 16) & 0xFF) <= 12 and ((pv >> 8) & 0xFF) >= 40 and ((pv >> 8) & 0xFF) <= 80 and ((pv >> 8) & 0xFF) >= (pv & 0xFF) + 8)
								break
							mx2++
							}
						mw := mx2 - mst
						if (mw >= 3 and mw <= Max(8, Round(CaptureW * 0.014)))
							{
							mcx := mst + (mw // 2)
							pv := NumGet(pr1 + 0, mcx*4, "UInt")
							if ((pv & 0xFF) <= 52 and ((pv >> 16) & 0xFF) <= 12 and ((pv >> 8) & 0xFF) >= 40 and ((pv >> 8) & 0xFF) <= 80 and ((pv >> 8) & 0xFF) >= (pv & 0xFF) + 8)
								{
								pv := NumGet(pr2 + 0, mcx*4, "UInt")
								if ((pv & 0xFF) <= 52 and ((pv >> 16) & 0xFF) <= 12 and ((pv >> 8) & 0xFF) >= 40 and ((pv >> 8) & 0xFF) <= 80 and ((pv >> 8) & 0xFF) >= (pv & 0xFF) + 8)
									{
									ownG := (NumGet(pr0 + 0, mcx*4, "UInt") >> 8) & 0xFF
									maxL := 0
									maxR := 0
									kk := 1
									while (kk <= 4)
										{
										xx := Max(0, mst - kk)
										gv := (NumGet(pr0 + 0, xx*4, "UInt") >> 8) & 0xFF
										if (gv > maxL)
											maxL := gv
										xx := Min(CaptureW - 1, mx2 - 1 + kk)
										gv := (NumGet(pr0 + 0, xx*4, "UInt") >> 8) & 0xFF
										if (gv > maxR)
											maxR := gv
										kk++
										}
									if (maxL >= ownG + 80 and maxR >= ownG + 80)
										{
										mN++
										mX[mN] := mcx
										}
									}
								}
							}
						}
					else
						mx2++
					}
				if (mN >= 1)
					{
					fX := mX
					nf := mN
					}
				}
			}
		}
	if (nf < 1)
		{
		if (NoiseFishT > 0 and NoiseFishPrev >= 0 and ((tnow - NoiseFishT) / QpcFreq) < 1.2)
			NoiseFishX := FishBarLeft + NoiseFishPrev
		return true
		}
	fpick := fX[1]
	if (NoiseFishT > 0 and NoiseFishPrev >= 0 and ((tnow - NoiseFishT) / QpcFreq) < 0.35)
		{
		fjmax := Round(CaptureW * 0.10)
		if (fjmax < 100)
			fjmax := 100
		fnear := false
		fk2 := 1
		while (fk2 <= nf)
			{
			if (Abs(fX[fk2] - NoiseFishPrev) <= fjmax)
				fnear := true
			fk2++
			}
		if (!fnear)
			{
			NoiseFishX := FishBarLeft + NoiseFishPrev
			return true
			}
		}
	if (NoiseFishT > 0 and ((tnow - NoiseFishT) / QpcFreq) < 0.6)
		{
		fbestd := 999999
		k := 1
		while (k <= nf)
			{
			fd := Abs(fX[k] - NoiseFishPrev)
			if (fd < fbestd)
				{
				fbestd := fd
				fpick := fX[k]
				}
			k++
			}
		}
	NoiseFishX := FishBarLeft + fpick
	NoiseFishFresh := true
	NoiseFishPrev := fpick
	NoiseFishT := tnow
	return true
}

;====================================================================================================;

BellonaScan() {
	global pCaptureBits, CaptureW, CaptureH
	global BelA, BelB, BelF, BelOK, BelSeen
	BelSeen := false
	BelA := [0, 0]
	BelB := [0, 0]
	BelF := [-1, -1]
	BelOK := [false, false]
	step := 4
	ncol := CaptureW // step
	col := []
	i := 0
	while (i < ncol)
		{
		x := i * step
		s := 0
		c := 0
		y := 5
		while (y < CaptureH - 5)
			{
			v := NumGet(pCaptureBits + 0, (y*CaptureW + x)*4, "UInt")
			s += ((v & 0xFF) + ((v >> 8) & 0xFF) + ((v >> 16) & 0xFF)) // 3
			c++
			y += 4
			}
		col[i] := (c > 0) ? (s // c) : 0
		i++
		}
	pref := []
	pref[0] := 0
	i := 0
	while (i < ncol)
		{
		pref[i+1] := pref[i] + col[i]
		i++
		}
	halfc := ncol // 2
	gapmax := Round(ncol * 0.035)
	if (gapmax < 4)
		gapmax := 4
		minw := Round(halfc * 0.15)
		maxw := Round(halfc * 0.85)
	sd := 1
	while (sd <= 2)
		{
		lo := (sd = 1) ? 0 : halfc
		hi := (sd = 1) ? halfc : ncol
		hist := []
		bi := 0
		while (bi < 64)
			{
			hist[bi] := 0
			bi++
			}
		k := 0
		i := lo
		while (i < hi)
			{
			bi := col[i] // 4
			if (bi > 63)
				bi := 63
			if (bi < 0)
				bi := 0
			hist[bi] := hist[bi] + 1
			k++
			i++
			}
		need := Round(k * 0.20)
		acc := 0
		bg := 0
		bi := 0
		while (bi < 64)
			{
			acc += hist[bi]
			if (acc >= need)
				{
				bg := bi * 4
				break
				}
			bi++
			}
		need := Round(k * 0.98)
		acc := 0
		pk := 255
		bi := 0
		while (bi < 64)
			{
			acc += hist[bi]
			if (acc >= need)
				{
				pk := bi * 4
				break
				}
			bi++
			}
		thr := bg + ((pk - bg) * 0.40)
		if (thr < bg + 25)
			thr := bg + 25

		bestLen := 0
		bestS := -1
		bestE := -1
		rs := -1
		re := -1
		gap := 0
		i := lo
		while (i < hi)
			{
			if (col[i] >= thr)
				{
				if (rs < 0)
					rs := i
				re := i
				gap := 0
				}
			else if (rs >= 0)
				{
				gap++
				if (gap > gapmax)
					{
					if (re - rs > bestLen)
						bestLen := re - rs, bestS := rs, bestE := re
					rs := -1
					gap := 0
					}
				}
			i++
			}
		if (rs >= 0 and re - rs > bestLen)
			bestLen := re - rs, bestS := rs, bestE := re

		barw := bestLen + 1
		bestIn := (bestS >= 0) ? ((pref[bestE+1] - pref[bestS]) / barw) : 0
		bestSc := bestIn - bg
		if (bestS >= 0 and barw >= minw and barw <= maxw and bestSc >= 28)
			BelSeen := true
		if (bestS >= 0 and barw >= minw and barw <= maxw and bestSc >= 120)
			{
			BelA[sd] := bestS * step
			BelB[sd] := bestE * step
			BelOK[sd] := true
			fhi := bestIn * 0.62
			flo := (pk - bg) * 0.15
			if (flo < 20)
				flo := 20
			flo := bg + flo
			wcap := Round(halfc * 0.10)
			if (wcap < 2)
				wcap := 2
			s0 := bestS - 3
			if (s0 < lo)
				s0 := lo
			s1 := bestE + 3
			if (s1 > hi - 1)
				s1 := hi - 1
			fbest := 99999
			fs := -1
			fe := -1
			cs := -1
			i := s0
			while (i <= s1 + 1)
				{
				isf := (i <= s1 and col[i] >= flo and col[i] < fhi)
				if (isf)
					{
					if (cs < 0)
						cs := i
					}
				else if (cs >= 0)
					{
					ce := i - 1
					if (ce - cs <= wcap and cs > lo and ce < hi - 1 and col[cs-1] >= fhi and col[ce+1] >= fhi)
						{
						cm := (pref[ce+1] - pref[cs]) / (ce - cs + 1)
						if (cm < fbest)
							fbest := cm, fs := cs, fe := ce
						}
					cs := -1
					}
				i++
				}
			if (fs >= 0)
				BelF[sd] := ((fs + fe) * step) // 2
			}
		sd++
		}
	return (BelOK[1] or BelOK[2]) ? 2 : (BelSeen ? 1 : 0)
}

BellonaDrive(sd) {
	global BelA, BelB, BelF, BelOK, BelPrevF, BelPrevB, BelPrevT, BelVel, BelBVel, BelDown, QpcFreq
	global BelSide, BelAcc, BelBias, WindowWidth
	if (!BelOK[sd])
		return
	bar := (BelA[sd] + BelB[sd]) / 2
	fish := BelF[sd]
	if (fish < 0)
		{
		if (BelSide[sd] = 0)
			return
		BelAcc[sd] := 0
		BellonaSet(sd, BelSide[sd] > 0)
		return
		}
	rs := WindowWidth / 2560
	if (rs <= 0)
		rs := 1
	BelSide[sd] := (fish > bar) ? 1 : -1
	DllCall("QueryPerformanceCounter", "Int64*", tn)
	dt := 0
	if (BelPrevT[sd] > 0)
		{
		dt := (tn - BelPrevT[sd]) / QpcFreq
		if (dt > 0.0005 and dt < 0.5)
			{
			BelVel[sd]  := BelVel[sd]  * 0.4 + ((fish - BelPrevF[sd]) / dt) * 0.6
			BelBVel[sd] := BelBVel[sd] * 0.4 + ((bar  - BelPrevB[sd]) / dt) * 0.6
			}
		}
	BelPrevT[sd] := tn
	BelPrevF[sd] := fish
	BelPrevB[sd] := bar
	e := bar - fish
	rel := BelBVel[sd] - BelVel[sd]
	if (Abs(e) <= 36 * rs and Abs(rel) <= 120 * rs)
		{
		kp := 0.0122 / rs
		kd := 0.00488 / rs
		if (dt > 0 and dt < 0.1)
			{
			BelBias[sd] := BelBias[sd] - (0.25 * kp * e * dt)
			if (BelBias[sd] > 0.2)
				BelBias[sd] := 0.2
			if (BelBias[sd] < -0.2)
				BelBias[sd] := -0.2
			}
		duty := 0.463 + BelBias[sd] - (kp * e) - (kd * rel)
		if (duty < 0)
			duty := 0
		if (duty > 1)
			duty := 1
		BelAcc[sd] := BelAcc[sd] + duty
		if (BelAcc[sd] >= 1)
			{
			BelAcc[sd] := BelAcc[sd] - 1
			want := true
			}
		else
			want := false
		}
	else
		want := ((e + (rel * 0.5)) < 0)
	BellonaSet(sd, want)
}

BellonaSet(sd, want) {
	global BelDown
	btn := (sd = 1) ? "LButton" : "RButton"
	if (want and (!BelDown[sd] or !GetKeyState(btn)))
		{
		if (sd = 1)
			send {lbutton down}
		else
			send {rbutton down}
		BelDown[sd] := true
		}
	else if (!want and (BelDown[sd] or GetKeyState(btn)))
		{
		if (sd = 1)
			send {lbutton up}
		else
			send {rbutton up}
		BelDown[sd] := false
		}
}

BellonaRelease() {
	global BelDown
	send {lbutton up}
	send {rbutton up}
	BelDown := [false, false]
}

LineScan() {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft
	global LineList, LineFishX, LineNoteX, LineFound, LineScanned
	global LineBarL, LineBarW, LineBarAge, LineFishSeen, SpecialRod, DarkHoldN, DarkFlashing, DarkAcc
	if (LineScanned)
		return LineFound
	LineScanned := true
	if (SpecialRod = "Darkheart")
		{
		if (RfBandDark())
			{
			DarkHoldN := DarkHoldN + 1
			if (DarkHoldN <= 45 and LineBarW >= 1)
				{
				if (!DarkFlashing)
					DarkAcc := 0
				DarkFlashing := true
				return LineFound
				}
			}
		else
			{
			DarkHoldN := 0
			DarkFlashing := false
			}
		}
	LineFound := false
	LineFishSeen := false
	LineFishX := -1
	LineNoteX := -1
	LineList := []

	VarSetCapacity(HitBuf, CaptureW * 4, 0)
	pHits := &HitBuf

	pFn := LineHitsFn()
	if (pFn)
		rows := DllCall(pFn, "Ptr", pCaptureBits, "Int", CaptureW, "Int", CaptureH, "Ptr", pHits, "Int")
	else
		rows := LineHitsAhk(pCaptureBits, CaptureW, CaptureH, pHits)

	need := Round(rows * 0.5)
	if (need < 2)
		need := 2

	s := -1
	p := -1
	x := 1
	q := pHits + 4
	while (x < CaptureW)
		{
		if (NumGet(q + 0, 0, "UInt") >= need)
			{
			if (s < 0)
				s := x, p := x
			else if (x - p <= 3)
				p := x
			else
				{
				LineList.Push((s + p) // 2)
				s := x
				p := x
				}
			}
		x++, q += 4
		}
	if (s >= 0)
		{
		LineList.Push((s + p) // 2)
		}

	bestGap := 999
	fi := -1
	i := 1
	while (i < LineList.Length())
		{
		gap := LineList[i+1] - LineList[i]
		if (gap >= 4 and gap <= 20 and gap < bestGap)
			bestGap := gap, fi := i
		i++
		}
	pinCol := false
	if (SpecialRod = "Pinions Aria" and PinMarkerX(fcx))
		{
		pinCol := true
		ci := 1
		while (ci < LineList.Length())
			{
			cg := LineList[ci+1] - LineList[ci]
			if (cg >= 3 and cg <= 20 and Abs(((LineList[ci] + LineList[ci+1]) / 2) - fcx) <= 8)
				{
				fcx := (LineList[ci] + LineList[ci+1]) / 2
				break
				}
			ci++
			}
		}
	else if (fi < 0)
		{
		LineBarAge := LineBarAge + 1
		return false
		}
	else
		fcx := (LineList[fi] + LineList[fi+1]) / 2
	LineFishX := FishBarLeft + fcx
	LineFishSeen := true

	others := []
	i := 1
	while (i <= LineList.Length())
		{
		if (pinCol ? (Abs(LineList[i] - fcx) > 8 and LineList[i] >= 3 and LineList[i] <= CaptureW - 4) : (i != fi and i != fi + 1))
			others.Push(LineList[i])
		i++
		}

	if (others.Length() >= 2)
		{
		expW := (LineBarW >= 40) ? LineBarW : 0
		lo := -1
		hi := -1
		if (pinCol)
			{
			oLft := others[1]
			oRgt := others[others.Length()]
			if (oRgt - oLft >= 40 and oRgt - oLft <= CaptureW * 0.75)
				{
				lo := oLft
				hi := oRgt
				if (expW > 0 and Abs((oRgt - oLft + 1) - expW) > expW * 0.25)
					{
					pi := 1
					while (pi < others.Length())
						{
						pj := pi + 1
						while (pj <= others.Length())
							{
							if (Abs((others[pj] - others[pi] + 1) - expW) <= 6)
								{
								lo := others[pi]
								hi := others[pj]
								pi := others.Length()
								break
								}
							pj++
							}
						pi++
						}
					}
				}
			}
		vgSkip := false
		if (SpecialRod = "Verdant Oath")
			{
			vgSkip := true
			vgo1 := Round(CaptureW * 0.005)
			vgo2 := Round(CaptureW * 0.018)
			vgR := []
			vgL := []
			vgi := 1
			while (vgi <= LineList.Length())
				{
				vgR[vgi] := LineGreenAt(LineList[vgi] + vgo1, LineList[vgi] + vgo2)
				vgL[vgi] := LineGreenAt(LineList[vgi] - vgo1, LineList[vgi] - vgo2)
				vgi++
				}
			vgi := 1
			while (vgi < LineList.Length())
				{
				if (vgR[vgi] and vgi != fi and vgi != fi + 1)
					{
					vgj := vgi + 1
					while (vgj <= LineList.Length())
						{
						if (vgL[vgj] and vgj != fi and vgj != fi + 1 and LineList[vgj] - LineList[vgi] >= 40 and (lo < 0 or LineList[vgj] - LineList[vgi] > hi - lo))
							{
							lo := LineList[vgi]
							hi := LineList[vgj]
							}
						vgj++
						}
					}
				vgi++
				}
			if (lo < 0 and expW > 0)
				{
				vgi := 1
				while (vgi <= LineList.Length())
					{
					vge := LineList[vgi]
					if (vgi != fi and vgi != fi + 1 and vgR[vgi] and LineBrownAt(vge - vgo1))
						{
						lo := vge
						hi := vge + expW - 1
						if (hi > CaptureW - 1)
							hi := CaptureW - 1
						break
						}
					if (vgi != fi and vgi != fi + 1 and vgL[vgi] and LineBrownAt(vge + vgo1))
						{
						hi := vge
						lo := vge - expW + 1
						if (lo < 0)
							lo := 0
						break
						}
					vgi++
					}
				}
			}
		bestScore := 999999
		oi := vgSkip ? others.Length() : 1
		while (lo < 0 and oi < others.Length())
			{
			oj := oi + 1
			while (oj <= others.Length())
				{
				sep := others[oj] - others[oi]
				if (sep >= 40)
					{
					score := (expW > 0) ? Abs(sep - expW) : Abs(sep - 200)
					if (score < bestScore)
						{
						bestScore := score
						lo := others[oi]
						hi := others[oj]
						}
					}
				oj++
				}
			oi++
			}
		if (lo >= 0)
			{
			LineBarL := FishBarLeft + lo
			LineBarW := hi - lo + 1
			LineBarAge := 0
			}
		else
			LineBarAge := LineBarAge + 1
		}
	else if (others.Length() = 1)
		{
		e := others[1]
		lsSide := ""
		ext := (LineBarW >= 40) ? LineBarW : 200
		if (LineBarW >= 40)
			{
			lsHL := e - LineBarW + 1
			lsHR := e + LineBarW - 1
			lsOkL := (lsHL >= -12)
			lsOkR := (lsHR <= CaptureW + 11)
			if (lsOkL and lsOkR)
				{
				if (LineBarAge <= 3)
					{
					lsPrevL := LineBarL - FishBarLeft
					lsSide := (Abs(lsHL - lsPrevL) <= Abs(e - lsPrevL)) ? "L" : "R"
					}
				else if (Abs(lsHL - fcx) <= 14 or lsHL <= 2)
					lsSide := "L"
				else if (Abs(lsHR - fcx) <= 14 or lsHR >= CaptureW - 3)
					lsSide := "R"
				}
			else if (lsOkL)
				lsSide := "L"
			else if (lsOkR)
				lsSide := "R"
			}
		if (lsSide = "")
			{
			spL := ColSpread(e - 120, e - 6, fcx)
			spR := ColSpread(e + 6, e + 120, fcx)
			if (spL > spR and spL > 0)
				lsSide := "L"
			else if (spR > 0)
				lsSide := "R"
			}
		if (lsSide = "L")
			{
			bl := e - ext + 1
			if (bl < 0)
				bl := 0
			LineBarL := FishBarLeft + bl
			LineBarW := e - bl + 1
			LineBarAge := 0
			}
		else if (lsSide = "R")
			{
			br := e + ext - 1
			if (br > CaptureW - 1)
				br := CaptureW - 1
			LineBarL := FishBarLeft + e
			LineBarW := br - e + 1
			LineBarAge := 0
			}
		else
			LineBarAge := LineBarAge + 1
		}
	else
		LineBarAge := LineBarAge + 1

	if (LineBarW < 1 or LineBarAge > 12)
		return false

	LineFound := true
	return true
}

LineColAvg(x, ByRef cr, ByRef cg, ByRef cb) {
	global pCaptureBits, CaptureW, CaptureH
	cr := 0
	cg := 0
	cb := 0
	if (x < 0 or x >= CaptureW)
		return false
	n := 0
	y := 0
	while (y < CaptureH)
		{
		px := NumGet(pCaptureBits + (y * CaptureW + x) * 4, 0, "UInt")
		cb += px & 0xFF
		cg += (px >> 8) & 0xFF
		cr += (px >> 16) & 0xFF
		n++
		y += 12
		}
	if (!n)
		return false
	cr /= n
	cg /= n
	cb /= n
	return true
}

LineGreenAt(x1, x2) {
	if (LineColAvg(x1, cr, cg, cb) and cg - ((cr > cb) ? cr : cb) > 30)
		return true
	if (LineColAvg(x2, cr, cg, cb) and cg - ((cr > cb) ? cr : cb) > 30)
		return true
	return false
}

LineBrownAt(x) {
	return (LineColAvg(x, cr, cg, cb) and cr > cg + 10 and cr > cb + 20)
}

VerdantBarScan() {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft, VgBarL, VgBarW, VgPrm, VgPrmReady
	if (!pCaptureBits or CaptureW < 40 or CaptureH < 6)
		return false
	if (!VgPrmReady)
		{
		PcSetPrm(VgPrm, "0x3B8113", 0, 1, 0)
		VgPrmReady := true
		}
	vgLs := []
	vgRs := []
	for vgI, vgY in [Floor(CaptureH * 0.30), Floor(CaptureH * 0.50), Floor(CaptureH * 0.70)]
		{
		vgP := pCaptureBits + vgY * CaptureW * 4
		vgA := PcFind(vgP, CaptureW, 4, VgPrm)
		if (vgA < 0)
			continue
		vgB := PcFind(vgP + (CaptureW - 1) * 4, CaptureW, -4, VgPrm)
		if (vgB < 0)
			continue
		vgB := CaptureW - 1 - vgB
		if (vgB - vgA + 1 >= CaptureW * 0.04 and vgB - vgA + 1 <= CaptureW * 0.85)
			{
			vgLs.Push(vgA)
			vgRs.Push(vgB)
			}
		}
	if (vgLs.Length() < 2)
		return false
	vgA := (vgLs.Length() = 3) ? RfMedian(vgLs) : ((vgLs[1] > vgLs[2]) ? vgLs[1] : vgLs[2])
	vgB := (vgRs.Length() = 3) ? RfMedian(vgRs) : ((vgRs[1] < vgRs[2]) ? vgRs[1] : vgRs[2])
	if (vgB - vgA + 1 < CaptureW * 0.04)
		return false
	vgO := Round(CaptureW * 0.005) + 1
	if (!LineBrownAt(vgA - vgO) and !LineBrownAt(vgB + vgO))
		return false
	VgBarL := FishBarLeft + vgA
	VgBarW := vgB - vgA + 1
	return true
}

VerdantFishX() {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft, FishColor, FishBarColorTolerance, LastFishX
	global VgPrmF, VgPrmFI
	if (!pCaptureBits or CaptureW < 40 or CaptureH < 6)
		return -1
	vfL := RfColList(FishColor)
	if (vfL.n < 1)
		return -1
	vfMaxW := Round(CaptureW * 0.04)
	for vfI, vfY in [Floor(CaptureH * 0.50), Floor(CaptureH * 0.30), Floor(CaptureH * 0.70)]
		{
		vfP := pCaptureBits + vfY * CaptureW * 4
		vfBest := -1
		vfBestD := 999999
		Loop, % vfL.n
			{
			vfK := A_Index
			vfHex := Format("0x{:02X}{:02X}{:02X}", vfL.r[vfK], vfL.g[vfK], vfL.b[vfK])
			PcSetPrm(VgPrmF, vfHex, FishBarColorTolerance, 0, 0)
			PcSetPrm(VgPrmFI, vfHex, FishBarColorTolerance, 0, 1)
			vfN := 0
			vfX := 0
			while (vfX < CaptureW and vfN < 24)
				{
				vfS := PcFind(vfP + vfX * 4, CaptureW - vfX, 4, VgPrmF)
				if (vfS < 0)
					break
				vfS += vfX
				vfE := PcFind(vfP + (vfS + 1) * 4, CaptureW - vfS - 1, 4, VgPrmFI)
				vfE := (vfE < 0) ? CaptureW - 1 : vfS + vfE
				vfN++
				if (vfE - vfS + 1 >= 3 and vfE - vfS + 1 <= vfMaxW)
					{
					vfC := (vfS + vfE) / 2
					vfD := (LastFishX >= 0) ? Abs(FishBarLeft + vfC - LastFishX) : 0
					if (vfD < vfBestD)
						{
						vfBestD := vfD
						vfBest := vfC
						}
					}
				vfX := vfE + 1
				}
			}
		if (vfBest >= 0)
			{
			LastFishX := FishBarLeft + vfBest
			return LastFishX
			}
		}
	return -1
}

PinMarkerX(ByRef cx) {
	global pCaptureBits, CaptureW, CaptureH, CapExtra, WindowHeight
	global PnPrmM, PnPrmMI, PnPrmC, PnPrmCI, PnPrmReady
	cx := -1
	if (!pCaptureBits or CaptureW < 40)
		return false
	if (!PnPrmReady)
		{
		PcSetPrm(PnPrmM, "0xC580FC", 36, 0, 0)
		PcSetPrm(PnPrmMI, "0xC580FC", 36, 0, 1)
		PcSetPrm(PnPrmC, "0x5AF7F9", 45, 0, 0)
		PcSetPrm(PnPrmCI, "0x5AF7F9", 45, 0, 1)
		PnPrmReady := true
		}
	PinRowsM := [Round(WindowHeight * 0.030), Round(WindowHeight * 0.034), Round(WindowHeight * 0.026), Round(WindowHeight * 0.038), Round(WindowHeight * 0.042)]
	PinRowsC := [0 - Round(WindowHeight * 0.009), 0 - Round(WindowHeight * 0.006), 0 - Round(WindowHeight * 0.012)]
	for i, rr in [PinRowsM[1], PinRowsM[2], PinRowsM[3], PinRowsM[4], PinRowsM[5], PinRowsC[1], PinRowsC[2], PinRowsC[3]]
		{
		if (rr >= CaptureH + 20 + CapExtra or rr < -17)
			continue
		p := pCaptureBits + (rr * CaptureW * 4)
		if (i <= 5)
			{
			i0 := PcFind(p, CaptureW, 4, PnPrmM)
			if (i0 < 0)
				continue
			i1 := PcFind(p + (i0 + 1) * 4, CaptureW - i0 - 1, 4, PnPrmMI)
			}
		else
			{
			i0 := PcFind(p, CaptureW, 4, PnPrmC)
			if (i0 < 0)
				continue
			i1 := PcFind(p + (i0 + 1) * 4, CaptureW - i0 - 1, 4, PnPrmCI)
			}
		w := (i1 < 0) ? (CaptureW - i0) : (i1 + 1)
		if (w < 2 or w > 30)
			continue
		cx := i0 + (w / 2)
		return true
		}
	return false
}

LineHitsAhk(pBits, w, h, pHits) {
	rowBytes := w * 4
	rows := 0
	y := 0
	while (y < h)
		{
		p := pBits + (y * rowBytes)
		pe := p + rowBytes
		px := NumGet(p + 0, 0, "UInt")
		prev := (px & 0xFF) + ((px >> 8) & 0xFF) + ((px >> 16) & 0xFF)
		p += 4, q := pHits + 4
		while (p < pe)
			px := NumGet(p + 0, 0, "UInt"), cur := (px & 0xFF) + ((px >> 8) & 0xFF) + ((px >> 16) & 0xFF), (cur - prev > 54 or prev - cur > 54) ? NumPut(NumGet(q + 0, 0, "UInt") + 1, q + 0, 0, "UInt") : 0, prev := cur, p += 4, q += 4
		rows++
		y += 3
		}
	return rows
}

LineHitsFn() {
	static pFn := "", Hex := "53565755415431C04531D24189D349C1E3024539C20F8D5B000000498BF2490FAFF34801CE0FB61E0FB67E0101FB0FB67E0201FBBF0100000039D77D310FB62CBE440FB664BE014401E5440FB664BE024401E54189EC4129DC790341F7DC4183FC367E0441FF04B989EBFFC7EBCBFFC04183C203EB9C415C5D5F5E5BC3"
	if (pFn != "")
		return pFn
	pFn := 0
	if (A_PtrSize != 8)
		return 0
	n := StrLen(Hex) // 2
	p := DllCall("VirtualAlloc", "Ptr", 0, "Ptr", n, "UInt", 0x3000, "UInt", 0x04, "Ptr")
	if (!p)
		return 0
	Loop, %n%
		NumPut("0x" . SubStr(Hex, 2 * A_Index - 1, 2), p + 0, A_Index - 1, "UChar")
	if (!DllCall("VirtualProtect", "Ptr", p, "Ptr", n, "UInt", 0x20, "UIntP", oldProt))
		{
		DllCall("VirtualFree", "Ptr", p, "Ptr", 0, "UInt", 0x8000)
		return 0
		}
	tw := 157, th := 23
	VarSetCapacity(tBits, tw * th * 4, 0)
	seed := 12345
	Loop, % tw * th
		{
		seed := Mod(seed * 1103515245 + 12345, 2147483648)
		v := (seed >> 8) & 0xFFFFFFFF
		if (Mod(A_Index, 7) < 3)
			v := v & 0x3F3F3F3F
		NumPut(v, tBits, (A_Index - 1) * 4, "UInt")
		}
	VarSetCapacity(hA, tw * 4, 0)
	VarSetCapacity(hB, tw * 4, 0)
	rA := LineHitsAhk(&tBits, tw, th, &hA)
	rB := DllCall(p, "Ptr", &tBits, "Int", tw, "Int", th, "Ptr", &hB, "Int")
	same := (rA = rB)
	anyHit := false
	Loop, %tw%
		{
		a := NumGet(hA, (A_Index - 1) * 4, "UInt")
		if (a != NumGet(hB, (A_Index - 1) * 4, "UInt"))
			same := false
		if (a)
			anyHit := true
		}
	if (!same or !anyHit)
		{
		DllCall("VirtualFree", "Ptr", p, "Ptr", 0, "UInt", 0x8000)
		return 0
		}
	pFn := p
	return pFn
}

PinionScan() {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft, BarScanRow
	global FishColor, FishBarColorTolerance, NoteColor, NoteColorTolerance
	global PinFishX, PinNoteX, PinFound
	PinFishX := -1
	PinNoteX := -1
	PinFound := false
	row := BarScanRow
	if (row < 0 or row >= CaptureH)
		row := CaptureH // 2
	rowOff := row * CaptureW * 4

	fb := RfBgr(RfColFirst(FishColor))
	fB := (fb >> 16) & 0xFF
	fG := (fb >> 8) & 0xFF
	fR := fb & 0xFF
	ftol := FishBarColorTolerance
	if (ftol < 4)
		ftol := 4

	nb := RfBgr(NoteColor)
	nB := (nb >> 16) & 0xFF
	nG := (nb >> 8) & 0xFF
	nR := nb & 0xFF
	ntol := NoteColorTolerance
	if (ntol < 4)
		ntol := 4

	bestW := 0
	fRunS := -1
	fRunE := -1
	nRunS := -1
	nRunE := -1
	x := 0
	while (x <= CaptureW)
		{
		isF := false
		isN := false
		if (x < CaptureW)
			{
			px := NumGet(pCaptureBits + 0, rowOff + (x*4), "UInt")
			b := px & 0xFF
			g := (px >> 8) & 0xFF
			r := (px >> 16) & 0xFF
			isF := (Abs(b - fB) <= ftol and Abs(g - fG) <= ftol and Abs(r - fR) <= ftol)
			isN := (Abs(b - nB) <= ntol and Abs(g - nG) <= ntol and Abs(r - nR) <= ntol)
			}
		if (isF)
			{
			if (fRunS < 0)
				fRunS := x
			fRunE := x
			}
		else if (fRunS >= 0)
			{
			w := fRunE - fRunS + 1
			if (w >= 3 and w <= 25 and w > bestW)
				{
				bestW := w
				PinFishX := FishBarLeft + ((fRunS + fRunE) / 2)
				}
			fRunS := -1
			}
		if (isN)
			{
			if (nRunS < 0)
				nRunS := x
			nRunE := x
			}
		else if (nRunS >= 0)
			{
			w := nRunE - nRunS + 1
			if (w >= 2 and w <= 10 and PinNoteX < 0)
				PinNoteX := FishBarLeft + ((nRunS + nRunE) / 2)
			nRunS := -1
			}
		x++
		}
	PinFound := (PinFishX >= 0)
	return PinFound
}


; --- Noiseform zone gimmick -------------------------------------------------------------------

NoiseIsCore(pv, cB, cG, cR, ctol) {
	vb := pv & 0xFF
	vg := (pv >> 8) & 0xFF
	vr := (pv >> 16) & 0xFF
	if (Abs(vb - cB) <= ctol and Abs(vg - cG) <= ctol and Abs(vr - cR) <= ctol)
		return true
	if (vg < 34 or vg > 104)
		return false
	if (vr > 52 or vb > 76)
		return false
	if (vg < vr + 10 or vg < vb + 4)
		return false
	vl := (vr + vg + vb) // 3
	if (vl < 14 or vl > 74)
		return false
	return true
}

NfNow() {
	global NfFakeT, QpcFreq
	if (NfFakeT)
		return NfFakeT
	DllCall("QueryPerformanceCounter", "Int64*", t)
	return t
}

NfLoadBlob(hex) {
	if (A_PtrSize != 8)
		return 0
	n := StrLen(hex) // 2
	p := DllCall("VirtualAlloc", "Ptr", 0, "Ptr", n, "UInt", 0x3000, "UInt", 0x04, "Ptr")
	if (!p)
		return 0
	Loop, %n%
		NumPut("0x" . SubStr(hex, 2 * A_Index - 1, 2), p + 0, A_Index - 1, "UChar")
	if (!DllCall("VirtualProtect", "Ptr", p, "Ptr", n, "UInt", 0x20, "UIntP", oldProt))
		{
		DllCall("VirtualFree", "Ptr", p, "Ptr", 0, "UInt", 0x8000)
		return 0
		}
	return p
}

NfNativeInit() {
	global NfNativeReady, pNfDiffRow, pNfIconHist
	static NfDiffHex := "5356575541544155415641574889CE4889D7418B5904498B691031C04531DB41BCFFFFFFFF41BDFFFFFFFF4439C00F8DAE000000440FB636440FB63F4529FE4585F6790341F7DE4589F2440FB67601440FB67F014529FE4585F6790341F7DE4501F2440FB67602440FB67F024529FE4585F6790341F7DE4501F241D1E34183E30F453B117E044183CB014589DF4183E7014589DE41D1EE4183E6014501F74589DE41C1EE024183E6014501F74589DE41C1EE034183E6014501F74183FF037C154183FC007D0C4189C44183EC0379034531E44189C5FFC04801DE4801DFE949FFFFFF4183FC000F8C8C0000004489E0480FAFC34889CE4801C64889D74801C74531D24531DB31D24489E04439E80F8F48000000440FB636440FB67E010FB64E024501F34501FB4101CB4439F17D034489F14129CF4501FA440FB6374401F2440FB677014401F2440FB677024401F2FFC04801DE4801DFE9AFFFFFFF4489650044896D044489550844895D0C895510B801000000E90200000031C0415F415E415D415C5D5F5E5BC3"
	static NfIconHex := "535657554154415541564157418B19418B69044531ED4183FD030F8DE8000000498B41104589EF440FAFFA41C1E7024889C74C01FF4989FA4189D7456BFF0C4D01FA4531F6453B710C0F8DB10000004489E8410FAF410C4401F0410341080FAFC2C1E0024889CE4801C64531DB41BCFFFFFFFF4139D30F8D5B0000000FB60639D87C200FB6460139D87C180FB6460239D87C104283049F014183FC007D2D4589DCEB284183FC007C224489D84429E039E87C124589E74539DF7D0A438304BA0141FFC7EBF141BCFFFFFFFF41FFC34883C604E99CFFFFFF4183FC007C1B89D04429E039E87C124589E74139D77D0A438304BA0141FFC7EBF141FFC6E945FFFFFF41FFC5E90EFFFFFF415F415E415D415C5D5F5E5BC3"
	if (NfNativeReady)
		return
	NfNativeReady := true
	pNfDiffRow := 0
	pNfIconHist := 0
	p1 := NfLoadBlob(NfDiffHex)
	p2 := NfLoadBlob(NfIconHex)
	VarSetCapacity(prm, 24, 0)
	VarSetCapacity(c1, 40 * 8, 0)
	VarSetCapacity(r1, 40 * 8, 0)
	Loop, 40
		{
		v := Mod(A_Index * 7, 200)
		o := (A_Index - 1) * 8
		NumPut(v, c1, o, "UChar"), NumPut(v + 3, c1, o + 1, "UChar"), NumPut(v + 1, c1, o + 2, "UChar")
		NumPut(v, r1, o, "UChar"), NumPut(v + 3, r1, o + 1, "UChar"), NumPut(v + 1, r1, o + 2, "UChar")
		if (A_Index >= 11 and A_Index <= 20)
			NumPut(v + 90, r1, o, "UChar")
		}
	VarSetCapacity(o1, 24, 0)
	VarSetCapacity(o2, 24, 0)
	NumPut(36, prm, 0, "Int"), NumPut(8, prm, 4, "Int")
	NumPut(&o1, prm, 16, "Int64")
	rvN := p1 ? DllCall(p1, "Ptr", &c1, "Ptr", &r1, "Int", 40, "Ptr", &prm, "Int") : -9
	NumPut(&o2, prm, 16, "Int64")
	rvA := NfDiffRowAhk(&c1, &r1, 40, &prm)
	ok1 := (p1 != 0 and rvN = rvA and rvA = 1)
	Loop, 5
		if (NumGet(o1, (A_Index - 1) * 4, "Int") != NumGet(o2, (A_Index - 1) * 4, "Int"))
			ok1 := false
	if (ok1)
		pNfDiffRow := p1
	w := 30
	h := 12
	VarSetCapacity(img, w * h * 4, 0)
	Loop, % w * h
		{
		x := Mod(A_Index - 1, w)
		y := (A_Index - 1) // w
		v := ((x >= 8 and x <= 18 and y >= 3 and y <= 9) or (x = 24 and y >= 2)) ? 230 : 40
		o := (A_Index - 1) * 4
		NumPut(v, img, o, "UChar"), NumPut(v, img, o + 1, "UChar"), NumPut(v, img, o + 2, "UChar")
		}
	VarSetCapacity(h1, w * 6 * 4, 0)
	VarSetCapacity(h2, w * 6 * 4, 0)
	NumPut(200, prm, 0, "Int"), NumPut(5, prm, 4, "Int"), NumPut(3, prm, 8, "Int"), NumPut(3, prm, 12, "Int")
	NumPut(&h1, prm, 16, "Int64")
	if (p2)
		DllCall(p2, "Ptr", &img, "Int", w, "Int", h, "Ptr", &prm)
	NumPut(&h2, prm, 16, "Int64")
	NfIconHistAhk(&img, w, h, &prm)
	ok2 := (p2 != 0 and NumGet(h2, 12 * 4, "Int") = 3 and NumGet(h2, (3 * w + 12) * 4, "Int") = 3 and NumGet(h2, (3 * w + 24) * 4, "Int") = 0)
	Loop, % w * 6
		if (NumGet(h1, (A_Index - 1) * 4, "Int") != NumGet(h2, (A_Index - 1) * 4, "Int"))
			ok2 := false
	if (ok2)
		pNfIconHist := p2
}

NfDiffRowAhk(pCur, pRef, n, pPrm) {
	T := NumGet(pPrm + 0, 0, "Int")
	step := NumGet(pPrm + 0, 4, "Int")
	pOut := NumGet(pPrm + 0, 16, "Int64")
	sr := 0
	first := -1
	last := -1
	i := 0
	while (i < n)
		{
		o := i * step
		d := Abs(NumGet(pCur + 0, o, "UChar") - NumGet(pRef + 0, o, "UChar")) + Abs(NumGet(pCur + 0, o + 1, "UChar") - NumGet(pRef + 0, o + 1, "UChar")) + Abs(NumGet(pCur + 0, o + 2, "UChar") - NumGet(pRef + 0, o + 2, "UChar"))
		sr := ((sr << 1) & 0xF) | ((d > T) ? 1 : 0)
		if (((sr & 1) + ((sr >> 1) & 1) + ((sr >> 2) & 1) + ((sr >> 3) & 1)) >= 3)
			{
			if (first < 0)
				first := (i >= 3) ? (i - 3) : 0
			last := i
			}
		i++
		}
	if (first < 0)
		return 0
	tint := 0
	sl := 0
	slr := 0
	j := first
	while (j <= last)
		{
		o := j * step
		cb := NumGet(pCur + 0, o, "UChar"), cg := NumGet(pCur + 0, o + 1, "UChar"), cr := NumGet(pCur + 0, o + 2, "UChar")
		tint += cg - ((cb > cr) ? cb : cr)
		sl += cb + cg + cr
		slr += NumGet(pRef + 0, o, "UChar") + NumGet(pRef + 0, o + 1, "UChar") + NumGet(pRef + 0, o + 2, "UChar")
		j++
		}
	NumPut(first, pOut + 0, 0, "Int"), NumPut(last, pOut + 0, 4, "Int"), NumPut(tint, pOut + 0, 8, "Int"), NumPut(sl, pOut + 0, 12, "Int"), NumPut(slr, pOut + 0, 16, "Int")
	return 1
}

NfIconHistAhk(pBits, w, h, pPrm) {
	thr := NumGet(pPrm + 0, 0, "Int")
	minrun := NumGet(pPrm + 0, 4, "Int")
	y0 := NumGet(pPrm + 0, 8, "Int")
	rpb := NumGet(pPrm + 0, 12, "Int")
	pOut := NumGet(pPrm + 0, 16, "Int64")
	band := 0
	while (band < 3)
		{
		pRaw := pOut + band * w * 4
		pSol := pOut + (3 + band) * w * 4
		r := 0
		while (r < rpb)
			{
			y := y0 + band * rpb + r
			q := pBits + y * w * 4
			runS := -1
			x := 0
			while (x < w)
				{
				o := x * 4
				wh := (NumGet(q + 0, o, "UChar") >= thr and NumGet(q + 0, o + 1, "UChar") >= thr and NumGet(q + 0, o + 2, "UChar") >= thr)
				if (wh)
					{
					NumPut(NumGet(pRaw + 0, o, "Int") + 1, pRaw + 0, o, "Int")
					if (runS < 0)
						runS := x
					}
				else if (runS >= 0)
					{
					if (x - runS >= minrun)
						{
						k := runS
						while (k < x)
							{
							NumPut(NumGet(pSol + 0, k * 4, "Int") + 1, pSol + 0, k * 4, "Int")
							k++
							}
						}
					runS := -1
					}
				x++
				}
			if (runS >= 0 and w - runS >= minrun)
				{
				k := runS
				while (k < w)
					{
					NumPut(NumGet(pSol + 0, k * 4, "Int") + 1, pSol + 0, k * 4, "Int")
					k++
					}
				}
			r++
			}
		band++
		}
}

NoiseWarnKind() {
	global pNoteBits, NoteW, NoteH, FishBarLeft, NoteTop, WindowWidth, WindowHeight, QpcFreq
	global NoiseWNow, NfRing, NfRingT, NfRingN, NfRingIdx, NfRowBytes, NfN, NfKS
	global NfNativeReady, NfLatchKind, NfLatchT, NfWhy
	NoiseWNow := ""
	if (!pNoteBits or NoteH < 80 or NoteW < 100)
		return ""
	if (!NfNativeReady)
		NfNativeInit()
	if (!IsObject(NfKS))
		NfKS := [-0.9, -0.8, -0.6, -0.4, -0.2, 0.0, 0.2, 0.4, 0.6, 0.8, 0.9]
	cx := (WindowWidth * 0.5) - FishBarLeft
	cy := (WindowHeight * 0.52) - NoteTop
	R := WindowHeight * 0.139
	x0 := Round(cx - 1.7 * R)
	x1 := Round(cx + 1.7 * R)
	if (x0 < 0)
		x0 := 0
	if (x1 > NoteW - 1)
		x1 := NoteW - 1
	n := (x1 - x0) // 2
	if (n < 60)
		return ""
	rowBytes := n * 8
	if (NfRowBytes != rowBytes or !IsObject(NfRingT))
		{
		NfRowBytes := rowBytes
		VarSetCapacity(NfRing, 32 * 11 * rowBytes, 0)
		NfRingT := []
		NfRingN := 0
		NfRingIdx := 0
		NfLatchKind := ""
		NfLatchT := 0
		}
	now := NfNow()
	slot := NfRingIdx
	if (NfRingN > 0)
		{
		prevSlot := Mod(slot + 31, 32)
		if (((now - NfRingT[prevSlot]) / QpcFreq) < 0.040)
			slot := prevSlot
		}
	i := 0
	while (i < 11)
		{
		y := Round(cy + R * NfKS[i + 1])
		if (y < 0)
			y := 0
		if (y > NoteH - 1)
			y := NoteH - 1
		DllCall("RtlMoveMemory", "Ptr", &NfRing + ((slot * 11 + i) * rowBytes), "Ptr", pNoteBits + ((y * NoteW + x0) * 4), "Ptr", rowBytes)
		i++
		}
	if (slot = NfRingIdx)
		{
		NfRingT[slot] := now
		NfRingIdx := Mod(slot + 1, 32)
		if (NfRingN < 32)
			NfRingN := NfRingN + 1
		}
	kind := NfSingle(strong, weak)
	if (kind != "")
		NfWhy := "single " . kind
	for ri, lo in [0.12, 0.80]
		{
		if (kind != "")
			break
		ref := -1
		s := 0
		while (s < NfRingN)
			{
			if (s != slot)
				{
				age := (now - NfRingT[s]) / QpcFreq
				if (age >= lo and age <= lo + 0.45 and (ref < 0 or NfRingT[s] > NfRingT[ref]))
					ref := s
				}
			s++
			}
		if (ref < 0)
			continue
		kind := NfClassify(slot, ref, n, R, cx - x0, strong)
		if (kind != "")
			break
		}
	if (kind = "")
		return ""
	if (weak)
		{
		if (NfLatchKind != kind or ((now - NfLatchT) / QpcFreq) > 0.4)
			return ""
		NfLatchT := now
		NoiseWNow := kind
		return kind
		}
	latched := strong or (NfLatchKind = kind and ((now - NfLatchT) / QpcFreq) <= 0.4)
	NfLatchKind := kind
	NfLatchT := now
	if (!latched)
		return ""
	NoiseWNow := kind
	return kind
}

NfClassify(slot, ref, n, R, cxs, ByRef strong) {
	global NfRing, NfRowBytes, NfKS, pNfDiffRow, NfPrm, NfOut, NfWhy, NfPrmBuf, NfOutBuf
	strong := false
	if (!NfPrm)
		{
		VarSetCapacity(NfPrmBuf, 24, 0)
		VarSetCapacity(NfOutBuf, 24, 0)
		NfPrm := &NfPrmBuf
		NfOut := &NfOutBuf
		}
	NumPut(36, NfPrm + 0, 0, "Int"), NumPut(8, NfPrm + 0, 4, "Int"), NumPut(NfOut, NfPrm + 0, 16, "Int64")
	w := []
	fl := []
	fr := []
	gchg := 0
	tint := 0
	sl := 0
	slr := 0
	cnt := 0
	mA := Round((cxs - 1.2 * R) / 2)
	mB := Round((cxs + 1.2 * R) / 2)
	lA := 0
	lB := Round((cxs - 1.25 * R) / 2)
	rA := Round((cxs + 1.25 * R) / 2)
	rB := n - 1
	if (mA < 0)
		mA := 0
	if (mB > n - 1)
		mB := n - 1
	if (lB < 4 or rB - rA < 4 or mB - mA < 20)
		return ""
	k := 0
	while (k < 11)
		{
		pc := &NfRing + ((slot * 11 + k) * NfRowBytes)
		pr := &NfRing + ((ref * 11 + k) * NfRowBytes)
		for mi, mo in [lA, rA]
			{
			mn := (mo = lA) ? (lB - lA + 1) : (rB - rA + 1)
			if (pNfDiffRow)
				rv := DllCall(pNfDiffRow, "Ptr", pc + mo * 8, "Ptr", pr + mo * 8, "Int", mn, "Ptr", NfPrm, "Int")
			else
				rv := NfDiffRowAhk(pc + mo * 8, pr + mo * 8, mn, NfPrm)
			if (rv and NumGet(NfOut + 0, 4, "Int") - NumGet(NfOut + 0, 0, "Int") >= 4)
				{
				gchg := gchg + 1
				break
				}
			}
		if (pNfDiffRow)
			rv := DllCall(pNfDiffRow, "Ptr", pc + mA * 8, "Ptr", pr + mA * 8, "Int", mB - mA + 1, "Ptr", NfPrm, "Int")
		else
			rv := NfDiffRowAhk(pc + mA * 8, pr + mA * 8, mB - mA + 1, NfPrm)
		if (rv)
			{
			a := mA + NumGet(NfOut + 0, 0, "Int")
			b := mA + NumGet(NfOut + 0, 4, "Int")
			w[k + 1] := (b - a) * 2 / R
			fl[k + 1] := a
			fr[k + 1] := b
			tint += NumGet(NfOut + 0, 8, "Int")
			sl += NumGet(NfOut + 0, 12, "Int")
			slr += NumGet(NfOut + 0, 16, "Int")
			cnt += b - a + 1
			}
		else
			{
			w[k + 1] := 0
			fl[k + 1] := -1
			fr[k + 1] := -1
			}
		k++
		}
	if (cnt < 1)
		return ""
	if (gchg >= 5)
		{
		if ((sl - slr) / (cnt * 3) > -6)
			return ""
		tok := 0
		bok := 0
		Loop, 3
			{
			if (w[A_Index] <= 1.5)
				tok += 1
			if (w[A_Index + 8] >= 1.9 and w[A_Index + 8] <= 2.3)
				bok += 1
			}
		if (tok < 2 or bok < 2)
			return ""
		}
	shape := NfShape(w)
	gm := tint / cnt
	dl := (sl - slr) / (cnt * 3)
	if (shape = "" and gm >= 40)
		{
		gok := 0
		for i, v in [w[4], w[5], w[6], w[7], w[8]]
			if (v >= 1.5 and v <= 2.4)
				gok := gok + 1
		if (gok >= 3)
			shape := "CIR"
		}
	if (shape = "")
		return ""
	kind := ""
	if (shape = "CIR" and gm >= 25)
		{
		kind := "GREEN"
		strong := (gm >= 45)
		}
	else if (shape = "SQ" and dl >= 10)
		{
		kind := "WHITE"
		strong := (dl >= 20)
		}
	else if (shape = "TRI" and dl <= -6)
		{
		kind := "BLACK"
		strong := (dl <= -15)
		}
	if (kind = "")
		return ""
	if (gchg >= 5)
		{
		if (kind != "BLACK")
			{
			strong := false
			return ""
			}
		gext := 0
		k := 0
		while (k < 11)
			{
			pc := &NfRing + ((slot * 11 + k) * NfRowBytes)
			pr := &NfRing + ((ref * 11 + k) * NfRowBytes)
			for mi, mo in [lA, rA]
				{
				mn := (mo = lA) ? (lB - lA + 1) : (rB - rA + 1)
				if (pNfDiffRow)
					rv := DllCall(pNfDiffRow, "Ptr", pc + mo * 8, "Ptr", pr + mo * 8, "Int", mn, "Ptr", NfPrm, "Int")
				else
					rv := NfDiffRowAhk(pc + mo * 8, pr + mo * 8, mn, NfPrm)
				if (rv and (NumGet(NfOut + 0, 4, "Int") - NumGet(NfOut + 0, 0, "Int") + 1) * 2 >= mn)
					{
					gext := gext + 1
					break
					}
				}
			k++
			}
		if (gext >= 5)
			{
			strong := false
			return ""
			}
		}
	if (kind = "BLACK")
		{
		dk := 0
		tot := 0
		for i, yv in [-0.2, 0.0, 0.2, 0.4, 0.6]
			{
			hw := 0.40 + 0.6 * yv
			pc := &NfRing + ((slot * 11 + i + 3) * NfRowBytes)
			pr := &NfRing + ((ref * 11 + i + 3) * NfRowBytes)
			for j2, sg in [-1, 1]
				{
				ja := Round((cxs + sg * 0.2 * R) / 2)
				jb := Round((cxs + sg * hw * R) / 2)
				j := (ja < jb) ? ja : jb
				je := (ja < jb) ? jb : ja
				while (j <= je)
					{
					o := j * 8
					sc := NumGet(pc + 0, o, "UChar") + NumGet(pc + 0, o + 1, "UChar") + NumGet(pc + 0, o + 2, "UChar")
					sr := NumGet(pr + 0, o, "UChar") + NumGet(pr + 0, o + 1, "UChar") + NumGet(pr + 0, o + 2, "UChar")
					tot += 1
					if (sr - sc >= 36 and sc * 5 <= sr * 4)
						dk += 1
					j += 2
					}
				}
			}
		if (tot < 1 or dk * 10 < tot * 6)
			{
			strong := false
			return ""
			}
		}
	okr := 0
	k := 0
	while (k < 11)
		{
		a := fl[k + 1]
		b := fr[k + 1]
		if (a >= 0 and b - a >= 4)
			{
			pc := &NfRing + ((slot * 11 + k) * NfRowBytes)
			firstHit := -1
			lastHit := -1
			j := a
			while (j <= b)
				{
				o := j * 8
				pb := NumGet(pc + 0, o, "UChar"), pg := NumGet(pc + 0, o + 1, "UChar"), prr := NumGet(pc + 0, o + 2, "UChar")
				mx := (pb > pg) ? pb : pg
				if (prr > mx)
					mx := prr
				mn := (pb < pg) ? pb : pg
				if (prr < mn)
					mn := prr
				if (kind = "BLACK")
					hit := (mx <= 95)
				else if (kind = "WHITE")
					hit := (mn >= 200 and mx - mn <= 40)
				else
					hit := (pg >= 150 and pg - ((pb > prr) ? pb : prr) >= 50)
				if (hit)
					{
					if (firstHit < 0)
						firstHit := j
					lastHit := j
					}
				j++
				}
			if (firstHit >= 0 and (firstHit - a) <= 0.35 * (b - a) and (b - lastHit) <= 0.35 * (b - a))
				okr := okr + 1
			}
		k++
		}
	if (okr < 5)
		{
		strong := false
		return ""
		}
	NfWhy := shape . " g" . Round(gm) . " dL" . Round(dl)
	return kind
}

NfShape(w) {
	global NfKS
	sq := 0
	Loop, 11
		if (w[A_Index] >= 1.9 and w[A_Index] <= 2.3)
			sq := sq + 1
	if (sq >= 9)
		return "SQ"
	cen := [w[4], w[5], w[6], w[7], w[8]]
	cok := 0
	for i, v in cen
		if (v >= 1.75 and v <= 2.3)
			cok := cok + 1
	cmed := NfMedian(cen)
	tnar := (w[1] >= 0.7 and w[1] <= 1.85 and w[2] >= 0.7 and w[2] <= 1.85 and cmed - (w[1] + w[2]) / 2 >= 0.3)
	bnar := (w[10] >= 0.7 and w[10] <= 1.85 and w[11] >= 0.7 and w[11] <= 1.85 and cmed - (w[10] + w[11]) / 2 >= 0.3)
	if (cok >= 3 and (tnar or bnar))
		return "CIR"
	tok := 0
	for i, v in [w[1], w[2], w[3]]
		if (v <= 1.5)
			tok := tok + 1
	bok := 0
	for i, v in [w[9], w[10], w[11]]
		if (v >= 1.9 and v <= 2.3)
			bok := bok + 1
	upm := NfMedian([w[4], w[5]])
	dnm := NfMedian([w[7], w[8]])
	topm := NfMedian([w[1], w[2], w[3]])
	botm := NfMedian([w[9], w[10], w[11]])
	if (tok >= 2 and bok >= 2 and dnm - upm >= 0.15 and botm - topm >= 0.6)
		return "TRI"
	return ""
}

NfMedian(arr) {
	a := []
	for i, v in arr
		a.Push(v)
	nA := a.Length()
	i := 1
	while (i < nA)
		{
		j := i + 1
		while (j <= nA)
			{
			if (a[j] < a[i])
				{
				t := a[i]
				a[i] := a[j]
				a[j] := t
				}
			j++
			}
		i++
		}
	if (Mod(nA, 2) = 1)
		return a[(nA + 1) // 2]
	return (a[nA // 2] + a[nA // 2 + 1]) / 2
}

NfSingle(ByRef strong, ByRef weak) {
	global pNoteBits, NoteW, NoteH, FishBarLeft, NoteTop, WindowWidth, WindowHeight, NfSP, NfSPR
	strong := false
	weak := false
	if (!pNoteBits or NoteH < 80 or NoteW < 100)
		return ""
	R := WindowHeight * 0.139
	cx := (WindowWidth * 0.5) - FishBarLeft
	cy := (WindowHeight * 0.52) - NoteTop
	if (!IsObject(NfSP) or NfSPR != R)
		NfBuildPts(R)
	gi := 0
	for i, p in NfSP.disc
		gi += NfIsGreen(cx + p[1], cy + p[2])
	gi := gi / NfSP.disc.Length()
	if (gi >= 0.7)
		{
		ge := 0
		for i, p in NfSP.edge
			ge += NfIsGreen(cx + p[1], cy + p[2])
		if (ge <= 1)
			{
			strong := (gi >= 0.85)
			return "GREEN"
			}
		}
	wi := 0
	li := 0
	for i, p in NfSP.sq
		{
		v := NfPx(cx + p[1], cy + p[2])
		pb := v & 0xFF, pg := (v >> 8) & 0xFF, pr := (v >> 16) & 0xFF
		l := (pb + pg + pr) / 3
		li += l
		mx := (pb > pg) ? pb : pg
		if (pr > mx)
			mx := pr
		mn := (pb < pg) ? pb : pg
		if (pr < mn)
			mn := pr
		if (l >= 130 and mx - mn <= 50)
			wi += 1
		}
	nS := NfSP.sq.Length()
	li := li / nS
	if (wi / nS >= 0.85)
		{
		lo := 0
		wo := 0
		for i, p in NfSP.sqo
			{
			v := NfPx(cx + p[1], cy + p[2])
			pb := v & 0xFF, pg := (v >> 8) & 0xFF, pr := (v >> 16) & 0xFF
			l := (pb + pg + pr) / 3
			lo += l
			mx := (pb > pg) ? pb : pg
			if (pr > mx)
				mx := pr
			mn := (pb < pg) ? pb : pg
			if (pr < mn)
				mn := pr
			if (l >= 130 and mx - mn <= 50)
				wo += 1
			}
		nO := NfSP.sqo.Length()
		lo := lo / nO
		if (li - lo >= 40 and wo / nO <= 0.5)
			{
			gc := 0
			gs := 0
			for i, yv in [-0.40, -0.30, -0.20]
				{
				gc += NfLum(cx, cy + yv * R)
				gs += NfLum(cx - 0.25 * R, cy + yv * R) + NfLum(cx + 0.25 * R, cy + yv * R)
				}
			if (gs / 6 - gc / 3 >= 12)
				strong := (li - lo >= 80)
			else
				weak := true
			return "WHITE"
			}
		}
	ki := 0
	m := 0
	for i, p in NfSP.tri
		{
		l := NfLum(cx + p[1], cy + p[2])
		m += l
		if (l <= 110)
			ki += 1
		}
	nT := NfSP.tri.Length()
	m := m / nT
	if (ki / nT >= 0.85)
		{
		tout := 0
		for i, p in NfSP.tout
			tout += NfLum(cx + p[1], cy + p[2])
		tout := tout / NfSP.tout.Length()
		sadd := (m * 0.5 > 20) ? m * 0.5 : 20
		if (sadd > 40)
			sadd := 40
		if ((tout >= 50 and m <= 0.70 * tout) or (tout >= 15 and m <= 0.5 * tout))
			{
			side := 0
			for i, p in NfSP.side
				if (NfLum(cx + p[1], cy + p[2]) >= m + sadd)
					side += 1
			corn := 0
			for i, p in NfSP.corn
				if (NfLum(cx + p[1], cy + p[2]) <= 110)
					corn += 1
			if (side >= 4 and corn >= 3)
				{
				gl := 0
				for i, p in NfSP.glyph
					if (NfLum(cx + p[1], cy + p[2]) >= m + 30)
						gl += 1
				if (gl >= 4)
					{
					strong := (m <= 0.55 * tout or (side >= 5 and m <= 0.70 * tout))
					return "BLACK"
					}
				}
			}
		}
	return ""
}

NfPx(x, y) {
	global pNoteBits, NoteW, NoteH
	xx := Round(x)
	yy := Round(y)
	if (xx < 0)
		xx := 0
	if (xx > NoteW - 1)
		xx := NoteW - 1
	if (yy < 0)
		yy := 0
	if (yy > NoteH - 1)
		yy := NoteH - 1
	return NumGet(pNoteBits + 0, ((yy * NoteW) + xx) * 4, "UInt")
}

NfLum(x, y) {
	v := NfPx(x, y)
	return ((v & 0xFF) + ((v >> 8) & 0xFF) + ((v >> 16) & 0xFF)) / 3
}

NfIsGreen(x, y) {
	v := NfPx(x, y)
	pb := v & 0xFF, pg := (v >> 8) & 0xFF, pr := (v >> 16) & 0xFF
	return (pg >= 110 and pg - pr >= 60 and pg - pb >= 15) ? 1 : 0
}

NfBuildPts(R) {
	global NfSP, NfSPR
	NfSPR := R
	NfSP := {disc: [], edge: [], sq: [], sqo: [], tri: [], side: [], corn: [], tout: [], glyph: []}
	yy := -0.8
	while (yy <= 0.81)
		{
		xx := -0.8
		while (xx <= 0.81)
			{
			if (xx * xx + yy * yy <= 0.7225 and Abs(xx) > 0.12)
				NfSP.disc.Push([xx * R, yy * R])
			xx += 0.2
			}
		yy += 0.2
		}
	a := 0
	while (a < 8)
		{
		NfSP.edge.Push([1.12 * R * Cos(a * 0.7853981634), 1.12 * R * Sin(a * 0.7853981634)])
		a++
		}
	yy := -0.75
	while (yy <= 0.76)
		{
		xx := -0.75
		while (xx <= 0.76)
			{
			if (Abs(xx) > 0.15)
				NfSP.sq.Push([xx * R, yy * R])
			xx += 0.25
			}
		yy += 0.25
		}
	v := -0.9
	while (v <= 0.91)
		{
		NfSP.sqo.Push([-1.25 * R, v * R]), NfSP.sqo.Push([1.25 * R, v * R]), NfSP.sqo.Push([v * R, -1.25 * R]), NfSP.sqo.Push([v * R, 1.25 * R])
		v += 0.3
		}
	yy := -0.5
	while (yy <= 0.81)
		{
		hw := 0.65 + 0.5 * yy
		if (hw < 0.05)
			hw := 0.05
		xx := -1.0
		while (xx <= 1.01)
			{
			if (Abs(xx) <= hw - 0.2 and Abs(xx) > 0.15)
				NfSP.tri.Push([xx * R, yy * R])
			xx += 0.2
			}
		yy += 0.2
		}
	for i, yv in [-0.6, -0.35, -0.1]
		{
		hw := 0.65 + 0.5 * yv
		NfSP.side.Push([-(hw + 0.25) * R, yv * R]), NfSP.side.Push([(hw + 0.25) * R, yv * R])
		}
	NfSP.corn := [[-0.65 * R, 0.55 * R], [0.65 * R, 0.55 * R], [-0.45 * R, 0.7 * R], [0.45 * R, 0.7 * R]]
	NfSP.glyph := [[0, -0.40 * R], [0, -0.25 * R], [0, -0.10 * R], [0, 0.05 * R], [0, 0.20 * R], [0, 0.50 * R]
		, [-0.05 * R, -0.20 * R], [0.05 * R, -0.20 * R], [-0.05 * R, 0.10 * R], [0.05 * R, 0.10 * R]]
	NfSP.tout := [[-0.8 * R, -0.85 * R], [0.8 * R, -0.85 * R], [-1.1 * R, -0.5 * R], [1.1 * R, -0.5 * R], [-1.25 * R, 0], [1.25 * R, 0], [-0.45 * R, -1.05 * R], [0.45 * R, -1.05 * R]]
}

NoiseZoneIcons() {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft, WindowHeight, WindowWidth
	global NoiseZWx, NoiseZGx, NoiseZKx, NfIconN, pNfIconHist, NfNativeReady, NfHist, NfHistW, NfHPrm, NfHistBuf, NfHPrmBuf
	NoiseZWx := -1
	NoiseZGx := -1
	NoiseZKx := -1
	NfIconN := 0
	if (!pCaptureBits or CaptureW < 200 or CaptureH < 12)
		return false
	if (!NfNativeReady)
		NfNativeInit()
	w := CaptureW
	if (NfHistW != w)
		{
		NfHistW := w
		VarSetCapacity(NfHistBuf, w * 6 * 4, 0)
		NfHist := &NfHistBuf
		VarSetCapacity(NfHPrmBuf, 24, 0)
		NfHPrm := &NfHPrmBuf
		}
	D := WindowHeight * 0.018
	minrun := Round(D * 0.25)
	if (minrun < 5)
		minrun := 5
	NfZoneHist(w, 0, CaptureH // 3, minrun)
	cand := []
	sumw := 0
	x := 0
	st := -1
	while (x <= w and cand.Length() < 4)
		{
		on := false
		if (x < w)
			on := (NumGet(NfHist + 0, (3 * w + x) * 4, "Int") + NumGet(NfHist + 0, (4 * w + x) * 4, "Int") + NumGet(NfHist + 0, (5 * w + x) * 4, "Int")) > 0
		if (on and st < 0)
			st := x
		else if (!on and st >= 0)
			{
			wid := x - st
			if (wid >= D * 0.45 and wid <= D * 1.7)
				{
				cand.Push([st, x - 1, -1])
				sumw += wid
				}
			st := -1
			}
		x++
		}
	if (cand.Length() < 2)
		return false
	for i, c in cand
		{
		y := CaptureH - 1
		while (y >= 0)
			{
			run := 0
			best := 0
			off := (y * w + c[1]) * 4
			k := c[1]
			while (k <= c[2])
				{
				px := NumGet(pCaptureBits + 0, off, "UInt")
				if (((px >> 16) & 0xFF) >= 200 and ((px >> 8) & 0xFF) >= 200 and (px & 0xFF) >= 200)
					{
					run += 1
					if (run > best)
						best := run
					}
				else
					run := 0
				off += 4
				k++
				}
			if (best >= minrun)
				break
			y--
			}
		c[3] := y
		}
	ybot := -1
	for i, c in cand
		{
		if (c[3] < 4)
			continue
		agree := 0
		for j, d in cand
			if (j != i and d[3] >= 0 and Abs(d[3] - c[3]) <= 3)
				agree += 1
		if (agree >= 1 and c[3] > ybot)
			ybot := c[3]
		}
	if (ybot < 4)
		return false
	rpb := Round(1.1 * (sumw / cand.Length()) / 3)
	if (rpb < 1)
		rpb := 1
	y0 := ybot - (3 * rpb) + 1
	if (y0 < 0)
		y0 := 0
	NfZoneHist(w, y0, rpb, minrun)
	for i, c in cand
		{
		if (c[3] < 4 or Abs(c[3] - ybot) > 3)
			continue
		cT := 0
		cM := 0
		cB := 0
		k := c[1]
		while (k <= c[2])
			{
			cT += NumGet(NfHist + 0, k * 4, "Int")
			cM += NumGet(NfHist + 0, (w + k) * 4, "Int")
			cB += NumGet(NfHist + 0, (2 * w + k) * 4, "Int")
			k++
			}
		cmax := (cT > cM) ? cT : cM
		if (cB > cmax)
			cmax := cB
		cmin := (cT < cM) ? cT : cM
		if (cB < cmin)
			cmin := cB
		if (cmax < 1)
			continue
		kind := ""
		if (cT <= 0.45 * cB)
			kind := "TRI"
		else if (cmin >= 0.75 * cmax)
			kind := "SQ"
		else if (cT >= 0.35 * cM and cT <= 0.75 * cM and cB >= 0.45 * cM and cB <= 0.90 * cM)
			kind := "CIR"
		cx := Round(FishBarLeft + (c[1] + c[2]) / 2)
		sep := WindowWidth * 0.035
		if ((NoiseZWx >= 0 and Abs(cx - NoiseZWx) < sep) or (NoiseZGx >= 0 and Abs(cx - NoiseZGx) < sep) or (NoiseZKx >= 0 and Abs(cx - NoiseZKx) < sep))
			continue
		if (kind = "SQ" and NoiseZWx < 0)
			NoiseZWx := cx
		else if (kind = "CIR" and NoiseZGx < 0)
			NoiseZGx := cx
		else if (kind = "TRI" and NoiseZKx < 0)
			NoiseZKx := cx
		}
	NfIconN := (NoiseZWx >= 0) + (NoiseZGx >= 0) + (NoiseZKx >= 0)
	return (NfIconN >= 2)
}

NfZoneHist(w, y0, rpb, minrun) {
	global pCaptureBits, CaptureH, pNfIconHist, NfHist, NfHPrm
	DllCall("RtlZeroMemory", "Ptr", NfHist, "Ptr", w * 6 * 4)
	NumPut(200, NfHPrm + 0, 0, "Int"), NumPut(minrun, NfHPrm + 0, 4, "Int"), NumPut(y0, NfHPrm + 0, 8, "Int"), NumPut(rpb, NfHPrm + 0, 12, "Int"), NumPut(NfHist, NfHPrm + 0, 16, "Int64")
	if (pNfIconHist)
		DllCall(pNfIconHist, "Ptr", pCaptureBits, "Int", w, "Int", CaptureH, "Ptr", NfHPrm)
	else
		NfIconHistAhk(pCaptureBits, w, CaptureH, NfHPrm)
}


HalibutCircleX() {
	global QpcFreq, HaliLastX, HaliLastT
	DllCall("QueryPerformanceCounter", "Int64*", hnow)
	hx := HalibutFindCircle()
	if (hx >= 0)
		{
		HaliLastX := hx
		HaliLastT := hnow
		return hx
		}
	if (HaliLastT and ((hnow - HaliLastT) / QpcFreq) < 0.15)
		return HaliLastX
	HaliLastT := 0
	return -1
}

HalibutBlue(px) {
	b := px & 0xFF, g := (px >> 8) & 0xFF, r := (px >> 16) & 0xFF
	return (b >= 90 and b - r >= 45 and b - g >= 45 and r <= 90 and g <= 90)
}

HalibutFindCircle() {
	global pNoteBits, NoteW, NoteH, FishBarLeft, WindowHeight
	if (!pNoteBits or NoteH < 20 or NoteW < 20)
		return -1
	D := WindowHeight * 0.040
	gapMax := Round(D * 0.3)
	for ri, fr in [0.55, 0.45, 0.65]
		{
		p := pNoteBits + (Round(NoteH * fr) * NoteW * 4)
		runS := -1
		runE := -1
		x := 0
		while (x < NoteW + gapMax + 2)
			{
			if (x < NoteW and HalibutBlue(NumGet(p + 0, x * 4, "UInt")))
				{
				if (runS < 0)
					runS := x
				runE := x
				}
			else if (runS >= 0 and (x - runE > gapMax))
				{
				w := runE - runS + 1
				if (w >= D * 0.35 and w <= D * 1.5)
					{
					cx := HalibutVerify(runS, runE, D)
					if (cx >= 0)
						return FishBarLeft + cx
					}
				runS := -1
				}
			x += 2
			}
		}
	return -1
}

HalibutVerify(s, e, D) {
	global pNoteBits, NoteW, NoteH
	x0 := s - Round(D * 0.3)
	x1 := e + Round(D * 0.3)
	if (x0 < 0)
		x0 := 0
	if (x1 > NoteW - 1)
		x1 := NoteW - 1
	n := 0, minX := 99999, maxX := -1, minY := 99999, maxY := -1
	y := 0
	while (y < NoteH)
		{
		p := pNoteBits + (y * NoteW * 4)
		x := x0
		while (x <= x1)
			{
			if (HalibutBlue(NumGet(p + 0, x * 4, "UInt")))
				{
				n++
				if (x < minX)
					minX := x
				if (x > maxX)
					maxX := x
				if (y < minY)
					minY := y
				maxY := y
				}
			x += 2
			}
		y += 2
		}
	if (n < 4)
		return -1
	w := maxX - minX + 2
	h := maxY - minY + 2
	if (w < D * 0.45 or w > D * 1.4 or h < D * 0.45 or h > D * 1.4)
		return -1
	if (Abs(w - h) > 0.3 * ((w > h) ? w : h))
		return -1
	if ((n * 4) / (0.7854 * w * h) < 0.6)
		return -1
	cy := (minY + maxY) / 2
	if (cy < NoteH * 0.3 or cy > NoteH * 0.8 or maxY >= NoteH - 3)
		return -1
	return (minX + maxX) / 2
}

NoiseGimmickTarget() {
	global QpcFreq, NoiseZoneTgt, NoiseZoneT, NoiseZoneKind
	global NoiseZScanT, NoiseZWx, NoiseZGx, NoiseZKx, NoiseZOK, NoiseZFreshT
	global NoisePendKind, NoisePendT, NoiseZPrevOK, NoiseOnZoneN
	global WindowWidth, NfIconN, NfCW, NfCG, NfCK, NfPW, NfPG, NfPK, NfGoneN
	DllCall("QueryPerformanceCounter", "Int64*", gnow)
	gk := NoiseWarnKind()
	seq := (NoisePendT > 0 and ((gnow - NoisePendT) / QpcFreq) < 2.0)
	if (gk != "")
		{
		if (gk != "BLACK")
			{
			NoisePendKind := gk
			NoisePendT := gnow
			}
		else if (NoisePendKind = "" or NoisePendKind = "BLACK" or !seq)
			{
			NoisePendKind := "BLACK"
			NoisePendT := gnow
			}
		}
	pend := (NoisePendT > 0 and ((gnow - NoisePendT) / QpcFreq) < 2.20)
	zgone := false
	gint := 1.00
	if (pend or NoiseZoneTgt >= 0)
		gint := 0.15
	if (NoiseZScanT < 1 or ((gnow - NoiseZScanT) / QpcFreq) >= gint)
		{
		NoiseZScanT := gnow
		NoiseZoneIcons()
		tolX := WindowWidth * 0.015
		one := (NfIconN = 3)
		NfCW := (NoiseZWx >= 0 and (one or (NfPW >= 0 and Abs(NoiseZWx - NfPW) <= tolX))) ? NoiseZWx : -1
		NfCG := (NoiseZGx >= 0 and (one or (NfPG >= 0 and Abs(NoiseZGx - NfPG) <= tolX))) ? NoiseZGx : -1
		NfCK := (NoiseZKx >= 0 and (one or (NfPK >= 0 and Abs(NoiseZKx - NfPK) <= tolX))) ? NoiseZKx : -1
		NfPW := NoiseZWx
		NfPG := NoiseZGx
		NfPK := NoiseZKx
		if (NfIconN >= 2)
			{
			NoiseZFreshT := gnow
			NfGoneN := 0
			}
		else if (NoiseZoneTgt >= 0 and ((gnow - NoiseZoneT) / QpcFreq) >= 1.2)
			{
			NfGoneN := NfGoneN + 1
			if (NfGoneN >= 2)
				zgone := true
			}
		}
	NoiseZPrevOK := NoiseZOK
	NoiseZOK := (NoiseZFreshT > 0 and ((gnow - NoiseZFreshT) / QpcFreq) < 0.60)
	if (NoiseZoneTgt >= 0)
		{
		zage := (gnow - NoiseZoneT) / QpcFreq
		zgap := (NoiseZFreshT > 0) ? ((gnow - NoiseZFreshT) / QpcFreq) : 99
		if (!zgone and zage < 1.85 and zgap < 1.00)
			return NoiseZoneTgt
		if (!zgone and zage < 4.00 and NoiseZOK)
			return NoiseZoneTgt
		NoiseZoneTgt := -1
		NoiseZoneKind := ""
		NoisePendKind := ""
		NoisePendT := 0
		}
	if (!pend or !NoiseZOK)
		return -1
	gz := -1
	if (NoisePendKind = "WHITE")
		gz := NfCW
	else if (NoisePendKind = "GREEN")
		gz := NfCG
	else if (NoisePendKind = "BLACK")
		gz := NfCK
	if (gz < 0)
		return -1
	NoiseZoneTgt := gz
	NoiseZoneT := gnow
	NfGoneN := 0
	NoiseZoneKind := NoisePendKind
	NoisePendT := 0
	return gz
}
PinionPlan(fishX, noteX, ByRef isNote) {
	global RunLeft, RunWidth, WindowWidth, WindowHeight, QpcFreq, NoteBias
	global NoteLockY, NoteH, NoteFresh, NoteAllN
	global PnState, PnImpactAt, PnCoverX, PnNoteX, PnFall, PnFallN, PnPrevY, PnPrevT, PnPrevX, PnProg, PnWhy
	global PnRes, PnGlueAt, PnGlueLo, PnGlueHi, PnAwayAt, PnTwoN, PnResBlockUntil
	global PnSeenY, PnSeenAt, PnLandAt, PnLeaveAt, PnGone, NoteMissAt, NoteAllX, NoteAllY, NoteOriginX, PnChase, PnIconAt
	isNote := false
	DllCall("QueryPerformanceCounter", "Int64*", pnNow)
	p := PinProgress()
	if (p >= 0)
		PnProg := p
	if (RunWidth <= 0)
		return fishX
	halfW := RunWidth / 2
	barC := RunLeft + halfW
	if (fishX >= 0)
		{
		if (Abs(fishX - barC) <= WindowWidth * 0.010)
			{
			if (!PnGlueAt)
				{
				PnGlueAt := pnNow
				PnGlueLo := barC
				PnGlueHi := barC
				}
			if (barC < PnGlueLo)
				PnGlueLo := barC
			if (barC > PnGlueHi)
				PnGlueHi := barC
			}
		else
			PnGlueAt := 0
		if (Abs(fishX - barC) > WindowWidth * 0.06)
			{
			if (!PnAwayAt)
				PnAwayAt := pnNow
			}
		else
			PnAwayAt := 0
		}
	if (NoteFresh)
		{
		vDrop := (PnFallN >= 3 and PnFall > 0) ? PnFall : (WindowHeight * 0.60)
		twoOk := (NoteAllN >= 2)
		if (twoOk and fishX >= 0)
			{
			twoI := 1
			while (twoI <= NoteAllN)
				{
				if (NoteAllY[twoI] >= NoteH - WindowHeight * 0.07 and Abs((NoteOriginX + NoteAllX[twoI]) - fishX) <= WindowWidth * 0.02)
					twoOk := false
				twoI++
				}
			}
		PnTwoN := twoOk ? (PnTwoN + 1) : 0
		if ((PnState = 1 or PnRes) and PnNoteX >= 0)
			{
			if (!NoteMissAt and NoteLockY >= 0 and noteX >= 0 and Abs(noteX - PnNoteX) <= 60 and NoteLockY > PnSeenY)
				{
				PnGone := false
				PnSeenY := NoteLockY
				PnSeenAt := pnNow
				PnPrevY := NoteLockY
				PnPrevT := pnNow
				PnPrevX := noteX
				PnLandAt := pnNow + Round(((NoteH - NoteLockY) / vDrop) * QpcFreq)
				PnLeaveAt := PnLandAt + Round(0.08 * QpcFreq)
				landAt := PnLandAt + Round(0.15 * QpcFreq)
				if (landAt > PnImpactAt)
					PnImpactAt := landAt
				}
			else if (NoteMissAt or noteX < 0 or Abs(noteX - PnNoteX) > 60 or NoteLockY < PnSeenY or (pnNow - PnSeenAt) >= 0.06 * QpcFreq)
				PnGone := true
			}
		}
	if (!PnRes)
		{
		if (PnGlueAt and ((pnNow - PnGlueAt) / QpcFreq) >= 0.30 and (PnGlueHi - PnGlueLo) >= WindowWidth * 0.08)
			PnRes := 1
		else if (PnTwoN >= 3 and fishX >= 0 and Abs(fishX - barC) <= WindowWidth * 0.03 and pnNow >= PnResBlockUntil)
			PnRes := 1
		else if (PnIconAt and (pnNow - PnIconAt) <= 0.4 * QpcFreq)
			PnRes := 1          ; Alpha 1.8: the double-note icon over the fish (RfNoteNearBar)
		if (PnRes)
			{
			PnState := 0
			PnNoteX := -1
			PnGone := false
			}
		}
	else if (PnAwayAt and ((pnNow - PnAwayAt) / QpcFreq) >= 0.25)
		{
		PnRes := 0
		PnGlueAt := 0
		PnTwoN := 0
		PnNoteX := -1
		PnGone := false
		PnResBlockUntil := pnNow + Round(1.5 * QpcFreq)
		}
	if (PnRes)
		{
		if (noteX >= 0)
			{
			if (NoteFresh and !NoteMissAt and NoteLockY >= 0 and (PnNoteX < 0 or Abs(noteX - PnNoteX) > 60 or NoteLockY < PnSeenY))
				{
				PnNoteX := noteX
				PnSeenY := NoteLockY
				PnSeenAt := pnNow
				PnLandAt := pnNow + Round(((NoteH - NoteLockY) / vDrop) * QpcFreq)
				PnLeaveAt := PnLandAt + Round(0.08 * QpcFreq)
				PnGone := false
				}
			if (!PnGone or pnNow < PnLeaveAt)
				{
				isNote := true
				PnWhy := "resonance: note"
				return noteX
				}
			PnWhy := "resonance: no note"
			return (fishX >= 0) ? fishX : barC
			}
		PnNoteX := -1
		PnGone := false
		PnWhy := "resonance: no note"
		return (fishX >= 0) ? fishX : barC
		}
	if (PnState = 1)
		{
		if (pnNow >= PnImpactAt or (PnGone and pnNow >= PnLeaveAt))
			PnState := 0
		else
			{
			; Alpha 1.5: notes come first (hitting every note is the perfect catch on this rod). The
			; bar covers the fish as well when it is wide enough for both; it lets the note go only
			; when progress is about to run out
			if (fishX >= 0)
				{
				PnCoverX := PinionCover(fishX, PnNoteX, keeps)
				if (!keeps and PnProg >= 0 and PnProg < 0.12 + (100 - NoteBias) * 0.005)
					{
					PnState := 0
					PnWhy := "progress " . Round(PnProg * 100) . "%: back to the fish"
					return fishX
					}
				PnChase := !keeps
				}
			isNote := (PnChase and Abs(barC - PnCoverX) <= NoteHoldZone(RunWidth))
			PnWhy := "hold"
			return PnCoverX
			}
		}
	if (noteX < 0 or NoteBias <= 0)
		{
		PnWhy := "no note"
		return fishX
		}
	if (NoteFresh and NoteLockY >= 0 and !(NoteMissAt and Abs(noteX - PnNoteX) <= 60 and pnNow >= PnLeaveAt))
		{
		if (PnPrevT and Abs(noteX - PnPrevX) <= 60 and NoteLockY > PnPrevY)
			{
			dtS := (pnNow - PnPrevT) / QpcFreq
			if (dtS > 0.02 and dtS < 0.4)
				{
				v := (NoteLockY - PnPrevY) / dtS
				if (v < WindowHeight * 0.45)
					v := WindowHeight * 0.45
				if (v > WindowHeight * 0.80)
					v := WindowHeight * 0.80
				PnFall := (PnFall > 0) ? (PnFall * 0.8 + v * 0.2) : v
				PnFallN := PnFallN + 1
				}
			}
		PnPrevY := NoteLockY
		PnPrevT := pnNow
		PnPrevX := noteX
		}
	if (NoteLockY < 0 or !PnPrevT)
		return fishX
	vFall := (PnFallN >= 3 and PnFall > 0) ? PnFall : (WindowHeight * 0.60)
	tti := (NoteH - NoteLockY) / vFall - ((pnNow - PnPrevT) / QpcFreq)
	if (tti < -0.05)
		{
		PnWhy := "no note"
		return fishX
		}
	; Every reachable note is taken (hitting all notes is this rod's perfect catch): the bar covers
	; the note and the fish together when it is wide enough (keeps), else the note alone. The only
	; reason to stay with the fish is progress about to run out. Measured on the Pinions video
	; (2026-11-09): this rod's bar reaches 31-34% of the window width per second (1.4 and 1.5 used
	; the plain rod's 17%, so most notes were wrongly skipped as too far), and progress drains
	; about 10%/s while the fish is off the bar.
	cover := (fishX >= 0) ? PinionCover(fishX, noteX, keeps) : noteX
	if (fishX < 0)
		keeps := false
	; Alpha 1.9: no note is given up for being far (the user: the bar refused notes on the other
	; side). The travel time is from the bar's measured speed-up, and only until the note is on
	; the bar (PinionTravelTime); when even that is too slow the bar still goes ("go (late)").
	vBar := WindowWidth * 0.30
	tGo := PinionTravelTime(Abs(cover - barC))
	late := (tGo + 0.10 > tti)
	tTravel := tGo + 0.90
	if (fishX >= 0 and !keeps)
		{
		tOff := tti + Abs(cover - fishX) / vBar + 0.10
		floor := 0.12 + (100 - NoteBias) * 0.005
		if (PnProg >= 0 and PnProg - 0.10 * tOff < floor)
			{
			PnWhy := "skip: progress " . Round(PnProg * 100) . "%"
			return fishX
			}
		}
	if (tti > tTravel + 0.10)
		{
		PnWhy := "wait " . Round(tti - tTravel, 1) . "s"
		return fishX
		}
	PnState := 1
	PnNoteX := noteX
	PnCoverX := cover
	PnSeenY := NoteLockY
	PnSeenAt := PnPrevT
	PnGone := false
	PnLandAt := pnNow + Round(tti * QpcFreq)
	PnLeaveAt := PnLandAt + Round(0.08 * QpcFreq)
	PnImpactAt := PnLandAt + Round(0.15 * QpcFreq)
	PnChase := !keeps
	isNote := (PnChase and Abs(barC - cover) <= NoteHoldZone(RunWidth))
	PnWhy := (late ? "go (late) " : keeps ? "cover both " : "go ") . Round(Abs(cover - barC)) . "px"
	return cover
}

; Alpha 1.9: seconds for the bar, starting still, to get a note d px away onto the bar (within
; 35% of its width of the middle), plus 60 ms of lag. Measured on the Pinions video (2026-11-09):
; it speeds up at about 0.63 window widths/s² and passes 0.42 widths/s; 0.60 is used.
PinionTravelTime(d) {
	global WindowWidth, RunWidth
	ww := (WindowWidth > 0) ? WindowWidth : 1920
	a := ww * 0.60, vm := ww * 0.42
	d2 := d - ((RunWidth > 0) ? RunWidth * 0.35 : 0)
	if (d2 <= 0)
		return 0.06
	dAcc := vm * vm / (2 * a)
	t := (d2 <= dAcc) ? Sqrt(2 * d2 / a) : (vm / a + (d2 - dAcc) / vm)
	return t + 0.06
}

; Alpha 1.4. Where the bar's centre should go to catch a note at noteX: between the note and the
; fish when both fit on the bar with an edge of 15% of its width (at least 14 px) to spare, so the
; fish stays on (keeps true); otherwise on the note (keeps false).
PinionCover(fishX, noteX, ByRef keeps) {
	global RunWidth
	edge := RunWidth * 0.15
	if (edge < 14)
		edge := 14
	keeps := (Abs(noteX - fishX) <= RunWidth - 2 * edge)
	return keeps ? (noteX + fishX) / 2 : noteX + 0.0
}

PinProgress() {
	global pCaptureBits, CaptureW, PnProgRow, PnPrmW, PnPrmWI, PnPrmP, PnPrmPI
	if (!pCaptureBits or PnProgRow < 4 or CaptureW < 40)
		return -1
	best := -1
	bestN := 0
	r := PnProgRow - 4
	while (r <= PnProgRow + 4)
		{
		p := pCaptureBits + (r * CaptureW * 4)
		ww := 0
		pw := 0
		i0 := PcFind(p, CaptureW, 4, PnPrmW)
		if (i0 >= 0)
			{
			i1 := PcFind(p + (i0 + 1) * 4, CaptureW - i0 - 1, 4, PnPrmWI)
			ww := (i1 < 0) ? (CaptureW - i0) : (i1 + 1)
			j0 := PcFind(p + (i0 + ww) * 4, CaptureW - i0 - ww, 4, PnPrmP)
			if (j0 >= 0 and j0 <= 6)
				{
				js := i0 + ww + j0
				j1 := PcFind(p + (js + 1) * 4, CaptureW - js - 1, 4, PnPrmPI)
				pw := (j1 < 0) ? (CaptureW - js) : (j1 + 1)
				}
			}
		else
			{
			j0 := PcFind(p, CaptureW, 4, PnPrmP)
			if (j0 >= 0)
				{
				j1 := PcFind(p + (j0 + 1) * 4, CaptureW - j0 - 1, 4, PnPrmPI)
				pw := (j1 < 0) ? (CaptureW - j0) : (j1 + 1)
				}
			}
		if (ww + pw > bestN)
			{
			bestN := ww + pw
			best := ww / (ww + pw)
			}
		r += 2
		}
	if (bestN < CaptureW * 0.15)
		return -1
	return best
}

NoteTarget() {
	global SpecialRod, RunLeft, RunWidth, NoteDbgRod, HalibutPlayMinigame
	NoteDbgRod := NoteDbgRod + 1
	if (SpecialRod = "Noiseform")
		return NoiseGimmickTarget()
	if (SpecialRod = "Halibut Harpoon")
		return HalibutPlayMinigame ? HalibutCircleX() : -1
	if (SpecialRod != "Pinions Aria")
		return -1
	ref := (RunWidth > 0) ? RunLeft + (RunWidth / 2) : -1
	return NoteScan(ref)
}

;====================================================================================================;
;   Reel detection  (new in Alpha 0.7, written for Re:Fisch)
;
;   Reads the reel band (pCaptureBits: CaptureW x CaptureH, from RfCapFrame) for the bar
;   (RunLeft / RunWidth, client pixels), the fish (LastFishX), the arrow, and whether the reel
;   UI is on screen at all (the edge gate, RfGate). Special rods hand off to their own scanners.
;
;   From the bottom up:
;     colour lists  colour settings parsed once into {n, r[], g[], b[]}; pixel tests and row
;                   searches against them (RfColList, RfColHit, RfColRun)
;     brightness    a row as brightness values (RfRowLum) and the longest bright stretch in it
;                   (RfLongestRun), used three ways: the brightest stretch of a row (RfRowSpan,
;                   RfBarRowPick), the colour-free bar (RfBarPlain) and the track's lit part
;                   (RfTrackSpan, RfTrackBar)
;     bar           by its edge colours with learned live colours and the track as fallbacks
;                   (RfBarByColour), colour-free (RfBarPlain), and the dispatcher (RfBarFind)
;     fish          by colour, inside the colour-free bar, or as a narrow column band
;                   (RfFishFind, RfFishPlain, RfFishBand); the fish line (RfFishLineSeen); the
;                   arrow (RfArrowFind)
;     presence      RfReelVisible, RfReelScore
;     edge gate     the reel frame's top and bottom borders, seen as horizontal edges in the
;                   band's extra rows: learned at the start of a fight, then watched (RfGate*)
;====================================================================================================;

; ---- colour lists ----------------------------------------------------------------------------------

; A colour-list setting ("0xRRGGBB" values separated by commas, semicolons or bars) as
; {n, r[], g[], b[]} (rods read these fields too). Each text is parsed once; the store is emptied
; when it passes 97 entries.
RfColList(s) {
	static seen := {}, count := 0
	if (seen.HasKey(s))
		return seen[s]
	if (++count > 97)
		seen := {}, count := 1
	o := {n: 0, r: [], g: [], b: []}
	for i, part in StrSplit(s, [",", ";", "|"], " `t")
		{
		v := ColNorm(part)
		if (v < 0)
			continue
		o.n += 1
		o.r.Push(v >> 16 & 0xFF), o.g.Push(v >> 8 & 0xFF), o.b.Push(v & 0xFF)
		}
	seen[s] := o
	return o
}

; A list holding one colour, given as a pixel (0xRRGGBB).
RfColOne(px) {
	return {n: 1, r: [px >> 16 & 0xFF], g: [px >> 8 & 0xFF], b: [px & 0xFF]}
}

; The first colour of a colour-list setting as 0xRRGGBB (0 when there is none), and how many it
; holds.
RfColFirst(s) {
	o := RfColList(s)
	return o.n ? (o.r[1] << 16 | o.g[1] << 8 | o.b[1]) : 0
}

RfColCount(s) {
	return RfColList(s).n
}

; Is pixel px (0xRRGGBB in its low bytes) within tol of any colour in list o, on every channel?
RfColHit(o, px, tol) {
	r := px >> 16 & 0xFF, g := px >> 8 & 0xFF, b := px & 0xFF
	Loop, % o.n
		if (Abs(r - o.r[A_Index]) <= tol and Abs(g - o.g[A_Index]) <= tol and Abs(b - o.b[A_Index]) <= tol)
			return true
	return false
}

; Two pixels within tol of each other on every channel.
RfColNear(a, b, tol) {
	return (Abs((a >> 16 & 0xFF) - (b >> 16 & 0xFF)) <= tol and Abs((a >> 8 & 0xFF) - (b >> 8 & 0xFF)) <= tol
		and Abs((a & 0xFF) - (b & 0xFF)) <= tol)
}

; Searches band row y between columns x0 and x1 for colours of list o. how: "first" = the first
; match from the left, "last" = the first from the right, "mid" = the middle of the first run of
; matches (gaps of up to 4 px kept in it). Returns a client x (FishBarLeft + column) or -1.
RfColRun(o, tol, y, x0, x1, how := "first") {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft
	if (o.n < 1 or y < 0 or y >= CaptureH)
		return -1
	x0 := Max(x0, 0), x1 := Min(x1, CaptureW - 1)
	row := pCaptureBits + y * CaptureW * 4
	if (how = "last")
		{
		x := x1
		while (x >= x0)
			{
			if (RfColHit(o, NumGet(row + 0, x * 4, "UInt"), tol))
				return FishBarLeft + x
			x -= 1
			}
		return -1
		}
	a := -1, z := -1, x := x0
	while (x <= x1)
		{
		if (RfColHit(o, NumGet(row + 0, x * 4, "UInt"), tol))
			{
			if (how = "first")
				return FishBarLeft + x
			if (a < 0)
				a := x
			z := x
			}
		else if (a >= 0 and x - z > 4)
			break
		x += 1
		}
	return (a < 0) ? -1 : FishBarLeft + (a + z) / 2
}

; How many of n rows spread down the band (row k at (2k - 1) / 2n of its height) have a colour of
; list o at column x.
RfColColumnHits(o, tol, x, n) {
	global pCaptureBits, CaptureW, CaptureH
	hits := 0
	Loop, % n
		{
		y := Min(Floor(CaptureH * (A_Index * 2 - 1) / (n * 2)), CaptureH - 1)
		hits += RfColHit(o, NumGet(pCaptureBits + 0, (y * CaptureW + x) * 4, "UInt"), tol)
		}
	return hits
}

; The first pixel matching one colour, given in blue-green-red order (bgr), on five rows down the
; band (1/10, 3/10 .. 9/10 of its height): a client x, or -1.
RfFindColourBgr(bgr, tol) {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft
	; the wanted red, green and blue (bgr holds blue in its high byte); tested inline, since this
	; runs on the reel's arrow-less frames
	wr := bgr & 0xFF, wg := bgr >> 8 & 0xFF, wb := bgr >> 16 & 0xFF
	Loop, 5
		{
		row := pCaptureBits + Floor(CaptureH * (A_Index * 2 - 1) / 10) * CaptureW * 4
		Loop, % CaptureW
			{
			px := NumGet(row + 0, (A_Index - 1) * 4, "UInt")
			if (Abs((px >> 16 & 0xFF) - wr) <= tol and Abs((px >> 8 & 0xFF) - wg) <= tol and Abs((px & 0xFF) - wb) <= tol)
				return FishBarLeft + A_Index - 1
			}
		}
	return -1
}

; ---- pixels and brightness -------------------------------------------------------------------------

; Pixel (x, y) of the band as 0xRRGGBB, or -1 outside it.
RfBandPx(x, y) {
	global pCaptureBits, CaptureW, CaptureH
	if (x < 0 or y < 0 or x >= CaptureW or y >= CaptureH)
		return -1
	return NumGet(pCaptureBits + 0, (y * CaptureW + x) * 4, "UInt") & 0xFFFFFF
}

; v when it is at least lo, else lo (also when v is blank).
RfAtLeast(v, lo) {
	return (v >= lo) ? v : lo
}

; Band row y as brightness values (the mean of red, green and blue): lum[1] is column 0. lo, hi
; and sum get the row's lowest, highest and total brightness.
RfRowLum(y, ByRef lo := "", ByRef hi := "", ByRef sum := "") {
	global pCaptureBits, CaptureW
	row := pCaptureBits + y * CaptureW * 4
	lum := [], lo := 255, hi := 0, sum := 0
	Loop, % CaptureW
		{
		px := NumGet(row + 0, (A_Index - 1) * 4, "UInt")
		v := ((px & 0xFF) + (px >> 8 & 0xFF) + (px >> 16 & 0xFF)) // 3
		lum[A_Index] := v, sum += v
		if (v < lo)
			lo := v
		if (v > hi)
			hi := v
		}
	return lum
}

; The longest stretch of lum values above thr (at or above it when orEqual), where darker gaps of
; up to maxGap columns do not break a stretch. Its first and last columns (0-based) go to s and e;
; returns its length, 0 when there is none. On a tie the leftmost stretch wins.
RfLongestRun(lum, thr, maxGap, orEqual, ByRef s, ByRef e) {
	s := -1, e := -1, a := -1, z := -1, best := 0
	n := lum.Length()
	Loop, % n + 1
		{
		x := A_Index - 1
		if (A_Index <= n and (orEqual ? lum[A_Index] >= thr : lum[A_Index] > thr))
			{
			if (a < 0)
				a := x
			z := x
			}
		else if (a >= 0 and (x - z > maxGap or A_Index > n))
			{
			if (z - a + 1 > best)
				best := z - a + 1, s := a, e := z
			a := -1
			}
		}
	return best
}

; The brightest stretch of band row y: on a row with some contrast (40 or more between its
; darkest and brightest), the longest stretch past 55 % of the way up, gaps of up to 6 % of the
; band (6 px or more) allowed. At least minRun px: sets RunLeft / RunWidth.
RfRowSpan(y, minRun) {
	global CaptureW, CaptureH, FishBarLeft, RunLeft, RunWidth
	if (y < 0 or y >= CaptureH)
		return false
	lum := RfRowLum(y, lo, hi)
	if (hi - lo < 40)
		return false
	len := RfLongestRun(lum, lo + (hi - lo) * 0.55, RfAtLeast(Round(CaptureW * 0.06), 6), false, s, e)
	if (len < minRun)
		return false
	RunLeft := FishBarLeft + s, RunWidth := len
	return true
}

; RfRowSpan on every row of the band; the widest one wins and becomes BarScanRow. agree = how many
; rows found a stretch close to it (centre within 15 % of the band, width within half to 1.5x).
RfBarRowPick(minRun, ByRef agree := "") {
	global CaptureW, CaptureH, BarScanRow, RunLeft, RunWidth
	spans := [], best := ""
	Loop, % CaptureH
		if (RfRowSpan(A_Index - 1, minRun))
			{
			sp := {y: A_Index - 1, l: RunLeft, w: RunWidth}
			spans.Push(sp)
			if (!IsObject(best) or sp.w > best.w)
				best := sp
			}
	agree := 0
	if (!IsObject(best))
		return false
	mid := best.l + best.w / 2
	for i, sp in spans
		if (Abs(sp.l + sp.w / 2 - mid) <= CaptureW * 0.15 and sp.w >= best.w * 0.5 and sp.w <= best.w * 1.5)
			agree += 1
	BarScanRow := best.y, RunLeft := best.l, RunWidth := best.w
	return true
}

; The track's lit part on band row y: the longest stretch brighter than twice the row's median
; (and 15 over it), gaps of up to 20 px allowed, 40 px or wider. Columns to s and e.
RfTrackSpan(y, ByRef s, ByRef e) {
	global CaptureW, CaptureH
	s := -1, e := -1
	if (y < 0 or y >= CaptureH or CaptureW < 40)
		return false
	lum := RfRowLum(y)
	; the median, in steps of 4, from a 64-bin count
	bins := []
	Loop, 64
		bins[A_Index] := 0
	for i, v in lum
		bins[v // 4 + 1] += 1
	need := CaptureW // 2, seen := 0, med := 0
	for b, c in bins
		if ((seen += c) >= need)
			{
			med := (b - 1) * 4 + 2
			break
			}
	if (RfLongestRun(lum, Max(med * 2, med + 15), 20, false, a, z) < 40)
		return false
	s := a, e := z
	return true
}

; The bar as the track's lit part on row y, trusted only when the rows 15 % of the band's height
; above and below show the same stretch (each end within 6 % of its width, 6 px at least).
; l = client x, w = width.
RfTrackBar(y, ByRef l, ByRef w) {
	global CaptureH, FishBarLeft
	l := -1, w := 0
	if (!RfTrackSpan(y, s, e))
		return false
	slack := RfAtLeast(Round((e - s + 1) * 0.06), 6), dy := RfAtLeast(Round(CaptureH * 0.15), 2)
	for i, yy in [y - dy, y + dy]
		{
		yy := Min(Max(yy, 1), CaptureH - 2)
		if (yy != y and (!RfTrackSpan(yy, s2, e2) or Abs(s2 - s) > slack or Abs(e2 - e) > slack))
			return false
		}
	l := FishBarLeft + s, w := e - s + 1
	return true
}

; Is the band nearly black (85 % or more of a sample every 4th column of every 2nd row darker
; than 40)? Used with Darkheart.
RfBandDark() {
	global pCaptureBits, CaptureW, CaptureH
	dark := 0, n := 0, y := 0
	while (y < CaptureH)
		{
		row := pCaptureBits + y * CaptureW * 4, x := 0
		while (x < CaptureW)
			{
			px := NumGet(row + 0, x * 4, "UInt")
			if ((px & 0xFF) + (px >> 8 & 0xFF) + (px >> 16 & 0xFF) < 120)      ; brightness under 40
				dark += 1
			n += 1, x += 4
			}
		y += 2
		}
	return n ? (dark * 100 // n >= 85) : false
}

; ---- the bar ---------------------------------------------------------------------------------------

; What the bar finders remember between frames: last frame's ends (client x), the edge colours
; learned live, and the last five widths found by colour.
RfBarMemory() {
	global RfBarMem
	if (!IsObject(RfBarMem))
		RfBarMem := {lastL: -1, lastR: -1, liveL: -1, liveR: -1, liveW: -1, liveMiss: 0, liveOnlyAt: 0
			, widths: [], widthsAt: 0, plainL: -1, plainR: -1, plainRow: 0}
	return RfBarMem
}

; Forgets parts of that memory: "ends", "live" (learned colours) and / or "widths".
RfBarForget(parts) {
	m := RfBarMemory()
	if InStr(parts, "ends")
		m.lastL := -1, m.lastR := -1
	if InStr(parts, "live")
		m.liveL := -1, m.liveR := -1, m.liveW := -1, m.liveMiss := 0, m.liveOnlyAt := 0
	if InStr(parts, "widths")
		m.widths := [], m.widthsAt := 0
}

; The bar for the current rod and mode: sets RunLeft / RunWidth, true when found.
; Special rods and the Lines mode use their own scanners (RfBarRodScan). Otherwise the colour
; finder runs when both edge colours are set and the colour-free one when not, and whichever first
; finds a bar (the colour-free one together with a fish) is kept from then on (RfBarMode "colour"
; or "plain"; "" until then; the reel loop clears it every fight). Last resort: the brightest
; stretch of a row, whose width is only a guess (BarWidthTrusted false).
RfBarFind() {
	global
	local ok
	BarWidthTrusted := true
	RfBarStale := 0
	if (RfBarRodScan(ok))
		return ok
	if (BarLeftColor != "" and BarRightColor != "" and RfBarMode != "plain")
		{
		if (RfBarByColour())
			{
			RfBarMode := "colour"
			return true
			}
		if (RfBarMode = "colour")
			return false
		}
	if (RfBarMode != "colour")
		{
		ok := RfBarPlain()
		if (ok and RfBarMode = "" and RfFishPlain() >= 0)
			RfBarMode := "plain"
		if (RfBarMode = "plain")
			return ok
		}
	BarWidthTrusted := false
	return RfRowSpan(BarScanRow, 6) or RfBarRowPick(6)
}

; The bar from a special rod's own scanner, or the Lines mode's: false when the current rod and
; mode have none; else true, with found (true / false) and RunLeft / RunWidth when found.
RfBarRodScan(ByRef found) {
	global
	local how, lv, wv
	static rods := {"Stellarwave Melody": "SwScan SwBarL SwBarW", "Castbound": "CastboundScan CastBarL CastBarW"
		, "Noiseform": "NoiseScan NoiseBarL NoiseBarW", "Remembrance": "RemBarScan RemBarL RemBarW"
		, "MiguRod": "MiguBarScan MiguBarL MiguBarW", "Halibut Harpoon": "HalibutBarScan HaliBarL HaliBarW"
		, "Tryhard Rod": "TryhardScan TryBarL TryBarW"}
	if (rods.HasKey(SpecialRod))
		how := rods[SpecialRod]
	else if (ControlMode = "Lines" or SpecialRod = "Pinions Aria")
		how := "LineScan LineBarL LineBarW"
	else if (SpecialRod = "Verdant Oath")
		how := "VerdantBarScan VgBarL VgBarW"
	else
		return false
	how := StrSplit(how, " "), lv := how[2], wv := how[3]
	if (SpecialRod = "Pinions Aria" and ControlMode != "Lines")
		PinionScan()
	found := Func(how[1]).Call() ? true : false
	if (found and SpecialRod = "Stellarwave Melody")
		found := SwFound ? true : false
	; Alpha 1.3, for the reel log: RfBarStale is 1 when LineScan reused an old bar position (it
	; does for up to 12 frames) and 2 when only the fallback below keeps the bar
	if (found and lv = "LineBarL" and LineBarAge > 0)
		RfBarStale := 1
	if (!found and lv = "LineBarL")
		{
		found := (LineFishSeen and LineBarW >= 1)     ; Lines: the bar last seen with the fish line
		if (found)
			RfBarStale := 2
		}
	if (found)
		RunLeft := %lv%, RunWidth := %wv%
	return true
}

; The bar by its edge colours (Bar left / right colour settings) on the scan row: the left end is
; the first left-colour pixel, the right end the last right-colour pixel. Looked for near last
; frame's ends first (70 px either way, the live-learned colours before the set ones while the
; reel is on), then along the whole row, then on rows at 1/6, 3/6 and 5/6 of the band.
; The track's lit part (RfTrackBar) stands in when the match is clearly narrower than the usual
; width, or ends where the bar visibly goes on. Learns the colours just inside each end (live
; colours), and drops them after 6 s in which only they matched.
RfBarByColour() {
	global BarLeftColor, BarRightColor, BarColorTolerance, RunLeft, RunWidth, BarScanRow, QpcFreq
	global CaptureH, CaptureW, FishBarLeft, MgInPlay
	if (BarLeftColor = "" or BarRightColor = "")
		return false
	m := RfBarMemory()
	y := (BarScanRow >= 0 and BarScanRow < CaptureH) ? BarScanRow : CaptureH // 2
	lc := RfColList(BarLeftColor), rc := RfColList(BarRightColor)
	if (lc.n < 1 or rc.n < 1)
		return false
	tol := BarColorTolerance, liveTol := tol + 24
	l := (m.lastL >= 0) ? RfBarEndNear(m.liveL, lc, liveTol, tol, y, Round(m.lastL - FishBarLeft), "first") : -1
	r := (m.lastR >= 0) ? RfBarEndNear(m.liveR, rc, liveTol, tol, y, Round(m.lastR - FishBarLeft), "last") : -1
	if (l < 0)
		l := RfColRun(lc, tol, y, 0, CaptureW - 1, "first")
	if (r < 0)
		r := RfColRun(rc, tol, y, 0, CaptureW - 1, "last")
	Loop, 3
		{
		if (l >= 0 and r >= 0)
			break
		yy := Floor(CaptureH * (A_Index * 2 - 1) / 6)
		if (l < 0)
			l := RfColRun(lc, tol, yy, 0, CaptureW - 1, "first")
		if (r < 0)
			r := RfColRun(rc, tol, yy, 0, CaptureW - 1, "last")
		}
	; the track instead: when the colours cover clearly less than the usual width (widths found by
	; colour in the last 3 s), or when an end stops where the bar goes on
	DllCall("QueryPerformanceCounter", "Int64*", now)
	ref := (m.widths.Length() >= 3) ? RfMedian(m.widths) : 0
	viaTrack := false
	; Alpha 2.0: the bar turns green while the fish is off it. Found by that colour first (see
	; RfBarOffColour): before, the track stood in for 3 s at most (and took the fish line just
	; outside the bar as part of it), then the bar was "not found" and the reel let go.
	if (MgInPlay and (l < 0 or r < 0 or (ref > 8 and r - l + 1 < ref * 0.5)) and RfBarOffColour(y, ref, gl, gw))
		{
		m.lastL := -1, m.lastR := -1, m.liveMiss := 0, m.liveOnlyAt := 0
		RunLeft := FishBarLeft + gl, RunWidth := gw, BarScanRow := y
		return true
		}
	if (MgInPlay and ref > 8 and m.widthsAt and (now - m.widthsAt) / QpcFreq <= 3.0
		and ((l >= 0 and r > l) ? r - l + 1 : 0) < ref * 0.9
		and RfTrackBar(y, tl, tw) and Abs(tw - ref) <= ref * 0.25)
		viaTrack := true
	else if (l >= 0 and r > l
		and (RfBarEndOpen(y, Round(r - FishBarLeft), 1) or RfBarEndOpen(y, Round(l - FishBarLeft), -1))
		and RfTrackBar(y, tl, tw) and tw >= (r - l + 1) * 1.3 and tw <= CaptureW * 0.75
		and tl <= l + 10 and tl + tw - 1 >= r - 10)
		viaTrack := true
	if (viaTrack)
		l := tl, r := tl + tw - 1
	if (l < 0 or r < 0 or r <= l or r - l + 1 > CaptureW * 0.75)
		{
		m.lastL := -1, m.lastR := -1
		if (++m.liveMiss > 12)
			m.liveL := -1, m.liveR := -1, m.liveW := -1, m.liveOnlyAt := 0
		return false
		}
	m.lastL := viaTrack ? -1 : l, m.lastR := viaTrack ? -1 : r
	RunLeft := l, RunWidth := r - l + 1, BarScanRow := y, m.liveMiss := 0
	if (!viaTrack)
		{
		m.widths.Push(RunWidth)
		if (m.widths.Length() > 5)
			m.widths.RemoveAt(1)
		m.widthsAt := now
		}
	; is either end still the set colour, 2 px in? If not for 6 s, the live colours have drifted
	xl := Round(l - FishBarLeft), xr := Round(r - FishBarLeft)
	pl := RfBandPx(xl + 2, y), pr := RfBandPx(xr - 2, y)
	if ((pl >= 0 and RfColHit(lc, pl, tol)) or (pr >= 0 and RfColHit(rc, pr, tol)))
		m.liveOnlyAt := 0
	else if (!m.liveOnlyAt)
		m.liveOnlyAt := A_TickCount
	else if (A_TickCount - m.liveOnlyAt > 6000)
		{
		m.liveL := -1, m.liveR := -1, m.liveW := -1, m.liveOnlyAt := 0, m.lastL := -1, m.lastR := -1
		return false
		}
	; learn the colours just inside the ends while the width holds steady (within 35 %)
	if (m.liveW <= 0 or Abs(RunWidth - m.liveW) <= m.liveW * 0.35)
		{
		if (pl >= 0)
			m.liveL := RfBarEdgeColour(pl, RfBandPx(xl - 10, y), liveTol, m.liveL)
		if (pr >= 0)
			m.liveR := RfBarEdgeColour(pr, RfBandPx(xr + 10, y), liveTol, m.liveR)
		}
	m.liveW := RunWidth
	return true
}

; Alpha 2.0: the bar while the fish is off it. Fisch draws it dark olive green then (0x4D5841 on the
; user's screen, measured on video 2026-11-08; the track is near black) with a pale arrow inside
; pointing at the fish. Band row y: the longest stretch within 18 of that green on every channel
; (and greener than blue),
; gaps of up to 26 px (the arrow) bridged, at least 60 % and at most 130 % of the usual width ref
; (40 px to 45 % of the band when no width is known yet). Column s and width w.
RfBarOffColour(y, ref, ByRef s, ByRef w) {
	global CaptureW, CaptureH
	static off := 0x4D5841
	s := -1, w := 0
	if (y < 0 or y >= CaptureH or CaptureW < 40)
		return false
	best := 0, a := -1, last := -1, x := 0
	while (x <= CaptureW)
		{
		px := (x < CaptureW) ? RfBandPx(x, y) : -1
		; within 18 of the green, and greener than blue (the slate fish line's edge is bluer)
		hit := (px >= 0 and RfColNear(px, off, 18) and (px >> 8 & 0xFF) >= (px & 0xFF) + 8)
		if (hit)
			{
			if (a < 0 or x - last > 27)
				{
				if (a >= 0 and last - a + 1 > best)
					best := last - a + 1, s := a
				a := x
				}
			last := x
			}
		x += 1
		}
	if (a >= 0 and last - a + 1 > best)
		best := last - a + 1, s := a
	lo := (ref > 8) ? ref * 0.6 : 40, hi := (ref > 8) ? ref * 1.3 : CaptureW * 0.45
	if (best < lo or best > hi)
		{
		s := -1
		return false
		}
	w := best
	return true
}

; One end of the bar near band column x (70 px either way): with the live colour first (when the
; reel is on and one has been learned), then the colour list. how: "first" or "last" (RfColRun).
RfBarEndNear(live, list, liveTol, tol, y, x, how) {
	global MgInPlay
	v := (MgInPlay and live >= 0) ? RfColRun(RfColOne(live), liveTol, y, x - 70, x + 70, how) : -1
	return (v >= 0) ? v : RfColRun(list, tol, y, x - 70, x + 70, how)
}

; Does the bar go on past its colour match? The end at column x (dir +1: right end, -1: left end)
; is open when the pixel 10 px outside it looks like the one 18 px inside (each channel within 40).
RfBarEndOpen(y, x, dir) {
	po := RfBandPx(x + dir * 10, y), pi := RfBandPx(x - dir * 18, y)
	return (po >= 0 and pi >= 0 and RfColNear(po, pi, 40))
}

; A live edge colour: px, or -1 when the pixel just outside the bar (outside) looks the same (the
; edge cannot be told from what is around it); keeps prev when there is no outside pixel.
RfBarEdgeColour(px, outside, tol, prev) {
	if (outside < 0)
		return prev
	return RfColNear(px, outside, tol) ? -1 : px
}

; The bar without colours, on the scan row (the middle row when unset): the longest stretch at least
; 35 % of the way from the row's average brightness to its brightest (and 30 over the average),
; gaps of up to 4 px allowed, 8 px to 60 % of the band wide. Remembered for RfFishPlain.
RfBarPlain() {
	global CaptureW, CaptureH, FishBarLeft, BarScanRow, RunLeft, RunWidth
	m := RfBarMemory()
	y := (BarScanRow >= 0 and BarScanRow < CaptureH) ? BarScanRow : CaptureH // 2
	lum := RfRowLum(y, lo, hi, sum)
	avg := sum // CaptureW
	thr := avg + RfAtLeast((hi - avg) * 35 // 100, 30)
	if (hi < thr)
		return false
	len := RfLongestRun(lum, thr, 4, true, s, e)
	if (len < 8 or len > CaptureW * 0.6)
		return false
	RunLeft := FishBarLeft + s, RunWidth := len
	m.plainL := s, m.plainR := e, m.plainRow := y
	return true
}

; ---- the fish ----------------------------------------------------------------------------------------

; The fish inside the colour-free bar: on that bar's row, the stretch of up to 25 px that stands out
; most from the bar's average colour (every pixel in it at least 3x the average difference, 16 or
; more; summed over the stretch). Sets LastFishX; -1 when there is none.
RfFishPlain() {
	global pCaptureBits, CaptureW, FishBarLeft, LastFishX
	m := RfBarMemory()
	a := m.plainL, z := m.plainR
	if (z - a < 20)
		return -1
	row := pCaptureBits + m.plainRow * CaptureW * 4
	sb := 0, sg := 0, sr := 0, x := a
	while (x <= z)
		{
		px := NumGet(row + 0, x * 4, "UInt")
		sb += px & 0xFF, sg += px >> 8 & 0xFF, sr += px >> 16 & 0xFF, x += 1
		}
	n := z - a + 1, mb := sb // n, mg := sg // n, mr := sr // n
	dist := [], total := 0, x := a
	while (x <= z)
		{
		px := NumGet(row + 0, x * 4, "UInt")
		d := Abs((px & 0xFF) - mb) + Abs((px >> 8 & 0xFF) - mg) + Abs((px >> 16 & 0xFF) - mr)
		dist.Push(d), total += d, x += 1
		}
	thr := RfAtLeast((total // n) * 3, 16)
	best := 0, bs := -1, be := -1, s := -1, e := -1, sum := 0
	Loop, % n + 1
		{
		if (A_Index <= n and dist[A_Index] >= thr)
			{
			if (s < 0)
				s := A_Index, sum := 0
			e := A_Index, sum += dist[A_Index]
			continue
			}
		if (s >= 0 and e - s + 1 <= 25 and sum > best)
			best := sum, bs := s, be := e
		s := -1
		}
	if (bs < 0)
		return -1
	LastFishX := FishBarLeft + a - 1 + (bs + be) / 2
	return LastFishX
}

; The fish as a narrow band of columns (5 to 14 px) that are even down seven rows (spread 25 or
; less) and clearly darker or brighter (by 8 or more) than the columns 2.5 % of the band (10 px or
; more) to either side. Several: the one nearest LastFishX, or the strongest when there is none.
; Searched between band columns x0 and x1; a client x or -1.
RfFishBand(x0, x1) {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft, LastFishX
	off := RfAtLeast(Round(CaptureW * 0.025), 10)
	x0 := Max(x0, off), x1 := Min(x1, CaptureW - off - 1)
	if (x0 > x1)
		return -1
	ys := []
	Loop, 7
		ys.Push(Min(Floor(CaptureH * (A_Index * 2 - 1) / 14), CaptureH - 1))
	; every column's mean brightness and spread over those rows
	mean := {}, spread := {}, x := x0 - off
	while (x <= x1 + off)
		{
		vals := [], tot := 0
		for i, y in ys
			{
			px := NumGet(pCaptureBits + 0, (y * CaptureW + x) * 4, "UInt")
			v := ((px & 0xFF) + (px >> 8 & 0xFF) + (px >> 16 & 0xFF)) // 3
			vals.Push(v), tot += v
			}
		mu := tot / 7, q := 0
		for i, v in vals
			q += (v - mu) * (v - mu)
		mean[x] := mu, spread[x] := Sqrt(q / 7), x += 1
		}
	best := -1, bestScore := -1, a := -1, x := x0
	while (x <= x1 + 1)
		{
		ok := false
		if (x <= x1 and spread[x] <= 25)
			{
			dl := mean[x] - mean[x - off], dr := mean[x] - mean[x + off]
			ok := (Min(Abs(dl), Abs(dr)) >= 8 and (dl > 0) = (dr > 0))
			}
		if (ok and a < 0)
			a := x
		else if (!ok and a >= 0)
			{
			if (x - a >= 5 and x - a <= 14)
				{
				c := Round(a + (x - a) / 2)
				score := (LastFishX >= 0) ? 100000 - Abs(FishBarLeft + c - LastFishX)
					: Min(Abs(mean[c] - mean[c - off]), Abs(mean[c] - mean[c + off]))
				if (score > bestScore)
					bestScore := score, best := c
				}
			a := -1
			}
		x += 1
		}
	return (best < 0) ? -1 : FishBarLeft + best
}

; The fish for the current rod and mode: a client x, -1 when it is not found (for most rods the last
; place it was seen, LastFishX).
; Special rods and the Lines mode use their own scanners (RfFishRodScan). Then: inside the
; colour-free bar when that is the mode in use; by the Fish colour setting on the scan row (near
; the last place first, 55 px either way), on three more rows, and as a column band (RfFishBand).
; RfFishFresh (Alpha 1.1): true only when the fish was found on this frame, false when the
; answer is the last place it was seen. The reel log counts with it.
RfFishFind() {
	global
	local fx, fl, tol, y, lx
	RfFishFresh := false
	if (RfFishRodScan(fx))
		{
		RfFishFresh := (fx >= 0)
		return fx
		}
	if (RfBarMode = "plain" and (fx := RfFishPlain()) >= 0)
		{
		RfFishFresh := true
		return fx
		}
	fl := RfColList(FishColor), tol := FishBarColorTolerance, fx := -1
	y := (BarScanRow >= 0 and BarScanRow < CaptureH) ? BarScanRow : CaptureH // 2
	if (LastFishX >= 0)
		lx := Round(LastFishX - FishBarLeft), fx := RfColRun(fl, tol, y, lx - 55, lx + 55, "mid")
	if (fx < 0)
		fx := RfColRun(fl, tol, y, 0, CaptureW - 1, "mid")
	Loop, 3
		if (fx < 0)
			fx := RfColRun(fl, tol, Floor(CaptureH * (A_Index * 2 - 1) / 6), 0, CaptureW - 1, "mid")
	if (fx < 0)
		fx := RfFishBand(0, CaptureW - 1)
	if (fx >= 0)
		LastFishX := fx, RfFishFresh := true
	return LastFishX
}

; The fish from a special rod's own scanner or the Lines mode's: false when there is none for the
; current rod and mode; else true with the fish (a client x or -1) in fx.
RfFishRodScan(ByRef fx) {
	global
	local e, v, ok
	static rods := {"Castbound": "CastboundScan CastFishX", "Noiseform": "NoiseScan NoiseFishX"
		, "Tryhard Rod": "TryhardScan TryFishX", "Halibut Harpoon": "HalibutBarScan HaliFishX ok"
		, "Remembrance": "RemembranceScan RemTargetX ok", "MiguRod": "MiguScan MiguFishX ok"}
	if (SpecialRod = "Stellarwave Melody")
		{
		SwScan()
		fx := SwFishHeld ? -1 : SwFishX
		return true
		}
	if (rods.HasKey(SpecialRod))
		{
		; "ok": the fish only counts when the scanner says it found the minigame
		e := StrSplit(rods[SpecialRod], " "), v := e[2]
		ok := Func(e[1]).Call()
		fx := (e[3] = "ok" and !ok) ? -1 : %v%
		return true
		}
	if (ControlMode = "Lines")
		{
		LineScan()
		if (LineFishX >= 0)
			{
			if (SpecialRod = "Verdant Oath")
				LastFishX := LineFishX
			fx := LineFishX
			return true
			}
		}
	if (SpecialRod = "Verdant Oath")
		{
		fx := VerdantFishX()
		return true
		}
	if (SpecialRod = "Pinions Aria")
		{
		PinionScan()
		if (PinFishX >= 0)
			{
			fx := PinFishX
			return true
			}
		}
	return false
}

; Is the fish line on screen? Special rods and the Lines mode ask their scanners (RfFishLineRod).
; Otherwise: a run of the Fish colour up to 25 px wide on the scan row whose middle column shows the
; colour on at least 5 of 7 rows down the band.
RfFishLineSeen() {
	global
	local seen, fl, tol, y, row, x, a
	if (RfFishLineRod(seen))
		return seen
	fl := RfColList(FishColor)
	if (fl.n < 1)
		return false
	tol := FishBarColorTolerance
	y := (BarScanRow >= 0 and BarScanRow < CaptureH) ? BarScanRow : CaptureH // 2
	row := pCaptureBits + y * CaptureW * 4, x := 0
	while (x < CaptureW)
		{
		if (!RfColHit(fl, NumGet(row + 0, x * 4, "UInt"), tol))
			{
			x += 1
			continue
			}
		a := x
		while (x < CaptureW and RfColHit(fl, NumGet(row + 0, x * 4, "UInt"), tol))
			x += 1
		if (x - a <= 25 and RfColColumnHits(fl, tol, a + (x - a) // 2, 7) >= 5)
			return true
		}
	return false
}

; The fish line from a special rod's scanner or the Lines mode: false when there is none for the
; current rod and mode; else true with seen (true / false).
RfFishLineRod(ByRef seen) {
	global
	local e, v, ok
	; "and": the scanner must also say it found the minigame; "bar": the bar must show as well
	static rods := {"Stellarwave Melody": "SwScan SwFishX and", "Halibut Harpoon": "HalibutBarScan HaliFishX and"
		, "Tryhard Rod": "TryhardScan TryFishX and", "Castbound": "CastboundScan CastFishX"
		, "Remembrance": "RemembranceScan RemWhiteX", "MiguRod": "MiguScan MiguFishX bar"}
	if (rods.HasKey(SpecialRod))
		{
		e := StrSplit(rods[SpecialRod], " "), v := e[2]
		ok := Func(e[1]).Call()
		seen := (e[3] = "and" and !ok) ? false : (%v% >= 0 and (e[3] != "bar" or RfBarFind()))
		seen := seen ? true : false
		return true
		}
	if (ControlMode = "Lines")
		{
		LineScan()
		seen := LineFishSeen ? true : false
		return true
		}
	if (SpecialRod = "Verdant Oath")
		{
		seen := (VerdantFishX() >= 0 and VerdantBarScan()) ? true : false
		return true
		}
	return false
}

; The arrow by the Arrow colour setting (tolerance 8 at least): the middle of its first run on the
; scan row, else on five rows down the band. A client x or -1.
RfArrowFind() {
	global ArrowColor, ArrowColorTolerance, CaptureW, CaptureH, BarScanRow
	o := RfColList(ArrowColor)
	if (o.n < 1)
		return -1
	tol := RfAtLeast(ArrowColorTolerance, 8)
	y := (BarScanRow >= 0 and BarScanRow < CaptureH) ? BarScanRow : CaptureH // 2
	ax := RfColRun(o, tol, y, 0, CaptureW - 1, "mid")
	Loop, 5
		if (ax < 0)
			ax := RfColRun(o, tol, Floor(CaptureH * (A_Index * 2 - 1) / 10), 0, CaptureW - 1, "mid")
	return ax
}

; ---- is the reel on screen -------------------------------------------------------------------------

; The reel minigame's bar is showing (sets RunLeft / RunWidth). Without edge colours: the best row's
; stretch, backed by at least 3 rows and no wider than 75 % of the band.
RfReelVisible(minRun) {
	global
	local agree
	if SpecialRod in Castbound,Remembrance,MiguRod,Halibut Harpoon,Tryhard Rod,Stellarwave Melody
		return RfBarFind()
	if (SpecialRod = "Verdant Oath")
		{
		if (!VerdantBarScan())
			return false
		RunLeft := VgBarL, RunWidth := VgBarW
		return true
		}
	if (BarLeftColor != "" and BarRightColor != "")
		return RfBarByColour()
	return (RfBarRowPick(minRun, agree) and agree >= 3 and RunWidth <= CaptureW * 0.75)
}

; How sure is it that the reel minigame is up, 0 to 100: the fish line 55, the bar 40 (5 more when
; its width is plausible), the arrow alone 30. Tranquility: 80 when its rings show. Sets MgConf and
; MgSawFish / MgSawBar / MgSawArrow.
RfReelScore() {
	global
	MgSawBar := false, MgSawFish := false, MgSawArrow := false
	if (SpecialRod = "Tranquility")
		{
		MgSawFish := ManiaVisible()
		MgConf := MgSawFish ? 80 : 0
		return MgConf
		}
	MgSawFish := RfFishLineSeen() ? true : false
	MgSawBar := RfReelVisible(6) ? true : false
	MgSawArrow := (!MgSawFish and !MgSawBar and RfArrowFind() >= 0) ? true : false
	MgConf := Min(100, 55 * MgSawFish + 40 * MgSawBar + 30 * MgSawArrow
		+ 5 * (MgSawBar and RunWidth > 10 and RunWidth < CaptureW * 0.7))
	return MgConf
}

; ---- the edge gate ---------------------------------------------------------------------------------
; The reel frame has a border above and below the track. In the band's extra rows (18 above the
; reel area, 20 below) they show as rows where brightness jumps between 2 rows above and 2 rows
; below. At the start of a fight the gate learns which rows hold them ("learning"), then watches
; those rows ("armed"); when they fade the reel UI is going ("gone"). Where no border can be found it
; watches Fisch's green corner instead ("blind").
; RfGate fields: state, n (calls), learnAt / learnN / accT / accB / cntT / cntB (learning), rowT /
; rowB / peakT / peakB (the rows and their strength), goneAt, greenAt, latched, armAt, fightAt,
; lastGone, phantomAt / knownGood (RfReelSettled), and the sizes set by RfGateSetup.

; Sizes for this session (RfCapSetup calls it): top border candidates in band rows topStart .. 26,
; bottom ones from 5 rows under the reel area to the band's end. Pinions Aria and Darkheart wait
; longer before a gap counts (500 ms, not 130) and need no strong return to end one.
RfGateSetup() {
	global RfGate, CaptureH, WindowHeight, SpecialRod
	slow := (SpecialRod = "Pinions Aria" or SpecialRod = "Darkheart")
	RfGate := {on: true, topRows: 29, botOff: CaptureH + 5, edgeH: CaptureH + 38
		, topStart: Max(2, 18 - Round(WindowHeight * 0.0095)), gateN: 0
		, latchMs: slow ? 500 : 130, resumeF: slow ? 0 : 0.75, knownGood: false}
	RfGateReset()
}

; Back to "off", everything learned forgotten (the sizes and knownGood stay).
RfGateReset() {
	global RfGate
	g := RfGate
	g.state := "off", g.n := 0, g.armAt := 0, g.fightAt := 0, g.lastGone := false, g.phantomAt := 0
	g.goneAt := 0, g.greenAt := 0, g.latched := false, g.rowT := -1, g.rowB := -1, g.peakT := 0, g.peakB := 0
	RfGateRelearn(0)
	g.state := "off", g.n := 0, g.learnAt := 0
}

; Starts learning at the start of a fight.
RfGateStart() {
	global RfGate
	RfGateReset()
	g := RfGate
	if (!g.on)
		{
		g.state := "blind"
		return
		}
	DllCall("QueryPerformanceCounter", "Int64*", now)
	g.learnAt := now, g.fightAt := now, g.state := "learning"
}

; Learning from scratch (from time now).
RfGateRelearn(now) {
	global RfGate
	g := RfGate
	g.state := "learning", g.lastGone := false, g.learnAt := now, g.learnN := 0, g.n := 1
	g.accT := {}, g.accB := {}, g.cntT := {}, g.cntB := {}, g.goneAt := 0, g.greenAt := 0
}

; How much of band row r (0 = the band's first row) is a horizontal edge: the share of columns,
; every step-th, whose brightness 2 rows above and 2 rows below differs by 20 or more. 0 for rows
; outside 2 .. edgeH - 3.
RfEdgeAt(r, step) {
	global pUiEdgeBits, CaptureW, RfGate
	if (!pUiEdgeBits or r < 2 or r > RfGate.edgeH - 3 or CaptureW < 8)
		return 0
	above := pUiEdgeBits + (r - 2) * CaptureW * 4, below := above + CaptureW * 16
	cols := 0, hits := 0, x := 0
	while (x < CaptureW)
		{
		a := NumGet(above + 0, x * 4, "UInt"), b := NumGet(below + 0, x * 4, "UInt")
		hits += Abs(((a & 0xFF) + (a >> 8 & 0xFF) + (a >> 16 & 0xFF)) // 3
			- ((b & 0xFF) + (b >> 8 & 0xFF) + (b >> 16 & 0xFF)) // 3) >= 20
		cols += 1, x += step
		}
	return hits / cols
}

; The strongest edge among rows r0 .. r1 (every rstep-th, columns every cstep-th); its row to row.
RfEdgeBest(r0, r1, rstep, cstep, ByRef row := "") {
	best := 0, row := r0, r := r0
	while (r <= r1)
		{
		f := RfEdgeAt(r, cstep)
		if (f > best)
			best := f, row := r
		r += rstep
		}
	return best
}

; Both borders showing now: one at half strength or more and the other at 35 % or more. Checks
; every other row, alternating which ones from call to call.
RfEdgesShowing() {
	global RfGate
	g := RfGate
	g.gateN := (g.gateN >= 0 and g.gateN < 3) ? g.gateN + 1 : 0
	top := RfEdgeBest(2 + Mod(g.gateN, 2), g.topRows - 3, 2, 8)
	bot := RfEdgeBest(g.botOff + 2 + g.gateN // 2, g.edgeH - 3, 2, 8)
	return (Max(top, bot) >= 0.5 and Min(top, bot) >= 0.35)
}

; Has the reel UI finished sliding in? True once both borders show; if they do not, true anyway
; after 0.5 s (4 s when the borders were found in an earlier fight).
RfReelSettled() {
	global RfGate, QpcFreq
	g := RfGate
	if (RfEdgesShowing())
		{
		g.phantomAt := 0
		return true
		}
	DllCall("QueryPerformanceCounter", "Int64*", now)
	if (!g.phantomAt)
		{
		g.phantomAt := now
		return false
		}
	if ((now - g.phantomAt) / QpcFreq < (g.knownGood ? 4.0 : 0.5))
		return false
	g.phantomAt := 0, g.knownGood := false
	return true
}

; One step of the gate, called once per reel frame: "off", "learning", "present" or "gone".
; Armed, it measures every second call; the green corner is checked every 10th call when blind and
; every 3rd while the borders are missing. Gone: borders missing 500 ms (latched, or still missing
; now), or missing 200 ms with the green corner up 200 ms; blind: the green corner up 800 ms.
RfGateTick() {
	global RfGate, QpcFreq
	g := RfGate
	if (g.state = "off")
		return "off"
	DllCall("QueryPerformanceCounter", "Int64*", now)
	g.n += 1
	if (g.state = "learning")
		return RfGateLearn(g, now)
	if (g.state = "armed" and !Mod(g.n, 2) and RfGateWatch(g, now) = "learning")
		return "learning"
	if ((g.state = "blind" and !Mod(g.n, 10)) or (g.state = "armed" and g.goneAt and !Mod(g.n, 3)))
		g.greenAt := RfGreenCorner() ? (g.greenAt ? g.greenAt : now) : 0
	gone := g.goneAt ? (now - g.goneAt) * 1000.0 / QpcFreq : 0
	green := g.greenAt ? (now - g.greenAt) * 1000.0 / QpcFreq : 0
	if (g.state = "armed" and ((gone >= 500 and (g.latched or g.lastGone)) or (gone >= 200 and green >= 200)))
		return "gone"
	if (g.state = "blind" and green >= 800)
		{
		; no borders to go by: the green corner alone does not end a fight the fish line still shows
		if (!RfFishLineSeen())
			return "gone"
		RfReelLog("green corner up 800 ms but the fish line shows: kept going")
		g.greenAt := 0
		}
	return "present"
}

; Learning: every second call, each candidate row's edge strength is added up (every 3rd row,
; starting one row further each time, so three passes cover all). After 9 passes and 0.5 s the
; strongest top and bottom rows (on average) are taken, each refined to the best of itself and its
; neighbours. Weaker than 0.4: learn again during the first 3 s of the fight, then go blind.
RfGateLearn(g, now) {
	global QpcFreq
	if (!Mod(g.n, 2))
		{
		k := Mod(g.learnN, 3)
		RfGateSample(g.accT, g.cntT, Max(g.topStart, 2) + k, g.topRows - 3)
		RfGateSample(g.accB, g.cntB, g.botOff + 2 + k, g.edgeH - 3)
		g.learnN += 1
		}
	if (g.learnN < 9 or (now - g.learnAt) / QpcFreq < 0.5)
		return "learning"
	RfGateStrongest(g.accT, g.cntT, rowT, peak), g.peakT := peak
	RfGateStrongest(g.accB, g.cntB, rowB, peak), g.peakB := peak
	if (g.peakT < 0.4 or g.peakB < 0.4)
		{
		if ((now - g.fightAt) / QpcFreq < 3.0)
			{
			RfGateRelearn(now)
			return "learning"
			}
		g.state := "blind"
		RfReelLog(Format("edge gate: no clear borders (top {}%, bottom {}%); watching the green corner", Round(100 * g.peakT), Round(100 * g.peakB)))
		return "present"
		}
	RfEdgeBest(rowT - 1, rowT + 1, 1, 2, rowT)
	RfEdgeBest(rowB - 1, rowB + 1, 1, 2, rowB)
	g.rowT := rowT, g.rowB := rowB, g.state := "armed", g.armAt := now, g.knownGood := true
	RfReelLog(Format("edge gate: borders at band rows {} and {} (strength {}%, {}%)", rowT, rowB, Round(100 * g.peakT), Round(100 * g.peakB)))
	return "learning"
}

; Adds the edge strength of rows r, r + 3 .. up to rEnd to their running sums (acc) and counts (cnt).
RfGateSample(acc, cnt, r, rEnd) {
	while (r <= rEnd)
		{
		acc[r] := (acc.HasKey(r) ? acc[r] : 0) + RfEdgeAt(r, 8)
		cnt[r] := (cnt.HasKey(r) ? cnt[r] : 0) + 1
		r += 3
		}
}

; The row with the highest average strength (lowest row on a tie) to row, that average to peak;
; peak 0 and row -1 when nothing was sampled. (peak goes back ByRef: AutoHotkey v1 returns a
; local variable's decimal number as 6-digit text, and the gate compares against it exactly.)
RfGateStrongest(acc, cnt, ByRef row, ByRef peak) {
	peak := -1, row := -1
	for r, sum in acc
		if (sum / cnt[r] > peak)
			peak := sum / cnt[r], row := r
	if (row < 0)
		peak := 0
}

; Armed: reads the two learned rows. Present when the top one is at half its learned strength,
; or at a quarter with the bottom one at half; a gap then ends once both are back to resumeF of
; their strength (or after 500 ms), unless it latched. Missing: the gap starts, and latches after
; latchMs. Missing within 1.5 s of arming while a border shows on other rows: the rows were wrong,
; learn again ("learning"; else "").
; Alpha 1.0: borders that look missing while the fish line still shows are no gap. Something drew
; over the border rows (a flash, an effect, a popup) and the reel is still up; until then a 130 ms
; dip let go of the bar, latched, and ended the fight as "UI gone" mid-fight. A latched gap also
; ends once the fish line is seen again. At a real ending the fish line goes too.
RfGateWatch(g, now) {
	global QpcFreq
	t := RfEdgeAt(g.rowT, 3), b := RfEdgeAt(g.rowB, 3)
	if (t >= 0.5 * g.peakT or (t >= 0.25 * g.peakT and b >= 0.5 * g.peakB))
		{
		g.lastGone := false, g.kept := false
		if (!g.latched and (!g.goneAt or (t >= g.resumeF * g.peakT and b >= g.resumeF * g.peakB)
			or (now - g.goneAt) * 1000.0 / QpcFreq >= 500))
			g.goneAt := 0, g.greenAt := 0
		return ""
		}
	if (RfFishLineSeen())
		{
		if (!g.kept)
			RfReelLog(Format("borders weak (top {}%, bottom {}% of learned) but the fish line shows: kept going"
				, Round(100 * t / g.peakT), Round(100 * b / g.peakB)))
		g.kept := true, g.lastGone := false, g.goneAt := 0, g.greenAt := 0, g.latched := false
		return ""
		}
	if (!g.goneAt)
		RfReelLog(Format("borders weak (top {}%, bottom {}% of learned), no fish line: letting go", Round(100 * t / g.peakT), Round(100 * b / g.peakB)))
	g.lastGone := true, g.kept := false
	if (!g.goneAt)
		g.goneAt := now
	else if ((now - g.goneAt) * 1000.0 / QpcFreq >= g.latchMs)
		{
		if (!g.latched)
			RfReelLog("borders missing " . g.latchMs . " ms: latched (the fight ends in 500 ms unless the fish line returns)")
		g.latched := true
		}
	if (!g.latched and (now - g.armAt) / QpcFreq < 1.5
		and (RfEdgeBest(g.topStart, g.topRows - 3, 1, 8) >= 0.5 * g.peakT
		or RfEdgeBest(g.botOff + 2, g.edgeH - 3, 1, 8) >= 0.5 * g.peakB))
		{
		RfGateRelearn(now)
		return "learning"
		}
	return ""
}

; Should the reel let go now? True once the gate has the reel UI missing, after the mouse buttons
; are released (Bellona's Waraxe's too). tick: run the gate first, as a measuring call, so the answer
; is fresh. Rods with their own UI never stop here; on Darkheart a black frame (a flash) does not
; count.
RfHandsOff(tick) {
	global RfGate, SpecialRod, MaxLeftToggle, MaxRightToggle, BelDown, DarkFlashing
	g := RfGate
	if SpecialRod in Tranquility,Lullaby,Stellarwave Melody
		return false
	if (tick and g.state = "armed")
		{
		g.n += Mod(g.n + 1, 2)
		RfGateTick()
		}
	if (!g.goneAt or (SpecialRod = "Darkheart" and (DarkFlashing or RfBandDark())))
		return false
	MaxLeftToggle := false, MaxRightToggle := false
	RfLetGoLeft()
	if (SpecialRod = "Bellona's Waraxe" and (BelDown[1] or BelDown[2] or GetKeyState("RButton")))
		BellonaRelease()
	return true
}

; Releases the left mouse button if the macro or Windows has it down, noting when (PrecisionUpAt).
RfLetGoLeft() {
	global PrecisionDown, PrecisionUpAt
	if (!PrecisionDown and !GetKeyState("LButton"))
		return
	send {lbutton up}
	PrecisionDown := false
	DllCall("QueryPerformanceCounter", "Int64*", PrecisionUpAt)
}



; ---- Single-row bounded scans -------------------------------------------------------------


; ---- Color-free structural bar detector -----------------------------------------------------


; ---- Minigame presence, scored 0-100 ---------------------------------------------------------

NoteHoldZone(w) {
	z := w * 0.20
	if (z < 10)
		z := 10
	return z
}

;
RemBarScan() {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft, RemembranceMode
	global RemBarScanned, RemBarFound, RemBarL, RemBarW, RemBarRing
	if (RemBarScanned)
		return RemBarFound
	RemBarScanned := true
	RemBarFound := false
	if (CaptureW < 40 or CaptureH < 6)
		return false
	if (RemembranceMode = "Departed")
		{
		bLo := 55
		bHi := 110
		}
	else
		{
		bLo := 145
		bHi := 235
		}
	bRows := [Floor(CaptureH * 0.2), Floor(CaptureH * 0.5), Floor(CaptureH * 0.8)]
	VarSetCapacity(bHits, CaptureW, 0)
	for bI, bY in bRows
		{
		bOff := bY * CaptureW * 4
		bX := 0
		while (bX < CaptureW)
			{
			bP := NumGet(pCaptureBits + 0, bOff + (bX*4), "UInt")
			bB := bP & 0xFF
			bG := (bP >> 8) & 0xFF
			bR := (bP >> 16) & 0xFF
			if (Abs(bR - bG) <= 10 and Abs(bG - bB) <= 10)
				{
				bLum := (bR + bG + bB) // 3
				if (bLum >= bLo and bLum <= bHi)
					NumPut(NumGet(bHits, bX, "UChar") + 1, bHits, bX, "UChar")
				}
			bX++
			}
		}
	bMinRef := Round(CaptureW * 0.08)
	bMaxRef := Round(CaptureW * 0.35)
	if (!IsObject(RemBarRing))
		RemBarRing := []
	bHaveRef := (RemBarRing.MaxIndex() >= 3)
	bRef := bHaveRef ? Round(RfMedian(RemBarRing)) : Round(CaptureW * 0.206)
	bAccLo := bHaveRef ? Round(bRef * 0.7) : bMinRef
	bAccHi := bHaveRef ? Round(bRef * 1.3) : bMaxRef
	bGap := Round(CaptureW * 0.018)
	if (bGap < 6)
		bGap := 6
	bBestL := -1
	bBestLen := 0
	bRunS := -1
	bLast := -1
	bX := 0
	while (bX <= CaptureW)
		{
		bOn := false
		if (bX < CaptureW)
			bOn := (NumGet(bHits, bX, "UChar") >= 2)
		if (bOn)
			{
			if (bRunS < 0)
				bRunS := bX
			bLast := bX
			}
		else if (bRunS >= 0 and ((bX - bLast) > bGap or bX = CaptureW))
			{
			if ((bLast - bRunS + 1) > bBestLen)
				{
				bBestLen := bLast - bRunS + 1
				bBestL := bRunS
				}
			bRunS := -1
			}
		bX++
		}
	if (bBestL >= 0 and bBestLen >= bAccLo and bBestLen <= bAccHi)
		{
		RemBarL := FishBarLeft + bBestL
		RemBarW := bBestLen
		RemBarRing.Push(bBestLen)
		if (RemBarRing.MaxIndex() > 5)
			RemBarRing.RemoveAt(1)
		RemBarFound := true
		return true
		}
	bSum := 0
	bBest := -1
	bBestSum := 0
	bX := 0
	while (bX < CaptureW)
		{
		bSum := bSum + NumGet(bHits, bX, "UChar")
		if (bX >= bRef)
			bSum := bSum - NumGet(bHits, bX - bRef, "UChar")
		if (bX >= bRef - 1 and bSum > bBestSum)
			{
			bBestSum := bSum
			bBest := bX - bRef + 1
			}
		bX++
		}
	if (bBest < 0 or bBestSum < bRef * 3 * 0.45)
		return false
	RemBarL := FishBarLeft + bBest
	RemBarW := bRef
	RemBarFound := true
	return true
}

RemembranceScan() {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft, BarScanRow
	global FishColor, FishBarColorTolerance
	global RemWhiteX, RemBlackX, RemTargetX, RemScanned, RemFound
	if (RemScanned)
		return RemFound
	RemScanned := true
	RemFound := false
	RemWhiteX := -1
	RemBlackX := -1
	RemTargetX := -1
	if (CaptureW < 40 or CaptureH < 6)
		return false

	rRows := []
	Loop, 5
		{
		ry := Floor(CaptureH * (A_Index*2 - 1) / 10)
		if (ry >= CaptureH)
			ry := CaptureH - 1
		rRows.Push(ry)
		}

	wList := RfColList(FishColor)
	if (wList.n < 1)
		wList := RfColList("0xFFFFFF")
	wR := wList.r[1]
	wG := wList.g[1]
	wB := wList.b[1]
	wTol := FishBarColorTolerance
	if (wTol < 6)
		wTol := 6
	wMaxW := Round(CaptureW * 0.03)
	if (wMaxW < 8)
		wMaxW := 8
	wBestX := -1
	wBestV := 0
	for wPass, wRowI in [3, 2, 4]
		{
		wRy := rRows[wRowI]
		wOff := wRy * CaptureW * 4
		wRunS := -1
		wX := 0
		while (wX <= CaptureW)
			{
			wHit := false
			if (wX < CaptureW)
				{
				wPx := NumGet(pCaptureBits + 0, wOff + (wX*4), "UInt")
				wHit := (Abs(((wPx >> 16) & 0xFF) - wR) <= wTol and Abs(((wPx >> 8) & 0xFF) - wG) <= wTol and Abs((wPx & 0xFF) - wB) <= wTol)
				}
			if (wHit)
				{
				if (wRunS < 0)
					wRunS := wX
				}
			else if (wRunS >= 0)
				{
				wRunW := wX - wRunS
				if (wRunW >= 2 and wRunW <= wMaxW)
					{
					wCx := wRunS + (wRunW // 2)
					wVotes := 0
					for rI, ry in rRows
						{
						if (RemWhiteAt(wCx, ry, wR, wG, wB, wTol))
							wVotes++
						}
					if (wVotes > wBestV)
						{
						wBestV := wVotes
						wBestX := wCx
						}
					}
				wRunS := -1
				}
			wX++
			}
		if (wBestV >= 4)
			break
		}
	if (wBestV < 4)
		return false
	RemWhiteX := FishBarLeft + wBestX

	rOff := Round(CaptureW * 0.02)
	if (rOff < 8)
		rOff := 8
	bX := -1
	bV := 0
	rx := rOff
	while (rx < CaptureW - rOff)
		{
		if (IsDarkNotch(rx, BarScanRow, rOff))
			{
			rVotes := 0
			for rI, ry in rRows
				{
				if (IsDarkNotch(rx, ry, rOff))
					rVotes++
				}
			if (rVotes >= 3 and rVotes > bV)
				{
				bV := rVotes
				bX := rx
				}
			}
		rx++
		}
	if (bX >= 0)
		RemBlackX := FishBarLeft + bX

	RemFound := true
	RemTargetX := RemAimX(RemWhiteX, RemBlackX)
	return true
}

RemWhiteAt(hx, hy, hr, hg, hb, htol) {
	global pCaptureBits, CaptureW, CaptureH
	if (hy < 0 or hy >= CaptureH)
		return false
	hOff := hy * CaptureW * 4
	hI := hx - 5
	if (hI < 0)
		hI := 0
	hE := hx + 5
	if (hE > CaptureW - 1)
		hE := CaptureW - 1
	while (hI <= hE)
		{
		hP := NumGet(pCaptureBits + 0, hOff + (hI*4), "UInt")
		if (Abs(((hP >> 16) & 0xFF) - hr) <= htol and Abs(((hP >> 8) & 0xFF) - hg) <= htol and Abs((hP & 0xFF) - hb) <= htol)
			return true
		hI++
		}
	return false
}

RemAimX(wx, bx) {
	global RunWidth, RemembranceMode
	rHalf := RunWidth / 2
	if (rHalf < 4 or bx < 0)
		return wx
	rDep := (RemembranceMode = "Departed")
	rClear := rHalf + (rDep ? (RunWidth * 0.15) : (RunWidth * 0.06))
	if (Abs(bx - wx) > rClear + rHalf)
		return wx
	if (bx > wx)
		{
		rAim := bx - rClear
		if (!rDep)
			{
			rLo := wx - rHalf + 2
			if (rAim < rLo)
				rAim := rLo
			}
		return rAim
		}
	rAim := bx + rClear
	if (!rDep)
		{
		rHi := wx + rHalf - 2
		if (rAim > rHi)
			rAim := rHi
		}
	return rAim
}

HalibutBarScan() {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft
	global HaliBarScanned, HaliBarFound, HaliBarL, HaliBarW, HaliFishX
	if (HaliBarScanned)
		return HaliBarFound
	HaliBarScanned := true
	HaliBarFound := false
	HaliFishX := -1
	if (CaptureW < 40 or CaptureH < 8)
		return false
	hRows := [Floor(CaptureH * 0.28), Floor(CaptureH * 0.38), Floor(CaptureH * 0.78), Floor(CaptureH * 0.88)]
	VarSetCapacity(hBar, CaptureW, 0)
	VarSetCapacity(hDark, CaptureW, 0)
	hTrk := 0
	for hI, hY in hRows
		{
		p := pCaptureBits + (hY * CaptureW * 4)
		x := 0
		while (x < CaptureW)
			{
			px := NumGet(p + 0, x * 4, "UInt"), b := px & 0xFF, g := (px >> 8) & 0xFF, r := (px >> 16) & 0xFF
			if (Abs(r - 0x53) <= 12 and Abs(g - 0x48) <= 12 and Abs(b - 0xA0) <= 14)
				NumPut(NumGet(hBar, x, "UChar") + 1, hBar, x, "UChar")
			else if (Abs(r - 0x2A) <= 12 and Abs(g - 0x26) <= 12 and Abs(b - 0x75) <= 14)
				hTrk++
			else
				{
				mx := (r > g) ? r : g
				mx := (b > mx) ? b : mx
				mn := (r < g) ? r : g
				mn := (b < mn) ? b : mn
				if (mx < 60 and mx - mn <= 10)
					NumPut(NumGet(hDark, x, "UChar") + 1, hDark, x, "UChar")
				}
			x++
			}
		}
	if (hTrk < CaptureW * 0.6)
		return false

	hGap := Round(CaptureW * 0.03)
	if (hGap < 12)
		hGap := 12
	hBestL := -1, hBestLen := 0, hRunS := -1, hLast := -1
	x := 0
	while (x <= CaptureW)
		{
		if (x < CaptureW and NumGet(hBar, x, "UChar") >= 2)
			{
			if (hRunS < 0)
				hRunS := x
			hLast := x
			}
		else if (hRunS >= 0 and ((x - hLast) > hGap or x = CaptureW))
			{
			if ((hLast - hRunS + 1) > hBestLen)
				{
				hBestLen := hLast - hRunS + 1
				hBestL := hRunS
				}
			hRunS := -1
			}
		x++
		}

	hMaxFW := Round(CaptureW * 0.02)
	if (hMaxFW < 12)
		hMaxFW := 12
	hBestHits := 0, hRunS := -1, hHits := 0
	x := 0
	while (x <= CaptureW)
		{
		hd := (x < CaptureW) ? NumGet(hDark, x, "UChar") : 0
		if (hd >= 2)
			{
			if (hRunS < 0)
				hRunS := x, hHits := 0
			hHits += hd
			}
		else if (hRunS >= 0)
			{
			if ((x - hRunS) <= hMaxFW and hHits > hBestHits)
				{
				hBestHits := hHits
				HaliFishX := FishBarLeft + ((hRunS + x - 1) / 2)
				}
			hRunS := -1
			}
		x++
		}

	if (hBestL < 0 or hBestLen < CaptureW * 0.08 or hBestLen > CaptureW * 0.85)
		return false
	HaliBarL := FishBarLeft + hBestL
	HaliBarW := hBestLen
	HaliBarFound := true
	return true
}

TryRowRuns(p, ByRef prm, ByRef prmI, gap, rr) {
	global CaptureW
	x := 0
	n := 0
	s0 := -1
	e0 := -1
	while (x < CaptureW and n < 40)
		{
		s := PcFind(p + x * 4, CaptureW - x, 4, prm)
		if (s < 0)
			break
		s += x
		e := PcFind(p + (s + 1) * 4, CaptureW - s - 1, 4, prmI)
		e := (e < 0) ? CaptureW - 1 : s + e
		n++
		if (s0 >= 0 and s - e0 - 1 <= gap)
			e0 := e
		else
			{
			if (s0 >= 0)
				rr.Push([s0, e0])
			s0 := s
			e0 := e
			}
		x := e + 1
		}
	if (s0 >= 0)
		rr.Push([s0, e0])
}

TryTrackAt(x) {
	global pCaptureBits, CaptureW, CaptureH
	if (x < 0 or x >= CaptureW)
		return false
	tkN := 0
	for tkI, tkY in [Floor(CaptureH * 0.30), Floor(CaptureH * 0.50), Floor(CaptureH * 0.70)]
		{
		tkPx := NumGet(pCaptureBits + (tkY * CaptureW + x) * 4, 0, "UInt")
		tkB := tkPx & 0xFF
		tkG := (tkPx >> 8) & 0xFF
		tkR := (tkPx >> 16) & 0xFF
		if (tkR + 16 >= tkB and tkR < 70 and tkB < 70 and (tkG < 40 or (tkG < 48 and tkR >= tkG)))
			tkN++
		}
	return (tkN >= 2)
}

TryTrackPx(px) {
	tpB := px & 0xFF
	tpG := (px >> 8) & 0xFF
	tpR := (px >> 16) & 0xFF
	return (tpR + 16 >= tpB and tpR < 70 and tpB < 70 and tpG >= 18 and (tpG < 40 or (tpG < 48 and tpR >= tpG)))
}

TryGapBright(p, a, b) {
	global CaptureW
	if (a > b or b - a + 1 > CaptureW * 0.06)
		return false
	gbN := b - a + 1
	gbHi := 0
	while (a <= b)
		{
		if (((NumGet(p + a * 4, 0, "UInt") >> 16) & 0xFF) >= 140)
			gbHi++
		a++
		}
	return (gbHi = gbN or (gbN <= CaptureW * 0.03 and gbHi >= 2 and gbHi * 5 >= gbN))
}

TryhardScan() {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft, WindowHeight, LastFishX
	global TryScanned, TryFound, TryFishX, TryBarL, TryBarW, TryPrmReady
	global TryPrm1, TryPrm1I, TryPrm2, TryPrm2I, TryPrm3, TryPrm3I, TryPrmF, TryPrmFI, TryPrmT, TryPrmTI
	global TryhardBarColors, TryhardFishColors, TryhardTrackColors
	if ((TryhardBarColors != "" or TryhardFishColors != "" or TryhardTrackColors != "")
		and RfColCount(TryhardBarColors) + RfColCount(TryhardFishColors) + RfColCount(TryhardTrackColors) > 0)
		return TryhardScanX()
	if (TryScanned)
		return TryFound
	TryScanned := true
	TryFound := false
	TryFishX := -1
	if (!pCaptureBits or CaptureW < 40 or CaptureH < 6)
		return false
	if (!TryPrmReady)
		{
		PcSetPrm(TryPrm1, "0x33030B", 14, 0, 0)
		PcSetPrm(TryPrm1I, "0x33030B", 14, 0, 1)
		PcSetPrm(TryPrm2, "0x5F020A", 30, 0, 0)
		PcSetPrm(TryPrm2I, "0x5F020A", 30, 0, 1)
		PcSetPrm(TryPrm3, "0xBE0C0E", 66, 0, 0)
		PcSetPrm(TryPrm3I, "0xBE0C0E", 66, 0, 1)
		PcSetPrm(TryPrmF, "0x2F020C", 14, 0, 0)
		PcSetPrm(TryPrmFI, "0x2F020C", 14, 0, 1)
		PcSetPrm(TryPrmT, "0x3A0608", 14, 0, 0)
		PcSetPrm(TryPrmTI, "0x3A0608", 14, 0, 1)
		TryPrmReady := true
		}
	tfMaxW := Round(CaptureW * 0.02)
	tfNear := Round(CaptureW * 0.003) + 1
	tfC := []
	for tfI, tfO in [Round(WindowHeight * 0.0028), Round(WindowHeight * 0.0049), Round(WindowHeight * 0.0069)]
		{
		if (tfO < 1 or tfO > 17)
			continue
		tfR := []
		TryRowRuns(pCaptureBits - tfO * CaptureW * 4, TryPrmF, TryPrmFI, 1, tfR)
		for tfK, tfV in tfR
			{
			if (tfV[2] - tfV[1] + 1 >= 3 and tfV[2] - tfV[1] + 1 <= tfMaxW)
				tfC.Push([(tfV[1] + tfV[2]) / 2, tfI])
			}
		}
	tfBest := -1
	tfBestD := 999999
	for tfK, tfV in tfC
		{
		tfSeen := 1 << tfV[2]
		for tfK2, tfV2 in tfC
			{
			if (Abs(tfV2[1] - tfV[1]) <= tfNear)
				tfSeen := tfSeen | (1 << tfV2[2])
			}
		if (((tfSeen >> 1) & 1) + ((tfSeen >> 2) & 1) + ((tfSeen >> 3) & 1) >= 2)
			{
			tfD := (LastFishX >= 0) ? Abs(FishBarLeft + tfV[1] - LastFishX) : Abs(tfV[1] - CaptureW / 2)
			if (tfD < tfBestD)
				{
				tfBestD := tfD
				tfBest := tfV[1]
				}
			}
		}
	if (tfBest >= 0)
		{
		TryFishX := FishBarLeft + tfBest
		LastFishX := TryFishX
		}
	tbGap := Round(CaptureW * 0.006)
	tbMinW := Round(CaptureW * 0.02)
	if (tbMinW < 12)
		tbMinW := 12
	tbLs := []
	tbRs := []
	for tbI, tbY in [Floor(CaptureH * 0.30), Floor(CaptureH * 0.50), Floor(CaptureH * 0.70)]
		{
		tbP := pCaptureBits + tbY * CaptureW * 4
		tbR := []
		TryRowRuns(tbP, TryPrm1, TryPrm1I, 0, tbR)
		TryRowRuns(tbP, TryPrm2, TryPrm2I, 0, tbR)
		TryRowRuns(tbP, TryPrm3, TryPrm3I, 0, tbR)
		tbJ := 2
		while (tbJ <= tbR.Length())
			{
			tbV := tbR[tbJ]
			tbK := tbJ - 1
			while (tbK >= 1 and tbR[tbK][1] > tbV[1])
				{
				tbR[tbK + 1] := tbR[tbK]
				tbK--
				}
			tbR[tbK + 1] := tbV
			tbJ++
			}
		tbA := -1
		tbB := -1
		tbS := -1
		tbE := -1
		for tbK, tbV in tbR
			{
			if (tbS >= 0 and (tbV[1] - tbE - 1 <= tbGap or TryGapBright(tbP, tbE + 1, tbV[1] - 1)))
				{
				if (tbV[2] > tbE)
					tbE := tbV[2]
				}
			else
				{
				if (tbS >= 0 and tbE - tbS > tbB - tbA)
					{
					tbA := tbS
					tbB := tbE
					}
				tbS := tbV[1]
				tbE := tbV[2]
				}
			}
		if (tbS >= 0 and tbE - tbS > tbB - tbA)
			{
			tbA := tbS
			tbB := tbE
			}
		if (tbA >= 0 and tbB - tbA + 1 >= tbMinW and tbB - tbA + 1 <= CaptureW * 0.6)
			{
			tbLs.Push(tbA)
			tbRs.Push(tbB)
			}
		}
	if (tbLs.Length() < 2)
		return false
	tbA := (tbLs.Length() = 3) ? RfMedian(tbLs) : ((tbLs[1] > tbLs[2]) ? tbLs[1] : tbLs[2])
	tbB := (tbRs.Length() = 3) ? RfMedian(tbRs) : ((tbRs[1] < tbRs[2]) ? tbRs[1] : tbRs[2])
	tbO := Round(CaptureW * 0.006) + 2
	tbTL := TryTrackAt(tbA - tbO)
	tbTR := TryTrackAt(tbB + tbO)
	if (!(tbTL or tbA - tbO < 0) or !(tbTR or tbB + tbO >= CaptureW) or !(tbTL or tbTR))
		return false
	if (tfBest >= 0)
		{
		tbP := pCaptureBits + Floor(CaptureH * 0.50) * CaptureW * 4
		tbSum := 0
		Loop, 8
			tbSum += (NumGet(tbP + Round(tbA + (tbB - tbA) * (A_Index + 1) / 10) * 4, 0, "UInt") >> 16) & 0xFF
		if (tbSum <= 8 * 90)
			{
			tbPh := Round(CaptureW * 0.006)
			if (tfBest >= tbA - tbPh and tfBest <= tbA + tbPh + 2)
				tbA := Round(tfBest + tbPh + 1)
			else if (tfBest >= tbB - tbPh - 2 and tfBest <= tbB + tbPh)
				tbB := Round(tfBest - tbPh - 1)
			}
		}
	if (tbB - tbA + 1 < tbMinW)
		return false
	if (tfBest < 0)
		{
		tqC := []
		for tqI, tqY in [Floor(CaptureH * 0.30), Floor(CaptureH * 0.50), Floor(CaptureH * 0.70)]
			{
			tqP := pCaptureBits + tqY * CaptureW * 4
			tqSum := 0
			tqN := 0
			tqX := tbA + 2
			while (tqX <= tbB - 2)
				{
				tqPx := NumGet(tqP + tqX * 4, 0, "UInt")
				tqR := (tqPx >> 16) & 0xFF
				if (tqR > ((tqPx >> 8) & 0xFF) + 60 and tqR > (tqPx & 0xFF) + 60)
					{
					tqSum += tqR
					tqN++
					}
				tqX++
				}
			if (tqN < 8)
				continue
			tqRef := tqSum / tqN
			if (tqRef < 110)
				continue
			tqS := -1
			tqX := tbA + 2
			while (tqX <= tbB - 1)
				{
				tqPx := (tqX <= tbB - 2) ? NumGet(tqP + tqX * 4, 0, "UInt") : 0xFFFFFF
				tqR := (tqPx >> 16) & 0xFF
				tqD := (tqR < tqRef * 0.72 and ((tqPx >> 8) & 0xFF) < 40 and (tqPx & 0xFF) < 40)
				if (tqD and tqS < 0)
					tqS := tqX
				else if (!tqD and tqS >= 0)
					{
					if (tqX - tqS >= 3 and tqX - tqS <= tfMaxW)
						tqC.Push([(tqS + tqX - 1) / 2, tqI, (tqS <= tbA + 2 or tqX >= tbB - 1) ? 100000 : 0])
					tqS := -1
					}
				tqX++
				}
			}
		tqBestD := 999999
		for tqK, tqV in tqC
			{
			tqSeen := 1 << tqV[2]
			for tqK2, tqV2 in tqC
				{
				if (Abs(tqV2[1] - tqV[1]) <= tfNear)
					tqSeen := tqSeen | (1 << tqV2[2])
				}
			if (((tqSeen >> 1) & 1) + ((tqSeen >> 2) & 1) + ((tqSeen >> 3) & 1) >= 2)
				{
				tqD := (LastFishX >= 0) ? Abs(FishBarLeft + tqV[1] - LastFishX) + tqV[3] : Abs(tqV[1] - (tbA + tbB) / 2) + tqV[3]
				if (tqD < tqBestD)
					{
					tqBestD := tqD
					tfBest := tqV[1]
					}
				}
			}
		if (tfBest >= 0)
			{
			TryFishX := FishBarLeft + tfBest
			LastFishX := TryFishX
			}
		}
	if (tfBest < 0)
		{
		ttC := []
		ttK := Round(CaptureW * 0.003) + 2
		for ttI, ttY in [Floor(CaptureH * 0.30), Floor(CaptureH * 0.50), Floor(CaptureH * 0.70)]
			{
			ttP := pCaptureBits + ttY * CaptureW * 4
			ttR := []
			TryRowRuns(ttP, TryPrmT, TryPrmTI, 1, ttR)
			for ttJ, ttV in ttR
				{
				if (ttV[2] - ttV[1] + 1 < 2 or ttV[2] - ttV[1] + 1 > tfMaxW)
					continue
				if (ttV[2] >= tbA - tbO and ttV[1] <= tbB + tbO)
					continue
				if (ttV[1] - ttK < 0 or ttV[2] + ttK >= CaptureW)
					continue
				if (TryTrackPx(NumGet(ttP + (ttV[1] - ttK) * 4, 0, "UInt")) and TryTrackPx(NumGet(ttP + (ttV[2] + ttK) * 4, 0, "UInt")))
					ttC.Push([(ttV[1] + ttV[2]) / 2, ttI])
				}
			}
		ttBestD := 999999
		for ttJ, ttV in ttC
			{
			ttSeen := 1 << ttV[2]
			for ttJ2, ttV2 in ttC
				{
				if (Abs(ttV2[1] - ttV[1]) <= tfNear)
					ttSeen := ttSeen | (1 << ttV2[2])
				}
			if (((ttSeen >> 1) & 1) + ((ttSeen >> 2) & 1) + ((ttSeen >> 3) & 1) >= 2)
				{
				ttD := (LastFishX >= 0) ? Abs(FishBarLeft + ttV[1] - LastFishX) : Abs(ttV[1] - (tbA + tbB) / 2)
				if (ttD < ttBestD)
					{
					ttBestD := ttD
					tfBest := ttV[1]
					}
				}
			}
		if (tfBest >= 0)
			{
			TryFishX := FishBarLeft + tfBest
			LastFishX := TryFishX
			}
		}
	TryBarL := FishBarLeft + tbA
	TryBarW := tbB - tbA + 1
	TryFound := true
	return true
}

TryhardScanX() {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft, WindowHeight, LastFishX
	global TryScanned, TryFound, TryFishX, TryBarL, TryBarW, TryPrmReady
	global TryPrm1, TryPrm1I, TryPrm2, TryPrm2I, TryPrm3, TryPrm3I, TryPrmF, TryPrmFI, TryPrmT, TryPrmTI
	global TryhardBarColors, TryhardBarTol, TryhardFishColors, TryhardFishTol, TryhardTrackColors, TryXKey, TryXBuf, TryXNB, TryXNF
	if (TryScanned)
		return TryFound
	TryScanned := true
	TryFound := false
	TryFishX := -1
	if (!pCaptureBits or CaptureW < 40 or CaptureH < 6)
		return false
	if (!TryPrmReady)
		{
		PcSetPrm(TryPrm1, "0x33030B", 14, 0, 0)
		PcSetPrm(TryPrm1I, "0x33030B", 14, 0, 1)
		PcSetPrm(TryPrm2, "0x5F020A", 30, 0, 0)
		PcSetPrm(TryPrm2I, "0x5F020A", 30, 0, 1)
		PcSetPrm(TryPrm3, "0xBE0C0E", 66, 0, 0)
		PcSetPrm(TryPrm3I, "0xBE0C0E", 66, 0, 1)
		PcSetPrm(TryPrmF, "0x2F020C", 14, 0, 0)
		PcSetPrm(TryPrmFI, "0x2F020C", 14, 0, 1)
		PcSetPrm(TryPrmT, "0x3A0608", 14, 0, 0)
		PcSetPrm(TryPrmTI, "0x3A0608", 14, 0, 1)
		TryPrmReady := true
		}
	txKey := TryhardBarColors . "|" . TryhardBarTol . "|" . TryhardFishColors . "|" . TryhardFishTol . "|" . TryhardTrackColors
	if (txKey != TryXKey)
		{
		TryXKey := txKey
		txB := RfColList(TryhardBarColors)
		txF := RfColList(TryhardFishColors)
		txT := RfColList(TryhardTrackColors)
		TryXNB := (txB.n > 9) ? 9 : txB.n
		TryXNF := (txF.n > 9) ? 9 : txF.n
		VarSetCapacity(TryXBuf, 48 * (TryXNB + TryXNF + 1), 0)
		Loop, % TryXNB
			PcPrmAt(&TryXBuf + 48 * (A_Index - 1), txB.r[A_Index], txB.g[A_Index], txB.b[A_Index], RodCap(txB, A_Index, txT, RodTol(TryhardBarTol)), 0)
		Loop, % TryXNF
			PcPrmAt(&TryXBuf + 48 * (TryXNB + A_Index - 1), txF.r[A_Index], txF.g[A_Index], txF.b[A_Index], RodTol(TryhardFishTol), 0)
		}
	tfMaxW := Round(CaptureW * 0.02)
	tfNear := Round(CaptureW * 0.003) + 1
	tfC := []
	for tfI, tfO in [Round(WindowHeight * 0.0028), Round(WindowHeight * 0.0049), Round(WindowHeight * 0.0069)]
		{
		if (tfO < 1 or tfO > 17)
			continue
		tfR := []
		TryRowRuns(pCaptureBits - tfO * CaptureW * 4, TryPrmF, TryPrmFI, 1, tfR)
		Loop, % TryXNF
			TryRowRunsAt(pCaptureBits - tfO * CaptureW * 4, &TryXBuf + 48 * (TryXNB + A_Index - 1), 1, tfR)
		if (TryXNF)
			TryRunsMerge(tfR, 1)
		for tfK, tfV in tfR
			{
			if (tfV[2] - tfV[1] + 1 >= 3 and tfV[2] - tfV[1] + 1 <= tfMaxW)
				tfC.Push([(tfV[1] + tfV[2]) / 2, tfI])
			}
		}
	if (TryXNF)
		{
		tvK := Round(CaptureW * 0.012) + 2
		tvC := []
		for tfK, tfV in tfC
			{
			if (TryFishLineAt(Round(tfV[1]), tvK))
				tvC.Push(tfV)
			}
		tfC := tvC
		}
	tfBest := -1
	tfBestD := 999999
	for tfK, tfV in tfC
		{
		tfSeen := 1 << tfV[2]
		for tfK2, tfV2 in tfC
			{
			if (Abs(tfV2[1] - tfV[1]) <= tfNear)
				tfSeen := tfSeen | (1 << tfV2[2])
			}
		if (((tfSeen >> 1) & 1) + ((tfSeen >> 2) & 1) + ((tfSeen >> 3) & 1) >= 2)
			{
			tfD := (LastFishX >= 0) ? Abs(FishBarLeft + tfV[1] - LastFishX) : Abs(tfV[1] - CaptureW / 2)
			if (tfD < tfBestD)
				{
				tfBestD := tfD
				tfBest := tfV[1]
				}
			}
		}
	if (tfBest >= 0)
		{
		TryFishX := FishBarLeft + tfBest
		LastFishX := TryFishX
		}
	tbGap := Round(CaptureW * 0.006)
	tbMinW := Round(CaptureW * 0.02)
	if (tbMinW < 12)
		tbMinW := 12
	tbLs := []
	tbRs := []
	for tbI, tbY in [Floor(CaptureH * 0.30), Floor(CaptureH * 0.50), Floor(CaptureH * 0.70)]
		{
		tbP := pCaptureBits + tbY * CaptureW * 4
		tbR := []
		TryRowRuns(tbP, TryPrm1, TryPrm1I, 0, tbR)
		TryRowRuns(tbP, TryPrm2, TryPrm2I, 0, tbR)
		TryRowRuns(tbP, TryPrm3, TryPrm3I, 0, tbR)
		Loop, % TryXNB
			TryRowRunsAt(tbP, &TryXBuf + 48 * (A_Index - 1), 0, tbR)
		tbJ := 2
		while (tbJ <= tbR.Length())
			{
			tbV := tbR[tbJ]
			tbK := tbJ - 1
			while (tbK >= 1 and tbR[tbK][1] > tbV[1])
				{
				tbR[tbK + 1] := tbR[tbK]
				tbK--
				}
			tbR[tbK + 1] := tbV
			tbJ++
			}
		tbA := -1
		tbB := -1
		tbS := -1
		tbE := -1
		for tbK, tbV in tbR
			{
			if (tbS >= 0 and (tbV[1] - tbE - 1 <= tbGap or TryGapBright(tbP, tbE + 1, tbV[1] - 1)))
				{
				if (tbV[2] > tbE)
					tbE := tbV[2]
				}
			else
				{
				if (tbS >= 0 and tbE - tbS > tbB - tbA)
					{
					tbA := tbS
					tbB := tbE
					}
				tbS := tbV[1]
				tbE := tbV[2]
				}
			}
		if (tbS >= 0 and tbE - tbS > tbB - tbA)
			{
			tbA := tbS
			tbB := tbE
			}
		if (tbA >= 0 and tbB - tbA + 1 >= tbMinW and tbB - tbA + 1 <= CaptureW * 0.6)
			{
			tbLs.Push(tbA)
			tbRs.Push(tbB)
			}
		}
	if (tbLs.Length() < 2)
		return false
	tbA := (tbLs.Length() = 3) ? RfMedian(tbLs) : ((tbLs[1] > tbLs[2]) ? tbLs[1] : tbLs[2])
	tbB := (tbRs.Length() = 3) ? RfMedian(tbRs) : ((tbRs[1] < tbRs[2]) ? tbRs[1] : tbRs[2])
	tbO := Round(CaptureW * 0.006) + 2
	tbTL := TryTrackAtX(tbA - tbO)
	tbTR := TryTrackAtX(tbB + tbO)
	if (!(tbTL or tbA - tbO < 0) or !(tbTR or tbB + tbO >= CaptureW) or !(tbTL or tbTR))
		return false
	if (tfBest >= 0)
		{
		tbP := pCaptureBits + Floor(CaptureH * 0.50) * CaptureW * 4
		tbSum := 0
		Loop, 8
			tbSum += (NumGet(tbP + Round(tbA + (tbB - tbA) * (A_Index + 1) / 10) * 4, 0, "UInt") >> 16) & 0xFF
		if (tbSum <= 8 * 90)
			{
			tbPh := Round(CaptureW * 0.006)
			if (tfBest >= tbA - tbPh and tfBest <= tbA + tbPh + 2)
				tbA := Round(tfBest + tbPh + 1)
			else if (tfBest >= tbB - tbPh - 2 and tfBest <= tbB + tbPh)
				tbB := Round(tfBest - tbPh - 1)
			}
		}
	if (tbB - tbA + 1 < tbMinW)
		return false
	if (tfBest < 0)
		{
		tqC := []
		for tqI, tqY in [Floor(CaptureH * 0.30), Floor(CaptureH * 0.50), Floor(CaptureH * 0.70)]
			{
			tqP := pCaptureBits + tqY * CaptureW * 4
			tqSum := 0
			tqN := 0
			tqX := tbA + 2
			while (tqX <= tbB - 2)
				{
				tqPx := NumGet(tqP + tqX * 4, 0, "UInt")
				tqR := (tqPx >> 16) & 0xFF
				if (tqR > ((tqPx >> 8) & 0xFF) + 60 and tqR > (tqPx & 0xFF) + 60)
					{
					tqSum += tqR
					tqN++
					}
				tqX++
				}
			if (tqN < 8)
				continue
			tqRef := tqSum / tqN
			if (tqRef < 110)
				continue
			tqS := -1
			tqX := tbA + 2
			while (tqX <= tbB - 1)
				{
				tqPx := (tqX <= tbB - 2) ? NumGet(tqP + tqX * 4, 0, "UInt") : 0xFFFFFF
				tqR := (tqPx >> 16) & 0xFF
				tqD := (tqR < tqRef * 0.72 and ((tqPx >> 8) & 0xFF) < 40 and (tqPx & 0xFF) < 40)
				if (tqD and tqS < 0)
					tqS := tqX
				else if (!tqD and tqS >= 0)
					{
					if (tqX - tqS >= 3 and tqX - tqS <= tfMaxW)
						tqC.Push([(tqS + tqX - 1) / 2, tqI, (tqS <= tbA + 2 or tqX >= tbB - 1) ? 100000 : 0])
					tqS := -1
					}
				tqX++
				}
			}
		tqBestD := 999999
		for tqK, tqV in tqC
			{
			tqSeen := 1 << tqV[2]
			for tqK2, tqV2 in tqC
				{
				if (Abs(tqV2[1] - tqV[1]) <= tfNear)
					tqSeen := tqSeen | (1 << tqV2[2])
				}
			if (((tqSeen >> 1) & 1) + ((tqSeen >> 2) & 1) + ((tqSeen >> 3) & 1) >= 2)
				{
				tqD := (LastFishX >= 0) ? Abs(FishBarLeft + tqV[1] - LastFishX) + tqV[3] : Abs(tqV[1] - (tbA + tbB) / 2) + tqV[3]
				if (tqD < tqBestD)
					{
					tqBestD := tqD
					tfBest := tqV[1]
					}
				}
			}
		if (tfBest >= 0)
			{
			TryFishX := FishBarLeft + tfBest
			LastFishX := TryFishX
			}
		}
	if (tfBest < 0)
		{
		ttC := []
		ttK := Round(CaptureW * 0.003) + 2
		for ttI, ttY in [Floor(CaptureH * 0.30), Floor(CaptureH * 0.50), Floor(CaptureH * 0.70)]
			{
			ttP := pCaptureBits + ttY * CaptureW * 4
			ttR := []
			TryRowRuns(ttP, TryPrmT, TryPrmTI, 1, ttR)
			for ttJ, ttV in ttR
				{
				if (ttV[2] - ttV[1] + 1 < 2 or ttV[2] - ttV[1] + 1 > tfMaxW)
					continue
				if (ttV[2] >= tbA - tbO and ttV[1] <= tbB + tbO)
					continue
				if (ttV[1] - ttK < 0 or ttV[2] + ttK >= CaptureW)
					continue
				if (TryTrackPx(NumGet(ttP + (ttV[1] - ttK) * 4, 0, "UInt")) and TryTrackPx(NumGet(ttP + (ttV[2] + ttK) * 4, 0, "UInt")))
					ttC.Push([(ttV[1] + ttV[2]) / 2, ttI])
				}
			}
		ttBestD := 999999
		for ttJ, ttV in ttC
			{
			ttSeen := 1 << ttV[2]
			for ttJ2, ttV2 in ttC
				{
				if (Abs(ttV2[1] - ttV[1]) <= tfNear)
					ttSeen := ttSeen | (1 << ttV2[2])
				}
			if (((ttSeen >> 1) & 1) + ((ttSeen >> 2) & 1) + ((ttSeen >> 3) & 1) >= 2)
				{
				ttD := (LastFishX >= 0) ? Abs(FishBarLeft + ttV[1] - LastFishX) : Abs(ttV[1] - (tbA + tbB) / 2)
				if (ttD < ttBestD)
					{
					ttBestD := ttD
					tfBest := ttV[1]
					}
				}
			}
		if (tfBest >= 0)
			{
			TryFishX := FishBarLeft + tfBest
			LastFishX := TryFishX
			}
		}
	TryBarL := FishBarLeft + tbA
	TryBarW := tbB - tbA + 1
	TryFound := true
	return true
}

; -------------------------------------------------- Stellarwave Melody

SwLog(m) {
}

SwSetup() {
	global SwReady, SwPrmFr, SwPrmFrI, SwPrmBk, SwPrmBkI, SwPrmCap, SwPrmCapI, SwPrmWh, SwPrmWhI, SwPrmCore, SwPrmCoreI, SwPrmStU, SwPrmStUI
	global SwPrmHd, SwPrmHdI, SwFrTol, SwColKey, SwXBarN, SwXCapN, SwXHdN, SwTplF, SwTplFBuf
	global SwZ, SwFrR, SwFrG, SwFrB, SwTpl, SwGradDef, SwWSign, SwStarV, SwStarT, SwLockFail, SwLockN, SwPitchRef, SwPitchRefH, SwStarYRef, SwStarYRefH
	global SwCacheW, SwCacheH, SwCacheSB, SwCacheFrH, SwCacheFrT
	SwTplHex := ""
	SwTplHex .= "E9E3E2EDECBB6C0F0000051497EBE3D6C6BAB9B7C9F0CD8315000EB1EDC3B8C0C3ECF3E5C0BBEEC5762F91E9BAC5EFFDDFE0AABAEEC2C0F6B3ACEDC0C0F0C1B7E9BA63177BEFBAD3F6F2D6BBF3B77020E2BC4B0008AFD9B9F8F7B9D9D3870900CCCF54000031EBB8D8DBB9F4A1380B3AC6D54C000001C0CCBDBDCCE28D455C5CD1800D00000073E0B7B7E4C166455C5C09020000000036EDB7B7F1A62E01174500000000000016EFB8BAF59C1D06030000000000000005E9BAC4E993020B070400000000000000DDC4CDDE87060F0D0A00000403000000C9C8D4D6720A12100D00000505020000C5C4D5D07207131412000407070703009AD0E0C65F09141212"
	SwTplHex .= "007F4642720300000000000DA361265900595B169E33010000000444C5414534001A8F18569C47140C195BD667287606000064693257B2BEB5D5D7823C563600000008AA883C3148665945436A740200000006AAA448314E615E514064A0130000002D933A48ADB2949FB588365B76010005742540A853120B0D2D78622A822F002068159F4E06000000032D6F4C3079004A3E389C1900000000001051651F9500533F5591060000000000084B661F9F004F413AA01800000000000B50682095002D6211A1480200000001276D4E387B0006711F4CA54F0A0506287F602D802F00002C7E3B4EB1A78FA6BC8E3C55750300000155A74A33507A695543657C0F00"
	SwTplHex .= "C9B07E5F43493B3F4144648BB3D2C4378AC3BFB7B5B8B1B0C7C5C1BFC090763A04246BC6CFA3A7B9A5B5CA7A344A321B01020E85E03C4245438CEE40351F090600010773DE2A3B0E0363EE40330D05040001066FDD2835030050EE41320B040300010672DE2A3004014FEE41320B040400010580DD282F05024FEF42320A050500010584DD292D040253F04B320A050600010580DD2A2F040255F159300A060600010575DE2A2F050259F05A2E08060600010576DE2A36090367F15B2F09050600020586DF2F3C342D93EF5B300E0605020835BADC85949C96A8D866342B0F0957A9BBC3B8B7B9BBBDBDC1B387624326D8BBB49B858A7178818FB5C3D3C8B449"
	SwTplHex .= "083084B4977155504D4B4B4B5069767C60B58E554A7091A8ABACAFA7926D2D86B2644F4DB2B77D3A322C2E4669A7A55B5A514F494CA84F0A0100000513717B3A6497BCAF613B8A0F0100002F939C8E838D392F76C9447725020034C67554494A68130A11D0705844060ECA6D4C93BCC061160C24D46C59430852BD32914D1F479A543D9FCB407C24078187407D08040860A4C2B05D3A750D017F8D3B8F14040E68534E444B8519040045C2398571386D8498988D5C140601000BC1794F87B4AE0D2029130C0A0301000164DD8E644B47096096754C3721182055A5D6D07E44440CC2646F87A2C0C4C8BF9E7C564471980796856C544D4C4C4A4744627C8E541C"
	SwTplHex .= "0000000007489A75899883494F0E010000000000249670ACC8C6CDAD3454010001010008637C8A7D260B43DC63550C000101000B8E73813C0401029E8C4E280001020202AD6B872102010089895C2C0002020209C46E782B020103B26B6921000202075CBE795355080028C05F7702000116829E7C7641712F1CAE797042000002689579B9C7953D87B2AB60790800000AA6689C989FD95A89C7648B2300000014B950878594D35DB48971610000000000A6705C94A7B456B65D8521010000000041BE7E7E8E6497A54B620D04010100000153AAA099A1C98C5658100870312F0000010F2E2F33A39F3E77435EC738480000000203020339C6596BA1AA7A5631"
	SwTplHex .= "9E93A8B07E6864857B625D757595624485AD9A967B8C7567648C7A5D86C19A385B95AB8FB39E955C94B49C51BAD2AE26587DB396A3919655A48C9B66A1C0B33A567BB39E807BA14F8B5793788DBBB654557AB39D6E6EA75A875098798CBCB8545679B4986C6EA660854BA0798CC5B02E557DB4966570A2597E48AC788FC8AE2E567EB4965F6E9B567A49AF7891CDA734567FB5965E6B9D57774AB17899CB983D5682B4975A77A15A694BB0789BC079425783B4905668A1586451B07987A55340587FB48B514AA458614BAF7F6E9C3D2D577BA691422790846032B38C6E72541E29444818100F1F271666A4906F876A2603030201030104071FA47957789B962F"
	SwTplHex .= "0000000C70A69C917B74666F4808000000001EAD987A6C7F83937E604C680C00000EB1854B606B473F54A0B06B3D670201709A3C6D3301000102095EC14F5B3503BD584D45000000000000029996315E20B5416E0F000000000000004BB8286720B4406B100000000000000041B92A6A05C252533900000000000001819B2F6A31BE8B2F7503000000000012BD5D5677869CAA6240320000000003898F4C7C837A7B7B7B24410000000003B57C7C7B7B7678787753150000000100528186888A0101010100000000000200000414181C010101000100000001020101000000006769686767666563625550504E4C4C4E7D7B7C7D7D7D7D7D7D7D7D7C7C7E7D7C"
	SwTplHex .= "A59EB4A09F9DB79D9934450F00000000D5A362A1E0A77081E47E343300000000B6B62798DDBC326FD3C71C5200000000A2A32688D3C52468BCDE1F5007000000A19C2A6DBCC523659CE8314F0E000000A29B3568BBC5236591E9394D0E000000A39B3763C1C5246496E8394E0E000000A49B365FBFC72463A6E1264E0E000000A49C365CBDD324639DDA1F4E0C000000A49C365ABBD424629ED9215009000000A39C3956B3D4255FACD921560B010000959D39478DD525569CD8214E32715A395C875827339D523F4DE56C596FE19E1B03121302020C150408C3C1949DA5A2530101010101010000001A9EB3B2AB967101010101000000000000022BA6DC8A2E"
	SwTplHex .= "0202010001010C1CB0B1B19C9C9C9E9E020201000101081179E7F0D5F2CCA79E02020101010002040E3A9FCCD6A6A2AE02020101010000000C1190D6B29CE8BB02020101010002070F5EECB59EBADABD030302010102090F57E7C6A2B793C7BD2C202A1C070D1359E7C2B3B68F78B6BF47C8DFA0784E84EAC1B1D4896E486CB972C7BFEABCC8EDBCAED8A56A231F356250DDBABFF2F3BBA9D8A67D1600010B1F3B95E8B9BBB8ACD8A8811E00000101023A5CECE2ACAAD8C98E5C0200000001023C8FECBCB4B2BCD4976E08010000010277E1BAB9EDEAB4BCC48C310101000101DDB9B9F0C7D8E6B3BBA5570301010101BBB8E8B08B76A3D4C48E2D0302010001"
	SwTplHex .= "8873535A6393ABA98F61371302000001B88E9889AEA592ADB37B681A0A000001BDBD9FC0AB8779558FA5642B1001000162B6BFBC8583372767B16339140201025684C0B28954221F5DAC663E160302035670C1A19422171B69A95E39150402035667B4A29214131A66AD603C160A06065660B49D7C12131B6EA36C471B2C261C565CAC9765100F1C6D97757682A49A714C4C67681C060E1C6CA789AC9E9CBAB80602010102010D1A66AEA2927F6A8FD70101010002010E1949B8A47876275AD2010101010204161B54AD976D6D4471D00101010B1E25254395A9A59F839CB5B400012353516578A2A26990A0A9A89F5D00005076A9ACB0996F6825243D4D432A"
	SwTplHex .= "000000000000010000000000000000004938110200040A090A080300010002059BA1903F1B202761543C1208043C8169C3C09D9B3D46A8ACA85C4F0F1DC3C3C49CC4C68E81ABA561B79F473E9FA58BC99486C6A1A3C86B5954C45D84C654438B706F9ACDB4955D2B1B7FB6A68C35191B6663678E704F371D15174E62441A090A9897917137282E4C5341160E0D387354C5C090913B46B6B3A650460F21B9C6C3A4CBC48867A7AD67B4944A3091B296D2958FC9A09BCF685A6CC44E84C6703F99736DA5C8B19E522B1AA4ADA49539182C1A4D64968356310F0F1663784F1D08050007274623100701010507090905010000000000000001000000000001000201"
	SwTplHex .= "28C35257470300000000000162B544810CB38934741F010000000029C46C51780324D2712E6A0501000003A48F448A2903036EB7376D1E0301003DC251735309030217DB663C520401029C92408B2007040420C6982584240826DD625D85250A1E6082C6AE3082968CA2DD566396835F9C9677786F686C75797B746B6E664C6B90A686897D5C718384898866688479871A4E7EBEB92A969B8D9DE55278A78446050413B79A2C8323072DDC615277150804030AD46F3858040003AC9036791305040342CC4C632B0200005EB943752C060505AE8F2C770A02000113CD7240640E0549C2524F3F03010001037FA942693414C376337409020302010119C879356F"
	SwGradHex := "EDDEACEADBADE8D7B1E6D2B3E3CBB7E3C8BBE1C3BDDFBEC0DDBAC3DBB4C5D8B0C8D6ACC9D1A5C9CFA0CBCB9BCBC997CCC693CEC18CCEBF89D0BC84D0B87DD2B77AD1B779CEB778CCB776C9B875C6B773C2B672C0B671BCB570B8B56FB5B46DB2B46CAFB36BACB36AA8B369A6B165A0AF639CAE6298AE6095AB5E90AB5D8DA95C8AA95A86A75982A6577EA55579A35377A25476A15375A054759F54759E55739C54729C54729B547099547097546E93536A9153698D52668A5265875262855360"
	SwZ := ["Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo", "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"]
	SwFrR := 85
	SwFrG := 68
	SwFrB := 109
	SwFrTol := 26
	SwSetFrame(SwFrR, SwFrG, SwFrB)
	PcSetPrm(SwPrmBk, "0x000000", 45, 0, 0)
	PcSetPrm(SwPrmBkI, "0x000000", 45, 0, 1)
	PcSetPrm(SwPrmCap, "0xAFDAE8", 22, 0, 0)
	PcSetPrm(SwPrmCapI, "0xAFDAE8", 22, 0, 1)
	PcSetPrm(SwPrmWh, "0xFFFFFF", 30, 0, 0)
	PcSetPrm(SwPrmWhI, "0xFFFFFF", 30, 0, 1)
	PcSetPrm(SwPrmHd, "0xFFFFFF", 30, 0, 0)
	PcSetPrm(SwPrmHdI, "0xFFFFFF", 30, 0, 1)
	PcSetPrm(SwPrmCore, "0x7E5CA6", 22, 0, 0)
	PcSetPrm(SwPrmCoreI, "0x7E5CA6", 22, 0, 1)
	PcSetPrm(SwPrmStU, "0x3C1C60", 30, 0, 0)
	PcSetPrm(SwPrmStUI, "0x3C1C60", 30, 0, 1)
	VarSetCapacity(SwTpl, 3072, 0)
	Loop 3072
		NumPut("0x" . SubStr(SwTplHex, 2 * A_Index - 1, 2), SwTpl, A_Index - 1, "UChar")
	SwTplF := []
	Loop 3072
		SwTplF.Push(NumGet(SwTpl, A_Index - 1, "UChar") / 255.0)
	VarSetCapacity(SwTplFBuf, 3072 * 8, 0)
	Loop 3072
		NumPut(SwTplF[A_Index], SwTplFBuf, (A_Index - 1) * 8, "Double")
	VarSetCapacity(SwGradDef, 192, 0)
	Loop 192
		NumPut("0x" . SubStr(SwGradHex, 2 * A_Index - 1, 2), SwGradDef, A_Index - 1, "UChar")
	SwWSign := 0
	SwStarV := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	SwStarT := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	SwLockFail := false
	SwLockN := 0
	SwColKey := ""
	SwXBarN := 0
	SwXCapN := 0
	SwXHdN := 0
	SwPitchRef := -1
	SwPitchRefH := -1
	SwStarYRef := -1
	SwStarYRefH := -1
	SwCacheW := -1
	SwCacheH := -1
	SwCacheSB := 0
	SwCacheFrH := -1
	SwCacheFrT := -1
	SwReady := true
}

SwSetFrame(r, g, b) {
	global SwPrmFr, SwPrmFrI, SwFrTol
	hex := Format("0x{:02X}{:02X}{:02X}", r, g, b)
	PcSetPrm(SwPrmFr, hex, SwFrTol, 0, 0)
	PcSetPrm(SwPrmFrI, hex, SwFrTol, 0, 1)
}

SwTolOf(v, d) {
	if v is not number
		return d
	v := Round(v)
	if (v < 0)
		return 0
	if (v > 255)
		return 255
	return v
}

SwXFill(ByRef buf, o, tol) {
	n := o.n - 1
	if (n > 8)
		n := 8
	VarSetCapacity(buf, 48 * 8, 0)
	Loop % n
		PcPrmAt(&buf + (A_Index - 1) * 48, o.r[A_Index + 1], o.g[A_Index + 1], o.b[A_Index + 1], tol, 0)
	return (n > 0) ? n : 0
}

SwApplyColours() {
	global StellarBarColors, StellarBarTol, StellarFishColors, StellarFishTol, StellarHeadColors, StellarHeadTol
	global SwColKey, SwFrR, SwFrG, SwFrB, SwFrTol, SwFrLearned, SwPrmCap, SwPrmCapI, SwPrmHd, SwPrmHdI
	global SwXBar, SwXBarN, SwXCap, SwXCapN, SwXHd, SwXHdN
	key := StellarBarColors . "|" . StellarBarTol . "|" . StellarFishColors . "|" . StellarFishTol . "|" . StellarHeadColors . "|" . StellarHeadTol
	if (key == SwColKey)
		return
	SwColKey := key
	bt := SwTolOf(StellarBarTol, 26)
	ft := SwTolOf(StellarFishTol, 22)
	ht := SwTolOf(StellarHeadTol, 30)
	o := RfColList(RfColCount(StellarBarColors) ? StellarBarColors : "0x55446D")
	SwFrR := o.r[1]
	SwFrG := o.g[1]
	SwFrB := o.b[1]
	SwFrTol := bt
	SwSetFrame(SwFrR, SwFrG, SwFrB)
	SwFrLearned := false
	SwXBarN := SwXFill(SwXBar, o, bt)
	o := RfColList(RfColCount(StellarFishColors) ? StellarFishColors : "0xAFDAE8")
	hex := Format("0x{:02X}{:02X}{:02X}", o.r[1], o.g[1], o.b[1])
	PcSetPrm(SwPrmCap, hex, ft, 0, 0)
	PcSetPrm(SwPrmCapI, hex, ft, 0, 1)
	SwXCapN := SwXFill(SwXCap, o, ft)
	o := RfColList(RfColCount(StellarHeadColors) ? StellarHeadColors : "0xFFFFFF")
	hex := Format("0x{:02X}{:02X}{:02X}", o.r[1], o.g[1], o.b[1])
	PcSetPrm(SwPrmHd, hex, ht, 0, 0)
	PcSetPrm(SwPrmHdI, hex, ht, 0, 1)
	SwXHdN := SwXFill(SwXHd, o, ht)
	SwLog("colours bar " . SwFrR . "," . SwFrG . "," . SwFrB . "+" . SwXBarN . " tol " . bt . "  fish +" . SwXCapN . " tol " . ft . "  head +" . SwXHdN . " tol " . ht)
}

SwRunsAt(p, x0, x1, a, gap, rr) {
	x := x0
	s0 := -1
	e0 := -1
	n := 0
	while (x <= x1 and n < 60)
		{
		i := PcFindAt(p + x * 4, x1 - x + 1, 4, a)
		if (i < 0)
			break
		s := x + i
		j := PcFindAt(p + (s + 1) * 4, x1 - s, 4, a + 24)
		e := (j < 0) ? x1 : s + j
		n++
		if (s0 >= 0 and s - e0 - 1 <= gap)
			e0 := e
		else
			{
			if (s0 >= 0)
				rr.Push([s0, e0])
			s0 := s
			e0 := e
			}
		x := e + 1
		}
	if (s0 >= 0)
		rr.Push([s0, e0])
}

SwRunsX(p, x0, x1, a, n, gap, rr) {
	Loop % n
		SwRunsAt(p, x0, x1, a + (A_Index - 1) * 48, gap, rr)
	TryRunsMerge(rr, gap)
}

SwColScan(x, y0, y1, need, span, aN, aI) {
	global pCaptureBits, CaptureW
	y := y0
	while (y <= y1 - need)
		{
		i2 := PcFindAt(pCaptureBits + (y * CaptureW + x) * 4, y1 - y + 1, CaptureW * 4, aN)
		if (i2 < 0)
			break
		y := y + i2
		j := PcFindAt(pCaptureBits + ((y + 1) * CaptureW + x) * 4, y1 - y, CaptureW * 4, aI)
		ln := (j < 0) ? (y1 - y + 1) : (j + 1)
		if (ln >= need)
			{
			yb := y + ln
			k2 := 0
			while (k2 < span and yb + k2 <= y1)
				{
				if (SwLum(pCaptureBits + ((yb + k2) * CaptureW + x) * 4) >= 240)
					return y
				k2++
				}
			}
		y := y + ln
		}
	return -1
}

SwNow() {
	global QpcFreq
	DllCall("QueryPerformanceCounter", "Int64*", t)
	return t / QpcFreq
}

SwLum(p) {
	px := NumGet(p + 0, 0, "UInt")
	return ((px >> 16) & 0xFF) + 2 * ((px >> 8) & 0xFF) + (px & 0xFF)
}

SwMedian(arr) {
	n := arr.Length()
	if (n < 1)
		return 0
	a := []
	for i, v in arr
		a.Push(v)
	j := 2
	while (j <= n)
		{
		v := a[j]
		k := j - 1
		while (k >= 1 and a[k] > v)
			{
			a[k + 1] := a[k]
			k--
			}
		a[k + 1] := v
		j++
		}
	return (Mod(n, 2) = 1) ? a[(n + 1) // 2] : (a[n // 2] + a[n // 2 + 1]) / 2
}

SwRuns(p, x0, x1, ByRef prm, ByRef prmI, gap, rr) {
	x := x0
	s0 := -1
	e0 := -1
	n := 0
	while (x <= x1 and n < 60)
		{
		i := PcFind(p + x * 4, x1 - x + 1, 4, prm)
		if (i < 0)
			break
		s := x + i
		j := PcFind(p + (s + 1) * 4, x1 - s, 4, prmI)
		e := (j < 0) ? x1 : s + j
		n++
		if (s0 >= 0 and s - e0 - 1 <= gap)
			e0 := e
		else
			{
			if (s0 >= 0)
				rr.Push([s0, e0])
			s0 := s
			e0 := e
			}
		x := e + 1
		}
	if (s0 >= 0)
		rr.Push([s0, e0])
}

SwCover(rr, a, b) {
	t := 0
	for i, v in rr
		{
		lo := (v[1] > a) ? v[1] : a
		hi := (v[2] < b) ? v[2] : b
		if (hi >= lo)
			t += hi - lo + 1
		}
	return t
}

SwGlowAdd(x, now) {
	global SwGlowX, SwGlowT
	if (!IsObject(SwGlowX))
		{
		SwGlowX := []
		SwGlowT := []
		}
	SwGlowX.Push(x)
	SwGlowT.Push(now)
	while (SwGlowX.Length() > 8)
		{
		SwGlowX.RemoveAt(1)
		SwGlowT.RemoveAt(1)
		}
}

SwGlowZones(now) {
	global SwGlowX, SwGlowT, SwZL, SwZH, SwPitch
	SwZL := []
	SwZH := []
	if (!IsObject(SwGlowX))
		return 0
	lo := []
	hi := []
	Loop % SwGlowX.Length()
		{
		a := now - SwGlowT[A_Index]
		h := (a < 0.55) ? 1.4 : ((a < 0.7) ? 1.0 : ((a < 0.85) ? 0.5 : 0))
		if (a < 0 or h <= 0)
			continue
		r := Round(h * SwPitch)
		l := SwGlowX[A_Index] - r
		j := lo.Length() + 1
		while (j > 1 and lo[j - 1] > l)
			j--
		lo.InsertAt(j, l)
		hi.InsertAt(j, SwGlowX[A_Index] + r)
		}
	Loop % lo.Length()
		{
		n := SwZL.Length()
		if (n and lo[A_Index] <= SwZH[n] + 1)
			{
			if (hi[A_Index] > SwZH[n])
				SwZH[n] := hi[A_Index]
			}
		else
			{
			SwZL.Push(lo[A_Index])
			SwZH.Push(hi[A_Index])
			}
		}
	return SwZL.Length()
}

SwGlowNear(x, h, amax, now) {
	global SwGlowX, SwGlowT, SwPitch
	if (!IsObject(SwGlowX))
		return false
	Loop % SwGlowX.Length()
		{
		a := now - SwGlowT[A_Index]
		if (a >= 0 and a < amax and Abs(SwGlowX[A_Index] - x) <= h * SwPitch)
			return true
		}
	return false
}

SwCoverX(rr, a, b) {
	global SwZL, SwZH
	c := SwCover(rr, a, b)
	Loop % SwZL.Length()
		{
		l := (SwZL[A_Index] > a) ? SwZL[A_Index] : a
		h := (SwZH[A_Index] < b) ? SwZH[A_Index] : b
		if (h >= l)
			c := c - SwCover(rr, l, h)
		}
	return c
}

SwZoneLen(a, b) {
	global SwZL, SwZH
	n := 0
	Loop % SwZL.Length()
		{
		l := (SwZL[A_Index] > a) ? SwZL[A_Index] : a
		h := (SwZH[A_Index] < b) ? SwZH[A_Index] : b
		if (h >= l)
			n := n + h - l + 1
		}
	return n
}

SwInZone(x, m) {
	global SwZL, SwZH
	Loop % SwZL.Length()
		{
		if (x >= SwZL[A_Index] - m and x <= SwZH[A_Index] + m)
			return true
		}
	return false
}

SwFightReset() {
	global SwPreK, SwParkAt, SwFrStillRef, SwFrStillT, SwFrameT, SwReactEst, SwFoundT, SwBarHold, SwGlowX, SwGlowT, SwZL, SwZH, SwFishHeld
	global SwPressK, SwPressQ, SwPressMs, SwPressDecT, SwPressNom, SwPressCx, SwPressCy, SwPressPre, SwPressSx, SwPressSy, SwWantK, SwWantT, SwWantNom, SwWantPre, SwWantSx, SwWantSy, SwWantCx, SwWantCy
	global SwLitFastT, SwLitFastV, SwHov1, SwHov2, SwMoveOn, SwHyb, SwWantStrk, SwPressLit, SwLitRawN
	global SwReady, SwS, SwSB, SwSX, SwPitch, SwSlotC0, SwFrTop, SwFrMiss, SwLastC, SwLastL, SwW, SwWSign, SwWRing, SwFound, SwBarL, SwBarW, SwFishX, SwFrRef, SwFrRefT, SwFrMoveT
	global SwFishAt, SwFishLast, SwPhase, SwPhaseT, SwInvalidT, SwUndarkT, SwStarsValid, SwLit, SwLitPrev, SwLitRaw, SwLitRawT, SwStarFound, SwStarY, SwStarX0, SwStarPitch, SwStarRetryT, SwStarOkT
	global SwGradOk, SwGrad, SwDarkR, SwDarkG, SwDarkB, SwFrLearned, SwLastStep, SwPiano, SwPianoDis, SwTipT, SwScanned, SwStarStableT, SwStarPitch, SwStarX0, SwLockFail, SwLockN
	global WindowWidth, WindowHeight, FishBarTop, FishBarLeft, RobloxHwnd, MacroRunning, LookDownX, LookDownY, SwWMeas, SwMeasN, SwMeasT, SwPostT
	global SwSM, SwSB, SwFrH, SwFrHC, SwFrT, SwFrTC, SwFrHT, SwFrBad, SwFrOk, SwStarFullT, SwCacheW, SwCacheH, SwCacheSB, SwCacheFrH, SwCacheFrT
	if (!SwReady)
		SwSetup()
	SwApplyColours()
	KittyReset()
	SwWMeas := false
	SwMeasN := 0
	SwMeasT := 0
	SwPostT := 0
	SwS := WindowHeight / 1440.0
	SwSX := WindowWidth / 2560.0
	SwSM := (SwS < SwSX) ? SwS : SwSX
	SwSB := SwSM
	SwFrH := -1
	SwFrHC := -1
	SwFrT := -1
	SwFrTC := -1
	SwFrHT := 0
	SwFrBad := 0
	SwFrOk := false
	SwStarFullT := 0
	if (SwCacheH = WindowHeight and SwCacheW = WindowWidth)
		{
		SwSB := SwCacheSB
		SwFrH := SwCacheFrH
		SwFrT := SwCacheFrT
		SwFrOk := true
		}
	SwPitch := 115.5 * SwSX
	SwSlotC0 := WindowWidth / 2 - 5.5 * SwPitch
	SwFrTop := Round(1208 * SwS) - Round(FishBarTop)
	SwFrMiss := 0
	SwFrRef := -1
	SwFrRefT := 0
	SwFrMoveT := 0
	SwFrStillRef := -1
	SwFrStillT := 0
	SwLastC := -1
	SwLastL := -1
	SwW := Round(WindowHeight * 0.625)
	SwWRing := []
	SwFound := false
	SwBarL := -1
	SwBarW := 0
	SwFishX := -1
	SwFishAt := 0
	SwFishLast := -1
	SwPhase := 0
	SwPhaseT := 0
	SwInvalidT := 0
	SwUndarkT := 0
	SwStarsValid := false
	SwLit := 0
	SwLitPrev := 0
	SwLitRaw := -1
	SwLitRawT := 0
	SwStarFound := false
	SwStarRetryT := 0
	SwStarOkT := 0
	SwStarStableT := 0
	SwStarPitch := 0
	SwStarX0 := 0
	SwGradOk := false
	VarSetCapacity(SwGrad, 192, 0)
	SwDarkR := 22
	SwDarkG := 8
	SwDarkB := 22
	SwFrLearned := false
	SwLastStep := 0
	SwPiano := -1
	SwPianoDis := 0
	SwTipT := 0
	SwScanned := false
	SwLockFail := (SwLockN >= 3)
	SwFrameT := 0
	SwReactEst := 0.12
	SwFoundT := 0
	SwBarHold := false
	SwGlowX := []
	SwGlowT := []
	SwZL := []
	SwZH := []
	SwFishHeld := false
	SwPreK := 0
	SwParkAt := 0
	SwPressK := 0
	SwPressQ := 0
	SwPressMs := 90
	SwPressDecT := 0
	SwPressNom := 0
	SwPressCx := 0
	SwPressCy := 0
	SwPressPre := false
	SwPressSx := 0
	SwPressSy := 0
	SwWantK := 0
	SwWantT := 0
	SwWantNom := 0
	SwWantPre := false
	SwWantSx := 0
	SwWantSy := 0
	SwWantCx := 0
	SwWantCy := 0
	SwLitFastT := 0
	SwLitFastV := 0
	SwWantStrk := 0
	SwPressLit := 0
	SwLitRawN := 0
	SwHov1 := 0.025
	SwHov2 := 0.03
	SwMoveOn := 0.06
	SwHyb := 0.012
	SwPhaseReset()
	if (MacroRunning and RobloxHwnd and WinActive("ahk_id " . RobloxHwnd))
		MouseMove, %LookDownX%, %LookDownY%, 0
}

SwPhaseReset() {
	global SwVetoM, SwVetoZ, SwRecZ, SwDwell, SwDwellPN, SwPressN, SwClickStall, SwPress0At, SwUnsureK, SwUnsureT, SwUnsureR
	global SwSlotSt, SwSlotFirst, SwSlotHits, SwSlotLvl, SwSlotGone, SwOrder, SwK0, SwClicks, SwClickAt, SwClickLit, SwClickSlot, SwRetry, SwSlotBlind
	global SwStop, SwStopWhy, SwLastClick, SwTie, SwLastOnset, SwGradOk, SwPurpleN, SwClickTook, SwTieWas, SwWantK, SwWantStrk
	global SwOverK, SwOverT, SwOverL, SwOverR, SwOverS, SwTryAt
	SwPreEnd("reset")
	SwDwell := false
	SwWantK := 0
	SwWantStrk := 0
	SwSlotSt := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	SwSlotFirst := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	SwSlotHits := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	SwSlotLvl := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	SwSlotGone := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	SwSlotBlind := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	SwTie := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	SwTieWas := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	SwVetoM := 0
	SwVetoZ := -1
	SwRecZ := -1
	SwOrder := []
	SwK0 := -1
	SwClicks := 0
	SwClickAt := 0
	SwClickLit := 0
	SwClickSlot := 0
	SwRetry := 0
	SwPurpleN := 0
	SwClickTook := 0
	SwDwellPN := 0
	SwPressN := 0
	SwClickStall := 0
	SwPress0At := 0
	SwUnsureK := 0
	SwUnsureT := 0
	SwUnsureR := 0
	SwOverK := 0
	SwOverT := 0
	SwOverL := 0
	SwOverR := -1
	SwOverS := 0
	SwTryAt := 0
	SwStop := false
	SwStopWhy := ""
	SwLastClick := 0
	SwLastOnset := 0
	SwGradOk := false
}

SwSlotX(k) {
	global SwSlotC0, SwPitch
	return SwSlotC0 + (k - 1) * SwPitch
}

SwScan() {
	global SwScanned, SwReady, pCaptureBits, CaptureW, CaptureH, pNoteBits, NoteFresh, SwFrameT
	global SwFound, SwBarL, SwBarW, SwFishX, SwPhase, SwPhaseT, SwInvalidT, SwUndarkT, SwStarsValid, SwLit, SwLitPrev, SwLastStep, SwK0, SwClicks, SwStop, SwStopWhy, SwGradOk, SwWRing, SwStarStableT, SwLastClick
	global SwW, SwWMeas, SwMeasN, SwPostT, SwBarHold, SwCleanL, SwCleanW
	if (SwScanned)
		return true
	SwScanned := true
	if (!SwReady)
		SwSetup()
	if (!pCaptureBits or CaptureW < 40 or CaptureH < 40)
		return false
	now := SwNow()
	SwFrameT := now
	if (KittyMode())
		return KittyScan(now)
	SwStarsRead(now)
	SwBarScan(now)
	SwFishScan(now)
	dark := SwDarkTest()
	if (SwPhase = 0)
		{
		if (SwStarsValid and dark and SwFound)
			{
			SwPhase := 1
			SwPhaseT := now
			SwInvalidT := 0
			SwUndarkT := 0
			SwPhaseReset()
			SwWMeas := false
			SwMeasN := 0
			SwLitPrev := SwLit
			SwLog("phase start lit=" . SwLit)
			}
		}
	else
		{
		if (SwStarsValid)
			SwInvalidT := 0
		else if (!SwInvalidT)
			SwInvalidT := now
		if (dark)
			SwUndarkT := 0
		else if (!SwUndarkT and now - SwLastClick >= 1.0 and now - SwPhaseT >= 1.0)
			SwUndarkT := now
		if ((SwInvalidT and now - SwInvalidT > 0.2) or (SwUndarkT and now - SwUndarkT > 1.0))
			{
			SwPhase := 0
			SwWRing := []
			SwPostT := now
			if (SwWMeas)
				SwWRing := [SwW]
			SwWMeas := false
			SwMeasN := 0
			SwLog("phase end" . (SwInvalidT ? " stars" : "") . (SwUndarkT ? " undark" : ""))
			SwPreEnd("phase end")
			}
		if (SwPhase and SwStarsValid and SwLit < SwLitPrev)
			{
			if (SwLit = 0)
				{
				SwLog("lit reset " . SwLitPrev . "->0")
				SwPhaseReset()
				SwWMeas := false
				SwMeasN := 0
				SwPhaseT := now
				}
			else
				SwLog("lit dropped " . SwLitPrev . "->" . SwLit . " ignored")
			}
		if (SwStarsValid)
			SwLitPrev := SwLit
		}
	if (SwPhase and SwFound)
		{
		if (!SwGradOk and !SwZoneLen(SwCleanL, SwCleanL + Round(SwCleanW) - 1))
			SwGradLearn()
		SwSlotsScan(now)
		}
	else if (SwPhase and SwBarHold and SwGradOk)
		SwSlotsScan(now, true)
	if (SwPhase and SwLastStep and now - SwLastStep > 1.0 and !SwStop and SwOrderCount() > 0)
		{
		SwStop := true
		SwStopWhy := "gap " . Round((now - SwLastStep) * 1000)
		SwLog("stop: " . SwStopWhy)
		}
	SwLastStep := now
	SwTip(now)
	return true
}

SwOrderCount() {
	global SwOrder
	return SwOrder.Length()
}

SwStarsRead(now) {
	global pNoteBits, NoteW, NoteH, NoteOriginX, NoteOriginY, SwS, SwSB, SwSX, WindowWidth, SwPrmWh, SwPrmWhI, SwPrmStU, SwPrmStUI
	global SwStarFound, SwStarY, SwStarX0, SwStarPitch, SwStarRetryT, SwStarV, SwStarT, SwStarsValid, SwLit, SwPitch, SwSlotC0, SwPhase, SwStarOkT, SwLitRaw, SwLitRawT, SwFastClicks
	global SwClickAt, SwClickLit, SwLitFastT, SwLitFastV, SwLitRawN, SwClickSlot, FishBarLeft
	global SwPitchRef, SwPitchRefH, SwStarStableT, WindowHeight, SwStarYRef, SwStarYRefH
	if (!pNoteBits or NoteW < 40 or NoteH < 8)
		{
		SwStarsValid := false
		return
		}
	if (SwStarFound)
		{
		if (SwStarRow(SwStarY, cs, tot))
			SwStarSet(cs)
		else if (!SwPhase)
			{
			SwStarFound := false
			SwStarRetryT := now
			}
		}
	if (!SwStarFound)
		{
		if (SwStarRetryT and now - SwStarRetryT < 0.2)
			{
			SwStarsValid := false
			return
			}
		SwStarRetryT := now
		if (!SwStarFind())
			{
			SwStarsValid := false
			return
			}
		}
	nom := 0.0625 * WindowHeight
	if (SwPitchRef > 0 and SwPitchRefH = WindowHeight and (SwStarPitch < 0.95 * SwPitchRef or SwStarPitch > 1.05 * SwPitchRef) and SwStarStableT and now - SwStarStableT >= 0.3 and SwStarPitch >= 0.90 * nom and SwStarPitch <= 1.05 * nom)
		{
		SwPitchRef := -1
		SwLog("star pitch unlearned " . Round(SwStarPitch, 2))
		}
	learned := (SwPitchRef > 0 and SwPitchRefH = WindowHeight)
	pref := learned ? SwPitchRef : nom
	if (SwStarPitch < 0.95 * pref or SwStarPitch > 1.05 * pref)
		{
		if (learned or SwStarPitch < 0.90 * pref or SwStarPitch > 1.05 * pref or !SwStarStableT or now - SwStarStableT < 0.1)
			{
			SwStarsValid := false
			return
			}
		}
	Loop 12
		{
		x := Round(SwStarX0 + (A_Index - 1) * SwStarPitch) - NoteOriginX
		if (x < 1 or x >= NoteW - 1)
			continue
		p := pNoteBits + (SwStarY * NoteW + x) * 4
		r := 0
		g := 0
		b := 0
		Loop 3
			{
			px := NumGet(p + (A_Index - 2) * 4, 0, "UInt")
			b += px & 0xFF
			g += (px >> 8) & 0xFF
			r += (px >> 16) & 0xFF
			}
		r := r // 3
		g := g // 3
		b := b // 3
		mn := (r < g) ? ((r < b) ? r : b) : ((g < b) ? g : b)
		v := 0
		if (mn >= 200)
			v := 2
		else if (Abs(r - 60) <= 30 and Abs(g - 28) <= 30 and Abs(b - 96) <= 30)
			v := 1
		if (v)
			{
			SwStarV[A_Index] := v
			SwStarT[A_Index] := now
			}
		}
	valid := true
	lit := 0
	pre := true
	Loop 12
		{
		if (now - SwStarT[A_Index] > 0.15)
			valid := false
		if (SwStarV[A_Index] = 2 and pre)
			lit++
		else
			pre := false
		}
	SwStarsValid := valid
	if (valid and !(SwPitchRef > 0 and SwPitchRefH = WindowHeight) and SwStarStableT and now - SwStarStableT >= 0.3 and Abs(SwStarPitch / nom - 1) > 0.01 and SwStarPitch >= 0.95 * nom)
		{
		SwPitchRef := SwStarPitch
		SwPitchRefH := WindowHeight
		SwLog("star pitch learned " . Round(SwStarPitch, 2))
		}
	if (valid)
		{
		SwStarYRef := SwStarY
		SwStarYRefH := WindowHeight
		}
	if (valid)
		{
		if (lit != SwLitRaw)
			{
			if (SwClickAt and SwClickSlot and (lit = SwClickLit + 1 or (SwClickLit = 11 and lit = 0)))
				SwGlowAdd(Round(SwSlotX(SwClickSlot)) - Round(FishBarLeft), now)
			SwLitRaw := lit
			SwLitRawT := now
			SwLitRawN := 1
			}
		else
			SwLitRawN := SwLitRawN + 1
		if (SwLitFastT and now - SwLitFastT < 0.1 and SwLitRaw = SwLitFastV - 1)
			{
			SwLog("star revert " . SwLitFastV . "->" . SwLitRaw)
			SwLitFastT := 0
			}
		if (now - SwLitRawT >= (SwFastClicks ? 0.03 : 0.1))
			SwLit := SwLitRaw
		else if (((SwClickAt and SwLitRaw = SwClickLit + 1) or (KittyMode() and KittyExpectLit() >= 0 and SwLitRaw = KittyExpectLit() + 1)) and SwLit != SwLitRaw and SwLitRawN >= 2)
			{
			SwLit := SwLitRaw
			SwLitFastT := now
			SwLitFastV := SwLitRaw
			}
		SwStarOkT := now
		}
	else if (SwPhase and SwStarOkT and now - SwStarOkT > 0.5)
		{
		SwStarFound := false
		SwStarRetryT := 0
		}
}

SwStarRow(y, ByRef cs, ByRef tot) {
	global pNoteBits, NoteW, NoteH, SwS, SwSB, SwSX, SwPrmWh, SwPrmWhI, SwPrmStU, SwPrmStUI
	cs := []
	tot := 0
	if (y < 0 or y >= NoteH)
		return false
	rr := []
	p := pNoteBits + y * NoteW * 4
	SwRuns(p, 0, NoteW - 1, SwPrmWh, SwPrmWhI, 2, rr)
	SwRuns(p, 0, NoteW - 1, SwPrmStU, SwPrmStUI, 2, rr)
	TryRunsMerge(rr, 2)
	wlo := Round(10 * SwS)
	whi := Round(60 * SwS)
	for i, v in rr
		{
		w := v[2] - v[1] + 1
		if (w >= wlo and w <= whi)
			{
			cs.Push((v[1] + v[2]) / 2)
			tot += w
			}
		}
	if (cs.Length() != 12)
		return false
	pitch := (cs[12] - cs[1]) / 11
	pmin := ((SwS < SwSX) ? SwS : SwSX) * 60
	pmax := ((SwS > SwSX) ? SwS : SwSX) * 120
	if (pitch < pmin or pitch > pmax)
		return false
	Loop 11
		{
		if (Abs(cs[A_Index + 1] - cs[A_Index] - pitch) > 0.08 * pitch)
			return false
		}
	return true
}

SwStarFind() {
	global NoteOriginX, NoteOriginY, NoteH, SwS, SwSB, SwStarFound, SwStarY, SwStarX0, SwStarPitch, SwPitch, SwSlotC0, SwStarYRef, SwStarYRefH, SwStarFullT, WindowHeight
	yn := Round(1060 * SwS) - NoteOriginY
	half := Round(10 * SwS)
	best := 0
	bcs := ""
	Loop % 2 * half + 1
		{
		y := yn - half + A_Index - 1
		if (!SwStarRow(y, cs, tot))
			continue
		if (tot > best)
			{
			best := tot
			SwStarY := y
			bcs := cs
			}
		}
	if (best <= 0)
		{
		by := -1
		if (SwStarYRef >= 0 and SwStarYRefH = WindowHeight)
			best := SwStarRows(SwStarYRef - half, SwStarYRef + half, 1, yn, half, by)
		if (by < 0 and (!SwStarFullT or SwNow() - SwStarFullT >= 1.0 or SwDarkTest()))
			{
			SwStarFullT := SwNow()
			st := Round(2 * SwS)
			if (st < 1)
				st := 1
			best := SwStarRows(0, NoteH - 1, st, yn, half, by)
			}
		if (by >= 0)
			{
			SwStarRow(by, bcs, tot)
			SwStarY := by
			}
		}
	if (best <= 0 or !IsObject(bcs))
		return false
	SwStarFound := true
	SwStarSet(bcs)
	SwLog("stars y=" . (NoteOriginY + SwStarY) . " x0=" . Round(SwStarX0) . " pitch=" . Round(SwStarPitch, 2))
	return true
}

SwPitchOk(p) {
	global SwPitchRef, SwPitchRefH, WindowHeight
	nom := 0.0625 * WindowHeight
	if (p >= 0.90 * nom and p <= 1.05 * nom)
		return true
	return (SwPitchRef > 0 and SwPitchRefH = WindowHeight and p >= 0.95 * SwPitchRef and p <= 1.05 * SwPitchRef)
}

SwStarRows(y0, y1, st, yn, half, ByRef by) {
	best := 0
	by := -1
	y := y0
	while (y <= y1)
		{
		if ((y < yn - half or y > yn + half) and SwStarRow(y, cs, tot) and tot > best and SwPitchOk((cs[12] - cs[1]) / 11))
			{
			best := tot
			by := y
			}
		y += st
		}
	if (by >= 0 and st > 1)
		{
		yc := by
		Loop % 2 * st - 1
			{
			y := yc - st + A_Index
			if (SwStarRow(y, cs, tot) and tot >= best and SwPitchOk((cs[12] - cs[1]) / 11))
				{
				best := tot
				by := y
				}
			}
		}
	return best
}

SwStarSet(cs) {
	global NoteOriginX, SwStarX0, SwStarPitch, SwPitch, SwSlotC0, SwStarStableT, SwSX
	np := (cs[12] - cs[1]) / 11
	if (Abs(np - SwStarPitch) > 0.4 or Abs(NoteOriginX + cs[1] - SwStarX0) > 1.5)
		SwStarStableT := SwNow()
	SwStarX0 := NoteOriginX + cs[1]
	SwStarPitch := np
	SwPitch := SwStarPitch * 1.28333
	if (!KittyMode() and Abs(SwPitch - 115.5 * SwSX) > 0.01 * 115.5 * SwSX)
		SwPitch := 115.5 * SwSX
	SwSlotC0 := SwStarX0 + 5.5 * SwStarPitch - 5.5 * SwPitch
}

SwFrameTop() {
	global pCaptureBits, CaptureW, CaptureH, SwPrmFr, SwPrmFrI, SwS, SwSB, SwLastC, FishBarLeft, FishBarTop, WindowWidth, WindowHeight, SwXBar, SwXBarN
	y0 := Round(WindowHeight * 0.83) - Round(FishBarTop)
	y1 := Round(WindowHeight * 0.89) - Round(FishBarTop)
	if (y0 < 0)
		y0 := 0
	if (y1 > CaptureH - 12)
		y1 := CaptureH - 12
	need := Round(3 * SwSB)
	if (need < 2)
		need := 2
	span := Round(8 * SwSB)
	cx := (SwLastC >= 0) ? SwLastC : WindowWidth / 2
	found := []
	for i, k in [-3, -2, -1, 1, 2, 3]
		{
		x := Round(cx + k * 0.05 * WindowWidth) - Round(FishBarLeft)
		if (x < 0 or x >= CaptureW)
			continue
		y := SwColScan(x, y0, y1, need, span, &SwPrmFr, &SwPrmFrI)
		Loop % SwXBarN
			{
			yy := SwColScan(x, y0, y1, need, span, &SwXBar + (A_Index - 1) * 48, &SwXBar + (A_Index - 1) * 48 + 24)
			if (yy >= 0 and (y < 0 or yy < y))
				y := yy
			}
		if (y >= 0)
			found.Push(y)
		}
	if (!found.Length())
		return -1
	return Round(SwMedian(found))
}

SwBarScan(now) {
	global SwFrStillRef, SwFrStillT, SwFoundT, SwBarHold, SwLitRawT
	global pCaptureBits, CaptureW, CaptureH, SwS, SwSB, SwPrmFr, SwPrmFrI, SwFrTop, SwFrMiss, SwLastC, SwLastL, SwW, SwWSign, SwWRing, SwFound, SwBarL, SwBarW
	global SwPhase, FishBarLeft, FishBarTop, WindowWidth, WindowHeight, SwFrLearned, SwPiano, SwPianoDis, SwCleanL, SwCleanW, SwFrRef, SwFrRefT, SwFrMoveT
	global SwXBar, SwXBarN, SwWMeas, SwMeasN, SwMeasT, SwSM, SwSB, SwFrH, SwFrHC, SwFrT, SwFrTC, SwFrHT, SwFrBad, SwFrOk
	global SwCacheW, SwCacheH, SwCacheSB, SwCacheFrH, SwCacheFrT
	SwGlowZones(now)
	ft := SwFrameTop()
	nom := Round(1208 * SwS) - Round(FishBarTop)
	if (ft >= 0 and ft >= nom - Round(0.01 * WindowHeight) and ft <= nom + Round(0.06 * WindowHeight))
		{
		if (now - SwFrRefT >= 0.2)
			{
			if (SwFrRef >= 0 and Abs(ft - SwFrRef) > 5 * SwSB)
				{
				SwFrMoveT := now
				SwLog("frame top moved " . SwFrRef . "->" . ft)
				}
			SwFrRef := ft
			SwFrRefT := now
			}
		SwFrTop := ft
		SwFrMiss := 0
		if (SwFrStillRef < 0 or Abs(ft - SwFrStillRef) > 3 * SwSB)
			{
			SwFrStillRef := ft
			SwFrStillT := now
			}
		}
	else
		SwFrMiss++
	SwFound := false
	SwBarHold := false
	SwCleanL := -1
	SwCleanW := 0
	if (SwFrMiss > 6)
		{
		SwLastL := -1
		SwLastC := -1
		return
		}
	if (SwFrBad >= 3 and SwFrH > 0)
		{
		SwFrH := -1
		SwFrHC := -1
		SwFrBad := 0
		if (!SwFrOk)
			{
			SwSB := SwSM
			SwFrHT := now + 0.9
			}
		}
	if (SwFrH < 0 and SwFrMiss = 0 and now - SwFrMoveT >= 0.2 and Abs(SwFrTop - SwFrRef) <= 1 and now - SwFrHT >= 0.1)
		{
		SwFrHT := now
		SwFrameBot(SwFrTop, t0, t1, b0, b1)
		h2 := b0 + b1
		tcn := (t0 + t1) // 2
		if (b0 > 0 and SwFrHC > 0 and Abs(h2 - SwFrHC) <= 2 and Abs(tcn - SwFrTC) <= 1)
			{
			SwSB := (Abs(h2 / (168.0 * SwSM) - 1) > 0.03) ? h2 / 168.0 : SwSM
			ob := Round(84 * SwSB)
			SwFrH := (b0 <= ob and ob <= b1) ? ob : (h2 + 1) // 2
			ot := Round(2 * SwSB)
			SwFrT := (t0 <= ot and ot <= t1) ? ot : (t0 + t1 + 1) // 2
			SwFrOk := false
			SwLog("bar rows " . b0 . "-" . b1 . " top " . t0 . "-" . t1 . " sb " . Round(SwSB, 3))
			}
		SwFrHC := (b0 > 0) ? h2 : -1
		SwFrTC := (b0 > 0) ? tcn : -1
		}
	yt := SwFrTop + ((SwFrH > 0) ? SwFrT : Round(2 * SwSB))
	yb := SwFrTop + ((SwFrH > 0) ? SwFrH : Round(84 * SwSB))
	if (yt < 0 or yb >= CaptureH)
		return
	ra := []
	rb := []
	xa := Round(WindowWidth * 0.225) - Round(FishBarLeft)
	xb := Round(WindowWidth * 0.775) - Round(FishBarLeft)
	if (xa < 0)
		xa := 0
	if (xb > CaptureW - 1)
		xb := CaptureW - 1
	SwRuns(pCaptureBits + yt * CaptureW * 4, xa, xb, SwPrmFr, SwPrmFrI, 3, ra)
	SwRuns(pCaptureBits + yb * CaptureW * 4, xa, xb, SwPrmFr, SwPrmFrI, 3, rb)
	if (SwXBarN)
		{
		SwRunsX(pCaptureBits + yt * CaptureW * 4, xa, xb, &SwXBar, SwXBarN, 3, ra)
		SwRunsX(pCaptureBits + yb * CaptureW * 4, xa, xb, &SwXBar, SwXBarN, 3, rb)
		}
	L := -1
	w := 0
	Wp := Round(WindowHeight * 0.625)
	if (SwPhase and !SwWMeas)
		SwW := Wp
	if (SwCleanFrame(ra, rb, yt, yb, cl, cw, now))
		{
		SwCleanL := cl
		SwCleanW := cw
		if (SwPhase)
			{
			if (!SwWMeas)
				{
				if (cw < 0.95 * Wp)
					{
					if (SwMeasN > 0 and now - SwMeasT > 0.3)
						SwMeasN := 0
					SwMeasN++
					SwMeasT := now
					one := false
					pc := SwPianoFind(cl, Round(cl + cw) - 1)
					if (pc >= 0)
						{
						if (Abs(pc - (cl + cw / 2.0)) <= 0.01 * WindowWidth)
							one := true
						else
							SwMeasN--
						}
					if (one or SwMeasN >= 2)
						{
						SwWMeas := true
						SwLog("bar measured " . Round(cw))
						}
					}
				else
					SwMeasN := 0
				}
			else if (cw >= 0.97 * Wp)
				{
				SwWMeas := false
				SwMeasN := 0
				SwW := Wp
				}
			if (SwWMeas)
				{
				SwW := cw
				L := cl
				w := Round(cw)
				}
			else if (Abs(cw - SwW) <= 0.03 * SwW)
				{
				L := cl
				w := Round(cw)
				}
			}
		else
			{
		SwWRing.Push(cw)
		if (SwWRing.Length() > 7)
			SwWRing.RemoveAt(1)
		n := SwWRing.Length()
		if (n >= 3)
			{
			l3 := [SwWRing[n - 2], SwWRing[n - 1], SwWRing[n]]
			m3 := SwMedian(l3)
			mx := l3[1]
			mn := l3[1]
			for i, v in l3
				{
				if (v > mx)
					mx := v
				if (v < mn)
					mn := v
				}
			if (mx - mn <= 0.01 * mx and Abs(m3 - SwW) > 0.03 * SwW)
				{
				SwW := m3
				SwWRing := l3
				}
			else
				SwW := SwMedian(SwWRing)
			}
		else
			SwW := cw
		if (Abs(cw - SwW) <= 0.03 * SwW or (SwLastL >= 0 and Abs(cw - SwBarW) <= 0.06 * SwW))
			{
			L := cl
			w := Round(cw)
			}
			}
		if (!SwFrLearned)
			SwFrameLearn(yt, cl, cw)
		}
	if (L < 0 and SwW > 0)
		{
		wi := Round(SwW)
		if (SwFit(ra, rb, yt, yb, wi, fl))
			{
			L := fl
			w := wi
			}
		}
	if (L < 0)
		{
		if (SwFrMiss = 0 and now - SwFrMoveT >= 0.2 and Abs(SwFrTop - SwFrRef) <= 1 and now - SwLitRawT >= 0.8 and SwDarkTest())
			SwFrBad++
		SwBarHold := (SwFoundT and now - SwFoundT < 0.5 and now - SwLitRawT < 0.6 and SwFrMiss = 0)
		return
		}
	SwFrBad := 0
	if (SwFrH > 0)
		{
		SwFrOk := true
		SwCacheW := WindowWidth
		SwCacheH := WindowHeight
		SwCacheSB := SwSB
		SwCacheFrH := SwFrH
		SwCacheFrT := SwFrT
		}
	SwFound := true
	SwFoundT := now
	SwBarL := Round(FishBarLeft) + L
	SwBarW := w
	SwLastL := L
	SwLastC := SwBarL + w / 2.0
	SwPianoCheck()
}

SwFrameCov(y, xa, xb) {
	global pCaptureBits, CaptureW, CaptureH, SwPrmFr, SwPrmFrI, SwXBar, SwXBarN
	if (y < 0 or y >= CaptureH)
		return 0
	rr := []
	SwRuns(pCaptureBits + y * CaptureW * 4, xa, xb, SwPrmFr, SwPrmFrI, 3, rr)
	if (SwXBarN)
		SwRunsX(pCaptureBits + y * CaptureW * 4, xa, xb, &SwXBar, SwXBarN, 3, rr)
	c := 0
	for i, v in rr
		c += v[2] - v[1] + 1
	return c
}

SwFrameBot(ft, ByRef t0, ByRef t1, ByRef r0, ByRef r1) {
	global CaptureW, CaptureH, SwS, SwSX, SwSB, FishBarLeft, WindowWidth
	t0 := -1
	t1 := -1
	r0 := -1
	r1 := -1
	xa := Round(WindowWidth * 0.225) - Round(FishBarLeft)
	xb := Round(WindowWidth * 0.775) - Round(FishBarLeft)
	if (xa < 0)
		xa := 0
	if (xb > CaptureW - 1)
		xb := CaptureW - 1
	thin := Round(8 * ((SwSB > SwSX) ? SwSB : SwSX))
	if (thin < 3)
		thin := 3
	tc := []
	ct := 0
	Loop % thin + 1
		{
		c := SwFrameCov(ft + A_Index - 1, xa, xb)
		tc.Push(c)
		if (c > ct)
			ct := c
		}
	if (ct < 0.08 * WindowWidth)
		return
	u0 := 0
	while (u0 <= thin and tc[u0 + 1] < 0.6 * ct)
		u0++
	u1 := u0
	while (u1 + 1 <= thin and tc[u1 + 2] >= 0.6 * ct)
		u1++
	ya := ft + Round(60 * ((SwS < SwSX) ? SwS : SwSX))
	yz := ft + Round(110 * ((SwS > SwSX) ? SwS : SwSX))
	if (ya < 0)
		ya := 0
	if (yz > CaptureH - 1)
		yz := CaptureH - 1
	best := 0
	q0 := -1
	q1 := -1
	s0 := -1
	pk := 0
	y := ya
	while (y <= yz + 1)
		{
		c := (y <= yz) ? SwFrameCov(y, xa, xb) : 0
		if (y <= yz and c >= 0.6 * ct)
			{
			if (s0 < 0)
				{
				s0 := y
				pk := 0
				}
			if (c > pk)
				pk := c
			}
		else if (s0 >= 0)
			{
			if (y <= yz and y - s0 <= thin and pk > best)
				{
				best := pk
				q0 := s0 - ft
				q1 := y - 1 - ft
				}
			s0 := -1
			}
		y++
		}
	if (q0 < 0)
		return
	t0 := u0
	t1 := u1
	r0 := q0
	r1 := q1
}

SwCleanFrame(ra, rb, yt, yb, ByRef cl, ByRef cw, now) {
	global pCaptureBits, CaptureW, SwS, SwSB, SwPhase, WindowWidth, SwPrmFr, SwWMeas, SwPostT, SwPitch
	cl := -1
	cw := 0
	if (!ra.Length() or !rb.Length())
		return false
	mn := 6 * SwSB
	a1 := -1
	b1 := -1
	for i, v in ra
		{
		if (v[2] - v[1] + 1 >= mn)
			{
			if (a1 < 0)
				a1 := v[1]
			b1 := v[2]
			}
		}
	a2 := -1
	b2 := -1
	for i, v in rb
		{
		if (v[2] - v[1] + 1 >= mn)
			{
			if (a2 < 0)
				a2 := v[1]
			b2 := v[2]
			}
		}
	if (a1 < 0 or a2 < 0)
		return false
	agree := 6 * SwSB
	if (SwWMeas or (SwPostT and now - SwPostT < 1.0))
		agree := 10 * SwSB
	if (Abs(a1 - a2) > agree or Abs(b1 - b2) > agree)
		return false
	w1 := b1 - a1 + 1
	if (w1 < 0.08 * WindowWidth or w1 > 0.5 * WindowWidth)
		return false
	m := Round(0.2 * SwPitch)
	if (SwInZone(a1, m) or SwInZone(b1, m) or SwInZone(a2, m) or SwInZone(b2, m))
		return false
	e1 := SwZoneLen(a1, b1)
	e2 := SwZoneLen(a2, b2)
	c1 := SwCover(ra, a1, b1)
	c2 := SwCover(rb, a2, b2)
	w2 := b2 - a2 + 1
	if ((c1 < 0.85 * w1 or c2 < 0.85 * w2) and (e1 > 0.7 * w1 or 0.15 * c1 + 0.85 * SwCoverX(ra, a1, b1) < 0.85 * (w1 - e1) or 0.15 * c2 + 0.85 * SwCoverX(rb, a2, b2) < 0.85 * (w2 - e2)))
		return false
	if (SwPhase and SwDarkTest())
		{
		g3 := Round(3 * SwSB)
		g9 := Round(9 * SwSB)
		for i, y in [yt, yb]
			{
			p := pCaptureBits + y * CaptureW * 4
			x := a1 - g9
			while (x <= a1 - g3)
				{
				if (x < 0 or SwLum(p + x * 4) >= 240)
					return false
				x++
				}
			x := b1 + g3
			while (x <= b1 + g9)
				{
				if (x >= CaptureW or SwLum(p + x * 4) >= 240)
					return false
				x++
				}
			}
		}
	cl := (a1 + a2) // 2
	cw := ((b1 - a1 + 1) + (b2 - a2 + 1)) / 2.0
	return true
}

SwFrameLearn(yt, cl, cw) {
	global pCaptureBits, CaptureW, SwFrLearned, SwFrR, SwFrG, SwFrB, SwPrmFr
	p := pCaptureBits + yt * CaptureW * 4
	n := 0
	r := 0
	g := 0
	b := 0
	Loop 32
		{
		x := Round(cl + cw * (A_Index - 0.5) / 32)
		if (x < 0 or x >= CaptureW)
			continue
		if (PcFind(p + x * 4, 1, 4, SwPrmFr) != 0)
			continue
		px := NumGet(p + x * 4, 0, "UInt")
		b += px & 0xFF
		g += (px >> 8) & 0xFF
		r += (px >> 16) & 0xFF
		n++
		}
	if (n < 12)
		return
	SwFrR := r // n
	SwFrG := g // n
	SwFrB := b // n
	SwSetFrame(SwFrR, SwFrG, SwFrB)
	SwFrLearned := true
	SwLog("frame " . SwFrR . "," . SwFrG . "," . SwFrB . " n=" . n)
}

SwFit(ra, rb, yt, yb, w, ByRef L) {
	global pCaptureBits, CaptureW, SwS, SwSB, SwLastL, WindowWidth, SwPrmBk, SwPrmBkI
	L := -1
	cands := []
	for i, rr in [ra, rb]
		{
		for j, v in rr
			{
			if (v[2] - v[1] + 1 < 6 * SwSB)
				continue
			cands.Push(v[1])
			cands.Push(v[2] - w + 1)
			}
		}
	if (!cands.Length())
		return false
	ka := []
	kb := []
	xa := 0
	xb := CaptureW - 1
	SwRuns(pCaptureBits + yt * CaptureW * 4, xa, xb, SwPrmBk, SwPrmBkI, 0, ka)
	SwRuns(pCaptureBits + yb * CaptureW * 4, xa, xb, SwPrmBk, SwPrmBkI, 0, kb)
	d := Round(0.04 * w)
	if (d < 4)
		d := 4
	lim := Round(0.1 * WindowWidth)
	best := -999999
	bestIn := 0
	bestEx := 0
	for i, c in cands
		{
		if (SwLastL >= 0 and Abs(c - SwLastL) > lim)
			continue
		inside := SwCoverX(ra, c, c + w - 1) + SwCoverX(rb, c, c + w - 1)
		ex := SwZoneLen(c, c + w - 1)
		outside := SwCoverX(ra, c - d, c - 1) + SwCoverX(ra, c + w, c + w + d - 1) + SwCoverX(rb, c - d, c - 1) + SwCoverX(rb, c + w, c + w + d - 1)
		dark := SwCover(ka, c, c + w - 1) + SwCover(kb, c, c + w - 1)
		sc := inside - outside - 5 * dark
		if (SwLastL >= 0)
			sc -= Abs(c - SwLastL) * 0.25
		if (sc > best)
			{
			best := sc
			L := c
			bestIn := inside
			bestEx := ex
			}
		}
	pl := (L < 0) ? 0 : SwCover(ra, L, L + w - 1) + SwCover(rb, L, L + w - 1)
	if (L < 0 or ((bestEx > 0.7 * w or 0.3 * pl + 0.7 * bestIn < 1.4 * (w - bestEx)) and pl < 1.4 * w))
		{
		L := -1
		return false
		}
	return true
}

SwPianoFind(xa, xb) {
	global pCaptureBits, CaptureW, CaptureH, SwS, SwSB, SwFrTop, SwPrmBk, SwPrmBkI
	yb := SwFrTop + Round(21 * SwSB)
	yu := SwFrTop + Round(13 * SwSB)
	if (yb >= CaptureH or yu < 0)
		return -1
	if (xa < 0)
		xa := 0
	if (xb > CaptureW - 1)
		xb := CaptureW - 1
	rr := []
	SwRuns(pCaptureBits + yb * CaptureW * 4, xa, xb, SwPrmBk, SwPrmBkI, 0, rr)
	pu := pCaptureBits + yu * CaptureW * 4
	for i, v in rr
		{
		ln := v[2] - v[1] + 1
		if (ln < 40 * SwSB or ln > 62 * SwSB)
			continue
		bright := 0
		x := v[1]
		while (x <= v[2])
			{
			if (SwLum(pu + x * 4) >= 320)
				bright++
			x++
			}
		if (bright < 0.6 * ln)
			continue
		return (v[1] + v[2]) / 2.0
		}
	return -1
}

SwPianoCheck() {
	global SwBarL, SwBarW, SwPiano, SwPianoDis, SwWRing, SwW, FishBarLeft, WindowWidth, SwLastL, SwLastC
	SwPiano := -1
	xa := SwBarL - Round(FishBarLeft)
	pc := SwPianoFind(xa, xa + SwBarW - 1)
	if (pc < 0)
		return
	SwPiano := Round(FishBarLeft) + pc
	c := SwBarL + SwBarW / 2.0
	if (Abs(c - SwPiano) > 0.015 * WindowWidth)
		{
		SwPianoDis++
		if (SwPianoDis >= 3)
			{
			SwLog("piano disagrees " . Round(c) . " vs " . Round(SwPiano) . " w=" . Round(SwW))
			SwWRing := []
			SwBarL := Round(SwPiano - SwBarW / 2.0)
			SwLastL := SwBarL - Round(FishBarLeft)
			SwLastC := SwBarL + SwBarW / 2.0
			SwPianoDis := 0
			}
		}
	else
		SwPianoDis := 0
}

SwFishScan(now) {
	global pCaptureBits, CaptureW, CaptureH, SwS, SwSB, SwFrTop, SwFishX, SwFishAt, SwFishLast, FishBarLeft, WindowWidth, SwPrmCap, SwPrmCapI, SwPrmHd, SwPrmHdI, SwFishHeld
	global SwFrMiss, SwFound, SwBarL, SwBarW
	global SwXCap, SwXCapN, SwXHd, SwXHdN
	SwFishX := -1
	yc := SwFrTop - Round(5 * SwSB)
	yh := SwFrTop - Round(41 * SwSB)
	if (yh < 0 or yc >= CaptureH)
		return
	xa := Round(WindowWidth * 0.225) - Round(FishBarLeft)
	xb := Round(WindowWidth * 0.775) - Round(FishBarLeft)
	if (xa < 0)
		xa := 0
	if (xb > CaptureW - 1)
		xb := CaptureW - 1
	rc := []
	rh := []
	SwRuns(pCaptureBits + yc * CaptureW * 4, xa, xb, SwPrmCap, SwPrmCapI, 0, rc)
	if (SwXCapN)
		SwRunsX(pCaptureBits + yc * CaptureW * 4, xa, xb, &SwXCap, SwXCapN, 0, rc)
	SwRuns(pCaptureBits + yh * CaptureW * 4, xa, xb, SwPrmHd, SwPrmHdI, 0, rh)
	if (SwXHdN)
		SwRunsX(pCaptureBits + yh * CaptureW * 4, xa, xb, &SwXHd, SwXHdN, 0, rh)
	caps := []
	for i, v in rc
		{
		ln := v[2] - v[1] + 1
		if (ln >= Floor(6 * SwSB) and ln <= Round(20 * SwSB))
			caps.Push((v[1] + v[2]) / 2.0)
		}
	heads := []
	for i, v in rh
		{
		ln := v[2] - v[1] + 1
		if (ln >= Floor(16 * SwSB) and ln <= Round(38 * SwSB))
			heads.Push((v[1] + v[2]) / 2.0)
		}
	fx := -1
	for i, c in caps
		{
		for j, h in heads
			{
			if (c - h >= -3 * SwSB and c - h <= 16 * SwSB)
				{
				fx := c
				break
				}
			}
		if (fx >= 0)
			break
		}
	if (fx < 0 and caps.Length() = 1)
		fx := caps[1]
	if (fx < 0 and heads.Length() = 1 and SwFishLast >= 0 and now - SwFishAt < 0.2)
		{
		h := heads[1] + 7.5 * SwSB
		if (Abs(Round(FishBarLeft) + h - SwFishLast) <= 0.05 * WindowWidth)
			fx := h
		}
	if (fx < 0)
		{
		held := (SwFishLast >= 0 and now - SwFishAt < 0.6 and SwFrMiss = 0 and SwFound and SwFishLast >= SwBarL + 0.15 * SwBarW
			and SwFishLast <= SwBarL + 0.85 * SwBarW and SwGlowNear(SwFishLast - Round(FishBarLeft), 1.1, 0.7, now))
		if (held)
			{
			SwFishX := SwFishLast
			if (!SwFishHeld)
				SwLog("fish held at " . Round(SwFishLast))
			}
		SwFishHeld := held
		return
		}
	SwFishHeld := false
	SwFishX := Round(FishBarLeft) + fx
	SwFishLast := SwFishX
	SwFishAt := now
}

SwDarkTest() {
	global pCaptureBits, CaptureW, SwS, SwSB, SwFrTop, FishBarLeft, WindowWidth, SwZL
	y := SwFrTop - Round(12 * SwSB)
	if (y < 0)
		return false
	n := 0
	d := 0
	p := pCaptureBits + y * CaptureW * 4
	Loop 24
		{
		x := Round(WindowWidth * (0.225 + 0.55 * (A_Index - 0.5) / 24)) - Round(FishBarLeft)
		if (x < 0 or x >= CaptureW or SwInZone(x, 0))
			continue
		px := NumGet(p + x * 4, 0, "UInt")
		b := px & 0xFF
		g := (px >> 8) & 0xFF
		r := (px >> 16) & 0xFF
		mx := (r > g) ? ((r > b) ? r : b) : ((g > b) ? g : b)
		n++
		if (mx < 50)
			d++
		}
	return (n >= (SwZL.Length() ? 8 : 12) and d >= 0.85 * n)
}

SwGradLearn() {
	global pCaptureBits, CaptureW, CaptureH, SwS, SwSB, SwFrTop, SwCleanL, SwCleanW, SwGrad, SwGradOk, SwDarkR, SwDarkG, SwDarkB
	if (SwCleanL < 0 or SwCleanW < 20)
		return
	y := SwFrTop + Round(44 * SwSB)
	if (y >= CaptureH)
		return
	p := pCaptureBits + y * CaptureW * 4
	c := SwCleanL + SwCleanW / 2.0
	last := -1
	Loop 64
		{
		x := Round(SwCleanL + SwCleanW * (A_Index - 0.5) / 64)
		if (x < 0 or x >= CaptureW)
			continue
		if (Abs(x - c) <= 32 * SwSB)
			{
			if (last >= 0)
				{
				NumPut(NumGet(SwGrad, last * 3, "UChar"), SwGrad, (A_Index - 1) * 3, "UChar")
				NumPut(NumGet(SwGrad, last * 3 + 1, "UChar"), SwGrad, (A_Index - 1) * 3 + 1, "UChar")
				NumPut(NumGet(SwGrad, last * 3 + 2, "UChar"), SwGrad, (A_Index - 1) * 3 + 2, "UChar")
				}
			continue
			}
		px := NumGet(p + x * 4, 0, "UInt")
		NumPut(px & 0xFF, SwGrad, (A_Index - 1) * 3, "UChar")
		NumPut((px >> 8) & 0xFF, SwGrad, (A_Index - 1) * 3 + 1, "UChar")
		NumPut((px >> 16) & 0xFF, SwGrad, (A_Index - 1) * 3 + 2, "UChar")
		last := A_Index - 1
		}
	n := 0
	r := 0
	g := 0
	b := 0
	for i, x in [SwCleanL - Round(9 * SwSB), SwCleanL - Round(6 * SwSB), SwCleanL - Round(3 * SwSB), SwCleanL + Round(SwCleanW) + Round(3 * SwSB), SwCleanL + Round(SwCleanW) + Round(6 * SwSB), SwCleanL + Round(SwCleanW) + Round(9 * SwSB)]
		{
		if (x < 0 or x >= CaptureW)
			continue
		px := NumGet(p + x * 4, 0, "UInt")
		if ((px & 0xFF) >= 60 or ((px >> 8) & 0xFF) >= 60 or ((px >> 16) & 0xFF) >= 60)
			continue
		b += px & 0xFF
		g += (px >> 8) & 0xFF
		r += (px >> 16) & 0xFF
		n++
		}
	if (n >= 3)
		{
		SwDarkR := r // n
		SwDarkG := g // n
		SwDarkB := b // n
		}
	SwGradOk := true
	SwLog("gradient learned L=" . SwCleanL . " w=" . Round(SwCleanW) . " dark=" . SwDarkR . "," . SwDarkG . "," . SwDarkB)
}

SwSlotStrokes(k) {
	global pCaptureBits, CaptureW, CaptureH, SwS, SwSB, SwFrTop, SwPitch, FishBarLeft, SwPrmCore, SwPrmCoreI
	cx := Round(SwSlotX(k)) - Round(FishBarLeft)
	half := Round(0.45 * SwPitch)
	a := cx - half
	b := cx + half
	if (a < 0)
		a := 0
	if (b > CaptureW - 1)
		b := CaptureW - 1
	if (b - a < 8)
		return 0
	lo := Round(4 * SwSB)
	if (lo < 3)
		lo := 3
	hi := Round(20 * SwSB)
	gap := Round(2 * SwSB)
	if (gap < 2)
		gap := 2
	cnt := 0
	marg := (SwSB < 0.8) ? 80 : 120
	for i, dy in [20, 32, 44, 56, 68]
		{
		y := SwFrTop + Round(dy * SwSB)
		if (y < 0 or y >= CaptureH)
			continue
		p := pCaptureBits + y * CaptureW * 4
		rr := []
		SwRuns(p, a, b, SwPrmCore, SwPrmCoreI, 0, rr)
		for j, v in rr
			{
			ln := v[2] - v[1] + 1
			if (ln < lo or ln > hi)
				continue
			cl := 0
			x := v[1]
			while (x <= v[2])
				{
				cl += SwLum(p + x * 4)
				x++
				}
			cl := cl // ln
			thr := cl + marg
			if (thr > 640)
				thr := 640
			okl := false
			x := v[1] - gap
			while (x < v[1])
				{
				if (x >= a and SwLum(p + x * 4) >= thr)
					okl := true
				x++
				}
			okr := false
			x := v[2] + 1
			while (x <= v[2] + gap)
				{
				if (x <= b and SwLum(p + x * 4) >= thr)
					okr := true
				x++
				}
			if (okl and okr)
				cnt++
			}
		}
	return cnt
}

SwSlotWhite(k) {
	global pCaptureBits, CaptureW, CaptureH, SwS, SwSB, SwFrTop, SwPitch, FishBarLeft, SwPrmWh, SwPrmWhI
	cx := Round(SwSlotX(k)) - Round(FishBarLeft)
	half := Round(0.45 * SwPitch)
	a := cx - half
	b := cx + half
	if (a < 0)
		a := 0
	if (b > CaptureW - 1)
		b := CaptureW - 1
	cnt := 0
	for i, dy in [24, 44, 64]
		{
		y := SwFrTop + Round(dy * SwSB)
		if (y < 0 or y >= CaptureH)
			continue
		rr := []
		SwRuns(pCaptureBits + y * CaptureW * 4, a, b, SwPrmWh, SwPrmWhI, 0, rr)
		for j, v in rr
			{
			ln := v[2] - v[1] + 1
			if (ln >= 3 * SwSB and ln <= 40 * SwSB)
				cnt++
			}
		}
	return (cnt >= 2)
}

SwSlotsScan(now, held := false) {
	global SwSlotSt, SwSlotFirst, SwSlotHits, SwSlotLvl, SwSlotGone, SwOrder, SwK0, SwLit, SwClicks, SwStop, SwStopWhy, SwTie, SwLastOnset, SwZ
	global SwSlotBlind, SwFishX, SwSB
	Loop 12
		{
		k := A_Index
		st := SwSlotSt[k]
		if (st >= 2)
			continue
		c := SwSlotStrokes(k)
		if (c >= 1)
			{
			SwSlotGone[k] := 0
			if (st = 0)
				{
				SwSlotSt[k] := 1
				SwSlotFirst[k] := now
				SwSlotLvl[k] := c
				SwSlotHits[k] := (c >= 2) ? 1 : 0
				}
			else
				SwSlotHits[k] := (c >= 2) ? SwSlotHits[k] + 1 : SwSlotHits[k]
			if (SwSlotSt[k] = 1 and (SwSlotHits[k] >= 2 or c >= 4))
				SwAssign(k, now)
			}
		else if (st = 1 and !held)
			{
			if (!SwSlotGone[k])
				SwSlotGone[k] := now
			else if (now - SwSlotGone[k] > 0.3)
				{
				SwSlotSt[k] := 0
				SwSlotHits[k] := 0
				SwSlotGone[k] := 0
				}
			}
		else if (st = 0 and !held and (SwFishX < 0 or Abs(SwFishX - SwSlotX(k)) >= 40 * SwSB))
			SwSlotBlind[k] := now
		}
}

SwAssign(k, now) {
	global SwSlotSt, SwSlotFirst, SwSlotLvl, SwOrder, SwK0, SwLit, SwClicks, SwStop, SwStopWhy, SwTie, SwLastOnset, SwZ, SwPhaseT, SwStarStableT, SwLitRaw, SwLitRawT, SwTieWas, SwSlotBlind
	SwSlotSt[k] := 2
	if (SwK0 < 0 and now - SwStarStableT >= 0.1 and SwLit = SwLitRaw and now - SwLitRawT >= 0.3)
		SwK0 := SwLit
	pos := SwOrder.Length() + 1
	i := SwOrder.Length()
	while (i >= 1)
		{
		o := SwOrder[i]
		if (SwSlotFirst[o] > SwSlotFirst[k] or (SwSlotFirst[o] = SwSlotFirst[k] and SwSlotLvl[o] < SwSlotLvl[k]))
			pos := i
		else
			break
		i--
		}
	if (pos <= SwClicks and !SwStop)
		{
		SwStop := true
		SwStopWhy := "late onset"
		SwLog("stop: late onset slot " . k)
		}
	SwOrder.InsertAt(pos, k)
	if (pos > 1 and Abs(SwSlotFirst[SwOrder[pos - 1]] - SwSlotFirst[k]) < 0.15)
		{
		SwTie[k] := 1
		SwTie[SwOrder[pos - 1]] := 1
		}
	if (pos < SwOrder.Length() and Abs(SwSlotFirst[SwOrder[pos + 1]] - SwSlotFirst[k]) < 0.15)
		{
		SwTie[k] := 1
		SwTie[SwOrder[pos + 1]] := 1
		}
	b := SwSlotBlind[k]
	if (b < SwPhaseT)
		b := SwPhaseT
	Loop % pos - 1
		{
		o := SwOrder[A_Index]
		if (o != k and SwSlotFirst[o] >= b - 0.05)
			{
			SwTie[o] := 1
			SwTie[k] := 1
			}
		}
	Loop % SwOrder.Length() - pos
		{
		o := SwOrder[pos + A_Index]
		bo := SwSlotBlind[o]
		if (bo < SwPhaseT)
			bo := SwPhaseT
		if (SwSlotFirst[k] >= bo - 0.05)
			{
			SwTie[o] := 1
			SwTie[k] := 1
			}
		}
	Loop 12
		{
		if (SwTie[A_Index] = 1)
			SwTieWas[A_Index] := 1
		}
	SwLastOnset := now
	SwLog("onset slot " . k . " rank " . pos . " t+" . Round((now - SwPhaseT) * 1000) . " lvl " . SwSlotLvl[k] . (SwTie[k] ? " tie" : ""))
}

SwZodiac(i) {
	global SwZ
	return SwZ[Mod(i, 12) + 1]
}

SwClickStep() {
	if (KittyMode())
		return KittyClickStep()
	global SwFrStillT, SwVetoM, SwVetoZ, SwDwell, SwDwellPN, SwPressN, SwClickStall, SwFrameT, SwReactEst, SwUnsureK, SwUnsureT, SwUnsureR, SwPressK, SwWantK, SwWantT, SwLitRaw
	global SwClickSigns, SwStop, SwStopWhy, SwPhase, SwStarsValid, SwFound, SwFishX, SwLit, SwK0, SwOrder, SwSlotSt, SwSlotFirst, SwClicks, SwClickAt, SwClickLit, SwClickSlot, SwFastClicks
	global SwRetry, SwLastClick, SwLastOnset, SwTie, SwLockFail, SwBarL, SwBarW, SwS, SwSB, SwFrMiss, WindowWidth, SwPhaseT, SwStarStableT, SwPurpleN, SwFrMoveT, SwLitRaw, SwClickTook, SwLitRawT
	global SwTieWas, SwSlotGone, PrecisionDown, PrecisionDownAt, QpcFreq, SwSlotBlind, SwBarHold, MacroRunning, SwRetryClicks, SwTryAt, SwOverS
	SwPressTick()
	if (SwPhase and SwClickSigns)
		SwCursorGuard()
	if (SwPressK)
		return
	if (SwWantK)
		{
		if (SwStop or SwLockFail or !SwPhase or !SwClickSigns or !MacroRunning)
			SwWantK := 0
		else if (SwSlotWhite(SwWantK) or (SwClickAt and SwWantK = SwClickSlot and (SwLitRaw = SwClickLit + 1 or (SwClickLit = 11 and SwLitRaw = 0))))
			{
			SwLog("want dropped slot " . SwWantK)
			SwWantK := 0
			}
		else if (SwNow() - SwWantT > 0.25)
			{
			SwLog("want expired slot " . SwWantK)
			SwWantK := 0
			}
		else if ((!SwFound and !SwBarHold) or SwFishX < 0)
			return
		else if ((SwFishX < SwBarL - 10 * SwSB or SwFishX > SwBarL + SwBarW + 10 * SwSB) and !(SwFastClicks and !PrecisionDown and SwFishX < SwBarL - 10 * SwSB))
			{
			SwLog("want dropped slot " . SwWantK . " (fish outside)")
			SwWantK := 0
			}
		else
			{
			SwDoClick(SwWantK, SwWantT)
			return
			}
		}
	if (!SwClickSigns or SwStop or SwLockFail or !SwPhase or !SwStarsValid)
		return
	now := SwNow()
	if (SwClickAt and (SwLit = SwClickLit + 1 or (SwClickLit = 11 and SwLit = 0)))
		{
		if (SwDwell)
			SwReactLearn()
		SwSlotSt[SwClickSlot] := 3
		SwClickAt := 0
		SwRetry := 0
		SwPurpleN := 0
		SwPressN := 0
		SwTryAt := 0
		SwOverS := 0
		SwLog("click ok slot " . SwClickSlot . " lit " . SwLit)
		if (SwDwell)
			SwDwellEnd()
		return
		}
	if ((!SwFound and !SwBarHold) or SwFishX < 0)
		return
	if (SwClickAt)
		{
		if (SwLit != SwClickLit)
			{
			SwStop := true
			SwStopWhy := "lit " . SwClickLit . "->" . SwLit
			SwLog("stop: " . SwStopWhy)
			return
			}
		ta := (SwRetryClicks and SwTryAt > SwClickAt) ? SwTryAt : SwClickAt
		fout := (SwFishX < SwBarL - 10 * SwSB or SwFishX > SwBarL + SwBarW + 10 * SwSB) and !(SwFastClicks and !PrecisionDown and SwFishX < SwBarL - 10 * SwSB)
		left := SwRetryClicks and SwPressN + SwRetry < 3 and SwClickSlot != SwOverS
		more := left and !fout
		if (SwDwell)
			{
			if (SwLitRaw != SwClickLit or SwSlotWhite(SwClickSlot) or SwFrameT - SwClickAt >= 0.5)
				{
				if (SwLitRaw = SwClickLit + 1 or (SwClickLit = 11 and SwLitRaw = 0))
					SwReactLearn()
				SwDwellEnd()
				}
			else
				{
				SwDwellPN := (SwSlotStrokes(SwClickSlot) >= 2) ? SwDwellPN + 1 : 0
				fl := Max(0.35, 1.5 * SwReactEst) + SwClickStall
				if (SwDwellPN >= 2 and (SwRetryClicks ? more : SwPressN < 1) and fl <= 0.45 and SwFrameT - ta >= fl and !(SwFrMoveT and now - SwFrMoveT < 0.4))
					{
					SwPressN := SwPressN + 1
					SwDwellPN := 0
					SwTryAt := now
					SwLog("repress " . SwPressN . " slot " . SwClickSlot)
					SwDoClick(SwClickSlot, now)
					return
					}
				}
			}
		if (now - ta < 1.0 + SwClickTook)
			return
		if (SwSlotWhite(SwClickSlot))
			{
			if (now - SwClickAt < 1.0 or (SwLitRaw != SwClickLit and now - SwClickAt < 1.5))
				return
			SwStop := true
			SwStopWhy := "white, star not lit"
			SwLog("stop: " . SwStopWhy)
			return
			}
		if (SwSlotStrokes(SwClickSlot) >= 2)
			SwPurpleN := SwPurpleN + 1
		else
			SwPurpleN := 0
		if (SwPurpleN >= 2 and (SwRetryClicks ? more : SwRetry < 1) and !(SwFrMoveT and now - SwFrMoveT < 0.4) and now - SwLitRawT >= 0.3)
			{
			SwRetry := SwRetry + 1
			SwPurpleN := 0
			SwTryAt := now
			SwLog("retry " . SwRetry . " slot " . SwClickSlot . " (still purple)")
			SwDoClick(SwClickSlot, now)
			return
			}
		if (now - ta < 1.5 or (left and fout))
			return
		SwStop := true
		SwStopWhy := "click failed"
		SwLog("stop: " . SwStopWhy)
		return
		}
	if (SwLit != SwLitRaw)
		return
	if (SwK0 < 0)
		{
		if (now - SwStarStableT < 0.1 or now - SwLitRawT < 0.3 or !SwOrder.Length())
			return
		SwK0 := SwLit
		SwLog("k0 " . SwK0)
		}
	if (SwLit >= 12 or now - SwLastClick < (SwFastClicks ? 0.05 : 0.2))
		return
	if (SwLit < SwK0)
		{
		SwStop := true
		SwStopWhy := "lit below k0"
		SwLog("stop: " . SwStopWhy)
		return
		}
	i := SwLit - SwK0 + 1
	if (i > SwOrder.Length())
		return
	k := SwOrder[i]
	if (SwSlotSt[k] = 3)
		{
		SwStop := true
		SwStopWhy := "target already clicked"
		SwLog("stop: " . SwStopWhy . " slot " . k)
		return
		}
	if (!SwFound and (SwTie[k] or SwTieWas[k]))
		return
	fast := (SwFastClicks and !SwTie[k] and !SwTieWas[k])
	if (now - SwSlotFirst[k] < (SwFastClicks ? (SwTie[k] ? 0.2 : 0.1) : 0.35) or SwSlotWhite(k))
		return
	settled := (SwOrder.Length() >= 12 - SwK0) or (SwOrder.Length() > i) or (now - SwLastOnset >= (SwFastClicks ? 0.15 : 0.35))
	if (!settled)
		return
	if (fast)
		{
		Loop 12
			{
			if (A_Index != k and SwSlotSt[A_Index] = 1 and !SwSlotGone[A_Index] and now - SwSlotFirst[A_Index] < 0.5 and (SwSlotFirst[A_Index] <= SwSlotFirst[k] + 0.15 or Max(SwSlotBlind[A_Index], SwPhaseT) <= SwSlotFirst[k] + 0.15))
				return
			}
		}
	if (SwFrMiss or (SwFrMoveT and now - SwFrMoveT < 0.4 and now - SwFrStillT < 0.15))
		return
	if ((SwFishX < SwBarL - 10 * SwSB or SwFishX > SwBarL + SwBarW + 10 * SwSB) and !(SwFastClicks and !PrecisionDown and SwFishX < SwBarL - 10 * SwSB))
		return
	z := Mod(SwK0 + i - 1, 12)
	if (SwTie[k])
		{
		j := i + 1
		while (j <= SwOrder.Length() and SwTie[SwOrder[j]])
			j++
		if (j - 1 > i)
			{
			best := k
			bestS := -9
			secondS := -9
			nleft := 0
			lone := 0
			firstLeft := 0
			Loop % j - i
				{
				kk := SwOrder[i + A_Index - 1]
				if (z = SwVetoZ and (SwVetoM >> (kk - 1)) & 1)
					continue
				tdZ := -1
				tdS := -9
				sc := SwTplBest2(kk, z, tdZ, tdS)
				if (tdS >= 0.5 and tdZ != z and tdS >= sc + 0.2)
					{
					SwLog("tie drop slot " . kk . " looks like " . SwZodiac(tdZ) . " (" . Round(tdS, 3) . ")")
					continue
					}
				if (nleft = 0)
					firstLeft := kk
				nleft++
				lone := kk
				if (sc > bestS)
					{
					secondS := bestS
					bestS := sc
					best := kk
					}
				else if (sc > secondS)
					secondS := sc
				}
			if (nleft = 1)
				best := lone
			else if (nleft > 1 and !(bestS >= 0.5 and bestS - secondS >= 0.08))
				{
				best := firstLeft
				SwLog("tie by order slot " . best . " for " . SwZodiac(z) . " (" . Round(bestS, 3) . " vs " . Round(secondS, 3) . ")")
				}
			if (nleft = 0)
				{
				if (SwRecover(i, z))
					return
				if (now - SwLastOnset > 1.0)
					{
					SwStop := true
					SwStopWhy := "tie unresolved " . SwZodiac(z)
					SwLog("stop: " . SwStopWhy . " (" . Round(bestS, 3) . " vs " . Round(secondS, 3) . ")")
					}
				return
				}
			if (best != k)
				{
				Loop % SwOrder.Length()
					{
					if (SwOrder[A_Index] = best)
						{
						SwOrder.RemoveAt(A_Index)
						break
						}
					}
				SwOrder.InsertAt(i, best)
				SwLog("tie pick slot " . best . " for " . SwZodiac(z) . " (" . Round(bestS, 3) . ")")
				k := best
				}
			}
		SwTie[k] := 0
		}
	if (SwFastClicks and PrecisionDown)
		{
		DllCall("QueryPerformanceCounter", "Int64*", qn)
		if ((qn - PrecisionDownAt) * 1000.0 / QpcFreq < 250)
			return
		}
	if (fast)
		{
		if (SwTplOk(k, z) = 0)
			{
			if (SwRecover(i, z))
				return
			if (SwRetryClicks)
				{
				SwOverride(i, k, z, now)
				return
				}
			SwStop := true
			SwStopWhy := "shape veto " . SwZodiac(z) . " slot " . k
			SwLog("stop: " . SwStopWhy)
			return
			}
		SwDoClick(k, now)
		return
		}
	res := SwTplOk(k, z)
	if (res = 1)
		{
		SwDoClick(k, now)
		return
		}
	rearm := (SwTieWas[k] and i < SwOrder.Length() and SwTie[SwOrder[i + 1]])
	if (res = 3)
		{
		if (SwUnsureK != k * 16 + z)
			{
			SwUnsureK := k * 16 + z
			SwUnsureT := now
			}
		if ((!SwFastClicks and !SwRetryClicks) or now - SwUnsureT < 0.2)
			return
		if (rearm and SwUnsureR != k * 16 + z)
			{
			SwUnsureR := k * 16 + z
			SwTie[k] := 1
			SwLog("unsure retie slot " . k . " for " . SwZodiac(z))
			return
			}
		SwLog("unsure click slot " . k . " for " . SwZodiac(z))
		SwDoClick(k, now)
		return
		}
	if (SwRecover(i, z))
		return
	if (rearm)
		{
		if (SwVetoZ != z)
			{
			SwVetoZ := z
			SwVetoM := 0
			}
		SwVetoM := SwVetoM | (1 << (k - 1))
		SwTie[k] := 1
		SwLog("tie retry slot " . k . " not " . SwZodiac(z))
		return
		}
	if (SwRetryClicks)
		{
		SwOverride(i, k, z, now)
		return
		}
	SwStop := true
	SwStopWhy := "shape veto " . SwZodiac(z) . " slot " . k
	SwLog("stop: " . SwStopWhy)
}

SwOverride(i, k, z, now) {
	global SwOverK, SwOverT, SwOverL, SwOverR, SwOverS, SwRecZ
	if (SwOverK != k * 16 + z or now - SwOverL > 0.1)
		{
		SwOverK := k * 16 + z
		SwOverT := now
		}
	SwOverL := now
	if (now - SwOverT < 0.2)
		return
	if (SwOverR != z)
		{
		SwOverR := z
		SwRecZ := -1
		if (SwRecover(i, z))
			return
		}
	SwOverS := k
	SwLog("veto override slot " . k . " for " . SwZodiac(z))
	SwDoClick(k, now)
}

SwCursorGuard() {
	global RobloxHwnd, MacroRunning, FishBarLeft, FishBarRight, FishBarTop, FishBarBottom, WindowHeight, LookDownX, LookDownY
	global SwPreK, SwPreX, SwPreY, SwPreAt, SwPreNudge, SwPreNudgeAt, SwStop, SwDwell, SwClickSlot, SwClickAt, SwFastClicks
	global SwPressK, SwHov1, SwMoveOn, SwHyb, SwWantK, SwLockN, SwLockFail, SwStopWhy, SwWantStrk
	if (!MacroRunning or !RobloxHwnd or !WinActive("ahk_id " . RobloxHwnd))
		return false
	if (SwPressK)
		return false
	moved := false
	if (SwPreK)
		{
		CoordMode, Mouse, Screen
		MouseGetPos, mx, my
		el := SwNow() - SwPreAt
		if (Abs(mx - SwPreX - SwPreNudge) > 2 or Abs(my - SwPreY) > 2)
			{
			CoordMode, Mouse, Client
			SwPreK := 0
			SwDwell := false
			moved := true
			SwLog("prehover ended (cursor moved)")
			if (SwWantK and (Abs(mx - SwPreX - SwPreNudge) > 8 or Abs(my - SwPreY) > 8))
				{
				SwWantStrk := SwWantStrk + 1
				if (SwWantStrk >= 3)
					{
					SwWantK := 0
					SwLockN++
					SwLockFail := true
					SwStop := true
					SwStopWhy := "cursor locked"
					SwLog("stop: cursor locked (" . mx . "," . my . " vs " . SwPreX . "," . SwPreY . ")")
					}
				}
			}
		else if (SwStop or el >= (KittyMode() ? 1.2 : 0.8))
			{
			CoordMode, Mouse, Client
			SwPreEnd(SwStop ? "stop" : "timeout")
			return true
			}
		else if (SwDwell and SwFastClicks and SwPreK = SwClickSlot and SwNow() - SwClickAt >= SwMoveOn - SwHyb)
			{
			rem := SwMoveOn - (SwNow() - SwClickAt)
			if (rem > 0)
				RfSpinFor(rem * 1000)
			CoordMode, Mouse, Client
			SwPreNext()
			return false
			}
		else
			{
			h1 := SwFastClicks ? SwHov1 : 0.075
			if (!SwPreNudge and el >= h1 - SwHyb)
				{
				rem := h1 - el
				if (rem > 0)
					RfSpinFor(rem * 1000)
				MouseMove, % SwPreX + 1, % SwPreY, 0
				SwPreNudge := 1
				SwPreNudgeAt := SwNow()
				}
			CoordMode, Mouse, Client
			return false
			}
		}
	MouseGetPos, mx, my
	if (my < FishBarTop - 0.03 * WindowHeight or my > FishBarBottom or mx < FishBarLeft or mx > FishBarRight)
		return false
	MouseMove, %LookDownX%, %LookDownY%, 0
	if (moved)
		SwParkSet()
	SwLog("cursor parked from " . mx . "," . my)
	return true
}

SwDoClick(k, now) {
    global KittyDiagIssuedN
	global RobloxHwnd, PrecisionDown, PrecisionUpAt, SwFishX, SwSB, SwFrTop, FishBarTop, SwClickLit, SwClickSlot, SwLit, SwLockFail, SwLockN, SwStop, SwStopWhy, SwLastStep, SwFastClicks
	global SwPreK, SwPreX, SwPreY, SwPreAt, SwPreNudge, SwPreNudgeAt, ControlMode, MacroRunning
	global SwDwell, SwPressN, SwWantK, SwWantT, SwWantNom, SwWantPre, SwWantSx, SwWantSy, SwWantCx, SwWantCy, SwPressK, SwPressQ, SwPressMs, SwPressDecT, SwPressNom, SwPressCx, SwPressCy, SwPressPre, SwPressSx, SwPressSy, SwHov1, SwHov2, SwHyb
	global SwWantStrk, SwPressLit
	if (SwPressK)
		return false
	if (!RobloxHwnd or !WinActive("ahk_id " . RobloxHwnd))
		return false
	wasWant := SwWantK
	atomic := (ControlMode = "Manual" or !MacroRunning)
	nomA := 0
	if (PrecisionDown or GetKeyState("LButton"))
		{
		send {lbutton up}
		PrecisionDown := false
		DllCall("QueryPerformanceCounter", "Int64*", PrecisionUpAt)
		}
	if (wasWant = k)
		{
		cx := SwWantCx
		cy := SwWantCy
		sx := SwWantSx
		sy := SwWantSy
		}
	else
		{
		cx := Round(SwSlotX(k))
		if (Abs(SwFishX - cx) < 20 * SwSB)
			cx := cx + ((SwFishX >= cx) ? -Round(22 * SwSB) : Round(22 * SwSB))
		cy := Round(FishBarTop) + SwFrTop + Round(44 * SwSB)
		VarSetCapacity(pt, 8, 0)
		NumPut(cx, pt, 0, "Int")
		NumPut(cy, pt, 4, "Int")
		DllCall("ClientToScreen", "Ptr", RobloxHwnd, "Ptr", &pt)
		sx := NumGet(pt, 0, "Int")
		sy := NumGet(pt, 4, "Int")
		}
	h1 := KittyMode() ? 0.025 : (SwFastClicks ? SwHov1 : 0.075)
	h2 := KittyMode() ? 0.025 : (SwFastClicks ? SwHov2 : 0.075)
	CoordMode, Mouse, Screen
	pre := false
	if (SwPreK = k and Abs(sx - SwPreX) <= 3 and Abs(sy - SwPreY) <= 3)
		{
		MouseGetPos, mx, my
		if (Abs(mx - SwPreX - SwPreNudge) <= 2 and Abs(my - SwPreY) <= 2)
			{
			pre := true
			sx := SwPreX
			sy := SwPreY
			}
		}
	if (!pre)
		{
		MouseMove, %sx%, %sy%, 0
		SwPreX := sx
		SwPreY := sy
		SwPreK := k
		SwPreNudge := 0
		SwPreNudgeAt := 0
		SwPreAt := SwNow()
		SwDwell := false
		if (!atomic)
			{
			CoordMode, Mouse, Client
			if (wasWant != k)
				{
				SwWantK := k
				SwWantT := now
				SwWantNom := (h1 + h2) * 1000
				SwWantPre := false
				SwWantSx := sx
				SwWantSy := sy
				SwWantCx := cx
				SwWantCy := cy
				SwWantStrk := 0
				}
			else
				{
				SwWantNom := SwWantNom + (h1 + h2) * 1000
				SwWantPre := false
				}
			return false
			}
		RfSpinFor(h1 * 1000)
		MouseMove, % sx + 1, % sy, 0
		SwPreNudge := 1
		SwPreNudgeAt := SwNow()
		RfSpinFor(h2 * 1000)
		nomA := (h1 + h2) * 1000
		}
	else
		{
		if (!SwPreNudge)
			{
			rem := SwPreAt + h1 - SwNow()
			if (rem > SwHyb and !atomic)
				{
				CoordMode, Mouse, Client
				if (!SwWantK)
					{
					SwWantK := k
					SwWantT := now
					SwWantNom := (rem + h2) * 1000
					SwWantPre := true
					SwWantSx := sx
					SwWantSy := sy
					SwWantCx := cx
					SwWantCy := cy
					SwWantStrk := 0
					}
				return false
				}
			if (rem > 0)
				{
				RfSpinFor(rem * 1000)
				nomA := nomA + rem * 1000
				}
			MouseMove, % sx + 1, % sy, 0
			SwPreNudge := 1
			SwPreNudgeAt := SwNow()
			}
		rem := SwPreNudgeAt + h2 - SwNow()
		if (rem > SwHyb and !atomic)
			{
			CoordMode, Mouse, Client
			if (!SwWantK)
				{
				SwWantK := k
				SwWantT := now
				SwWantNom := rem * 1000
				SwWantPre := true
				SwWantSx := sx
				SwWantSy := sy
				SwWantCx := cx
				SwWantCy := cy
				SwWantStrk := 0
				}
			return false
			}
		if (rem > 0)
			{
			RfSpinFor(rem * 1000)
			nomA := nomA + rem * 1000
			}
		}
	MouseGetPos, mx, my
	CoordMode, Mouse, Client
	if (Abs(mx - sx) > 8 or Abs(my - sy) > 8)
		{
		SwWantK := 0
		SwLockN++
		SwLockFail := true
		SwStop := true
		SwStopWhy := "cursor locked"
		SwLog("stop: cursor locked (" . mx . "," . my . " vs " . sx . "," . sy . ")")
		return false
		}
	pr := KittyMode() ? 80 : (SwPressN ? 120 : 90)
	SwPressNom := (wasWant ? SwWantNom : nomA) + pr
	SwPressDecT := wasWant ? SwWantT : now
	SwPressPre := wasWant ? SwWantPre : pre
	SwWantK := 0
	SwPreK := 0
	SwDwell := false
	SwPressLit := SwLit
	SwPressCx := cx
	SwPressCy := cy
	SwPressSx := sx
	SwPressSy := sy
	SwPressMs := pr
	if (KittyMode())
		KittyDiagIssuedN++
	SendInput {lbutton down}
	DllCall("QueryPerformanceCounter", "Int64*", SwPressQ)
	SwPressK := k
	SwLastStep := SwNow()
	if (atomic)
		{
		RfSpinFor(pr)
		SwPressEnd()
		}
	return true
}

SwPressTick() {
	global SwPressK, SwPressQ, SwPressMs, QpcFreq, SwHyb
	if (!SwPressK)
		return
	if (GetKeyState("LButton"))
		{
		DllCall("QueryPerformanceCounter", "Int64*", q)
		rem := SwPressMs - (q - SwPressQ) * 1000.0 / QpcFreq
		if (rem > 20)
			return
		if (rem > 0)
			RfSpinFor(rem)
		SendInput {lbutton up}
		}
	SwPressDone()
}

SwPressEnd() {
	global SwPressK
	if (!SwPressK)
		return
	if (GetKeyState("LButton"))
		SendInput {lbutton up}
	SwPressDone()
}

SwPressDone() {
	global SwPressK, SwPressDecT, SwPressNom, SwPressCx, SwPressCy, SwPressPre, SwPressSx, SwPressSy, SwPressN, SwRetry, SwClicks, SwClickAt, SwClickLit, SwClickTook, SwClickStall, SwPress0At, SwLastClick, SwLastStep
	global SwPreK, SwPreX, SwPreY, SwPreAt, SwPreNudge, SwPreNudgeAt, SwDwell, SwDwellPN, PrecisionUpAt, MacroRunning, ControlMode, SwPressLit, SwClickSlot
	k := SwPressK
	SwPressK := 0
	SwClickLit := SwPressLit
	SwClickSlot := k
	SwPreX := SwPressSx
	SwPreY := SwPressSy
	SwPreNudge := 1
	SwPreNudgeAt := SwNow()
	SwPreAt := SwPreNudgeAt
	SwPreK := k
	SwDwell := true
	SwDwellPN := 0
	DllCall("QueryPerformanceCounter", "Int64*", PrecisionUpAt)
	SwClickAt := SwNow()
	if (!SwPressN)
		SwPress0At := SwClickAt
	SwClickTook := SwClickAt - SwPressDecT
	SwClickStall := SwClickTook - SwPressNom / 1000.0
	if (SwClickStall < 0)
		SwClickStall := 0
	if (!SwRetry and !SwPressN)
		SwClicks++
	SwLastClick := SwClickAt
	SwLastStep := SwClickAt
	SwLog("click slot " . k . " at " . SwPressCx . "," . SwPressCy . " lit " . SwClickLit . " took " . Round(SwClickTook * 1000) . (SwPressPre ? " pre" : "") . (SwPressN ? " repress" : ""))
	if (!MacroRunning or ControlMode = "Manual")
		SwPreEnd("park")
}

SwDwellEnd() {
	global SwDwell, SwPreK, SwClickSlot
	SwDwell := false
	if (!SwPreK or SwPreK != SwClickSlot)
		return
	if (!SwPreNext())
		SwPreEnd("done")
}

SwPreNext() {
	if (KittyMode())
		return false
	global SwPreK, SwPreX, SwPreY, SwPreAt, SwPreNudge, SwFastClicks, MacroRunning, ControlMode, SwStop, SwK0, SwClickLit, SwOrder, SwSlotSt, SwClickSlot
	global SwFishX, SwSB, SwFrTop, FishBarTop, RobloxHwnd
	nk := 0
	if (MacroRunning and SwFastClicks and ControlMode != "Manual" and !SwStop and SwK0 >= 0 and SwClickLit < 11 and RobloxHwnd and WinActive("ahk_id " . RobloxHwnd))
		{
		i := SwClickLit - SwK0 + 2
		if (i >= 1 and i <= SwOrder.Length())
			{
			nk := SwOrder[i]
			if (nk = SwClickSlot or SwSlotSt[nk] != 2)
				nk := 0
			}
		}
	if (!nk)
		return false
	cx := Round(SwSlotX(nk))
	if (Abs(SwFishX - cx) < 20 * SwSB)
		cx := cx + ((SwFishX >= cx) ? -Round(22 * SwSB) : Round(22 * SwSB))
	cy := Round(FishBarTop) + SwFrTop + Round(44 * SwSB)
	VarSetCapacity(pt, 8, 0)
	NumPut(cx, pt, 0, "Int")
	NumPut(cy, pt, 4, "Int")
	DllCall("ClientToScreen", "Ptr", RobloxHwnd, "Ptr", &pt)
	SwPreX := NumGet(pt, 0, "Int")
	SwPreY := NumGet(pt, 4, "Int")
	CoordMode, Mouse, Screen
	MouseMove, %SwPreX%, %SwPreY%, 0
	CoordMode, Mouse, Client
	SwPreK := nk
	SwPreNudge := 0
	SwPreAt := SwNow()
	SwLog("prehover slot " . nk)
	return true
}

SwReactLearn() {
	global SwFrameT, SwClickAt, SwPress0At, SwPressN, SwReactEst
	lat := SwFrameT - SwClickAt
	if (SwPressN and lat < 0.10)
		lat := SwFrameT - SwPress0At
	SwReactEst := Max(lat, 0.8 * SwReactEst)
}

SwPreEnd(why) {
	global SwPreK, RobloxHwnd, SwParkX, SwParkY, SwDwell, SwPressK
	if (SwPressK)
		SwPressEnd()
	if (!SwPreK)
		return
	SwPreK := 0
	SwDwell := false
	if (RobloxHwnd)
		{
		SwParkSet()
		CoordMode, Mouse, Screen
		MouseMove, %SwParkX%, %SwParkY%, 0
		CoordMode, Mouse, Client
		}
	SwLog("prehover ended (" . why . ")")
}

SwParkSet() {
	global RobloxHwnd, LookDownX, LookDownY, SwParkAt, SwParkX, SwParkY, SwParkNudge
	VarSetCapacity(pt, 8, 0)
	NumPut(Round(LookDownX), pt, 0, "Int")
	NumPut(Round(LookDownY), pt, 4, "Int")
	DllCall("ClientToScreen", "Ptr", RobloxHwnd, "Ptr", &pt)
	SwParkX := NumGet(pt, 0, "Int")
	SwParkY := NumGet(pt, 4, "Int")
	SwParkAt := SwNow()
	SwParkNudge := 0
}

SwParkWait() {
	global SwParkAt, SwParkX, SwParkY, SwParkNudge
	el := SwNow() - SwParkAt
	if (el >= 0.07)
		{
		SwParkAt := 0
		return false
		}
	if (!SwParkNudge and el >= 0.04)
		{
		CoordMode, Mouse, Screen
		MouseMove, % SwParkX + 1, % SwParkY, 0
		CoordMode, Mouse, Client
		SwParkNudge := 1
		}
	return true
}

SwTplOk(k, z) {
	global SwTie, SwLastOnset, SwSlotFirst
	SwTplMask(k, m, kn)
	if (!IsObject(m))
		return 3
	s0 := SwTplScore(m, kn, z)
	s1 := SwTplScore(m, kn, Mod(z + 11, 12))
	s2 := SwTplScore(m, kn, Mod(z + 1, 12))
	SwLog("shape slot " . k . " " . SwZodiac(z) . " " . Round(s0, 3) . " prev " . Round(s1, 3) . " next " . Round(s2, 3))
	if (z < 11 and s2 >= 0.5 and s2 >= s0 + 0.15)
		return 0
	if (s0 < 0.05)
		return 3
	return 1
}

SwRecover(i, z) {
	global SwSlotSt, SwOrder, SwRecZ
	if (!SwTplSumFn() or z = SwRecZ)
		return false
	SwRecZ := z
	n := 0
	fk := 0
	fs := 0
	fo := 0
	Loop 12
		{
		kk := A_Index
		if (SwSlotSt[kk] >= 2 or SwSlotWhite(kk))
			continue
		SwTplMask(kk, m, kn)
		if (!IsObject(m))
			continue
		sc := SwTplScore(m, kn, z)
		ot := -9
		zz := z + 1
		while (zz < 12)
			{
			s := SwTplScore(m, kn, zz)
			if (s > ot)
				ot := s
			zz++
			}
		if (sc >= 0.35 and sc >= ot + 0.10)
			{
			n++
			fk := kk
			fs := sc
			fo := ot
			}
		}
	if (n != 1)
		return false
	SwSlotSt[fk] := 2
	SwOrder.InsertAt(i, fk)
	SwLog("recover slot " . fk . " for " . SwZodiac(z) . " (" . Round(fs, 3) . " vs " . Round(fo, 3) . ")")
	return true
}

SwTplBest2(k, z, ByRef tdZ, ByRef tdS) {
	tdZ := -1
	tdS := -9
	SwTplMask(k, m, kn)
	if (!IsObject(m))
		return -9
	sc := -9
	Loop % 12 - z
		{
		zz := z + A_Index - 1
		s := SwTplScore(m, kn, zz)
		if (zz = z)
			sc := s
		if (s > tdS)
			{
			tdS := s
			tdZ := zz
			}
		}
	return sc
}

SwTplBest(k, z) {
	SwTplMask(k, m, kn)
	if (!IsObject(m))
		return -9
	return SwTplScore(m, kn, z)
}

SwTplMask(k, ByRef m, ByRef kn) {
	global pCaptureBits, CaptureW, CaptureH, SwS, SwSB, SwFrTop, SwBarL, SwBarW, SwFishX, FishBarLeft, SwGrad, SwGradOk, SwGradDef, SwDarkR, SwDarkG, SwDarkB
	m := ""
	kn := ""
	cx := Round(SwSlotX(k)) - Round(FishBarLeft)
	sz := 64 * SwSB
	x0 := cx - sz / 2
	y0 := SwFrTop + 11 * SwSB
	cell := sz / 16
	L := SwBarL - Round(FishBarLeft)
	w := SwBarW
	c := L + w / 2.0
	fx := (SwFishX >= 0) ? SwFishX - Round(FishBarLeft) : -9999
	pG := SwGradOk ? &SwGrad : &SwGradDef
	mm := []
	kk := []
	Loop 256
		{
		mm.Push(0)
		kk.Push(0)
		}
	total := 0
	Loop 16
		{
		j := A_Index - 1
		Loop 16
			{
			i := A_Index - 1
			hit := 0
			kc := 0
			for a, oy in [0.25, 0.75]
				{
				y := Round(y0 + cell * (j + oy))
				if (y < 0 or y >= CaptureH)
					continue
				p := pCaptureBits + y * CaptureW * 4
				for b, ox in [0.25, 0.75]
					{
					x := Round(x0 + cell * (i + ox))
					if (x < 0 or x >= CaptureW)
						continue
					u := (x - L) / (w - 1.0)
					if (Abs(x - c) <= 30 * SwSB or Abs(x - fx) <= 10 * SwSB)
						continue
					if ((u < 0.03 and x >= L - 8 * SwSB) or (u > 0.97 and x <= L + w - 1 + 8 * SwSB))
						continue
					if (u >= 0.03 and u <= 0.97)
						{
						bin := Floor(u * 64)
						if (bin > 63)
							bin := 63
						eb := NumGet(pG + 0, bin * 3, "UChar")
						eg := NumGet(pG + 0, bin * 3 + 1, "UChar")
						er := NumGet(pG + 0, bin * 3 + 2, "UChar")
						}
					else
						{
						er := SwDarkR
						eg := SwDarkG
						eb := SwDarkB
						}
					px := NumGet(p + x * 4, 0, "UInt")
					db := Abs((px & 0xFF) - eb)
					dg := Abs(((px >> 8) & 0xFF) - eg)
					dr := Abs(((px >> 16) & 0xFF) - er)
					d := (db > dg) ? ((db > dr) ? db : dr) : ((dg > dr) ? dg : dr)
					kc++
					if (d >= 40)
						hit++
					}
				}
			if (kc >= 2)
				{
				mm[j * 16 + i + 1] := hit / kc
				kk[j * 16 + i + 1] := 1
				total++
				}
			}
		}
	if (total < 96)
		return
	m := mm
	kn := kk
}

SwTplScore(m, kn, z) {
	global SwTplF, SwTplFBuf
	if (!kn.HasKey("TpCnt"))
		SwTplPrep(m, kn)
	n := kn.TpCnt
	if (n < 16)
		return -9
	sa := kn.TpSumA
	saa := kn.TpSumAA
	best := -9
	if (kn.HasKey("TpPV"))
		{
		VarSetCapacity(sums, 216, 0)
		DllCall(SwTplSumFn(), "Ptr", kn.TpPV, "Ptr", kn.TpPO, "Int", n, "Ptr", &SwTplFBuf + z * 2048, "Ptr", &sums)
		Loop 9
			{
			o := (A_Index - 1) * 24
			sb := NumGet(sums, o, "Double")
			sbb := NumGet(sums, o + 8, "Double")
			sab := NumGet(sums, o + 16, "Double")
			num := sab - sa * sb / n
			den := (saa - sa * sa / n) * (sbb - sb * sb / n)
			if (den <= 0.000001)
				continue
			sc := num / Sqrt(den)
			if (sc > best)
				best := sc
			}
		return best
		}
	cv := kn.TpVals
	base := z * 256 + 1
	Loop 9
		{
		of := kn.TpOffs[A_Index]
		sb := 0
		sbb := 0
		sab := 0
		Loop % n
			{
			vb := SwTplF[base + of[A_Index]]
			va := cv[A_Index]
			sb := sb + vb
			sbb := sbb + vb * vb
			sab := sab + va * vb
			}
		num := sab - sa * sb / n
		den := (saa - sa * sa / n) * (sbb - sb * sb / n)
		if (den <= 0.000001)
			continue
		sc := num / Sqrt(den)
		if (sc > best)
			best := sc
		}
	return best
}

SwTplPrep(m, kn) {
	cv := []
	cj := []
	ci := []
	n := 0
	sa := 0
	saa := 0
	Loop 16
		{
		j := A_Index - 1
		Loop 16
			{
			i := A_Index - 1
			if (!kn[j * 16 + i + 1])
				continue
			va := m[j * 16 + i + 1]
			n++
			sa := sa + va
			saa := saa + va * va
			cv.Push(va)
			cj.Push(j)
			ci.Push(i)
			}
		}
	kn.TpCnt := n
	kn.TpSumA := sa
	kn.TpSumAA := saa
	if (SwTplSumFn())
		{
		kn.SetCapacity("TpBV", n * 8 + 8)
		kn.SetCapacity("TpBO", 9 * n * 4 + 8)
		pv := kn.GetAddress("TpBV")
		po := kn.GetAddress("TpBO")
		Loop % n
			NumPut(cv[A_Index], pv + (A_Index - 1) * 8, 0, "Double")
		q := 0
		Loop 3
			{
			dx := A_Index - 2
			Loop 3
				{
				dy := A_Index - 2
				Loop % n
					{
					NumPut(Mod(cj[A_Index] - dy + 16, 16) * 16 + Mod(ci[A_Index] - dx + 16, 16), po + q * 4, 0, "Int")
					q++
					}
				}
			}
		kn.TpPV := pv
		kn.TpPO := po
		return
		}
	of := []
	Loop 3
		{
		dx := A_Index - 2
		Loop 3
			{
			dy := A_Index - 2
			o := []
			Loop % n
				o.Push(Mod(cj[A_Index] - dy + 16, 16) * 16 + Mod(ci[A_Index] - dx + 16, 16))
			of.Push(o)
			}
		}
	kn.TpVals := cv
	kn.TpOffs := of
}

SwTplSumFn() {
	static pFn := "", Hex := "534C8B5424304531DB4183FB097D5B660F57C0660F57C9660F57D231C04439C07D2E48631A4883C204F2410F101CD9F20F1024C1F20F58C3660F28EBF20F59EBF20F58CDF20F59E3F20F58D4FFC0EBCDF2410F1102F2410F114A08F2410F1152104983C21841FFC3EB9F5BC3"
	if (pFn != "")
		return pFn
	pFn := 0
	if (A_PtrSize != 8)
		return 0
	n := StrLen(Hex) // 2
	p := DllCall("VirtualAlloc", "Ptr", 0, "Ptr", n, "UInt", 0x3000, "UInt", 0x04, "Ptr")
	if (!p)
		return 0
	Loop, %n%
		NumPut("0x" . SubStr(Hex, 2 * A_Index - 1, 2), p + 0, A_Index - 1, "UChar")
	if (!DllCall("VirtualProtect", "Ptr", p, "Ptr", n, "UInt", 0x20, "UIntP", oldProt))
		{
		DllCall("VirtualFree", "Ptr", p, "Ptr", 0, "UInt", 0x8000)
		return 0
		}
	tn := 20
	VarSetCapacity(tv, tn * 8, 0)
	VarSetCapacity(tofs, 9 * tn * 4, 0)
	VarSetCapacity(ttpl, 256 * 8, 0)
	VarSetCapacity(tout, 216, 0)
	Loop 256
		NumPut(Mod((A_Index - 1) * 13, 255) / 255.0, ttpl, (A_Index - 1) * 8, "Double")
	Loop % tn
		NumPut(Mod((A_Index - 1) * 7, 5) / 4.0, tv, (A_Index - 1) * 8, "Double")
	Loop % 9 * tn
		NumPut(Mod((A_Index - 1) * 37 + 11, 256), tofs, (A_Index - 1) * 4, "Int")
	DllCall(p, "Ptr", &tv, "Ptr", &tofs, "Int", tn, "Ptr", &ttpl, "Ptr", &tout)
	Loop 9
		{
		s := A_Index - 1
		sb := 0
		sbb := 0
		sab := 0
		Loop % tn
			{
			c := A_Index - 1
			vb := NumGet(ttpl, NumGet(tofs, (s * tn + c) * 4, "Int") * 8, "Double")
			va := NumGet(tv, c * 8, "Double")
			sb := sb + vb
			sbb := sbb + vb * vb
			sab := sab + va * vb
			}
		if (NumGet(tout, s * 24, "Double") != sb or NumGet(tout, s * 24 + 8, "Double") != sbb or NumGet(tout, s * 24 + 16, "Double") != sab)
			{
			DllCall("VirtualFree", "Ptr", p, "Ptr", 0, "UInt", 0x8000)
			return 0
			}
		}
	pFn := p
	return pFn
}

SwTip(now) {
	global RfTip13
	global KittyReason, SwFishX, SwTipT, SwPhase, SwLit, SwK0, SwOrder, SwClicks, SwStop, SwStopWhy, SwStarsValid, SwStarFound, SwFound, TooltipX, Tooltip13, MgInPlay
	if (now - SwTipT < 0.25)
		return
	SwTipT := now
	if (!MgInPlay)
		return
	if (!SwStarFound)
		txt := "Stellarwave: stars not found"
	else if (!SwPhase)
		txt := "Stellarwave: tracking"
	else if (SwStop)
		txt := "Stellarwave: stopped (" . SwStopWhy . ")"
	else
		txt := "Stellarwave: " . SwLit . "/12 lit, " . SwOrder.Length() . " signs seen, " . SwClicks . " clicked" . ((SwLit < 12) ? ", next " . SwZodiac(SwLit) : "")
	if (KittyMode())
		txt := "Kitty Keys: " . (SwFound ? "bar OK" : "bar missing") . " | " . (SwStarsValid ? SwLit . "/12 lit" : "stars missing") . " | " . (SwFishX >= 0 ? "fish OK" : "fish missing") . " | " . KittyReason . (SwStop ? " | " . SwStopWhy : "")
	RfTip13 = %txt%
}

RodTol(v) {
	if v is not number
		return 20
	v := Round(v)
	if (v < 0)
		return 0
	if (v > 255)
		return 255
	return v
}

RodCap(o, k, other, t) {
	i := 1
	while (i <= other.n and i <= 9)
		{
		d := Abs(o.r[k] - other.r[i])
		dg := Abs(o.g[k] - other.g[i])
		db := Abs(o.b[k] - other.b[i])
		if (dg > d)
			d := dg
		if (db > d)
			d := db
		c := (d = 0) ? -1 : (d - 1) // 2
		if (c < t)
			t := c
		i++
		}
	return t
}

PcPrmAt(a, r, g, b, tol, mode) {
	NumPut(b, a + 0, 0, "Int")
	NumPut(g, a + 0, 4, "Int")
	NumPut(r, a + 0, 8, "Int")
	NumPut(tol, a + 0, 12, "Int")
	NumPut(mode, a + 0, 16, "Int")
	NumPut(0, a + 0, 20, "Int")
	NumPut(b, a + 0, 24, "Int")
	NumPut(g, a + 0, 28, "Int")
	NumPut(r, a + 0, 32, "Int")
	NumPut(tol, a + 0, 36, "Int")
	NumPut(mode, a + 0, 40, "Int")
	NumPut(1, a + 0, 44, "Int")
}

PcFindAt(p, n, stride, a) {
	if (n <= 0)
		return -1
	pFn := PcFindPixFn()
	if (pFn)
		return DllCall(pFn, "Ptr", p, "Int", n, "Int", stride, "Ptr", a, "Int")
	return PcFindPixAhk(p, n, stride, NumGet(a + 0, 0, "Int"), NumGet(a + 0, 4, "Int"), NumGet(a + 0, 8, "Int"), NumGet(a + 0, 12, "Int"), NumGet(a + 0, 16, "Int"), NumGet(a + 0, 20, "Int"))
}

TryRowRunsAt(p, a, gap, rr) {
	global CaptureW
	x := 0
	n := 0
	s0 := -1
	e0 := -1
	while (x < CaptureW and n < 40)
		{
		s := PcFindAt(p + x * 4, CaptureW - x, 4, a)
		if (s < 0)
			break
		s += x
		e := PcFindAt(p + (s + 1) * 4, CaptureW - s - 1, 4, a + 24)
		e := (e < 0) ? CaptureW - 1 : s + e
		n++
		if (s0 >= 0 and s - e0 - 1 <= gap)
			e0 := e
		else
			{
			if (s0 >= 0)
				rr.Push([s0, e0])
			s0 := s
			e0 := e
			}
		x := e + 1
		}
	if (s0 >= 0)
		rr.Push([s0, e0])
}

TryRunsMerge(rr, gap) {
	j := 2
	while (j <= rr.Length())
		{
		v := rr[j]
		k := j - 1
		while (k >= 1 and rr[k][1] > v[1])
			{
			rr[k + 1] := rr[k]
			k--
			}
		rr[k + 1] := v
		j++
		}
	out := []
	for i, v in rr
		{
		n := out.Length()
		if (n and v[1] - out[n][2] - 1 <= gap)
			{
			if (v[2] > out[n][2])
				out[n][2] := v[2]
			}
		else
			out.Push([v[1], v[2]])
		}
	if (rr.Length())
		rr.RemoveAt(1, rr.Length())
	for i, v in out
		rr.Push(v)
}

TryFishLineAt(c, k) {
	global pCaptureBits, CaptureW, CaptureH
	if (c < 0 or c >= CaptureW)
		return false
	n := 0
	for i, y in [Floor(CaptureH * 0.30), Floor(CaptureH * 0.50), Floor(CaptureH * 0.70)]
		{
		p := pCaptureBits + y * CaptureW * 4
		v := NumGet(p + c * 4, 0, "UInt")
		a := (c - k >= 0) ? NumGet(p + (c - k) * 4, 0, "UInt") : -1
		b := (c + k < CaptureW) ? NumGet(p + (c + k) * 4, 0, "UInt") : -1
		if (a < 0)
			a := b
		if (b < 0)
			b := a
		if (a < 0)
			continue
		d := 0
		for j, sh in [0, 8, 16]
			{
			e := Abs(((v >> sh) & 0xFF) - ((((a >> sh) & 0xFF) + ((b >> sh) & 0xFF)) / 2))
			if (e > d)
				d := e
			}
		if (d >= 8)
			n++
		}
	return (n >= 2)
}

TryTrackAtX(x) {
	global pCaptureBits, CaptureW, CaptureH, TryhardTrackColors, TryhardTrackTol
	if (x < 0 or x >= CaptureW)
		return false
	tkL := RfColList(TryhardTrackColors)
	tkT := RodTol(TryhardTrackTol)
	tkN := 0
	for tkI, tkY in [Floor(CaptureH * 0.30), Floor(CaptureH * 0.50), Floor(CaptureH * 0.70)]
		{
		tkPx := NumGet(pCaptureBits + (tkY * CaptureW + x) * 4, 0, "UInt")
		tkB := tkPx & 0xFF
		tkG := (tkPx >> 8) & 0xFF
		tkR := (tkPx >> 16) & 0xFF
		if ((tkR + 16 >= tkB and tkR < 70 and tkB < 70 and (tkG < 40 or (tkG < 48 and tkR >= tkG))) or RfColHit(tkL, tkPx, tkT))
			tkN++
		}
	return (tkN >= 2)
}


MiguBarScan() {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft
	global MiguBarScanned, MiguBarFound, MiguBarL, MiguBarW
	if (MiguBarScanned)
		return MiguBarFound
	MiguBarScanned := true
	MiguBarFound := false
	if (CaptureW < 40 or CaptureH < 6)
		return false
	qRows := [Floor(CaptureH * 0.30), Floor(CaptureH * 0.50), Floor(CaptureH * 0.70)]
	qTrk := 0
	qOff := qRows[2] * CaptureW * 4
	qX := 0
	while (qX < CaptureW)
		{
		qP := NumGet(pCaptureBits + 0, qOff + (qX*4), "UInt")
		qB := qP & 0xFF
		qG := (qP >> 8) & 0xFF
		qR := (qP >> 16) & 0xFF
		if (qR > 150 and qG < 110 and (qR - qG) > 90 and (qR - qB) > 55)
			qTrk++
		qX++
		}
	if (qTrk < CaptureW * 0.25)
		return false
	VarSetCapacity(qHits, CaptureW, 0)
	for qI, qY in qRows
		{
		qOff := qY * CaptureW * 4
		qX := 0
		while (qX < CaptureW)
			{
			qP := NumGet(pCaptureBits + 0, qOff + (qX*4), "UInt")
			qB := qP & 0xFF
			qG := (qP >> 8) & 0xFF
			qR := (qP >> 16) & 0xFF
			if (qR > 190 and qG >= 140 and qG <= 245 and qB >= 90 and qB <= 215 and (qR - qB) > 40)
				NumPut(NumGet(qHits, qX, "UChar") + 1, qHits, qX, "UChar")
			qX++
			}
		}
	qGap := Round(CaptureW * 0.035)
	if (qGap < 12)
		qGap := 12
	qMinW := Round(CaptureW * 0.05)
	if (qMinW < 24)
		qMinW := 24
	qBestL := -1
	qBestLen := 0
	qRunS := -1
	qLast := -1
	qX := 0
	while (qX <= CaptureW)
		{
		qOn := false
		if (qX < CaptureW)
			qOn := (NumGet(qHits, qX, "UChar") >= 2)
		if (qOn)
			{
			if (qRunS < 0)
				qRunS := qX
			qLast := qX
			}
		else if (qRunS >= 0 and ((qX - qLast) > qGap or qX = CaptureW))
			{
			if ((qLast - qRunS + 1) > qBestLen)
				{
				qBestLen := qLast - qRunS + 1
				qBestL := qRunS
				}
			qRunS := -1
			}
		qX++
		}
	if (qBestL < 0 or qBestLen < qMinW or qBestLen > CaptureW * 0.85)
		return false
	MiguBarL := FishBarLeft + qBestL
	MiguBarW := qBestLen
	MiguBarFound := true
	return true
}

MiguScan() {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft, FishColor, FishBarColorTolerance
	global MiguFishX, MiguLastX, MiguScanned, MiguFound
	if (MiguScanned)
		return MiguFound
	MiguScanned := true
	MiguFound := false
	MiguFishX := -1
	if (CaptureW < 40 or CaptureH < 6)
		return false

	gkRows := [Floor(CaptureH * 0.30), Floor(CaptureH * 0.55), Floor(CaptureH * 0.85)]
	VarSetCapacity(gkBuf, CaptureW, 0)
	for gkI, gkY in gkRows
		{
		gkOff := gkY * CaptureW * 4
		gkX := 0
		while (gkX < CaptureW)
			{
			gkP := NumGet(pCaptureBits + 0, gkOff + (gkX*4), "UInt")
			if (((gkP >> 16) & 0xFF) < 110 and ((gkP >> 8) & 0xFF) < 35 and (gkP & 0xFF) < 40)
				NumPut(1, gkBuf, gkX, "UChar")
			gkX++
			}
		}
	gkMinW := Round(CaptureW * 0.005)
	if (gkMinW < 3)
		gkMinW := 3
	gkMaxW := Round(CaptureW * 0.034)
	if (gkMaxW < 12)
		gkMaxW := 12
	gkGap := Round(CaptureW * 0.006)
	if (gkGap < 3)
		gkGap := 3
	gkPad := Round(CaptureW * 0.004)
	if (gkPad < 2)
		gkPad := 2
	VarSetCapacity(gkMask, CaptureW, 0)
	gkX := 0
	while (gkX < CaptureW)
		{
		if (!NumGet(gkBuf, gkX, "UChar"))
			{
			gkX++
			continue
			}
		gkA := gkX
		gkLast := gkX
		while (gkX < CaptureW and (NumGet(gkBuf, gkX, "UChar") or (gkX - gkLast) <= gkGap))
			{
			if (NumGet(gkBuf, gkX, "UChar"))
				gkLast := gkX
			gkX++
			}
		gkW := gkLast - gkA + 1
		if (gkW < gkMinW or gkW > gkMaxW)
			continue
		gkM := gkA - gkPad
		if (gkM < 0)
			gkM := 0
		while (gkM <= gkLast + gkPad and gkM < CaptureW)
			{
			NumPut(1, gkMask, gkM, "UChar")
			gkM++
			}
		}

	gkList := RfColList(FishColor)
	if (gkList.n < 1)
		return false
	gkTol := FishBarColorTolerance
	if (gkTol < 6)
		gkTol := 6
	gkMinR := 255
	gkMinG := 255
	gkI := 1
	while (gkI <= gkList.n)
		{
		if (gkList.r[gkI] < gkMinR)
			gkMinR := gkList.r[gkI]
		if (gkList.g[gkI] < gkMinG)
			gkMinG := gkList.g[gkI]
		gkI++
		}
	gkMinR := gkMinR - gkTol
	gkMinG := gkMinG - gkTol
	gkFRows := []
	Loop, 5
		{
		gkY := Floor(CaptureH * (A_Index*2 - 1) / 10)
		if (gkY >= CaptureH)
			gkY := CaptureH - 1
		gkFRows.Push(gkY)
		}
	gkFW := Round(CaptureW * 0.03)
	if (gkFW < 8)
		gkFW := 8
	gkCandX := []
	gkCandV := []
	for gkPass, gkRi in [3, 2, 4]
		{
		gkOff := gkFRows[gkRi] * CaptureW * 4
		gkS := -1
		gkX := 0
		while (gkX <= CaptureW)
			{
			gkHit := false
			if (gkX < CaptureW and !NumGet(gkMask, gkX, "UChar"))
				{
				gkP := NumGet(pCaptureBits + 0, gkOff + (gkX*4), "UInt")
				if (((gkP >> 16) & 0xFF) >= gkMinR and ((gkP >> 8) & 0xFF) >= gkMinG)
					gkHit := RfColHit(gkList, gkP, gkTol)
				}
			if (gkHit)
				{
				if (gkS < 0)
					gkS := gkX
				}
			else if (gkS >= 0)
				{
				gkRw := gkX - gkS
				if (gkRw >= 2 and gkRw <= gkFW)
					{
					gkCx := gkS + (gkRw // 2)
					gkV := 0
					for gkI, gkY in gkFRows
						{
						if (MiguFishAt(gkCx, gkY, gkList, gkTol, &gkMask))
							gkV++
						}
					if (gkV >= 4)
						{
						gkCandX.Push(gkCx)
						gkCandV.Push(gkV)
						}
					}
				gkS := -1
				}
			gkX++
			}
		if (gkCandX.MaxIndex())
			break
		}
	if (!gkCandX.MaxIndex())
		return false
	gkBestV := 0
	for gkI, gkV in gkCandV
		{
		if (gkV > gkBestV)
			gkBestV := gkV
		}
	gkBestX := -1
	gkNear := 999999
	for gkI, gkCx in gkCandX
		{
		if (gkCandV[gkI] < gkBestV)
			continue
		if (MiguLastX >= 0)
			{
			gkD := Abs((FishBarLeft + gkCx) - MiguLastX)
			if (gkD < gkNear and gkD <= CaptureW * 0.25)
				{
				gkNear := gkD
				gkBestX := gkCx
				}
			}
		}
	if (gkBestX < 0)
		{
		for gkI, gkCx in gkCandX
			{
			if (gkCandV[gkI] >= gkBestV and (gkBestX < 0 or gkCx < gkBestX))
				gkBestX := gkCx
			}
		}
	MiguFishX := FishBarLeft + gkBestX
	MiguLastX := MiguFishX
	MiguFound := true
	return true
}

MiguFishAt(fx, fy, fList, fTol, pMask) {
	global pCaptureBits, CaptureW, CaptureH
	if (fy < 0 or fy >= CaptureH)
		return false
	fOff := fy * CaptureW * 4
	fI := fx - 5
	if (fI < 0)
		fI := 0
	fE := fx + 5
	if (fE > CaptureW - 1)
		fE := CaptureW - 1
	while (fI <= fE)
		{
		if (!NumGet(pMask + 0, fI, "UChar") and RfColHit(fList, NumGet(pCaptureBits + 0, fOff + (fI*4), "UInt"), fTol))
			return true
		fI++
		}
	return false
}

CastboundScan() {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft
	global CastBarL, CastBarW, CastFishX, CastScanned, CastFound
	global CastPrevL, CastPrevW, CastPrevF, CastSameN, CastSameT, CastStatic, QpcFreq
	global CastboundBarColors, CastboundFishColors, CastboundTrackColors
	if ((CastboundBarColors != "" or CastboundFishColors != "" or CastboundTrackColors != "")
		and CastboundXActive())
		return CastboundScanX()
	if (CastScanned)
		return CastFound
	CastScanned := true
	CastFound := false
	CastBarL := -1
	CastBarW := 0
	CastFishX := -1
	if (CaptureW < 80 or CaptureH < 6)
		return false

	row := CaptureH // 2
	rowOffset := row * CaptureW * 4

	; --- is the minigame even on screen? ----------------------------------------------------
	nTrk := 0
	trkFirst := -1
	trkLast := -1
	x := 0
	while (x < CaptureW)
		{
		px := NumGet(pCaptureBits + 0, rowOffset + (x*4), "UInt")
		tb := px & 0xFF
		tg := (px >> 8) & 0xFF
		tr := (px >> 16) & 0xFF
		tsum := tb + tg + tr
		if ((tb - tg) > 20 and (tr - tg) > 5 and tsum >= 180 and tsum <= 340)
			{
			nTrk++
			if (trkFirst < 0)
				trkFirst := x
			trkLast := x
			}
		x++
		}
	if (nTrk < CaptureW * 0.10)
		return false
	if ((trkLast - trkFirst + 1) < CaptureW * 0.45)
		{
		return false
		}

	cbY1 := CaptureH // 3
	cbY2 := CaptureH // 2
	cbY3 := (CaptureH * 2) // 3
	cbGapMax := Round(CaptureW * 0.035)
	if (cbGapMax < 30)
		cbGapMax := 30
	bestL := -1
	bestLen := 0
	runS := -1
	runE := -1
	gap := 0
	cbX := 0
	while (cbX < CaptureW)
		{
		cbHits := 0
		for cbK, cbYY in [cbY1, cbY2, cbY3]
			{
			px := NumGet(pCaptureBits + 0, (cbYY*CaptureW*4) + (cbX*4), "UInt")
			cbB := px & 0xFF
			cbG := (px >> 8) & 0xFF
			cbR := (px >> 16) & 0xFF
			cbSum := cbB + cbG + cbR
			cbIsTrk := ((cbB - cbG) > 20 and (cbR - cbG) > 5 and cbSum >= 180 and cbSum <= 340)
			cbIsSw := (cbG < 90 and cbB > 130 and (cbB - cbG) > 80 and cbR < 160)
			if (!cbIsTrk and !cbIsSw and cbSum >= 110)
				cbHits++
			}
		if (cbHits >= 2)
			{
			if (runS < 0)
				runS := cbX
			runE := cbX
			gap := 0
			}
		else if (runS >= 0)
			{
			gap++
			if (gap > cbGapMax)
				{
				if (runE - runS + 1 > bestLen)
					{
					bestLen := runE - runS + 1
					bestL := runS
					}
				runS := -1
				gap := 0
				}
			}
		cbX++
		}
	if (runS >= 0 and (runE - runS + 1) > bestLen)
		{
		bestLen := runE - runS + 1
		bestL := runS
		}
	if (bestL >= 0 and bestLen >= 24 and bestLen <= CaptureW * 0.85)
		{
		CastBarL := FishBarLeft + bestL
		CastBarW := bestLen
		}

	; --- fallback: the gap the bar leaves in the purple track --------------------------------
	if (CastBarW <= 0)
		{
		tGap := Round(CaptureW * 0.02)
		if (tGap < 10)
			tGap := 10
		nTrk := 0
		tBest := -1
		tLen := 0
		tRun := -1
		tEnd := -1
		tG := 0
		x := 0
		while (x < CaptureW)
			{
			px := NumGet(pCaptureBits + 0, rowOffset + (x*4), "UInt")
			bb := px & 0xFF
			gg := (px >> 8) & 0xFF
			rr := (px >> 16) & 0xFF
			sum := bb + gg + rr
			isTrk := ((bb - gg) > 20 and (rr - gg) > 5 and sum >= 180 and sum <= 340)
			if (isTrk)
				{
				nTrk++
				if (tRun >= 0)
					{
					tG++
					if (tG > tGap)
						{
						if (tEnd - tRun + 1 > tLen)
							{
							tLen := tEnd - tRun + 1
							tBest := tRun
							}
						tRun := -1
						tG := 0
						}
					}
				}
			else
				{
				if (tRun < 0)
					tRun := x
				tEnd := x
				tG := 0
				}
			x++
			}
		if (tRun >= 0 and (tEnd - tRun + 1) > tLen)
			{
			tLen := tEnd - tRun + 1
			tBest := tRun
			}
		if (nTrk >= CaptureW * 0.25 and tBest >= 0 and tLen >= CaptureW * 0.05 and tLen <= CaptureW * 0.9)
			{
			CastBarL := FishBarLeft + tBest
			CastBarW := tLen
			}
		}

	; --- the sword marker: deep violet, almost no green --------------------------------------
	y1 := CaptureH // 6
	y2 := CaptureH // 2
	y3 := (CaptureH * 5) // 6
	sBest := -1
	sLen := 0
	sRun := -1
	sPrev := -1
	sGap := 0
	x := 0
	while (x < CaptureW)
		{
		hits := 0
		for i, yy in [y1, y2, y3]
			{
			px := NumGet(pCaptureBits + 0, (yy*CaptureW*4) + (x*4), "UInt")
			bb := px & 0xFF
			gg := (px >> 8) & 0xFF
			rr := (px >> 16) & 0xFF
			if (gg < 90 and bb > 130 and (bb - gg) > 80 and rr < 160)
				hits++
			}
		if (hits >= 2)
			{
			if (sRun < 0)
				sRun := x
			sPrev := x
			sGap := 0
			}
		else if (sRun >= 0)
			{
			sGap++
			if (sGap > 6)
				{
				if ((sPrev - sRun + 1) > sLen)
					{
					sLen := sPrev - sRun + 1
					sBest := (sRun + sPrev) // 2
					}
				sRun := -1
				sGap := 0
				}
			}
		x++
		}
	if (sRun >= 0 and (sPrev - sRun + 1) > sLen)
		{
		sLen := sPrev - sRun + 1
		sBest := (sRun + sPrev) // 2
		}
	if (sBest >= 0 and sLen >= 6)
		CastFishX := FishBarLeft + sBest

	DllCall("QueryPerformanceCounter", "Int64*", csNow)
	if (CastBarW > 0 and CastBarL = CastPrevL and CastBarW = CastPrevW and CastFishX = CastPrevF)
		{
		CastSameN := CastSameN + 1
		if (!CastSameT)
			CastSameT := csNow
		}
	else
		{
		CastSameN := 0
		CastSameT := 0
		}
	CastPrevL := CastBarL
	CastPrevW := CastBarW
	CastPrevF := CastFishX
	CastStatic := (CastSameT and ((csNow - CastSameT) / QpcFreq) >= 0.25)

	CastFound := (CastBarW > 0 and CastFishX >= 0)
	return CastFound
}

CastboundScanX() {
	global pCaptureBits, CaptureW, CaptureH, FishBarLeft
	global CastBarL, CastBarW, CastFishX, CastScanned, CastFound
	global CastPrevL, CastPrevW, CastPrevF, CastSameN, CastSameT, CastStatic, QpcFreq
	global CastboundBarColors, CastboundBarTol, CastboundFishColors, CastboundFishTol, CastboundTrackColors, CastboundTrackTol
	global CbxKey, CbxR, CbxG, CbxB
	cxKey := CastboundBarColors . "|" . CastboundBarTol . "|" . CastboundFishColors . "|" . CastboundFishTol . "|" . CastboundTrackColors . "|" . CastboundTrackTol
	if (cxKey != CbxKey)
		{
		CbxKey := cxKey
		RodLut(CbxR, CbxG, CbxB, CastboundBarColors, CastboundBarTol, CastboundSwordX(), CastboundFishTol, CastboundTrackColors, CastboundTrackTol)
		}
	if (CastScanned)
		return CastFound
	CastScanned := true
	CastFound := false
	CastBarL := -1
	CastBarW := 0
	CastFishX := -1
	if (CaptureW < 80 or CaptureH < 6)
		return false

	row := CaptureH // 2
	rowOffset := row * CaptureW * 4

	; --- is the minigame even on screen? ----------------------------------------------------
	nTrk := 0
	trkFirst := -1
	trkLast := -1
	x := 0
	while (x < CaptureW)
		{
		px := NumGet(pCaptureBits + 0, rowOffset + (x*4), "UInt")
		tb := px & 0xFF
		tg := (px >> 8) & 0xFF
		tr := (px >> 16) & 0xFF
		tsum := tb + tg + tr
		cxH := CbxR[tr] & CbxG[tg] & CbxB[tb]
		if (((tb - tg) > 20 and (tr - tg) > 5 and tsum >= 180 and tsum <= 340) or (cxH & 0x7FC0000))
			{
			nTrk++
			if (trkFirst < 0)
				trkFirst := x
			trkLast := x
			}
		x++
		}
	if (nTrk < CaptureW * 0.10)
		return false
	if ((trkLast - trkFirst + 1) < CaptureW * 0.45)
		return false

	cbY1 := CaptureH // 3
	cbY2 := CaptureH // 2
	cbY3 := (CaptureH * 2) // 3
	cbGapMax := Round(CaptureW * 0.035)
	if (cbGapMax < 30)
		cbGapMax := 30
	bestL := -1
	bestLen := 0
	runS := -1
	runE := -1
	gap := 0
	cbX := 0
	while (cbX < CaptureW)
		{
		cbHits := 0
		for cbK, cbYY in [cbY1, cbY2, cbY3]
			{
			px := NumGet(pCaptureBits + 0, (cbYY*CaptureW*4) + (cbX*4), "UInt")
			cbB := px & 0xFF
			cbG := (px >> 8) & 0xFF
			cbR := (px >> 16) & 0xFF
			cbSum := cbB + cbG + cbR
			cxH := CbxR[cbR] & CbxG[cbG] & CbxB[cbB]
			cbIsTrk := (((cbB - cbG) > 20 and (cbR - cbG) > 5 and cbSum >= 180 and cbSum <= 340) or (cxH & 0x7FC0000))
			cbIsSw := ((cbG < 90 and cbB > 130 and (cbB - cbG) > 80 and cbR < 160) or (cxH & 0x3FE00))
			if (!cbIsTrk and !cbIsSw and (cbSum >= 110 or (cxH & 0x1FF)))
				cbHits++
			}
		if (cbHits >= 2)
			{
			if (runS < 0)
				runS := cbX
			runE := cbX
			gap := 0
			}
		else if (runS >= 0)
			{
			gap++
			if (gap > cbGapMax)
				{
				if (runE - runS + 1 > bestLen)
					{
					bestLen := runE - runS + 1
					bestL := runS
					}
				runS := -1
				gap := 0
				}
			}
		cbX++
		}
	if (runS >= 0 and (runE - runS + 1) > bestLen)
		{
		bestLen := runE - runS + 1
		bestL := runS
		}
	if (bestL >= 0 and bestLen >= 24 and bestLen <= CaptureW * 0.85)
		{
		CastBarL := FishBarLeft + bestL
		CastBarW := bestLen
		}

	; --- fallback: the gap the bar leaves in the purple track --------------------------------
	if (CastBarW <= 0)
		{
		tGap := Round(CaptureW * 0.02)
		if (tGap < 10)
			tGap := 10
		nTrk := 0
		tBest := -1
		tLen := 0
		tRun := -1
		tEnd := -1
		tG := 0
		x := 0
		while (x < CaptureW)
			{
			px := NumGet(pCaptureBits + 0, rowOffset + (x*4), "UInt")
			bb := px & 0xFF
			gg := (px >> 8) & 0xFF
			rr := (px >> 16) & 0xFF
			sum := bb + gg + rr
			cxH := CbxR[rr] & CbxG[gg] & CbxB[bb]
			isTrk := (((bb - gg) > 20 and (rr - gg) > 5 and sum >= 180 and sum <= 340) or (cxH & 0x7FC0000))
			if (isTrk)
				{
				nTrk++
				if (tRun >= 0)
					{
					tG++
					if (tG > tGap)
						{
						if (tEnd - tRun + 1 > tLen)
							{
							tLen := tEnd - tRun + 1
							tBest := tRun
							}
						tRun := -1
						tG := 0
						}
					}
				}
			else
				{
				if (tRun < 0)
					tRun := x
				tEnd := x
				tG := 0
				}
			x++
			}
		if (tRun >= 0 and (tEnd - tRun + 1) > tLen)
			{
			tLen := tEnd - tRun + 1
			tBest := tRun
			}
		if (nTrk >= CaptureW * 0.25 and tBest >= 0 and tLen >= CaptureW * 0.05 and tLen <= CaptureW * 0.9)
			{
			CastBarL := FishBarLeft + tBest
			CastBarW := tLen
			}
		}

	; --- the sword marker: deep violet, almost no green --------------------------------------
	y1 := CaptureH // 6
	y2 := CaptureH // 2
	y3 := (CaptureH * 5) // 6
	sBest := -1
	sLen := 0
	sRun := -1
	sPrev := -1
	sGap := 0
	x := 0
	while (x < CaptureW)
		{
		hits := 0
		for i, yy in [y1, y2, y3]
			{
			px := NumGet(pCaptureBits + 0, (yy*CaptureW*4) + (x*4), "UInt")
			bb := px & 0xFF
			gg := (px >> 8) & 0xFF
			rr := (px >> 16) & 0xFF
			cxH := CbxR[rr] & CbxG[gg] & CbxB[bb]
			if ((cxH & 0x3FE00) or (gg < 90 and bb > 130 and (bb - gg) > 80 and rr < 160))
				hits++
			}
		if (hits >= 2)
			{
			if (sRun < 0)
				sRun := x
			sPrev := x
			sGap := 0
			}
		else if (sRun >= 0)
			{
			sGap++
			if (sGap > 6)
				{
				if ((sPrev - sRun + 1) > sLen)
					{
					sLen := sPrev - sRun + 1
					sBest := (sRun + sPrev) // 2
					}
				sRun := -1
				sGap := 0
				}
			}
		x++
		}
	if (sRun >= 0 and (sPrev - sRun + 1) > sLen)
		{
		sLen := sPrev - sRun + 1
		sBest := (sRun + sPrev) // 2
		}
	if (sBest >= 0 and sLen >= 6)
		CastFishX := FishBarLeft + sBest

	DllCall("QueryPerformanceCounter", "Int64*", csNow)
	if (CastBarW > 0 and CastBarL = CastPrevL and CastBarW = CastPrevW and CastFishX = CastPrevF)
		{
		CastSameN := CastSameN + 1
		if (!CastSameT)
			CastSameT := csNow
		}
	else
		{
		CastSameN := 0
		CastSameT := 0
		}
	CastPrevL := CastBarL
	CastPrevW := CastBarW
	CastPrevF := CastFishX
	CastStatic := (CastSameT and ((csNow - CastSameT) / QpcFreq) >= 0.25)

	CastFound := (CastBarW > 0 and CastFishX >= 0)
	return CastFound
}

CastboundXActive() {
	global CastboundBarColors, CastboundBarTol, CastboundFishColors, CastboundFishTol, CastboundTrackColors, CastboundTrackTol
	static key := "", act := false
	k := CastboundBarColors . "|" . CastboundBarTol . "|" . CastboundFishColors . "|" . CastboundFishTol . "|" . CastboundTrackColors . "|" . CastboundTrackTol
	if (k == key)
		return act
	key := k
	act := false
	for li, lst in [[RfColList(CastboundBarColors), RodTol(CastboundBarTol), 1], [RfColList(CastboundSwordX()), RodTol(CastboundFishTol), 2], [RfColList(CastboundTrackColors), RodTol(CastboundTrackTol), 3]]
		{
		o := lst[1]
		t := lst[2]
		i := 1
		while (i <= o.n and i <= 9)
			{
			r0 := (o.r[i] - t < 0) ? 0 : o.r[i] - t
			g0 := (o.g[i] - t < 0) ? 0 : o.g[i] - t
			b0 := (o.b[i] - t < 0) ? 0 : o.b[i] - t
			r1 := (o.r[i] + t > 255) ? 255 : o.r[i] + t
			g1 := (o.g[i] + t > 255) ? 255 : o.g[i] + t
			b1 := (o.b[i] + t > 255) ? 255 : o.b[i] + t
			if (lst[3] = 1)
				red := (r0 + g0 + b0 >= 110)
			else if (lst[3] = 2)
				red := (g1 < 90 and b0 > 130 and b0 - g1 > 80 and r1 < 160)
			else
				red := (b0 - g1 > 20 and r0 - g1 > 5 and r0 + g0 + b0 >= 180 and r1 + g1 + b1 <= 340)
			if (!red)
				{
				act := true
				return act
				}
			i++
			}
		}
	return act
}

CastboundSwordX() {
	global CastboundFishColors
	static inp := "", outp := ""
	if (CastboundFishColors == inp)
		return outp
	inp := CastboundFishColors
	outp := ""
	Loop, Parse, inp, `,;| , %A_Space%%A_Tab%
		{
		v := ColNorm(A_LoopField)
		if (v < 0 or v = 0x5522A3)
			continue
		outp .= (outp = "" ? "" : ", ") . Format("0x{:06X}", v)
		}
	return outp
}

RodLut(ByRef lr, ByRef lg, ByRef lb, bar, barTol, fish, fishTol, trk, trkTol) {
	lr := []
	lg := []
	lb := []
	v := 0
	while (v < 256)
		{
		lr[v] := 0
		lg[v] := 0
		lb[v] := 0
		v++
		}
	oB := RfColList(bar)
	oF := RfColList(fish)
	oT := RfColList(trk)
	for li, lst in [[oB, RodTol(barTol), 0, oF, oT], [oF, RodTol(fishTol), 9, oT, oT], [oT, RodTol(trkTol), 18, oF, oF]]
		{
		o := lst[1]
		sh := lst[3]
		k := 1
		while (k <= o.n and k <= 9)
			{
			t := RodCap(o, k, lst[5], RodCap(o, k, lst[4], lst[2]))
			bit := 1 << (sh + k - 1)
			v := 0
			while (v < 256)
				{
				if (Abs(v - o.r[k]) <= t)
					lr[v] := lr[v] | bit
				if (Abs(v - o.g[k]) <= t)
					lg[v] := lg[v] | bit
				if (Abs(v - o.b[k]) <= t)
					lb[v] := lb[v] | bit
				v++
				}
			k++
			}
		}
}


IsDarkNotch(x, y, off) {
	global pCaptureBits, CaptureW, CaptureH
	if (y < 0 or y >= CaptureH or x < off or x >= CaptureW - off)
		return false
	rowOffset := y * CaptureW * 4
	pc := NumGet(pCaptureBits + 0, rowOffset + (x*4), "UInt")
	pl := NumGet(pCaptureBits + 0, rowOffset + ((x-off)*4), "UInt")
	pr := NumGet(pCaptureBits + 0, rowOffset + ((x+off)*4), "UInt")
	c := ((pc & 0xFF) + ((pc >> 8) & 0xFF) + ((pc >> 16) & 0xFF)) // 3
	lN := ((pl & 0xFF) + ((pl >> 8) & 0xFF) + ((pl >> 16) & 0xFF)) // 3
	rN := ((pr & 0xFF) + ((pr >> 8) & 0xFF) + ((pr >> 16) & 0xFF)) // 3
	navg := (lN + rN) // 2
	margin := Round(navg * 0.25)
	if (margin < 8)
		margin := 8
	return (lN - c >= margin and rN - c >= margin)
}


DetTestToggle:
if (DetTesting)
	{
	DetTesting := false
	SetTimer, DetTestTick, Off
	RfBtnText("DetTestBtn", "▶  Test detection")
	GuiControl, 1:, DetTestOut, Test stopped.
	Loop, 20
		RfTipClear(A_Index)
	return
	}
if (MacroRunning)
	{
	GuiControl, 1:, DetTestOut, Stop the macro first - the test needs the capture to itself.
	return
	}
DetTesting := true
Loop, 20
	RfTipClear(A_Index)
RfBtnText("DetTestBtn", "■  Stop test")
SetTimer, DetTestTick, 250
return

DetTestTick:
if (!DetTesting or TargetSection != "Minigame" or MacroRunning)
	{
	DetTesting := false
	SetTimer, DetTestTick, Off
	RfBtnText("DetTestBtn", "▶  Test detection")
	Loop, 20
		RfTipClear(A_Index)
	return
	}
RfFindRoblox()
if (!RobloxHwnd)
	{
	GuiControl, 1:, DetTestOut, Roblox is not open.
	return
	}
RfMeasure()
RfCapFrame()
if (SpecialRod = "Stellarwave Melody")
	{
	if (!SwReady)
		SwSetup()
	SwApplyColours()
	}
DetC := RfReelScore()
DetTxt := "Bar " . (MgSawBar ? "✔" : "✘")
DetTxt .= "    Fish line " . (MgSawFish ? "✔" : "✘")
DetTxt .= "    Arrow " . ((MgSawArrow or RfArrowFind() >= 0) ? "✔" : "✘")
DetTxt .= "    →  " . DetC . "%"
if (DetC >= 90)
	DetTxt .= "  solid"
else if (DetC >= 55)
	DetTxt .= "  usable"
else if (DetC > 0)
	DetTxt .= "  weak - re-pick colors"
else
	DetTxt .= "  nothing seen"
GuiControl, 1:, DetTestOut, %DetTxt%
return

;====================================================================================================;

AstraMigrateColours:
if (SpecialRod = "Astraenus Serenade")
	{
	SpecialRod := "None"
	ControlMode := "Precision"
	if ((FishColor = "0x434B5B" and BarLeftColor = "0xF1F1F1" and BarRightColor = "0xF1F1F1")
		or (FishColor = "0x8C7A7E" and BarLeftColor = "0xCCC19A" and BarRightColor = "0x845AC0"))
		{
		FishColor := "0x98816E"
		FishBarColorTolerance := 20
		BarLeftColor := "0xD8C55B"
		BarRightColor := "0x9E59FF"
		BarColorTolerance := 10
		}
	}
if (SpecialRod = "Chasm Stalker")
	SpecialRod := "None"
return

ApplyVerdantOathPreset:
FishColor := "0x434B5B"
BarLeftColor := "0x67512C"
BarRightColor := "0x65502D"
ArrowColor := "0x848587"
BarColorTolerance := 3
FishBarColorTolerance := 12
ArrowColorTolerance := 0
GuiControl, 1:, FishColor, %FishColor%
GuiControl, 1:, BarLeftColor, %BarLeftColor%
GuiControl, 1:, BarRightColor, %BarRightColor%
GuiControl, 1:, ArrowColor, %ArrowColor%
GuiControl, 1:, BarColorTolerance, %BarColorTolerance%
GuiControl, 1:, FishBarColorTolerance, %FishBarColorTolerance%
GuiControl, 1:, ArrowColorTolerance, %ArrowColorTolerance%
gosub, RefreshSwatches
return

ApplyNoRodPreset:
NoRodSets := [ ["0x0C4125","0x33A95F"]                                                  ; Noiseform
	, ["0x0D0B0B","0x5D52A8"]                                                           ; Halibut Harpoon
	, ["0x434B5B","0x67512C"]                                                           ; Verdant Oath
	, ["0xFFFFFF","0x474747"], ["0xFFFFFF","0xB5B5B5"]                                  ; Remembrance
	, ["0xF9D9D4,0xFAD6CE,0xF9D4C7,0xF9D2C4,0xF8D0B7","0xE9B681,0xE0A66F,0xD1935B"] ]   ; MiguRod
NoRodHit := false
for i, s in NoRodSets
	{
	if (FishColor = s[1] and BarLeftColor = s[2] and (s.Length() < 3 or BarColorTolerance = s[3]))
		NoRodHit := true
	}
if (!NoRodHit)
	return
for i, f in ProfileFields
	{
	if (f[2] != "FishColor" and f[2] != "BarLeftColor" and f[2] != "BarRightColor" and f[2] != "ArrowColor"
		and f[2] != "BarColorTolerance" and f[2] != "FishBarColorTolerance" and f[2] != "ArrowColorTolerance")
		continue
	NoRodKey := f[2]
	%NoRodKey% := f[3]
	if (!NoRodQuiet)
		GuiControl, 1:, %NoRodKey%, % f[3]
	}
if (!NoRodQuiet)
	gosub, RefreshSwatches
return

ApplyHalibutPreset:
FishColor := "0x0D0B0B"
BarLeftColor := "0x5D52A8"
BarRightColor := "0x5D52A8"
ArrowColor := "0x413A76"
BarColorTolerance := 3
FishBarColorTolerance := 3
ArrowColorTolerance := 3
GuiControl, 1:, FishColor, %FishColor%
GuiControl, 1:, BarLeftColor, %BarLeftColor%
GuiControl, 1:, BarRightColor, %BarRightColor%
GuiControl, 1:, ArrowColor, %ArrowColor%
GuiControl, 1:, BarColorTolerance, %BarColorTolerance%
GuiControl, 1:, FishBarColorTolerance, %FishBarColorTolerance%
GuiControl, 1:, ArrowColorTolerance, %ArrowColorTolerance%
gosub, RefreshSwatches
return

ApplyRemembrancePreset:
if (RemembranceMode = "Departed")
	{
	BarLeftColor := "0x474747"
	BarRightColor := "0x474747"
	BarColorTolerance := 8
	}
else
	{
	BarLeftColor := "0xB5B5B5"
	BarRightColor := "0xB5B5B5"
	BarColorTolerance := 10
	}
FishColor := "0xFFFFFF"
FishBarColorTolerance := 10
GuiControl, 1:, BarLeftColor, %BarLeftColor%
GuiControl, 1:, BarRightColor, %BarRightColor%
GuiControl, 1:, BarColorTolerance, %BarColorTolerance%
GuiControl, 1:, FishColor, %FishColor%
GuiControl, 1:, FishBarColorTolerance, %FishBarColorTolerance%
gosub, RefreshSwatches
return

ApplyMiguRodPreset:
BarLeftColor := "0xE9B681,0xE0A66F,0xD1935B"
BarRightColor := "0xE9B681,0xE0A66F,0xD1935B"
BarColorTolerance := 14
FishColor := "0xF9D9D4,0xFAD6CE,0xF9D4C7,0xF9D2C4,0xF8D0B7"
FishBarColorTolerance := 10
GuiControl, 1:, BarLeftColor, %BarLeftColor%
GuiControl, 1:, BarRightColor, %BarRightColor%
GuiControl, 1:, BarColorTolerance, %BarColorTolerance%
GuiControl, 1:, FishColor, %FishColor%
GuiControl, 1:, FishBarColorTolerance, %FishBarColorTolerance%
gosub, RefreshSwatches
return

RemembranceModeChanged:
GuiControlGet, RemembranceMode, 1:, RemembranceMode
gosub, ApplyRemembrancePreset
gosub, QueueAutoSave
return

ApplyNoiseformPreset:
FishColor := "0x0C4125"
BarLeftColor := "0x33A95F"
BarRightColor := "0x2C894D"
ArrowColor := "0x000000"
BarColorTolerance := 3
FishBarColorTolerance := 5
ArrowColorTolerance := 0
Kp := 0.3
Kd := 0.3
VelocitySmoothing := 0.5
StoppingDistanceMultiplier := 5.0
GuiControl, 1:, FishColor, %FishColor%
GuiControl, 1:, BarLeftColor, %BarLeftColor%
GuiControl, 1:, BarRightColor, %BarRightColor%
GuiControl, 1:, ArrowColor, %ArrowColor%
GuiControl, 1:, BarColorTolerance, %BarColorTolerance%
GuiControl, 1:, FishBarColorTolerance, %FishBarColorTolerance%
GuiControl, 1:, ArrowColorTolerance, %ArrowColorTolerance%
GuiControl, 1:, Kp, %Kp%
GuiControl, 1:, Kd, %Kd%
GuiControl, 1:, VelocitySmoothing, %VelocitySmoothing%
GuiControl, 1:, StoppingDistanceMultiplier, %StoppingDistanceMultiplier%
gosub, RefreshSwatches
return

SpecialRodChanged:
GuiControlGet, SpecialRod, 1:, SpecialRod
KittyReset()
if (SpecialRod = "Requiem" or SpecialRod = "Darkheart" or SpecialRod = "Lullaby"
	or SpecialRod = "Verdant Oath")
	ControlMode := "Lines"
if (SpecialRod = "Remembrance")
	ControlMode := "Lines"
if (SpecialRod = "MiguRod" or SpecialRod = "Halibut Harpoon" or SpecialRod = "Tryhard Rod" or SpecialRod = "Stellarwave Melody")
	ControlMode := "Precision"
gosub, ApplyNoRodPreset
if (SpecialRod = "Halibut Harpoon")
	gosub, ApplyHalibutPreset
if (SpecialRod = "Noiseform")
	gosub, ApplyNoiseformPreset
if (SpecialRod = "Remembrance")
	gosub, ApplyRemembrancePreset
if (SpecialRod = "MiguRod")
	gosub, ApplyMiguRodPreset
if (SpecialRod = "Verdant Oath")
	gosub, ApplyVerdantOathPreset
gosub, RefreshControlModes
gosub, RefreshSwatches
gosub, RfRodChangedUi
gosub, QueueAutoSave
return

;====================================================================================================;

ColNorm(v) {
	t := Trim(v)
	if (t = "")
		return -1
	hadPrefix := false
	if (SubStr(t, 1, 1) = "#")
		{
		t := SubStr(t, 2)
		hadPrefix := true
		}
	else if (SubStr(t, 1, 2) = "0x" or SubStr(t, 1, 2) = "0X")
		{
		t := SubStr(t, 3)
		hadPrefix := true
		}
	if (RegExMatch(t, "^[0-9a-fA-F]{6}$"))
		{
		hv := "0x" . t
		return hv + 0
		}
	if (!hadPrefix and RegExMatch(t, "^[0-9]{1,8}$") and (t + 0) <= 0xFFFFFF)
		return t + 0        
	return -1
}

ColListToArray(str) {
	arr := []
	Loop, Parse, str, `,;| , %A_Space%%A_Tab%
		{
		cn := ColNorm(A_LoopField)
		if (cn >= 0)
			arr.Push(cn)
		}
	return arr
}

ColArrayToList(arr) {
	out := ""
	for i, v in arr
		out .= (out = "" ? "" : ", ") . Format("0x{:06X}", v)
	return out
}

ColListAdd(str, hex) {
	arr := ColListToArray(str)
	cn := ColNorm(hex)
	if (cn < 0)
		return ColArrayToList(arr)
	for i, v in arr
		{
		if (v = cn)
			return ColArrayToList(arr)
		}
	if (arr.MaxIndex() >= 9)
		return ColArrayToList(arr)
	arr.Push(cn)
	return ColArrayToList(arr)
}

ColListRemoveAt(str, idx) {
	arr := ColListToArray(str)
	if (idx < 1 or idx > arr.MaxIndex())
		return ColArrayToList(arr)
	arr.RemoveAt(idx)
	return ColArrayToList(arr)
}

CMStore(key, val) {
	global
	%key% := val
	CMSec := CMTargetSection[key]
	IniWrite, %val%, %ActiveProfileFile%, %CMSec%, %key%
	GuiControl, 1:, %key%, %val%
	gosub, RefreshSwatches
}

;----------------------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------------------

CMApplyTargets:
if (SpecialRod = "Tryhard Rod")
	CMTargetKeys := ["TryhardFishColors","TryhardBarColors","TryhardTrackColors","ArrowColor","NoteColor","PerfectGreenColor","PerfectWhiteColor"]
else if (SpecialRod = "Castbound")
	CMTargetKeys := ["CastboundFishColors","CastboundBarColors","CastboundTrackColors","ArrowColor","NoteColor","PerfectGreenColor","PerfectWhiteColor"]
else if (SpecialRod = "Stellarwave Melody")
	CMTargetKeys := ["StellarBarColors","StellarFishColors","StellarHeadColors","PerfectGreenColor","PerfectWhiteColor"]
else
	CMTargetKeys := ["FishColor","BarLeftColor","BarRightColor","ArrowColor","NoteColor","PerfectGreenColor","PerfectWhiteColor"]
CMSelOk := false
for CMSelI, CMSelK in CMTargetKeys
	{
	if (CMSelK = CMSel)
		CMSelOk := true
	}
if (!CMSelOk)
	CMSel := CMTargetKeys[1]
return

FreezePickHotkey:
if (FreezeActive)
	return
gosub, CMApplyTargets
FreezeTarget := CMSel
FreezeMode := "add"
gosub, FreezePick
return

FreezePick:
if (FreezeActive)
	return
FreezeActive := true
FreezePicked := ""

SysGet, FrzVX, 76
SysGet, FrzVY, 77
SysGet, FrzVW, 78
SysGet, FrzVH, 79
if (FrzVW < 1)
	{
	FrzVX := 0
	FrzVY := 0
	FrzVW := A_ScreenWidth
	FrzVH := A_ScreenHeight
	}

Gui, 1:Hide

if (hFullBM)
	{
	DllCall("DeleteObject", "Ptr", hFullBM)
	hFullBM := 0
	}
if (hFullMemDC)
	{
	DllCall("DeleteDC", "Ptr", hFullMemDC)
	hFullMemDC := 0
	}
hFrzScreenDC := DllCall("GetDC", "Ptr", 0, "Ptr")
hFullMemDC := DllCall("CreateCompatibleDC", "Ptr", hFrzScreenDC, "Ptr")
VarSetCapacity(FrzBMI, 40, 0)
NumPut(40, FrzBMI, 0, "UInt")
NumPut(FrzVW, FrzBMI, 4, "Int")
NumPut(-FrzVH, FrzBMI, 8, "Int")
NumPut(1, FrzBMI, 12, "UShort")
NumPut(32, FrzBMI, 14, "UShort")
NumPut(0, FrzBMI, 16, "UInt")
hFullBM := DllCall("CreateDIBSection", "Ptr", hFrzScreenDC, "Ptr", &FrzBMI, "UInt", 0, "Ptr*", pFullBits, "Ptr", 0, "UInt", 0, "Ptr")
DllCall("SelectObject", "Ptr", hFullMemDC, "Ptr", hFullBM)
DllCall("BitBlt", "Ptr", hFullMemDC, "Int", 0, "Int", 0, "Int", FrzVW, "Int", FrzVH
	, "Ptr", hFrzScreenDC, "Int", FrzVX, "Int", FrzVY, "UInt", 0x00CC0020)
DllCall("ReleaseDC", "Ptr", 0, "Ptr", hFrzScreenDC)
Gui, 1:Show, NoActivate

FrzWhat := CMTargetLabel.HasKey(FreezeTarget) ? CMTargetLabel[FreezeTarget] : FreezeTarget
gosub, FrzBuildMenu
if (!RobloxHwnd)
	RfFindRoblox()
FrzMonL := 0
FrzMonT := 0
FrzMonW := A_ScreenWidth
FrzMonH := A_ScreenHeight
if (RobloxHwnd)
	{
	RfClientArea(RobloxHwnd, FrzRx, FrzRy, FrzRw, FrzRh)
	FrzRcx := FrzRx + (FrzRw // 2)
	FrzRcy := FrzRy + (FrzRh // 2)
	SysGet, FrzMonN, MonitorCount
	Loop, %FrzMonN%
		{
		SysGet, FrzM, Monitor, %A_Index%
		if (FrzRcx >= FrzMLeft and FrzRcx < FrzMRight and FrzRcy >= FrzMTop and FrzRcy < FrzMBottom)
			{
			FrzMonL := FrzMLeft
			FrzMonT := FrzMTop
			FrzMonW := FrzMRight - FrzMLeft
			FrzMonH := FrzMBottom - FrzMTop
			break
			}
		}
	}
FrzBW := FrzMonW - 220
if (FrzBW > 1060)
	FrzBW := 1060
if (FrzBW < 420)
	FrzBW := 420
FrzBX := FrzMonL + ((FrzMonW - FrzBW) // 2) - FrzVX
FrzBY := FrzMonT + 54 - FrzVY
FrzTX := FrzBX + 28
FrzTW := FrzBW - 56
Gui, Frz:New, +AlwaysOnTop -Caption +ToolWindow +HwndhFrzGui
Gui, Frz:Color, 000000
Gui, Frz:Margin, 0, 0
Gui, Frz:Add, Picture, x0 y0 w%FrzVW% h%FrzVH%, HBITMAP:%hFullBM%
FrzR1 := FrzBY + 22
FrzR2 := FrzBY + 62
FrzR3 := FrzBY + 92
FrzR4 := FrzBY + 122
Gui, Frz:Add, Progress, x%FrzBX% y%FrzBY% w%FrzBW% h158 Background0B0B0C, 0
FrzExitW := 268
FrzHintW := FrzTW - FrzExitW
FrzExitX := FrzTX + FrzHintW
Gui, Frz:Font, s9 Bold cE5484D, Segoe UI
Gui, Frz:Add, Text, x%FrzTX% y%FrzR1% w%FrzTW% h20 BackgroundTrans, ❄   SCREEN FROZEN
Gui, Frz:Font, s20 Bold cFFFFFF, Segoe UI
Gui, Frz:Add, Text, x%FrzTX% y%FrzR2% w%FrzTW% h34 BackgroundTrans vFrzTitle, %FrzWhat%
Gui, Frz:Font, s10 Bold cBDBDC2, Segoe UI
Gui, Frz:Add, Text, x%FrzTX% y%FrzR3% w%FrzTW% h22 BackgroundTrans vFrzMenuTx, %FrzMenu%
Gui, Frz:Font, s10 Norm cEDEDED, Segoe UI
Gui, Frz:Add, Text, x%FrzTX% y%FrzR4% w%FrzHintW% h24 BackgroundTrans vFrzCount, Click the color in game  ·  number keys switch
Gui, Frz:Font, s10 Bold cE5484D, Segoe UI
Gui, Frz:Add, Text, x%FrzExitX% y%FrzR4% w%FrzExitW% h24 BackgroundTrans, Right-click or Esc to finish
Gui, Frz:Show, x%FrzVX% y%FrzVY% w%FrzVW% h%FrzVH%, Re:FischFreeze

LoupeSrc := 25
LoupeZoom := 7
LoupeImgW := LoupeSrc * LoupeZoom
LoupeW := LoupeImgW + 12
LoupeH := LoupeImgW + 12 + 28
Gui, Loupe:New, +AlwaysOnTop -Caption +ToolWindow +E0x8000020 +HwndhLoupeGui
Gui, Loupe:Color, 0B0E14
Gui, Loupe:Margin, 0, 0
Gui, Loupe:Show, x0 y0 w%LoupeW% h%LoupeH% NoActivate, Re:FischLoupe
hLoupeRgn := DllCall("CreateRoundRectRgn", "Int", 0, "Int", 0, "Int", LoupeW+1, "Int", LoupeH+1, "Int", 12, "Int", 12, "Ptr")
DllCall("SetWindowRgn", "Ptr", hLoupeGui, "Ptr", hLoupeRgn, "Int", true)

hLoupeDC := DllCall("GetDC", "Ptr", hLoupeGui, "Ptr")
hLoupeMem := DllCall("CreateCompatibleDC", "Ptr", hLoupeDC, "Ptr")
hLoupeBM := DllCall("CreateCompatibleBitmap", "Ptr", hLoupeDC, "Int", LoupeW, "Int", LoupeH, "Ptr")
hLoupeOldBM := DllCall("SelectObject", "Ptr", hLoupeMem, "Ptr", hLoupeBM, "Ptr")
DllCall("ReleaseDC", "Ptr", hLoupeGui, "Ptr", hLoupeDC)
hLoupeFont := DllCall("CreateFont", "Int", -14, "Int", 0, "Int", 0, "Int", 0, "Int", 700
	, "UInt", 0, "UInt", 0, "UInt", 0, "UInt", 1, "UInt", 0, "UInt", 0, "UInt", 0, "UInt", 0, "Str", "Consolas", "Ptr")

CoordMode, Mouse, Screen
FrzCancelled := false
FrzAdded := 0
FrzForceZ := true
Loop
	{
	if (GetKeyState("Escape", "P") or GetKeyState("RButton", "P"))
		{
		FrzCancelled := (FrzAdded = 0)
		while GetKeyState("RButton", "P")
			sleep 5
		break
		}
	FrzSwitch := 0
	Loop, % CMTargetKeys.MaxIndex()
		{
		if (A_Index <= 9 and GetKeyState(A_Index, "P"))
			{
			FrzSwitch := A_Index
			break
			}
		}
	if (FrzSwitch)
		{
		while GetKeyState(FrzSwitch, "P")
			sleep 5
		FreezeTarget := CMTargetKeys[FrzSwitch]
		CMSel := FreezeTarget
		FrzWhat := CMTargetLabel[FreezeTarget]
		FrzAdded := 0
		gosub, FrzBuildMenu
		GuiControl, Frz:, FrzTitle, %FrzWhat%
		GuiControl, Frz:, FrzMenuTx, %FrzMenu%
		GuiControl, Frz:, FrzCount, % FrzWhat . " already has " . RfColCount(%FreezeTarget%) . "  ·  click to add more"
		FrzForceZ := true
		}
	MouseGetPos, FrzMx, FrzMy
	FreezePaintLoupe(FrzMx, FrzMy, FrzForceZ)
	FrzForceZ := false
	if GetKeyState("LButton", "P")
		{
		while GetKeyState("LButton", "P")
			sleep 5
		FrzForceZ := true
		FrzHex := FreezePixelAt(FrzMx, FrzMy)
		if (FrzHex != "" and FreezeTarget != "")
			{
			FrzBefore := RfColCount(%FreezeTarget%)
			if (FreezeMode = "add")
				CMStore(FreezeTarget, ColListAdd(%FreezeTarget%, FrzHex))
			else
				CMStore(FreezeTarget, FrzHex)
			FrzAfter := RfColCount(%FreezeTarget%)
			FreezePicked := FrzHex
			if (FrzAfter > FrzBefore)
				{
				FrzAdded := FrzAdded + 1
				GuiControl, Frz:, FrzCount, % "added " . FrzAdded . "   (" . FrzAfter . " on this color)   last " . FrzHex
				}
			else
				GuiControl, Frz:, FrzCount, % "added " . FrzAdded . "   " . FrzHex . " was already in the list"
			}
		}
	sleep 12
	}
CoordMode, Mouse, Client

Gui, Loupe:Destroy
Gui, Frz:Destroy
Gui, 1:Default
Gui, 1:Show
if (hLoupeMem)
	{
	if (hLoupeOldBM)
		DllCall("SelectObject", "Ptr", hLoupeMem, "Ptr", hLoupeOldBM)
	DllCall("DeleteDC", "Ptr", hLoupeMem)
	hLoupeMem := 0
	hLoupeOldBM := 0
	}
if (hLoupeBM)
	{
	DllCall("DeleteObject", "Ptr", hLoupeBM)
	hLoupeBM := 0
	}
if (hLoupeFont)
	{
	DllCall("DeleteObject", "Ptr", hLoupeFont)
	hLoupeFont := 0
	}
FreezeActive := false
gosub, RfAfterPick
return

FrzBuildMenu:
FrzMenu := ""
for FrzI, FrzK in CMTargetKeys
	FrzMenu .= (FrzMenu = "" ? "" : "     ")
		. ((FrzK = FreezeTarget) ? "▸ " : "") . FrzI . " " . CMShortLabel[FrzK]
return

FreezePixelAt(sx, sy) {
	global pFullBits, FrzVX, FrzVY, FrzVW, FrzVH
	x := sx - FrzVX
	y := sy - FrzVY
	if (x < 0 or y < 0 or x >= FrzVW or y >= FrzVH)
		return ""
	v := NumGet(pFullBits + 0, (y*FrzVW*4) + (x*4), "UInt")
	return Format("0x{:02X}{:02X}{:02X}", (v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF)
}

FreezePaintLoupe(sx, sy, force := false) {
	global hLoupeGui, hLoupeMem, hLoupeFont, hFullMemDC, pFullBits
	global LoupeSrc, LoupeZoom, LoupeImgW, LoupeW, LoupeH
	global FrzVX, FrzVY, FrzVW, FrzVH
	static lastX := -99999, lastY := -99999, lastZ := 0
	if (!hLoupeMem)
		return
	px := sx - FrzVX
	py := sy - FrzVY
	half := LoupeSrc // 2

	DllCall("SetBkMode", "Ptr", hLoupeMem, "Int", 1)
	brBG := DllCall("CreateSolidBrush", "UInt", 0x0C0B0B, "Ptr")
	VarSetCapacity(rc, 16, 0)
	NumPut(0, rc, 0, "Int"), NumPut(0, rc, 4, "Int"), NumPut(LoupeW, rc, 8, "Int"), NumPut(LoupeH, rc, 12, "Int")
	DllCall("FillRect", "Ptr", hLoupeMem, "Ptr", &rc, "Ptr", brBG)
	DllCall("DeleteObject", "Ptr", brBG)

	sx0 := px - half
	sy0 := py - half
	if (sx0 < 0)
		sx0 := 0
	if (sy0 < 0)
		sy0 := 0
	if (sx0 > FrzVW - LoupeSrc)
		sx0 := FrzVW - LoupeSrc
	if (sy0 > FrzVH - LoupeSrc)
		sy0 := FrzVH - LoupeSrc
	DllCall("SetStretchBltMode", "Ptr", hLoupeMem, "Int", 3)
	DllCall("StretchBlt", "Ptr", hLoupeMem, "Int", 6, "Int", 6, "Int", LoupeImgW, "Int", LoupeImgW
		, "Ptr", hFullMemDC, "Int", sx0, "Int", sy0, "Int", LoupeSrc, "Int", LoupeSrc, "UInt", 0x00CC0020)
	cpx := (px - sx0)
	cpy := (py - sy0)
	if (cpx < 0)
		cpx := 0
	if (cpy < 0)
		cpy := 0

	cx := 6 + (cpx * LoupeZoom)
	cy := 6 + (cpy * LoupeZoom)
	penW := DllCall("CreatePen", "Int", 0, "Int", 1, "UInt", 0xFFFFFF, "Ptr")
	penK := DllCall("CreatePen", "Int", 0, "Int", 1, "UInt", 0x000000, "Ptr")
	hollow := DllCall("GetStockObject", "Int", 5, "Ptr")
	oldBr := DllCall("SelectObject", "Ptr", hLoupeMem, "Ptr", hollow, "Ptr")
	oldPen := DllCall("SelectObject", "Ptr", hLoupeMem, "Ptr", penK, "Ptr")
	DllCall("Rectangle", "Ptr", hLoupeMem, "Int", cx-2, "Int", cy-2, "Int", cx+LoupeZoom+2, "Int", cy+LoupeZoom+2)
	DllCall("SelectObject", "Ptr", hLoupeMem, "Ptr", penW)
	DllCall("Rectangle", "Ptr", hLoupeMem, "Int", cx-1, "Int", cy-1, "Int", cx+LoupeZoom+1, "Int", cy+LoupeZoom+1)
	DllCall("SelectObject", "Ptr", hLoupeMem, "Ptr", oldPen)
	DllCall("SelectObject", "Ptr", hLoupeMem, "Ptr", oldBr)
	DllCall("DeleteObject", "Ptr", penW)
	DllCall("DeleteObject", "Ptr", penK)

	hex := FreezePixelAt(sx, sy)
	if (hex = "")
		hex := "0x000000"
	sr := "0x" . SubStr(hex, 3, 2)
	sg := "0x" . SubStr(hex, 5, 2)
	sb := "0x" . SubStr(hex, 7, 2)
	swBGR := (sb << 16) | (sg << 8) | sr
	brSw := DllCall("CreateSolidBrush", "UInt", swBGR, "Ptr")
	NumPut(6, rc, 0, "Int"), NumPut(LoupeImgW + 10, rc, 4, "Int")
	NumPut(34, rc, 8, "Int"), NumPut(LoupeImgW + 32, rc, 12, "Int")
	DllCall("FillRect", "Ptr", hLoupeMem, "Ptr", &rc, "Ptr", brSw)
	DllCall("DeleteObject", "Ptr", brSw)

	oldFont := DllCall("SelectObject", "Ptr", hLoupeMem, "Ptr", hLoupeFont, "Ptr")
	DllCall("SetTextColor", "Ptr", hLoupeMem, "UInt", 0xF7F1EE)
	NumPut(40, rc, 0, "Int"), NumPut(LoupeImgW + 10, rc, 4, "Int")
	NumPut(LoupeW - 6, rc, 8, "Int"), NumPut(LoupeImgW + 32, rc, 12, "Int")
	DllCall("DrawText", "Ptr", hLoupeMem, "Str", hex, "Int", -1, "Ptr", &rc, "UInt", 0x24)
	DllCall("SelectObject", "Ptr", hLoupeMem, "Ptr", oldFont)

	hdc := DllCall("GetDC", "Ptr", hLoupeGui, "Ptr")
	DllCall("BitBlt", "Ptr", hdc, "Int", 0, "Int", 0, "Int", LoupeW, "Int", LoupeH
		, "Ptr", hLoupeMem, "Int", 0, "Int", 0, "UInt", 0x00CC0020)
	DllCall("ReleaseDC", "Ptr", hLoupeGui, "Ptr", hdc)

	lx := sx + 26
	ly := sy + 26
	if (lx + LoupeW > FrzVX + FrzVW)
		lx := sx - LoupeW - 26
	if (ly + LoupeH > FrzVY + FrzVH)
		ly := sy - LoupeH - 26
	if (force or lx != lastX or ly != lastY or A_TickCount - lastZ >= 100)
		{
		lastX := lx
		lastY := ly
		lastZ := A_TickCount
		DllCall("SetWindowPos", "Ptr", hLoupeGui, "Ptr", -1, "Int", lx, "Int", ly, "Int", 0, "Int", 0, "UInt", 0x0211)
		}
}

;====================================================================================================;

ReFishSteer(down, timed := true) {
    global ReFishSpaceDown, MacroRunning, MgInPlay, RobloxHwnd
    global PrecisionDown, PrecisionDownAt, PrecisionUpAt, PrecisionResendAt, QpcFreq
    if (!MacroRunning or !MgInPlay or !WinActive("ahk_id " . RobloxHwnd)) {
        ReFishSpaceRelease()
        return
    }
    DllCall("QueryPerformanceCounter", "Int64*", now)
    if (down) {
        if (!ReFishSpaceDown) {
            if (timed and PrecisionUpAt and (now - PrecisionUpAt) * 1000.0 / QpcFreq < 25)
                return
            SendEvent {Space down}
            ReFishSpaceDown := true
            PrecisionDown := true
            PrecisionDownAt := now
            PrecisionResendAt := now
        } else if (!GetKeyState("Space") or (now - PrecisionResendAt) * 1000.0 / QpcFreq >= 400) {
            SendEvent {Space down}
            PrecisionResendAt := now
        }
    } else if (ReFishSpaceDown) {
        if (timed and PrecisionDownAt and (now - PrecisionDownAt) * 1000.0 / QpcFreq < 35)
            return
        ReFishSpaceRelease()
    }
}

ReFishSpaceRelease() {
    global ReFishSpaceDown, PrecisionDown, PrecisionUpAt
    if (!ReFishSpaceDown)
        return
    SendEvent {Space up}
    ReFishSpaceDown := false
    PrecisionDown := false
    DllCall("QueryPerformanceCounter", "Int64*", PrecisionUpAt)
}

ReFishBarInput(down) {
    if (KittyMode())
        ReFishSteer(down, false)
    else if (down)
        Send {LButton down}
    else
        Send {LButton up}
}

ReFishInputWatchdog:
if (ReFishSpaceDown and (!MacroRunning or !MgInPlay or !KittyMode() or !WinActive("ahk_id " . RobloxHwnd)))
    ReFishSpaceRelease()
return

ReFishExit(reason, code) {
    ReFishFlushLog()
    global KittyMouseDown
    ReFishSpaceRelease()
    if (KittyMouseDown)
        SendEvent {LButton up}
}

; Preallocate the small palette once; no per-frame GDI allocations.
; Kitty Keys detector. Personal-use experimental adaptation, 2026-11-07.
; Uses Re:Fisch/Yato's existing screen capture, zodiac templates and click helpers.
; Kitty-specific pixels are kept separate from Stellarwave's original settings.
;
; Speed/tracking pass (personal build):
;   - Glyph masks and the fish-marker row scan run as small x64 kernels (KittyMcReady),
;     self-tested at startup against the original AHK code; on any mismatch or on 32-bit
;     AutoHotkey the original code path is used unchanged.
;   - All 12 slots are matched in one frame; slots are surveyed while a click is in flight,
;     so the next sign is already known to be steady (KittyHistNote / KittyHistSettled).
;   - The expected +1 star step confirms after two matching frames (KittyExpectLit).
;   - Mouse stages use QPC time and are ticked every frame; the aim follows a glyph that
;     shifts while hovering (KittyAimTrack). Click speed setting: Normal / Fast / Turbo.
KittyMode() {
    global StellarSkin, SpecialRod
    return (StellarSkin = "Kitty Keys" and SpecialRod = "Stellarwave Melody")
}

KittyReset() {
    global KittyRefreshUntil
    KittyRefreshUntil := 0
    global KittyRecheckAt, KittyAckTimeout
    KittyRecheckAt := 0
    KittyAckTimeout := 0.50
    global KittyGlyphCenters, KittyWaitLit, KittyRetries, KittyMouseStage, KittyMouseDown
    if (KittyMouseStage or KittyMouseDown)
        KittyMouseCancel("reset")
    KittyGlyphCenters := {}
    global KittyGlyphHist
    KittyGlyphHist := {}
    KittyWaitLit := -1
    KittyRetries := 0
    global KittyBarBottom, KittyBarSeen, KittyTarget, KittyTargetAt, KittyTargetReads, KittyGeneration, KittyReason
    KittyGeneration := KittyGeneration + 1
    KittyReason := "waiting for signs"
    global KittyReadAt, KittyReadLit, KittyCandidate, KittyConfidence, KittyLastTriedLit, KittyMissAt
    KittyBarBottom := -1
    KittyBarSeen := 0
    KittyTarget := 0
    KittyTargetAt := 0
    KittyTargetReads := 0
    KittyReadAt := 0
    KittyReadLit := -1
    KittyCandidate := 0
    KittyConfidence := 0
    KittyLastTriedLit := -1
    KittyMissAt := 0
}

KittyBeginRefresh(now) {
    global KittyMouseStage, KittyMouseDown, LookDownX, LookDownY
    global KittyRefreshUntil, KittyBarSeen, KittyGlyphCenters, KittyCandidate, KittyConfidence
    global SwClickAt, SwWantK, KittyReason
    ; Cancel only click ownership. Move off old symbols before releasing a held old click.
    ; The separate Space steering hold is preserved across symbol sets.
    if (KittyMouseStage or KittyMouseDown) {
        CoordMode, Mouse, Client
        MouseMove, %LookDownX%, %LookDownY%, 0
        KittyMouseCancel("new sign set")
    }
    KittySequenceReset()
    KittyGlyphCenters := {}
    KittyCandidate := 0
    KittyConfidence := 0
    SwClickAt := 0
    SwWantK := 0
    KittyRefreshUntil := now + 0.06
    ; Reacquire changed geometry immediately instead of rejecting it for 300 ms.
    KittyBarSeen := 0
    RfReelWidthsForget()
    KittyReason := "new sign set; tracking while fresh symbols settle"
    KittyInputLog("SEQUENCE_REFRESH")
}

KittyScan(now) {
    global KittyDiagScanN, SwFrameT, SwPhase, SwPhaseT, SwLit, SwLitPrev, SwStarsValid, SwFound
    global SwClickAt, SwWantK, SwFishX, SwLastStep, KittyMissAt, KittyLastTriedLit, KittyRefreshUntil
    KittyDiagScanN++
    SwFrameT := now
    SwStarsRead(now)
    refreshing := (SwStarsValid and SwLit = 0 and SwLitPrev > 0)
    if (refreshing) {
        KittyBeginRefresh(now)
        SwLitPrev := SwLit ; consume this transition even while the bar is reacquiring
    }
    KittyBarScan(now)
    KittyFishScan(now)
    if (SwFound) {
        KittyMissAt := 0
        if (SwStarsValid) {
            if (!SwPhase) {
                SwPhaseReset()
                if (!refreshing)
                    KittySequenceReset()
                SwPhase := 1
                SwPhaseT := now
                KittyLastTriedLit := -1
            }
            SwLitPrev := SwLit
        }
        ; A transiently missing star row blocks clicks, not bar steering or tracking state.
    } else {
        if (!KittyMissAt)
            KittyMissAt := now
        if (now - KittyMissAt > 0.25) {
            SwPhase := 0
            SwWantK := 0
            SwClickAt := 0
        }
    }
    SwLastStep := now
    SwTip(now)
    return true
}


KittyBarScan(now) {
    global pCaptureBits, CaptureW, CaptureH, FishBarLeft, FishBarTop, WindowWidth, WindowHeight
    global KittyRimTol, KittyBarBottom, KittyBarSeen, KittyPrmRim, KittyPrmRimI
    global SwFound, SwBarHold, SwBarL, SwBarW, SwFrTop, SwFrMiss, SwSB, SwSM, SwW
    global SwCleanL, SwCleanW, SwFoundT, SwLastL, SwLastC, SwFrStillT, SwFrStillRef, SwFrMoveT
    SwFound := false
    SwBarHold := false
    PcSetPrm(KittyPrmRim, "0xFFFFFF", SwTolOf(KittyRimTol, 35), 0, 0)
    PcSetPrm(KittyPrmRimI, "0xFFFFFF", SwTolOf(KittyRimTol, 35), 0, 1)
    s := SwSM
    xa := Max(0, Round(WindowWidth * 0.225) - Round(FishBarLeft))
    xb := Min(CaptureW - 1, Round(WindowWidth * 0.775) - Round(FishBarLeft))
    y0 := Max(0, Round(WindowHeight * 0.80) - Round(FishBarTop))
    y1 := Min(CaptureH - 1, Round(WindowHeight * 0.995) - Round(FishBarTop))
    if (KittyBarSeen and now - KittyBarSeen < 0.3) {
        topRows := []
        bottomRows := []
        for oi, off in [0, -1, 1, -2, 2, -3, 3] {
            yt := SwFrTop + off
            yb := KittyBarBottom + off
            for qi, yy in [yt, yb] {
                if (yy < y0 or yy > y1)
                    continue
                rr := []
                SwRuns(pCaptureBits + yy * CaptureW * 4, xa, xb, KittyPrmRim, KittyPrmRimI, Round(40 * s), rr)
                for ri, v in rr {
                    w := v[2] - v[1] + 1
                    if (w >= WindowWidth * 0.16 and w <= WindowHeight * 0.72 and Abs(w - SwW) <= 0.08 * SwW) {
                        row := {y:yy, l:v[1], r:v[2]}
                        if (qi = 1)
                            topRows.Push(row)
                        else
                            bottomRows.Push(row)
                    }
                }
            }
        }
        for ti, a in topRows {
            for bi, b in bottomRows {
                if (Abs(a.l - b.l) <= 12 * s and Abs(a.r - b.r) <= 12 * s and Abs((b.y - a.y) - (KittyBarBottom - SwFrTop)) <= 3 * s) {
                    KittyBarCommit(a, b, now)
                    return true
                }
            }
        }
    }
    rows := []
    y := y0
    ; Paired long white rims distinguish the bar from the keyboard and progress bar.
    while (y <= y1) {
        rr := []
        SwRuns(pCaptureBits + y * CaptureW * 4, xa, xb, KittyPrmRim, KittyPrmRimI, Round(40 * s), rr)
        for i, v in rr {
            w := v[2] - v[1] + 1
            if (w >= WindowWidth * 0.16 and w <= WindowHeight * 0.72)
                rows.Push({y:y, l:v[1], r:v[2]})
        }
        y++
    }
    for i, a in rows {
        for j, b in rows {
            dh := b.y - a.y
            if (dh < 73 * s or dh > 104 * s)
                continue
            if (Abs(a.l - b.l) > 12 * s or Abs(a.r - b.r) > 12 * s)
                continue
            w := a.r - a.l + 1
            if (KittyBarSeen and now - KittyBarSeen < 0.3 and Abs(w - SwW) > 0.12 * SwW)
                continue
            KittyBarCommit(a, b, now)
            return true
        }
    }
    SwFrMiss++
    return false
}

KittyPink(px) {
    b := px & 255
    g := (px >> 8) & 255
    r := (px >> 16) & 255
    return (r >= 120 and b >= 150 and r - g >= 20 and b - g >= 35)
}

KittyFishScan(now) {
    global pCaptureBits, CaptureW, CaptureH, FishBarLeft, WindowWidth, SwFrTop, SwSB, SwFound
    global SwFishX, SwFishLast, SwFishAt, SwFishHeld, KittyBarBottom
    SwFishX := -1
    SwFishHeld := false
    if (!SwFound or KittyBarBottom < 0)
        return
    xa := Max(0, Round(WindowWidth * 0.225) - Round(FishBarLeft))
    xb := Min(CaptureW - 1, Round(WindowWidth * 0.775) - Round(FishBarLeft))
    xs := []
    for i, dy in [4, 6, 8] {
        y := KittyBarBottom + Round(dy * SwSB)
        if (y >= CaptureH)
            continue
        p := pCaptureBits + y * CaptureW * 4
        ; Same runs as the original per-pixel loop, found by KittyPinkRuns (machine code when ready).
        for ri, run in KittyPinkRuns(p, xa, xb, Round(12 * SwSB)) {
            l := run[1]
            r := run[2]
            w := r - l + 1
            if (w >= 4 * SwSB and w <= 35 * SwSB) {
                cx := Round((l + r) / 2)
                n := 0
                good := 0
                yy := SwFrTop + Round(12 * SwSB)
                while (yy < KittyBarBottom - Round(6 * SwSB)) {
                    px := NumGet(pCaptureBits + (yy * CaptureW + cx) * 4, 0, "UInt")
                    n++
                    if ((px & 255) > 120 and ((px >> 8) & 255) > 120 and ((px >> 16) & 255) > 120)
                        good++
                    yy++
                }
                if (n > 0 and good >= 0.7 * n)
                    xs.Push(cx)
            }
        }
    }
    if (!xs.Length())
        return
    ; Reject competing marker candidates instead of jumping to a cat decoration.
    fx := SwMedian(xs)
    for i, x in xs
        if (Abs(x - fx) > 20 * SwSB)
            return
    SwFishX := Round(FishBarLeft) + fx
    SwFishLast := SwFishX
    SwFishAt := now
}

KittyGlyphPixel(px) {
    b := px & 255, g := (px >> 8) & 255, r := (px >> 16) & 255
    ; Purple glyph ink; exclude neutral silver and the pink paw decorations.
    return (b - r >= 22 and r - g >= 17 and g < 170 and r < 190)
}

KittyMask(k, ByRef m, ByRef kn, shift := 0, store := true) {
    global KittyGlyphCenters, FishBarTop, pCaptureBits, CaptureW, CaptureH, SwSB, SwFrTop, SwPitch, FishBarLeft, SwFrameT, KittyMaskLast
    m := "", kn := "", KittyMaskLast := ""
    cx := SwSlotX(k) - Round(FishBarLeft) + shift
    xlo := Max(0, Round(cx - 0.48 * SwPitch)), xhi := Min(CaptureW - 1, Round(cx + 0.48 * SwPitch))
    ylo := Max(0, Round(SwFrTop + 2 * SwSB)), yhi := Min(CaptureH - 1, Round(SwFrTop + 82 * SwSB))
    if (xhi - xlo + 1 < 2 or yhi - ylo + 1 < 2)
        return
    if (!KittyMaskCore(KittyMcReady(), pCaptureBits, CaptureW, xlo, xhi, ylo, yhi, SwSB, m, kn, g)) {
        m := "", kn := ""
        return
    }
    point := {x: Round(FishBarLeft) + xlo + (g.xl + g.xr) / 2.0, y: Round(FishBarTop) + ylo + (g.yt + g.yb) / 2.0, w:g.w, h:g.h, seen:SwFrameT, cropX:Round(FishBarLeft) + cx}
    KittyMaskLast := point
    if (store)
        KittyGlyphCenters[k] := point
    if (Abs(shift) < 0.5)
        KittyHistNote(k, point)
}

; Ink mask + 16x16 shape grid for one sign crop. fast = machine code; otherwise the original
; AHK code below. Returns false when the crop holds no usable glyph (same rules both ways).
; plain = use the full ink box instead of the main-body box (self-test against the AHK path).
KittyMaskCore(fast, p, stride, xlo, xhi, ylo, yhi, sb, ByRef m, ByRef kn, ByRef g, plain := false) {
    global KittyMcInk, KittyMcDown, KittyTplPOAddr
    static prm := "", out := "", prm2 := "", sums := "", scratch := "", scratchN := 0, init := false
    m := "", kn := "", g := ""
    gw := xhi - xlo + 1, gh := yhi - ylo + 1
    if (gw < 2 or gh < 2)
        return false
    if (fast) {
        if (!init) {
            VarSetCapacity(prm, 32, 0), VarSetCapacity(out, 64, 0), VarSetCapacity(prm2, 48, 0), VarSetCapacity(sums, 16, 0)
            init := true
        }
        need := (gh * 12 + gw * gh + 3) // 4 * 4 + gw * 4 + 64
        if (need > scratchN) {
            scratchN := need * 2
            VarSetCapacity(scratch, scratchN, 0)
        }
        NumPut(stride, prm, 0, "Int"), NumPut(xlo, prm, 4, "Int"), NumPut(xhi, prm, 8, "Int")
        NumPut(ylo, prm, 12, "Int"), NumPut(yhi, prm, 16, "Int"), NumPut(Max(2, Round(4 * sb)), prm, 20, "Int")
        NumPut(Max(2, Round(2 * sb)), prm, 24, "Int")
        count := DllCall(KittyMcInk, "Ptr", p, "Ptr", &prm, "Ptr", &scratch, "Ptr", &out, "Int")
        xl := NumGet(out, 0, "Int"), xr := NumGet(out, 4, "Int"), yt := NumGet(out, 8, "Int"), yb := NumGet(out, 12, "Int")
        ; Main-body box: stray specks and slivers of the neighbouring signs are left out.
        if (!plain and NumGet(out, 36, "Int") > 0)
            xl := NumGet(out, 20, "Int"), xr := NumGet(out, 24, "Int"), yt := NumGet(out, 28, "Int"), yb := NumGet(out, 32, "Int"), count := NumGet(out, 36, "Int")
    } else {
        VarSetCapacity(ink, gw * gh, 0)
        rowL := [], rowR := [], rowN := []
        Loop % gh {
            gy := A_Index - 1, y := ylo + gy
            rp := p + y * stride * 4
            p1 := NumGet(rp + Min(xhi, xlo + 1) * 4, 0, "UInt")
            p2 := NumGet(rp + Min(xhi, xlo + 3) * 4, 0, "UInt")
            p3 := NumGet(rp + Max(xlo, xhi - 3) * 4, 0, "UInt")
            p4 := NumGet(rp + Max(xlo, xhi - 1) * 4, 0, "UInt")
            br := KittyMedian4((p1 >> 16) & 255, (p2 >> 16) & 255, (p3 >> 16) & 255, (p4 >> 16) & 255)
            bg := KittyMedian4((p1 >> 8) & 255, (p2 >> 8) & 255, (p3 >> 8) & 255, (p4 >> 8) & 255)
            bb := KittyMedian4(p1 & 255, p2 & 255, p3 & 255, p4 & 255)
            l := -1, r := -1, n := 0
            Loop % gw {
                gx := A_Index - 1
                px := NumGet(rp + (xlo + gx) * 4, 0, "UInt")
                pb := px & 255, pg := (px >> 8) & 255, pr := (px >> 16) & 255
                if (pb - pr < 22 or pr - pg < 17 or pg >= 170 or pr >= 190)
                    continue
                delta := Max(Abs(pr - br), Abs(pg - bg), Abs(pb - bb))
                if (delta < 18)
                    continue
                NumPut(1, ink, gy * gw + gx, "UChar")
                if (l < 0)
                    l := gx
                r := gx
                n++
            }
            rowL.Push(l), rowR.Push(r), rowN.Push(n)
        }
        ; Reject detached one/two-pixel rail baselines, retaining tall glyph strokes.
        band := 0
        Loop % gh + 1 {
            ri := A_Index
            has := (ri <= gh and rowN[ri] > 0)
            if (has and !band)
                band := ri
            if (!has and band) {
                count := ri - band
                if (count < Max(2, Round(4 * sb))) {
                    DllCall("RtlZeroMemory", "Ptr", &ink + (band - 1) * gw, "UPtr", count * gw)
                    Loop % count {
                        rowL[band + A_Index - 1] := -1
                        rowN[band + A_Index - 1] := 0
                    }
                }
                band := 0
            }
        }
        xl := gw, xr := 0, yt := gh, yb := 0, count := 0
        Loop % gh {
            ri := A_Index
            if (rowL[ri] < 0)
                continue
            xl := Min(xl, rowL[ri]), xr := Max(xr, rowR[ri])
            yt := Min(yt, ri - 1), yb := Max(yb, ri - 1)
            count += rowN[ri]
        }
    }
    w := xr - xl + 1, h := yb - yt + 1
    if (count < 12 or Max(w, h) < 15 * sb or Min(w, h) < 5 * sb)
        return false
    g := {xl:xl, xr:xr, yt:yt, yb:yb, w:w, h:h}
    scale := 14.0 / Max(w, h)
    dw := Max(1, Round(w * scale)), dh := Max(1, Round(h * scale))
    left := (16 - dw) // 2, top := (16 - dh) // 2
    if (fast) {
        NumPut(gw, prm2, 0, "Int"), NumPut(gh, prm2, 4, "Int"), NumPut(xl, prm2, 8, "Int"), NumPut(xr, prm2, 12, "Int")
        NumPut(yt, prm2, 16, "Int"), NumPut(yb, prm2, 20, "Int"), NumPut(dw, prm2, 24, "Int"), NumPut(dh, prm2, 28, "Int")
        NumPut(left, prm2, 32, "Int"), NumPut(top, prm2, 36, "Int")
        ; Grid goes straight into the scorer's value buffer; every Kitty cell is scored, so
        ; the shift-offset table is shared (KittyTplPOAddr) instead of rebuilt per crop.
        kn := {}
        kn.SetCapacity("TpBV", 256 * 8 + 8)
        pv := kn.GetAddress("TpBV")
        DllCall(KittyMcDown, "Ptr", &prm2, "Ptr", &scratch + gh * 12, "Ptr", pv, "Ptr", &sums)
        kn.TpCnt := 256
        kn.TpSumA := NumGet(sums, 0, "Double")
        kn.TpSumAA := NumGet(sums, 8, "Double")
        kn.TpPV := pv
        kn.TpPO := KittyTplPOAddr
        m := {grid: pv}
        return true
    }
    m := [], kn := []
    Loop 256 {
        m.Push(0), kn.Push(1)
    }
    Loop % dh {
        j := A_Index - 1
        Loop % dw {
            i := A_Index - 1, hit := 0
            for ai, oy in [0.25, 0.75] {
                y := Min(yb, Floor(yt + (j + oy) * h / dh))
                for bi, ox in [0.25, 0.75] {
                    x := Min(xr, Floor(xl + (i + ox) * w / dw))
                    hit += NumGet(ink, y * gw + x, "UChar")
                }
            }
            m[(top + j) * 16 + left + i + 1] := hit / 4.0
        }
    }
    return true
}

; Pink fish-marker runs on one capture row: [[l, r], ...] in left-to-right order, exactly
; as the original KittyFishScan loop closed them (a run ends after a gap wider than G).
KittyPinkRuns(p, xa, xb, G) {
    global KittyMcPink
    static prm := "", out := "", init := false
    if (KittyMcReady()) {
        if (!init) {
            VarSetCapacity(prm, 16, 0), VarSetCapacity(out, 512 * 8, 0)
            init := true
        }
        NumPut(xa, prm, 0, "Int"), NumPut(xb, prm, 4, "Int"), NumPut(G, prm, 8, "Int")
        n := DllCall(KittyMcPink, "Ptr", p, "Ptr", &prm, "Ptr", &out, "Int", 512, "Int")
        if (n <= 512) {
            runs := []
            Loop % n
                runs.Push([NumGet(out, (A_Index - 1) * 8, "Int"), NumGet(out, (A_Index - 1) * 8 + 4, "Int")])
            return runs
        }
    }
    return KittyPinkRunsAhk(p, xa, xb, G)
}

KittyPinkRunsAhk(p, xa, xb, G) {
    runs := []
    l := -1
    r := -1
    x := xa
    while (x <= xb + G + 1) {
        hit := (x <= xb) ? KittyPink(NumGet(p + x * 4, 0, "UInt")) : false
        if (hit) {
            if (l < 0)
                l := x
            r := x
        }
        if (l >= 0 and x - r > G) {
            runs.Push([l, r])
            l := -1
            r := -1
        }
        x++
    }
    return runs
}

; Loads the x64 kernels once (VirtualAlloc + VirtualProtect, as SwTplSumFn does) and keeps
; them only if they reproduce the original AHK results on a test strip. Any failure leaves
; Kitty Keys on the original code path, so behaviour never depends on this succeeding.
KittyMcReady() {
    global KittyMcInk, KittyMcDown, KittyMcPink, KittyTplPOBuf, KittyTplPOAddr, KittyMcState
    static Hex := "41574989D74989CB4C89C2415641554154555756534881ECB8000000418B470849634F044D63470C4D63174C898C241801000089C3458B6F1429CB8D7B01895C2478897C241C418B7F104429C7448D7701897C247C4963F64C8D0CB5000000004889B424980000004A8D3C0A4A8D340F4901F14C894C24704585F60F8E8F0B00008D69014863D848897C240848C1E3024C63CD4489AC248000000049C1E1024989DC39C54489B424840000004D0F4CE1498D69084889BC24880000004889B424900000004C89642430448D61034139C4448D60FD4889742410480F4DEB4983E9044139CC4C89BC24080100004E8D249500000000488994241001000048896C2438488D6BF4490F4EE983E8014883EB044C8964245039C84C89C8480F4FC34D0FAFD048896C244048636C241C48635C247848896C24584C01D14F8D04934C8B54247048894424484D8D1C8B48634C247C4889D0488D4C8A0448894C2460488D8C24A400000048894C2468660F1F440000488B742430488B7C24484889442420B9100000004C89442428488B6C2468458B3C30488B742438458B2438458B3430488B742440458B2C304489F84489F64589E94589E0D3E8D3EE41D3E90FB6C0400FB6F641D3E8450FB6C98D1430450FB6C089F74401CA4401C239F00F4EF84439CF410F4FF94439C7410F4FF829FA39F00F4CC64439C8410F4CC14439C0410F4CC083E9084883C50429C28955FC83F9F87597448B64241C488B4424204C8B4424284585E40F8E270800008BAC24A40000008BBC24A800000031C94531ED8BB424AC00000041BEFFFFFFFF41BCFFFFFFFFEB0A0F1F80000000004889C1418B048B4E8D0C1141C6010089C2440FB6C0C1EA104589C70FB6D24129D74183FF157E6D0FB6C44189D74129C74183FF107E5E3DA90000007F5781FABD0000007F4F01D24189EF4129D729EA410F48D701C04189FF4129C729F8410F48C74501C04189F74529C74129F0450F48C739C20F4CD04439C2410F4CD083FA237E1241C601014585E44189CE440F48E14183C501488D41014839D90F855FFFFFFF488B4424204C8B442428488B7C2408488B7424104489204883C0044489374883C7044883C60448897C2408488B7C245044896EFC4901F848897424104901FB488B742460488B7C24584901FA4839F00F8522FEFFFF448BAC2480000000448BB42484000000488BBC2488000000488BB424900000004C8BBC2408010000488B9424100100008B44247C41B90100000041BB0100000083C0024585F6744A428B6C8EFC31C985ED7E2C85C90F85E80500004983C1014439C80F8C120100004589CA4489D94539CE7C17428B6C8EFC4D63D985ED7FD44589DA4C63D94585DB74084529DA4539D57F204983C1014439C80F8CDB0000004539CE7CEE4D63D9EB9F660F1F8400000000004585D27EDB458D43FF48635C241C8B6C24784D63D24D63C0488B4C247044896C24084D01DA4D89C44489742410448B74241C49C1E0024C0FAFE3488D4C29014C01E14E8D2495FCFFFFFF660F1F4400004989CB4929EB4D8D53FF4585F67E334989CD4D29D54183E501741541C643FF004D89DA4C39D9741A0F1F84000000000041C602004983C20241C642FF004C39D175EE42C70402FFFFFFFF4801D942C70406000000004983C0044D39C475A24983C101448B6C2408448B7424104439C80F8D28FFFFFF0F1F004585F60F844A0700004C634C247C8B6C241C4589F331C04531C04531D231DBEB0A0F1F80000000004889C88B0C8285C9781F39CD0F4FE98B0C8739CB0F4CD94139C3440F4FD84139C2440F4CD044030486488D48014939C175CE488B842418010000660F6F05CE0A00008928895804448958084489500C44894010C74024000000000F1140144585C00F8E16040000418B47184C637C241C4C894C24204D8D6102488B9C249800000041BDFFFFFFFFBDFFFFFFFFC7442410FFFFFFFF89442408498D470C41BAFFFFFFFF480FAFC331DB4883C0034883E0FC488D0C0231C0BAFFFFFFFF48894C24284589D141F7D141C1E91F4139C60F8EED030000448B1C8689C74585DB7E3A4584C90F84070400004189C18B4C24084129E94139C90F8E260400004439EB0F8EB3050000896C24104189DD4489D24489DB4189C289FD0F1F004883C0014939C4759F478D2C004C8B4C2420488B4C24284531DB438D44050044896C2428BFFFFFFFFF41BAFFFFFFFF448D24850000000031C048894C24204983C1014139C67E3C908B1C8689C585DB7E214585D20F88960300004189C58B4C24084129FD4139CD0F8FAB0300004101DB89EF488D58014939C174234889D84139C67FC54585D20F899C0400004531DB41BAFFFFFFFF488D58014939C175DD448B5C241C488B4C24204585DB0F8E1B0500004C635424784889C84E8D4C910441F6C2017514488D4104C701000000004939C1741B0F1F440000C700000000004883C008C740FC000000004939C175EA8B44241039C20F8F7F0000004C63DA8B44247889D64D0FAFDF488D5C8104448B54241C4585D20F8EF7030000488B7C24708B6C24100F1F4400004E8D141F4989C9660F1F840000000000410FB602458B214983C1044983C2014401E0418941FC4C39CB75E583C6014D01FB39F57DCB48897C2470896C2410448B4C241C4585C90F8E410400004C635424784889C84E8D54910431DB0F1F440000448B084883C0044401CB4939C275F14989C98B7C2478895424204989CA4C894C2428B9FFFFFFFF8B6C241C31C0448944243083C7024531E4BEFFFFFFFF41BDFFFFFFFF41BBFFFFFFFF41BEFFFFFFFF4189C8660F1F44000089F2F7D2C1EA1F39C50F8E71020000418B0A85C97E3A84D20F84A602000089C2448B4C24084429F24439CA0F8ED70200004539E00F8D910300004589E04589F54189F34189CC89C64189C60F1F44000083C0014983C20439F875A5448D341B4C8B4C2428448B44243031F6418D041E895C24288B5C241CBDFFFFFFFFC1E002448974241C8B54242041BAFFFFFFFF448B7424088944242031C00F1F800000000039C30F8E48020000418B0985C97E1C4585D20F88F60100004189C44129EC4539F40F8F4902000001CE89C583C0014983C10439F875CA8B7C241039FA0F8F9B0300004863DA488B4424704489ED83C701490FAFDF4429DD31F641BCFFFFFFFF41BAFFFFFFFF4801D84889C34963C34801C34801EB0F1F40004539DD7C2F4889D84531C94829E866900FB6084989C64883C0014101C94939DE75EE4585C97E0D4585D24189D4440F48D24401CE83C2014C01FB39FA75C266410F6ECA66410F6ED466410F6EC3488B84241801000066410F6EDD660F62CA660F62C3897024660F6CC10F1140144881C4B80000004489C05B5E5F5D415C415D415E415FC3428B5C8EFC85DB0F8E0D0200004983C1014139C10F8F2AFBFFFF4589CA4539F17EDE4C63D9E92AFAFFFF66904439EB7E0F4584C9740A896C24104189DD4489D24883C00131DB41BAFFFFFFFF4939C40F85D7FBFFFFE933FCFFFF4585DB0F8E21FCFFFF4401DB4585D289FD440F48D0E910FCFFFF85DB0F8E7AFCFFFF4101DB4585D2440F48D0E969FCFFFF904401DB89FDE9EEFBFFFF660F1F440000456BDB644539E37C148B4C24104439D2410F4FD239F90F4DF9897C24104189DB4189C2E930FCFFFF0F1F8400000000004531ED41BEFFFFFFFF41BCFFFFFFFFE99FF8FFFF0F1F40004539E07D0D84D274094589E04589F54189F383C0014531E4BEFFFFFFFF4983C20439F80F8557FDFFFFE9ADFDFFFF85C90F8E15FEFFFF01CE4585D2440F48D0E905FEFFFF85C90F8E84FDFFFF4101CC85F60F48F04189C683C0014983C20439F80F851AFDFFFFE970FDFFFF0F1F4400004585D20F898800000031F641BAFFFFFFFFE9C5FDFFFF66904101CCEBC70F1F006BF664397424207F0E4539D3450F4FDA4139ED440F4CED89CE4189C2E998FDFFFF8B44241083C6014D01FB39C60F8EE9FBFFFFE93EFCFFFF8B5C2428456BDB644401C3C1E3024439DB0F8F4DFBFFFF8B5C24104439D2410F4FD241BAFFFFFFFF39FB0F4CDF4531DB895C2410E911FBFFFF8B4C241C448B6424286BF6644401E1C1E10239CE0F8C5EFFFFFF4539D3450F4FDA4139ED41BAFFFFFFFF440F4CED31F6E915FDFFFF4589CBE927F8FFFF4489DB4189C289FDE955FAFFFF4189CC89C6E9FFFEFFFF0F84B500000041BDFFFFFFFF41BBFFFFFFFFE9EAFCFFFF8B44241039C20F8E22FBFFFF8B44241C85C00F848C00000041BBFFFFFFFF41BDFFFFFFFF31F641BCFFFFFFFF41BAFFFFFFFFE933FDFFFF0F1F440000837C247CFF0F8463F7FFFF488B8424180100008B5C241C4531C08918488B9C2418010000C74004000000004489700848C7400C0000000048B800000000FFFFFFFF488943144889431CC7432400000000E908FDFFFF31F641BCFFFFFFFF41BAFFFFFFFFE9C6FCFFFF31DBE920FBFFFF9041574989D7415641554154554C89CD5756534883EC58448B510C8B5118448B71088B59104C898424B00000004489D08B79148B31895424184429F08B511C448B4920895C241C83C001897C2408895424148B51244C89C14D8D80000800008944242089F84989CB29D883C0010F1F400049C703000000004983C31049C743F8000000004D39D875E8448B5C24144585DB0F8EA20100008B5C2414C7442404000000004C89442440F20F100DE10200008D3C9D000000008D1C850000000048894C2448895C242C89C389D0C1E004897C24248B7C24184401C84889AC24B8000000448B4C24088944240C8D041B448D1CBD00000000894424288B442420895C2408448D248500000000448D2C004863C648894424304863C748894424380F1F40008B4424088B7C24248B74241C8B5C242899F7FF8D0C308B4424084439C9410F4FC901D899F7FF01F04439C8410F4FC14863E88B44241885C00F8EA8000000488B5C24304863C1486354240C44894C2410488BB424B0000000488B7C2438480FAFEB8B4C2420480FAFC34C8D04D64801FA488D3CD6498D342F498D1C070F1F400089C8660FEFC09941F7FB4401F04439D0410F4FC24898440FB60C060FB604034101C1418D440D009941F7FB4401F04439D0410F4FC24983C0084401E148980FB614034C01F80FB604284401CA01D0F20F2AC0F20F59C1F2410F1140F84C39C7759F448B4C241083442404018B74242C8344240C108B44240401742408394424140F85FAFEFFFF4C8B442440488B4C2448488BAC24B8000000660FEFC90F1F4000F20F10014883C108660F28D0F20F59D0660F14C2660F58C84939C875E30F114D004883C4585B5E5F5D415C415D415E415FC3662E0F1F8400000000000F1F4000415741564989CE4155415455575653448B6204448B7A088B0A438D043C8D500139D10F8FB80000004863D129C831FF41BDFFFFFFFF8D7001488D420141BAFFFFFFFF4189D34801C64139D47C7F0F1F00418B1C9689D90FB6EBC1E9100FB6C983F9777E6881FD950000007E600FB6DF29D983F9137E5629DD83FD227E4F4189D531C94585D27871660F1F8400000000004439F97E234139F97E0F8D143F4863D24589149045896C900483C70141BDFFFFFFFF41BAFFFFFFFF4889C24839F074224883C0014189D34139D47D844585D278E74489D94429E9EBB70F1F800000000031FF5B89F85E5F5D415C415D415E415FC30F1F80000000004189D2EBCF0F1F0000000000FFFFFFFF00000000FFFFFFFF000000000000D03F"
    if (KittyMcState != "")
        return (KittyMcState = 1)
    KittyMcState := 0
    if (A_PtrSize != 8 or !SwTplSumFn())
        return false
    n := StrLen(Hex) // 2
    p := DllCall("VirtualAlloc", "Ptr", 0, "Ptr", n, "UInt", 0x3000, "UInt", 0x04, "Ptr")
    if (!p)
        return false
    Loop, %n%
        NumPut("0x" . SubStr(Hex, 2 * A_Index - 1, 2), p + 0, A_Index - 1, "UChar")
    if (!DllCall("VirtualProtect", "Ptr", p, "Ptr", n, "UInt", 0x20, "UIntP", oldProt)) {
        DllCall("VirtualFree", "Ptr", p, "Ptr", 0, "UInt", 0x8000)
        return false
    }
    KittyMcInk := p, KittyMcDown := p + 3200, KittyMcPink := p + 3840
    ; Shift-offset table for the template scorer, identical to SwTplPrep's for a full grid.
    VarSetCapacity(KittyTplPOBuf, 9 * 256 * 4, 0)
    q := 0
    Loop 3 {
        dx := A_Index - 2
        Loop 3 {
            dy := A_Index - 2
            Loop 256 {
                c := A_Index - 1
                NumPut(Mod(c // 16 - dy + 16, 16) * 16 + Mod(Mod(c, 16) - dx + 16, 16), KittyTplPOBuf, q * 4, "Int")
                q++
            }
        }
    }
    KittyTplPOAddr := &KittyTplPOBuf
    KittyMcState := 1
    if (!KittyMcSelfTest()) {
        KittyMcState := 0
        KittyMcInk := 0, KittyMcDown := 0, KittyMcPink := 0
        return false
    }
    return true
}

; Draws a small synthetic strip (noisy purple background, glyph strokes, a one-pixel rail,
; pink marks) and requires the kernels to match the original AHK code exactly.
KittyMcSelfTest() {
    tw := 97, th := 72
    VarSetCapacity(tb, tw * th * 4, 0)
    seed := 777
    Loop % tw * th {
        seed := Mod(seed * 1103515245 + 12345, 2147483648)
        NumPut(0x3A2A50 + ((seed >> 9) & 0x070307), tb, (A_Index - 1) * 4, "UInt")
    }
    for si, s in [[30, 33, 8, 47, 0x9677B9], [18, 52, 20, 23, 0x9677B9], [44, 47, 30, 58, 0x8A60C8], [60, 88, 12, 15, 0xA070B8], [70, 73, 10, 50, 0x9677B9], [5, 9, 5, 9, 0x9677B9]] {
        y := s[3]
        while (y <= s[4]) {
            x := s[1]
            while (x <= s[2]) {
                NumPut(s[5], tb, (y * tw + x) * 4, "UInt")
                x++
            }
            y++
        }
    }
    Loop % tw {
        NumPut(0x9677B9, tb, (62 * tw + A_Index - 1) * 4, "UInt")
        if (A_Index > 4 and A_Index < 22)
            NumPut(0xE070F0, tb, (66 * tw + A_Index - 1) * 4, "UInt")
        if (A_Index > 40 and A_Index < 47 or A_Index = 60)
            NumPut(0xD068E8, tb, (66 * tw + A_Index - 1) * 4, "UInt")
    }
    passed := 0
    for ti, t in [[2, 94, 3, 68, 1.0], [10, 60, 0, 71, 0.8], [40, 96, 5, 60, 1.3], [0, 40, 2, 70, 0.6], [25, 50, 0, 30, 1.0]] {
        a := KittyMaskCore(false, &tb, tw, t[1], t[2], t[3], t[4], t[5], m1, k1, g1)
        b := KittyMaskCore(true, &tb, tw, t[1], t[2], t[3], t[4], t[5], m2, k2, g2, true)
        if (a != b)
            return false
        if (!a)
            continue
        if (g1.xl != g2.xl or g1.xr != g2.xr or g1.yt != g2.yt or g1.yb != g2.yb)
            return false
        ; the main-body box always lies inside the full box
        if (KittyMaskCore(true, &tb, tw, t[1], t[2], t[3], t[4], t[5], m3, k3, g3)
            and (g3.xl < g2.xl or g3.xr > g2.xr or g3.yt < g2.yt or g3.yb > g2.yb))
            return false
        SwTplPrep(m1, k1)
        if (k1.TpCnt != 256 or k2.TpCnt != 256 or k1.TpSumA != k2.TpSumA or k1.TpSumAA != k2.TpSumAA)
            return false
        Loop 256 {
            if (m1[A_Index] != NumGet(k2.TpPV, (A_Index - 1) * 8, "Double"))
                return false
        }
        Loop % 9 * 256 {
            if (NumGet(k1.TpPO, (A_Index - 1) * 4, "Int") != NumGet(k2.TpPO, (A_Index - 1) * 4, "Int"))
                return false
        }
        passed++
    }
    for ri, r in [[66, 0, 96, 12], [66, 3, 50, 2], [62, 0, 96, 5], [20, 10, 80, 0]] {
        fast := KittyPinkRuns(&tb + r[1] * tw * 4, r[2], r[3], r[4])
        slow := KittyPinkRunsAhk(&tb + r[1] * tw * 4, r[2], r[3], r[4])
        if (fast.Length() != slow.Length())
            return false
        for i, v in slow {
            if (fast[i][1] != v[1] or fast[i][2] != v[2])
                return false
        }
        if (ri = 1 and !slow.Length())
            return false
    }
    return (passed >= 2)
}

; Per-slot glyph geometry for the current sign set. A glyph seen sitting still across frames
; counts as settled the moment it becomes the target, instead of re-waiting from scratch.
KittyHistNote(k, point) {
    global KittyGlyphHist, SwSB
    if (!IsObject(KittyGlyphHist))
        KittyGlyphHist := {}
    old := KittyGlyphHist[k]
    tol := Max(2, 4 * SwSB)
    if (IsObject(old) and Abs(point.x - old.x) <= tol and Abs(point.y - old.y) <= tol
        and Abs(point.w - old.w) <= Max(2, old.w * 0.06) and Abs(point.h - old.h) <= Max(2, old.h * 0.06)) {
        if (point.seen > old.last) {
            old.reads := old.reads + 1
            old.last := point.seen
        }
        return
    }
    KittyGlyphHist[k] := {x:point.x, y:point.y, w:point.w, h:point.h, since:point.seen, last:point.seen, reads:1}
}

KittyHistSettled(k, point, now) {
    global KittyGlyphHist, SwSB, SwFastClicks
    if (!IsObject(KittyGlyphHist))
        return false
    hs := KittyGlyphHist[k]
    if (!IsObject(hs) or hs.reads < 2)
        return false
    tol := Max(2, 4 * SwSB)
    if (Abs(point.x - hs.x) > tol or Abs(point.y - hs.y) > tol
        or Abs(point.w - hs.w) > Max(2, hs.w * 0.06) or Abs(point.h - hs.h) > Max(2, hs.h * 0.06))
        return false
    return (now - hs.since >= (SwFastClicks ? 0.025 : 0.06))
}

; While a click is in flight or awaiting its star, measure every other slot once per frame
; (cheap with the kernels) so the next sign's position is already known to be steady.
KittySurvey() {
    global SwFrameT, SwFound, SwStarsValid, KittyMouseStage, KittyMouseSlot
    static lastFrame := 0
    if (!KittyMcReady() or !SwFound or !SwStarsValid or SwFrameT = lastFrame)
        return
    lastFrame := SwFrameT
    Loop 12 {
        if (KittyMouseStage and A_Index = KittyMouseSlot)
            continue
        KittyMask(A_Index, m, kn, 0, false)
    }
}

; Follow the target while hovering: if its glyph has shifted a few pixels on a fresh frame
; (and still matches), move the aim onto it before the press goes down.
KittyAimTrack() {
    global KittyMouseStage, KittyMouseSlot, KittyMouseZ, KittyAimCX, KittyAimCY, KittyAimCropX
    global KittyMouseAimW, KittyMouseAimH, KittyMouseX, KittyMouseY, KittyMouseValidatedAt
    global KittyMaskLast, KittyShapeMin, RobloxHwnd, SwFrameT
    static lastFrame := 0
    if (!KittyMcReady() or KittyMouseStage < 1 or KittyMouseStage > 2 or SwFrameT = lastFrame)
        return
    lastFrame := SwFrameT
    k := KittyMouseSlot
    KittyMask(k, m, kn, KittyAimCropX - SwSlotX(k), false)
    if (!IsObject(m) or !IsObject(KittyMaskLast))
        return
    pt0 := KittyMaskLast
    ; Hover highlights can bloat the ink box; only trust a same-size glyph.
    if (Abs(pt0.w - KittyMouseAimW) > Max(3, KittyMouseAimW * 0.15) or Abs(pt0.h - KittyMouseAimH) > Max(3, KittyMouseAimH * 0.15))
        return
    if (KittyShapeScore(m, kn, KittyMouseZ) < Max(0.55, Min(0.95, KittyShapeMin / 100.0)))
        return
    dx := pt0.x - KittyAimCX, dy := pt0.y - KittyAimCY
    if (Abs(dx) > Max(6, KittyMouseAimW * 0.5) or Abs(dy) > Max(6, KittyMouseAimH * 0.5))
        return
    KittyMouseValidatedAt := pt0.seen
    if (Abs(dx) < 2 and Abs(dy) < 2)
        return
    VarSetCapacity(pt, 8, 0)
    NumPut(Round(pt0.x), pt, 0, "Int"), NumPut(Round(pt0.y), pt, 4, "Int")
    if (!DllCall("ClientToScreen", "Ptr", RobloxHwnd, "Ptr", &pt))
        return
    nx := NumGet(pt, 0, "Int"), ny := NumGet(pt, 4, "Int")
    ; One line, so the mouse timer never sees the new aim without the cursor on it.
    KittyAimCX := pt0.x, KittyAimCY := pt0.y, KittyMouseX := nx, KittyMouseY := ny, DllCall("SetCursorPos", "Int", nx, "Int", ny)
}

; The zodiac a just-sent click should light, so that exact +1 star step can confirm after
; two matching frames instead of waiting out the full stability delay.
KittyExpectLit() {
    global KittyWaitLit, KittyMouseStage, KittyMouseZ
    if (KittyWaitLit >= 0)
        return KittyWaitLit
    if (KittyMouseStage >= 3)
        return KittyMouseZ
    return -1
}

; Click timings in ms for the Click speed setting. fast = a confident first try with
; Fast sign clicks on; otherwise the careful timings (retries, weaker matches).
KittyPaceTiming(fast, ByRef hover, ByRef press, ByRef release) {
    global KittyClickSpeed
    if (KittyClickSpeed = "Normal") {
        hover := fast ? 25 : 50
        press := fast ? 65 : 100
        release := fast ? 40 : 75
    } else if (KittyClickSpeed = "Turbo") {
        hover := fast ? 12 : 22
        press := fast ? 34 : 50
        release := fast ? 17 : 30
    } else {
        hover := fast ? 17 : 33
        press := fast ? 45 : 70
        release := fast ? 25 : 50
    }
}

KittyMs() {
    global QpcFreq
    DllCall("QueryPerformanceCounter", "Int64*", t)
    return t * 1000.0 / QpcFreq
}

KittyFindSign(z, ByRef confidence) {
    global KittyShapeMin, KittyShapeMargin, KittyGeneration, KittyScores, KittyGlyphCenters
    global KittyMatchMargin, SwPitch, SwFastClicks, KittyDiagFindN
    static next := 1, expected := -1, generation := -1, winner := 0, best := 0, runner := -9, winMargin := 0
    KittyDiagFindN++
    static quickK := 0, quickZ := -1, quickGen := -1
    KittyTemplatesSetup()
    if (next = 1 and quickK and quickZ = z and quickGen = KittyGeneration) {
        if (KittyQuickMatch(quickK, z, confidence))
            return quickK
    }
    if (expected != z or generation != KittyGeneration or next = 1) {
        expected := z, generation := KittyGeneration
        next := 1, winner := 0, best := 0, runner := -9, winMargin := 0
        KittyScores := ""
    }
    minimum := Max(0.55, Min(0.95, KittyShapeMin / 100.0))
    margin := Max(0.10, Min(0.5, KittyShapeMargin / 100.0))
    ; With the kernels a crop costs well under a millisecond, so all 12 slots fit in one
    ; frame; without them keep the original 4-slots-per-frame split.
    scanN := KittyMcReady() ? 12 : 4
    Loop % scanN {
        if (next > 12)
            break
        k := next
        next++
        slotBest := -9, slotMargin := -9, bestPoint := ""
        offsets := (k = 1 or k = 12) ? [0, -0.12 * SwPitch, 0.12 * SwPitch, -0.24 * SwPitch, 0.24 * SwPitch, -0.36 * SwPitch, 0.36 * SwPitch] : [0, -0.10 * SwPitch, 0.10 * SwPitch]
        for vi, shift in offsets {
            ; Most glyphs need no local offset search. Reserve it for borderline crops.
            if (vi > 1 and ((slotBest < 0.35 and k != 1 and k != 12) or (slotBest >= minimum and slotMargin >= margin)))
                break
            KittyMask(k, m, kn, shift)
            if (!IsObject(m))
                continue
            sc := KittyShapeScore(m, kn, z)
            other := -9
            if (sc >= minimum) {
                Loop 12 {
                    zz := A_Index - 1
                    if (zz != z)
                        other := Max(other, KittyShapeScore(m, kn, zz))
                }
            }
            if (sc > slotBest) {
                slotBest := sc
                slotMargin := sc - other
                bestPoint := KittyGlyphCenters[k]
            }
        }
        KittyScores .= "slot" . k . "=" . Round(slotBest, 3) . " "
        if (slotBest < minimum or slotMargin < margin or !IsObject(bestPoint))
            continue
        KittyGlyphCenters[k] := bestPoint
        if (slotBest > best) {
            runner := best, best := slotBest, winner := k, winMargin := slotMargin
        } else
            runner := Max(runner, slotBest)
        ; The puzzle has one glyph per zodiac. An exceptionally clear match needs no
        ; scan of all remaining slots; Fast sign clicks controls one-pass confirmation.
        if (slotBest >= 0.80 and slotMargin >= 0.20) {
            confidence := slotBest
            KittyMatchMargin := slotMargin
            next := 1
            quickK := k, quickZ := z, quickGen := KittyGeneration
            return k
        }
    }
    confidence := best
    if (next <= 12)
        return -1
    next := 1
    KittyMatchMargin := winMargin
    accepted := (winner and best - runner >= margin) ? winner : 0
    if (accepted)
        quickK := accepted, quickZ := z, quickGen := KittyGeneration
    return accepted
}

KittyInputLog(event) {
    global KittyLogBuffer, KittyMouseZ, KittyMouseSlot, KittyMouseX, KittyMouseY, KittyRetries, SwLit, SwLitRaw, KittyPace, KittyHoverMs, KittyPressMs, KittyReleaseMs, ReFishSpaceDown
    text := A_Now . " tick=" . A_TickCount . " | INPUT " . event . " target=" . SwZodiac(KittyMouseZ) . " slot=" . KittyMouseSlot . " xy=" . KittyMouseX . "," . KittyMouseY . " pace=" . KittyPace . " timing=" . KittyHoverMs . "/" . KittyPressMs . "/" . KittyReleaseMs . " retry=" . (KittyRetries + 0) . " lit=" . SwLit . " raw=" . SwLitRaw . " space=" . (ReFishSpaceDown ? "down" : "up") . "`r`n"
    KittyLogBuffer .= text
}

KittyMouseCancel(reason := "cancelled") {
    global KittyMouseStage, KittyMouseDown, KittyReason
    KittyMouseStage := 0
    if (KittyMouseDown) {
        SendEvent {lbutton up}
        KittyInputLog("CANCEL_RELEASE " . reason)
    }
    KittyMouseDown := false

    KittyReason := reason
    KittyInputLog("CANCEL " . reason)
}

KittyMouseStart(k, point, z) {
    global MacroRunning, RobloxHwnd, KittyMouseStage, KittyMouseDown, KittyMouseDue, KittyMouseStarted
    global KittyMouseX, KittyMouseY, KittyMouseZ, KittyMouseSlot, KittyReason, KittyMouseAimW, KittyMouseAimH
    global KittyGeneration, KittyMouseGeneration, KittyMouseValidatedAt
    global SwFastClicks, KittyConfidence, KittyMatchMargin, KittyRetries
    global KittyHoverMs, KittyPressMs, KittyReleaseMs, KittyAckTimeout, KittyPace
    global KittyAimCX, KittyAimCY, KittyAimCropX
    fast := (SwFastClicks and KittyRetries = 0 and KittyConfidence >= 0.80 and KittyMatchMargin >= 0.20)
    KittyPace := fast ? "fast" : "reliable"
    KittyPaceTiming(fast, KittyHoverMs, KittyPressMs, KittyReleaseMs)
    KittyAckTimeout := fast ? 0.30 : 0.50
    if (!IsObject(point) or !MacroRunning or !WinActive("ahk_id " . RobloxHwnd))
        return false
    VarSetCapacity(pt, 8, 0)
    NumPut(Round(point.x), pt, 0, "Int"), NumPut(Round(point.y), pt, 4, "Int")
    if (!DllCall("ClientToScreen", "Ptr", RobloxHwnd, "Ptr", &pt))
        return false
    KittyMouseX := NumGet(pt, 0, "Int"), KittyMouseY := NumGet(pt, 4, "Int")
    ; Release only the symbol mouse button. Space steering keeps running.
    SendEvent {lbutton up}

    CoordMode, Mouse, Screen
    MouseMove, %KittyMouseX%, %KittyMouseY%, 0
    CoordMode, Mouse, Client
    KittyMouseAimW := point.w, KittyMouseAimH := point.h
    KittyMouseZ := z, KittyMouseSlot := k
    KittyMouseGeneration := KittyGeneration
    KittyMouseValidatedAt := point.seen
    KittyAimCX := point.x, KittyAimCY := point.y, KittyAimCropX := point.cropX
    ; QPC milliseconds: A_TickCount only moves in ~15.6 ms steps, too coarse for these stages.
    KittyMouseStarted := KittyMs()
    KittyMouseDue := KittyMouseStarted + KittyHoverMs
    KittyMouseDown := false
    KittyMouseStage := 1
    KittyReason := "hovering " . SwZodiac(z)
    KittyInputLog("MOVE")
    return true
}

KittyCursorOnTarget() {
    global KittyMouseX, KittyMouseY, KittyMouseAimW, KittyMouseAimH
    VarSetCapacity(pos, 8, 0)
    if (!DllCall("GetCursorPos", "Ptr", &pos))
        return false
    return (Abs(NumGet(pos, 0, "Int") - KittyMouseX) <= Max(6, KittyMouseAimW * 0.35) and Abs(NumGet(pos, 4, "Int") - KittyMouseY) <= Max(6, KittyMouseAimH * 0.35))
}

; Ticked by KittyMouseTimer and also every main-loop frame (KittyClickStep), so stages
; advance at frame rate instead of the 10-16 ms timer. The guard stops the timer thread
; from running a stage while an interrupted main-loop tick is midway through one.
KittyMouseTick() {
    static busy := false
    if (busy)
        return
    busy := true
    KittyMouseTickCore()
    busy := false
}

KittyMouseTickCore() {
    global MacroRunning, RobloxHwnd, KittyMouseStage, KittyMouseDown, KittyMouseDue, KittyMouseStarted
    global KittyMouseZ, KittyMouseSlot, KittyReason, KittyDiagIssuedN, KittyMouseX, KittyMouseY
    global KittyWaitLit, KittyWaitAt, KittyWaitSlot
    global SwStarsValid, SwLit, SwLitRaw, KittyHoverMs, KittyPressMs, KittyReleaseMs
    if (!KittyMouseStage)
        return
    nowMs := KittyMs()
    if (!MacroRunning or !KittyMode() or !WinActive("ahk_id " . RobloxHwnd)) {
        KittyMouseCancel("click cancelled: game inactive or macro stopped")
        return
    }
    if (KittyMouseStage <= 2 and !KittyPressEligible()) {
        KittyMouseCancel("puzzle or expected sign changed before press")
        return
    }
    if (nowMs - KittyMouseStarted > 900) {
        KittyMouseCancel("click watchdog released mouse")
        return
    }
    ; After release, let a confirmed response end the neutral dwell early.
    if (KittyMouseStage = 4 and SwStarsValid and SwLit = SwLitRaw and SwLit > KittyMouseZ) {
        KittyMouseStage := 0
        return
    }
    accepted := (SwStarsValid and SwLit = SwLitRaw and SwLit > KittyMouseZ)
    if (nowMs < KittyMouseDue and !(KittyMouseStage = 3 and accepted))
        return
    if (KittyMouseStage = 1) {
        if (!KittyCursorOnTarget()) {
            KittyMouseCancel("cursor moved off symbol before hover")
            return
        }
        ; Roblox must receive movement/hover events, not just a teleported pointer.
        DllCall("SetCursorPos", "Int", KittyMouseX + 1, "Int", KittyMouseY)
        DllCall("SetCursorPos", "Int", KittyMouseX, "Int", KittyMouseY)
        KittyMouseStage := 2
        KittyMouseDue := nowMs + KittyHoverMs
        return
    }
    if (KittyMouseStage = 2) {
        if (!KittyAimForPress() or !KittyPressEligible()) {
            KittyMouseCancel("symbol changed or disappeared before press")
            return
        }
        SendEvent {lbutton down}
        KittyDiagIssuedN++
        KittyMouseDown := true
        KittyMouseStage := 3
        KittyMouseDue := nowMs + KittyPressMs
        KittyReason := "button down on " . SwZodiac(KittyMouseZ)
        KittyInputLog("DOWN")
        return
    }
    if (KittyMouseStage = 3) {
        SendEvent {lbutton up}
        KittyMouseDown := false

        KittyWaitLit := KittyMouseZ
        KittyWaitSlot := KittyMouseSlot
        KittyWaitAt := SwNow()
        KittyMouseStage := 4
        KittyMouseDue := nowMs + (accepted ? 0 : KittyReleaseMs)
        KittyReason := "press sent; checking " . SwZodiac(KittyWaitLit) . " star"
        KittyInputLog("UP_AWAIT_ACK")
        return
    }
    ; Neutral mouse dwell ends here; independent Space steering has continued throughout.
    KittyMouseStage := 0
}

KittyMouseTimer:
KittyMouseTick()
return

KittySequenceReset() {
    global KittyGlyphCenters, KittyGlyphHist
    KittyGlyphCenters := {}
    KittyGlyphHist := {}
    global KittyMouseStage, KittyMouseDown, KittyWaitLit, KittyRetries, KittyTarget, KittyTargetReads
    global KittyLastTriedLit, KittyGeneration, KittyReadAt, KittyRecheckAt
    if (KittyMouseStage or KittyMouseDown)
        KittyMouseCancel("sign sequence reset")
    KittyWaitLit := -1
    KittyRetries := 0
    KittyTarget := 0
    KittyTargetReads := 0
    KittyLastTriedLit := -1
    KittyGeneration++
    KittyReadAt := 0
    KittyRecheckAt := 0
}

KittyClickStep() {
    global KittyDiagClickN, KittyMouseStage, KittyReason, MacroRunning, RobloxHwnd, SwClickSigns
    global SwStarsValid, SwFound, SwFishX, SwBarL, SwBarW, SwSB, SwLit, SwLitRaw, SwPhase
    global KittyWaitLit, KittyWaitAt, KittyWaitSlot, KittyRetries, KittyDiagAckN, KittyDiagRetryN
    global KittyReadAt, KittyTarget, KittyTargetAt, KittyTargetReads, KittyCandidate, KittyConfidence, KittyAckTimeout
    global KittyGlyphCenters, KittyGeneration, KittyRecheckAt, LookDownX, LookDownY, SwFastClicks, KittyMatchMargin, KittyRefreshUntil
    KittyDiagClickN++
    KittyMouseTick()
    if (KittyMouseStage) {
        KittyAimTrack()
        KittySurvey()
        return
    }
    if (!MacroRunning or !WinActive("ahk_id " . RobloxHwnd) or !SwClickSigns) {
        KittyReason := SwClickSigns ? "waiting for active running game" : "sign clicking disabled"
        return
    }
    if (!SwStarsValid or !SwPhase) {
        KittyReason := "waiting for star row / sign phase"
        return
    }
    now := SwNow()
    if (KittyWaitLit >= 0) {
        ; Only observed, stable prefix advancement confirms progress. Button events do not.
        if (SwLit = SwLitRaw and SwLit > KittyWaitLit) {
            KittyDiagAckN++
            KittyInputLog("ACK_STAR_ADVANCED")
            KittyWaitLit := -1
            KittyRetries := 0
            KittyTarget := 0
            KittyTargetReads := 0
            KittyGeneration++
            KittyReason := "confirmed; next " . ((SwLit < 12) ? SwZodiac(SwLit) : "sequence complete")
        } else if (SwLitRaw > KittyWaitLit and SwLitRaw != SwLit) {
            KittyReason := "star changed; waiting for stable confirmation"
            KittySurvey()
            return
        } else if (SwLit < KittyWaitLit) {
            KittySequenceReset()
            return
        } else if (now - KittyWaitAt < KittyAckTimeout) {
            KittySurvey()
            return
        } else {
            ; No permanent retry cap: retry this zodiac while the live puzzle remains active.
            ; Clear hover, then require a fresh shape match and a fresh measured click point.
            KittyRetries++
            KittyDiagRetryN++
            KittyInputLog("RETRY_NO_STAR_ADVANCE")
            KittyWaitLit := -1
            KittyTarget := 0
            KittyTargetReads := 0
            KittyGeneration++
            KittyReadAt := 0
            KittyRecheckAt := now + 0.04
            MouseMove, %LookDownX%, %LookDownY%, 0
            KittyReason := "not confirmed; rechecking same symbol for retry " . KittyRetries
            return
        }
    }
    if (now < KittyRefreshUntil) {
        KittyReason := "new set settling; symbols next"
        return
    }
    if (now < KittyRecheckAt)
        return
    if (!SwFound or SwFishX < 0 or SwLit >= 12 or SwLit != SwLitRaw)
        return
    ; Every captured frame is matched when the kernels are active (one frame = one read).
    if (!KittyMcReady() and now - KittyReadAt < (SwFastClicks ? 0.015 : 0.03))
        return
    KittyReadAt := now
    k := KittyFindSign(SwLit, score)
    if (k < 0) {
        KittyReason := "matching " . SwZodiac(SwLit) . " (partial scan)"
        return
    }
    KittyCandidate := k, KittyConfidence := score
    if (!k) {
        KittyTargetSettled(0, "", now)
        KittyTarget := 0
        KittyTargetReads := 0
        KittyReason := "no accepted " . SwZodiac(SwLit) . "; best " . Round(score * 100) . "%"
        return
    }
    KittyReason := "matched " . SwZodiac(SwLit) . " slot " . k . " (" . Round(score * 100) . "%)"
    if (!IsObject(KittyGlyphCenters[k]) or !KittyTargetSettled(k, KittyGlyphCenters[k], now))
        return
    if (KittyRecheckTarget(k, SwLit))
        KittyMouseStart(k, KittyGlyphCenters[k], SwLit)
}


StellarSkinChanged:
GuiControlGet, NewStellarSkin, 1:, StellarSkin
if (MacroRunning) {
    GuiControl, 1:ChooseString, StellarSkin, %StellarSkin%
    return
}
StellarSkin := NewStellarSkin
KittyKeysEnabled := (StellarSkin = "Kitty Keys")
SwFightReset()
gosub, QueueAutoSave
gosub, RfRodChangedUi
return


KittyBarCommit(a, b, now) {
    global FishBarLeft, SwFound, SwBarHold, SwBarL, SwBarW, SwW, SwCleanL, SwCleanW
    global SwLastL, SwLastC, SwFrTop, SwFrStillT, SwFrMoveT, SwFrStillRef, SwSB
    global SwFoundT, SwFrMiss, KittyBarSeen, KittyBarBottom, SwSM
    s := SwSM
    w := a.r - a.l + 1
    dh := b.y - a.y
            if (KittyBarSeen and Abs(a.y - SwFrTop) <= 3 * s) {
                if (!SwFrStillT)
                    SwFrStillT := now
            } else {
                SwFrStillT := now
                SwFrMoveT := now
            }
            SwFrTop := a.y
            SwFrStillRef := a.y
            KittyBarBottom := b.y
            SwSB := dh / 90.0
            SwBarL := Round(FishBarLeft) + a.l
            SwBarW := w
            SwW := w
            SwCleanL := a.l
            SwCleanW := w
            SwLastL := SwBarL
            SwLastC := SwBarL + w / 2
            SwFound := true
            SwFoundT := now
            SwFrMiss := 0
            KittyBarSeen := now
    return true
}


KittyTemplatesSetup() {
    global KittyTplF, KittyTplFBuf
    static ready := false
    if (ready)
        return
    hex := "0000000000000000000000000000000000000000000000000000000000000000000080D54000000000000080FF8000000080C080C0C000000000C0C080FF400000FF2B000080D50000D580000080D50000FF00000000C055C0C000000080800000808000000040AAFF4000000080800000404000000000FFC00000000000000000000000000000FF800000000000000000000000000000AA800000000000000000000000000000AA800000000000000000000000000000AA000000000000000000000000000000AA0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000FFC00000000000000000FF800000000080FF0000000000000040FF800000000040FFC0000000000000C0FF00000000000080FFD555555580D5D52B0000000000000080FFFFFFFFFFFF800000000000000040FFFF40000040C0FF40000000000000FFC0000000000000C0FF400000000080FF4000000000000000FFC00000000080FF0000000000000000C0FF0000000080FF000000000000000080FF0000000080FF550000000000002BFFAA0000000000C0FF400000000000C0FF40000000000040FFFF802B4080FFFF40000000000000000080FFFFFFFFC04000000000000000000000000000000000000000000000000000000000000000000000000000C0FF800000000000000080C0FF00000080C0FFFFFFFF80FFFFFFFFC080000000000000C0FF80AA80FFC000000000000000000080FF000000808000000000000000000080FF000000808000000000000000000080FF000000808000000000000000000080FF000000808000000000000000000080FF000000808000000000000000000080C000000080800000000000000000008080000000808000000000000000000080AA0000008080000000000000004080C0FFFFFFFFFFC0400000000000C0FFFFFF8080808080FFFFFF80000000408000000000000000004080FF0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004080FFC080AAFFC080000000000000C0FF40000000000000400000000000C6AAAAD53900000000000000000000C055000000AA00000080FFFFD5000000FF00000000D5000080C0000080800000C055000000AA0000AA00000000FF000040D54040C0550000AA00000000FF0000005580804000000080C0000055C0000000000000000000000080FFD5AA00000000004080000000002B80FF800000000000004080C0FFFFFFD580000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000C0FFFFFF800000000000000000000080C02B0040C040000000000000000000FF4000000040FF000000000000000000FF0000000000FF000000000000000000FF0000000040FF000000000000000080FF80000000C04000000000000040FFC0C0FF000080C000000000000000C0800000C08040FF4000000000000000FF00000080AAC0800000000000000000C0800000C0FFC00000000000000000002BAAD5AA80AA800000000000000000000000000000AA80000000FF0000000000000000000055C00000C0C00000000000000000000000C0FFFFC040000000000000000000000000000000000000000000000000000000000000000000000000FFC040D5C040808080AAFFC00000000080FFFFAAC0FFFF80FFFF80FF800000000080FF2B80FF800080AA0080C00000000080FF0000FF800055AA0080FF0000000080FF0000FF400000AA0080FF0000000080FF0000FF000000AA0080C00000000080FF0000FF000000AA0080800000000080FF0000FF000080AA00FF800000000080FF0000FF000080AA00FF400000000080FF0000FF000080AA80FF000000000080AA0000FF000080C6D5AA00000000000000000000000000FFFF00000000000000000000000040C0FFFFC0400000000000000000000080802B80C08000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080FFFF800000000000000000000040FF80000080FF400000000000000000FF2B000000002BD51C0000000000005580000000000000805500000000000000C0000000000000805500000000000000FF400000000040FF0000000000C0FFFFFF800000000080FF8080800000000000000000000000002B555555000000000000000000000000000000000000C0FFFFFF80808080808080808040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000FF80AAFFC0408080000000000000000040FFFF80FFFFAAC0C0000000000000000080AA0080FF0040FF000000000000000080710080FF0000FF000000000000000080550040FF0000FF000000000000000080550000FF0000FF000000000000000080550000FF0000FF000000000000000080550000FF0000FF000000000000000080550000FF0000FF000000000000000080550000FF0000FF00000000000000002B1C0000550000FF800039D5000000000000000000000040FFFFFFFFC000000000000000000000000000AAFF8000000000000000000000000000AA4000000000000000000000000000000000000000000000000000000000000000000000000000000000000080FFFFFFFFFFFF00000000000000000040808080C0FFFF00000000000000000000000080FFC6FF0000000000000000000000C0FF4055FF0000000000000000000080FF400055FF00000000000000000040FF40000055FF000000390000000080FF5500000039AA000000D5C0000080C04000000000000000000000C0C080D500000000000000000000000040FFFF2B000000000000000000000000C0FFFF800000000000000000000000AAD52B00AA80000000000000000000C0D50000000080000000000000000000C02B0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000C080000040C0FFC0000000000000000040C08000FF40008080000000000000000000D5FF800000808000000000000000000055FF000000808000000000000000000055C00000008080000000000000000000558000000080800000000000000000002B4000000080800080FFC00000000000000000000080FFFFC00080C000000000000000000040FFC0000000FF00000000000000000080FFC04000C0C0000000000000000055FF4040C0FF8000000000000000FFFFD5400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002BFF40000040800000008055000000008E00AA2B3980557100AA558E000000C02B0040C0AA0000AAC080002BFF0000000000000000000000000000000000000055FF40000080802B0040805500000000AA00AA2B71552B7100D52B71000000802B0040C0AA000080FF40002B8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080C00000000000000000C0FF0000000000FFC000000000000080FF40000000000040FF000000000000FF8000000000000000FF800000000080FF000000000000000080FF00000000C0C0000000000000000080FF00000000FF80000000000000FFFFFFFFFFFFFFFFFFFFFFFF000000008080C0FF80808080FFC0808000000000000080FF00000000FF800000000000000000C0C00000000080C00000000000000000FF800000000040FF0000000000000080FF000000000000FF80000000000040FF8000000000000080FF400000000080C00000000000000000C080000000000000000000000000000000000000"
    global KittyTplBytes
    VarSetCapacity(KittyTplBytes, 3072, 0)
    Loop 3072
        NumPut("0x" . SubStr(hex, A_Index * 2 - 1, 2), KittyTplBytes, A_Index - 1, "UChar")
    KittyTplF := []
    VarSetCapacity(KittyTplFBuf, 3072 * 8, 0)
    Loop 3072 {
        v := NumGet(KittyTplBytes, A_Index - 1, "UChar") / 255.0
        KittyTplF.Push(v)
        NumPut(v, KittyTplFBuf, (A_Index - 1) * 8, "Double")
    }
    ready := true
}

KittyShapeScore(m, kn, z) {
	global KittyTplF, KittyTplFBuf
	if (!kn.HasKey("TpCnt"))
		SwTplPrep(m, kn)
	n := kn.TpCnt
	if (n < 16)
		return -9
	sa := kn.TpSumA
	saa := kn.TpSumAA
	best := -9
	if (kn.HasKey("TpPV"))
		{
		VarSetCapacity(sums, 216, 0)
		DllCall(SwTplSumFn(), "Ptr", kn.TpPV, "Ptr", kn.TpPO, "Int", n, "Ptr", &KittyTplFBuf + z * 2048, "Ptr", &sums)
		Loop 9
			{
			o := (A_Index - 1) * 24
			sb := NumGet(sums, o, "Double")
			sbb := NumGet(sums, o + 8, "Double")
			sab := NumGet(sums, o + 16, "Double")
			num := sab - sa * sb / n
			den := (saa - sa * sa / n) * (sbb - sb * sb / n)
			if (den <= 0.000001)
				continue
			sc := num / Sqrt(den)
			if (sc > best)
				best := sc
			}
		return best
		}
	cv := kn.TpVals
	base := z * 256 + 1
	Loop 9
		{
		of := kn.TpOffs[A_Index]
		sb := 0
		sbb := 0
		sab := 0
		Loop % n
			{
			vb := KittyTplF[base + of[A_Index]]
			va := cv[A_Index]
			sb := sb + vb
			sbb := sbb + vb * vb
			sab := sab + va * vb
			}
		num := sab - sa * sb / n
		den := (saa - sa * sa / n) * (sbb - sb * sb / n)
		if (den <= 0.000001)
			continue
		sc := num / Sqrt(den)
		if (sc > best)
			best := sc
		}
	return best
}


; Live diagnostics: records game detector state only, not chat, keys, or account data.
KittyDiagTick:
if (!KittyMode()) {
    RfTip19 =
    return
}
KittyDiagReport()
return

KittyDiagReport() {
    global MacroRunning, MacroPaused, MgInPlay, SpecialRod, StellarSkin, SwClickSigns
    global KittyDiagStage, KittyDiagScanN, KittyDiagClickN, KittyDiagFindN, KittyDiagIssuedN, KittyDiagAckN, KittyDiagRetryN
    global SwFound, SwFishX, SwStarFound, SwStarsValid, SwLit, SwLitRaw, SwPhase, SwStop, SwStopWhy
    global SwWantK, SwPressK, SwLockFail, KittyCandidate, KittyConfidence, KittyReason
    global WindowLeft, WindowTop, WindowWidth, WindowHeight, RobloxHwnd, KittyScores, KittyMouseStage, KittyMouseX, KittyMouseY
    global pCaptureBits, CaptureW, CaptureH, pNoteBits, NoteW, NoteH
    global KittyMcState, KittyClickSpeed
    static last := "", lastWrite := 0, lastCapture := 0
    stage := KittyDiagStage ? KittyDiagStage : "ready / not started"
    active := RobloxHwnd ? WinActive("ahk_id " . RobloxHwnd) : 0
    text := "Re:Fisch " . RfVersion . " | SPACE + MOUSE | " . (MacroRunning ? "RUNNING" : "STOPPED")
    text .= "`nStage: " . stage . " | Focus: " . (active ? "Roblox" : "other")
    text .= "`nScan / click-step / match / sent: " . (KittyDiagScanN + 0) . " / " . (KittyDiagClickN + 0) . " / " . (KittyDiagFindN + 0) . " / " . (KittyDiagIssuedN + 0)
    text .= "`nBar: " . (SwFound ? "yes" : "no") . "  Fish: " . Round(SwFishX) . "  Stars: " . (SwStarsValid ? "valid" : "missing") . "  Lit: " . SwLit
    text .= "`nConfirmed: " . (KittyDiagAckN + 0) . " | Retries: " . (KittyDiagRetryN + 0)
    text .= "`nSigns: " . (SwClickSigns ? "ON" : "OFF") . " | " . KittyReason
    ; Diagnostics are written to disk only; no on-screen status box.
    state := stage . " | running=" . MacroRunning . " paused=" . MacroPaused . " play=" . MgInPlay . " focus=" . active
    state .= " | rod=" . SpecialRod . " skin=" . StellarSkin . " signs=" . SwClickSigns
    state .= " | client=" . WindowWidth . "x" . WindowHeight . " origin=" . WindowLeft . "," . WindowTop
    state .= " | scans=" . (KittyDiagScanN + 0) . " clickSteps=" . (KittyDiagClickN + 0) . " matchCalls=" . (KittyDiagFindN + 0) . " sent=" . (KittyDiagIssuedN + 0)
    state .= " | bar=" . SwFound . " fish=" . SwFishX . " starFound=" . SwStarFound . " starValid=" . SwStarsValid . " lit=" . SwLit . " raw=" . SwLitRaw . " phase=" . SwPhase
    state .= " | stop=" . SwStop . ":" . SwStopWhy . " lock=" . SwLockFail . " queued=" . SwWantK . " pressed=" . SwPressK
    state .= " | candidate=" . KittyCandidate . " score=" . Round(KittyConfidence, 3) . " reason=" . KittyReason
    state .= " | confirmed=" . (KittyDiagAckN + 0) . " retries=" . (KittyDiagRetryN + 0)
    state .= " | glyphScores=" . KittyScores . " mouseStage=" . KittyMouseStage . " mouseXY=" . KittyMouseX . "," . KittyMouseY
    state .= " | kernels=" . (KittyMcState = 1 ? "on" : "off") . " speed=" . KittyClickSpeed
    ; Sample at 2 Hz, buffered by the OS; do not write on every steering frame.
    if ((state != last and A_TickCount - lastWrite >= 2000) or A_TickCount - lastWrite >= 4000) {
        line := A_Now . " tick=" . A_TickCount . " | " . state . "`r`n"
        FileAppend, %line%, %A_ScriptDir%\KittyKeys_diagnostic.log, UTF-8
        last := state, lastWrite := A_TickCount
    }

}

KittyDiagBitmap(path, ptr, w, h) {
    if (!ptr or w < 1 or h < 1 or w > 8192 or h > 4096)
        return false
    ; Both existing capture buffers are top-down BGRA DIB sections.
    bytes := w * h * 4
    VarSetCapacity(header, 54, 0)
    NumPut(0x4D42, header, 0, "UShort")
    NumPut(54 + bytes, header, 2, "UInt")
    NumPut(54, header, 10, "UInt")
    NumPut(40, header, 14, "UInt")
    NumPut(w, header, 18, "Int")
    NumPut(-h, header, 22, "Int")
    NumPut(1, header, 26, "UShort")
    NumPut(32, header, 28, "UShort")
    NumPut(bytes, header, 34, "UInt")
    f := FileOpen(path, "w")
    if (!IsObject(f))
        return false
    a := f.RawWrite(&header, 54)
    b := f.RawWrite(ptr + 0, bytes)
    f.Close()
    return (a = 54 and b = bytes)
}

KittyMedian4(a, b, c, d) {
    return (a + b + c + d - Min(Min(a, b), Min(c, d)) - Max(Max(a, b), Max(c, d))) / 2.0
}

; Require fresh observations of the same glyph at a settled size and position.
KittyTargetSettled(k, point, now) {
    global SwLit, SwSB, SwFastClicks, KittyGeneration, KittyReason
    static slot := 0, z := -1, generation := -1, anchor := "", since := 0, frame := 0, reads := 0
    if (!IsObject(point)) {
        slot := 0, z := -1, anchor := "", reads := 0
        return false
    }
    changed := (slot != k or z != SwLit or generation != KittyGeneration or !IsObject(anchor))
    if (!changed) {
        positionTol := Max(2, 4 * SwSB)
        changed := (Abs(point.x - anchor.x) > positionTol or Abs(point.y - anchor.y) > positionTol
            or Abs(point.w - anchor.w) > Max(2, anchor.w * 0.06)
            or Abs(point.h - anchor.h) > Max(2, anchor.h * 0.06))
    }
    if (changed) {
        slot := k, z := SwLit, generation := KittyGeneration
        anchor := {x:point.x, y:point.y, w:point.w, h:point.h}
        since := now, frame := point.seen, reads := 1
        ; New target, but its glyph may already have been watched holding still this set.
        if (KittyHistSettled(k, point, now)) {
            KittyReason := "settled " . SwZodiac(z) . " (already tracked)"
            return true
        }
        KittyReason := "waiting for " . SwZodiac(z) . " to settle"
        return false
    }
    if (point.seen > frame) {
        reads++
        frame := point.seen
    }
    minimum := SwFastClicks ? 0.025 : 0.06
    if (reads < 2 or now - since < minimum) {
        if (KittyHistSettled(k, point, now))
            return true
        KittyReason := "confirming stable " . SwZodiac(z)
        return false
    }
    return true
}

KittyRecheckTarget(k, z) {
    global KittyGlyphCenters, KittyConfidence, KittyShapeMin, KittyReason
    old := KittyGlyphCenters[k]
    if (!IsObject(old))
        return false
    ; Refresh the accepted crop from the latest capture, centered on its measured glyph.
    KittyMask(k, m, kn, old.cropX - SwSlotX(k))
    if (!IsObject(m)) {
        KittyReason := "target disappeared before mouse move"
        return false
    }
    sc := KittyShapeScore(m, kn, z)
    minimum := Max(0.55, Min(0.95, KittyShapeMin / 100.0))
    fresh := KittyGlyphCenters[k]
    if (sc < minimum or Abs(fresh.x - old.x) > 4 or Abs(fresh.y - old.y) > 4
        or Abs(fresh.w - old.w) > Max(2, old.w * 0.08)
        or Abs(fresh.h - old.h) > Max(2, old.h * 0.08)) {
        KittyReason := "target changed; reacquiring before click"
        return false
    }
    KittyConfidence := Min(KittyConfidence, sc)
    return true
}

KittyPressEligible() {
    global SwFound, SwFoundT, SwStarOkT, SwStarsValid, SwPhase, SwClickSigns
    global SwLit, SwLitRaw, SwFrameT, KittyMouseZ, KittyRefreshUntil
    global KittyGeneration, KittyMouseGeneration, KittyMouseValidatedAt
    now := SwNow()
    lease := (KittyMouseValidatedAt > 0 and now - KittyMouseValidatedAt <= 0.35)
    sameTarget := (KittyMouseGeneration = KittyGeneration and SwLit = KittyMouseZ and SwLitRaw = KittyMouseZ)
    barRecent := SwFound or (SwFoundT > 0 and now - SwFoundT <= 0.25)
    starsRecent := SwStarsValid or (SwStarOkT > 0 and now - SwStarOkT <= 0.18)
    return (lease and sameTarget and barRecent and starsRecent and SwPhase and SwClickSigns
        and SwFrameT > 0 and now - SwFrameT <= 0.25 and now >= KittyRefreshUntil)
}

; Use the fresh pre-hover matched point; hover highlighting must not reject its own click.
KittyAimForPress() {
    global KittyMouseX, KittyMouseY, KittyMouseAimW, KittyMouseAimH
    ; Eligibility checks the generation, zodiac, capture age and short target lease.
    if (!KittyPressEligible())
        return false
    VarSetCapacity(pos, 8, 0)
    if (!DllCall("GetCursorPos", "Ptr", &pos))
        return false
    dx := Abs(NumGet(pos, 0, "Int") - KittyMouseX)
    dy := Abs(NumGet(pos, 4, "Int") - KittyMouseY)
    if (dx > Max(16, KittyMouseAimW * 0.65) or dy > Max(16, KittyMouseAimH * 0.65))
        return false
    DllCall("SetCursorPos", "Int", KittyMouseX, "Int", KittyMouseY)
    return true
}

KittyQuickMatch(k, z, ByRef confidence) {
    global KittyShapeMin, KittyShapeMargin, KittyMatchMargin, KittyGlyphCenters
    old := KittyGlyphCenters[k]
    offset := IsObject(old) ? old.cropX - SwSlotX(k) : 0
    KittyMask(k, m, kn, offset)
    if (!IsObject(m))
        return false
    confidence := KittyShapeScore(m, kn, z)
    minimum := Max(0.55, Min(0.95, KittyShapeMin / 100.0))
    if (confidence < minimum)
        return false
    other := -9
    Loop, 12 {
        if (A_Index - 1 != z)
            other := Max(other, KittyShapeScore(m, kn, A_Index - 1))
    }
    KittyMatchMargin := confidence - other
    return (KittyMatchMargin >= Max(0.10, Min(0.5, KittyShapeMargin / 100.0)))
}

; Discover newly constructed controls once per page, rather than every animation frame.
; Restyle the macro's existing hint windows without replacing input/click behaviour.
ReFishThemeTips:
staticTipsPid := DllCall("GetCurrentProcessId")
WinGet, tipList, List, ahk_class tooltips_class32 ahk_pid %staticTipsPid%
Loop, %tipList%
{
    th := tipList%A_Index%
    if (!ReFishTipSeen.HasKey(th)) {
        DllCall("uxtheme\SetWindowTheme", "Ptr", th, "Str", "", "Str", "")
        SendMessage, 0x413, 0x1D1A1A, 0, , ahk_id %th%
        SendMessage, 0x414, 0xEDEDED, 0, , ahk_id %th%
        ReFishTipSeen[th] := true
    }
}
return

; Flush buffered input diagnostics. Keep this helper and its timer together.
ReFishFlushLog() {
    global KittyLogBuffer
    if (KittyLogBuffer = "")
        return
    chunk := KittyLogBuffer
    KittyLogBuffer := ""
    FileAppend, %chunk%, %A_ScriptDir%\KittyKeys_diagnostic.log, UTF-8
}

ReFishLogTimer:
ReFishFlushLog()
return

; Re:Fisch logo (multi-size .ico, 16-256 px), base64. Generated; do not hand-edit.
ReFishLogoB64() {
    b := ""
    b .= "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"
    b .= "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"
    b .= "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"
    b .= "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"
    b .= "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"
    b .= "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"
    b .= "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"
    b .= "mbH5QgGiiiiuVgvdtBrgqDG1a/CVzEQyVGarQLTLBnz21HGe39XNjkKJsUuM9DWdt3K6Q2Aqr13Sn72UEnKvSt4YjtSrfPj40aRegMWxcjOTrLCvDsVDtfPnZ5jzy+q/89hjdQNDSV57djNwzVFxdx59nOE4ImuEZBOQXtJj0tbsCz2m9cVn/u8qmhayKHcdfZzTjQZZs2gYQAtiEBjeMzBQuSgK2JU4zBjkiR5jZ30lY9OhOlCt8h+OPI6kat0vuKW1ULKW9x87wo/HRheN3U/rGbTbWoyRJwG/O6G5XpABtrMzFXh9pM9aTIqumeVegZ4g4AejQ/zHo4+TNYYgVbnzfZqM2GMtH37yKF8+c4reICBm8WxcFtBlNkBUH0n+dqe5iA+wtxklva/XWHIi4uZgvlUM9AUhXx88i1N4f/8mMumixWCeMLZLsX7OJJL/56dP0huEi8rjVyArhj5jcXBfOzDQA4yZ+KdZbxvLjM2ccJGGiMy2PEZAb2D51uAZBuOI/9K/mTVhhuE0OTNXfKCaLIbqspayc9xx+ADfHDxLbxi0opYsEvUfASttYLPgarH7h1TI/fn5mcnyr4D8bGRkeGfv8lvLqmsPR3WfETE6Ryo3bwyPV6t8b2SQK3J5tueLxCiR145M/phO6q0IfTbkgfI4tx86wP8dHaF3EWJ9A9TV++dk86Y/zP7y408eev8kGk8dCt7NTguoR7+xKcwSIurnuH+wKwg4FUW84+B+3nfsEGXnWBYErbIt7bCabGbxEkIrf3LiCW577GH2VytJlm8RBniSYhXxmzNZRPQbiQO407aRC0hURCXWL/cYE60JQzvX2y5d2kWUNYYvnD7Bv3j0If5y4CSRenqDgFASosXq8a0tQu3/51Gcepx6AkkIL8DXBgd466P7+JMTT0CKUBYj8VsbToPQ9hnrap4vXUj9TzlTczeYu8G/d/3mbz0W11/7jbFhVxBj5wOe2TQLWPOOK3MFbl12Ga/oXcaGbBabTuSM0lXy0wGHZiAoI0ImxfHH63X2jg7ztcEBflEuExohbxZ3fN8AFfXutaVesy3Mfu9DTxx8RZOmbeUC9qWMUfV85Iog+9pVNpSzs7mVYxptEKba4GijzkeOH+ULp09yQ6nEi7t72FHsYm0mS8kELcRw/vB5SUPCDqXiHEfrdR6qjPOTsRHuHRvjZNQgFKE7CFrp3sV6EudPucwGbA6zEikfmUzTtjTAZC3wnvUbv3s4jl/+tbEhlxdjdZ6/nEnVWzPr120D1maybMhmWZ9Navq7bUAu3dDZ8MqoixmIGzxZr3O0XudYo85wnKD5fLp9xLN4izrOv6Oq9+7Xu3rtliDz4w8fe/yWqaT/otnAlhaI3Xv7bXjvpiDDoaihORHx8+jYNDtxS0GAkKxzOVir8ki13FrKMHk2dyuZlc4kClL13x1YIJn/H+szgfTJvdRUtT/MsDnMaM27Oy4m/U+BgecxgO4C+4XxkeM3l3p6N2RzL/plveo8LIjttxNZyoSoWWvJmeTJGkNGEsnOWUPOGHI2IGtsaiZkzlbizqXk+2Saunt9V19gVT/ziSePfHYX2D0XsWrTOfeyCwzr1mX6Ce89GDWu+eb4sMvNsylYOhdz/HrstjD36OH62A0MDFT3cHHrNp0w63bQPceOVUcb0ZuuzGQrN+VLUlHvzdKdLyjil9X7G3NFuSrM1Udc/KY9AwPj29vow562S2sv6FfA/lF59OSOru5HtmRy/7zsnT8WR5KV2Q8RL522JF+vyeT1FcVuW3Hurf/jxNF7doH9NNMnVttq09sDuhuCj4yN/PK5XT0nr87mbx33zh+LIjIii7gkcnHbfAEq3us12bx/TanHVtS965PHj/zpbgg+3SaabXuY7d4klxx8eGz43ud29Zy8Kpu/VVE5FDWcAWMWyWTMZ4bUJzGNmnr3/HzJvKLYbcrevfuTTx7+77shuJv2M9YzmmZ8LhP07tuSyb52eRBmDzXqcV3VBCIsaYPZj4PUksaW+FdLPcGNuUJtnPi3P/Xkkc/PlPgzZoDzmOChbaXub28IMy+8KptfM+RiPe1iL2CCJaMwK4SPVamjrj/M8vruZXZ9GO4bifT1nzlx5DuXQvxLYoDJTPDxsZHjhXzmL9fbTHFrLn/TqiA0Z1zsh53zCmJFZAktPD2iQxL5rKu6ZUHIy0s99kWFkuREPvVgefi3/urMiccvlfhPe8Ha5BDjO9b2v7DL2Lvr8MrHozoPVMuciKM4Rk2AtJhBOr7d75lF9Ga006lqjKpF/JogDHbkC2wJs2RFvj8e6+5Pnjj0I0jqOPc8jfRFJ3S17ALTfIk/WNf/6qwE76qr/9Uh7+zBRp0jjTpnXezq6jUd+CmGJfRwbog7aW4U0KwYWWYD2x9m2JzN0Wesz4nc03D6yY8dP/TNSYR/2imMjtFgN5i70i8A8K7LN+7IG/MbqP5aTf11NbBDLmYwjhnxjor3NNQv2qbKTkp9RgwFY+gxluVBQJ8JyAouL+YXAv+76t2eTxw/cn/KLHIXyN105uo6LoS7wG4HnfyCt6/pvyo0wQtEeJ6qXuXQdV7p81BQ1D7LecBbpGKFIYMcE9iPcl/Vu59+4uSRhycL2D6QPR3OVs+aFk7rz81UzsmbV60qFozJ51zOlp+llC8CNVtzQ3Fc2zMwMD7FPQaA75TEzxkDXIgZYCewd9a+zGI/yT3tNGl5vr+b2U9azpcfJktI4IJEWLqSpbN0ls4cnv8P6Ouo4v4USqwAAAAASUVORK5CYIKJUE5HDQoaCgAAAA1JSERSAAABAAAAAQAIBgAAAFxyqGYAAERVSURBVHja7b15nF1Xdef7XXufO9eoyZoH25Jt2bENNhgziYYMJNDpgRZ5yctLh05CD5BOMzUJoSMrCc2Y8HgE8pJ+r5NOOp0EN+kMDUngkUaAIQmTDbYkW7M1WdZQ8x3P3uv9cc69ulUqSaWqulc17PX5HBk03Kq6d6+112+t3/otCBYsWLBgwYIFCxYsWLBgwYIFCxYsWLBgwYIFCxYs2BIzWe4/t4YzEBzgsmkIAEvEFOQRkLvZLU/tel7u3rdGn+JR3Zt8yMHvg01re8BMPTOPgMoSPTOyFD+4R/btc9f6wH7rgQcyZ86cyQxns9m4UbBZY0JAWIZW9156o7LPNRo1Bgfjvfv316/lK3t27bJtF4kPAWABOD27dpnpHH7Pli0Djahwa4zc7vHbRdnilQ0qrBa0D6SgSgFRG1xh+Zoi3igVRCuqjCJywcJpRU8YzCEjHMrVzLG9p/ZfuiIgsMvCPr+Yg4EsytR+1y67d98+157K//vbv2ejuPpDKrzMwYPADoFbMsZgRRBNflhFUb38auHqDzWA1q8CgiQYUcCp0lBFVS+APiPIt0TMV7KOv33f8QMnJl04u3ZF7Ft8wUAW022/n93yKI+65u/9wq133uNEX6vID3rVBzPG9EUiiCpeFafgUFdT1RpKVVVqQA2VWJUYxAcfWPYBIAMaiZBFyIPmRDSPkBWRCLFWwIigCA6l5v2EgW9GIn9ljPvL/3jo0OPN19sNFuBRcCEAzIPtBrsTWpjrXXfcsd7E8k+88kaPvixvrZUkShOrurKqjqiXIVUzpF5G1VNGqavSAHy49YNdwxkMQgTkRCgi9IowKEYHxfgBMVoQkUjENgNC1Tu18LfGyKes2k+/78hTJ5uZ6hvBLPRAIAsa3wNNx//5HXe/SOP4Zxz806wxKwVQr9RV4yH1ck6deU6dDHlPGXCpmxsEQ/JiEs54sJnBTHzrSc6RBQoIg8Zwi1hdK9YPGqNZJDImCQZ1dSMCf2pU/58PHn3mK4shEMhCxPjtb9i7b7vjVQrvcPC6vFhR9cSqbkg9J70zp72TS+ppoAhgESzLvLkbrCPO4YEYxQNZhEExbDCWjcb6lWI0ErEiQl0VQT9nRT7y/sMHPz/dhRYCwDT2KXbbN6YY/+e33/WQd/69KvL6jAjqlar6+Ix6e9jHcs476mgrZZPg7MG66DBKckM5lAzCGrHcZq1uFOsLYowYkRhFVD+PMb/6wUMHvpQEgl3RXiYXsJd9ANgDpknQec/27Ru8Rnuc6r/IiFjvvVZV/VHv7DO+wSX1aeEmSe01OH2wBRAMmpnBoBhuNxG3mcgVRUSMMbEqRvh9EffIBw4dOtp25m96NmBvfpFvt/0k+xOcf+td/8ohf2RFXimK1Lz3T3tnvurq5rCPaaSpl03f+uD4wRaKWYQIoQKcVMez6owH6UdcBsSKvS9W+YlXrlxVe82lC3+/F/wedkX7OOGXawYgnwLzRnDvuvWu7cboxw3yA5pU9OMT3kVPuAYX1JFpw/XB6YMt9KxAgDjNCgbFcK/NsM1ETkSsFSFW/yWn8pZfO3rwyd1gH00yAV02GcAeMPtAHwV99+07flyRPzEi9+B9PKwqX3N1+7irUwNySErgCRaMRdNFMClMrQDHfMxFVTMoRvPgjDHbQH/iFStWX/ztoQvfaPeJJZ8BpBHP7dm5M1up6q8bw1u8Kqi6p31svx3XqaLkQpofbAnVCeppsfB+m+Eum3GCWGsEp/q7hXLpLXvPfrPc9I1ufn+GLlf5HwX372+/fWOt5j8fGd6i3ruK9/q/4pr9alzDpbd+KO4FWyrZgJLUrhT4O1fnC3HVjqtX9T6OxPxktTix7523337bo+D27NoVLckMIG1/xG+//a4XZJRPi7AN5+Mz6qPHXI0x9S3HDxZsqZoBaihFER62OTaLjbEmUtUzDfU/8utHn/lK01eWTA2g+QO9c9td32tFPyOwTlTjAxpHX45rxG0RMliwpZ4RRAgN4KiPsWLMLSJORfqNyI++ZOXK77z/0jcP7tm1K9p3ovMdAts1579tx2uNyJ+h9KDqvu7q0TddfVI/P1iw5ZQJGIRnfUwVzAaxTpCsQd748MDKp97/+Def6kYQsF1zfjV/ppBTVf9YXLP7fYN8wPrBlnEmABABZ9Uxot5sMpEXxBiR3a0g0GGugO045r91x2ss5s8VsqqqX45r5rBvUAgpf7BgkMLf8+oZUi9bTKQiIkbkDS/tX/nEfxz+5oFOBgHpZKvv3Vu334ex+xT6var/Ulwzx9KbP8zhBws2GRJUUDabiFdFeR+JiEDV4b/vI0efeaxTLULTCZLPo+DetemO9WrsnwL9qLqvxjVzNDh/sGDTmicZN37Wx3w5rhpV9QoFo+ZP3rkpbRF2wF/nGwLIGjC7d+7MNFT/woq5V1Tjr7t6tD9N+4PzBwt29bpAEw7UVM1mY50xpldFdj28ecPvZ8+di/ct5AxgD7vso+Amqu6jGbEvx/t4v4+j77p6uPmDBZthJpBHOOAbfMc1LN7HGWPuk9Hqb6UDRHZBZgC7wX6SE+5dt975oxmxH1Dv4jPqoy/FFTJBiydYx67NKaVkWRpnLUI4rTErxJp+JI5sdP9Dg4PPv3/oW3+fMGr364IpAjbn+X9x846t9ch8W6C34j2fjSumrIoNrb5g8+TsOtsDvsgCg5BU/LLAD2WK2ifiVaSOyIs+dOTAU/OlJzAvEGB/qrhds/KfIpF+VPVrrmZG1QfnDzZ3p28+c+DiN19jMdUDLEln4GtxTTxgRAre+f/85gceyOy/PHl8cwNAsz3xrq13vjlj7GvU+/igj+1xHwduf7A5+P3snX4mr8siCAZKMhh3SmOeTOoBLmvti/sujr0t6QrMvR5g55r6fwJ0YsvOtRj/aYH8iKp8Ka6KCbg/WIdSfEFbVNqm4nP7I83agFwf6coChwfN2YHn1LHBRFJAVIWXvrJvxR+/b+Rbl+aqI2DmmvoLqEr8vqyxK1HVb7q6qaUfULBg8+P8ipDUkgzgvFJxntE4ZiSOGW57RuOYsnPEqhhNpLrMNZQldLpC4oKsByjfcHVxqGaM7WkY+yFA97NbbkoRsJX633bnC1H9O6uYoz42/6tRIScGj6ZaPsGCXcXh0y1OrVQ//f+IJOtbNElRBah4T9V7MiKszmRYm82yPpNjMLKUjEUEKl4Zjhucrdc526jzfKNB1XuyxlAwJgke6dovQdIsQVBNJOVFpPU9LaSsQFP166oqr8jkuMNknBexanjVhw8f3Neups0NdxtmaTvT4Om8+9WcsVHVO/dEXE8m+9KIGnbwBJtRgW9qFqA+SeUVxr1HVdmeL/CKvn4e6u3jzkKRFVFEwViMtO/3S9bB1dQzHMccq1X5+7FRvjg6zP5KmYZXeqzFIjh88m9aZ5VWIFiIWYFHiYDvxHU2ZS1FsdRj9z7gFU/xqHY1A2je/u+8dcfLQL5iVf1+1zBfa9TISyD8BJtL2q9ECGXncXge7unjf1u9hpf19rMiinBAzXvidP/jdCffiBCJkEv/O+493x4f448vnOfzI0M0VOm1Foem62QWR01AUjGRB6Ic99uMVzHG4X/o144+85ezzQKiudz+6nlP1gpl9brfNYiC8webg/MLiigMuZi7C0X+7boNvLp/gIwYJpxjqBG3UvXmHr+rAftYlQYe1SQgPNzTx8t6+/n6+BgfO3uKr4yN0GsjjCi+7XUUFhwEmFoQfDpusN1E2mvAqb4H+MvdPOq70gVIGH/4d99++wsU80GjyNOuYQ67mKwEzB9sds5vUJyHqnp+as1aPrz1Vu4ulhhPsb+IYERazj8zee7036RZQ9V7tuby/PDgSlZEEV8bG6OunqyYFK7Kgs8EDFBGyYkx68R4xG55Wf/AF79/+NLx3WD332BHwMwKAACN2L4lK8ZWUXcovf2DBZuN81uUulcyAr++5Tb2bNyKQRiOYwxg5+FsGRGsCGPOUVXlZ9as53dvv4N1mRwTzhFNEZ9fqN0BJZEbP+IalFV9RsBh3ppk5nu00zUAAfQXtm27pUbmYE5k4LBr6BcbVQmafsFmSsSZ5JgKdfX0Wssnt23nxT19XIwbWOlsDylWZSCKOFmr8q+OHuJQtUKPtcSLIBMQoKbKyzN5vTPK0FCt4rj715595tiNUoTNjU77AcRk3pAzdiBWdUdcHK7+YLN0fiVWT9EYfnPbdh7s6eFiXCcS2sTiOvNEAsNxg3XZLP/pth1szSWZgNXFsVnaCBzxDYlVXc7YgrHyo8mf7DIdgwCPJFtNcao/JqgOqec5n6zuCrd/sBua2ktRd6zKh7bcyoM9vVyK41lBydnqSkYijDvH2kyGj229nT5raSSrva/zvS+MYuB57znvnSEJpD+ya1dr8/D8B4A9SdDRd9y+cyciD6lXTjpn66qB7hNsxiKY7a2+Ued469r1fN/AIJfiBpkZOr8mlxAurSeYtoPc/vszDQKjznF3scgvbdxCVTXtLuiCzgIk3T34rHfGq6o15nsePPH8A4DuvoHi/g1kAGlqETdelzc2qqPulI+xwfuD3eDtb0lu3pf09PLmW9YxfAM3v1PFijAQRQxEERkRGqo00rHz/rbfn2kgiEQYimP+0YqV7F6xipE4TouCV4cvLJCNxGe8o4Z3WTEC7ocBdrJLOsAD2OcBVOQHBWVIvVxSjw3pf7AbvP29QkaEd6zfSCRCxfvrVvp9elsNRhHnGw0+P3yJvx0b41i1wqhzKNBjLRuzOR7s6eVVff1syuUYb84FXOf1jQhl73nr2vV8aWwkCUpGWKj5bXNceFg9F72XTUbxwg/sgf9wIzDA3oDgh3/P5jvXNYx/v0VyR1wsJ10sof0X7EZv/1Hn+OEVK3nTmrWMOndd53eq5I3BiPC7zz/HL508wacunuepSpnn4waj3jHiHOcadQ5WyvzN6DB/NTzEUNzg3lIPvdZS8/6aQUCAuirrslnK3rNvdISisZPK6QutIyBAA6VkjKwXKzGsYuUtf/iVofMznhKcUQZwN7sFHqUW8XBWbG/svX/OOwOKahD8CDbzvr9TpSDC/75yTVpwu37KX7KWc/U6P3/iKF8aG6FkLL3WtvXrL5fGmyoZIy7m/3ruNP/fyBDv33Ir9xV7GHXxNYONTWnD/2TFSv7b+XMMuxgr"
    b .= "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"
    b .= "953l/xeN4XB5IuD/UAOYff9/ZZRhR6HYUYZdM9Ccb9Q5VKkkasNTA871vrYIDigYg+ngVt35kDHrXv8/4f+PLxJ2ZAgAC7D/f1s+33H9PyWZ6DtUqXAhbiQZQIc0BBZG/7+3K1/LozwxMRa6/yEAzI3/n+9wOt3s/z+R4v8rxWqXxhFu9f+LReraJf5/wP8hACx8/J9IY32nPH51/L/IM6rm/r9NuRybUhHTTuL/nDEcD/3/EABmjf816f93A/9nRXg+Tvj/2enw/xLJqOrp/P90Y82dwP9PlScYD/3/0AWYFf73yv3FRP+/pp3cVpP0/w9VKpxvNCgYm075Lb3bSoD7ir2TBU06KJb6+MRY4P+HADAH/n+xRN4IlYZP+v8dOEvqFWtJ8b9SXKLitJf7/4W29L8zP6gVYThuBP5/CABz5P+XenBeO7psQ0Souyb+lyWL/6vq2Z4vsDnbtsREO9X/Fw5XqpyuBfwfagCzvK16rGVzNk9DO93/Xyb43ys7C8Uu4X/hqfIEE6H/HwLArBaAqmdtlOGWTKYL/X/hcLXC+UadzBK/rbqh/9fMAh6fGF+Mm9KXIATQpNyzsDcDaeubEhEazrM+m6VkbTJFhnSw/2/4zsQ4Ne8pGLt0hlXafo5YlV5j2FkodXyF2eX5/wmyAt63lVQlRITpJiZpfyohA8ABm3P55EbWzvL/G1fj/8vS2KiUzP9f7v93Uq2o2f9/tlblVG0a/f/QEQgQYKYHeH0219EDo0BODKfqNQ6UJxK1oSWN/0v0dYn//2TA/yEAzMUswqoo01GH9KrkTEJWOd9okDFmmlxkSSxV7jL+V56YmGb/X4gFoQ04U8fMiLAik0mq1dIZ2KjpmTxWrS7Jm5+rzP9LBycVbYr/94f+f8gA5tSaM4aSbSrySker1c/WqgtizXhnNipP5v/XusD/P1GrcrpWvbL/H1KAEACud2aljZtfEIt2UATUiNBQ5XyjceX8/hI5qy39/y7i/6fC/H8IAHM9SJFIkkJ2MDVv3o7j3mEXwSrvueD/+7qI/5v9/3D5hwAwJyxpoSsrwJubhpYiWr08/9+d/v9Iqv8f5v9DAFg8RIyliKWaGY56NmVzbO5C/z+b9v9P12tXMipDChACwI11ApKn02urDBAhHa013FT875WdxRK96fqyTr2P6pOVak+VJxh3nVNuDrYcpgHThZuxeqSDd7RP09a8laWTBUyH/4uljo7+Xp6q8Dwe+v8hA5iP3nxDfarNJx09slkRBm2UVselo2PHXeH+6+X/7bxP+P/FUsffy0iEERdzoDyRbFRWXdzv5U0jwXcgA2jdoQt6GOhyFV7S3XXjziHpTW06BDOsCOsyWZwqwlLYWqMtaFPznlvzBTblcq3+v3YokyoYw5HyBCfr1StXqoksnQ5Lh4aBlMt+Kcu9BpD0rj3DLsYiHXfKLfn8ktX/21ks0WejLun/lRl3of8fIADz0b6Ci40GRjovO3Z7vkjeyOJvW03RVEz6/6WuQHBN9f9vZJNSsBAArplWnmvUO0rRbS4euT1fYF0mR0N1ybypyaJTYWuuQNyF/v9oyv/PGROWf4YAMD8/3KlareNMwNh7VkQZ7i31XCk9vkgPcrOGsimbY3u+kAwAdbz/X+NUqv/vg2+GADDXTNaKcKpeo9phTrmmWerL+/qXTPpvRah6x0O9/azKZGl0cACopf9XCf3/EADmEU9mRDhTrzEUx4lSbwcLjmXvebi3n81ptdxcxbEW0yxFTgzfOzCYcik6X8l+PN3/F9R/QwCYmz5XeogiES7F8fRrpeZbgNR7bslk+b6BFZQX4xabKbd/2Sf7FF9Y6u24Kk8kwqhL9v9ljQT8HwLA/N3MFe85WCmnWv3a0W5AxTv+0YrVrIgSERJZpFmApAKg/2zlmo4vVG3H/yfrif5fwP8hAMzrYX5iYgzX4ZEAASres71Q4IdXrGLcJbCDxRAE2m9/hLJz3Ffq4fsGBhlzrqVz0Imnqdz0ZMr/D/3/EAA6otc3HMdEYrqScfzz1WtZl811dHKuU31/kWQe/1/esp6C6az4R7t9Z9r5/xAMQgCYh429p+p1ni5PkBfp6HSgKNScZ0M2x7++ZcP0tYCFlAVM+V6aWvyvG1zFq/oHGY0TFmXHpv80Wd1+od7g2+NjHYcbweY6DSjtvOMFPp+RHiQRoeocfzc2ykt7+5M6QAdvFivCiHO8YeVqvjI6zF8PX2IwimhMOti6AMbbdNIHaCVJ/Tdns7xt3aaOrlJv7zTkjeVblVFO1qoU2uXGAvf/xmcBNGQAV1UH/urYCOMuxgodFwgQlIZ63rNxC9tyecrOTa4H6E3OBHSy85v0fVJV9mzaxi2ZDDXvkA6/T4oSCXx5dLijRKNgyzEAyOQps4OVCZ6qTFDoQpopJFN0azJZPrj1NvLGUPf+SnmymxIE9IoDYEQYc453bdjMK/r6GXVxV8g4kREuxQ0eGxuhYEzX6g3BlkUGIFOKc8oXhofIXLFmqnNQYNTF3Ffq4YNbbwMgRq90LO0imJrm5jciDDUavHXdBn5izVqG4u44v1elaCzfHB/jWLWa8P+D+EcIAHRI1LJgDP9rZJjnG/Vptvd0VuDy1f2D/NrW2zEINe+naQ92OhvQK16/mY0MxQ3esm4jP7tuIyNdcv72b+szQxemuflDBAgBYB6TAAXy6bKJL44OUzSmo7Pt7VUGK8JQHPOagUE+fut2BqxlzMVkZJoZxeZm1/nKCFrbYie/JZl0zr/mPb+4cSs/t34jo861pv06HIpayz8OV8s8NjZKydqQ/ocA0FkY0NTu+9OL51vDQZ0scbUfeJtSkh/q7ed3t+/kwVIvF+NGK0uQ6cu6swgGbf21aRzKtq3dGrQRH7t1Oz+5Zi3DcXxFhaCT74tPq/9/fukiQ3FjckYUev8hAHSkGKhK0Vq+PTHGV0dH6DHdvXWa8+7rszn+79vv5K1rN+BRxlyMEcHKVVQL2oPBdZ8r44WkH3IkQtV7RuOY1w6s4Pd27GRX/yCX0rRfusnNMIYz9RqfGbpIyYTbPwSALookKvAHF84R01mBC65SGKyqx6ny79Zv4nduv4tX9g1Qdo5xFyOpo5o5omBJn0gEI0JNPcNxg1vzBT6y9XZ+bdt2VmUyjMbT0JXpfPGvZCx/euk8p+pVsqH4R5AF70YM0KQY2GMj/nZslC+PDPMPBlK2WxedwKRBaCiO2Vks8fFbd/Dl0WH+6Pw5vj4+Rtk58saQE2lt4G0Sr6bD5zLJ6aW1najhPRMpt35HocAbVq7m9YOr6I8iRl2MIF2fu2/e/qfrVT514flpbv8QAUIA6GQEaHOg//z8WV7W139Thk+kNXLrAGFX3yCv6BvgOxPj/PXQJb42NsKJWpWaeixCZISI5Da3kxxFW0W1RroDIdaEXLMmk+UFpV5eO7iCh3v76bWWcee6X+lncjem30b85vnTnK7XGEynJoPvhwDQtRjgVemxlm+Mj/E/Lp7nx1avZShu3BSnMOmpH/cxINxb6uGBnl6G4kQb//HyOAfKE5yq1bgQNyh7T9V7fOr6BkmWkhjDLZkM67I5dhQKvKDUy93FEusyORCYcI7h+HKtgZukz1iylgOVCT514Ry9rT0K4fYPAaDLWUCTF/Db586wq3+AQZuhwc2jojYDQdk5lKRN91BvHy/rGyBWZdzFDMcxwy5mzDlq3rcGnYrWMmAjBqKIPhuRNcnAU1U9Yy5udSFuusyWKhHCJ8+eZtQ5eqO2ABB8f2EHgKoxar16TavNi2IY6BoHsek8p2tVfuvsafZuvo3aTcoCpgsEqjAeOxTXggtrMlnWZ3OYpsZxOivjUbwqsULVe8pO07Feab3ezf6gnCoDUcRfXLrA54YvJjsGvG+Ly0JY/TP3YaCmb3pVNcb6OXcBmu7gGo0aUElJJEvik4pV6Y8i/vvF83xh5BJ9UbL4Qju/S3RmAiNpBV9Shdy6KmXvGfMxoy5mNI4ZczET3lFVxaUO1Pw3LJCfw7cKf3U+euYkOZk6ixGu//myjCRFYJRaJNUywCPXiawzawOeXd8QtNJOXNFFrhl4WTkYPnjqBM/X65NbUgsQwEiaJRhpe5AF7UJKIsrykdMnOF2vkTNtkl+B9DPfAUDTs1Kt1Wr1mYRXMxPF69/mmw2UURByiMoSEQ71QN5YTtSqfOD0CfIiLJwcYPE/sXoGo4j/dv45Pjt0gf4oClX/Di7DzaWXswgjq8/vrM4LEWhP+lEpckGAgpglpdvWhAKfHbrA7zx/lsEo6vicAMtkAKvPRnxjbJSPnjlJKVT9O54h5sWoJHswh/ayL1aun6xfNwDsTz8pg5xJhmpEo/T2XApZQPth/djZk/zN8BAD7f3pYMyG7Zc3hvONOu85cZRGymfQkPp3LAOIRCimxDERzgK8cQb+fd2/sJNdyacl/rgCBRFyzS+0hHYINKvw7z1xlKcrE/SGCbU5HUYP/MKJI5yoVxNxUULq32nty4IYTf3yxCTfnUsA+CL70s/NHHYoOTFSMnbpiDe2KQfljGHExbz92CHONeoUw6DK7LCoMfyHE0f56tgo/VesFQ8RYL6Pr0cpiEm2U6PgzSHmaxjoVWm2L8KhRiJmYfrNUlreIK0zGacTg8drVf7d0UOMORekqm5QaKxkLb9y8jh/MXSBgaliqCH171C9BfqNIYuxsSqakacT+L5P5xwAHkk/W9H8UY9etCKywkSqSyqWy6SiYK+NeLI8wc8efYZx77qqj79Y17AL0Gst//Hkcf7wwjkGo8zk9yw4f0f5rStspFZEYvUTxHIogQDMPQCkw2Xy0VP7LwFPC7DSWrVLjbslckVn4FsTY7zlyDMMu5iitQuKKLRQHqeKkSTt/+Vnj/N7559rOX8o+nUn8zLACmvVCIhydMXpw2cA9s6gVj8jItAedtm0SPYNRRi01peMwS01RNd2UBspffWJ8gRvPnyQM/VaQmENmcCk7knOGAzCzx8/wh+03fzB+buXfeWNYaWJvCIg8q294HdzpQj1HARB0kKg8hWHUhIjK4xdms7Qdl7rqvRZy+FqmZ86dIDHJ8ZZMfWAL1NrQqXhOOYtR57mM5cutDgUIUR2d4nroDH0GiMexag+NtMOAMx8GtAnv9iv1bybKIgprYsyeqxRF5bsGEcisdVIFWzONxq8+fAB3rNxK29YuYYxF+PSkdxlN3iCssJm+PbEGL9w4jDHq9Wk4Nc+4NMaRArhoJMBwKmy1mY0I8bWvG9kfPbL6aU9ozq9neH9r4D8/dil0Yd6B16bMWYL4A81akt7r0AbZTgjCeT56+GLDMUxL+ntp2BsS2B0uaT8GWPosZY/vnCOXzhxhEtxTM8kiq+EVl83A7LAg/mirogiiVW/e+bMkQ/sv+yz86cJuCcNFmLkr5pVx5Um+eCX9MctSZvQoVig10T83vmz/PThAxyslFkRZVrOsZRxpksLo+Mu5t3HD7Pn2WPJ1iVrpzh/sK6l/8CgsayxkdcEon/+UXDNmt18i4L69Nf/WfPe5cTYzZnM0isEXoMr4EkCwWCU4cnyBG86tJ/feu4UkUiLOehZWul+rEpeDP024nPDl/jxZ/bzZ5eSwZ5mCtraKx6s6/h/Y5Qlb4ytq4KRP4eZ9f9vCAI0YYCC/ODY8PN/2TvwuqwxGy24pQ0DpicMNVmDHtg3OsTXx8fYmMtxe6GIkBQPRWTRBkZN+fyRMQzYiKPVCr966jifeO4UFe/pmXTrE1L+m3gmX1ws+kEbmbrXA7VbVrz3m2fP6v4bGNWxN/gVo38A/uG+FT3GyGvzInrWxWZo6vbbpV4XSNV4BChay6lajc8MXeBUrcat+QIbczk03RDcFjcWheO7dJtyfxQxHDf4nefPsvfkMb5bnqDXRlgBN6nFF5z/Ztz+DVVuiTI8kC86K2JU9JOfPLj/b/ZAtO8GAkA0CziIkfqjVR/9cl5sz45sTp9NuwHL6iOQZB97nC65VJQ/uXievxkZ4h+tWMWPrLqFbfk8dVUqqdafWaBZgSf5WXLG0GcjzjfqPHrxef7w/DmO1Sr02miaWf7g+De1+g9sz+bIirF172o5NX8wCap3IgPYB7ob7P87Ojrykr7BuyIj9xXFuBNx3VRUbzidWDLZQHp7NtmCfz8+yl8PX+J0vcbqKMP6XJ6CNbg0YDRvT7nJhT2vihGhaCwFazlTr/FHF57n/adP8OeXLlJTT6+NWtJe4dZfGOaAXmN4aaHH5Y0xsfLZj54+9ok9YPbeYACYtSqwqH6ipv7Hi8aYO7N5HqtMkBFZhiSQJBsgdW4BBqIMFe/5g/Pn+LNLF3iop4/XrVjJQ719rIwyOIWqd61BmW5kBk1c39xQVDSGrAhjzvH1sVE+O3yJL44Mcb5RJ28sg1GUio2GW58FtsqrpsqOXIEeY6Shigi/AZe1O2a/N4sZtwTNXvA/u3HrF3LGvnrcOffpsWFbVo9hmTOzdfLyD6fKhE/Ufbfk8ry0t59X9g2ws1hiZSbTKhrWvG+l4qSioDKLD6ml1tzGyLMiZETImYS2NOZcspl3dIR9I8M8U61Q956iNWRS0U4/6YQEx19os///tGfADUSRrTr39ZWnj78EZsb9n5cMoBlprJr3xaqvLhkj9+SSLKCQikEsW3SWciO1LSPotREonKnX+a/nz/GpC8+zIZfjgZ5eXlDq5a5CkY25PD0mSsU0kps3TiSek3R9ilNP9k+ZtATUiqQ7BhONw4rznK3XOViZ4NsTY3xrfJyjtQpl58iKIW8MhVSnP9z4C/v2r6hyX67AgLV4wIh5/17wn2J2CHzWn/DlLGDbF7LGvLrqnfuTsWE74j0RBD54+5T8lKxAVamltz5An7VsyOXYksuzvVBkSy7PumyOVVFEyVoKYomMYBGMXLHmAI/SSF9vwjuG4pjn6nWerVc5UqlwrFrh2XqNobiB0+QGyRmDFZl82wfHX/CFv6IY3tA74ErW2rr333ju1LGX7ATdO0uVvlnXAFpagd6/N4bHcoi8MFfk8xOjRMag2v3tuwsJAlymEuuk1NynWUFGhFxkW0tLD1cqHCiX+ezQRSzJuq8ea+m1lj4b0WMtJWvJi2ktMPEoNa9UvWPMOUadY9TFjDtH2btWBpKRBO/3GNu2UIRJYh3S/otOiVohINzkXTaJL9W956WlEqUUWhrMex8Ft5vZ19/n9MnuBvsouJ/dsPW/ZYz5Uee9++zEqD3RqLd0A4NdT0Pnsua/cHnngk+XfXil9V9legggaWZgEKwkWYZpey1luk1OwakX0+1fV2VdlOEf9vS7jBhb9/Fnf+PMs6+bTeV/3nYD7mwusfHm52P8D1mR3pcUSno2bkhw/pnH3snOqa1um0WI0htY2v6NXBFC9Ir14Y6gw7eUrgorwksKJc2IEKtWsxl5x3x8sHNq3e8D/RTYd44PDT/UN1CxxvxgSYwTxBxr1MmGLGAOO4CSRyc9zXVbmm4I5oo/n/rvg/OzJAp/DxSK3JXNOxGJnPr3fezkif/+KbBvnaNC/3ycDtmdDhWt3bB1X2TMy7x695nxEftso0F+WXcFggWbe+q/Nsrwwz39zopYj39i0PISTpyo72XuO3rno22vO0EfBadef9qpToDIK4u9WjKGGA13ULBgs5L7hpwYdhV7NEpaug0n/qf3njhR3c/8rOicF95OU4PsN86eOOidvs2KmH5j3auKvWnxKliwYDdqDVVeUSyxykROjFjvec8nTp78xqfS4vt8fI15o+/vB90D0YfHh7/xYE/frdaYFwwaGxsJ9YBgwWaD+1+UL3J/vhhjJGp4/6cfP3P853ZB9JF5cv55ywDaMgG3G2xN6/869v7bHqIX5oru3lyeyrKnCQcLNnPnvzOb48X5kvMQxV6fNpG+SUG+OI/OP+8BoFkP+O2zZ8sZ69+gque8YF9R6HG3ZXKUVUMQCBbsOs6/OZPlVcVer4L1ynAcx2/42IkTw48k3WHtkAj2/FmTIPSW9VsetmK+"
    b .= "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"
    return b
}

; Writes the logo next to the script when it is missing or differs in size from this one.
ReFishEnsureIcon(path) {
    b64 := ReFishLogoB64()
    if (!DllCall("Crypt32\CryptStringToBinaryW", "Str", b64, "UInt", 0, "UInt", 1, "Ptr", 0, "UInt*", n, "Ptr", 0, "Ptr", 0))
        return false
    FileGetSize, sz, %path%
    if (!ErrorLevel and sz = n)
        return true
    VarSetCapacity(bin, n, 0)
    if (!DllCall("Crypt32\CryptStringToBinaryW", "Str", b64, "UInt", 0, "UInt", 1, "Ptr", &bin, "UInt*", n, "Ptr", 0, "Ptr", 0))
        return false
    f := FileOpen(path, "w")
    if (!IsObject(f))
        return false
    f.RawWrite(bin, n)
    f.Close()
    return true
}

;====================================================================================================;
;   Settings store: Re-Fisch\settings.ini (global) + Re-Fisch\profiles\<name>.ini (per profile).
;   On first run, profiles and settings from a DeepFish / Re:Fisch fork folder next to this
;   script are copied in, so calibrated colours and tuning carry over.
;====================================================================================================;

EnsureConfigFiles:
if !InStr(FileExist(RfDataDir), "D")
	FileCreateDir, %RfDataDir%
if !InStr(FileExist(ProfilesDir), "D")
	FileCreateDir, %ProfilesDir%
RfImported := ""
if (!FileExist(SettingsFile))
	{
	RfImportOverwrite := 0
	gosub, RfImportFork
	}
if !FileExist(DefaultProfileFile)
	gosub, BuildDefaultProfile
if !FileExist(SettingsFile)
	{
	IniWrite, Default, %SettingsFile%, Profiles, ActiveProfile
	IniWrite, p, %SettingsFile%, Hotkeys, StartStop
	IniWrite, o, %SettingsFile%, Hotkeys, Reload
	IniWrite, m, %SettingsFile%, Hotkeys, Exit
	IniWrite, 0, %SettingsFile%, GUI, AlwaysOnTop
	IniWrite, 0, %SettingsFile%, GUI, KeepOpen
	IniWrite, 1, %SettingsFile%, GUI, AutoSave
	}
return

; Copies fork profiles/settings found next to the script. RfImportOverwrite = 1 replaces files.
RfImportFork:
RfForkDir := ""
for RfImpI, RfImpName in ["Profiles-KittyKeys", "Profiles"]
	{
	if InStr(FileExist(A_ScriptDir . "\" . RfImpName), "D")
		{
		RfForkDir := A_ScriptDir . "\" . RfImpName
		break
		}
	}
if (RfForkDir = "")
	return
RfImpCount := 0
Loop, Files, %RfForkDir%\*.ini
	{
	FileCopy, %A_LoopFileFullPath%, %ProfilesDir%\%A_LoopFileName%, %RfImportOverwrite%
	if (!ErrorLevel)
		RfImpCount++
	}
for RfImpI, RfImpName in ["Settings-KittyKeys.ini", "Settings.ini"]
	{
	if FileExist(A_ScriptDir . "\" . RfImpName)
		{
		FileCopy, % A_ScriptDir . "\" . RfImpName, %SettingsFile%, %RfImportOverwrite%
		break
		}
	}
RfImported := RfForkDir
return

LoadSettingsFile:
IniRead, ActiveProfile, %SettingsFile%, Profiles, ActiveProfile, Default
IniRead, TotemGlobal, %SettingsFile%, Totem, Global, 0
IniRead, StartStopKey, %SettingsFile%, Hotkeys, StartStop, p
IniRead, ReloadKey, %SettingsFile%, Hotkeys, Reload, o
IniRead, ExitKey, %SettingsFile%, Hotkeys, Exit, m
IniRead, GuiAlwaysOnTop, %SettingsFile%, GUI, AlwaysOnTop, 0
if (GuiAlwaysOnTop != 1)
	GuiAlwaysOnTop := 0
IniRead, GuiKeepOpen, %SettingsFile%, GUI, KeepOpen, 0
if (GuiKeepOpen != 1)
	GuiKeepOpen := 0
IniRead, GuiAutoSave, %SettingsFile%, GUI, AutoSave, 1
if (GuiAutoSave != 1)
	GuiAutoSave := 0
IniRead, UpdateAuto, %SettingsFile%, Updates, AutoCheck, 1
if (UpdateAuto != 0)
	UpdateAuto := 1
IniRead, UpdateChannel, %SettingsFile%, Updates, Channel, Stable
if (UpdateChannel != "Test")
	UpdateChannel := "Stable"
IniRead, UpdateSkipped, %SettingsFile%, Updates, Skipped, %A_Space%
RfUtilLoad()
; The old "read this first" lock is replaced by the setup checklist on the Home tab.
ReadThisAccepted := 1
hReadThisLockMsg := 0
; Webhooks and the utilities return with their own panels in a later build; keep them off.
WebhookURL := ""
WebhookOn := 0
WebhookShot := 0
WebhookOnCatch := 0
WebhookOnAlert := 0
WebhookSummaryMin := 10
WebhookStallMin := 10
ActiveProfileFile := ProfilesDir . "\" . ActiveProfile . ".ini"
if !FileExist(ActiveProfileFile)
	{
	ActiveProfile := "Default"
	ActiveProfileFile := DefaultProfileFile
	IniWrite, Default, %SettingsFile%, Profiles, ActiveProfile
	}
return

; Utilities are rebuilt in a later build: force them off after every profile load.
RfUtilitiesOff:
TotemAuto := false
AquariumAuto := false
KeeperAuto := false
return

ReadThisLockedNotice:
return

;====================================================================================================;
;   Re:Fisch drawing. Cards, tabs, buttons and the run chip are drawn with GDI+ into bitmaps and
;   shown in plain bitmap controls: rounded and anti-aliased, and because nothing is clipped to a
;   shape they can't flicker when a tab changes (the old rounded corners clipped every control).
;   Each drawn control keeps its description in RfPaintSpec[hwnd]; RfPaint(hwnd) draws it again
;   after a hover, a state change or a new size.
;
;   A description:  w, h (window units), bg (colour around the shape), r (corner radius),
;   text, icon (a Segoe MDL2 Assets character), pt / ipt (text / icon size), align ("c" or "l"),
;   pad, and looks: {n: normal, h: hover, a: active}, each {fill, edge, fg, ifg, dot}.
;====================================================================================================;

RfGdipStart() {
	static ok := ""
	if (ok != "")
		return ok
	ok := false
	if (!DllCall("LoadLibrary", "Str", "gdiplus", "Ptr"))
		{
		RfDrawNote("Failed: gdiplus.dll did not load")
		return false
		}
	VarSetCapacity(si, 24, 0)
	NumPut(1, si, 0, "UInt")
	tok := 0
	st := DllCall("gdiplus\GdiplusStartup", "UPtr*", tok, "Ptr", &si, "Ptr", 0)
	if (st = 0 and tok)
		ok := true
	else
		RfDrawNote("Failed: GDI+ did not start (" . st . ")")
	return ok
}

; Opaque ARGB from RRGGBB. The hex text goes through a variable first: AutoHotkey v1 reads a
; variable holding "0x..." as a number, but not always a bare concatenation result.
RfArgb(hex) {
	v := "0x" . hex
	v += 0
	return 0xFF000000 | (v & 0xFFFFFF)
}

; What the About tab shows for drawing: "on", or why something failed.
RfDrawNote(msg := "") {
	static note := ""
	if (msg != "" and note = "")
		note := msg
	return (note = "") ? "On  (GDI+)" : note
}

; Colour between a and b (t = 0 gives a, 1 gives b), as RRGGBB.
RfMix(a, b, t) {
	a := "0x" . a, b := "0x" . b
	r := Round(((a >> 16) & 255) + (((b >> 16) & 255) - ((a >> 16) & 255)) * t)
	g := Round(((a >> 8) & 255) + (((b >> 8) & 255) - ((a >> 8) & 255)) * t)
	l := Round((a & 255) + ((b & 255) - (a & 255)) * t)
	return Format("{:02X}{:02X}{:02X}", r, g, l)
}

RfGdipFont(face, pt, style := 0) {
	static fonts := ""
	global DpiF
	if (!IsObject(fonts))
		fonts := {}
	key := face . "|" . pt . "|" . style
	if (fonts.HasKey(key))
		return fonts[key]
	fam := 0, font := 0
	if (DllCall("gdiplus\GdipCreateFontFamilyFromName", "WStr", face, "Ptr", 0, "Ptr*", fam) = 0 and fam)
		DllCall("gdiplus\GdipCreateFont", "Ptr", fam, "Float", pt * DpiF * 4 / 3, "Int", style, "Int", 2, "Ptr*", font)
	fonts[key] := font
	return font
}

; Semibold where the font exists, plain bold otherwise.
RfFontFor(face, pt, style := 0) {
	if (face = "")
		face := "Segoe UI Semibold"
	f := RfGdipFont(face, pt, style + 0)
	if (!f)
		f := RfGdipFont("Segoe UI", pt, (face = "Segoe UI Semibold") ? 1 : style + 0)
	return f
}

RfGdipFmt() {
	static fmt := 0
	if (!fmt)
		{
		typo := 0
		DllCall("gdiplus\GdipStringFormatGetGenericTypographic", "Ptr*", typo)
		DllCall("gdiplus\GdipCloneStringFormat", "Ptr", typo, "Ptr*", fmt)
		DllCall("gdiplus\GdipSetStringFormatFlags", "Ptr", fmt, "Int", 0x1000 | 0x800 | 0x4000)
		DllCall("gdiplus\GdipSetStringFormatLineAlign", "Ptr", fmt, "Int", 1)
		}
	return fmt
}

RfGdipTextW(g, text, font) {
	if (text = "" or !font)
		return 0
	VarSetCapacity(lay, 16, 0), VarSetCapacity(box, 16, 0)
	NumPut(4000.0, lay, 8, "Float"), NumPut(400.0, lay, 12, "Float")
	DllCall("gdiplus\GdipMeasureString", "Ptr", g, "WStr", text, "Int", -1, "Ptr", font, "Ptr", &lay
		, "Ptr", RfGdipFmt(), "Ptr", &box, "Ptr", 0, "Ptr", 0)
	return NumGet(box, 8, "Float")
}

; Width of a text in window units (used to size the tabs before they are created).
RfTextWidth(text, pt, face := "") {
	global DpiF
	if (!RfGdipStart())
		return Ceil(StrLen(text) * pt * 0.8)
	bmp := 0, g := 0
	DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", 8, "Int", 8, "Int", 0, "Int", 0x26200A, "Ptr", 0, "Ptr*", bmp)
	DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", bmp, "Ptr*", g)
	DllCall("gdiplus\GdipSetTextRenderingHint", "Ptr", g, "Int", 4)
	w := RfGdipTextW(g, text, RfFontFor(face, pt))
	DllCall("gdiplus\GdipDeleteGraphics", "Ptr", g)
	DllCall("gdiplus\GdipDisposeImage", "Ptr", bmp)
	return Ceil(w / DpiF)
}

RfGdipRoundPath(x, y, w, h, r, dMin := 0) {
	path := 0
	DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", path)
	d := Max(dMin, Min(r * 2, w, h))
	if (d < 1)
		{
		DllCall("gdiplus\GdipAddPathRectangle", "Ptr", path, "Float", x, "Float", y, "Float", w, "Float", h)
		return path
		}
	DllCall("gdiplus\GdipAddPathArc", "Ptr", path, "Float", x, "Float", y, "Float", d, "Float", d, "Float", 180.0, "Float", 90.0)
	DllCall("gdiplus\GdipAddPathArc", "Ptr", path, "Float", x + w - d, "Float", y, "Float", d, "Float", d, "Float", 270.0, "Float", 90.0)
	DllCall("gdiplus\GdipAddPathArc", "Ptr", path, "Float", x + w - d, "Float", y + h - d, "Float", d, "Float", d, "Float", 0.0, "Float", 90.0)
	DllCall("gdiplus\GdipAddPathArc", "Ptr", path, "Float", x, "Float", y + h - d, "Float", d, "Float", d, "Float", 90.0, "Float", 90.0)
	DllCall("gdiplus\GdipClosePathFigure", "Ptr", path)
	return path
}

RfGdipDraw(g, text, font, color, x, H, dy := 0) {
	global DpiF
	VarSetCapacity(rc, 16, 0)
	NumPut(x, rc, 0, "Float"), NumPut(dy * DpiF, rc, 4, "Float"), NumPut(4000.0, rc, 8, "Float"), NumPut(H, rc, 12, "Float")
	br := 0
	DllCall("gdiplus\GdipCreateSolidFill", "UInt", RfArgb(color), "Ptr*", br)
	DllCall("gdiplus\GdipDrawString", "Ptr", g, "WStr", text, "Int", -1, "Ptr", font, "Ptr", &rc, "Ptr", RfGdipFmt(), "Ptr", br)
	DllCall("gdiplus\GdipDeleteBrush", "Ptr", br)
}

; Dot, icon and text, centred as one group (or from the left edge when align = "l").
RfGdipContent(g, s, lk, W, H) {
	global DpiF
	pt := s.HasKey("pt") ? s.pt : 9
	font := RfFontFor(s.face, pt, s.style)
	icon := s.icon
	ifont := (icon != "") ? RfGdipFont("Segoe MDL2 Assets", s.HasKey("ipt") ? s.ipt : pt + 1) : 0
	if (!ifont)
		icon := ""
	tw := RfGdipTextW(g, s.text, font)
	iw := (icon != "") ? RfGdipTextW(g, icon, ifont) : 0
	dw := (lk.dot != "") ? 8 * DpiF : 0
	gap := (s.HasKey("gap") ? s.gap : 8) * DpiF
	; key cap (s.hint): the key that does the same thing in Roblox, drawn after the text
	kf := (s.hint != "") ? RfGdipFont("Segoe UI", pt * 0.85, 1) : 0
	kpad := pt * DpiF * 0.45
	kw := kf ? RfGdipTextW(g, s.hint, kf) + 2 * kpad : 0
	kgap := gap * 0.75
	Loop, 2
		{
		total := tw
		if (iw)
			total += iw + (tw ? gap : 0)
		if (dw)
			total += dw + (tw ? gap : 0)
		if (kw)
			total += kw + kgap
		if (total <= W - 8 * DpiF)
			break
		if (iw)                  ; too wide: drop the icon first, then the key cap
			iw := 0, icon := ""
		else
			kw := 0
		}
	x := (s.align = "l") ? (s.HasKey("pad") ? s.pad : 12) * DpiF : (W - total) / 2
	if (dw)
		{
		br := 0
		DllCall("gdiplus\GdipCreateSolidFill", "UInt", RfArgb(lk.dot), "Ptr*", br)
		DllCall("gdiplus\GdipFillEllipse", "Ptr", g, "Ptr", br, "Float", x, "Float", (H - dw) / 2, "Float", dw, "Float", dw)
		DllCall("gdiplus\GdipDeleteBrush", "Ptr", br)
		x += dw + gap
		}
	if (iw)
		{
		RfGdipDraw(g, icon, ifont, (lk.ifg != "") ? lk.ifg : lk.fg, x, H, s.HasKey("idy") ? s.idy : 1)
		x += iw + gap
		}
	if (tw)
		{
		RfGdipDraw(g, s.text, font, lk.fg, x, H, s.HasKey("dy") ? s.dy : 0)
		x += tw + kgap
		}
	if (kw)
		{
		kh := Min(H - 10 * DpiF, pt * DpiF * 2.1)
		kc := (lk.fill != "") ? lk.fill : "1A1A1D"
		path := RfGdipRoundPath(x + 0.5, (H - kh) / 2 + 0.5, kw - 1, kh - 1, 4 * DpiF)
		br := 0, pen := 0
		DllCall("gdiplus\GdipCreateSolidFill", "UInt", RfArgb(RfMix(kc, lk.fg, 0.12)), "Ptr*", br)
		DllCall("gdiplus\GdipFillPath", "Ptr", g, "Ptr", br, "Ptr", path)
		DllCall("gdiplus\GdipDeleteBrush", "Ptr", br)
		DllCall("gdiplus\GdipCreatePen1", "UInt", RfArgb(RfMix(kc, lk.fg, 0.3)), "Float", 1.0, "Int", 2, "Ptr*", pen)
		DllCall("gdiplus\GdipDrawPath", "Ptr", g, "Ptr", pen, "Ptr", path)
		DllCall("gdiplus\GdipDeletePen", "Ptr", pen)
		DllCall("gdiplus\GdipDeletePath", "Ptr", path)
		RfGdipDraw(g, s.hint, kf, (lk.ifg != "") ? lk.ifg : lk.fg, x + kpad, H, 0)
		}
}

RfPaint(h) {
	global RfPaintSpec, DpiF
	if (!h or !IsObject(RfPaintSpec) or !RfPaintSpec.HasKey(h) or !RfGdipStart())
		return false
	s := RfPaintSpec[h]
	lk := (s.state != "" and s.looks.HasKey(s.state)) ? s.looks[s.state] : s.looks.n
	; bw / bh, not W / H: AutoHotkey names ignore case, so "H" would overwrite the handle h
	bw := Max(1, Round(s.w * DpiF)), bh := Max(1, Round(s.h * DpiF))
	bmp := 0, g := 0
	DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", bw, "Int", bh, "Int", 0, "Int", 0x21808, "Ptr", 0, "Ptr*", bmp)
	if (!bmp)
		{
		RfDrawNote("Failed: no bitmap (" . bw . " x " . bh . ")")
		return false
		}
	DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", bmp, "Ptr*", g)
	DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", g, "Int", 4)
	DllCall("gdiplus\GdipSetTextRenderingHint", "Ptr", g, "Int", 4)
	DllCall("gdiplus\GdipGraphicsClear", "Ptr", g, "UInt", RfArgb(s.bg))
	if (s.kind = "switch")
		RfGdipSwitch(g, s, bw, bh)
	else if (lk.fill != "" or lk.edge != "")
		{
		path := RfGdipRoundPath(0.5, 0.5, bw - 1, bh - 1, (s.HasKey("r") ? s.r : 8) * DpiF)
		if (lk.fill != "")
			{
			br := 0
			DllCall("gdiplus\GdipCreateSolidFill", "UInt", RfArgb(lk.fill), "Ptr*", br)
			DllCall("gdiplus\GdipFillPath", "Ptr", g, "Ptr", br, "Ptr", path)
			DllCall("gdiplus\GdipDeleteBrush", "Ptr", br)
			}
		if (lk.edge != "")
			{
			pen := 0
			DllCall("gdiplus\GdipCreatePen1", "UInt", RfArgb(lk.edge), "Float", Max(1, Floor(DpiF)), "Int", 2, "Ptr*", pen)
			DllCall("gdiplus\GdipDrawPath", "Ptr", g, "Ptr", pen, "Ptr", path)
			DllCall("gdiplus\GdipDeletePen", "Ptr", pen)
			}
		DllCall("gdiplus\GdipDeletePath", "Ptr", path)
		}
	if (s.kind != "switch" and (s.text != "" or s.icon != "" or lk.dot != ""))
		RfGdipContent(g, s, lk, bw, bh)
	hbm := 0
	DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", bmp, "Ptr*", hbm, "UInt", RfArgb(s.bg))
	DllCall("gdiplus\GdipDeleteGraphics", "Ptr", g)
	DllCall("gdiplus\GdipDisposeImage", "Ptr", bmp)
	if (!hbm)
		{
		RfDrawNote("Failed: no HBITMAP")
		return false
		}
	; STM_SETIMAGE. The control may keep a copy of a 32-bit bitmap instead of the bitmap itself;
	; whatever it hands back is no longer used, and ours is freed if it was copied.
	old := DllCall("SendMessage", "Ptr", h, "UInt", 0x172, "Ptr", 0, "Ptr", hbm, "Ptr")
	if (old and old != hbm)
		DllCall("DeleteObject", "Ptr", old)
	cur := DllCall("SendMessage", "Ptr", h, "UInt", 0x173, "Ptr", 0, "Ptr", 0, "Ptr")
	if (!cur)
		RfDrawNote("Failed: the control kept no image")
	else if (cur != hbm)
		DllCall("DeleteObject", "Ptr", hbm)
	return true
}

; Which look a drawn control should show now: active tab, hovered, or normal.
RfPaintState(h) {
	global RfPaintSpec, RfHoverCtl, RfActiveTab
	s := RfPaintSpec[h]
	if (s.kind = "tab" and s.name = RfActiveTab)
		return "a"
	return (h = RfHoverCtl and s.looks.HasKey("h")) ? "h" : "n"
}

RfRepaintState(h) {
	global RfPaintSpec
	if (!RfPaintSpec.HasKey(h))
		return
	st := RfPaintState(h)
	if (st != RfPaintSpec[h].state)
		{
		RfPaintSpec[h].state := st
		RfPaint(h)
		}
}

; ------------------------------------------------------------------------------------------------
; Buttons. A leading ▶ ■ ✕ ✓ in the text becomes the matching icon.
; ------------------------------------------------------------------------------------------------
RfBtnSetText(s, text) {
	static map := ""
	if (!IsObject(map))
		map := {"▶": 0xE768, "■": 0xE71A, "✕": 0xE711, "✓": 0xE73E}
	ic := SubStr(text, 1, 1)
	if (map.HasKey(ic))
		{
		s.icon := Chr(map[ic])
		text := LTrim(SubStr(text, 2))
		}
	else if (!s.keepIcon)
		s.icon := ""
	s.text := text
}

RfBtnLooks(kind) {
	global ColorAccent, ColorText, ColorMuted
	if (kind = "primary")
		return {n: {fill: ColorAccent, fg: "FFFFFF", ifg: "FFFFFF"}, h: {fill: "F0646A", fg: "FFFFFF", ifg: "FFFFFF"}}
	return {n: {fill: "242428", edge: "303035", fg: ColorText, ifg: ColorMuted}, h: {fill: "2F2F35", edge: "3D3D44", fg: "FFFFFF", ifg: "FFFFFF"}}
}

RfBtnSpec(w, h, text, kind, bg, icon := "") {
	s := {w: w, h: h, bg: bg, r: 7, pt: 9, state: "n", kind: kind, looks: RfBtnLooks(kind)}
	if (icon != "")
		s.icon := icon, s.keepIcon := true
	RfBtnSetText(s, text)
	return s
}

; New text for a drawn button, by its variable name (e.g. DetTestBtn) or handle.
RfBtnText(var, text) {
	global RfBtnVar, RfPaintSpec
	h := RfBtnVar.HasKey(var) ? RfBtnVar[var] : var
	if (!RfPaintSpec.HasKey(h))
		return
	RfBtnSetText(RfPaintSpec[h], text)
	RfPaint(h)
}

;====================================================================================================;
;   Re:Fisch interface (new): header with live status, top tabs, dashboard, footer save bar.
;   Every settings control is bound to the same variable the engine reads, so changes apply
;   live; Save / auto-save writes them to the active profile.
;====================================================================================================;

RfTheme() {
	global
	ColorBG := "0B0B0C"
	ColorPanel := "131315"
	ColorCard := "1A1A1D"
	ColorInput := "111113"
	ColorAccent := "E5484D"
	ColorText := "EDEDED"
	ColorMuted := "8E8E93"
	ColorBorder := "2B2B2F"
	ColorGreen := "3DD68C"
	ColorRed := "E5484D"
	ColorAmber := "F5B83D"
	ColorDim := "55555B"
	ColorInfo := "6CB6FF"
	ColorStart := "E6E6E6"
	ColorEdge := "2A2A2F"
	ColorBad := "FF8A8A"           ; a field that holds no usable number or key (RfMarkBad)
	ColorBadBg := "3A1719"
	ColorBadBGR := RfBgrHex(ColorBad), ColorBadBgBGR := RfBgrHex(ColorBadBg)
	RfBrushBad := RfBrush(ColorBadBg)
	; the text colours in GDI's blue-green-red order
	ColorTextBGR := RfBgrHex(ColorText), ColorMutedBGR := RfBgrHex(ColorMuted)
	ColorRedBGR := RfBgrHex(ColorRed), ColorGreenBGR := RfBgrHex(ColorGreen)
	ColorAmberBGR := RfBgrHex(ColorAmber), ColorDimBGR := RfBgrHex(ColorDim)
	ColorInfoBGR := RfBgrHex(ColorInfo), ColorInputBGR := RfBgrHex(ColorInput)
	ColorWhiteBGR := 0xFFFFFF
	; the painted surfaces
	RfBrushBG := RfBrush(ColorBG), RfBrushPanel := RfBrush(ColorPanel)
	RfBrushCard := RfBrush(ColorCard), RfBrushInput := RfBrush(ColorInput)
	RfBrushBorder := RfBrush(ColorBorder), RfBrushEdge := RfBrush("29292E")
	RfBrushBtn := RfBrush("26262A"), RfBrushBtnHi := RfBrush("34343A")
	RfBrushRed := RfBrush(ColorRed), RfBrushRedHi := RfBrush("F0646A")
	RfBrushGreen := RfBrush(ColorGreen), RfBrushTabHi := RfBrush("18181B")
	RfBrushStart := RfBrush(ColorStart), RfBrushStartHi := RfBrush("FFFFFF")
	RfBrushAmber := RfBrush(ColorAmber), RfBrushAmberHi := RfBrush("FFC95A")
	RfBrushAmberSoft := RfBrush("33280F")
}

; A solid GDI brush in a theme colour ("RRGGBB").
RfBrush(hex) {
	return DllCall("CreateSolidBrush", "UInt", RfBgrHex(hex), "Ptr")
}

; ------------------------------------------------------------------------------------------------
; Control helpers. Assume-global (needed for the v-variables); temporaries are declared local.
; ------------------------------------------------------------------------------------------------
RfReg(h, tab, grp) {
	global RfCtl
	RfCtl.Push({h: h, tab: tab, grp: grp})
}

RfDark(h) {
	DllCall("uxtheme\SetWindowTheme", "Ptr", h, "Str", "DarkMode_CFD", "Ptr", 0)
}

; Controls in the main window are plain rectangles: clipping them to rounded shapes made them
; flicker whenever a tab was shown. Only separate windows (the ready banner) are rounded.
RfRound(h, w, ht, r) {
}

RfRoundWin(h, w, ht, r) {
	global DpiF
	rgn := DllCall("CreateRoundRectRgn", "Int", 0, "Int", 0, "Int", Round(w * DpiF) + 1, "Int", Round(ht * DpiF) + 1
		, "Int", Round(r * 2 * DpiF), "Int", Round(r * 2 * DpiF), "Ptr")
	DllCall("SetWindowRgn", "Ptr", h, "Ptr", rgn, "Int", true)
}

; A card: one drawn, rounded bitmap (fill and 1 px edge) under its controls.
RfCard(tab, grp, x, y, w, h) {
	global
	local hb
	Gui, 1:Add, Text, x%x% y%y% w%w% h%h% +0xE Hwndhb
	RfPaintSpec[hb] := {w: w, h: h, bg: ColorBG, r: 10, state: "n", looks: {n: {fill: ColorCard, edge: ColorEdge}}}
	RfPaint(hb)
	RfReg(hb, tab, grp)
	RfCards.Push({tab: tab, grp: grp, edge: hb, x: x, y: y, w: w, h: h, rows: [], ny: y, nh: h})
	RfIsCardBg[hb] := true
	return hb
}

; ------------------------------------------------------------------------------------------------
; Relayout. Cards are built at fixed spots; when a mode hides some rows (a Normal cast has no
; Perfect settings, Precision has no Manual multipliers, each rod has its own options) the
; hidden rows are collapsed, every card shrinks to what it shows, and the cards below move up.
; Rows are found from the controls' real positions, so the builders stay simple.
; ------------------------------------------------------------------------------------------------
RfLayoutInit() {
	global
	local ci, cd, i, c, it, rows, k, j, tmp, r, cx, cy, best
	RfGrpParent := {kitty: "stellar", swdefault: "stellar", remem: "notstellar", hali: "notstellar", requiem: "notstellar"
		, otherrod: "notstellar", norod: "notstellar"}
	for i, c in RfCtl
		{
		if (RfIsCardBg.HasKey(c.h))
			continue
		GuiControlGet, RfLp, 1:Pos, % c.h
		if (RfIsDdl.HasKey(c.h))
			RfLpH := Min(RfLpH, Round(24 * RfUiK))
		cx := RfLpX + 1, cy := RfLpY + 1
		; the smallest card under the control whose group can be on together with the control's
		; (two cards can share a spot when they belong to different rods)
		best := ""
		for ci, cd in RfCards
			{
			if (cd.tab != c.tab or cx < cd.x or cx >= cd.x + cd.w or cy < cd.y or cy >= cd.y + cd.h)
				continue
			if (cd.grp != "" and cd.grp != c.grp and RfGrpParent[c.grp] != cd.grp)
				continue
			if (!IsObject(best) or cd.w * cd.h < best.w * best.h)
				best := cd
			}
		if (IsObject(best))
			best.rows.Push({h: c.h, tab: c.tab, grp: c.grp, x: RfLpX, y: RfLpY, w: RfLpW, ht: RfLpH})
		}
	; items -> rows (sorted by y; a row is everything starting within 12 px of its first item)
	for ci, cd in RfCards
		{
		it := cd.rows
		k := 2
		while (k <= it.Length())
			{
			tmp := it[k], j := k - 1
			while (j >= 1 and it[j].y > tmp.y)
				{
				it[j + 1] := it[j]
				j -= 1
				}
			it[j + 1] := tmp
			k += 1
			}
		rows := []
		for i, c in it
			{
			if (!rows.Length() or c.y >= rows[rows.Length()].top + Round(12 * RfUiK))
				rows.Push({top: c.y, items: []})
			rows[rows.Length()].items.Push(c)
			}
		cd.end := cd.y
		for i, r in rows
			{
			for k, c in r.items
				cd.end := Max(cd.end, c.y + c.ht)
			}
		cd.rows := rows
		}
	; cards in placement order: by original top, then left
	RfCardOrder := []
	for ci, cd in RfCards
		{
		k := RfCardOrder.Length() + 1
		while (k > 1 and (RfCardOrder[k - 1].y > cd.y or (RfCardOrder[k - 1].y = cd.y and RfCardOrder[k - 1].x > cd.x)))
			{
			RfCardOrder[k] := RfCardOrder[k - 1]
			k -= 1
			}
		RfCardOrder[k] := cd
		}
}

RfItemOn(c) {
	global RfActiveTab
	return (c.tab = "" or c.tab = RfActiveTab) and RfGroupOn(c.grp)
}

; Positions every card of the active tab and returns nothing; controls are moved, not shown.
RfRelayout() {
	global
	local ci, cd, i, r, k, c, s, vis, top, placed, p, b, maxB, low, dy, nextTop, lastB, gi, g2, visB, vn, gap
	; 1. collapse hidden rows; every visible card gets the height of what it shows. A hidden row
	;    only gives its space back when it lies fully below everything shown above it (rows of
	;    two modes can interleave, e.g. Precision and Manual reel settings). Alpha 1.4: each
	;    visible row after the first sits gap px lower than built (r.extra), for roomier cards.
	gap := Round(5 * RfUiK)
	for ci, cd in RfCardOrder
		{
		cd.on := (cd.tab = RfActiveTab and RfGroupOn(cd.grp))
		if (!cd.on)
			continue
		s := 0, lastB := 0, visB := 0, vn := 0
		for i, r in cd.rows
			{
			vis := false
			b := 0
			for k, c in r.items
				{
				if (RfItemOn(c))
					{
					vis := true
					b := Max(b, c.y + c.ht)
					}
				}
			r.on := vis
			r.shift := s
			if (vis)
				{
				r.extra := vn * gap, vn += 1
				lastB := Max(lastB, b - s + r.extra)
				visB := Max(visB, b)
				}
			else if (r.top >= visB)
				{
				nextTop := (i < cd.rows.Length()) ? cd.rows[i + 1].top : cd.end
				s += Max(0, nextTop - r.top)
				}
			}
		cd.nh := Max(cd.h - s + Max(0, vn - 1) * gap, lastB - cd.y + Round(8 * RfUiK))
		}
	; 2. cards built side by side at the same height stay the same height
	for ci, cd in RfCardOrder
		{
		if (!cd.on)
			continue
		for gi, g2 in RfCardOrder
			{
			if (g2.on and g2 != cd and g2.y = cd.y and g2.h = cd.h and g2.nh > cd.nh)
				cd.nh := g2.nh
			}
		}
	; 3. place each card under every placed card it overlaps horizontally
	placed := []
	for ci, cd in RfCardOrder
		{
		if (!cd.on)
			continue
		top := RfY0
		for p, b in placed
			{
			if (b.x < cd.x + cd.w and cd.x < b.x + b.w)
				top := Max(top, b.ny + b.nh + Round(14 * RfUiK))
			}
		cd.ny := top
		placed.Push(cd)
		}
	; 4. columns that end within 40 px of each other end together
	maxB := 0
	for ci, cd in placed
		maxB := Max(maxB, cd.ny + cd.nh)
	; remember how tall this tab is on its own; RfFitWindow sizes the window to the tallest
	RfTabBottom[RfActiveTab] := maxB
	for ci, cd in placed
		{
		low := true
		for gi, g2 in placed
			{
			if (g2 != cd and g2.ny > cd.ny and g2.x < cd.x + cd.w and cd.x < g2.x + g2.w)
				low := false
			}
		if (low and maxB - (cd.ny + cd.nh) <= Round(40 * RfUiK))
			cd.nh := maxB - cd.ny
		}
	; 5. move what changed
	for ci, cd in placed
		{
		dy := cd.ny - cd.y
		if (cd.ny != cd.ly or cd.nh != cd.lh)
			{
			if (cd.nh != cd.lh and cd.nh != RfPaintSpec[cd.edge].h)
				{
				RfPaintSpec[cd.edge].h := cd.nh
				RfPaint(cd.edge)
				}
			GuiControl, 1:Move, % cd.edge, % "y" . cd.ny . " h" . cd.nh
			cd.ly := cd.ny, cd.lh := cd.nh
			}
		for i, r in cd.rows
			{
			if (!r.on)
				continue
			for k, c in r.items
				{
				if (c.ly = c.y + dy - r.shift + r.extra)
					continue
				c.ly := c.y + dy - r.shift + r.extra
				GuiControl, 1:Move, % c.h, % "y" . c.ly
				}
			}
		}
}

RfHead(tab, grp, x, y, w, text) {
	global
	local hh
	Gui, 1:Font, s8 Bold, Segoe UI
	Gui, 1:Add, Text, x%x% y%y% w%w% h16 +0x80 Hwndhh, %text%
	Gui, 1:Font, s9 Norm, Segoe UI
	RfStyle[hh] := {bg: RfBrushCard, fg: ColorRedBGR}
	RfReg(hh, tab, grp)
	return hh
}

RfLbl(tab, grp, x, y, w, text, fg := "", h := 22) {
	global
	local hl
	Gui, 1:Add, Text, x%x% y%y% w%w% h%h% +0x80 +0x200 Hwndhl, %text%
	RfStyle[hl] := {bg: RfBrushCard, fg: (fg = "") ? ColorTextBGR : fg}
	RfReg(hl, tab, grp)
	return hl
}

RfHint(tab, grp, x, y, w, h, text) {
	global
	local hn
	Gui, 1:Font, s8 Norm, Segoe UI
	Gui, 1:Add, Text, x%x% y%y% w%w% h%h% +0x80 Hwndhn, %text%
	Gui, 1:Font, s9 Norm, Segoe UI
	RfStyle[hn] := {bg: RfBrushCard, fg: ColorMutedBGR}
	RfReg(hn, tab, grp)
	return hn
}

RfEdit(tab, grp, x, y, w, var, tip := "") {
	global
	local he, val
	val := %var%
	Gui, 1:Add, Edit, x%x% y%y% w%w% h22 v%var% gRfChanged -E0x200 +Border Hwndhe, %val%
	RfIsEdit[var] := true
	RfEditH[var] := he
	RfDark(he)
	RfReg(he, tab, grp)
	if (tip != "")
		RfTips[he] := tip
	return he
}

RfDdl(tab, grp, x, y, w, var, list, tip := "") {
	global
	local hd, val
	val := %var%
	Gui, 1:Add, DropDownList, x%x% y%y% w%w% h400 v%var% gRfChanged Hwndhd, %list%
	GuiControl, 1:ChooseString, %hd%, %val%
	RfIsDdl[hd] := true
	RfDark(hd)
	RfReg(hd, tab, grp)
	if (tip != "")
		RfTips[hd] := tip
	return hd
}

; A setting switch (Alpha 1.4: drawn on/off switch). The real CheckBox stays, hidden, so Submit,
; RfDupPush and the profile code keep reading and writing it; the drawn switch (RfSwitch) sits in
; its place, is what the layout moves and shows, and is the one the hover help belongs to.
RfChk(tab, grp, x, y, w, var, text, tip := "") {
	global
	local hk, chk, hs
	chk := %var% ? "Checked" : ""
	Gui, 1:Add, CheckBox, x%x% y%y% w%w% h20 v%var% gRfChanged %chk% Hidden Hwndhk, %text%
	hs := RfSwitch(x, y, w, hk, text, ColorCard)
	RfReg(hs, tab, grp)
	if (tip != "")
		RfTips[hs] := tip
	return hs
}

; The drawn switch for the hidden CheckBox hk: a click flips hk and sends the window the click
; notice hk would have sent (WM_COMMAND, BN_CLICKED), so hk's own g-label runs as before.
RfSwitch(x, y, w, hk, text, bg) {
	global
	local hs, n
	RfSwN := ((RfSwN = "") ? 0 : RfSwN) + 1
	n := "RfSw" . RfSwN
	Gui, 1:Add, Text, x%x% y%y% w%w% h20 +0xE +0x100 v%n% gRfSwitchClick Hwndhs
	RfPaintSpec[hs] := {w: w, h: 20, bg: bg, pt: 9, kind: "switch", text: text, state: "n", looks: {n: {}, h: {}}
		, on: (DllCall("SendMessage", "Ptr", hk, "UInt", 0xF0, "Ptr", 0, "Ptr", 0, "Ptr") = 1)}
	RfSwChk[n] := hk, RfSwAll[hs] := hk
	RfPaint(hs)
	return hs
}

; Redraws every switch whose CheckBox changed (a profile load, Home's copy of a switch, a click).
RfSwSync() {
	global RfSwAll, RfPaintSpec
	if (!IsObject(RfSwAll))
		return
	for hs, hk in RfSwAll
		{
		st := (DllCall("SendMessage", "Ptr", hk, "UInt", 0xF0, "Ptr", 0, "Ptr", 0, "Ptr") = 1)
		if (st != RfPaintSpec[hs].on)
			{
			RfPaintSpec[hs].on := st
			RfPaint(hs)
			}
		}
}

; A switch: rounded track (accent when on), round knob, then the label.
RfGdipSwitch(g, s, W, H) {
	global DpiF, ColorAccent, ColorText
	hov := (s.state = "h")
	th := Round(H * 0.80), tw := Round(th * 1.8), ty := (H - th) / 2, tx := 1
	path := RfGdipRoundPath(tx + 0.5, ty + 0.5, tw - 1, th - 1, th / 2)
	br := 0
	DllCall("gdiplus\GdipCreateSolidFill", "UInt", RfArgb(s.on ? (hov ? "F0646A" : ColorAccent) : (hov ? "3A3A41" : "2C2C31")), "Ptr*", br)
	DllCall("gdiplus\GdipFillPath", "Ptr", g, "Ptr", br, "Ptr", path)
	DllCall("gdiplus\GdipDeleteBrush", "Ptr", br)
	if (!s.on)
		{
		pen := 0
		DllCall("gdiplus\GdipCreatePen1", "UInt", RfArgb(hov ? "4A4A52" : "3D3D44"), "Float", Max(1, Floor(DpiF)), "Int", 2, "Ptr*", pen)
		DllCall("gdiplus\GdipDrawPath", "Ptr", g, "Ptr", pen, "Ptr", path)
		DllCall("gdiplus\GdipDeletePen", "Ptr", pen)
		}
	DllCall("gdiplus\GdipDeletePath", "Ptr", path)
	d := th * 0.70, pad := (th - d) / 2
	kx := s.on ? (tx + tw - d - pad) : (tx + pad)
	DllCall("gdiplus\GdipCreateSolidFill", "UInt", RfArgb(s.on ? "FFFFFF" : (hov ? "C8C8CE" : "9A9AA2")), "Ptr*", br)
	DllCall("gdiplus\GdipFillEllipse", "Ptr", g, "Ptr", br, "Float", kx, "Float", ty + pad, "Float", d, "Float", d)
	DllCall("gdiplus\GdipDeleteBrush", "Ptr", br)
	if (s.text != "")
		RfGdipDraw(g, s.text, RfGdipFont("Segoe UI", s.pt, 0), hov ? "FFFFFF" : ColorText, tx + tw + th * 0.55, H, 0)
}

; A drawn, rounded button on a card (bg = the colour around it).
RfBtn(tab, grp, x, y, w, h, text, label, kind := "ghost", var := "", bg := "", icon := "") {
	global
	local hb, vo
	vo := (var != "") ? "v" . var : ""
	Gui, 1:Add, Text, x%x% y%y% w%w% h%h% +0xE +0x100 %vo% g%label% Hwndhb
	RfPaintSpec[hb] := RfBtnSpec(w, h, text, kind, (bg = "") ? ColorCard : bg, icon)
	RfPaint(hb)
	if (var != "")
		RfBtnVar[var] := hb
	if (tab != "-")
		RfReg(hb, tab, grp)
	return hb
}


; A labelled row: label on the left, an Edit (or list) reaching the card's right edge.
RfRowEdit(tab, grp, cx, y, label, var, tip := "", iw := 150) {
	global
	RfLbl(tab, grp, cx + 14, y, 200, label)
	RfEdit(tab, grp, cx + 224, y, iw, var, tip)
}

RfRowDdl(tab, grp, cx, y, label, var, list, tip := "", iw := 150) {
	global
	local hd
	RfLbl(tab, grp, cx + 14, y, 200, label)
	hd := RfDdl(tab, grp, cx + 224, y, iw, var, list, tip)
	return hd
}

; ------------------------------------------------------------------------------------------------
; Which conditional groups are visible right now.
; ------------------------------------------------------------------------------------------------
RfGroupOn(g) {
	global CastMode, ControlMode, SpecialRod, StellarSkin
	if (g = "")
		return true
	if (g = "perfect")
		return (CastMode = "Perfect")
	if (g = "normalcast")
		return (CastMode != "Perfect")
	if (g = "manual")
		return (ControlMode = "Manual")
	if (g = "precision")
		return (ControlMode != "Manual")
	if (g = "stellar")
		return (SpecialRod = "Stellarwave Melody")
	if (g = "notstellar")
		return (SpecialRod != "Stellarwave Melody")
	if (g = "swdefault")
		return (SpecialRod = "Stellarwave Melody" and StellarSkin != "Kitty Keys")
	if (g = "kitty")
		return (SpecialRod = "Stellarwave Melody" and StellarSkin = "Kitty Keys")
	if (g = "remem")
		return (SpecialRod = "Remembrance")
	if (g = "hali")
		return (SpecialRod = "Halibut Harpoon")
	if (g = "requiem")
		return (SpecialRod = "Requiem")
	if (g = "otherrod")
		return (SpecialRod != "None" and SpecialRod != "Stellarwave Melody" and SpecialRod != "Remembrance"
			and SpecialRod != "Halibut Harpoon" and SpecialRod != "Requiem")
	if (g = "norod")
		return (SpecialRod = "None")
	return true
}

; ------------------------------------------------------------------------------------------------
; Window height follows the open tab: the window ends just below that tab's cards (or below the
; sidebar, if that is taller), so there is no empty strip and no card is stretched to fill one.
; The top of the window stays put; the footer and "Made by" move with the bottom edge.
; ------------------------------------------------------------------------------------------------
RfFitWindow() {
	global
	local need, t, b, gap, hc, dy, nh, i
	gap := Round(12 * RfUiK)
	need := RfTabBottom.HasKey(RfActiveTab) ? RfTabBottom[RfActiveTab] : 0
	GuiControlGet, RfFk, 1:Pos, %hRfReloadBtn%
	GuiControlGet, RfFf, 1:Pos, %hRfFootBG%
	need := Max(need, RfFkY + RfFkH + Round(44 * RfUiK) - gap - RfFfH)
	if (need = RfContentBottom)
		return false
	RfContentBottom := need
	dy := need + gap - RfFfY
	nh := need + gap + RfFfH
	if (dy)
		{
		; only the footer's own controls and "Made by" move (never another tab's cards)
		for i, hc in [hRfDiv2, hRfFootBG, hRfFootProf, hRfSaveStatus, hRfAuto, hRfSaveBtn, hRfMadeBy]
			{
			GuiControlGet, RfFc, 1:Pos, %hc%
			GuiControl, 1:Move, %hc%, % "y" . (RfFcY + dy)
			}
		}
	GuiControl, 1:Move, %hRfSideBG%, h%nh%
	GuiControl, 1:Move, %hRfSideLine%, h%nh%
	RfH := nh
	if (RfGuiBuilt)
		Gui, 1:Show, % "w" . RfW . " h" . RfH . " NoActivate" . (DllCall("IsWindowVisible", "Ptr", GuiHwnd) ? "" : " Hide")
	return true
}

RfApplyVisibility() {
	global RfCtl, RfActiveTab, GuiHwnd, RfCardOrder
	if (IsObject(RfCardOrder))
		{
		RfRelayout()
		RfFitWindow()
		}
	for i, c in RfCtl
		{
		show := (c.tab = "" or c.tab = RfActiveTab) and RfGroupOn(c.grp)
		h := c.h
		GuiControl, % "1:" . (show ? "Show" : "Hide"), %h%
		}
	DllCall("RedrawWindow", "Ptr", GuiHwnd, "Ptr", 0, "Ptr", 0, "UInt", 0x0185)
}

; ------------------------------------------------------------------------------------------------
; Window scale. The interface is built at 100% (the numbers in the builders), then every control
; of the main window is moved and resized by k, its font is swapped for a k-sized copy, drawn
; controls (cards, tabs, buttons) get k-sized specs and are drawn again, and the card layout and
; window size follow. Runs once, before RfLayoutInit reads the positions.
; ------------------------------------------------------------------------------------------------
RfScaleUi(k) {
	global
	local hc, cls, hf, lf, s, ci, cd, nx, ny, nw, nh, fonts, pt0
	if (k = 1 or k = "")
		return
	fonts := {}
	hc := DllCall("GetWindow", "Ptr", GuiHwnd, "UInt", 5, "Ptr")          ; first child
	while (hc)
		{
		GuiControlGet, RfSc, 1:Pos, %hc%
		nx := Round(RfScX * k), ny := Round(RfScY * k), nw := Max(1, Round(RfScW * k)), nh := Max(1, Round(RfScH * k))
		WinGetClass, cls, ahk_id %hc%
		if (cls = "ComboBox")
			GuiControl, 1:Move, %hc%, x%nx% y%ny% w%nw%          ; h of a drop-down list is its open list
		else
			GuiControl, 1:Move, %hc%, x%nx% y%ny% w%nw% h%nh%
		; font: one k-sized copy per original font
		hf := DllCall("SendMessage", "Ptr", hc, "UInt", 0x31, "Ptr", 0, "Ptr", 0, "Ptr")
		if (hf)
			{
			if (!fonts.HasKey(hf))
				{
				VarSetCapacity(lf, 92, 0)
				DllCall("GetObject", "Ptr", hf, "Int", 92, "Ptr", &lf)
				NumPut(Round(NumGet(lf, 0, "Int") * k), lf, 0, "Int")
				fonts[hf] := DllCall("CreateFontIndirect", "Ptr", &lf, "Ptr")
				}
			DllCall("SendMessage", "Ptr", hc, "UInt", 0x30, "Ptr", fonts[hf], "Ptr", 0)
			}
		; the logo pictures: reload the icon at the new size so it stays sharp
		if ((hc = hHeaderLogo or hc = hRfAboutLogo) and FileExist(ReFishIcoPath))
			GuiControl, 1:, %hc%, *w%nw% *h%nh% %ReFishIcoPath%
		; drawn controls: scale the description and draw again
		if (RfPaintSpec.HasKey(hc))
			{
			s := RfPaintSpec[hc]
			pt0 := s.HasKey("pt") ? s.pt : 9
			s.ipt := (s.HasKey("ipt") ? s.ipt : pt0 + 1) * k
			s.pt := pt0 * k
			s.r := (s.HasKey("r") ? s.r : 8) * k
			s.gap := (s.HasKey("gap") ? s.gap : 8) * k
			s.pad := (s.HasKey("pad") ? s.pad : 12) * k
			s.dy := (s.HasKey("dy") ? s.dy : 0) * k
			s.idy := (s.HasKey("idy") ? s.idy : 1) * k
			s.w := nw, s.h := nh
			RfPaint(hc)
			}
		hc := DllCall("GetWindow", "Ptr", hc, "UInt", 2, "Ptr")          ; next sibling
		}
	for ci, cd in RfCards
		{
		cd.x := Round(cd.x * k), cd.y := Round(cd.y * k), cd.w := Round(cd.w * k), cd.h := Round(cd.h * k)
		cd.ny := cd.y, cd.nh := cd.h
		}
	RfY0 := Round(RfY0 * k)
	RfW := Round(RfW * k), RfH := Round(RfH * k)
}

; ------------------------------------------------------------------------------------------------
; Window colours.
; ------------------------------------------------------------------------------------------------
RfCtlColorStatic(wParam, lParam) {
	global RfStyle
	global RfBrushBG, ColorTextBGR, hFrzGui, RfHoverCtl
	if (hFrzGui and DllCall("GetParent", "Ptr", lParam, "Ptr") = hFrzGui)
		return
	DllCall("SetBkMode", "Ptr", wParam, "Int", 1)
	if (IsObject(RfStyle) and RfStyle.HasKey(lParam))
		{
		s := RfStyle[lParam]
		DllCall("SetTextColor", "Ptr", wParam, "UInt", s.fg)
		return s.bg
		}
	DllCall("SetTextColor", "Ptr", wParam, "UInt", ColorTextBGR)
	return RfBrushBG
}

RfCtlColorEdit(wParam, lParam) {
	global RfBrushInput, ColorInputBGR, ColorTextBGR, RfBadH, RfBrushBad, ColorBadBGR, ColorBadBgBGR
	if (IsObject(RfBadH) and RfBadH.HasKey(lParam))
		{
		DllCall("SetTextColor", "Ptr", wParam, "UInt", ColorBadBGR)
		DllCall("SetBkColor", "Ptr", wParam, "UInt", ColorBadBgBGR)
		return RfBrushBad
		}
	DllCall("SetTextColor", "Ptr", wParam, "UInt", ColorTextBGR)
	DllCall("SetBkColor", "Ptr", wParam, "UInt", ColorInputBGR)
	return RfBrushInput
}

RfCtlColorBtn(wParam, lParam) {
	global RfBrushCard, ColorTextBGR
	DllCall("SetBkMode", "Ptr", wParam, "Int", 1)
	DllCall("SetTextColor", "Ptr", wParam, "UInt", ColorTextBGR)
	return RfBrushCard
}

; ------------------------------------------------------------------------------------------------
; Build.
; ------------------------------------------------------------------------------------------------
RfBuildGui:
RfTheme()
RfCtl := []
RfStyle := {}
RfTips := {}
RfBtnVar := {}
RfSwChk := {}, RfSwAll := {}, RfSwN := 0
RfPaintSpec := {}
RfIsEdit := {}
RfEditH := {}          ; variable -> its Edit (RfMarkBad)
RfBadH := {}           ; Edits drawn red: they hold no usable number or key
RfTabH := {}
RfCards := []
RfIsCardBg := {}
RfIsDdl := {}
RfDupFrom := {}
RfDupSide := {}
RfTabBottom := {}
RfContentBottom := 0
RfGuiBuilt := false
RfActiveTab := "Home"
RfHoverCtl := 0
RfSB := 200          ; sidebar width
RfW := RfSB + 820
RfH := 640
RfL := RfSB + 16
RfR := RfSB + 416
RfCW := 388
RfFullW := 788
RfY0 := 68
RfGdipStart()
; Window size. Everything is laid out at 100% below, then RfScaleUi shrinks it all by RfUiK.
; Change it in the settings file: [GUI] UiScale=0.95 (0.6 to 1.25; 1 = the old full size).
RfUiK := 0.95
if (SettingsFile != "")
	IniRead, RfUiK, %SettingsFile%, GUI, UiScale, 0.95
RfUiK += 0
if RfUiK is not number
	RfUiK := 0.95
RfUiK := (RfUiK < 0.6) ? 0.6 : (RfUiK > 1.25) ? 1.25 : RfUiK

; Home shows the game-setup, hotkey and window options of the Settings tab (and the Auto Totem
; switch of Utilities) a second time. A variable can only belong to one control, so the Home copies
; are "RfDup" + the name and are kept in step both ways (RfDupPull / RfDupPush).
StartStopKeyCtrl := StartStopKey
ReloadKeyCtrl := ReloadKey
ExitKeyCtrl := ExitKey
RfSetupDefs := [["Lower graphics on start", "AutoLowerGraphics", "AutoGraphicsDelay"], ["Zoom camera in", "AutoZoomInCamera", "AutoZoomDelay"]
	, ["Turn on camera mode", "AutoEnableCameraMode", "AutoCameraDelay"], ["Look down before casting", "AutoLookDownCamera", "AutoLookDelay"]
	, ["Blur camera", "AutoBlurCamera", "AutoBlurDelay"]]
RfDupPairs := []
for RfI, RfRow in RfSetupDefs
	{
	RfDupPairs.Push([RfRow[2], "chk"])
	RfDupPairs.Push([RfRow[3], "edit"])
	}
for RfI, RfV in ["StartStopKeyCtrl", "ReloadKeyCtrl", "ExitKeyCtrl"]
	RfDupPairs.Push([RfV, "edit"])
for RfI, RfV in ["GuiAlwaysOnTop", "GuiKeepOpen", "RfTotOn"]
	RfDupPairs.Push([RfV, "chk"])
for RfI, RfP in RfDupPairs
	{
	RfV := RfP[1]
	RfDup%RfV% := %RfV%
	}

Gui, 1:New, +HwndGuiHwnd -MaximizeBox +0x02000000, Re:Fisch
RfSetWindowIcons(GuiHwnd)
Gui, 1:Font, s9 c%ColorText%, Segoe UI
Gui, 1:Color, %ColorBG%, %ColorInput%
Gui, 1:Margin, 0, 0
OnMessage(0x133, "RfCtlColorEdit")
OnMessage(0x134, "RfCtlColorEdit")
OnMessage(0x135, "RfCtlColorBtn")
OnMessage(0x138, "RfCtlColorStatic")

;---- sidebar: name, session, run state, Start / Reload / Exit -----------------------------------
Gui, 1:Add, Text, x0 y0 w%RfSB% h%RfH% HwndhRfSideBG
RfStyle[hRfSideBG] := {bg: RfBrushPanel, fg: ColorTextBGR}
Gui, 1:Add, Text, x%RfSB% y0 w1 h%RfH% HwndhRfSideLine
RfStyle[hRfSideLine] := {bg: RfBrushBorder, fg: ColorTextBGR}
if (FileExist(ReFishIcoPath))
	{
	Gui, 1:Add, Picture, x18 y18 w38 h38 HwndhHeaderLogo, %ReFishIcoPath%
	RfStyle[hHeaderLogo] := {bg: RfBrushPanel, fg: ColorTextBGR}
	}
Gui, 1:Font, s15 Bold, Segoe UI
Gui, 1:Add, Text, x64 y15 w130 h28 +0x80 HwndhRfTitle, Re:Fisch
RfStyle[hRfTitle] := {bg: RfBrushPanel, fg: 0xFFFFFF}
Gui, 1:Font, s8 Norm, Segoe UI
Gui, 1:Add, Text, x65 y42 w130 h16 +0x80 HwndhRfSub, %RfVersion%
RfStyle[hRfSub] := {bg: RfBrushPanel, fg: ColorMutedBGR}

; session card
Gui, 1:Add, Text, x12 y74 w176 h159 +0xE HwndhRfSideCard
RfPaintSpec[hRfSideCard] := {w: 176, h: 159, bg: ColorPanel, r: 10, state: "n", looks: {n: {fill: ColorCard, edge: ColorEdge}}}
RfPaint(hRfSideCard)
Gui, 1:Font, s8 Bold, Segoe UI
Gui, 1:Add, Text, x26 y86 w150 h16 +0x80 HwndhRfSideHead, SESSION
RfStyle[hRfSideHead] := {bg: RfBrushCard, fg: ColorRedBGR}
RfTileDefs := [["CASTS", "RfTileCasts", 0xFFFFFF, "RfTileCastsSub", "0"], ["REEL FIGHTS", "RfTileFights", 0xFFFFFF, "RfTileFightsSub", "0"]
	, ["TIME-OUTS", "RfTileFails", ColorAmberBGR, "RfTileFailsSub", "0"], ["SESSION TIME", "RfTileTime", 0xFFFFFF, "RfTileTimeSub", "0:00"]]
; four tiles in a 2 x 2 grid: label, number, and a small note under the number
for RfI, RfRow in RfTileDefs
	{
	RfTx := 26 + Mod(RfI - 1, 2) * 80
	RfTy := 108 + ((RfI - 1) // 2) * 60
	Gui, 1:Font, s7 Bold, Segoe UI
	Gui, 1:Add, Text, x%RfTx% y%RfTy% w76 h14 +0x80 HwndRfTl, % RfRow[1]
	RfStyle[RfTl] := {bg: RfBrushCard, fg: ColorMutedBGR}
	Gui, 1:Font, s15 Bold, Segoe UI
	Gui, 1:Add, Text, % "x" . (RfTx - 1) . " y" . (RfTy + 13) . " w77 h28 +0x80 v" . RfRow[2] . " HwndRfTv", % RfRow[5]
	RfStyle[RfTv] := {bg: RfBrushCard, fg: RfRow[3]}
	Gui, 1:Font, s8 Norm, Segoe UI
	Gui, 1:Add, Text, % "x" . RfTx . " y" . (RfTy + 41) . " w78 h14 +0x80 v" . RfRow[4] . " HwndRfTs",
	RfStyle[RfTs] := {bg: RfBrushCard, fg: ColorMutedBGR}
	}

; run state chip and the Start button (both drawn; RfRunPaint sets their look)
Gui, 1:Add, Text, x12 y245 w176 h30 +0xE HwndhRunStatus
RfPaintSpec[hRunStatus] := {w: 176, h: 30, bg: ColorPanel, r: 15, pt: 9, state: "n", text: "Idle", looks: {n: {fill: "1C1C20", edge: "2A2A2F", fg: ColorMuted, dot: ColorDim}}}
Gui, 1:Add, Text, x12 y283 w176 h44 +0xE +0x100 vStartStopDisplay gRfStartButton HwndhStartStopBtnHwnd
RfPaintSpec[hStartStopBtnHwnd] := {w: 176, h: 44, bg: ColorPanel, r: 10, pt: 11, ipt: 11, state: "n", looks: {n: {fill: ColorStart, fg: "101010"}}}
RfRunPaint(true)
; Reload / Exit show their Roblox key as a key cap (RfFooterText keeps it current)
hRfReloadBtn := RfBtn("-", "", 12, 335, 86, 32, "Reload", "DoReload", "ghost", "", ColorPanel, Chr(0xE72C))
hRfExitBtn := RfBtn("-", "", 102, 335, 86, 32, "Exit", "DoExit", "ghost", "", ColorPanel, Chr(0xE7E8))
Gui, 1:Font, s8 Norm, Segoe UI
Gui, 1:Add, Text, % "x18 y" . (RfH - 30) . " w170 h16 +0x80 HwndhRfMadeBy", Made by bai
RfStyle[hRfMadeBy] := {bg: RfBrushPanel, fg: ColorDimBGR}
Gui, 1:Font, s9 Norm, Segoe UI

;---- tabs (drawn pills with an icon) ------------------------------------------------------------
RfTabIcon := {Home: 0xE80F, Fishing: 0xE7FC, Rod: 0xE945, Utilities: 0xE90F, Settings: 0xE713, About: 0xE946}
RfTabTint := RfMix(ColorBG, ColorAccent, 0.16)
RfTabRim := RfMix(ColorBG, ColorAccent, 0.5)
RfTx := RfL
for RfTi, RfTn in ["Home", "Fishing", "Rod", "Utilities", "Settings", "About"]
	{
	RfTw := RfTextWidth(RfTn, 10) + 50
	Gui, 1:Add, Text, x%RfTx% y14 w%RfTw% h34 +0xE +0x100 vRfTab%RfTn% gRfTabClick HwndRfTh
	RfPaintSpec[RfTh] := {w: RfTw, h: 34, bg: ColorBG, r: 9, pt: 10, ipt: 11, kind: "tab", name: RfTn, state: "n"
		, text: RfTn, icon: Chr(RfTabIcon[RfTn])
		, looks: {n: {fg: ColorMuted, ifg: ColorMuted}, h: {fill: "18181B", edge: "26262B", fg: ColorText, ifg: ColorText}
		, a: {fill: RfTabTint, edge: RfTabRim, fg: "FFFFFF", ifg: ColorAccent}}}
	RfTabH[RfTn] := RfTh
	RfPaint(RfTh)
	RfTx += RfTw + 6
	}
Gui, 1:Add, Text, % "x" . (RfSB + 1) . " y56 w" . (RfW - RfSB - 1) . " h1 HwndhRfDiv1"
RfStyle[hRfDiv1] := {bg: RfBrushBorder, fg: ColorTextBGR}

gosub, RfBuildHome
gosub, RfBuildFishing
gosub, RfBuildRod
gosub, RfBuildUtilities
gosub, RfBuildSettings
gosub, RfBuildAbout

;---- footer (content side) ----------------------------------------------------------------------
RfFy := RfH - 44
Gui, 1:Add, Text, % "x" . (RfSB + 1) . " y" . (RfFy - 1) . " w" . (RfW - RfSB - 1) . " h1 HwndhRfDiv2"
RfStyle[hRfDiv2] := {bg: RfBrushBorder, fg: ColorTextBGR}
Gui, 1:Add, Text, % "x" . (RfSB + 1) . " y" . RfFy . " w" . (RfW - RfSB - 1) . " h44 HwndhRfFootBG"
RfStyle[hRfFootBG] := {bg: RfBrushPanel, fg: ColorTextBGR}
Gui, 1:Font, s8 Norm, Segoe UI
Gui, 1:Add, Text, % "x" . (RfL + 2) . " y" . (RfFy + 14) . " w380 h18 +0x80 vRfFootProfile HwndhRfFootProf", % "Profile:  " . ActiveProfile . "     ·     F9 picks colors"
RfStyle[hRfFootProf] := {bg: RfBrushPanel, fg: ColorMutedBGR}
Gui, 1:Add, Text, % "x" . (RfW - 404) . " y" . (RfFy + 14) . " w150 h18 Right +0x80 vRfSaveStatus HwndhRfSaveStatus",
RfStyle[hRfSaveStatus] := {bg: RfBrushPanel, fg: ColorGreenBGR}
Gui, 1:Font, s9 Norm, Segoe UI
RfAutoChk := GuiAutoSave ? "Checked" : ""
Gui, 1:Add, CheckBox, % "x" . (RfW - 244) . " y" . (RfFy + 12) . " w100 h20 vGuiAutoSave gRfAutoSaveToggle " . RfAutoChk . " Hidden HwndhRfAutoChk", Auto-save
hRfAuto := RfSwitch(RfW - 244, RfFy + 12, 100, hRfAutoChk, "Auto-save", ColorPanel)
RfTips[hRfAuto] := "Save to the profile automatically a moment after any change."
hRfSaveBtn := RfBtn("-", "", RfW - 132, RfFy + 8, 116, 28, "Save", "RfSave", "primary", "", ColorPanel, Chr(0xE74E))
gosub, RfFooterText
RfScaleUi(RfUiK)

if (GuiAlwaysOnTop)
	Gui, 1:+AlwaysOnTop
RfLayoutInit()
for RfTi, RfTn in ["Fishing", "Rod", "Utilities", "Settings", "About", "Home"]
	{
	RfActiveTab := RfTn
	RfRelayout()
	}
RfFitWindow()
RfActiveTab := "Home"
gosub, RfShowTab
RfDarkAttr := 1
DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", GuiHwnd, "Int", 20, "Int*", RfDarkAttr, "Int", 4)
Gui, 1:Show, w%RfW% h%RfH%, Re:Fisch
RfGuiBuilt := true
; Text painted this early can come out as black boxes (the colour handler cannot run yet during
; start-up); full repaints shortly after fix that before it is noticeable. Drawn parts (cards,
; tabs, buttons) are bitmaps and are right from the first frame.
SetTimer, RfRepaint, -60
SetTimer, RfRepaint2, -400
gosub, RefreshSwatches
gosub, RfOverlayBuild
SetTimer, RfUiTick, 100
SetTimer, RfHoverTick, 40
if (RfImported != "")
	{
	RfSaveStatusText := "Imported settings from " . RfImported
	GuiControl, 1:, RfSaveStatus, Imported fork settings
	SetTimer, RfClearSaveStatus, -6000
	}
return

; ------------------------------------------------------------------------------------------------
; Home: live status, quick toggles (the same switches as Settings), utilities, setup checklist.
; The session numbers are in the sidebar.
; ------------------------------------------------------------------------------------------------
RfBuildHome:
RfT := "Home"
; status
RfCard(RfT, "", RfL, RfY0, RfCW, 200)
RfHead(RfT, "", RfL + 16, RfY0 + 13, 200, "STATUS")
RfHomeRows := [["Rod", "RfHomeRod"], ["Skin", "RfHomeSkin"], ["Cast  ·  shake", "RfHomeCast"], ["Reel", "RfHomeReel"], ["Doing now", "RfHomeTask"], ["Auto Totem", "RfHomeTotem"], ["Loop speed", "RfHomeLoop"]]
RfY2 := RfY0 + 36
for RfI, RfRow in RfHomeRows
	{
	RfLbl(RfT, "", RfL + 16, RfY2, 96, RfRow[1], ColorMutedBGR)
	RfV := RfRow[2]
	Gui, 1:Add, Text, % "x" . (RfL + 112) . " y" . RfY2 . " w268 h22 +0x80 +0x200 v" . RfV . " HwndRfHv", -
	RfStyle[RfHv] := {bg: RfBrushCard, fg: ColorTextBGR}
	RfReg(RfHv, RfT, "")
	RfY2 += 22
	}
; utilities
RfY := RfY0 + 210
RfCard(RfT, "", RfL, RfY, RfCW, 112)
RfHead(RfT, "", RfL + 16, RfY + 13, 300, "UTILITIES")
RfChk(RfT, "", RfL + 16, RfY + 37, 356, "RfDupRfTotOn", "Auto Totem  ·  keep totem events going", "Same switch as on the Utilities tab, where the`nevents are picked.")
RfLbl(RfT, "", RfL + 16, RfY + 58, 356, "Auto Appraise is started from the Utilities tab.", ColorMutedBGR, 20)
RfBtn(RfT, "", RfL + 16, RfY + 80, 150, 24, "Open Utilities", "RfGoUtilities", "ghost", "", "", Chr(0xE90F))
; quick toggles
RfCard(RfT, "", RfR, RfY0, RfCW, 322)
RfHead(RfT, "", RfR + 16, RfY0 + 13, 200, "QUICK TOGGLES")
RfLbl(RfT, "", RfR + 16, RfY0 + 36, 200, "GAME SETUP", ColorDimBGR, 16)
RfLbl(RfT, "", RfR + 300, RfY0 + 36, 74, "delay ms", ColorDimBGR, 16)
RfY := RfY0 + 56
for RfI, RfRow in RfSetupDefs
	{
	RfChk(RfT, "", RfR + 16, RfY + 1, 270, "RfDup" . RfRow[2], RfRow[1], "Same switch as Settings, Game setup.")
	RfEdit(RfT, "", RfR + 300, RfY, 74, "RfDup" . RfRow[3], "Wait after this step (ms).")
	RfY += 26
	}
RfLbl(RfT, "", RfR + 16, RfY0 + 192, 200, "HOTKEYS", ColorDimBGR, 16)
RfY := RfY0 + 212
RfLbl(RfT, "", RfR + 16, RfY, 76, "Start / stop")
RfEdit(RfT, "", RfR + 92, RfY, 52, "RfDupStartStopKeyCtrl", "Any key name: p, F6, Insert ...`nApplied when settings are saved.")
RfLbl(RfT, "", RfR + 158, RfY, 50, "Reload")
RfEdit(RfT, "", RfR + 208, RfY, 52, "RfDupReloadKeyCtrl", "Applied when settings are saved.")
RfLbl(RfT, "", RfR + 274, RfY, 30, "Exit")
RfEdit(RfT, "", RfR + 306, RfY, 68, "RfDupExitKeyCtrl", "Applied when settings are saved.")
RfLbl(RfT, "", RfR + 16, RfY0 + 246, 200, "WINDOW", ColorDimBGR, 16)
RfChk(RfT, "", RfR + 16, RfY0 + 266, 356, "RfDupGuiAlwaysOnTop", "Keep this window on top")
RfChk(RfT, "", RfR + 16, RfY0 + 290, 356, "RfDupGuiKeepOpen", "Keep this window open after pressing Start")
; setup checklist
RfY := RfY0 + 332
RfCard(RfT, "", RfL, RfY, RfFullW, 128)
RfHead(RfT, "", RfL + 16, RfY + 13, 400, "FIRST-TIME SETUP")
RfHint(RfT, "", RfL + 16, RfY + 38, 370, 80, "IN FISCH SETTINGS`n•  Extra Brightness: slider all the way right`n•  Camera Shake: off`n•  Fishing Minigame Shake: slider all the way left`n•  Show Enchant Info: off")
RfHint(RfT, "", RfL + 404, RfY + 38, 370, 80, "WINDOWS / ROBLOX`n•  Fullscreen Roblox (windowed fullscreen if detection fails)`n•  Windows display scale 100%, HDR off`n•  Don't move or resize Roblox while running`n•  Calibrate colors with F9 if the bar or fish is missed")
return

RfGoUtilities:
RfActiveTab := "Utilities"
gosub, RfShowTab
return
; ------------------------------------------------------------------------------------------------
; Fishing: cast, shake, reel, colors, detection check.
; ------------------------------------------------------------------------------------------------
RfBuildFishing:
RfT := "Fishing"
; CAST
RfCard(RfT, "", RfL, RfY0, RfCW, 196)
RfHead(RfT, "", RfL + 14, RfY0 + 12, 200, "CAST")
RfRowDdl(RfT, "", RfL, RfY0 + 34, "Cast mode", "CastMode", "Normal|Perfect", "NORMAL holds the mouse for a fixed time.`nPERFECT watches the power bar and lets go`non the green marker.")
RfRowEdit(RfT, "", RfL, RfY0 + 60, "Wait for bobber (ms)", "WaitForBobberDelay", "How long to wait after casting before shaking.`nRaise it on laggy servers.")
RfRowEdit(RfT, "normalcast", RfL, RfY0 + 86, "Hold to cast (ms)", "HoldRodCastDuration", "Longer = further cast.")
RfRowEdit(RfT, "perfect", RfL, RfY0 + 86, "Release timing (ms)", "PerfectReleaseTiming", "Lets go this many ms earlier (+) or later (-).`nReleases too late? raise it by 5.`nToo early? lower it by 5.")
RfRowEdit(RfT, "perfect", RfL, RfY0 + 112, "Give up after (s)", "PerfectFailTimeout", "Falls back to a normal cast if the power bar`nis never found in this time.")
RfRowEdit(RfT, "perfect", RfL, RfY0 + 138, "Wait cycles", "PerfectWaitCycles", "Full bar cycles to watch before releasing.")
RfLbl(RfT, "perfect", RfL + 14, RfY0 + 164, 200, "Green / white tolerance")
RfEdit(RfT, "perfect", RfL + 224, RfY0 + 164, 72, "PerfectGreenTolerance", "Color tolerance for the green marker.")
RfEdit(RfT, "perfect", RfL + 302, RfY0 + 164, 72, "PerfectWhiteTolerance", "Color tolerance for the white fill.")
; SHAKE
RfY := RfY0 + 206
RfCard(RfT, "", RfL, RfY, RfCW, 142)
RfHead(RfT, "", RfL + 14, RfY + 12, 200, "SHAKE")
RfRowDdl(RfT, "", RfL, RfY + 34, "Shake mode", "ShakeMode", "Navigation|Disabled", "NAVIGATION presses Enter through the shake`nprompts. DISABLED skips straight to the reel.")
RfRowEdit(RfT, "", RfL, RfY + 60, "Navigation key", "NavigationKey", "Your Roblox UI navigation key (default \).")
RfRowEdit(RfT, "", RfL, RfY + 86, "Press every (ms)", "NavigationSpamDelay", "Delay between shake presses.")
RfRowEdit(RfT, "", RfL, RfY + 112, "Give up after (s)", "NavigationShakeFailsafe", "Recasts if no reel appears in this time.")
; DETECTION CHECK
RfY := RfY0 + 358
RfCard(RfT, "", RfL, RfY, RfCW, 78)
RfHead(RfT, "", RfL + 14, RfY + 12, 200, "DETECTION CHECK")
RfBtn(RfT, "", RfL + 14, RfY + 36, 150, 28, "▶  Test detection", "DetTestToggle", "ghost", "DetTestBtn")
Gui, 1:Font, s8 Norm, Segoe UI
Gui, 1:Add, Text, % "x" . (RfL + 174) . " y" . (RfY + 36) . " w200 h28 +0x80 +0x200 vDetTestOut HwndRfDo", Open a reel in Fisch, then press Test.
Gui, 1:Font, s9 Norm, Segoe UI
RfStyle[RfDo] := {bg: RfBrushCard, fg: ColorMutedBGR}
RfReg(RfDo, RfT, "")
; REEL
RfCard(RfT, "", RfR, RfY0, RfCW, 254)
RfHead(RfT, "", RfR + 14, RfY0 + 12, 200, "REEL")
ControlModeDdlH := RfRowDdl(RfT, "", RfR, RfY0 + 34, "Control mode", "ControlMode", "Manual|Precision|Lines", "PRECISION steers with velocity tracking (best`nfor most rods). LINES follows the fish line.`nMANUAL uses the multipliers below.")
ControlModeDdl := 1
RfRowEdit(RfT, "", RfR, RfY0 + 60, "Bar search time-out (s)", "BarCalculationFailsafe", "Recasts if the bar is never measured.")
RfRowEdit(RfT, "", RfR, RfY0 + 86, "Side zone ratio", "SideBarRatio", "How close to the edges the bar may go`n(fraction of bar width).")
RfRowEdit(RfT, "precision", RfR, RfY0 + 112, "Kp  (reaction)", "Kp", "Raise if slow to catch a fish that bolts.")
RfRowEdit(RfT, "precision", RfR, RfY0 + 138, "Kd  (damping)", "Kd", "Raise if the bar wobbles on the fish.`nKd matters most.")
RfRowEdit(RfT, "precision", RfR, RfY0 + 164, "Velocity smoothing", "VelocitySmoothing", "How much each new frame counts (0.6 to 1).`nHigher reacts faster, lower is smoother.`nValues under 0.6 count as 0.6.")
RfRowEdit(RfT, "precision", RfR, RfY0 + 190, "Stopping distance", "StoppingDistanceMultiplier", "Sails past the fish? raise. Crawls? lower.")
RfChk(RfT, "precision", RfR + 14, RfY0 + 218, 200, "HumanClicks", "Human-like clicking", "Clicks no faster than a person could: each press and`nrelease lasts a moment, with a little random variation.`nCosts a few px of centring at 8 per second.")
RfLbl(RfT, "precision", RfR + 224, RfY0 + 217, 72, "clicks / s", ColorMutedBGR)
RfEdit(RfT, "precision", RfR + 300, RfY0 + 217, 74, "HumanCps", "Fastest clicks per second with Human-like clicking on`n(1 to 20). 8 is about as fast as a quick player.`nUnder 6 the fish starts to slip.")
RfManualDefs := [["Stable right  × / ÷", "StableRightMultiplier", "StableRightDivision"], ["Stable left  × / ÷", "StableLeftMultiplier", "StableLeftDivision"]
	, ["Unstable right  × / ÷", "UnstableRightMultiplier", "UnstableRightDivision"], ["Unstable left  × / ÷", "UnstableLeftMultiplier", "UnstableLeftDivision"]
	, ["Ankle break  R / L", "RightAnkleBreakMultiplier", "LeftAnkleBreakMultiplier"], ["Stabilizer  /  side wait", "StabilizerLoop", "SideBarWaitMultiplier"]]
RfY := RfY0 + 112
for RfI, RfRow in RfManualDefs
	{
	RfLbl(RfT, "manual", RfR + 14, RfY, 200, RfRow[1])
	RfEdit(RfT, "manual", RfR + 224, RfY, 72, RfRow[2])
	RfEdit(RfT, "manual", RfR + 302, RfY, 72, RfRow[3])
	RfY += 21
	}
; COLORS
RfY := RfY0 + 256
RfCard(RfT, "", RfR, RfY, RfCW, 180)
RfHead(RfT, "", RfR + 14, RfY + 12, 200, "COLORS")
RfBtn(RfT, "", RfR + 254, RfY + 8, 120, 24, "Pick  (F9)", "FreezePickHotkey", "ghost", "", "", Chr(0xE790))
RfColorDefs := [["Fish line", "FishColor", "FishBarColorTolerance"], ["Bar left end", "BarLeftColor", "BarColorTolerance"]
	, ["Bar right end", "BarRightColor", ""], ["Bar arrow", "ArrowColor", "ArrowColorTolerance"]]
RfY += 38
for RfI, RfRow in RfColorDefs
	{
	RfLbl(RfT, "", RfR + 14, RfY, 96, RfRow[1])
	RfSw := RfRow[2] . "Swatch"
	Gui, 1:Add, Progress, % "x" . (RfR + 112) . " y" . (RfY + 3) . " w16 h16 Background202020 v" . RfSw . " HwndRfSwH", 0
	RfReg(RfSwH, RfT, "")
	RfEdit(RfT, "", RfR + 134, RfY, 178, RfRow[2], "Comma-separated list: add every shade it takes.`nPick from the game with F9.")
	if (RfRow[3] != "")
		RfEdit(RfT, "", RfR + 318, RfY, 56, RfRow[3], "Color tolerance (0-255).")
	RfY += 26
	}
RfHint(RfT, "", RfR + 14, RfY + 4, 360, 28, "Tolerance column: fish, bar (both ends), arrow. F9 freezes the screen; number keys switch target.")
return

; ------------------------------------------------------------------------------------------------
; Rod: special rod, skin, Stellarwave / Kitty Keys and per-rod options.
; ------------------------------------------------------------------------------------------------
RfBuildRod:
RfT := "Rod"
RfRodList := "None|Stellarwave Melody|Pinions Aria|Requiem|Darkheart|Bellona's Waraxe|Dreambreaker|Tranquility|Noiseform|Verdant Oath|Lullaby|Castbound|Remembrance|MiguRod|Halibut Harpoon|Splitbranch Twig|Tryhard Rod"
RfCard(RfT, "", RfL, RfY0, RfCW, 160)
RfHead(RfT, "", RfL + 14, RfY0 + 12, 200, "ROD")
RfRowDdl(RfT, "", RfL, RfY0 + 34, "Special rod", "SpecialRod", RfRodList, "Pick the rod you fish with if it has its own`nminigame. None = any normal rod.")
RfRowDdl(RfT, "stellar", RfL, RfY0 + 60, "Skin", "StellarSkin", "Default|Kitty Keys", "Kitty Keys has its own sign detection.")
Gui, 1:Font, s8 Norm, Segoe UI
Gui, 1:Add, Text, % "x" . (RfL + 14) . " y" . (RfY0 + 92) . " w360 h60 +0x80 vRfRodNote HwndRfRn", -
Gui, 1:Font, s9 Norm, Segoe UI
RfStyle[RfRn] := {bg: RfBrushCard, fg: ColorMutedBGR}
RfReg(RfRn, RfT, "")
; per-rod options (right column; Stellarwave uses that column for its own card)
RfY := RfY0
RfCard(RfT, "notstellar", RfR, RfY, RfCW, 140)
RfHead(RfT, "notstellar", RfR + 14, RfY + 12, 300, "ROD OPTIONS")
RfRowDdl(RfT, "remem", RfR, RfY + 34, "Remembrance mode", "RemembranceMode", "Living|Departed", "Match the side of the minigame you play.")
RfChk(RfT, "hali", RfR + 14, RfY + 36, 300, "HalibutPlayMinigame", "Play the harpoon minigame", "ON - goes for the exclamation mark.`nOFF - stays on the fish line.")
RfRowEdit(RfT, "requiem", RfR, RfY + 34, "Min hold (ms)", "ReelMinHold", "Raise if the reel keeps snapping.")
RfRowEdit(RfT, "requiem", RfR, RfY + 60, "Min release (ms)", "ReelMinRelease", "Raise if the reel keeps snapping.")
RfHint(RfT, "otherrod", RfR + 14, RfY + 34, 360, 60, "This rod runs on its built-in handling and your saved settings.`nIts own settings panel arrives in a later build. Its colors`ncan already be picked with F9 (number keys switch target).")
RfHint(RfT, "norod", RfR + 14, RfY + 34, 360, 60, "Normal rods use the Fishing tab: reel control and colors.`nPick a special rod on the left for rods with their own`nminigame.")
; Stellarwave / Kitty Keys
RfCard(RfT, "stellar", RfR, RfY0, RfCW, 198)
RfHead(RfT, "stellar", RfR + 14, RfY0 + 12, 300, "STELLARWAVE MELODY")
RfChk(RfT, "stellar", RfR + 14, RfY0 + 36, 360, "SwClickSigns", "Click the signs", "ON - clicks the zodiac signs in the order shown`nabove the bar while reeling. OFF - only reels.")
RfChk(RfT, "stellar", RfR + 14, RfY0 + 60, 360, "SwFastClicks", "Fast sign clicks", "Clicks each sign as soon as it is matched,`nwith shorter clicks.")
RfChk(RfT, "stellar", RfR + 14, RfY0 + 84, 360, "SwRetryClicks", "Retry failed clicks", "Retries a sign whose click did not register.")
RfRowDdl(RfT, "kitty", RfR, RfY0 + 112, "Click speed", "KittyClickSpeed", "Normal|Fast|Turbo", "How long each sign click hovers, holds and`nrests. NORMAL = original timings, FAST is`nabout a third quicker, TURBO is quickest.`nDrop a level if signs get missed.")
RfRowEdit(RfT, "kitty", RfR, RfY0 + 138, "Min shape match (%)", "KittyShapeMin", "How closely a sign must match its zodiac.")
RfRowEdit(RfT, "kitty", RfR, RfY0 + 164, "Shape margin (%)", "KittyShapeMargin", "How much better the best match must be`nthan the runner-up.")
RfY := RfY0 + 170
RfCard(RfT, "stellar", RfL, RfY, RfCW, 160)
RfHead(RfT, "swdefault", RfL + 14, RfY + 12, 300, "STELLARWAVE COLORS")
RfSwDefs := [["Bar frame", "StellarBarColors", "StellarBarTol"], ["Fish line", "StellarFishColors", "StellarFishTol"], ["Fish head", "StellarHeadColors", "StellarHeadTol"]]
RfY2 := RfY + 36
for RfI, RfRow in RfSwDefs
	{
	RfLbl(RfT, "swdefault", RfL + 14, RfY2, 96, RfRow[1])
	RfEdit(RfT, "swdefault", RfL + 134, RfY2, 178, RfRow[2], "Only change if the bar or fish is not picked up.")
	RfEdit(RfT, "swdefault", RfL + 318, RfY2, 56, RfRow[3], "Color tolerance.")
	RfY2 += 26
	}
RfHint(RfT, "swdefault", RfL + 14, RfY2 + 4, 360, 30, "Defaults: frame 0x55446D, fish 0xAFDAE8, head 0xFFFFFF.")
RfHead(RfT, "kitty", RfL + 14, RfY + 12, 300, "KITTY KEYS")
RfRowEdit(RfT, "kitty", RfL, RfY + 36, "Bar rim tolerance", "KittyRimTol", "Tolerance for the white rims of the Kitty bar.")
Gui, 1:Font, s8 Norm, Segoe UI
Gui, 1:Add, Text, % "x" . (RfL + 14) . " y" . (RfY + 68) . " w360 h80 +0x80 vRfKittyInfo HwndRfKi", -
Gui, 1:Font, s9 Norm, Segoe UI
RfStyle[RfKi] := {bg: RfBrushCard, fg: ColorMutedBGR}
RfReg(RfKi, RfT, "kitty")
return

; ------------------------------------------------------------------------------------------------
; Utilities: rebuilt in build 3.
; ------------------------------------------------------------------------------------------------
RfBuildUtilities:
RfT := "Utilities"
; AUTO TOTEM (rebuilt in 2.3: pick events, the totems are found on the hotbar by name)
RfCard(RfT, "", RfL, RfY0, RfCW, 344)
RfHead(RfT, "", RfL + 14, RfY0 + 12, 300, "AUTO TOTEM")
RfChk(RfT, "", RfL + 14, RfY0 + 36, 360, "RfTotOn", "Keep the events below going", "Between casts: finds the totems on the hotbar, uses a Sundial`nfirst when an event needs day or night, and uses the totem`nagain when its icon (bottom right) goes away.")
RfLbl(RfT, "", RfL + 14, RfY0 + 62, 300, "EVENTS", ColorDimBGR, 16)
for RfI, RfV in RfTotDefs()
	RfChk(RfT, "", RfL + 14 + ((RfI - 1) // 6) * 182, RfY0 + 80 + Mod(RfI - 1, 6) * 24, 176, "RfTotE" . RfV.id, RfV.label, RfV.tip)
RfRowEdit(RfT, "", RfL, RfY0 + 230, "Use time (ms)", "RfTotUseMs", "How long to wait after using a totem before`nthe next one (or the rod back in hand).")
RfRowEdit(RfT, "", RfL, RfY0 + 256, "No icon seen: again after (min)", "RfTotRetryMin", "When no new icon shows up after a totem is used,`nit is used again after this many minutes.")
RfHint(RfT, "", RfL + 14, RfY0 + 284, 360, 18, "Needs the rod hotbar key (Settings, Recovery) and Windows text reading.")
Gui, 1:Font, s8 Norm, Segoe UI
Gui, 1:Add, Text, % "x" . (RfL + 14) . " y" . (RfY0 + 306) . " w360 h32 +0x80 vRfTotStatus HwndhRfTotStatus", -
Gui, 1:Font, s9 Norm, Segoe UI
RfStyle[hRfTotStatus] := {bg: RfBrushCard, fg: ColorGreenBGR}
RfReg(hRfTotStatus, RfT, "")
; AUTO APPRAISE
RfCard(RfT, "", RfR, RfY0, RfCW, 344)
RfHead(RfT, "", RfR + 14, RfY0 + 12, 300, "AUTO APPRAISE   ·   new")
RfRowEdit(RfT, "", RfR, RfY0 + 34, "Stop on mutation(s)", "RfApTargets", "Comma-separated, e.g. Shiny, Sparkling.`nStops as soon as one of them appears.")
RfRowEdit(RfT, "", RfR, RfY0 + 60, "Talk key", "RfApKey", "The key that opens the Appraiser's dialogue`n(the interact key, usually E).")
RfRowEdit(RfT, "", RfR, RfY0 + 86, "Most tries", "RfApMax", "Stops after this many appraisals.")
RfRowEdit(RfT, "", RfR, RfY0 + 112, "Wait for dialogue (ms)", "RfApWaitMs", "Time for the dialogue to open after talking.")
RfRowEdit(RfT, "", RfR, RfY0 + 138, "Wait for result (ms)", "RfApResultMs", "Time for the appraisal result to show.")
RfBtn(RfT, "", RfR + 14, RfY0 + 170, 120, 24, "Pick button 1", "RfApPick1")
Gui, 1:Font, s8 Norm, Segoe UI
Gui, 1:Add, Text, % "x" . (RfR + 144) . " y" . (RfY0 + 170) . " w230 h24 +0x80 +0x200 vRfApPos1Txt HwndRfApT1", -
Gui, 1:Font, s9 Norm, Segoe UI
RfStyle[RfApT1] := {bg: RfBrushCard, fg: ColorMutedBGR}
RfReg(RfApT1, RfT, "")
RfBtn(RfT, "", RfR + 14, RfY0 + 198, 120, 24, "Pick button 2", "RfApPick2")
Gui, 1:Font, s8 Norm, Segoe UI
Gui, 1:Add, Text, % "x" . (RfR + 144) . " y" . (RfY0 + 198) . " w170 h24 +0x80 +0x200 vRfApPos2Txt HwndRfApT2", -
Gui, 1:Font, s9 Norm, Segoe UI
RfStyle[RfApT2] := {bg: RfBrushCard, fg: ColorMutedBGR}
RfReg(RfApT2, RfT, "")
RfBtn(RfT, "", RfR + 318, RfY0 + 198, 56, 24, "Clear", "RfApClearPos2")
RfBtn(RfT, "", RfR + 14, RfY0 + 232, 170, 28, "▶  Start appraising", "RfApStart", "primary")
Gui, 1:Font, s8 Norm, Segoe UI
Gui, 1:Add, Text, % "x" . (RfR + 194) . " y" . (RfY0 + 232) . " w180 h28 +0x80 +0x200 vRfApStatus HwndRfApS", Start key stops it.
Gui, 1:Font, s9 Norm, Segoe UI
RfStyle[RfApS] := {bg: RfBrushCard, fg: ColorMutedBGR}
RfReg(RfApS, RfT, "")
RfHint(RfT, "", RfR + 14, RfY0 + 270, 360, 62, "Stand at the Appraiser holding the fish. Open the dialogue once, use`nPick to hover the button that appraises (button 2 only if a`nsecond click is needed), then Start. Reads the result with Windows`ntext recognition; stops when there is not enough money.")
; AUTO AQUARIUM
RfCard(RfT, "", RfL, RfY0 + 354, RfFullW, 70)
RfHead(RfT, "", RfL + 14, RfY0 + 366, 400, "AUTO AQUARIUM")
RfLbl(RfT, "", RfL + 14, RfY0 + 388, 700, "Being rebuilt for Re:Fisch - arrives in build 3.", ColorDimBGR)
gosub, RfApPosText
return

; ------------------------------------------------------------------------------------------------
; Settings: profiles, hotkeys, window, game setup, recovery.
; ------------------------------------------------------------------------------------------------
RfBuildSettings:
RfT := "Settings"
RfCard(RfT, "", RfL, RfY0, RfCW, 130)
RfHead(RfT, "", RfL + 14, RfY0 + 12, 200, "PROFILE")
Gui, 1:Add, DropDownList, % "x" . (RfL + 14) . " y" . (RfY0 + 34) . " w200 h300 vProfileSelect gRfProfileSelect HwndRfPs"
RfIsDdl[RfPs] := true
RfDark(RfPs)
RfReg(RfPs, RfT, "")
RfBtn(RfT, "", RfL + 222, RfY0 + 33, 74, 24, "New", "RfProfileNew")
RfBtn(RfT, "", RfL + 300, RfY0 + 33, 74, 24, "Copy", "RfProfileDuplicate")
RfBtn(RfT, "", RfL + 222, RfY0 + 62, 152, 24, "Delete profile", "RfProfileDelete")
RfBtn(RfT, "", RfL + 14, RfY0 + 94, 200, 24, "Import from DeepFish fork", "RfImportButton")
RfY := RfY0 + 140
RfCard(RfT, "", RfL, RfY, RfCW, 112)
RfHead(RfT, "", RfL + 14, RfY + 12, 200, "HOTKEYS")
RfRowEdit(RfT, "", RfL, RfY + 34, "Start / stop", "StartStopKeyCtrl", "Any key name: p, F6, Insert ...")
RfRowEdit(RfT, "", RfL, RfY + 60, "Reload", "ReloadKeyCtrl")
RfRowEdit(RfT, "", RfL, RfY + 86, "Exit", "ExitKeyCtrl")
RfY := RfY0 + 262
RfCard(RfT, "", RfL, RfY, RfCW, 84)
RfHead(RfT, "", RfL + 14, RfY + 12, 200, "WINDOW")
RfChk(RfT, "", RfL + 14, RfY + 34, 360, "GuiAlwaysOnTop", "Keep this window on top")
RfChk(RfT, "", RfL + 14, RfY + 56, 360, "GuiKeepOpen", "Keep this window open after pressing Start")
; GAME SETUP
RfCard(RfT, "", RfR, RfY0, RfCW, 182)
RfHead(RfT, "", RfR + 14, RfY0 + 12, 200, "GAME SETUP")
RfLbl(RfT, "", RfR + 300, RfY0 + 10, 74, "delay ms", ColorMutedBGR, 18)
RfY := RfY0 + 34
for RfI, RfRow in RfSetupDefs
	{
	RfChk(RfT, "", RfR + 14, RfY + 1, 270, RfRow[2], RfRow[1], "Also on the Home tab (Quick toggles).")
	RfEdit(RfT, "", RfR + 300, RfY, 74, RfRow[3])
	RfY += 28
	}
; RECOVERY
RfY := RfY0 + 192
RfCard(RfT, "", RfR, RfY, RfCW, 140)
RfHead(RfT, "", RfR + 14, RfY + 12, 200, "RECOVERY")
RfRowEdit(RfT, "", RfR, RfY + 34, "Restart delay (ms)", "RestartDelay", "Pause between a finished fight and the next cast.")
RfRowEdit(RfT, "", RfR, RfY + 60, "Re-equip after N failed casts", "UnstickAfter", "Un-equips and re-equips the rod when casts`nkeep failing (stuck bobber). 0 = never.")
RfRowEdit(RfT, "", RfR, RfY + 86, "Rod hotbar key", "RodSlotKey", "The hotbar key your rod sits on.")
RfRowEdit(RfT, "", RfR, RfY + 112, "Bag hotbar key", "BagSlotKey", "Optional: switched to and back to un-stick a`ncast. Blank = press the rod key twice.")
gosub, RefreshProfileList
return

; ------------------------------------------------------------------------------------------------
; About: name, version, and the one-line attribution the reused parts' licences ask for.
; ------------------------------------------------------------------------------------------------
RfBuildAbout:
RfT := "About"
RfCard(RfT, "", RfL, RfY0, RfFullW, 112)
if (FileExist(ReFishIcoPath))
	{
	Gui, 1:Add, Picture, % "x" . (RfL + 20) . " y" . (RfY0 + 20) . " w56 h56 HwndRfAl", %ReFishIcoPath%
	RfStyle[RfAl] := {bg: RfBrushCard, fg: ColorTextBGR}
	RfReg(RfAl, RfT, "")
	hRfAboutLogo := RfAl
	}
Gui, 1:Font, s16 Bold, Segoe UI
Gui, 1:Add, Text, % "x" . (RfL + 90) . " y" . (RfY0 + 20) . " w400 h30 +0x80 HwndRfAt", Re:Fisch
Gui, 1:Font, s9 Norm, Segoe UI
RfStyle[RfAt] := {bg: RfBrushCard, fg: 0xFFFFFF}
RfReg(RfAt, RfT, "")
RfLbl(RfT, "", RfL + 90, RfY0 + 52, 500, RfVersion . "   ·   Made by bai", ColorMutedBGR)
RfHint(RfT, "", RfL + 90, RfY0 + 78, 680, 18, "Includes parts adapted from DeepFish by Yato and IRUS by AsphaltCake.")
RfY := RfY0 + 124
RfCard(RfT, "", RfL, RfY, RfFullW, 212)
RfHead(RfT, "", RfL + 20, RfY + 13, 300, "THIS INSTALL")
RfSysRows := [["AutoHotkey", A_AhkVersion . ((A_PtrSize = 8) ? "   ·   64-bit" : "   ·   32-bit")]
	, ["Speed kernels", (KittyMcState = 1) ? "On" : "Off  (needs 64-bit AutoHotkey)"]
	, ["Settings folder", RfDataDir]
	, ["Active profile", ActiveProfile]
	, ["Drawing", RfDrawNote()]]
RfY2 := RfY + 38
for RfI, RfRow in RfSysRows
	{
	RfLbl(RfT, "", RfL + 20, RfY2, 130, RfRow[1], ColorMutedBGR)
	Gui, 1:Add, Text, % "x" . (RfL + 156) . " y" . RfY2 . " w420 h22 +0x80 +0x200 +0x8000 HwndRfSv" . ((RfI = 4) ? " vRfAboutProfile" : "") . ((RfI = 5) ? " vRfAboutDraw" : ""), % RfRow[2]
	RfStyle[RfSv] := {bg: RfBrushCard, fg: ColorTextBGR}
	RfReg(RfSv, RfT, "")
	RfY2 += 24
	}
RfBtn(RfT, "", RfL + 580, RfY + 70, 168, 28, "Open settings folder", "RfOpenDataDir", "ghost", "", "", Chr(0xE8B7))
RfBtn(RfT, "", RfL + 580, RfY + 104, 168, 28, "Create shortcut", "RfMakeShortcut", "ghost", "", "", Chr(0xE71B))
RfHint(RfT, "", RfL + 20, RfY + 170, 748, 32, "Each reel fight is logged to reel.log in the settings folder; Kitty Keys to KittyKeys_diagnostic.log`nnext to this script.   Automating a game may break its rules. You use this at your own risk.")
; UPDATES (Alpha 2.2)
RfY := RfY0 + 348
RfCard(RfT, "", RfL, RfY, RfFullW, 76)
RfHead(RfT, "", RfL + 20, RfY + 13, 100, "UPDATES")
hRfUpdStatus := RfLbl(RfT, "", RfL + 130, RfY + 10, 618, "Not checked yet", ColorMutedBGR)
RfChk(RfT, "", RfL + 20, RfY + 40, 300, "UpdateAuto", "Check for updates when Re:Fisch starts", "Looks for a newer version on GitHub a few seconds`nafter start-up and asks before installing it.`nYour settings and profiles are kept.")
RfLbl(RfT, "", RfL + 340, RfY + 39, 60, "Channel")
RfDdl(RfT, "", RfL + 404, RfY + 39, 120, "UpdateChannel", "Stable|Test", "STABLE gets tested builds.`nTEST gets every new build first; it may have bugs.")
RfBtn(RfT, "", RfL + 580, RfY + 36, 168, 28, "Check now", "RfUpdCheckNow", "ghost", "", "", Chr(0xE72C))
return

; ------------------------------------------------------------------------------------------------
; Updates (Alpha 2.2). Each channel is a public GitHub repo holding Re-Fisch.ahk and version.txt
; (lines "version=Alpha 2.2", "file=Re-Fisch.ahk", "notes=... | ..." ) on branch main:
;   Stable  github.com/burntcodex/Re-Fisch       every user
;   Test    github.com/burntcodex/-testbranch    gets each build first (tools\publish.ps1 test);
;           a build that works is pushed to Stable unchanged (tools\publish.ps1 stable).
; A newer version is downloaded next to this script, must carry the advertised RfVersion and pass
; the AutoHotkey load check, then replaces this file (the old one goes to Re-Fisch\backup) and
; the script reloads. Never while fishing. Settings live in Re-Fisch\, so they are kept.
; ------------------------------------------------------------------------------------------------
RfUpdAutoTimer:
RfUpdCheck("auto")
return

RfUpdCheckNow:
RfUpdCheck("manual")
return

RfUpdBase(ch) {
	return "https://raw.githubusercontent.com/burntcodex/" . ((ch = "Test") ? "-testbranch" : "Re-Fisch") . "/main/"
}

RfUpdSay(text) {
	global hRfUpdStatus
	if (hRfUpdStatus)
		GuiControl, 1:, %hRfUpdStatus%, %text%
}

RfUpdSaveIni() {
	global
	GuiControlGet, UpdateAuto, 1:, UpdateAuto
	GuiControlGet, UpdateChannel, 1:, UpdateChannel
	UpdateAuto := UpdateAuto ? 1 : 0
	if (UpdateChannel != "Test")
		UpdateChannel := "Stable"
	IniWrite, %UpdateAuto%, %SettingsFile%, Updates, AutoCheck
	IniWrite, %UpdateChannel%, %SettingsFile%, Updates, Channel
	if (A_GuiControl = "UpdateChannel")
		RfUpdSay("Channel: " . UpdateChannel . ".  Press Check now.")
}

; mode "auto" (start-up): only speaks up for a newer version not already declined.
; mode "manual" (Check now): always reports, and offers a declined version again.
RfUpdCheck(mode) {
	global
	local base, txt, code, info, msg, notes
	if (RfUpdBusy)
		return
	if (MacroRunning or MacroPreview)
		{
		if (mode = "manual")
			RfUpdSay("Stop fishing first, then check again.")
		return
		}
	RfUpdBusy := true
	RfUpdSay("Checking the " . UpdateChannel . " channel ...")
	base := RfUpdBase(UpdateChannel)
	txt := ""
	code := RfHttpGet(base . "version.txt?t=" . A_Now . A_MSec, txt)
	info := (code = 200) ? RfUpdParse(txt) : ""
	if (!IsObject(info) or info.version = "")
		{
		RfUpdSay("Could not reach GitHub" . (code ? " (HTTP " . code . ")" : "") . ". Try Check now later.")
		RfUpdBusy := false
		return
		}
	if (RfVerCmp(info.version, RfVersion) <= 0)
		{
		RfUpdSay("Up to date  ·  " . RfVersion . " is the newest on " . UpdateChannel . "  ·  checked " . A_Hour . ":" . A_Min)
		RfUpdBusy := false
		return
		}
	RfUpdSay(info.version . " is available on " . UpdateChannel . "  (you have " . RfVersion . ")")
	if (mode = "auto" and info.version = UpdateSkipped)
		{
		RfUpdBusy := false
		return
		}
	notes := Trim(StrReplace(info.notes, "|", "`n"))
	msg := "Re:Fisch " . info.version . " is out on the " . UpdateChannel . " channel (you have " . RfVersion . ")."
		. ((notes != "") ? "`n`n" . notes : "") . "`n`nUpdate now? Re:Fisch restarts; your settings and profiles are kept."
	Gui, 1:+OwnDialogs
	MsgBox, 0x24, Re:Fisch update, %msg%
	IfMsgBox, Yes
		{
		msg := RfUpdInstall(base, info)          ; reloads on success, so this is an error
		RfUpdSay("Update failed: " . msg)
		Gui, 1:+OwnDialogs
		MsgBox, 0x30, Re:Fisch update, % "The update was not installed:`n`n" . msg
		}
	else
		{
		UpdateSkipped := info.version
		IniWrite, %UpdateSkipped%, %SettingsFile%, Updates, Skipped
		}
	RfUpdBusy := false
}

; Downloads, checks and installs; on success it reloads into the new version, otherwise it returns
; what went wrong (the running file is untouched unless the final move succeeded).
RfUpdInstall(base, info) {
	global
	local file, tmp, code, txt, m, m1, log, bakDir
	file := (info.file != "") ? info.file : "Re-Fisch.ahk"
	if (RegExMatch(file, "[\\/:*?""<>|]") or InStr(file, ".."))
		return "version.txt names an odd file (" . file . ")."
	tmp := A_ScriptFullPath . ".download"
	FileDelete, %tmp%
	RfUpdSay("Downloading " . info.version . " ...")
	txt := ""
	code := RfHttpGet(base . file . "?t=" . A_Now . A_MSec, txt, tmp)
	if (code != 200 or !FileExist(tmp))
		{
		FileDelete, %tmp%
		return "the download failed" . (code ? " (HTTP " . code . ")" : "") . "."
		}
	FileRead, txt, %tmp%
	if (!RegExMatch(txt, "m)^RfVersion := ""([^""]+)""", m) or m1 != info.version)
		{
		FileDelete, %tmp%
		return "GitHub is still updating its copy. Try again in a few minutes."
		}
	txt := ""
	log := A_Temp . "\ReFisch_update_check.txt"
	RunWait, % """" . A_AhkPath . """ /ErrorStdOut /iLib """ . log . """ """ . tmp . """", , Hide UseErrorLevel
	if (ErrorLevel != 0)
		{
		FileDelete, %tmp%
		return "the new version did not pass the load check (code " . ErrorLevel . ")."
		}
	if (GuiAutoSave)
		gosub, RfSaveQuiet
	bakDir := RfDataDir . "\backup"
	if !InStr(FileExist(bakDir), "D")
		FileCreateDir, %bakDir%
	FileCopy, %A_ScriptFullPath%, % bakDir . "\Re-Fisch " . RfVersion . ".ahk", 1
	FileMove, %tmp%, %A_ScriptFullPath%, 1
	if (ErrorLevel)
		{
		FileDelete, %tmp%
		return "could not replace " . A_ScriptName . " (open in an editor, or OneDrive syncing?)."
		}
	IniDelete, %SettingsFile%, Updates, Skipped
	Reload
	Sleep, 2000
	return "Re:Fisch did not restart. Start it again by hand."
}

; GET url with short timeouts. Returns the HTTP status (0 = no connection). The body goes to text,
; or byte-for-byte to the file saveTo when given.
RfHttpGet(url, ByRef text, saveTo := "") {
	try
		{
		r := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		r.SetTimeouts(5000, 5000, 5000, 20000)
		r.Open("GET", url, false)
		r.SetRequestHeader("Cache-Control", "no-cache")
		r.SetRequestHeader("User-Agent", "ReFisch-Updater")
		r.Send()
		code := r.Status
		if (code != 200)
			return code
		if (saveTo = "")
			text := r.ResponseText
		else
			{
			st := ComObjCreate("ADODB.Stream")
			st.Type := 1
			st.Open()
			st.Write(r.ResponseBody)
			st.SaveToFile(saveTo, 2)
			st.Close()
			}
		return 200
		}
	catch
		return 0
}

; "key=value" lines into an object (version, file, notes).
RfUpdParse(txt) {
	info := {}
	txt := StrReplace(txt, Chr(0xFEFF))
	Loop, Parse, txt, `n, `r
		{
		p := InStr(A_LoopField, "=")
		if (p > 1)
			info[Trim(SubStr(A_LoopField, 1, p - 1))] := Trim(SubStr(A_LoopField, p + 1))
		}
	return info
}

; > 0 when version a is newer than b, < 0 when older, 0 when equal. Stage first (Alpha < Beta <
; none), then each number: "Alpha 2.10" is newer than "Alpha 2.9".
RfVerCmp(a, b) {
	sa := InStr(a, "Alpha") ? 1 : InStr(a, "Beta") ? 2 : 3
	sb := InStr(b, "Alpha") ? 1 : InStr(b, "Beta") ? 2 : 3
	if (sa != sb)
		return sa - sb
	ma := "", mb := ""
	RegExMatch(a, "\d+(\.\d+)*", ma)
	RegExMatch(b, "\d+(\.\d+)*", mb)
	pa := StrSplit(ma, "."), pb := StrSplit(mb, ".")
	Loop, % Max(pa.Length(), pb.Length())
		{
		x := (pa[A_Index] = "") ? 0 : pa[A_Index] + 0
		y := (pb[A_Index] = "") ? 0 : pb[A_Index] + 0
		if (x != y)
			return (x > y) ? 1 : -1
		}
	return 0
}

RfRepaint2:
gosub, RfRepaint
return

RfRepaint:
GuiControl, 1:, RfAboutDraw, % RfDrawNote()
if (!DllCall("IsWindowVisible", "Ptr", GuiHwnd))
	return
Sleep, 20          ; the colour handler only runs once this thread is ~15 ms old
DllCall("RedrawWindow", "Ptr", GuiHwnd, "Ptr", 0, "Ptr", 0, "UInt", 0x0587)
RfHomeRefresh(true)
return

RfOpenDataDir:
Run, explore "%RfDataDir%"
return

RfMakeShortcut:
RfLnkName := "Re" . Chr(0xA789) . "Fisch.lnk"
FileCreateShortcut, %A_ScriptFullPath%, %A_Desktop%\%RfLnkName%, %A_ScriptDir%, , Re:Fisch fishing macro, %ReFishIcoPath%
RfLnkErr := ErrorLevel
FileCreateShortcut, %A_ScriptFullPath%, %A_ScriptDir%\%RfLnkName%, %A_ScriptDir%, , Re:Fisch fishing macro, %ReFishIcoPath%
RfStyle[hRfSaveStatus] := {bg: RfBrushPanel, fg: (RfLnkErr or ErrorLevel) ? ColorRedBGR : ColorGreenBGR}
GuiControl, 1:, RfSaveStatus, % (RfLnkErr or ErrorLevel) ? "Could not create the shortcut" : "✓  Shortcut created"
SetTimer, RfClearSaveStatus, -4000
return

; ------------------------------------------------------------------------------------------------
; Tabs and hover.
; ------------------------------------------------------------------------------------------------
RfTabClick:
RfClicked := SubStr(A_GuiControl, 6)
if (RfClicked = "" or RfClicked = RfActiveTab)
	return
RfActiveTab := RfClicked
gosub, RfShowTab
return

RfShowTab:
for RfTn, RfTh in RfTabH
	RfRepaintState(RfTh)
TargetSection := (RfActiveTab = "Fishing") ? "Minigame" : RfActiveTab
gosub, RfRefreshDerived
RfApplyVisibility()
RfHomeRefresh(true)
return

RfSetWindowIcons(h) {
	global ReFishIcoPath
	if (!FileExist(ReFishIcoPath))
		return
	big := DllCall("GetSystemMetrics", "Int", 11)
	small := DllCall("GetSystemMetrics", "Int", 49)
	hb := DllCall("LoadImage", "Ptr", 0, "Str", ReFishIcoPath, "UInt", 1, "Int", big, "Int", big, "UInt", 0x10, "Ptr")
	hs := DllCall("LoadImage", "Ptr", 0, "Str", ReFishIcoPath, "UInt", 1, "Int", small, "Int", small, "UInt", 0x10, "Ptr")
	if (hb)
		DllCall("SendMessage", "Ptr", h, "UInt", 0x80, "Ptr", 1, "Ptr", hb)
	if (hs)
		DllCall("SendMessage", "Ptr", h, "UInt", 0x80, "Ptr", 0, "Ptr", hs)
}

RfHoverTick:
if (MacroRunning or !DllCall("IsWindowVisible", "Ptr", GuiHwnd))
	{
	if (RfHoverCtl)
		{
		RfOld := RfHoverCtl
		RfHoverCtl := 0
		gosub, RfHoverPaint
		}
	RfTipHide()
	return
	}
MouseGetPos, , , RfOverWin, RfOverCtl, 2
if (RfOverWin != GuiHwnd)
	RfOverCtl := 0
if (RfOverCtl != RfHoverCtl)
	{
	RfOld := RfHoverCtl
	RfHoverCtl := RfOverCtl
	gosub, RfHoverPaint
	RfTipHover(RfHoverCtl)
	}
return

; Setting help (new in Alpha 1.1): the text a field, list or switch was built with (RfTips) shows
; under it after the mouse rests on it for 450 ms, and goes when the mouse leaves. Until 1.1 the
; texts were kept but never shown. Tooltip 4, placed under the control so it is never under the
; mouse (the hover check would see the tooltip and take it down again).
RfTipHover(h) {
	global RfTips, RfTipFor
	RfTipHide()
	if (h and IsObject(RfTips) and RfTips.HasKey(h))
		{
		RfTipFor := h
		SetTimer, RfTipShow, -450
		}
}

RfTipHide() {
	global RfTipFor, RfTipUp
	if (!RfTipFor and !RfTipUp)
		return
	RfTipFor := 0
	SetTimer, RfTipShow, Off
	if (RfTipUp)
		ToolTip, , , , 4
	RfTipUp := false
}

RfTipShow:
if (!RfTipFor or RfTipFor != RfHoverCtl or MacroRunning)
	return
WinGetPos, RfTipX, RfTipY, , RfTipH, ahk_id %RfTipFor%
CoordMode, ToolTip, Screen
ToolTip, % RfTips[RfTipFor], RfTipX, RfTipY + RfTipH + 4, 4
RfTipUp := true
return

; Drawn controls (buttons, tabs, Start) swap to their hover look; nothing else is repainted.
RfHoverPaint:
for RfHi, RfHh in [RfOld, RfHoverCtl]
	{
	if (RfHh)
		RfRepaintState(RfHh)
	}
return

; A drawn switch was clicked: flip its hidden CheckBox and post the CheckBox's own click notice,
; so its g-label (RfChanged, RfAutoSaveToggle) runs with A_GuiControl set to the setting.
RfSwitchClick:
RfSwC := RfSwChk[A_GuiControl]
if (!RfSwC)
	return
RfSwSt := DllCall("SendMessage", "Ptr", RfSwC, "UInt", 0xF0, "Ptr", 0, "Ptr", 0, "Ptr")
DllCall("SendMessage", "Ptr", RfSwC, "UInt", 0xF1, "Ptr", (RfSwSt = 1) ? 0 : 1, "Ptr", 0)
RfSwSync()
DllCall("PostMessage", "Ptr", GuiHwnd, "UInt", 0x111, "Ptr", DllCall("GetDlgCtrlID", "Ptr", RfSwC, "Int") & 0xFFFF, "Ptr", RfSwC)
return

; ------------------------------------------------------------------------------------------------
; Change handling: every bound control lands here.
; ------------------------------------------------------------------------------------------------
RfChanged:
RfDupFrom[A_GuiControl] := true
RfDupLast := A_GuiControl
if (RfIsEdit.HasKey(A_GuiControl))
	{
	SetTimer, RfCommitEdits, -700
	return
	}
RfPrevRod := SpecialRod
RfPrevSkin := StellarSkin
gosub, RfSubmitChecked
RfUtilSave()
if (A_GuiControl = "SpecialRod" and SpecialRod != RfPrevRod)
	{
	gosub, SpecialRodChanged
	return
	}
if (A_GuiControl = "StellarSkin" and StellarSkin != RfPrevSkin)
	{
	if (MacroRunning)
		{
		StellarSkin := RfPrevSkin
		GuiControl, 1:ChooseString, StellarSkin, %StellarSkin%
		return
		}
	KittyKeysEnabled := (StellarSkin = "Kitty Keys")
	SwFightReset()
	}
if (A_GuiControl = "GuiAlwaysOnTop" or A_GuiControl = "RfDupGuiAlwaysOnTop")
	Gui, % "1:" . (GuiAlwaysOnTop ? "+" : "-") . "AlwaysOnTop"
if (A_GuiControl = "UpdateAuto" or A_GuiControl = "UpdateChannel")
	RfUpdSaveIni()

if (A_GuiControl = "SpecialRod" or A_GuiControl = "StellarSkin" or A_GuiControl = "ControlMode" or A_GuiControl = "CastMode")
	{
	gosub, RfRefreshDerived
	RfApplyVisibility()
	}
RfHomeRefresh(true)
gosub, QueueAutoSave
return

; Edits: applied a moment after typing stops. A numeric field that does not hold a number
; keeps its previous value in the engine until it is fixed (the Save button reports it).
RfCommitEdits:
gosub, RfSubmitChecked
RfUtilSave()
RfHomeRefresh(true)
gosub, RefreshSwatches
if (SpecialRod = "Stellarwave Melody")
	SwApplyColours()
gosub, QueueAutoSave
return

RfSubmitChecked:
RfSnap := {}
for RfFi, RfF in ProfileFields
	{
	RfK := RfF[2]
	RfSnap[RfK] := %RfK%
	}
Gui, 1:Submit, NoHide
RfDupPull()
RfBadNow := ""
for RfFi, RfF in ProfileFields
	{
	if (RfF[4] != "num")
		continue
	RfK := RfF[2]
	RfVal := %RfK%
	if RfVal is not number
		{
		%RfK% := RfSnap[RfK]
		RfBadNow .= RfK . " "
		}
	}
RfDupPush()
RfBadN := RfMarkBad(RfBadNow)
if (RfBadN)
	{
	RfStyle[hRfSaveStatus] := {bg: RfBrushPanel, fg: ColorAmberBGR}
	GuiControl, 1:, RfSaveStatus, % (RfBadN = 1) ? "Fix the red field" : "Fix the " . RfBadN . " red fields"
	RfBadShown := true
	}
else if (RfBadShown)
	{
	RfBadShown := false
	GuiControl, 1:, RfSaveStatus,
	}
return

; Draws the Edits of the variables in names (separated by spaces; also their Home copies) red
; and every other one normal again. Returns how many are red.
RfMarkBad(names) {
	global RfBadH, RfEditH
	now := {}, n := 0
	Loop, Parse, names, %A_Space%
		{
		if (A_LoopField = "")
			continue
		for i, k in [A_LoopField, "RfDup" . A_LoopField]
			if (IsObject(RfEditH) and RfEditH.HasKey(k) and !now.HasKey(RfEditH[k]))
				now[RfEditH[k]] := true, n += 1
		}
	if (!IsObject(RfBadH))
		RfBadH := {}
	for h in RfBadH
		if (!now.HasKey(h))
			DllCall("InvalidateRect", "Ptr", h, "Ptr", 0, "Int", true)
	for h in now
		if (!RfBadH.HasKey(h))
			DllCall("InvalidateRect", "Ptr", h, "Ptr", 0, "Int", true)
	RfBadH := now
	return n
}

; Home shows several Settings / Utilities switches a second time (RfDupPairs, set up in
; RfBuildGui). After a Submit both copies hold what their own control shows; RfDupPull takes the
; side that was just changed (RfDupFrom) into the real variable, RfDupPush then writes it into the
; other control. Only pairs that differ are touched, so writing a control can't start a loop.
RfDupPull() {
	global
	local i, p, v, d, a, b
	for i, p in RfDupPairs
		{
		v := p[1], d := "RfDup" . v
		a := %v%, b := %d%
		if (p[2] = "chk")
			a := a ? 1 : 0, b := b ? 1 : 0
		if (a == b)
			continue
		if (RfDupFrom.HasKey(d) and (!RfDupFrom.HasKey(v) or RfDupLast = d))
			{
			%v% := %d%
			RfDupSide[v] := "real"
			}
		else
			{
			%d% := %v%
			RfDupSide[v] := "dup"
			}
		}
}

RfDupPush() {
	global
	local i, p, v, d, c
	for i, p in RfDupPairs
		{
		v := p[1], d := "RfDup" . v
		if (!RfDupSide.HasKey(v))
			continue
		c := (RfDupSide[v] = "real") ? v : d
		%d% := %v%
		if (p[2] = "chk")
			GuiControl, 1:, %c%, % %v% ? 1 : 0
		else
			GuiControl, 1:, %c%, % %v%
		}
	RfDupSide := {}
	RfDupFrom := {}
}

; After a profile is loaded: every Home copy shows the real value again.
RfSyncDups() {
	global
	RfDupFrom := {}
	RfDupPull()
	RfDupPush()
}

; Called by SpecialRodChanged (kept engine logic) after presets are applied.
RfRodChangedUi:
gosub, RfRefreshDerived
RfApplyVisibility()
RfHomeRefresh(true)
return

QueueAutoSave:
if (GuiAutoSave)
	SetTimer, RfSaveQuiet, -900
return

RfAutoSaveToggle:
Gui, 1:Submit, NoHide
IniWrite, %GuiAutoSave%, %SettingsFile%, GUI, AutoSave
if (GuiAutoSave)
	gosub, RfSaveQuiet
return

RefreshControlModes:
if (SpecialRod = "Noiseform")
	CmList := "Precision"
else if (SpecialRod = "Darkheart" or SpecialRod = "Pinions Aria" or SpecialRod = "Lullaby" or SpecialRod = "Castbound")
	CmList := "Lines"
else if (SpecialRod = "Remembrance")
	CmList := "Lines|Precision"
else if (SpecialRod = "MiguRod" or SpecialRod = "Halibut Harpoon" or SpecialRod = "Tryhard Rod" or SpecialRod = "Stellarwave Melody")
	CmList := "Precision"
else if (SpecialRod = "Requiem" or SpecialRod = "Bellona's Waraxe" or SpecialRod = "Dreambreaker" or SpecialRod = "Verdant Oath")
	CmList := "Lines|Precision"
else
	CmList := "Manual|Precision|Lines"
if (!InStr("|" . CmList . "|", "|" . ControlMode . "|"))
	{
	RfSp := InStr(CmList, "|")
	ControlMode := RfSp ? SubStr(CmList, 1, RfSp - 1) : CmList
	}
if (ControlModeDdl)
	{
	GuiControl, 1:, ControlMode, % "|" . CmList
	GuiControl, 1:ChooseString, ControlMode, %ControlMode%
	}
gosub, CMApplyTargets
return

; Derived texts: rod note, Kitty kernel status.
RfRefreshDerived:
RfNote := ""
if (SpecialRod = "None")
	RfNote := "Any rod without its own minigame. Reel control and colors are on the Fishing tab."
else if (SpecialRod = "Stellarwave Melody")
	RfNote := (StellarSkin = "Kitty Keys") ? "Kitty Keys skin: Space steers the bar while the mouse clicks the zodiac signs. Keep the cursor free (no shift lock)." : "Clicks the zodiac signs in the order shown above the bar, then reels. Keep the cursor free (no shift lock)."
else
	RfNote := SpecialRod . " runs on its built-in handling. Reel control is set for it automatically."
GuiControl, 1:, RfRodNote, %RfNote%
RfKiTxt := "Speed kernels:  " . ((KittyMcState = 1) ? "ON  (machine-code glyph and marker scans)" : "OFF  (32-bit AutoHotkey or self-test failed; original scans used)")
RfKiTxt .= "`nSigns are matched in one frame and the cursor follows a sign that moves while hovering."
GuiControl, 1:, RfKittyInfo, %RfKiTxt%
return

; Colour swatches next to the colour lists (also called by the F9 picker and presets).
RefreshSwatches:
for RfSi, RfSk in ["FishColor", "BarLeftColor", "BarRightColor", "ArrowColor"]
	{
	RfSv := %RfSk%
	RfHex := RfColCount(RfSv) ? Format("{:06X}", RfColFirst(RfSv)) : "202020"
	GuiControl, % "1:+Background" . RfHex, %RfSk%Swatch
	}
return

; After the F9 picker closes: refresh every colour field it can have changed.
RfAfterPick:
for RfPi, RfPk in ["FishColor", "BarLeftColor", "BarRightColor", "ArrowColor", "StellarBarColors", "StellarFishColors", "StellarHeadColors"]
	{
	RfPv := %RfPk%
	GuiControl, 1:, %RfPk%, %RfPv%
	}
if (SpecialRod = "Stellarwave Melody")
	SwApplyColours()
gosub, RefreshSwatches
RfActiveTab := (SpecialRod = "Stellarwave Melody") ? "Rod" : "Fishing"
gosub, RfShowTab
return

; ------------------------------------------------------------------------------------------------
; Save / profiles.
; ------------------------------------------------------------------------------------------------
RfSave:
RfSaveLoud := true
gosub, RfSaveCore
return

RfSaveQuiet:
RfSaveLoud := false
gosub, RfSaveCore
return

RfSaveCore:
Gui, 1:Submit, NoHide
RfDupPull()
RfDupPush()
RfBad := ""
for RfFi, RfF in ProfileFields
	{
	RfK := RfF[2]
	if (RfF[4] = "num")
		{
		RfVal := %RfK%
		if RfVal is not number
			RfBad .= RfK . "  "
		}
	}
for RfFi, RfK in ["StartStopKeyCtrl", "ReloadKeyCtrl", "ExitKeyCtrl"]
	{
	RfVal := %RfK%
	if (RfVal = "" or (!GetKeyVK(RfVal) and !GetKeySC(RfVal)))
		RfBad .= RfK . "  "
	}
RfMarkBad(RfBad)
RfBadShown := (RfBad != "")
if (RfBad != "")
	{
	GuiControl, 1:, RfSaveStatus, Not saved: fix the red fields
	RfStyle[hRfSaveStatus] := {bg: RfBrushPanel, fg: ColorRedBGR}
	if (RfSaveLoud)
		MsgBox, 4144, Re:Fisch, These fields need a valid number or key and were not saved:`n`n%RfBad%
	SetTimer, RfClearSaveStatus, -4000
	return
	}
FileCopy, %ActiveProfileFile%, %ActiveProfileFile%.bak, 1
for RfFi, RfF in ProfileFields
	{
	RfSec := RfF[1]
	RfK := RfF[2]
	RfVal := %RfK%
	if (RfF[4] = "bool")
		RfVal := RfVal ? "true" : "false"
	RfDst := (RfSec = "Aquarium" or RfSec = "Keeper" or (TotemGlobal and RfSec = "Totem")) ? SettingsFile : ActiveProfileFile
	IniWrite, %RfVal%, %RfDst%, %RfSec%, %RfK%
	}
RfHkState := HotkeysArmed ? "On" : "Off"
if (StartStopKeyCtrl != StartStopKey)
	{
	Hotkey, % "$" . StartStopKey, , Off
	StartStopKey := StartStopKeyCtrl
	Hotkey, % "$" . StartStopKey, RfKeyStart, %RfHkState%
	}
if (ReloadKeyCtrl != ReloadKey)
	{
	Hotkey, % "$" . ReloadKey, , Off
	ReloadKey := ReloadKeyCtrl
	Hotkey, % "$" . ReloadKey, RfKeyReload, Off
	RunKeysArmed := false
	RfSyncRunKeys()
	}
if (ExitKeyCtrl != ExitKey)
	{
	Hotkey, % "$" . ExitKey, , Off
	ExitKey := ExitKeyCtrl
	Hotkey, % "$" . ExitKey, RfKeyExit, Off
	RunKeysArmed := false
	RfSyncRunKeys()
	}
IniWrite, %StartStopKey%, %SettingsFile%, Hotkeys, StartStop
IniWrite, %ReloadKey%, %SettingsFile%, Hotkeys, Reload
IniWrite, %ExitKey%, %SettingsFile%, Hotkeys, Exit
RfVal := GuiAlwaysOnTop ? 1 : 0
IniWrite, %RfVal%, %SettingsFile%, GUI, AlwaysOnTop
RfVal := GuiKeepOpen ? 1 : 0
IniWrite, %RfVal%, %SettingsFile%, GUI, KeepOpen

RfStyle[hRfSaveStatus] := {bg: RfBrushPanel, fg: ColorGreenBGR}
GuiControl, 1:, RfSaveStatus, % "✓  Saved  " . A_Hour . ":" . A_Min
gosub, RfFooterText
SetTimer, RfClearSaveStatus, -4000
return

RfClearSaveStatus:
GuiControl, 1:, RfSaveStatus,
return

RfFooterText:
GuiControl, 1:, RfAboutProfile, %ActiveProfile%
GuiControl, 1:, RfFootProfile, % "Profile:  " . ActiveProfile . "     ·     F9 picks colors"
for RfKi, RfKb in [[hRfReloadBtn, ReloadKey], [hRfExitBtn, ExitKey]]
	{
	if (RfPaintSpec.HasKey(RfKb[1]) and RfPaintSpec[RfKb[1]].hint != RfKb[2])
		{
		RfPaintSpec[RfKb[1]].hint := RfKb[2]
		RfPaint(RfKb[1])
		}
	}
return

RefreshProfileList:
ProfileNames := "|"
Loop, Files, %ProfilesDir%\*.ini
	{
	SplitPath, A_LoopFileName, , , , RfNameNoExt
	ProfileNames .= RfNameNoExt . "|"
	}
GuiControl, 1:, ProfileSelect, %ProfileNames%
GuiControl, 1:ChooseString, ProfileSelect, %ActiveProfile%
return

; Pushes every profile value back into its control (after switching or importing a profile).
RefreshGuiFields:
for RfFi, RfF in ProfileFields
	{
	RfK := RfF[2]
	RfVal := %RfK%
	if (RfF[4] = "bool")
		GuiControl, 1:, %RfK%, % RfVal ? 1 : 0
	else if (RfF[4] = "shakemode" or RfF[4] = "controlmode" or RfF[4] = "castmode" or RfF[4] = "specialrod"
		or RfF[4] = "remembrancemode" or RfF[4] = "stellarskin" or RfF[4] = "kittyspeed")
		GuiControl, 1:ChooseString, %RfK%, %RfVal%
	else if (RfF[4] != "totemsel")
		GuiControl, 1:, %RfK%, %RfVal%
	}
gosub, RefreshControlModes
gosub, RefreshSwatches
gosub, RfFooterText
gosub, RfRefreshDerived
RfSyncDups()
RfApplyVisibility()
RfHomeRefresh(true)
return

RfProfileSelect:
GuiControlGet, RfNewProfile, 1:, ProfileSelect
if (RfNewProfile = "" or RfNewProfile = ActiveProfile)
	return
ActiveProfile := RfNewProfile
ActiveProfileFile := ProfilesDir . "\" . ActiveProfile . ".ini"
IniWrite, %ActiveProfile%, %SettingsFile%, Profiles, ActiveProfile
gosub, LoadActiveProfile
gosub, RfUtilitiesOff
gosub, RefreshGuiFields
return

RfProfileNew:
RfDupFrom := ""
gosub, RfProfileCreate
return

RfProfileDuplicate:
RfDupFrom := ActiveProfileFile
gosub, RfProfileCreate
return

RfProfileCreate:
Gui, 1:-AlwaysOnTop
InputBox, RfNewName, Re:Fisch, % (RfDupFrom = "" ? "Name for the new profile:" : "Name for the copy of " . ActiveProfile . ":"), , 300, 130
if (GuiAlwaysOnTop)
	Gui, 1:+AlwaysOnTop
if ErrorLevel
	return
RfNewName := Trim(RfNewName)
if (RfNewName = "")
	return
if RegExMatch(RfNewName, "[\\/:*?""<>|]")
	{
	MsgBox, 4144, Re:Fisch, Profile names can't contain \ / : * ? " < > |
	return
	}
RfNewFile := ProfilesDir . "\" . RfNewName . ".ini"
if FileExist(RfNewFile)
	{
	MsgBox, 4144, Re:Fisch, A profile named "%RfNewName%" already exists.
	return
	}
if (RfDupFrom != "")
	{
	gosub, RfSaveQuiet
	FileCopy, %RfDupFrom%, %RfNewFile%, 0
	}
else
	{
	for RfFi, RfF in ProfileFields
		{
		RfSec := RfF[1]
		RfK := RfF[2]
		RfVal := RfF[3]
		IniWrite, %RfVal%, %RfNewFile%, %RfSec%, %RfK%
		}
	}
ActiveProfile := RfNewName
ActiveProfileFile := RfNewFile
IniWrite, %ActiveProfile%, %SettingsFile%, Profiles, ActiveProfile
gosub, LoadActiveProfile
gosub, RfUtilitiesOff
gosub, RefreshProfileList
gosub, RefreshGuiFields
return

RfProfileDelete:
RfCount := 0
Loop, Files, %ProfilesDir%\*.ini
	RfCount++
if (ActiveProfile = "Default")
	{
	MsgBox, 4144, Re:Fisch, The Default profile can't be deleted.
	return
	}
if (RfCount <= 1)
	{
	MsgBox, 4144, Re:Fisch, You can't delete the only profile.
	return
	}
MsgBox, 4100, Re:Fisch, Delete profile "%ActiveProfile%"? This can't be undone.
IfMsgBox, No
	return
FileDelete, %ActiveProfileFile%
ActiveProfile := "Default"
ActiveProfileFile := DefaultProfileFile
IniWrite, %ActiveProfile%, %SettingsFile%, Profiles, ActiveProfile
gosub, LoadActiveProfile
gosub, RfUtilitiesOff
gosub, RefreshProfileList
gosub, RefreshGuiFields
return

RfImportButton:
MsgBox, 4100, Re:Fisch, Copy profiles and settings from a DeepFish / Re:Fisch fork folder next to this script?`n`nProfiles with the same name are replaced.
IfMsgBox, No
	return
RfImportOverwrite := 1
gosub, RfImportFork
if (RfImported = "")
	{
	MsgBox, 4144, Re:Fisch, No fork folder was found next to this script.`n`nPut this script in the same folder as your DeepFish / Re:Fisch fork (the one with Profiles-KittyKeys or Profiles), then try again.
	return
	}
gosub, LoadSettingsFile
gosub, LoadActiveProfile
gosub, RfUtilitiesOff
gosub, RefreshProfileList
gosub, RefreshGuiFields
GuiControl, 1:, RfSaveStatus, Imported fork settings
SetTimer, RfClearSaveStatus, -5000
return

; ------------------------------------------------------------------------------------------------
; Window.
; ------------------------------------------------------------------------------------------------
RefreshRunChip:
RfSyncRunKeys()
RfRunPaint()
return

; Sidebar chip and Start button for the current run state (idle, waiting for the key, running).
RfRunPaint(force := false) {
	global
	local st, c, b, sig
	if (!hRunStatus)
		return
	st := MacroRunning ? "run" : (MacroPreview ? "wait" : "idle")
	sig := st . "|" . StartStopKey
	if (!force and sig = RfRunPaintSig)
		return
	RfRunPaintSig := sig
	c := RfPaintSpec[hRunStatus], b := RfPaintSpec[hStartStopBtnHwnd]
	if (st = "run")
		{
		c.text := "Running"
		c.looks := {n: {fill: RfMix(ColorPanel, ColorGreen, 0.14), edge: RfMix(ColorPanel, ColorGreen, 0.45), fg: ColorGreen, dot: ColorGreen}}
		RfBtnSetText(b, "■  Stop")
		b.looks := {n: {fill: ColorAccent, fg: "FFFFFF", ifg: "FFFFFF"}, h: {fill: "F0646A", fg: "FFFFFF", ifg: "FFFFFF"}}
		}
	else if (st = "wait")
		{
		c.text := "Waiting for  " . StartStopKey
		c.looks := {n: {fill: RfMix(ColorPanel, ColorAmber, 0.14), edge: RfMix(ColorPanel, ColorAmber, 0.45), fg: ColorAmber, dot: ColorAmber}}
		RfBtnSetText(b, "✕  Cancel")
		b.looks := {n: {fill: ColorAmber, fg: "101010", ifg: "101010"}, h: {fill: "FFC95A", fg: "101010", ifg: "101010"}}
		}
	else
		{
		c.text := "Idle"
		c.looks := {n: {fill: "1C1C20", edge: ColorEdge, fg: ColorMuted, dot: ColorDim}}
		RfBtnSetText(b, "▶  Start")
		b.looks := {n: {fill: ColorStart, fg: "101010", ifg: "101010"}, h: {fill: "FFFFFF", fg: "101010", ifg: "101010"}}
		}
	b.hint := StartStopKey
	c.state := "n"
	b.state := RfPaintState(hStartStopBtnHwnd)
	RfPaint(hRunStatus)
	RfPaint(hStartStopBtnHwnd)
}

ShowGuiFromTray:
RfDisarmKeys()
if (!MacroRunning)
	MacroPreview := false
Gui, 1:Show
gosub, RefreshRunChip
SetTimer, RfRepaint, -150
return

GuiClose:
gosub, DoExit
return

GuiEscape:
return

ClearIconTip:
ToolTip, , , , 3
return

;====================================================================================================;
;   Status overlay, "ready" banner, live dashboard and session stats (new).
;   The engine's status lines are plain variables (RfTip1..RfTip20, formerly tooltips 1-20).
;   One 10 Hz timer turns them into a compact overlay over Roblox and feeds the Home tab.
;   Catches are read from Fisch's own message (rf_catch.ahk).
;====================================================================================================;

RfTipClear(n) {
	global
	RfTip%n% := ""
}

RfSet(var, txt, force := false) {
	static last := ""
	if (!IsObject(last))
		last := {}
	if (!force and last.HasKey(var) and last[var] == txt)
		return
	last[var] := txt
	GuiControl, 1:, %var%, %txt%
}

RfFmtTime(ms, short := false) {
	s := ms // 1000
	h := s // 3600
	m := Mod(s // 60, 60)
	s := Mod(s, 60)
	if (short)
		return (h ? h . ":" . (m < 10 ? "0" : "") : "") . m . ":" . (s < 10 ? "0" : "") . s
	return h . "h " . (m < 10 ? "0" : "") . m . "m " . (s < 10 ? "0" : "") . s . "s"
}

; Stats belong to one fishing session: they start from zero when fishing starts, stay on screen
; after a stop, and are kept across a reload (Re-Fisch\session.ini). No fish counting (removed in
; build 2.7): casts, reel fights, time-outs and session time.
RfSesFields() {
	static f := ["RfSesCasts", "RfSesFights", "RfSesFail", "RfSesTrackLost", "RfSesRunMs", "RfSesLastTxt"]
	return f
}

RfSessionBegin() {
	global
	local i, k
	for i, k in RfSesFields()
		%k% := (k = "RfSesLastTxt") ? "-" : 0
	RfSesStart := A_TickCount
	RfSesLive := true
	RfTotemBegin()
	RfSesSave()
}

RfSesSave() {
	global
	local i, k, v, f
	if (RfDataDir = "")
		return
	f := RfDataDir . "\session.ini"
	for i, k in RfSesFields()
		{
		v := %k%
		if (k = "RfSesRunMs" and RfSesLive)
			v := RfSesRunMs + A_TickCount - RfSesStart
		IniWrite, %v%, %f%, Session, %k%
		}
}

RfSesLoad() {
	global
	local i, k, v, f
	f := RfDataDir . "\session.ini"
	if (!FileExist(f))
		return
	for i, k in RfSesFields()
		{
		IniRead, v, %f%, Session, %k%, %A_Space%
		if (k = "RfSesLastTxt")
			%k% := (v = "ERROR" or v = "") ? "-" : v
		else
			{
			if v is integer
				%k% := v
			}
		}
}

; Written every few seconds while something changes, and on stop / reload / exit.
RfSesAutoSave() {
	global
	local sig
	if (A_TickCount - RfSesSaveT < 4000)
		return
	RfSesSaveT := A_TickCount
	sig := RfSesCasts . "|" . RfSesFights . "|" . RfSesFail . "|" . RfSesLive . "|" . (RfSesLive ? (A_TickCount - RfSesStart) // 10000 : 0)
	if (sig != RfSesSaveSig)
		{
		RfSesSaveSig := sig
		RfSesSave()
		}
}

RfSessionEnd() {
	global
	if (RfSesLive)
		RfSesRunMs += A_TickCount - RfSesStart
	RfSesLive := false
	RfFightT0 := 0
	RfSesSave()
}

; Casts that time out before a fight (no bite, bar never found).
RfStat(kind) {
	global
	if (kind = "shakefail" or kind = "barfail")
		RfSesFail += 1
}

RfFightStart() {
	global
	RfFightT0 := A_TickCount
}

RfFightEnd(why) {
	global
	RfSesFights += 1
	RfSesLastTxt := (RfFightT0 ? Round((A_TickCount - RfFightT0) / 1000.0, 1) . " s" : "-")
	RfFightT0 := 0
	if (why = "barlost" or why = "nofishline" or why = "nofish60")
		RfSesTrackLost += 1
}

; ------------------------------------------------------------------------------------------------
; Overlay and banner.
; ------------------------------------------------------------------------------------------------
RfOverlayBuild:
for RfOi, RfOk in RfSesFields()
	%RfOk% := (RfOk = "RfSesLastTxt") ? "-" : 0
RfSesLive := false
RfFightT0 := 0
RfUiN := 0
RfRunSig := ""
RfOcrState := ""
RfOcrLang := ""
RfWatchPid := 0
RfWatchHwnd := 0
RfHomeRbxT := 0
RfHomeRbx := false
RfSesSaveT := 0
RfSesSaveSig := ""
RfApRunning := false
RfSesLoad()
; Status overlay: one layered window, drawn with GDI+ in the main window's style (RfOvRender).
Gui, RfOv:New, +AlwaysOnTop -Caption +ToolWindow +E0x80020 +HwndhRfOv
RfOvShown := false
RfOvSig := ""
RfOvRenderAt := 0
return

RfUiTick:
RfSesAutoSave()
RfSwSync()
; ---- run state: header chip, Start button, tray tip ------------------------------------------
RfNowSig := (MacroRunning ? "run" : (MacroPreview ? "armed" : "idle")) . "|" . StartStopKey
if (RfNowSig != RfRunSig)
	{
	RfRunSig := RfNowSig
	gosub, RefreshRunChip
	if (MacroRunning)
		Menu, Tray, Tip, Re:Fisch  ·  fishing
	else if (MacroPreview)
		Menu, Tray, Tip, % "Re:Fisch  ·  waiting - press " . StartStopKey . " in Roblox to start"
	else
		Menu, Tray, Tip, Re:Fisch
	}
; ---- overlay -------------------------------------------------------------------------------
RfArmed := (MacroPreview and !MacroRunning and !RfApRunning)
RfOvDetail := ""
if (!RfArmed)
	{
	Loop, 13
		{
		RfIdx := A_Index + 7
		RfLn := RfTip%RfIdx%
		if (RfLn = "" or RegExMatch(RfLn, "^(Auto\w+|Navigation Key|Shake Mode): "))
			continue
		if (RfIdx = 7 or InStr(RfLn, "Current Task: ") = 1)
			continue
		RfLn := RegExReplace(RfLn, "^Action: ")
		RfOvDetail .= (RfOvDetail = "" ? "" : "`n") . RfLn
		}
	}
RfOvTaskTxt := RfArmed ? "Press " . StartStopKey . " to start" : StrReplace(RfTip7, "Current Task: ")
if (RfApRunning)
	{
	RfOvTaskTxt := "Appraising  ·  try " . RfApTry . " of " . RfApMaxN
	RfOvDetail := "Looking for: " . RfApTargets . "`n" . RfApLast
	}
if (!RfArmed and RfEngHold != "")
	{
	RfOvTaskTxt := "Paused"
	RfOvDetail := RfEngHold . (RfOvDetail = "" ? "" : "`n" . RfOvDetail)
	}
if (RfArmed and !RfApRunning)
	RfOvDetail := "Waiting for you in Roblox."
if (RfOvTaskTxt = "")
	RfOvTaskTxt := "Running"
RfRunMs := RfSesRunMs + (RfSesLive ? A_TickCount - RfSesStart : 0)
RfRbxOk := (RobloxHwnd and !DetTesting and !FreezeActive and WinExist("ahk_id " . RobloxHwnd))
RfOvWant := ((MacroRunning or MacroPreview or RfApRunning) and RfRbxOk and WinActive("ahk_id " . RobloxHwnd))
if (RfOvWant)
	{
	RfOvState := RfApRunning ? "appraise" : (MacroRunning ? "run" : "ready")
	RfOvTimeTxt := RfFmtTime(RfRunMs, true)
	RfOvPulse := (RfOvState = "ready") ? Mod(A_TickCount // 700, 2) : 1     ; the Ready dot breathes
	RfOvKeysTxt := StartStopKey . "|" . ReloadKey . "|" . ExitKey
	; follow the Roblox window if it moves or is maximised
	RfClientArea(RobloxHwnd, RfRx, RfRy, RfRw, RfRh)
	RfOvRect := RfRx . "|" . RfRy . "|" . RfRw . "|" . RfRh
	RfOvNewSig := RfOvState . "|" . RfOvPulse . "|" . RfOvKeysTxt . "|" . RfOvTaskTxt . "|" . RfOvDetail . "|" . RfSesCasts . "|" . RfSesFail . "|" . RfOvTimeTxt . "|" . RfOvRect
	; Layered-window drawing shares the reel thread. During a fight, render at
	; most four times a second; show/hide and the input watchdog stay responsive.
	if ((RfOvNewSig != RfOvSig or !RfOvShown) and (!RfOvShown or !MgInPlay or A_TickCount - RfOvRenderAt >= 250))
		{
		RfOvRenderAt := A_TickCount
		RfOvSig := RfOvNewSig
		RfOvX := RfRx + Round(RfRw * 0.02)
		RfOvY2 := RfRy + Round(RfRh * 0.5) - Round(180 * DpiF)
		RfOvRender(RfOvX, RfOvY2, {state: RfOvState, task: RfOvTaskTxt, detail: RfOvDetail, casts: RfSesCasts
			, fails: RfSesFail, time: RfOvTimeTxt, pulse: RfOvPulse
			, keys: [[StartStopKey, MacroRunning ? "stop" : "start"], [ReloadKey, "reload"], [ExitKey, "exit"]]})
		if (!RfOvShown)
			DllCall("ShowWindow", "Ptr", hRfOv, "Int", 4)          ; SW_SHOWNOACTIVATE
		RfOvShown := true
		}
	}
else if (RfOvShown)
	{
	Gui, RfOv:Hide
	RfOvShown := false
	}
; ---- sidebar numbers and Home status (about 3 times a second while the window is open) ----
RfUiN := Mod(RfUiN + 1, 3)
if (RfUiN = 0 and DllCall("IsWindowVisible", "Ptr", GuiHwnd))
	RfHomeRefresh(false)
if (RfUiN = 0 and RfActiveTab = "Utilities" and DllCall("IsWindowVisible", "Ptr", GuiHwnd))
	RfSet("RfTotStatus", RfTotemStatus())
return

; ------------------------------------------------------------------------------------------------
; Status overlay, drawn like the main window: a rounded panel, a "RE:FISCH" card header, a state
; chip like the sidebar's (Ready / Running / Appraising), the current task and details, three stat
; tiles and the keys as key caps. x, y are screen pixels; o holds what to show.
; ------------------------------------------------------------------------------------------------
RfOvRender(x, y, o) {
	global DpiF, hRfOv, ColorPanel, ColorCard, ColorEdge, ColorText, ColorMuted, ColorDim, ColorAccent
		, ColorGreen, ColorAmber, ColorInfo
	k := DpiF
	pw := Round(252 * k), pad := 14 * k
	lines := []
	if (o.detail != "")
		Loop, Parse, % o.detail, `n
			lines.Push(A_LoopField)
	; heights (pixels)
	yHead := 12 * k, yTask := 40 * k
	yDet := yTask + 26 * k
	yTiles := yDet + lines.Length() * 15 * k + (lines.Length() ? 8 * k : 0)
	tileH := 48 * k
	yKeys := yTiles + tileH + 10 * k
	ph := Round(yKeys + 20 * k + 12 * k)
	; surface
	VarSetCapacity(bi, 40, 0)
	NumPut(40, bi, 0, "UInt"), NumPut(pw, bi, 4, "Int"), NumPut(-ph, bi, 8, "Int")
	NumPut(1, bi, 12, "UShort"), NumPut(32, bi, 14, "UShort")
	hdcS := DllCall("GetDC", "Ptr", 0, "Ptr")
	mdc := DllCall("CreateCompatibleDC", "Ptr", hdcS, "Ptr")
	bits := 0
	hbm := DllCall("CreateDIBSection", "Ptr", mdc, "Ptr", &bi, "UInt", 0, "Ptr*", bits, "Ptr", 0, "UInt", 0, "Ptr")
	obm := DllCall("SelectObject", "Ptr", mdc, "Ptr", hbm, "Ptr")
	g := 0
	if (RfGdipStart())
		DllCall("gdiplus\GdipCreateFromHDC", "Ptr", mdc, "Ptr*", g)
	if (g)
		{
		DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", g, "Int", 4)
		DllCall("gdiplus\GdipSetTextRenderingHint", "Ptr", g, "Int", 4)
		; panel
		RfOvShape(g, 0, 0, pw, ph, 12 * k, ColorPanel, 242, ColorEdge)
		; header + state chip
		RfGdipDraw(g, "RE:FISCH", RfGdipFont("Segoe UI", 8, 1), ColorAccent, pad, 20 * k, yHead / k)
		st := o.state
		cc := (st = "run") ? ColorGreen : (st = "appraise") ? ColorInfo : ColorAmber
		ct := (st = "run") ? "Running" : (st = "appraise") ? "Appraising" : "Ready"
		cf := RfFontFor("", 8)
		cw := RfGdipTextW(g, ct, cf) + 30 * k
		cx := pw - pad - cw
		RfOvShape(g, cx, yHead - 1 * k, cw, 22 * k, 11 * k, RfMix(ColorPanel, cc, 0.14), 255, RfMix(ColorPanel, cc, 0.45))
		dot := 7 * k
		RfOvShape(g, cx + 10 * k, yHead + 10 * k - dot / 2, dot, dot, dot / 2, o.pulse ? cc : RfMix(ColorPanel, cc, 0.4), 255, "")
		RfGdipDraw(g, ct, cf, cc, cx + 22 * k, 20 * k, yHead / k)
		; task and details
		tf := RfFontFor("", 11)
		RfGdipDraw(g, RfOvFit(g, o.task, tf, pw - 2 * pad), tf, "FFFFFF", pad, 24 * k, yTask / k)
		df := RfGdipFont("Segoe UI", 8)
		for i, ln in lines
			RfGdipDraw(g, RfOvFit(g, ln, df, pw - 2 * pad), df, ColorMuted, pad, 15 * k, (yDet + (i - 1) * 15 * k) / k)
		; stat tiles
		gap := 6 * k
		tw := (pw - 2 * pad - 2 * gap) / 3
		lf := RfGdipFont("Segoe UI", 7, 1), vf := RfFontFor("", 13)
		for i, t in [["CASTS", o.casts, "FFFFFF"], ["TIME-OUTS", o.fails, ColorAmber], ["TIME", o.time, "FFFFFF"]]
			{
			tx := pad + (i - 1) * (tw + gap)
			RfOvShape(g, tx, yTiles, tw, tileH, 8 * k, ColorCard, 255, ColorEdge)
			RfGdipDraw(g, t[1], lf, ColorMuted, tx + 10 * k, 14 * k, (yTiles + 7 * k) / k)
			RfGdipDraw(g, t[2], vf, t[3], tx + 10 * k, 24 * k, (yTiles + 20 * k) / k)
			}
		; key caps
		kf := RfFontFor("", 8), nf := RfGdipFont("Segoe UI", 8)
		kx := pad
		for i, kp in o.keys
			{
			kw := Max(18 * k, RfGdipTextW(g, kp[1], kf) + 12 * k)
			RfOvShape(g, kx, yKeys, kw, 20 * k, 5 * k, "242428", 255, "34343A")
			RfGdipDraw(g, kp[1], kf, ColorText, kx + (kw - RfGdipTextW(g, kp[1], kf)) / 2, 20 * k, yKeys / k)
			kx += kw + 6 * k
			RfGdipDraw(g, kp[2], nf, ColorMuted, kx, 20 * k, yKeys / k)
			kx += RfGdipTextW(g, kp[2], nf) + 14 * k
			}
		DllCall("gdiplus\GdipDeleteGraphics", "Ptr", g)
		}
	VarSetCapacity(pt, 8), NumPut(x, pt, 0, "Int"), NumPut(y, pt, 4, "Int")
	VarSetCapacity(sz, 8), NumPut(pw, sz, 0, "Int"), NumPut(ph, sz, 4, "Int")
	VarSetCapacity(src, 8, 0)
	DllCall("UpdateLayeredWindow", "Ptr", hRfOv, "Ptr", hdcS, "Ptr", &pt, "Ptr", &sz, "Ptr", mdc, "Ptr", &src
		, "UInt", 0, "UInt*", 0x01FF0000, "UInt", 2)
	DllCall("SelectObject", "Ptr", mdc, "Ptr", obm)
	DllCall("DeleteObject", "Ptr", hbm)
	DllCall("DeleteDC", "Ptr", mdc)
	DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdcS)
}

; A rounded shape on the overlay: fill (RRGGBB) at alpha a (0-255), optional 1 px edge.
RfOvShape(g, x, y, w, ht, r, fill, a, edge) {
	path := RfGdipRoundPath(x + 0.5, y + 0.5, w - 1, ht - 1, r)
	br := 0
	DllCall("gdiplus\GdipCreateSolidFill", "UInt", (RfArgb(fill) & 0xFFFFFF) | (a << 24), "Ptr*", br)
	DllCall("gdiplus\GdipFillPath", "Ptr", g, "Ptr", br, "Ptr", path)
	DllCall("gdiplus\GdipDeleteBrush", "Ptr", br)
	if (edge != "")
		{
		pen := 0
		DllCall("gdiplus\GdipCreatePen1", "UInt", RfArgb(edge), "Float", 1.0, "Int", 2, "Ptr*", pen)
		DllCall("gdiplus\GdipDrawPath", "Ptr", g, "Ptr", pen, "Ptr", path)
		DllCall("gdiplus\GdipDeletePen", "Ptr", pen)
		}
	DllCall("gdiplus\GdipDeletePath", "Ptr", path)
}

; Text shortened with "…" until it fits maxw pixels.
RfOvFit(g, text, font, maxw) {
	if (RfGdipTextW(g, text, font) <= maxw)
		return text
	while (StrLen(text) > 1 and RfGdipTextW(g, text . "…", font) > maxw)
		text := SubStr(text, 1, -1)
	return RTrim(text) . "…"
}

; Home tab: stat tiles and the STATUS card. Runs whether or not the macro is started; force
; rewrites every field (used when the tab is opened and after a setting changes).
RfHomeRefresh(force := false) {
	global
	local runMs, task
	if (RfSesSaveSig = "" and !RfSesSaveT and RfSesLastTxt = "")
		return
	runMs := RfSesRunMs + (RfSesLive ? A_TickCount - RfSesStart : 0)
	RfSet("RfTileCasts", RfSesCasts, force)
	RfSet("RfTileFights", RfSesFights, force)
	RfSet("RfTileFails", RfSesFail, force)
	RfSet("RfTileTime", RfFmtTime(runMs, true), force)
	RfSet("RfTileCastsSub", (runMs > 60000) ? Round(RfSesCasts * 3600000.0 / runMs, 1) . " / hour" : "", force)
	RfSet("RfTileFightsSub", (RfSesLastTxt != "" and RfSesLastTxt != "-") ? "last " . RfSesLastTxt : "", force)
	RfSet("RfTileFailsSub", "no bite or bar", force)
	RfSet("RfTileTimeSub", RfSesLive ? "fishing" : "", force)
	RfSet("RfHomeRod", (SpecialRod = "None") ? "Normal rod" : SpecialRod, force)
	RfSet("RfHomeSkin", (SpecialRod = "Stellarwave Melody") ? StellarSkin : "-", force)
	RfSet("RfHomeCast", CastMode . " cast   ·   " . ((ShakeMode = "Disabled") ? "no shake" : "navigation shake"), force)
	RfSet("RfHomeReel", ControlMode . "   ·   " . RfSesTrackLost . " tracking losses", force)
	; Roblox is looked up once a second so "Doing now" is useful before Start is pressed
	if (force or A_TickCount - RfHomeRbxT > 1000)
		{
		RfHomeRbxT := A_TickCount
		RfHomeRbx := WinExist("ahk_exe RobloxPlayerBeta.exe") ? true : false
		}
	task := StrReplace(RfTip7, "Current Task: ")
	if (MacroRunning)
		task := (task != "") ? task : "running"
	else if (MacroPreview)
		task := "waiting - press " . StartStopKey . " in Roblox"
	else
		task := RfHomeRbx ? "idle  ·  Roblox is open, press Start" : "idle  ·  Roblox is not running"
	RfSet("RfHomeTask", task, force)
	RfSet("RfHomeTotem", RfTotemStatus(), force)
	if (MacroRunning and MgInPlay and PfDt > 0)
		RfSet("RfHomeLoop", Round(1000.0 / PfDt) . " fps   ·   " . PfDt . " ms per frame   ·   capture " . PfCap . " ms", force)
	else
		RfSet("RfHomeLoop", "shown while reeling", force)
}

;====================================================================================================;
;   Text reading for Auto Appraise (new). A small helper script (Re-Fisch\catch-watcher.ahk,
;   written and started here the first time Appraise needs it) reads part of the Roblox window
;   with Windows' built-in text recognition (Windows 10 / 11) and sends the text back. It runs as
;   its own process, so a slow read never stalls Re:Fisch.
;   (The fish counter that used this reader was removed in build 2.7; it may return later.)
;====================================================================================================;

RfTextReady() {
	global RfOcrState
	return (RfOcrState = "ok")
}

RfWatchStart() {
	global
	local b64, n, bin, f
	RfOcrState := ""
	RfWatchHwnd := 0
	RfWatchPath := RfDataDir . "\catch-watcher.ahk"
	b64 := RfWatchSourceB64()
	n := 0
	DllCall("Crypt32\CryptStringToBinaryW", "Str", b64, "UInt", 0, "UInt", 1, "Ptr", 0, "UInt*", n, "Ptr", 0, "Ptr", 0)
	VarSetCapacity(bin, n, 0)
	DllCall("Crypt32\CryptStringToBinaryW", "Str", b64, "UInt", 0, "UInt", 1, "Ptr", &bin, "UInt*", n, "Ptr", 0, "Ptr", 0)
	f := FileOpen(RfWatchPath, "w")
	if (IsObject(f))
		{
		f.RawWrite(bin, n)
		f.Close()
		}
	OnMessage(0x4A, "RfWatchMsg")
	RfWatchPid := 0
	Run, % """" . A_AhkPath . """ """ . RfWatchPath . """ " . (A_ScriptHwnd + 0) . " " . DllCall("GetCurrentProcessId"), %RfDataDir%, UseErrorLevel, RfWatchPid
	if (ErrorLevel or !RfWatchPid)
		RfOcrState := "off:could not start the text reader"
}

; Starts the reader if it is not running and waits until it is ready (or says why it is not).
RfTextEnsure(timeoutMs := 8000) {
	global RfWatchPid, RfOcrState, RfWatchHwnd
	if (RfWatchPid)
		{
		Process, Exist, %RfWatchPid%
		if (!ErrorLevel)
			RfWatchPid := 0, RfWatchHwnd := 0, RfOcrState := ""
		}
	if (!RfWatchPid)
		RfWatchStart()
	t0 := A_TickCount
	while (RfOcrState = "" and A_TickCount - t0 < timeoutMs)
		Sleep, 50
	return (RfOcrState = "ok" and RfWatchHwnd)
}

; WM_COPYDATA from the reader: 1 its window, 4 ready / error, 5 text read.
RfWatchMsg(wParam, lParam) {
	global
	local kind, p, txt, bar
	kind := NumGet(lParam + 0, 0, "UPtr")
	p := NumGet(lParam + 0, 2 * A_PtrSize, "Ptr")
	txt := p ? StrGet(p, "UTF-16") : ""
	if (kind = 1)
		{
		RfWatchHwnd := txt + 0
		return true
		}
	if (kind = 4)
		{
		bar := InStr(txt, "|")
		if (SubStr(txt, 1, bar - 1) = "ready")
			RfOcrState := "ok", RfOcrLang := SubStr(txt, bar + 1)
		else
			RfOcrState := "off:" . SubStr(txt, bar + 1)
		return true
		}
	if (kind = 5)
		{
		RfAreaTxt := txt
		RfAreaDone := true
		return true
		}
}

; One read of part of the Roblox window (fractions 0-1). "" if the reader is not ready.
RfOcrArea(fx, fy, fw, fh, timeoutMs := 5000) {
	global RfWatchHwnd, RobloxHwnd, RfAreaTxt, RfAreaDone, RfOcrState
	if (!RfWatchHwnd or RfOcrState != "ok" or !RobloxHwnd)
		return ""
	RfAreaDone := false
	RfAreaTxt := ""
	DllCall("PostMessage", "Ptr", RfWatchHwnd, "UInt", 0x8011, "Ptr", 0, "Ptr", RobloxHwnd)
	DllCall("PostMessage", "Ptr", RfWatchHwnd, "UInt", 0x8013
		, "Ptr", (Round(fx * 10000) << 16) | Round(fy * 10000), "Ptr", (Round(fw * 10000) << 16) | Round(fh * 10000))
	t0 := A_TickCount
	while (!RfAreaDone and A_TickCount - t0 < timeoutMs)
		Sleep, 30
	return RfAreaDone ? RfAreaTxt : ""
}

;====================================================================================================;
;   Utilities (new in Re:Fisch, build 2.2): Auto Totem and Auto Appraise.
;   Both are written from scratch for Re:Fisch. Settings live in Re-Fisch\settings.ini
;   [Utilities] and are the same for every profile.
;====================================================================================================;

RfUtilDefaults() {
	static d := ""
	if (!IsObject(d))
		{
		d := {RfTotOn: 0, RfTotUseMs: 2500, RfTotRetryMin: 15
			, RfApTargets: "Shiny, Sparkling", RfApKey: "e", RfApMax: 50, RfApWaitMs: 900, RfApResultMs: 1600
			, RfApPos1: "", RfApPos2: ""}
		for i, df in RfTotDefs()
			d["RfTotE" . df.id] := 0
		}
	return d
}

RfUtilLoad() {
	global
	local k, v, d
	for k, d in RfUtilDefaults()
		{
		IniRead, v, %SettingsFile%, Utilities, %k%, %d%
		%k% := (v = "ERROR") ? d : v
		}
}

RfUtilSave() {
	global
	local k, d, v
	for k, d in RfUtilDefaults()
		{
		v := %k%
		IniWrite, %v%, %SettingsFile%, Utilities, %k%
		}
}

RfNum(v, def, lo := 0) {
	if v is number
		return (v < lo) ? lo : v
	return def
}

; ------------------------------------------------------------------------------------------------
; Auto Totem (rebuilt in 2.3). The Utilities tab has a switch per event. Just before each cast:
;  1. the status icons at the bottom right are read (RfTotIcons); a moon there means night;
;  2. each picked event that is not running gets its totem, found on the hotbar by reading the
;     slot names with Windows text recognition (RfTotScan); an event that needs night or day gets
;     a Sundial first when the time is wrong;
;  3. the icon that appears after a totem is used is remembered as that event's icon (settings.ini
;     [TotemIcons], so it is known next time too); when it goes away the totem is used again.
;     When no new icon shows up, the totem is used again after "No icon seen" minutes.
; One event per group: one time of day (the first picked event that needs one decides), one
; weather, and one of Mutation / Shiny / Sparkling. Then the rod goes back in hand.
; ------------------------------------------------------------------------------------------------
RfTotDefs() {
	static d := ""
	if (!IsObject(d))
		d := [{id: "Night", names: ["sundial"], need: "Night", label: "Night  ·  Sundial", tip: "Keeps it night: a Sundial whenever it is day."}
			, {id: "Day", names: ["sundial"], need: "Day", label: "Day  ·  Sundial", tip: "Keeps it day: a Sundial whenever it is night."}
			, {id: "Aurora", names: ["aurora"], need: "Night", label: "Aurora  ·  night", tip: "Aurora Totem. Needs night: a Sundial first when it is day."}
			, {id: "Starfall", names: ["starfall", "meteor"], need: "Night", label: "Starfall  ·  night", tip: "Needs night: a Sundial first when it is day."}
			, {id: "Eclipse", names: ["eclipse"], need: "Day", label: "Eclipse  ·  day", tip: "Eclipse Totem. Needs day: a Sundial first when it is night."}
			, {id: "Mutation", names: ["mutation"], grp: "luck", label: "Mutation", tip: "Only one of Mutation, Shiny and Sparkling runs`n(the first one picked)."}
			, {id: "Clearcast", names: ["clearcast"], grp: "weather", label: "Clearcast  ·  clear", tip: "Only one weather runs (the first one picked)."}
			, {id: "Tempest", names: ["tempest"], grp: "weather", label: "Tempest  ·  rain", tip: "Only one weather runs (the first one picked)."}
			, {id: "Windset", names: ["windset"], grp: "weather", label: "Windset  ·  wind", tip: "Only one weather runs (the first one picked)."}
			, {id: "Smokescreen", names: ["smokescreen"], grp: "weather", label: "Smokescreen  ·  fog", tip: "Only one weather runs (the first one picked)."}
			, {id: "Shiny", names: ["shiny"], grp: "luck", label: "Shiny", tip: "Only one of Mutation, Shiny and Sparkling runs`n(the first one picked)."}
			, {id: "Sparkling", names: ["sparkling"], grp: "luck", label: "Sparkling", tip: "Only one of Mutation, Shiny and Sparkling runs`n(the first one picked)."}]
	return d
}

RfTotPicked(id) {
	global
	return (RfTotE%id% ? true : false)
}

; At the start of each fishing session: forget the hotbar, load the learned icons.
RfTotemBegin() {
	global RfTotState, RfTotSlots, RfTotSlotsAt, RfTotUsed, RfTotSunAt, RfTotSunBlock, RfTotNote, RfTotScanTxt, SettingsFile
	RfTotState := {}, RfTotSlots := {}, RfTotSlotsAt := 0, RfTotUsed := 0, RfTotSunAt := 0, RfTotSunBlock := 0
	RfTotNote := "", RfTotScanTxt := ""
	for i, df in RfTotDefs()
		{
		IniRead, v, %SettingsFile%, TotemIcons, % df.id, %A_Space%
		RfTotState[df.id] := {sig: RfTotSigParse(v), on: false, assumeUntil: 0, retryAt: 0, st: ""}
		}
}

; False when fishing was stopped while a totem was being used.
RfTotemRun() {
	global RfTotOn, RodSlotKey, RfTotState, RfTotNote, RfTip7, RfTip8, RfTotSunAt, RfTotSunBlock, RfTotUseMs
	if (!RfTotOn)
		return true
	if (!IsObject(RfTotState))
		RfTotemBegin()
	if (Trim(RodSlotKey) = "")
		{
		RfTotNote := "Needs the rod hotbar key (Settings tab, Recovery)"
		return true
		}
	RfTotNote := ""
	icons := RfTotIcons()
	timeNow := RfTotTime(icons)
	wantTime := "", grpOwner := {}, used := 0
	for i, df in RfTotDefs()
		{
		if (!RfTotPicked(df.id))
			continue
		if (df.need != "" and wantTime = "")
			wantTime := df.need, timeOwner := df.id
		if (df.grp != "" and !grpOwner.HasKey(df.grp))
			grpOwner[df.grp] := df.id
		}
	for i, df in RfTotDefs()
		{
		id := df.id, st := RfTotState[id]
		if (!RfTotPicked(id))
			{
			st.st := ""
			continue
			}
		if (df.need != "" and df.need != wantTime)
			{
			st.st := "waits (" . timeOwner . " keeps it " . RfTotLow(wantTime) . ")"
			continue
			}
		if (df.grp != "" and grpOwner[df.grp] != id)
			{
			st.st := "off (" . grpOwner[df.grp] . " is the " . (df.grp = "weather" ? "weather" : "pick") . ")"
			continue
			}
		; Running already?
		if (df.need != "" and df.need = timeNow and (id = "Night" or id = "Day"))
			{
			st.st := "yes"
			continue
			}
		if (id != "Night" and id != "Day" and RfTotActive(id, icons))
			continue
		if (A_TickCount < st.retryAt)
			continue
		; Time of day first.
		if (df.need != "" and timeNow != df.need)
			{
			if (timeNow = "")
				{
				st.st := "can't read the time of day (bottom right icons)"
				continue
				}
			if (A_TickCount < RfTotSunBlock)
				{
				st.st := "waits for " . RfTotLow(df.need) . " (Sundial did not change it)"
				continue
				}
			key := RfTotKeyFor(["sundial"])
			if (key = "")
				{
				st.st := "no Sundial Totem on the hotbar", st.retryAt := A_TickCount + 300000
				continue
				}
			r := RfTotSundial(key, df.need, icons)
			used := used + 1
			if (r < 0)
				return false
			icons := RfTotIcons(), timeNow := RfTotTime(icons)
			if (!r)
				{
				RfTotSunBlock := A_TickCount + 300000
				st.st := "Sundial used, but it is still " . RfTotLow(timeNow != "" ? timeNow : "unreadable")
				continue
				}
			if (id = "Night" or id = "Day")
				{
				st.st := "yes"
				continue
				}
			}
		key := RfTotKeyFor(df.names)
		if (key = "")
			{
			st.st := "no " . df.id . " Totem on the hotbar", st.retryAt := A_TickCount + 300000
			continue
			}
		r := RfTotUseEvent(df, key, icons)
		used := used + 1
		if (r < 0)
			return false
		icons := RfTotIcons(), timeNow := RfTotTime(icons)
		}
	if (used)
		{
		Send, {%RodSlotKey%}
		RfTip8 = Action: Rod back in hand
		if (!RfWait(700))
			return false
		}
	return true
}

RfTotLow(s) {
	StringLower, s, s
	return s
}

; Is the event's icon showing? Looked at twice, 0.7 s apart, before calling it gone.
RfTotActive(id, icons) {
	global RfTotState, RfTotRetryMin
	st := RfTotState[id]
	if (IsObject(st.sig))
		{
		if (RfTotFind(st.sig, icons))
			{
			st.on := true, st.st := "running"
			return true
			}
		if (st.on)
			{
			Sleep, 700
			if (RfTotFind(st.sig, RfTotIcons()))
				{
				st.st := "running"
				return true
				}
			}
		st.on := false
		}
	if (A_TickCount < st.assumeUntil)
		{
		st.st := "used, no icon seen: again in " . RfFmtTime(st.assumeUntil - A_TickCount, true)
		return true
		}
	return false
}

RfTotFind(sig, icons) {
	for i, ic in icons
		if (RfTotDist(sig, ic) <= 200)
			return i
	return 0
}

; Equip the totem on key and use it. False when fishing stopped.
RfTotUse(key, what) {
	global RfTip7, RfTip8, RfTotUsed, RfTotUseMs, KittyLogBuffer, RfTotSlotsAt
	RfTip7 = Current Task: Using %what% Totem (key %key%)
	Send, {LButton up}
	Send, {RButton up}
	Send, {%key%}
	RfTip8 = Action: Equip totem
	if (!RfWait(450))
		return false
	Send, {LButton down}
	Sleep, 90
	Send, {LButton up}
	RfTip8 = Action: Use totem
	RfTotUsed := RfTotUsed + 1
	RfTotSlotsAt := 0          ; the stack may have run out: read the hotbar again next time
	KittyLogBuffer .= "[" . A_Hour . ":" . A_Min . ":" . A_Sec . "] totem " . what . " used (key " . key . ")`r`n"
	return RfWait(RfNum(RfTotUseMs, 2500, 300))
}

; Sundial towards want ("Night" / "Day"); waits up to 40 s for the time icon to change.
; 1 = it is want now, 0 = it did not change, -1 = fishing stopped.
RfTotSundial(key, want, icons) {
	global RfTotSunAt
	if (!RfTotUse(key, "Sundial"))
		return -1
	RfTotSunAt := A_TickCount
	t0 := A_TickCount
	while (A_TickCount - t0 < 40000)
		{
		if (RfTotTime(RfTotIcons()) = want)
			return 1
		if (!RfWait(1000))
			return -1
		}
	return 0
}

; Use the event's totem and learn the icon that appears. 1 used, -1 fishing stopped.
RfTotUseEvent(df, key, before) {
	global RfTotState, RfTotRetryMin, SettingsFile
	st := RfTotState[df.id]
	if (!RfTotUse(key, df.id))
		return -1
	t0 := A_TickCount, got := ""
	while (A_TickCount - t0 < 8000)
		{
		now := RfTotIcons()
		if (IsObject(st.sig) and RfTotFind(st.sig, now))
			{
			got := "known"
			break
			}
		got := RfTotNewIcon(before, now, df.id)
		if (IsObject(got))
			break
		if (!RfWait(500))
			return -1
		}
	if (IsObject(got))
		{
		st.sig := got
		v := RfTotSigStr(got)
		IniWrite, %v%, %SettingsFile%, TotemIcons, % df.id
		}
	if (got != "")
		st.on := true, st.assumeUntil := 0, st.st := "running"
	else
		{
		st.on := false
		st.assumeUntil := A_TickCount + RfNum(RfTotRetryMin, 15, 1) * 60000
		st.st := "used, no icon seen: again in " . RfFmtTime(st.assumeUntil - A_TickCount, true)
		}
	return 1
}

; The icon in now that was not in before (and is not the moon or another event's icon); "" if none.
RfTotNewIcon(before, now, id) {
	global RfTotState
	best := "", bestD := 200
	for i, ic in now
		{
		d := 9999
		for j, b in before
			d := Min(d, RfTotDist(ic, b))
		if (d <= 200 or RfTotDist(ic, RfTotMoon()) <= 200)
			continue
		for k, st in RfTotState
			if (k != id and IsObject(st.sig) and RfTotDist(ic, st.sig) <= 200)
				d := 0
		if (d > bestD)
			best := ic, bestD := d
		}
	return best
}

; The moon icon (night), from a 1057 px high Roblox window on 2026-11-09.
RfTotMoon() {
	static m := ""
	if (!IsObject(m))
		m := RfTotSigParse("0026866995058300392056000093007000036000600003500070000350007300028000392000860002863029820005799997,76,120,2")
	return m
}

; "Night" when the moon is one of the three rightmost icons, "Day" when it is not (and at least two
; icons were read), "" when the row could not be read.
RfTotTime(icons) {
	if (icons.Length() < 2)
		return ""
	Loop % Min(3, icons.Length())
		if (RfTotDist(icons[A_Index], RfTotMoon()) <= 200)
			return "Night"
	return "Day"
}

; ---- the status icons ----------------------------------------------------------------------------
; The icon row sits above the level text at the bottom right: about 87.6-91.5 % down the window
; and up to 45 % of the window height in from the right edge.
RfTotIcons() {
	global WindowWidth, WindowHeight
	winW := WindowWidth, winH := WindowHeight
	if (winW < 200 or winH < 200)
		return []
	x0 := Max(winW // 2, winW - Round(winH * 0.45)), y0 := Round(winH * 0.876)
	s := RfGrab("totem", x0, y0, winW - x0, Round(winH * 0.915) - y0)
	if (!IsObject(s))
		return []
	return RfTotIconsIn(s, winH)
}

; Icons in surface s, right to left: runs of columns holding bright or strongly coloured pixels
; (gaps of up to 0.3 % of the window height bridged), each {x, w, top, h, g, a, hue, sat}.
; Thresholds follow the strip's median brightness, as the game world behind it varies.
RfTotIconsIn(s, winH) {
	sw := s.w, sh := s.h
	if (sw < 8 or sh < 8)
		return []
	hl := [], hm := []
	Loop 256
		hl[A_Index - 1] := 0, hm[A_Index - 1] := 0
	n := 0, y := 0
	while (y < sh)
		{
		x := 0, row := s.p + y * sw * 4
		while (x < sw)
			{
			px := NumGet(row + 0, x * 4, "UInt")
			b := px & 0xFF, g := (px >> 8) & 0xFF, r := (px >> 16) & 0xFF
			l := (r + g + b) // 3, m := Max(r, g, b)
			hl[l] := hl[l] + 1, hm[m] := hm[m] + 1, n := n + 1
			x := x + 2
			}
		y := y + 2
		}
	medL := RfTotMedian(hl, n), medM := RfTotMedian(hm, n)
	thrL := Min(230, Max(170, medL + 60)), thrM := Max(150, medM + 50)
	VarSetCapacity(mask, sw * sh, 0)
	col := []
	x := 0
	while (x < sw)
		col[x] := 0, x := x + 1
	y := 0
	while (y < sh)
		{
		x := 0, row := s.p + y * sw * 4
		while (x < sw)
			{
			px := NumGet(row + 0, x * 4, "UInt")
			b := px & 0xFF, g := (px >> 8) & 0xFF, r := (px >> 16) & 0xFF
			m := Max(r, g, b), mn := Min(r, g, b)
			if ((r + g + b) // 3 >= thrL or (m >= thrM and (m - mn) * 100 >= 35 * m))
				{
				NumPut(1, mask, y * sw + x, "UChar")
				col[x] := col[x] + 1
				}
			x := x + 1
			}
		y := y + 1
		}
	gap := Max(2, Round(winH * 0.003))
	runs := [], a := -1, last := -1
	x := 0
	while (x < sw)
		{
		if (col[x] > 0)
			{
			if (a >= 0 and x - last - 1 > gap)
				runs.Push([a, last]), a := -1
			if (a < 0)
				a := x
			last := x
			}
		x := x + 1
		}
	if (a >= 0)
		runs.Push([a, last])
	icons := []
	i := runs.Length()
	while (i >= 1)
		{
		ic := RfTotDescribe(s, mask, runs[i][1], runs[i][2], winH)
		if (IsObject(ic))
			icons.Push(ic)
		i := i - 1
		}
	return icons
}

RfTotMedian(hist, n) {
	acc := 0, half := n // 2
	Loop 256
		{
		acc := acc + hist[A_Index - 1]
		if (acc >= half)
			return A_Index - 1
		}
	return 255
}

; One icon between columns a and z: its box, a 10 x 10 grid of how full each cell is (0-9), its
; width / height in % and the hue / saturation of its average colour. "" if it is not icon-sized.
RfTotDescribe(s, ByRef mask, a, z, winH) {
	sw := s.w, sh := s.h
	top := -1, bot := -1, y := 0
	while (y < sh)
		{
		x := a
		while (x <= z)
			{
			if (NumGet(mask, y * sw + x, "UChar"))
				{
				if (top < 0)
					top := y
				bot := y
				break
				}
			x := x + 1
			}
		y := y + 1
		}
	iw := z - a + 1, ih := bot - top + 1
	if (top < 0 or ih < winH * 0.012 or iw < winH * 0.004 or iw > winH * 0.07 or ih > winH * 0.06)
		return ""
	cnt := [], area := []
	Loop 100
		cnt[A_Index - 1] := 0, area[A_Index - 1] := 0
	sr := 0, sg := 0, sb := 0, fg := 0
	y := top
	while (y <= bot)
		{
		cy := (y - top) * 10 // ih
		x := a
		while (x <= z)
			{
			c := cy * 10 + (x - a) * 10 // iw
			area[c] := area[c] + 1
			if (NumGet(mask, y * sw + x, "UChar"))
				{
				cnt[c] := cnt[c] + 1, fg := fg + 1
				px := NumGet(s.p + 0, (y * sw + x) * 4, "UInt")
				sb := sb + (px & 0xFF), sg := sg + ((px >> 8) & 0xFF), sr := sr + ((px >> 16) & 0xFF)
				}
			x := x + 1
			}
		y := y + 1
		}
	if (fg < 12)
		return ""
	grid := ""
	Loop 100
		{
		c := A_Index - 1
		grid .= area[c] ? Round(9 * cnt[c] / area[c]) : 0
		}
	hs := RfTotHueSat(sr // fg, sg // fg, sb // fg)
	return {x: a, w: iw, top: top, h: ih, g: grid, a: Round(iw * 100 / ih), hue: hs[1], sat: hs[2]}
}

RfTotHueSat(r, g, b) {
	m := Max(r, g, b), mn := Min(r, g, b), d := m - mn
	if (m = 0 or d = 0)
		return [0, 0]
	if (m = r)
		h := Mod(60 * (g - b) / d + 360, 360)
	else if (m = g)
		h := 60 * (b - r) / d + 120
	else
		h := 60 * (r - g) / d + 240
	return [Round(h), Round(d * 100 / m)]
}

; How different two icons look: grid cells (0-900) + half the width / height difference in % +
; colour (60 when only one is coloured, else half the hue difference in degrees). The same icon
; at 0.75-1.33x size measured 37-127, different icons 325 or more; 200 or less counts as the same.
RfTotDist(p, q) {
	d := 0
	Loop 100
		d := d + Abs(SubStr(p.g, A_Index, 1) - SubStr(q.g, A_Index, 1))
	d := d + Abs(p.a - q.a) // 2
	cp := (p.sat >= 20), cq := (q.sat >= 20)
	if (cp != cq)
		d := d + 60
	else if (cp)
		{
		hd := Abs(p.hue - q.hue)
		d := d + Min(hd, 360 - hd) // 2
		}
	return d
}

RfTotSigStr(ic) {
	return ic.g . "," . ic.a . "," . ic.hue . "," . ic.sat
}

RfTotSigParse(str) {
	p := StrSplit(str, ",")
	if (p.Length() < 4 or StrLen(p[1]) != 100)
		return ""
	return {g: p[1], a: p[2] + 0, hue: p[3] + 0, sat: p[4] + 0}
}

; ---- the hotbar ------------------------------------------------------------------------------------
; The hotbar key of the first totem whose name matches one of names; reads the hotbar when it has
; not been read since the last totem was used. "" when none is there.
RfTotKeyFor(names) {
	global RfTotSlots, RfTotSlotsAt
	if (!RfTotSlotsAt)
		RfTotScan()
	for i, nm in names
		if (RfTotSlots.HasKey(nm))
			return RfTotSlots[nm]
	return ""
}

; Reads every hotbar slot's text with Windows text recognition. The slots are found by their
; numbers (small white digits along the top of each slot, 93.8-94.4 % down the window); a slot
; starts 0.66 % of the window height left of its number and is 6.3 % wide (measured at 1057 px
; high: slots 69 px apart, centred at the bottom). If no numbers are seen, nine centred slots are
; assumed. A slot's key is the number read from its text, else its place from the left.
RfTotScan() {
	global RfTotSlots, RfTotSlotsAt, RfTotNote, RfTotScanTxt, WindowWidth, WindowHeight, KittyLogBuffer
	RfTotSlots := {}, RfTotSlotsAt := A_TickCount
	if (!RfTextEnsure(8000))
		{
		RfTotNote := "Windows text reading is not available, so the hotbar can't be read"
		return false
		}
	winW := WindowWidth, winH := WindowHeight
	if (winW < 200 or winH < 200)
		return false
	lefts := RfTotSlotLefts(), how := "numbers seen"
	if (!lefts.Length())
		{
		how := "assumed 9 slots"
		Loop 9
			lefts.Push(Round(winW / 2 + (A_Index - 5) * winH * 0.0653 - winH * 0.0316))
		}
	log := ""
	for i, x in lefts
		{
		fx := (x + winH * 0.001) / winW, fw := winH * 0.061 / winW
		if (fx < 0 or fx + fw > 1)
			continue
		txt := RfOcrArea(fx, 0.936, fw, 0.061, 3000)
		d := RegExMatch(txt, "^\s*(\d)", m) ? ((m1 = 0) ? 10 : m1 + 0) : 0
		nm := RfTotNameIn(txt)
		log .= " [" . i . "] " . RegExReplace(txt, "\s+", " ")
		if (nm = "" or RfTotSlots.HasKey(nm))
			continue
		v := d ? d : i
		if (v >= 1 and v <= 10)
			RfTotSlots[nm] := (v = 10) ? "0" : v
		}
	found := ""
	for nm, key in RfTotSlots
		found .= nm . "=" . key . " "
	RfTotScanTxt := (found = "") ? "no totems found" : Trim(found)
	KittyLogBuffer .= "[" . A_Hour . ":" . A_Min . ":" . A_Sec . "] totem hotbar (" . how . "): " . RfTotScanTxt . "  read:" . log . "`r`n"
	return true
}

; Left edges (client x) of the hotbar slots, from the slot numbers.
RfTotSlotLefts() {
	global WindowWidth, WindowHeight
	winW := WindowWidth, winH := WindowHeight
	x0 := Max(0, Round(winW / 2 - winH * 0.36)), x1 := Min(winW - 1, Round(winW / 2 + winH * 0.36))
	y0 := Round(winH * 0.9376), y1 := Round(winH * 0.9442)
	s := RfGrab("totembar", x0, y0, x1 - x0 + 1, y1 - y0 + 1)
	if (!IsObject(s))
		return []
	return RfTotDigitsIn(s, winH, x0)
}

; Slot numbers in surface s: runs of columns with white pixels (1 px gaps bridged), at most 1.2 %
; of the window height wide, with 4 or more white pixels over 3 or more rows. Returns each slot's
; left edge (the number's left edge - 0.66 % of the height, + x0).
RfTotDigitsIn(s, winH, x0) {
	sw := s.w, sh := Min(s.h, 60)
	cnt := [], rws := []
	x := 0
	while (x < sw)
		{
		c := 0, rm := 0, y := 0
		while (y < sh)
			{
			px := NumGet(s.p + 0, (y * s.w + x) * 4, "UInt")
			b := px & 0xFF, g := (px >> 8) & 0xFF, r := (px >> 16) & 0xFF
			if (Min(r, g, b) >= 190 and Max(r, g, b) - Min(r, g, b) < 60)
				c := c + 1, rm := rm | (1 << y)
			y := y + 1
			}
		cnt[x] := c, rws[x] := rm
		x := x + 1
		}
	lefts := [], maxW := Max(3, Round(winH * 0.012)), back := Round(winH * 0.0066)
	a := -1, last := -1, tot := 0, rm := 0
	x := 0
	while (x <= sw)
		{
		on := (x < sw and cnt[x] > 0)
		if (a >= 0 and (x = sw or (on and x - last - 1 > 1) or (!on and x - last > 1)))
			{
			nr := 0, t := rm
			while (t)
				nr := nr + (t & 1), t := t >> 1
			if (last - a + 1 <= maxW and tot >= 4 and nr >= 3)
				lefts.Push(x0 + a - back)
			a := -1, tot := 0, rm := 0
			}
		if (on)
			{
			if (a < 0)
				a := x
			last := x, tot := tot + cnt[x], rm := rm | rws[x]
			}
		x := x + 1
		}
	return lefts
}

; Which totem a slot's text names ("" if none): it must say Totem and one of the totem names, a
; letter off at most (u/v, i/l, 0/o and 5/s are not told apart: the game's font trips the reader).
RfTotNameIn(txt) {
	static kws := ["sundial", "aurora", "starfall", "meteor", "eclipse", "mutation", "clearcast", "tempest", "windset", "smokescreen", "shiny", "sparkling"]
	t := RfTotFold(txt)
	if (t = "")
		return ""
	joined := StrReplace(t, " ")
	if (!InStr(joined, "totem") and !RfTotWordNear(t, "totem"))
		return ""
	for i, kw in kws
		if (InStr(joined, RfTotFold(kw)))
			return kw
	for i, kw in kws
		if (RfTotWordNear(t, RfTotFold(kw)))
			return kw
	return ""
}

RfTotWordNear(t, f) {
	Loop, Parse, t, %A_Space%
		if (StrLen(A_LoopField) >= 4 and RfTotLev(A_LoopField, f) <= StrLen(f) // 4)
			return true
	return false
}

RfTotFold(s) {
	StringLower, s, s
	s := RegExReplace(s, "[^a-z0-9]+", " ")
	s := StrReplace(s, "0", "o"), s := StrReplace(s, "5", "s"), s := StrReplace(s, "1", "l")
	s := StrReplace(s, "rn", "m"), s := StrReplace(s, "u", "v"), s := StrReplace(s, "i", "l")
	return Trim(s)
}

RfTotLev(p, q) {
	lp := StrLen(p), lq := StrLen(q)
	prev := []
	Loop % lq + 1
		prev[A_Index - 1] := A_Index - 1
	Loop % lp
		{
		i := A_Index, cur := [], cur[0] := i
		cp := SubStr(p, i, 1)
		Loop % lq
			{
			j := A_Index
			cur[j] := Min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (cp = SubStr(q, j, 1) ? 0 : 1))
			}
		prev := cur
		}
	return prev[lq]
}

RfTotemStatus() {
	global RfTotOn, RodSlotKey, MacroRunning, RfTotState, RfTotNote, RfTotUsed, RfTotScanTxt
	if (!RfTotOn)
		return "Off"
	if (Trim(RodSlotKey) = "")
		return "Needs the rod hotbar key (Settings tab, Recovery)"
	n := 0, parts := ""
	for i, df in RfTotDefs()
		{
		if (!RfTotPicked(df.id))
			continue
		n := n + 1
		st := IsObject(RfTotState) ? RfTotState[df.id].st : ""
		if (MacroRunning and st != "")
			parts .= (parts = "" ? "" : "   ·   ") . df.id . ": " . st
		}
	if (!n)
		return "On, but no event is picked"
	if (!MacroRunning)
		return "On  ·  " . n . " event" . (n = 1 ? "" : "s") . " picked; checked before each cast"
	if (RfTotNote != "")
		return RfTotNote
	return (parts = "" ? "Checking before the next cast" : parts) . "   ·   " . RfTotUsed . " used"
		. (RfTotScanTxt != "" ? "   ·   hotbar: " . RfTotScanTxt : "")
}

; ------------------------------------------------------------------------------------------------
; Auto Appraise: at the Appraiser with the fish in hand, talks, clicks the picked dialogue
; button(s), reads the result and repeats until one of the chosen mutations shows up, the try
; limit is reached, or the game says there is not enough money. The start key stops it.
; A mutation only counts when it is new in the text after the appraisal (so a word that was
; already on screen - in the dialogue, say - never ends the run).
; ------------------------------------------------------------------------------------------------
RfApWait(ms) {
	global RfApRunning
	t := A_TickCount + ms
	Loop
		{
		if (!RfApRunning)
			return false
		left := t - A_TickCount
		if (left <= 0)
			break
		Sleep, % (left > 60) ? 50 : left
		}
	return RfApRunning
}

; "0.512,0.733" (fractions of the Roblox window) -> click there
RfApClick(pos) {
	global RobloxHwnd
	p := StrSplit(pos, ",")
	if (p.Length() != 2 or !RfClientArea(RobloxHwnd, rx, ry, rw, rh))
		return false
	x := rx + Round(rw * p[1]), y := ry + Round(rh * p[2])
	DllCall("SetCursorPos", "Int", x, "Int", y)
	Sleep, 40
	DllCall("mouse_event", "UInt", 0x01, "UInt", 1, "UInt", 1)   ; tiny move so Roblox sees the hover
	Sleep, 60
	send {lbutton down}
	Sleep, 70
	send {lbutton up}
	return true
}

RfApFoundIn(before, after) {
	global RfApTargets
	for i, t in StrSplit(RfApTargets, ",")
		{
		t := Trim(t)
		if (t != "" and InStr(after, t) and !InStr(before, t))
			return t
		}
	return ""
}

RfApStart:
gosub, RfSubmitChecked
RfUtilSave()
if (MacroRunning or MacroPreview)
	{
	GuiControl, 1:, RfApStatus, Stop fishing first (Start button / start key).
	return
	}
if (Trim(RfApTargets) = "" or RfApPos1 = "")
	{
	GuiControl, 1:, RfApStatus, Set the mutations and pick dialogue button 1 first.
	return
	}
RfFindRoblox()
if (!RobloxHwnd)
	{
	GuiControl, 1:, RfApStatus, Roblox is not running.
	return
	}
GuiControl, 1:, RfApStatus, Starting text reading ...
if (!RfTextEnsure())
	{
	GuiControl, 1:, RfApStatus, % "Windows text reading is not available" . ((RfOcrState != "" and RfOcrState != "ok") ? ": " . SubStr(RfOcrState, 5) : "")
	return
	}
RfApRunning := true
RfApTry := 0
RfApMaxN := Round(RfNum(RfApMax, 50, 1))
RfApLast := "starting"
Gui, 1:Hide
WinActivate, ahk_id %RobloxHwnd%
WinWaitActive, ahk_id %RobloxHwnd%, , 2
RfArmKeys()
RfApResult := "stopped"
while (RfApRunning)
	{
	if (RfApTry >= RfApMaxN)
		{
		RfApResult := "no match after " . RfApTry . " tries"
		break
		}
	RfApTry += 1
	RfApLast := "talking"
	send {%RfApKey%}
	if (!RfApWait(RfNum(RfApWaitMs, 900, 100)))
		break
	RfApBefore := RfOcrArea(0.05, 0.10, 0.90, 0.80)
	RfApLast := "appraising"
	RfApClick(RfApPos1)
	if (RfApPos2 != "")
		{
		if (!RfApWait(350))
			break
		RfApClick(RfApPos2)
		}
	if (!RfApWait(RfNum(RfApResultMs, 1600, 200)))
		break
	RfApAfter := RfOcrArea(0.05, 0.10, 0.90, 0.80)
	if (RegExMatch(RfApAfter, "i)not enough|can.?t afford|insufficient"))
		{
		RfApResult := "stopped: not enough money (try " . RfApTry . ")"
		break
		}
	RfApHit := RfApFoundIn(RfApBefore, RfApAfter)
	KittyLogBuffer .= "[" . A_Hour . ":" . A_Min . ":" . A_Sec . "] appraise " . RfApTry . ": " . SubStr(StrReplace(RfApAfter, "`n", " / "), 1, 160) . "`r`n"
	if (RfApHit != "")
		{
		RfApResult := "✓  " . RfApHit . " after " . RfApTry . " tries"
		SoundBeep, 880, 150
		SoundBeep, 1175, 200
		break
		}
	RfApLast := "no match"
	if (!RfApWait(400))
		break
	}
RfApRunning := false
GuiControl, 1:, RfApStatus, %RfApResult%
Gui, 1:Show
SetTimer, RfRepaint, -150
RfDisarmKeys()
return

; Pick a dialogue button: open the Appraiser's dialogue in Roblox, then hover the button.
RfApPick1:
RfApPickN := 1
gosub, RfApPick
return

RfApPick2:
RfApPickN := 2
gosub, RfApPick
return

RfApPick:
RfFindRoblox()
if (!RobloxHwnd)
	{
	GuiControl, 1:, RfApStatus, Roblox is not running.
	return
	}
Gui, 1:Hide
WinActivate, ahk_id %RobloxHwnd%
CoordMode, Mouse, Screen
Loop, 5
	{
	ToolTip, % "Re:Fisch: hover dialogue button " . RfApPickN . " in Roblox  -  " . (6 - A_Index)
	Sleep, 1000
	}
ToolTip
MouseGetPos, RfPmx, RfPmy
RfClientArea(RobloxHwnd, RfPrx, RfPry, RfPrw, RfPrh)
if (RfPrw > 0 and RfPrh > 0 and RfPmx >= RfPrx and RfPmy >= RfPry and RfPmx < RfPrx + RfPrw and RfPmy < RfPry + RfPrh)
	{
	RfApPos%RfApPickN% := Round((RfPmx - RfPrx) / RfPrw, 4) . "," . Round((RfPmy - RfPry) / RfPrh, 4)
	RfUtilSave()
	}
Gui, 1:Show
SetTimer, RfRepaint, -150
gosub, RfApPosText
return

RfApClearPos2:
RfApPos2 := ""
RfUtilSave()
gosub, RfApPosText
return

RfApPosText:
Loop, 2
	{
	RfPv := RfApPos%A_Index%
	RfPp := StrSplit(RfPv, ",")
	GuiControl, 1:, RfApPos%A_Index%Txt, % (RfPv = "") ? ((A_Index = 1) ? "not set" : "not used") : "set  ·  " . Round(RfPp[1] * 100) . " % across, " . Round(RfPp[2] * 100) . " % down"
	}
return


; Source of Re-Fisch\catch-watcher.ahk (parts/rf_watcher.ahk), base64 of the UTF-8 file.
RfWatchSourceB64() {
	s := ""
	s .= "77u/OyBSZTpGaXNjaCB0ZXh0IHJlYWRlciAtIHdyaXR0ZW4gYW5kIHN0YXJ0ZWQgYnkgUmU6RmlzY2ggKFJlLUZpc2NoXGNhdGNoLXdhdGNoZXIuYWhrKSB3aGVuIEF1dG8NCjsgQXBwcmFpc2UgbmVlZHMgdG8gcmVhZCB0aGUgZ2FtZS4gSXQgcmVhZHMgdGhlIGFyZWEgUmU6RmlzY2ggYXNrcyBmb3Igd2l0aCBXaW5kb3dzJyBidWlsdC1pbg0KOyB0ZXh0IHJlY29nbml0aW9uIGFuZCBzZW5kcyB0aGUgdGV4dCBiYWNrLiBJdCBydW5zIGFzIGl0cyBvd24gcHJvY2VzcyBzbyByZWFkaW5nIG5ldmVyIHN0YWxscw0KOyB0aGUgbWFjcm8sIGFuZCBjbG9zZXMgYnkgaXRzZWxmIHdoZW4gUmU6RmlzY2ggY2xvc2VzLiBFZGl0cyBoZXJlIGFyZSBvdmVyd3JpdHRlbi4NCiNOb0Vudg0KI05vVHJheUljb24NCiNTaW5nbGVJbnN0YW5jZSBGb3JjZQ0KI1BlcnNpc3RlbnQNClNldEJhdGNoTGluZXMsIC0xDQpnbG9iYWwgV01haW4gOj0gQV9BcmdzWzFdICsgMCwgV01haW5QaWQgOj0gQV9BcmdzWzJdICsgMA0KZ2xvYmFsIFdSYnggOj0gMCwgV0FyZWFSZXEgOj0gIiINCmdsb2JhbCBPY3JTdGF0ZSA6PSAiIiwgT2NyRW5naW5lIDo9IDAsIE9jckRlY29kZXIgOj0gMCwgT2NyTWF4RGltIDo9IDIwMDAsIE9jckxhbmcgOj0gIiINCmlmICghV01haW4gb3IgIVdNYWluUGlkKQ0KCUV4aXRBcHANCk9uTWVzc2FnZSgweDgwMTEsICJXT25TdGF0ZSIpDQpPbk1lc3NhZ2UoMHg4MDEzLCAiV09uQXJlYSIpDQpXU2VuZCgxLCBBX1NjcmlwdEh3bmQgKyAwKQ0KaWYgKCFPY3JJbml0KCkpDQoJew0KCVdTZW5kKDQsICJlcnJvcnwiIC4gU3ViU3RyKE9jclN0YXRlLCA1KSkNCglFeGl0QXBwDQoJfQ0KaWYgKCFJblN0cihPY3JTZWxmVGVzdCgpLCAiY2F1Z2h0IikpDQoJew0KCVdTZW5kKDQsICJlcnJvcnxXaW5kb3dzIE9DUiBmYWlsZWQgaXRzIHNlbGYtdGVzdCIpDQoJRXhpdEFwcA0KCX0NCldTZW5kKDQsICJyZWFkeXwiIC4gT2NyTGFuZykNCldBbGl2ZVQgOj0gMA0KTG9vcA0KCXsNCglpZiAoQV9UaWNrQ291bnQgLSBXQWxpdmVUID4gMTAwMCkNCgkJew0KCQlXQWxpdmVUIDo9IEFfVGlja0NvdW50DQoJCVByb2Nlc3MsIEV4aXN0LCAlV01haW5QaWQlDQoJCWlmICghRXJyb3JMZXZlbCkNCgkJCUV4aXRBcHANCgkJfQ0KCWlmIChJc09iamVjdChXQXJlYVJlcSkpDQoJCXsNCgkJV0FyIDo9IFdBcmVhUmVxDQoJCVdBcmVhUmVxIDo9ICIiDQoJCVdTZW5kKDUsIFdSZWFkQXJlYShXUmJ4LCAoV0FyWzFdID4+IDE2KSAvIDEwMDAwLjAsIChXQXJbMV0gJiAweEZGRkYpIC8gMTAwMDAuMCwgKFdBclsyXSA+PiAxNikgLyAxMDAwMC4wLCAoV0FyWzJdICYgMHhGRkZGKSAvIDEwMDAwLjApKQ0KCQljb250aW51ZQ0KCQl9DQoJU2xlZXAsIDMwDQoJfQ0KcmV0dXJuDQoNCjsgV2hpY2ggUm9ibG94IHdpbmRvdyB0byByZWFkIChsUGFyYW0pLg0KV09uU3RhdGUod1BhcmFtLCBsUGFyYW0pIHsNCglXUmJ4IDo9IGxQYXJhbQ0KCXJldHVybiAxDQp9DQoNCjsgT25lIHJlYWQgb2YgYW4gYXJlYSAoZnJhY3Rpb25zIG9mIHRoZSBSb2Jsb3ggd2luZG93IHggMTAwMDAsIHBhY2tlZCB0d28gcGVyIHBhcmFtZXRlcjoNCjsgd1BhcmFtID0geCA8PCAxNiB8IHksIGxQYXJhbSA9IHcgPDwgMTYgfCBoKS4gQW5zd2VyZWQgd2l0aCBtZXNzYWdlIDUuDQpXT25BcmVhKHdQYXJhbSwgbFBhcmFtKSB7DQoJV0FyZWFSZXEgOj0gW3dQYXJhbSAmIDB4RkZGRkZGRkYsIGxQYXJhbSAmIDB4RkZGRkZGRkZdDQoJcmV0dXJuIDENCn0NCg0KOyBXTV9DT1BZREFUQSB0byBSZTpGaXNjaDogMSBoZWxsbyAob3VyIHdpbmRvdyksIDQgcmVhZHkgLyBlcnJvciwgNSB0ZXh0IHJlYWQuDQpXU2VuZChraW5kLCB0ZXh0KSB7DQoJdGV4dCA6PSAiIiAuIHRleHQNCglWYXJTZXRDYXBhY2l0eShjZHMsIDMgKiBBX1B0clNpemUsIDApDQoJTnVtUHV0KGtpbmQsIGNkcywgMCwgIlVQdHIiKQ0KCU51bVB1dCgoU3RyTGVuKHRleHQpICsgMSkgKiAyLCBjZHMsIEFfUHRyU2l6ZSwgIlVJbnQiKQ0KCU51bVB1dCgmdGV4dCwgY2RzLCAyICogQV9QdHJTaXplLCAiUHRyIikNCglyZXMgOj0gMA0KCXJldHVybiBEbGxDYWxsKCJTZW5kTWVzc2FnZVRpbWVvdXQiLCAiUHRyIiwgV01haW4sICJVSW50IiwgMHg0QSwgIlB0ciIsIEFfU2NyaXB0SHduZCwgIlB0ciIsICZjZHMNCgkJLCAiVUludCIsIDIsICJVSW50IiwgMzAwMCwgIlB0cioiLCByZXMpDQp9DQoNCldSZWFkQXJlYShoLCBmeCwgZnksIGZ3LCBmaCkgew0KCVZhclNldENhcGFjaXR5KHJjLCAxNiwgMCksIFZhclNldENhcGFjaXR5KHB0LCA4LCAwKQ0KCWlmICghaCBvciAhRGxsQ2FsbCgiR2V0Q2xpZW50UmVjdCIsICJQdHIiLCBoLCAiUHRyIiwgJnJjKSBvciAhRGxsQ2FsbCgiQ2xpZW50VG9TY3JlZW4iLCAiUHRyIiwgaCwgIlB0ciIsICZwdCkpDQoJCXJldHVybiAiIg0KCXJ4IDo9IE51bUdldChwdCwgMCwgIkludCIpLCByeSA6PSBOdW1HZXQocHQsIDQsICJJbnQiKSwgcncgOj0gTnVtR2V0KHJjLCA4LCAiSW50IiksIHJoIDo9IE51bUdldChyYywgMTIsICJJbnQiKQ0KCWlmIChydyA8IDIwMCBvciByaCA8IDIwMCBvciBmdyA8PSAwIG9yIGZoIDw9IDApDQoJCXJldHVybiAiIg0KCXMgOj0gTWF4KDEuMCwgTWluKDIuMCwgMS41ICogMTA4MCAvIHJoKSkNCglyZXR1cm4gT2NyU2NyZWVuKHJ4ICsgUm91bmQocncgKiBmeCksIHJ5ICsgUm91bmQocmggKiBmeSksIE1heCg4LCBSb3VuZChydyAqIGZ3KSksIE1heCg4LCBSb3VuZChyaCAqIGZoKSksIHMpDQp9DQoNCjsgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tDQo7IFdpbmRvd3MuTWVkaWEuT2NyIHRocm91Z2ggV2luUlQuDQo7IC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQ0KVnQobywgaSkgew0KCXJldHVybiBOdW1HZXQo"
	s .= "TnVtR2V0KG8gKyAwLCAwLCAiUHRyIiksIGkgKiBBX1B0clNpemUsICJQdHIiKQ0KfQ0KDQpIc01ha2Uoc3RyKSB7DQoJaHMgOj0gMA0KCURsbENhbGwoImNvbWJhc2VcV2luZG93c0NyZWF0ZVN0cmluZyIsICJXU3RyIiwgc3RyLCAiVUludCIsIFN0ckxlbihzdHIpLCAiUHRyKiIsIGhzLCAiVUludCIpDQoJcmV0dXJuIGhzDQp9DQoNCkhzRnJlZShocykgew0KCWlmIChocykNCgkJRGxsQ2FsbCgiY29tYmFzZVxXaW5kb3dzRGVsZXRlU3RyaW5nIiwgIlB0ciIsIGhzLCAiVUludCIpDQp9DQoNCkhzVGV4dChocykgew0KCWlmICghaHMpDQoJCXJldHVybiAiIg0KCWxlbiA6PSAwDQoJcCA6PSBEbGxDYWxsKCJjb21iYXNlXFdpbmRvd3NHZXRTdHJpbmdSYXdCdWZmZXIiLCAiUHRyIiwgaHMsICJVSW50KiIsIGxlbiwgIlB0ciIpDQoJcmV0dXJuIChwIGFuZCBsZW4pID8gU3RyR2V0KHAsIGxlbiwgIlVURi0xNiIpIDogIiINCn0NCg0KRmFjdG9yeShjbHMsIGlpZCkgew0KCWhzIDo9IEhzTWFrZShjbHMpDQoJaWYgKCFocykNCgkJcmV0dXJuIDANCglWYXJTZXRDYXBhY2l0eShnLCAxNiwgMCkNCglEbGxDYWxsKCJvbGUzMlxDTFNJREZyb21TdHJpbmciLCAiV1N0ciIsIGlpZCwgIlB0ciIsICZnLCAiVUludCIpDQoJZiA6PSAwDQoJaHIgOj0gRGxsQ2FsbCgiY29tYmFzZVxSb0dldEFjdGl2YXRpb25GYWN0b3J5IiwgIlB0ciIsIGhzLCAiUHRyIiwgJmcsICJQdHIqIiwgZiwgIlVJbnQiKQ0KCUhzRnJlZShocykNCglyZXR1cm4gKGhyID0gMCkgPyBmIDogMA0KfQ0KDQpBc3luY1dhaXQoQnlSZWYgb3AsIHRpbWVvdXRNcyA6PSA0MDAwKSB7DQoJaWYgKCFvcCkNCgkJcmV0dXJuIGZhbHNlDQoJaW5mbyA6PSBDb21PYmpRdWVyeShvcCwgInswMDAwMDAzNi0wMDAwLTAwMDAtQzAwMC0wMDAwMDAwMDAwNDZ9IikNCglpZiAoIWluZm8pDQoJCXsNCgkJT2JqUmVsZWFzZShvcCkNCgkJb3AgOj0gMA0KCQlyZXR1cm4gZmFsc2UNCgkJfQ0KCXQwIDo9IEFfVGlja0NvdW50DQoJc3QgOj0gMA0KCUxvb3ANCgkJew0KCQlEbGxDYWxsKFZ0KGluZm8sIDcpLCAiUHRyIiwgaW5mbywgIlVJbnQqIiwgc3QsICJVSW50IikNCgkJaWYgKHN0ICE9IDAgb3IgQV9UaWNrQ291bnQgLSB0MCA+IHRpbWVvdXRNcykNCgkJCWJyZWFrDQoJCVNsZWVwLCAzDQoJCX0NCglyZXMgOj0gMA0KCWlmIChzdCA9IDEpDQoJCURsbENhbGwoVnQob3AsIDgpLCAiUHRyIiwgb3AsICJQdHIqIiwgcmVzLCAiVUludCIpDQoJZWxzZSBpZiAoc3QgPSAwKQ0KCQlEbGxDYWxsKFZ0KGluZm8sIDkpLCAiUHRyIiwgaW5mbywgIlVJbnQiKQ0KCU9ialJlbGVhc2UoaW5mbykNCglPYmpSZWxlYXNlKG9wKQ0KCW9wIDo9IHJlcw0KCXJldHVybiAocmVzICE9IDApDQp9DQoNCkNsb3NlT2JqKG8pIHsNCglpZiAoIW8pDQoJCXJldHVybg0KCWMgOj0gQ29tT2JqUXVlcnkobywgInszMEQ1QTgyOS03RkE0LTQwMjYtODNCQi1ENzVCQUU0RUE5OUV9IikNCglpZiAoYykNCgkJew0KCQlEbGxDYWxsKFZ0KGMsIDYpLCAiUHRyIiwgYywgIlVJbnQiKQ0KCQlPYmpSZWxlYXNlKGMpDQoJCX0NCn0NCg0KQm1wU3RyZWFtKGhibSkgew0KCXN0cmVhbSA6PSAwLCBwaWMgOj0gMCwgcmFzIDo9IDAsIHN6IDo9IDANCglpZiAoRGxsQ2FsbCgib2xlMzJcQ3JlYXRlU3RyZWFtT25IR2xvYmFsIiwgIlB0ciIsIDAsICJJbnQiLCAxLCAiUHRyKiIsIHN0cmVhbSwgIlVJbnQiKSAhPSAwIG9yICFzdHJlYW0pDQoJCXJldHVybiAwDQoJVmFyU2V0Q2FwYWNpdHkocGQsIDggKyAyICogQV9QdHJTaXplLCAwKQ0KCU51bVB1dCg4ICsgMiAqIEFfUHRyU2l6ZSwgcGQsIDAsICJVSW50IikNCglOdW1QdXQoMSwgcGQsIDQsICJVSW50IikNCglOdW1QdXQoaGJtLCBwZCwgOCwgIlB0ciIpDQoJVmFyU2V0Q2FwYWNpdHkoaWlkLCAxNiwgMCkNCglEbGxDYWxsKCJvbGUzMlxDTFNJREZyb21TdHJpbmciLCAiV1N0ciIsICJ7N0JGODA5ODAtQkYzMi0xMDFBLThCQkItMDBBQTAwMzAwQ0FCfSIsICJQdHIiLCAmaWlkLCAiVUludCIpDQoJaWYgKERsbENhbGwoIm9sZWF1dDMyXE9sZUNyZWF0ZVBpY3R1cmVJbmRpcmVjdCIsICJQdHIiLCAmcGQsICJQdHIiLCAmaWlkLCAiSW50IiwgMCwgIlB0cioiLCBwaWMsICJVSW50IikgPSAwIGFuZCBwaWMpDQoJCXsNCgkJRGxsQ2FsbChWdChwaWMsIDE1KSwgIlB0ciIsIHBpYywgIlB0ciIsIHN0cmVhbSwgIkludCIsIDEsICJJbnQqIiwgc3osICJVSW50IikNCgkJT2JqUmVsZWFzZShwaWMpDQoJCURsbENhbGwoVnQoc3RyZWFtLCA1KSwgIlB0ciIsIHN0cmVhbSwgIkludDY0IiwgMCwgIlVJbnQiLCAwLCAiUHRyIiwgMCwgIlVJbnQiKQ0KCQlEbGxDYWxsKCJvbGUzMlxDTFNJREZyb21TdHJpbmciLCAiV1N0ciIsICJ7OTA1QTBGRTEtQkM1My0xMURGLThDNDktMDAxRTRGQzY4NkRBfSIsICJQdHIiLCAmaWlkLCAiVUludCIpDQoJCURsbENhbGwoInNoY29yZVxDcmVhdGVSYW5kb21BY2Nlc3NTdHJlYW1PdmVyU3RyZWFtIiwgIlB0ciIsIHN0cmVhbSwgIlVJbnQiLCAwLCAiUHRyIiwgJmlpZCwgIlB0cioiLCByYXMsICJVSW50IikNCgkJfQ0KCU9ialJlbGVhc2Uoc3RyZWFtKQ0KCXJldHVybiByYXMNCn0NCg0KT2NySW5pdCgpIHsNCglPY3JTdGF0ZSA6PSAib2ZmOm5lZWRzIFdpbmRvd3MgMTAgb3IgMTEiDQoJaWYgKFN1YlN0cihBX09TVmVyc2lvbiwgMSwgMykgIT0gIjEwLiIpDQoJCXJldHVybiBmYWxzZQ0KCU9jclN0YXRlIDo9ICJvZmY6V2luZG93cyBPQ1IgaXMgbm90IGF2YWlsYWJsZSINCglPY3JEZWNvZGVyIDo9IEZhY3RvcnkoIldpbmRvd3MuR3JhcGhpY3MuSW1hZ2luZy5CaXRtYXBEZWNvZGVyIiwgIns0MzhDQ0IyNi1CQ0VGLTRFOTUtQkFENi0yM0E4MjJFNThEMDF9IikNCglmIDo9IEZhY3RvcnkoIldpbmRvd3MuTWVkaWEuT2NyLk9jckVuZ2luZSIsICJ7NUJGRkE4NUEtMzM4NC0zNTQwLTk5NDAtNjk5MTIwRDQyOEE4fSIpDQoJaWYgKCFPY3JEZWNvZGVyIG9yICFmKQ0KCQl7DQoJCWlmIChmKQ0KCQkJT2JqUmVsZWFzZShmKQ0KCQlyZXR1"
	s .= "cm4gZmFsc2UNCgkJfQ0KCW1heGQgOj0gMA0KCURsbENhbGwoVnQoZiwgNiksICJQdHIiLCBmLCAiVUludCoiLCBtYXhkLCAiVUludCIpDQoJT2NyTWF4RGltIDo9IChtYXhkID49IDUwMCkgPyBtYXhkIDogMjAwMA0KCU9jckVuZ2luZSA6PSAwDQoJbGYgOj0gRmFjdG9yeSgiV2luZG93cy5HbG9iYWxpemF0aW9uLkxhbmd1YWdlIiwgIns5QjAyNTJBQy0wQzI3LTQ0RjgtQjc5Mi05NzkzRkI2NkM2M0V9IikNCglpZiAobGYpDQoJCXsNCgkJZm9yIGksIHRhZyBpbiBbImVuLVVTIiwgImVuLUdCIiwgImVuIl0NCgkJCXsNCgkJCWhzIDo9IEhzTWFrZSh0YWcpDQoJCQlsYW5nIDo9IDANCgkJCURsbENhbGwoVnQobGYsIDYpLCAiUHRyIiwgbGYsICJQdHIiLCBocywgIlB0cioiLCBsYW5nLCAiVUludCIpDQoJCQlIc0ZyZWUoaHMpDQoJCQlpZiAoIWxhbmcpDQoJCQkJY29udGludWUNCgkJCW9rIDo9IDANCgkJCURsbENhbGwoVnQoZiwgOCksICJQdHIiLCBmLCAiUHRyIiwgbGFuZywgIlVDaGFyKiIsIG9rLCAiVUludCIpDQoJCQlpZiAob2spDQoJCQkJRGxsQ2FsbChWdChmLCA5KSwgIlB0ciIsIGYsICJQdHIiLCBsYW5nLCAiUHRyKiIsIE9jckVuZ2luZSwgIlVJbnQiKQ0KCQkJT2JqUmVsZWFzZShsYW5nKQ0KCQkJaWYgKE9jckVuZ2luZSkNCgkJCQl7DQoJCQkJT2NyTGFuZyA6PSB0YWcNCgkJCQlicmVhaw0KCQkJCX0NCgkJCX0NCgkJT2JqUmVsZWFzZShsZikNCgkJfQ0KCWlmICghT2NyRW5naW5lKQ0KCQl7DQoJCURsbENhbGwoVnQoZiwgMTApLCAiUHRyIiwgZiwgIlB0cioiLCBPY3JFbmdpbmUsICJVSW50IikNCgkJT2NyTGFuZyA6PSAiV2luZG93cyBsYW5ndWFnZSINCgkJfQ0KCU9ialJlbGVhc2UoZikNCglpZiAoIU9jckVuZ2luZSkNCgkJew0KCQlPY3JTdGF0ZSA6PSAib2ZmOm5vIE9DUiBsYW5ndWFnZSBpbnN0YWxsZWQgaW4gV2luZG93cyINCgkJcmV0dXJuIGZhbHNlDQoJCX0NCglPY3JTdGF0ZSA6PSAib2siDQoJcmV0dXJuIHRydWUNCn0NCg0KT2NyQml0bWFwVGV4dChoYm0pIHsNCglyYXMgOj0gQm1wU3RyZWFtKGhibSkNCglpZiAoIXJhcykNCgkJcmV0dXJuICIiDQoJZGVjIDo9IDANCglEbGxDYWxsKFZ0KE9jckRlY29kZXIsIDE0KSwgIlB0ciIsIE9jckRlY29kZXIsICJQdHIiLCByYXMsICJQdHIqIiwgZGVjLCAiVUludCIpDQoJc2JtIDo9IDANCglpZiAoQXN5bmNXYWl0KGRlYykpDQoJCXsNCgkJZnNiIDo9IENvbU9ialF1ZXJ5KGRlYywgIntGRTI4N0M5QS00MjBDLTQ5NjMtODdBRC02OTE0MzZFMDgzODN9IikNCgkJaWYgKGZzYikNCgkJCXsNCgkJCURsbENhbGwoVnQoZnNiLCA2KSwgIlB0ciIsIGZzYiwgIlB0cioiLCBzYm0sICJVSW50IikNCgkJCU9ialJlbGVhc2UoZnNiKQ0KCQkJQXN5bmNXYWl0KHNibSkNCgkJCX0NCgkJT2JqUmVsZWFzZShkZWMpDQoJCX0NCglyZXMgOj0gMA0KCWlmIChzYm0pDQoJCXsNCgkJRGxsQ2FsbChWdChPY3JFbmdpbmUsIDYpLCAiUHRyIiwgT2NyRW5naW5lLCAiUHRyIiwgc2JtLCAiUHRyKiIsIHJlcywgIlVJbnQiKQ0KCQlBc3luY1dhaXQocmVzKQ0KCQlDbG9zZU9iaihzYm0pDQoJCU9ialJlbGVhc2Uoc2JtKQ0KCQl9DQoJQ2xvc2VPYmoocmFzKQ0KCU9ialJlbGVhc2UocmFzKQ0KCWlmICghcmVzKQ0KCQlyZXR1cm4gIiINCgl0eHQgOj0gIiINCglsaW5lcyA6PSAwDQoJRGxsQ2FsbChWdChyZXMsIDYpLCAiUHRyIiwgcmVzLCAiUHRyKiIsIGxpbmVzLCAiVUludCIpDQoJaWYgKGxpbmVzKQ0KCQl7DQoJCW4gOj0gMA0KCQlEbGxDYWxsKFZ0KGxpbmVzLCA3KSwgIlB0ciIsIGxpbmVzLCAiVUludCoiLCBuLCAiVUludCIpDQoJCUxvb3AgJSBuDQoJCQl7DQoJCQlsbiA6PSAwDQoJCQlEbGxDYWxsKFZ0KGxpbmVzLCA2KSwgIlB0ciIsIGxpbmVzLCAiVUludCIsIEFfSW5kZXggLSAxLCAiUHRyKiIsIGxuLCAiVUludCIpDQoJCQlpZiAoIWxuKQ0KCQkJCWNvbnRpbnVlDQoJCQlocyA6PSAwDQoJCQlEbGxDYWxsKFZ0KGxuLCA3KSwgIlB0ciIsIGxuLCAiUHRyKiIsIGhzLCAiVUludCIpDQoJCQl0eHQgLj0gSHNUZXh0KGhzKSAuICJgbiINCgkJCUhzRnJlZShocykNCgkJCU9ialJlbGVhc2UobG4pDQoJCQl9DQoJCU9ialJlbGVhc2UobGluZXMpDQoJCX0NCglPYmpSZWxlYXNlKHJlcykNCglyZXR1cm4gdHh0DQp9DQoNCkRpYjMyKHcsIGgpIHsNCglWYXJTZXRDYXBhY2l0eShiaSwgNDAsIDApDQoJTnVtUHV0KDQwLCBiaSwgMCwgIlVJbnQiKSwgTnVtUHV0KHcsIGJpLCA0LCAiSW50IiksIE51bVB1dCgtaCwgYmksIDgsICJJbnQiKQ0KCU51bVB1dCgxLCBiaSwgMTIsICJVU2hvcnQiKSwgTnVtUHV0KDMyLCBiaSwgMTQsICJVU2hvcnQiKQ0KCWJpdHMgOj0gMA0KCXJldHVybiBEbGxDYWxsKCJDcmVhdGVESUJTZWN0aW9uIiwgIlB0ciIsIDAsICJQdHIiLCAmYmksICJVSW50IiwgMCwgIlB0cioiLCBiaXRzLCAiUHRyIiwgMCwgIlVJbnQiLCAwLCAiUHRyIikNCn0NCg0KT2NyU2NyZWVuKHgsIHksIHcsIGgsIHMpIHsNCglzdGF0aWMgaGJtIDo9IDAsIGJ3IDo9IDAsIGJoIDo9IDANCglzIDo9IE1pbihzLCAoT2NyTWF4RGltIC0gOCkgLyB3LCAoT2NyTWF4RGltIC0gOCkgLyBoKQ0KCWR3IDo9IE1heCg4LCBSb3VuZCh3ICogcykpLCBkaCA6PSBNYXgoOCwgUm91bmQoaCAqIHMpKQ0KCWlmIChkdyAhPSBidyBvciBkaCAhPSBiaCkNCgkJew0KCQlpZiAoaGJtKQ0KCQkJRGxsQ2FsbCgiRGVsZXRlT2JqZWN0IiwgIlB0ciIsIGhibSkNCgkJaGJtIDo9IERpYjMyKGR3LCBkaCkNCgkJYncgOj0gZHcsIGJoIDo9IGRoDQoJCX0NCglpZiAoIWhibSkNCgkJcmV0dXJuICIiDQoJc2RjIDo9IERsbENhbGwoIkdldERDIiwgIlB0ciIsIDAsICJQdHIiKQ0KCW1kYyA6PSBEbGxDYWxsKCJDcmVhdGVDb21wYXRpYmxlREMiLCAiUHRyIiwgc2RjLCAiUHRyIikNCglvbGQgOj0gRGxsQ2FsbCgiU2VsZWN0T2JqZWN0IiwgIlB0ciIsIG1kYywgIlB0ciIsIGhibSwgIlB0ciIpDQoJRGxsQ2FsbCgiU2V0U3RyZXRjaEJsdE1vZGUiLCAiUHRyIiwgbWRjLCAiSW50"
	s .= "IiwgNCkNCglEbGxDYWxsKCJTZXRCcnVzaE9yZ0V4IiwgIlB0ciIsIG1kYywgIkludCIsIDAsICJJbnQiLCAwLCAiUHRyIiwgMCkNCglEbGxDYWxsKCJTdHJldGNoQmx0IiwgIlB0ciIsIG1kYywgIkludCIsIDAsICJJbnQiLCAwLCAiSW50IiwgZHcsICJJbnQiLCBkaA0KCQksICJQdHIiLCBzZGMsICJJbnQiLCB4LCAiSW50IiwgeSwgIkludCIsIHcsICJJbnQiLCBoLCAiVUludCIsIDB4MDBDQzAwMjApDQoJRGxsQ2FsbCgiU2VsZWN0T2JqZWN0IiwgIlB0ciIsIG1kYywgIlB0ciIsIG9sZCkNCglEbGxDYWxsKCJEZWxldGVEQyIsICJQdHIiLCBtZGMpDQoJRGxsQ2FsbCgiUmVsZWFzZURDIiwgIlB0ciIsIDAsICJQdHIiLCBzZGMpDQoJcmV0dXJuIE9jckJpdG1hcFRleHQoaGJtKQ0KfQ0KDQpPY3JTZWxmVGVzdCgpIHsNCgl3IDo9IDc2MCwgaCA6PSAxMjANCgloYm0gOj0gRGliMzIodywgaCkNCglpZiAoIWhibSkNCgkJcmV0dXJuICIiDQoJaGRjIDo9IERsbENhbGwoIkNyZWF0ZUNvbXBhdGlibGVEQyIsICJQdHIiLCAwLCAiUHRyIikNCglvbGQgOj0gRGxsQ2FsbCgiU2VsZWN0T2JqZWN0IiwgIlB0ciIsIGhkYywgIlB0ciIsIGhibSwgIlB0ciIpDQoJVmFyU2V0Q2FwYWNpdHkocmMsIDE2LCAwKQ0KCU51bVB1dCh3LCByYywgOCwgIkludCIpLCBOdW1QdXQoaCwgcmMsIDEyLCAiSW50IikNCgliciA6PSBEbGxDYWxsKCJDcmVhdGVTb2xpZEJydXNoIiwgIlVJbnQiLCAweEZGRkZGRiwgIlB0ciIpDQoJRGxsQ2FsbCgiRmlsbFJlY3QiLCAiUHRyIiwgaGRjLCAiUHRyIiwgJnJjLCAiUHRyIiwgYnIpDQoJRGxsQ2FsbCgiRGVsZXRlT2JqZWN0IiwgIlB0ciIsIGJyKQ0KCWhmIDo9IERsbENhbGwoIkNyZWF0ZUZvbnQiLCAiSW50IiwgLTQwLCAiSW50IiwgMCwgIkludCIsIDAsICJJbnQiLCAwLCAiSW50IiwgNjAwDQoJCSwgIlVJbnQiLCAwLCAiVUludCIsIDAsICJVSW50IiwgMCwgIlVJbnQiLCAxLCAiVUludCIsIDAsICJVSW50IiwgMCwgIlVJbnQiLCA0LCAiVUludCIsIDAsICJTdHIiLCAiU2Vnb2UgVUkiLCAiUHRyIikNCglvZiA6PSBEbGxDYWxsKCJTZWxlY3RPYmplY3QiLCAiUHRyIiwgaGRjLCAiUHRyIiwgaGYsICJQdHIiKQ0KCURsbENhbGwoIlNldEJrTW9kZSIsICJQdHIiLCBoZGMsICJJbnQiLCAxKQ0KCURsbENhbGwoIlNldFRleHRDb2xvciIsICJQdHIiLCBoZGMsICJVSW50IiwgMHgwMDAwMDApDQoJcyA6PSAiWW91IGp1c3QgY2F1Z2h0IGEgQmlnIFRlc3QgRmlzaCINCglEbGxDYWxsKCJUZXh0T3V0IiwgIlB0ciIsIGhkYywgIkludCIsIDI0LCAiSW50IiwgMzYsICJTdHIiLCBzLCAiSW50IiwgU3RyTGVuKHMpKQ0KCURsbENhbGwoIlNlbGVjdE9iamVjdCIsICJQdHIiLCBoZGMsICJQdHIiLCBvZikNCglEbGxDYWxsKCJEZWxldGVPYmplY3QiLCAiUHRyIiwgaGYpDQoJRGxsQ2FsbCgiU2VsZWN0T2JqZWN0IiwgIlB0ciIsIGhkYywgIlB0ciIsIG9sZCkNCglEbGxDYWxsKCJEZWxldGVEQyIsICJQdHIiLCBoZGMpDQoJdHh0IDo9IE9jckJpdG1hcFRleHQoaGJtKQ0KCURsbENhbGwoIkRlbGV0ZU9iamVjdCIsICJQdHIiLCBoYm0pDQoJcmV0dXJuIHR4dA0KfQ0K"
	return s
}

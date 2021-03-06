{-# LANGUAGE FlexibleContexts #-}

import XMonad
import qualified XMonad.StackSet as W
import XMonad.Actions.CycleWS
import qualified XMonad.Actions.FlexibleManipulate as Flex
import XMonad.Actions.FloatSnap
import XMonad.Config.Kde
import XMonad.Config.Desktop
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.Minimize
import XMonad.Hooks.SetWMName
import XMonad.Hooks.UrgencyHook
import XMonad.Layout.BoringWindows
import XMonad.Layout.Decoration (defaultTheme, Theme (..))
import XMonad.Layout.Fullscreen hiding (fullscreenEventHook)
import XMonad.Layout.Grid
import XMonad.Layout.IM
import XMonad.Layout.Maximize
import XMonad.Layout.Named
import XMonad.Layout.NoBorders hiding (Never)
import XMonad.Layout.PerWorkspace
import XMonad.Layout.Reflect
import XMonad.Layout.SimpleDecoration (shrinkText)
import XMonad.Layout.Tabbed (tabbedAlways, tabbed, addTabsAlways)
import XMonad.Util.EZConfig
import XMonad.Util.NamedScratchpad

import Data.Ratio ((%))
import qualified Data.Map as M

import Utils

myTerminal          = "urxvtc"
myBrowser           = "chromium"
myBrowserPriv       = "chromium --incognito"
myFileManager       = "dolphin"
myRunner            = "kupfer"
myEditor            = "subl3"
myFocusFollowsMouse = True
myModMask           = mod4Mask
myBorderWidth       = 2
myWorkspaces        = ["1:www", "2:subl", "3:fm", "4:misc"] ++ map show [5..9] ++ ["0:video"]
myImWorkspaces      = ["z:im1", "x:im2"]
myScratchpadWS      = "NSP"
myMailWS            = "~:mail"

myNormalBorderColor  = "#aaaaaa"
myFocusedBorderColor = "#ff0000"
myFloatBorderColor = "#00ff00"
myHangoutsAppName = "crx_knipolnnllmklapflnccelgolnpehhpl"
myCompton = "compton -b -f --backend glx --blur-background --vsync opengl --glx-use-gpushader4 -D 4 --sw-opti -e 1 -m 0.8 -G"
--myCompton = "compton -b -f --blur-background --vsync opengl -D 4 --sw-opti -e 1 -m 0.8 -G"
myLockCommand = "/usr/lib/kde4/libexec/kscreenlocker_greet --immediateLock"
myInfoCommand = "sm -f white -b black \"\""

myAddWorkspaces = myImWorkspaces ++ [myMailWS, myScratchpadWS]

-- Skip workspaces on Left-Right switching
skipWS = myWorkspaces!!9 : myAddWorkspaces

myConsoleScratchpads =
    [ ((myModMask, xK_F1), "term1", "zsh")
    , ((myModMask, xK_F2), "term2", "zsh")
    , ((myModMask, xK_F3), "term3", "zsh")
    , ((myModMask, xK_F4), "term4", "zsh")
    , ((myModMask, xK_F5), "bash", "bash") -- backup shell
    , ((myModMask, xK_a ), "top", "htop")
    , ((myModMask, xK_s ), "mc", "mc")
    , ((myModMask, xK_d ), "mpd", "ncmpcpp")
    ]

-- key name command appName
myAppScratchpads =
    [ ((myModMask .|. shiftMask, xK_a), "ksysguard", "ksysguard", "ksysguard")
    , ((myModMask .|. shiftMask, xK_s), "krusader", "krusader", "krusader")
    , ((myModMask .|. shiftMask, xK_d), "kmix", "kmix", "kmix")
    , ((myModMask, xK_F5), "bash", "urxvt -name bash -e bash", "bash") -- backup shell
    ]

scratchpads = [NS name command (appName =? thisAppName) floatingConf | (_,name,command,thisAppName) <- myAppScratchpads]
    ++ [NS name (myTerminal ++ " -name " ++ name ++ " -e " ++ command) (appName =? name) floatingConf | (_,name,command) <- myConsoleScratchpads]
    where
        floatingConf = customFloating $ W.RationalRect (1/24) (1/24) (11/12) (11/12)

myLayoutMods l = lessBorders OnlyFloat
    $ fullscreenFull
    $ desktopLayoutModifiers
    $ boringWindows
    $ maximize
        l

myLayout = onWorkspace (myWorkspaces!!9) videoLayout
    $ onWorkspace (myImWorkspaces!!0) imLayoutP
    $ onWorkspace (myImWorkspaces!!1) imLayoutH
    $ (tiledR ||| tiledB ||| tiledL ||| myTabbed ||| myGrid ||| myFull)
    where
        tiledR = named "Tiled right" $ myLayoutMods $ Tall nmaster delta ratio
        tiledL = named "Tiled left" $ myLayoutMods $ reflectHoriz $ Tall nmaster delta ratio
        tiledB = named "Tiled bottom" $ myLayoutMods $ Mirror $ Tall nmaster delta ratio
        myTabbed = named "Tabbed" $ myLayoutMods $ tabbedAlways shrinkText myTheme
        myGrid = named "Grid" $ myLayoutMods $ Grid
        myFull = named "Full" $ myLayoutMods $ Full

        videoLayout = named "Video Full" $ noBorders Full
        imLayoutP = (imLayoutTemplate "IM Tabbed Pidgin" pidginImProperty Grid)
                ||| (imLayoutTemplate "IM Tiled B Pidgin" pidginImProperty tiledB)
                ||| (imLayoutTemplate "IM Tiled R Pidgin" pidginImProperty tiledR)
        imLayoutH = (imLayoutTemplate "IM Tiled B Hangouts" hangoutsImProperty tiledB)
                ||| (imLayoutTemplate "IM Tiled R Hangouts" hangoutsImProperty tiledR)
                ||| (imLayoutTemplate "IM Grid Hangouts" hangoutsImProperty Grid)

        imLayoutTemplate name property layout = named name $ myLayoutMods $ reflectHoriz $ withIM imRatio property layout
        pidginImProperty = Resource "Pidgin" `And` Role "buddy_list"
        hangoutsImProperty = Resource myHangoutsAppName `And` Title "Hangouts" `And` Role "buddy_list"
        imRatio = 5%20
        nmaster = 1
        ratio   = 3/4
        delta   = 4/100

        myLayoutMods l = lessBorders OnlyFloat
            $ fullscreenFull
            $ desktopLayoutModifiers
            $ boringWindows
            $ maximize
                l

        myTheme = defaultTheme {
            activeColor         = "#DADCDE",
            inactiveColor       = "#B6B9BE",
            urgentColor         = "#FFFF00",
            activeBorderColor   = "#FF0000",
            inactiveBorderColor = "#AAAAAA",
            urgentBorderColor   = "#FF00FF",
            activeTextColor     = "#000000",
            inactiveTextColor   = "#000000",
            urgentTextColor     = "#000000",
            fontName            = "-*-arial-bold-r-normal--*-100-*-*-*-*-*-*",
            decoHeight          = 25
        }

myBrowserQuery = (className =? "Chromium" <&&> appName /=? myHangoutsAppName) <||> className =? "Firefox"
myPidginQuery = className =? "Pidgin"
myHangoutsQuery = appName =? myHangoutsAppName

myManageHook = composeOne [ isKDEOverride -?> doFloat ]
    <+> ((className =? "krunner") >>= return . not --> manageHook kde4Config)
    <+> (composeOne
        [ myPidginQuery                     -?> doShift (myImWorkspaces!!0)
        , myHangoutsQuery                   -?> doShift (myImWorkspaces!!1)
        , myBrowserQuery                    -?> doShift (myWorkspaces!!0)
        , className =? "Kontact"            -?> doShift myMailWS
        , className =? "Thunderbird"        -?> doShift myMailWS
        , className =? "Xmessage"           -?> doFloat
        , className =? "Klipper"            -?> doFloat
        , className =? "Knotes"             -?> doFloat
        , className =? "smplayer"           -?> doShift (myWorkspaces!!9) <+> doSink
        , className =? "Vlc"                -?> doShift (myWorkspaces!!9) <+> doSink
        , className =? "Steam"              -?> doShift (myWorkspaces!!9) <+> doSink
        , className =? "MPlayer"            -?> doFullFloat
        , className =? "Sm"                 -?> doFullFloat
        ] )
    <+> (composeAll
        [ isDialog                          --> doCenterFloat
        , isKDETrayWindow                   --> doIgnore
        ] )
    <+> fullscreenManageHook
    <+> namedScratchpadManageHook scratchpads

myEventHook = fullscreenEventHook

myStartupHook = do
    spawn "killall compton &"
    ewmhDesktopsStartup
    setWMName "LG3D"
    spawn "plasma-desktop"
    spawn "urxvtd"
    spawn "pidgin"
    spawn "kupfer --no-splash"
    spawn $ "sleep 2;" ++ myCompton
    -- spawn "sleep 20; qdbus-qt4 org.kde.kded /kded org.kde.kded.unloadModule ktouchpadenabler; sleep 3; qdbus-qt4 org.kde.kded /kded org.kde.kded.loadModule ktouchpadenabler"
    spawn "thunderbird"
    --spawn "chromium"

myMouseBindings (XConfig {XMonad.modMask = modm}) = M.fromList $
    [ ((modm              , button1), \w -> focus w >> windows W.shiftMaster >> mouseMoveWindow w >> snapMagicMove (Just 50) (Just 50) w)
    , ((modm              , button2), \w -> focus w >> snapMagicMouseResize 50 Nothing Nothing w)
    , ((modm              , button3), \w -> focus w >> Flex.mouseWindow Flex.resize w >> snapMagicMouseResize 50 (Just 50) (Just 50) w)
    , ((modm              , button4), \_ -> focusUp)
    , ((modm .|. shiftMask, button4), \_ -> windows $ W.swapUp)
    , ((modm              , button5), \_ -> focusDown)
    , ((modm .|. shiftMask, button5), \_ -> windows $ W.swapDown)
    ]

myLogHook = do
    colorBorderWhen isFloat myFloatBorderColor
    removeBorderWhen isKDEOverride
    removeBorderWhen (className =? "Klipper")
    removeBorderWhen (className =? "Kupfer.py")
    myDynamicLog

main = xmonad $ withUrgencyHookC BorderUrgencyHook { urgencyBorderColor = "#ff00ff" } urgencyConfig { suppressWhen = Focused } $ ewmh kde4Config {
        terminal           = myTerminal,
        focusFollowsMouse  = myFocusFollowsMouse,
        borderWidth        = myBorderWidth,
        modMask            = myModMask,
        workspaces         = myWorkspaces ++ myAddWorkspaces,
        normalBorderColor  = myNormalBorderColor,
        focusedBorderColor = myFocusedBorderColor,
        mouseBindings      = myMouseBindings,
        layoutHook         = myLayout,
        manageHook         = myManageHook,
        handleEventHook    = myEventHook <+> handleEventHook kde4Config,
        startupHook        = myStartupHook,
        logHook            = myLogHook
    }

    `removeKeys`
        [ (myModMask              , xK_p     )
        , (myModMask .|. shiftMask, xK_p     )
        , (myModMask .|. shiftMask, xK_f     )
        ]

    `additionalKeys` (
        [ ((myModMask .|. shiftMask  , xK_Return), spawn myTerminal)
        , ((myModMask .|. shiftMask  , xK_KP_Enter), spawn myTerminal)
        , ((myModMask                , xK_f   ), withFocused (sendMessage . maximizeRestore))
        , ((myModMask                , xK_w   ), nextScreen)
        , ((myModMask .|. controlMask, xK_w   ), swapNextScreen)
        , ((myModMask                , xK_j   ), focusUp)
        , ((myModMask                , xK_k   ), focusDown)
        , ((myModMask                , xK_Up  ), focusUp)
        , ((myModMask                , xK_Down), focusDown)
        , ((myModMask .|. shiftMask  , xK_Up  ), windows W.swapUp)
        , ((myModMask .|. shiftMask  , xK_Down), windows W.swapDown)
        , ((myModMask                , xK_Tab ), toggleWS' [myScratchpadWS])
        , ((myModMask .|. shiftMask  , xK_Tab ), shiftToggleWS' [myScratchpadWS] >> toggleWS' [myScratchpadWS])
        , ((myModMask                , xK_Left ), viewPrevWS skipWS)
        , ((myModMask                , xK_Right), viewNextWS skipWS)
        , ((myModMask .|. shiftMask  , xK_Left ), shiftPrevWS skipWS >> viewPrevWS skipWS)
        , ((myModMask .|. shiftMask  , xK_Right), shiftNextWS skipWS >> viewNextWS skipWS)
        , ((myModMask                , xK_q   ), spawn myBrowser)
        , ((myModMask .|. shiftMask  , xK_q   ), spawn myBrowserPriv)
        , ((myModMask                , xK_e   ), spawn myFileManager)
        , ((myModMask .|. shiftMask  , xK_e   ), spawn myEditor)
        , ((noModMask                , xK_Scroll_Lock), spawn myLockCommand)
        , ((myModMask                , xK_r   ), spawn myRunner)
        , ((myModMask .|. shiftMask  , xK_r   ), spawn "xprop | xmessage -file -") -- debugging stuff
        --, ((myModMask .|. shiftMask  , xK_p   ), restart "xmonad" True) -- don't work
        , ((myModMask                , xK_i   ), spawn myInfoCommand)
        , ((myModMask                , xK_grave), windows $ W.view myMailWS)
        , ((myModMask .|. shiftMask  , xK_grave), windows $ W.shift myMailWS)
        , ((myModMask .|. controlMask, xK_grave), windows $ W.greedyView myMailWS)
        , ((myModMask                , xK_z), windows $ W.view $ myImWorkspaces!!0)
        , ((myModMask .|. shiftMask  , xK_z), windows $ W.shift $ myImWorkspaces!!0)
        , ((myModMask .|. controlMask, xK_z), windows $ W.greedyView $ myImWorkspaces!!0)
        , ((myModMask                , xK_x), windows $ W.view $ myImWorkspaces!!1)
        , ((myModMask .|. shiftMask  , xK_x), windows $ W.shift $ myImWorkspaces!!1)
        , ((myModMask .|. controlMask, xK_x), windows $ W.greedyView $ myImWorkspaces!!1)
        ] ++ [(key, namedScratchpadAction scratchpads name) | (key,name,_) <- myConsoleScratchpads]
          ++ [(key, namedScratchpadAction scratchpads name) | (key,name,_,_) <- myAppScratchpads]
          ++ [((m .|. myModMask, k), windows $ f i) | (i, k) <- zip myWorkspaces $ [xK_1 .. xK_9] ++ [xK_0], (f, m) <- [(W.view, 0), (W.shift, shiftMask)]]
          ++ [((controlMask .|. myModMask, k), windows $ W.greedyView i) | (i, k) <- zip myWorkspaces $ [xK_1 .. xK_9] ++ [xK_0]]
    )

    `additionalKeysP`
        [ ("<XF86AudioPlay>", spawn "mpc toggle")
        , ("<XF86AudioStop>", spawn "mpc stop")
        , ("<XF86AudioNext>", spawn "mpc next")
        , ("<XF86AudioPrev>", spawn "mpc prev")
        , ("M-<Home>", spawn "mpc toggle")
        , ("M-<End>", spawn "mpc stop")
        , ("M-]", spawn "mpc next")
        , ("M-[", spawn "mpc prev")
        , ("M-<Page_Up>", spawn "mpc volume +5")
        , ("M-<Page_Down>", spawn "mpc volume -5")
        , ("M-S-<Page_Up>", spawn "qdbus org.kde.kmix /kmix/KMixWindow/actions/increase_volume org.qtproject.Qt.QAction.trigger")
        , ("M-S-<Page_Down>", spawn "qdbus org.kde.kmix /kmix/KMixWindow/actions/decrease_volume org.qtproject.Qt.QAction.trigger")
        , ("M-S-<End>", spawn "qdbus org.kde.kmix /kmix/KMixWindow/actions/mute org.qtproject.Qt.QAction.trigger")
        , ("M-<F6>", spawn "xdotool search --name \"Hangouts\" set_window --role \"buddy_list\"")
        ]

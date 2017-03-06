-- vim:foldmethod=marker

-- About {{{
--
-- Module      : xmonad.hs
-- Copyright   : (c) Eric Garrido 2011 
-- License     : Public Domain
--
-- Maintainer  : eric@ekg.com
-- Stability   : unstable
-- Portability : unportable
-- Template    : http://www.haskell.org/haskellwiki/Xmonad/Config_archive/Template_xmonad.hs_(0.8)
-- Inspiration : http://github.com/pbrisbin/xmonad-config
-- 
--
-- }}}

-- Imports {{{

-- my lib
import ScratchPadKeys -- http://pbrisbin.com/xmonad/docs/ScratchPadKeys.html

-- xmonad
import XMonad hiding ((|||))
import qualified XMonad.StackSet as W

-- xmonad-contrib
import XMonad.Actions.CycleWS            (toggleWS)
import XMonad.Actions.FindEmptyWorkspace (tagToEmptyWorkspace, viewEmptyWorkspace)
import XMonad.Actions.Warp               (Corner(..), banishScreen)
import XMonad.Hooks.DynamicLog hiding    (dzen)
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.UrgencyHook
import XMonad.Layout.LayoutCombinators   ((|||), JumpToLayout(..))
import XMonad.Layout.LayoutHints         (layoutHintsWithPlacement)
import XMonad.Layout.NoBorders           (Ambiguity(..), With(..), lessBorders)
import XMonad.Layout.ResizableTile       (ResizableTall(..), MirrorResize(..))
import XMonad.Operations                 (kill)
import XMonad.Prompt
import XMonad.Util.EZConfig              (additionalKeysP)
import XMonad.Util.Loggers               (Logger, maildirNew, dzenColorL, wrapL, shortenL)
import XMonad.Util.Run                   (spawnPipe, safeSpawn)
import XMonad.Util.WorkspaceCompare      (getSortByXineramaRule)

-- general haskell stuff
import Data.Char             (toLower)
import Data.List             (isPrefixOf)
import System.Exit
import System.IO             (Handle, hPutStrLn, hGetContents)
import System.Process        (runInteractiveCommand)
import System.FilePath.Posix (splitFileName)

-- }}}

-- Main {{{
main :: IO ()
main = do
    xmproc <- spawnPipe "xmobar"
    xmonad $ defaultConfig
        { terminal           = "urxvtc"
        , manageHook         = myManageHook
        , layoutHook         = myLayout
        , logHook = dynamicLogWithPP xmobarPP
                      { ppOutput = hPutStrLn xmproc
                      , ppTitle = xmobarColor "green" "" . shorten 50
                      }
        } `additionalKeysP` myKeys

-- }}}

myManageHook = composeAll
                [ className =? "Gimp"   --> doFloat
                , manageDocks]

-- Layouts {{{
--
-- You can specify and transform your layouts by modifying these values.
-- If you change layout bindings be sure to use 'mod-shift-space' after
-- restarting (with 'mod-q') to reset your layout state to the new
-- defaults, as xmonad preserves your old layout settings by default.
--
-- The available layouts.  Note that each layout is separated by |||,
-- which denotes layout choice.
--
myLayout = avoidStruts standardLayouts
    where
        -- a simple Tall, Wide, Full setup but hinted, resizable, and
        -- with smarter borders
        standardLayouts = smart $ Mirror tiled ||| tiled ||| full

        tiled = hinted $ ResizableTall 1 (1/100) golden []
        full  = hinted Full

        -- master:slave set at the golden ratio
        golden = toRational $ 2/(1 + sqrt 5 :: Double)

        -- just like smartBorders but better for a xinerama setup
        smart = lessBorders $ Combine Union OnlyFloat OtherIndicated

        -- like hintedTile but applicable to any layout
        hinted l = layoutHintsWithPlacement (0,0) l

-- }}}

-- Scratchpads {{{

-- | All here-defined scratchpads in a list
scratchPadList :: [ScratchPad]
scratchPadList = [scratchMixer, scratchIRC, scratchTerminal, scratchWifi]

-- | alsamixer center screen
scratchMixer :: ScratchPad
scratchMixer = ScratchPad
    { cmd      = runInTerminal ["-name", "sp-alsamixer", "-e", "alsamixer"]
    , query    = resource =? "sp-alsamixer"
    , hook     = centerScreen 0.65
    }

-- | weechat center screen
scratchIRC :: ScratchPad
scratchIRC = ScratchPad
    { cmd     = runInTerminal ["-name", "sp-weechat", "-e", "weechat-curses"]
    , query   = resource =? "sp-weechat"
    , hook    = centerScreen 0.65
    }

-- | A terminal along the bottom edge
scratchTerminal :: ScratchPad
scratchTerminal = ScratchPad
    { cmd      = runInTerminal ["-name", "sp-term"]
    , query    = resource =? "sp-term"
    , hook     = bottomEdge 0.15
    }

-- | wicd center screen
scratchWifi :: ScratchPad
scratchWifi = ScratchPad
    { cmd     = runInTerminal ["-name", "sp-wicd", "-e", "wicd-curses"]
    , query   = resource =? "sp-wicd"
    , hook    = centerScreen 0.65
    }


-- }}}

-- Key Bindings {{{

myKeys :: [(String, X())]
myKeys = [("M-b"                   , spawn "google-chrome"          ) -- open web client

         -- extended workspace navigations
         , ("M-<Esc>"               , toggleWS                       ) -- switch to the most recently viewed ws
         , ("M-0"                   , viewEmptyWorkspace             ) -- go to next empty workspace
         , ("M-S-0"                 , tagToEmptyWorkspace            ) -- send window to empty workspace and view it

         -- extended window movements
         , ("M-S-o"                 , sendMessage MirrorShrink       ) -- shink slave panes vertically
         , ("M-S-i"                 , sendMessage MirrorExpand       ) -- expand slave panes vertically
         , ("M-f"                   , sendMessage $ JumpToLayout "Hinted Full" ) -- jump to full layout

         -- non-standard screen navigation
         , ("M-h"                   , focusScreen 0                  ) -- focus left screen
         , ("M-l"                   , focusScreen 1                  ) -- focus rght screen
         , ("M-S-h"                 , sendMessage Shrink             ) -- shrink master (was M-h)
         , ("M-S-l"                 , sendMessage Expand             ) -- expand master (was M-l)
         , ("M-S-t"                 , withFocused $ windows . W.sink ) -- push window back into tiling

         -- kill, reconfigure, exit
         , ("M-S-c"                 , kill                           ) -- close currently focused window
         , ("M-q"                   , myRestart                      ) -- restart xmonad
         , ("M-S-q"                 , io (exitWith ExitSuccess)      ) -- logout
         , ("M-x"                   , spawn "xscreensaver-command -lock" ) -- lock screen

         -- Scratchpads
         , ("M-t"                   , spawnScratchpad scratchTerminal  ) -- spawn a terminal in a scratchpad
         , ("M-m"                   , spawnScratchpad scratchIRC       ) -- spawn weechat in a scratchpad
         , ("M-v"                   , spawnScratchpad scratchMixer     ) -- spawn alsamixer in a scratchpad
         , ("M-w"                   , spawnScratchpad scratchWifi      ) -- spawn alsamixer in a scratchpad
         , ("M-y"                   , spawn "xdotool type $(fetchotp)" ) -- fetch an otp over bluetooth and send it to the active window
         , ("M-S-y"                 , spawn "xdotool type $(fetchotp --account='LastPass-eric@ericgar.com')" )
         , ("M-d"                   , spawn "xrandr --auto"            ) -- reconfigure display.
         , ("M-S-d"                 , spawn "/home/ekg/bin/xranr-toggle"  ) -- reconfigure display smartly.

    ] where
        focusScreen n = screenWorkspace n >>= flip whenJust (windows . W.view)
        myRestart = spawn $ "xmonad --recompile && xmonad --restart"

-- }}}
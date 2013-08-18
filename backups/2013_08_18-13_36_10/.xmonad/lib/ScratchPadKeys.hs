-------------------------------------------------------------------------------
-- |
-- Module      :  ScratchPadKeys
-- Copyright   :  (c) Patrick Brisbin 2010 
-- License     :  as-is
--
-- Maintainer  :  pbrisbin@gmail.com
-- Stability   :  unstable
-- Portability :  unportable
--
-- A module very similar to X.U.NamedScratchpad but with my own datatype
-- which forgoes the name and adds a keybind. A list of keybinds is
-- generated in /EZConfig/ notation for the scratchpads in the list and
-- an overall managehook is generated exactly as in the NamedScratchpad
-- module.
-- 
-- The command record is also an X () and not a String, this allows me
-- to pre define some scratchpads here which will auto-magically use
-- your user-defined terminal.
--
-------------------------------------------------------------------------------

module ScratchPadKeys (
    -- * Usage
    -- $usage
    ScratchPad(..),
    manageScratchPads,
    spawnScratchpad,
    runInTerminal,
    -- * ManageHooks
    -- $managehooks
    centerScreen,
    bottomEdge
    ) where

import XMonad
import XMonad.Actions.DynamicWorkspaces  (addHiddenWorkspace)
import XMonad.ManageHook                 (composeAll)
import XMonad.Hooks.ManageHelpers        (doRectFloat)
import Control.Arrow                     ((&&&))
import Control.Monad                     (filterM, when)

import qualified XMonad.StackSet as W

-- $usage
--
-- To use, you'll need to have myManageHook and myKeys defined. myKeys
-- will need to be using /EZConfig/ notation. Then, add the source code
-- for this module to @~\/.xmonad\/lib\/ScratchPadKeys.hs@ and add the
-- following to your @~\/.xmonad\/xmonad.hs@:
--
-- > import ScratchPadKeys
-- > import XMonad.Util.EZConfig (additionalKeysP)
-- >
-- > main :: IO ()
-- > main = xmonad $ defaultConfig
-- >    { ...
-- >    , manageHook = myManageHook
-- >    , ...
-- >    } `additionalKeysP` myKeys
-- >
-- > myManageHook :: ManageHook
-- > myManageHook = [ ...
-- >                , ...
-- >                ] <+> manageScratchPads scratchPadList
-- >
-- > myKeys :: [(String, X())]
-- > myKeys = [ ...
-- >          , ...
-- >          ] ++ scratchPadKeys scratchPadList
--
-- You can define your own scratchpads and scratchpad list or use the
-- one(s) provided by this module.
--

-- | A single scratchpad definition
data ScratchPad = ScratchPad
    { cmd     :: X ()       -- ^ The X action to take ex: spawn \"myapp\"
    , query   :: Query Bool -- ^ The query to find it once it's spawned
    , hook    :: ManageHook -- ^ the way to manage it when it's visible
    }

-- | A helper to execute a command using the user's defined terminal
runInTerminal :: [String] -> X ()
runInTerminal args = asks config >>= \c@XConfig { terminal = t } -> spawn $ unwords (t:args)

-- | Produce a managehook to manage all scratchpads in the passed list
manageScratchPads :: [ScratchPad] -> ManageHook
manageScratchPads = composeAll . fmap (\c -> query c --> hook c)

-- | Summon, banish, or spawn a single 'ScratchPad'
spawnScratchpad :: ScratchPad -> X ()
spawnScratchpad sp = withWindowSet $ \s -> do
    filterCurrent <- filterM (runQuery $ query sp) . 
        maybe [] W.integrate . W.stack . W.workspace $ W.current s

    case filterCurrent of
        (x:_) -> do
            when 
                (null . filter ((== "NSP") . W.tag) $ W.workspaces s) $ 
                addHiddenWorkspace "NSP"

            windows $ W.shiftWin "NSP" x
        [] -> do
            filterAll <- filterM (runQuery $ query sp) $ W.allWindows s

            case filterAll of
                (x:_) -> windows $ W.shiftWin (W.currentTag s) x
                []    -> cmd sp

-- $managehooks
--
-- Some convenient managehooks that I use in my scratchpad definitions.
--

-- | Floating, center screen with a given height
centerScreen :: Rational -> ManageHook
centerScreen h = doRectFloat $ W.RationalRect ((1 - h)/2) ((1 - h)/2) h h

-- | Floating, bottom edge with a given height
bottomEdge :: Rational -> ManageHook
bottomEdge h = doRectFloat $ W.RationalRect 0 (1 - h) 1 h

module Language.Haskell.GhcMod.Debug (debugInfo, rootInfo) where

import Control.Applicative ((<$>))
import CoreMonad (liftIO)
import Data.List (intercalate)
import Data.Maybe (isJust, fromJust)
import Language.Haskell.GhcMod.Convert
import Language.Haskell.GhcMod.Monad
import Language.Haskell.GhcMod.Types
import Language.Haskell.GhcMod.Internal

----------------------------------------------------------------

-- | Obtaining debug information.
debugInfo :: IOish m => GhcModT m String
debugInfo = cradle >>= \c -> convert' =<< do
    CompilerOptions gopts incDir pkgs <-
        if isJust $ cradleCabalFile c then
            fromCabalFile c ||> simpleCompilerOption
          else
            simpleCompilerOption
    return [
        "Root directory:      " ++ cradleRootDir c
      , "Current directory:   " ++ cradleCurrentDir c
      , "Cabal file:          " ++ show (cradleCabalFile c)
      , "GHC options:         " ++ unwords gopts
      , "Include directories: " ++ unwords incDir
      , "Dependent packages:  " ++ intercalate ", " (map showPkg pkgs)
      , "System libraries:    " ++ ghcLibDir
      ]
  where
    simpleCompilerOption = options >>= \op ->
        return $ CompilerOptions (ghcOpts op) [] []
    fromCabalFile c = options >>= \opts -> liftIO $ do
        pkgDesc <- parseCabalFile $ fromJust $ cradleCabalFile c
        getCompilerOptions (ghcOpts opts) c pkgDesc

----------------------------------------------------------------

-- | Obtaining root information.
rootInfo :: IOish m => GhcModT m String
rootInfo = convert' =<< cradleRootDir <$> cradle

-----------------------------------------------------------------------------
-- |
-- Module      : Berp.Compile
-- Copyright   : (c) 2010 Bernie Pope
-- License     : BSD-style
-- Maintainer  : florbitous@gmail.com
-- Stability   : experimental
-- Portability : ghc
--
-- Umbrella module for the compiler.
-- Management of the compilation process from Python to object code and
-- executable code.
--
-----------------------------------------------------------------------------

module Berp.Compile ( compilePythonToObjectFile ) where

import Language.Python.Version3.Parser (parseModule)
import Language.Python.Common.AST (ModuleSpan)
-- import Control.Monad (when)
import Control.Applicative ((<$>))
import Language.Haskell.Exts.Pretty (prettyPrint)
import System.Cmd (system)
-- import System.Exit (ExitCode (..))
-- import System.FilePath ((</>), (<.>), takeBaseName)
import System.FilePath ((<.>), takeBaseName)
import System.Plugins (make, MakeStatus (..))
import Berp.Compile.Compile (compiler)

compilePythonToObjectFile :: FilePath -> IO FilePath
compilePythonToObjectFile path = do
   -- XXX this could fail, and we need a way to find modules in a search path
   fileContents <- readFile path
   pyModule <- parseAndCheckErrors fileContents path
   haskellSrc <- prettyPrint <$> compiler pyModule
   let outputName = takeBaseName path
       haskellFilename = outputName <.> "hs"
       -- interfaceFilename = outputName <.> "hi"
       objectFilename = outputName <.> "o"
   writeFile haskellFilename (haskellSrc ++ "\n")
   -- _exitCodeCompile <- system $ ghcCommand "-O2" "-v0" haskellFilename
   _exitCodeCompile <- system $ ghcCommand "-O2" "-v0" haskellFilename
   return objectFilename
{-
   compileStatus <- make haskellFilename ["-O2", "-v0"]
   case compileStatus of
      MakeFailure _errs -> error "make failed"
      MakeSuccess _makeCode objectPath -> return objectPath
-}

parseAndCheckErrors :: String -> FilePath -> IO ModuleSpan
parseAndCheckErrors fileContents sourceName =
   case parseModule fileContents sourceName of
      Left e -> error $ show e
      Right (pyModule, _comments) -> return pyModule


-- XXX path to ghc should be a parameter
ghcCommand :: String -> String -> String -> String
ghcCommand optimise verbosity inputFile =
   unwords [ghcName, "-c", optimise, verbosity, inputFile]
   where
   ghcName = "ghc"
module Main where

import Spar.Run
import Spar.Options

main :: IO ()
main = runServer =<< getOpts

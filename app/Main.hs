{-# LANGUAGE OverloadedStrings     #-}
module Main where

import Lib
import Migrate

main :: IO ()
main = startApp connectionStr
-- main = migrate -- make this a command line argument
-- cmd args -->
    -- run_schema
    -- env (prod/dev --> create DBFunc based on this)
    -- connectionStr

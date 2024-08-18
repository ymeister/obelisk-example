module Main where

import Obelisk.Frontend
import Reflex.Dom

import Common.Route

import Frontend



main :: IO ()
main = run $ runFrontend checkedFullRouteEncoder frontend

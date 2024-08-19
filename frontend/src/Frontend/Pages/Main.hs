module Frontend.Pages.Main where

import Obelisk.Frontend
import Obelisk.Generated.Static
import Reflex.Dom



mainPage :: ObeliskWidget t route m => m ()
mainPage = do
  el "h1" $ text "Welcome to Obelisk!"
  elAttr "img" ("src" =: (static @"images/obelisk.jpg")) blank

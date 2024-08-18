module Frontend where

import Obelisk.Frontend
import Obelisk.Route
import Reflex.Dom

import Common.Route



frontend :: Frontend (R FrontendRoute)
frontend = Frontend
  { _frontend_head = frontendHead
  , _frontend_body = frontendBody
  }

frontendHead :: Monad m => m ()
frontendHead = blank
  --el "title" $ text "Obelisk Minimal Example"
  --elAttr "script" ("type" =: "application/javascript" <> "src" =: $(static "lib.js")) blank
  --elAttr "link" ("href" =: $(static "main.css") <> "type" =: "text/css" <> "rel" =: "stylesheet") blank

frontendBody :: Monad m => m ()
frontendBody = blank

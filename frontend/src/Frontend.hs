module Frontend where

import Obelisk.Frontend
import Obelisk.Route
import Obelisk.Route.Frontend
import Reflex.Dom

import Common.Route

import Frontend.Pages.Main



frontend :: Frontend (R FrontendRoute)
frontend = Frontend
  { _frontend_head = frontendHead
  , _frontend_body = frontendBody
  }

frontendHead :: ObeliskWidget t route m => RoutedT t route m ()
frontendHead = blank
  --el "title" $ text "Obelisk Minimal Example"
  --elAttr "script" ("type" =: "application/javascript" <> "src" =: $(static "lib.js")) blank
  --elAttr "link" ("href" =: $(static "main.css") <> "type" =: "text/css" <> "rel" =: "stylesheet") blank

frontendBody :: ObeliskWidget t (R FrontendRoute) m => RoutedT t (R FrontendRoute) m ()
frontendBody = subRoute_ $ \case
  FrontendRoute_Main -> mainPage
  FrontendRoute_404 -> blank

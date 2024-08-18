module Common.Route where

import Data.Functor.Identity
import Data.Kind (Type)
import Data.Text (Text)

import Obelisk.Route
import Obelisk.Route.TH



data BackendRoute :: Type -> Type where
  BackendRoute_Api :: BackendRoute ()

backendRouteEncoder :: BackendRoute a -> SegmentResult (Either Text) (Either Text) a
backendRouteEncoder = \case
  BackendRoute_Api -> PathSegment "api" $ unitEncoder mempty



data FrontendRoute :: Type -> Type where
  FrontendRoute_Main :: FrontendRoute ()
  FrontendRoute_404 :: FrontendRoute ()

frontendRouteEncoder :: FrontendRoute a -> SegmentResult (Either Text) (Either Text) a
frontendRouteEncoder = \case
  FrontendRoute_Main -> PathEnd $ unitEncoder mempty
  FrontendRoute_404 -> PathSegment "404" $ unitEncoder mempty



concat <$> mapM deriveRouteComponent
  [ ''BackendRoute
  , ''FrontendRoute
  ]



checkedFullRouteEncoder :: Encoder Identity Identity (R (FullRoute BackendRoute FrontendRoute)) PageName
checkedFullRouteEncoder = case checkEncoder fullRouteEncoder of
  Left e -> error $ show e
  Right x -> x

fullRouteEncoder
  :: Encoder (Either Text) Identity (R (FullRoute BackendRoute FrontendRoute)) PageName
fullRouteEncoder = mkFullRouteEncoder
  ((FullRoute_Frontend . ObeliskRoute_App) FrontendRoute_404 :/ ())
  backendRouteEncoder
  frontendRouteEncoder

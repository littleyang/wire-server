{-# LANGUAGE ConstraintKinds            #-}
{-# LANGUAGE DeriveGeneric              #-}
{-# LANGUAGE FlexibleContexts           #-}
{-# LANGUAGE GADTs                      #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE QuasiQuotes                #-}
{-# LANGUAGE ScopedTypeVariables        #-}
{-# LANGUAGE TemplateHaskell            #-}
{-# LANGUAGE TupleSections              #-}
{-# LANGUAGE TypeApplications           #-}
{-# LANGUAGE ViewPatterns               #-}

module Util.Types
  ( BrigReq
  , GalleyReq
  , SparReq
  , TestEnv(..)
  , teMgr
  , teCql
  , teBrig
  , teGalley
  , teSpar
  , teNewIdp
  , teMockIdp
  , teOpts
  , teTstOpts
  , Select
  , ResponseLBS
  , IntegrationConfig(..)
  , TestErrorLabel(..)
  ) where

import Bilge
import Cassandra as Cas
import Control.Exception
import Control.Monad
import Data.Aeson
import Data.Aeson.TH
import Data.String
import Data.String.Conversions
import GHC.Generics (Generic)
import Lens.Micro.TH
import SAML2.WebSSO.Config.TH (deriveJSONOptions)
import Spar.API ()
import Spar.Options as Options
import Spar.Types
import Util.Options

import qualified Data.Aeson as Aeson


type BrigReq   = Request -> Request
type GalleyReq = Request -> Request
type SparReq   = Request -> Request

data TestEnv = TestEnv
  { _teMgr     :: Manager
  , _teCql     :: Cas.ClientState
  , _teBrig    :: BrigReq
  , _teGalley  :: GalleyReq
  , _teSpar    :: SparReq
  , _teNewIdp  :: NewIdP
  , _teMockIdp :: Endpoint
  , _teOpts    :: Opts
  , _teTstOpts :: IntegrationConfig
  }

type Select = TestEnv -> (Request -> Request)

type ResponseLBS = Response (Maybe LBS)

data IntegrationConfig = IntegrationConfig
  { cfgBrig    :: Endpoint
  , cfgGalley  :: Endpoint
  , cfgSpar    :: Endpoint
  , cfgNewIdp  :: NewIdP
  , cfgMockIdp :: Endpoint
  } deriving (Show, Generic)

deriveFromJSON deriveJSONOptions ''IntegrationConfig
makeLenses ''TestEnv


newtype TestErrorLabel = TestErrorLabel { fromTestErrorLabel :: ST }
  deriving (Eq, Show, IsString)

instance FromJSON TestErrorLabel where
  parseJSON = fmap TestErrorLabel . withObject "TestErrorLabel" (.: "label")


-- A quick unit test that serves two purposes: (1) shows that it works (and helped with debugging);
-- (2) demonstrates how to use it.
_unitTestTestErrorLabel :: IO ()
_unitTestTestErrorLabel = do
  let val :: Either String TestErrorLabel
      val = Aeson.eitherDecode "{\"code\":404,\"message\":\"Not found.\",\"label\":\"not-found\"}"
  unless (val == Right "not-found") $
    throwIO . ErrorCall . show $ val

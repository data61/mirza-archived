{-# LANGUAGE CPP                   #-}
{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables   #-}
{-# LANGUAGE TypeFamilies          #-}
{-# LANGUAGE TypeOperators         #-}
{-# LANGUAGE UndecidableInstances  #-}
{-# OPTIONS_GHC -fno-warn-orphans  #-}


module Mirza.SupplyChain.Lib
    ( startApp,
      startApp_nomain,
      UIFlavour(..)
    )
    where

import           Mirza.SupplyChain.API
import qualified Mirza.SupplyChain.AppConfig as AC
import           Mirza.SupplyChain.Model     (User)
import           Mirza.SupplyChain.Service

import           Servant
import           Servant.Swagger.UI

import           Control.Lens                hiding ((.=))
import           Data.ByteString             (ByteString)
import           Data.Swagger
import           Database.PostgreSQL.Simple
import qualified Network.Wai.Handler.Warp    as Warp

import           GHC.Word                    (Word16)

import           Crypto.Scrypt               (ScryptParams, defaultParams)
import qualified Data.Pool                   as Pool


startApp :: ByteString -> AC.EnvType -> Word16 -> UIFlavour -> ScryptParams -> IO ()
startApp dbConnStr envT prt uiFlavour params = do
    connpool <- Pool.createPool (connectPostgreSQL dbConnStr) close
                        1 -- Number of "sub-pools",
                        60 -- How long in seconds to keep a connection open for reuse
                        10 -- Max number of connections to have open at any one time
                        -- TODO: Make this a config parameter

    let
        context = AC.SCSContext envT connpool params
        app     = return $ webApp context uiFlavour
    putStrLn $ "http://localhost:" ++ show prt ++ "/swagger-ui/"
    Warp.run (fromIntegral prt) =<< app

-- easily start the app in ghci, no command line arguments required.
startApp_nomain :: ByteString -> IO ()
startApp_nomain dbConnStr = startApp dbConnStr AC.Dev 8000 Original defaultParams

-- Application = Request -> (Response -> IO ResponseReceived) -> IO ResponseReceived
webApp :: AC.SCSContext -> UIFlavour -> Application
webApp context uiFlavour = serveWithContext api (basicAuthServerContext context) (server' context uiFlavour)

-- Implementation

-- | We test different ways to nest API, so we have an enumeration
data Variant
    = Normal
    | Nested
    | SpecDown
    deriving (Eq)

data UIFlavour
    = Original
    | JensOleG
    deriving (Eq, Read, Show)

server' :: AC.SCSContext -> UIFlavour -> Server API'
server' context uiFlavour = server Normal
        :<|> server Nested
        :<|> schemaUiServer (serveSwaggerAPI' SpecDown)
  where

    -- appProxy = Proxy :: Proxy AC.AppM
    server :: Variant -> Server API
    server variant =
      schemaUiServer (serveSwaggerAPI' variant)
        :<|> hoistServerWithContext
                (Proxy :: Proxy ServerAPI)
                (Proxy :: Proxy '[BasicAuthCheck User])
                (appMToHandler context)
                appHandlers
    -- mainServer = enter (appMToHandler context) (server Normal)
    schemaUiServer
        :: (Server api ~ Handler Swagger)
        => Swagger -> Server (SwaggerSchemaUI' dir api)
    schemaUiServer = case uiFlavour of
        Original -> swaggerSchemaUIServer
        JensOleG -> jensolegSwaggerSchemaUIServer

    serveSwaggerAPI' Normal    = serveSwaggerAPI
    serveSwaggerAPI' Nested    = serveSwaggerAPI
        & basePath ?~ "/nested"
        & info.description ?~ "Nested API"
    serveSwaggerAPI' SpecDown  = serveSwaggerAPI
        & info.description ?~ "Spec nested"
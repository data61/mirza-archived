{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeApplications #-}

module Mirza.BusinessRegistry.Tests.Client where

import           Mirza.BusinessRegistry.Tests.Settings  (testDbConnStr)

import           Control.Concurrent                     (ThreadId, forkIO,
                                                         killThread)
import           Control.Exception                      (bracket)
import           System.IO.Unsafe                       (unsafePerformIO)

import qualified Network.HTTP.Client                    as C
import           Network.Socket
import qualified Network.Wai                            as Wai
import           Network.Wai.Handler.Warp

import           Servant.API.BasicAuth
import           Servant.Client

import           Data.Either
import           Data.Text.Encoding                     (encodeUtf8)

import           Test.Hspec.Expectations
import           Test.Tasty
import           Test.Tasty.HUnit

import           Database.Beam.Query
import           Mirza.BusinessRegistry.Client.Servant
import           Mirza.BusinessRegistry.Database.Schema
import           Mirza.BusinessRegistry.Main            (GlobalOptions (..),
                                                         RunServerOptions (..),
                                                         initApplication,
                                                         initBRContext)
import           Mirza.BusinessRegistry.Types


import           Data.GS1.EPC                           (GS1CompanyPrefix (..))


import           Katip                                  (Severity (InfoS))

-- Cribbed from https://github.com/haskell-servant/servant/blob/master/servant-client/test/Servant/ClientSpec.hs

-- === Servant Client tests

-- *****************************************************************************
-- Test Data
-- *****************************************************************************

userABC :: NewUser
userABC = NewUser
  { newUserPhoneNumber = "0400 111 222"
  , newUserEmailAddress = EmailAddress "abc@example.com"
  , newUserFirstName = "Johnny"
  , newUserLastName = "Smith"
  , newUserCompany = GS1CompanyPrefix "something"
  , newUserPassword = "re4lly$ecret14!"}

authABC :: BasicAuthData
authABC = BasicAuthData
  (encodeUtf8 . getEmailAddress . newUserEmailAddress $ userABC)
  (encodeUtf8 . newUserPassword                      $ userABC)


newBusinessToBusinessResponse :: NewBusiness -> BusinessResponse
newBusinessToBusinessResponse business = (BusinessResponse
                                          <$> newBusinessGs1CompanyPrefix
                                          <*> newBusinessName)
                                          business

makeNewBusiness :: GS1CompanyPrefix -> Text -> NewBusiness
makeNewBusiness prefix name = NewBusiness prefix name


clientSpec :: IO TestTree
clientSpec = do
  ctx <- initBRContext go
  let BusinessRegistryDB usersTable businessesTable keysTable
        = businessRegistryDB

  res <- runAppM @_ @BusinessRegistryError ctx $ runDb $ do
      let deleteTable table = pg $ runDelete $ delete table (const (val_ True))
      deleteTable keysTable
      deleteTable usersTable
      deleteTable businessesTable

  res `shouldSatisfy` isRight

  let businessTests = testCaseSteps "Can create businesses" $ \step ->
        bracket runApp endWaiApp $ \(_tid,baseurl) -> do
          let http = runClient baseurl
              primaryBusiness = makeNewBusiness (GS1CompanyPrefix "prefix") "Name"
              primaryBusinessResponse = newBusinessToBusinessResponse primaryBusiness
              secondaryBusiness =  makeNewBusiness (GS1CompanyPrefix "prefixSecondary") "NameSecondary"
              secondaryBusinessResponse = newBusinessToBusinessResponse secondaryBusiness


          step "Can create a new business"
          http (addBusiness primaryBusiness)
            `shouldSatisfyIO` isRight
          -- TODO: Check that the output is correct.

          step "That the added business was added and can be listed."
          http listBusiness >>=
            either (const $ expectationFailure "Error listing businesses")
                  (`shouldContain` [ primaryBusinessResponse])

          step "Can't add business with the same GS1CompanyPrefix"
          http (addBusiness primaryBusiness{newBusinessName = "Another name"})
            `shouldSatisfyIO` isLeft
          -- TODO: Check that the error type is correct / meaningful.

          step "Can add a second business"
          http (addBusiness secondaryBusiness)
            `shouldSatisfyIO` isRight

          step "List businesses returns all of the businesses"
          http listBusiness >>=
              either (const $ expectationFailure "Error listing businesses")
                    (`shouldContain` [ primaryBusinessResponse
                                        , secondaryBusinessResponse])

  pure $ testGroup "Business Registry HTTP Client tests"
        [ businessTests
        ]
-- |
-- @action \`shouldReturn\` expected@ sets the expectation that @action@
-- returns @expected@.
shouldSatisfyIO :: (HasCallStack, Show a, Eq a) => IO a -> (a -> Bool) -> Expectation
action `shouldSatisfyIO` p = action >>= (`shouldSatisfy` p)


go :: GlobalOptions
go = GlobalOptions testDbConnStr 14 8 1 DebugS Dev

runApp :: IO (ThreadId, BaseUrl)
runApp = do
  ctx <- initBRContext go
  startWaiApp =<< initApplication go (RunServerOptions 8000) ctx

startWaiApp :: Wai.Application -> IO (ThreadId, BaseUrl)
startWaiApp app = do
    (prt, sock) <- openTestSocket
    let settings = setPort prt defaultSettings
    thread <- forkIO $ runSettingsSocket settings sock app
    return (thread, BaseUrl Http "localhost" prt "")

endWaiApp :: (ThreadId, BaseUrl) -> IO ()
endWaiApp (thread, _) = killThread thread

openTestSocket :: IO (Port, Socket)
openTestSocket = do
  s <- socket AF_INET Stream defaultProtocol
  localhost <- inet_addr "127.0.0.1"
  bind s (SockAddrInet aNY_PORT localhost)
  listen s 1
  prt <- socketPort s
  return (fromIntegral prt, s)

{-# NOINLINE manager' #-}
manager' :: C.Manager
manager' = unsafePerformIO $ C.newManager C.defaultManagerSettings

runClient :: BaseUrl -> ClientM a  -> IO (Either ServantError a)
runClient baseUrl' x = runClientM x (mkClientEnv manager' baseUrl')

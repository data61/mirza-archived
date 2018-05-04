module Tests.Client where

import           Control.Concurrent       (ThreadId, forkIO, killThread)
import           System.IO.Unsafe         (unsafePerformIO)

import qualified Network.HTTP.Client      as C
import           Network.Socket
import qualified Network.Wai              as Wai
import           Network.Wai.Handler.Warp

import           Servant.API.BasicAuth
import           Servant.Client

import           Data.Bifunctor
import           Data.Either              (isLeft, isRight)
import           Data.Text.Encoding       (encodeUtf8)

import           Crypto.Scrypt            (defaultParams)


import           Test.Tasty.Hspec

import           AppConfig                (EnvType (..))
import           Lib
import           Migrate                  (testDbConnStr)
import           Model

import           Data.GS1.EPC             (GS1CompanyPrefix (..))

import           Mirza.Client.Servant

-- Cribbed from https://github.com/haskell-servant/servant/blob/master/servant-client/test/Servant/ClientSpec.hs

-- === Servant Client tests

userABC :: NewUser
userABC = NewUser
  { phoneNumber = "0400 111 222"
  , emailAddress = EmailAddress "abc@example.com"
  , firstName = "Johnny"
  , lastName = "Smith"
  , company = GS1CompanyPrefix "something"
  , password = "re4lly$ecret14!"}

authABC :: BasicAuthData
authABC = BasicAuthData
  (encodeUtf8 . unEmailAddress . emailAddress $ userABC)
  (encodeUtf8 . password                      $ userABC)

clientSpec :: Spec
clientSpec =
  beforeAll (startWaiApp =<< buildApp testDbConnStr Dev Original defaultParams) $
  afterAll endWaiApp $ do
    describe "SupplyChain.Client new user" $ do
      it "Can create a new user" $ \(_,baseurl) -> do
        res <- first show <$> runClient (newUser userABC) baseurl
        res `shouldSatisfy` isRight

      it "Can't reuse email address" $ \(_,baseurl) -> do
        res <- first show <$> runClient (newUser userABC) baseurl
        res `shouldSatisfy` isLeft

    describe "BasicAuth" $ do
      it "Should be able to authenticate" $ \(_,baseurl) -> do
        res <- first show <$> runClient (contactsInfo authABC) baseurl
        res `shouldBe` Right []

-- Plumbing

startWaiApp :: Wai.Application -> IO (ThreadId, BaseUrl)
startWaiApp app = do
    (port, sock) <- openTestSocket
    let settings = setPort port $ defaultSettings
    thread <- forkIO $ runSettingsSocket settings sock app
    return (thread, BaseUrl Http "localhost" port "")


endWaiApp :: (ThreadId, BaseUrl) -> IO ()
endWaiApp (thread, _) = killThread thread

openTestSocket :: IO (Port, Socket)
openTestSocket = do
  s <- socket AF_INET Stream defaultProtocol
  localhost <- inet_addr "127.0.0.1"
  bind s (SockAddrInet aNY_PORT localhost)
  listen s 1
  port <- socketPort s
  return (fromIntegral port, s)



{-# NOINLINE manager' #-}
manager' :: C.Manager
manager' = unsafePerformIO $ C.newManager C.defaultManagerSettings

runClient :: ClientM a -> BaseUrl -> IO (Either ServantError a)
runClient x baseUrl' = runClientM x (mkClientEnv manager' baseUrl')


-- defaultEnv :: IO Env
-- defaultEnv = (\conn -> Env Dev conn Scrypt.defaultParams) <$> defaultPool

-- defaultPool :: IO (Pool Connection)
-- defaultPool = Pool.createPool (connectPostgreSQL testDbConnStr) close
--                 1 -- Number of "sub-pools",
--                 60 -- How long in seconds to keep a connection open for reuse
--                 10 -- Max number of connections to have open at any one time


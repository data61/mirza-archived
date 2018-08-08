{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables   #-}

module Mirza.SupplyChain.Handlers.Signatures
  (
    addUserToEvent
  , eventSign, getEventJSON, makeDigest, insertSignature, eventHashed
  ) where

import           Mirza.Common.Time
import           Mirza.Common.Utils
import           Mirza.SupplyChain.Handlers.Common
import           Mirza.SupplyChain.Handlers.EventRegistration (hasUserCreatedEvent,
                                                               insertUserEvent)

import qualified Mirza.SupplyChain.QueryUtils                 as QU
import qualified Mirza.SupplyChain.StorageBeam                as SB
import           Mirza.SupplyChain.Types                      hiding
                                                               (NewUser (..),
                                                               User (userId),
                                                               UserId)
import qualified Mirza.SupplyChain.Types                      as ST

import qualified Data.GS1.EventId                             as EvId

import           Database.Beam                                as B
import           Database.Beam.Backend.SQL.BeamExtensions

import qualified OpenSSL.EVP.Digest                           as EVPDigest
import           OpenSSL.EVP.PKey                             (toPublicKey)
import           OpenSSL.EVP.Verify                           (VerifyStatus (..),
                                                               verifyBS)
import           OpenSSL.PEM                                  (readPublicKey)
import           OpenSSL.RSA                                  (RSAPubKey)

import           Control.Lens                                 hiding ((.=))
import           Control.Monad.Error.Hoist                    ((<!?>), (<%?>))

import qualified Data.ByteString.Base64                       as BS64
import qualified Data.ByteString.Char8                        as BSC
import           Data.Char                                    (toLower)
import           Data.Text                                    (pack)
import qualified Data.Text                                    as T

-- | A function to tie a user to an event
-- Populates the ``UserEvents`` table
addUserToEvent :: SCSApp context err
               => ST.User
               -> ST.UserId
               -> EvId.EventId
               -> AppM context err ()
addUserToEvent (User loggedInUserId _ _) anotherUserId eventId =
    runDb $ addUserToEventQuery (EventOwner loggedInUserId) (SigningUser anotherUserId) eventId

addUserToEventQuery :: AsServiceError err
                    => EventOwner
                    -> SigningUser
                    -> EvId.EventId
                    -> DB context err ()
addUserToEventQuery (EventOwner lUserId@(ST.UserId loggedInUserId))
                (SigningUser (ST.UserId otherUserId))
                evId@(EvId.EventId eventId) = do
  userCreatedEvent <- hasUserCreatedEvent lUserId evId
  if userCreatedEvent
    then insertUserEvent
            (SB.EventId eventId)
            (SB.UserId loggedInUserId)
            (SB.UserId otherUserId)
            False Nothing
    else throwing _EventPermissionDenied (lUserId, evId)

{-
   The default padding is PKCS1-1.5, which is deprecated
   for new applications. We should be using PSS instead.

   In the OpenSSL wrapper, the verify function in generic,
   and does not allow you to specify a padding type, as this
   is an RSA specific property.

   I propose we modify OpenSSL to add a function called
   verifyBSRSA :: Digest -> BS -> key -> BS -> PaddingType -> IO VerifyStatus

   We'll need to use the foreign function interface to call:
   EVP_PKEY_CTX_set_rsa_padding in libSSL.

   Lets do this after we have everything compiling.
-}

eventSign :: (AsServiceError err, SCSApp context err)
          => ST.User
          -> SignedEvent
          -> AppM context err PrimaryKeyType
eventSign _user (SignedEvent eventId keyId (Signature sigStr) digest') = runDb $ do
  event <- getEventJSON eventId
  rsaPublicKey <- getPublicKey keyId
  sigBS <- BS64.decode (BSC.pack sigStr) <%?> review _InvalidSignature
  let (PEMString keyStr) = rsaPublicKey
  (pubKey :: RSAPubKey) <- liftIO (toPublicKey <$> readPublicKey keyStr) <!?> review _InvalidRSAKeyInDB (pack keyStr)
  let eventBS = QU.eventTxtToBS event
  digest <- liftIO (makeDigest digest') <!?> review _InvalidDigest digest'
  verifyStatus <- liftIO $ verifyBS digest sigBS pubKey eventBS
  if verifyStatus == VerifySuccess
    then insertSignature eventId keyId (Signature sigStr) digest'
    else throwing _InvalidSignature sigStr

-- TODO: Should this return Text or a JSON value?
getEventJSON :: AsServiceError err => EvId.EventId -> DB context err T.Text
getEventJSON eventId = do
  r <- pg $ runSelectReturningList $ select $ do
    allEvents <- all_ (SB._events SB.supplyChainDb)
    guard_ ((SB.event_id allEvents) ==. val_ (EvId.unEventId eventId))
    pure (SB.event_json allEvents)
  case r of
    [jsonEvent] -> return jsonEvent
    _           -> throwing _InvalidEventId eventId

-- TODO: ``getPublicKey`` should come from BR.Client
-- import the client in the file
getPublicKey :: AsServiceError err =>  KeyId -> DB context err PEM_RSAPubKey
getPublicKey (KeyId keyId) = do
  r <- pg $ runSelectReturningList $ select $ do
    allKeys <- all_ (SB._keys SB.supplyChainDb)
    guard_ (SB.key_id allKeys ==. val_ keyId)
    pure (SB.key_pem_str allKeys)
  case r of
    [k] -> return $ PEMString $ T.unpack k
    _   -> throwing _InvalidKeyId . KeyId $ keyId

makeDigest :: Digest -> IO (Maybe EVPDigest.Digest)
makeDigest = EVPDigest.getDigestByName . map toLower . show


insertSignature :: (AsServiceError err) => EvId.EventId
                -> KeyId
                -> Signature
                -> Digest
                -> DB environmentUnused err PrimaryKeyType

insertSignature eId kId (Signature sig) digest = do
  sigId <- newUUID
  timestamp <- generateTimestamp
  r <- pg $ runInsertReturningList (SB._signatures SB.supplyChainDb) $
        insertValues
        [(SB.Signature sigId) (SB.EventId $ EvId.unEventId eId)
         (SB.KeyId $ getKeyId kId) (BSC.pack sig)
          (BSC.pack $ show digest) (toDbTimestamp timestamp)]
  case r of
    [rowId] -> return ( SB.signature_id rowId)
    _       -> throwing _BackendErr "Failed to add signature"


-- do we need this?
--
eventHashed :: ST.User -> EvId.EventId -> AppM context err HashedEvent
eventHashed _user _eventId = error "not implemented yet"
-- return (HashedEvent eventId (EventHash "Blob"))

{-
eventHashed user eventId = do
  mHash <- liftIO $ Storage.eventHashed user eventId
  case mHash of
    Nothing -> throwError err404 { errBody = "Unknown eventId" }
    Just i -> return i
-}
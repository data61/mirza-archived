{-# LANGUAGE MultiParamTypeClasses #-}

module Mirza.BusinessRegistry.Handlers.Users
  (
    addUser
  , getUserByIdQuery
  , tableToAuthUser
  ) where

import           Mirza.BusinessRegistry.Database.Schema   hiding (UserId)
import           Mirza.BusinessRegistry.Database.Schema   as Schema

import           Mirza.BusinessRegistry.Handlers.Common
import qualified Mirza.BusinessRegistry.Types             as BRT
import           Mirza.Common.Utils

import           Database.Beam                            as B
import           Database.Beam.Backend.SQL.BeamExtensions

import qualified Crypto.Scrypt                            as Scrypt

import           Control.Lens                             (view, _2)
import           Control.Monad                            (when)
import           Control.Monad.IO.Class                   (liftIO)
import           Data.Maybe                               (isNothing)
import           Data.Text.Encoding                       (encodeUtf8)



addUser ::  (BRApp context err, BRT.HasScryptParams context)
        => BRT.NewUser
        -> BRT.AppM context err BRT.UserId
addUser = BRT.runDb . addUserQuery


-- | Hashes the password of the BRT.NewUser and inserts the user into the database
addUserQuery :: (BRT.AsBusinessRegistryError err, BRT.HasScryptParams context)
             => BRT.NewUser
             -> BRT.DB context err BRT.UserId
addUserQuery (BRT.NewUser (BRT.EmailAddress email) password companyPrefix firstName lastName phone) = do
  params <- view $ _2 . BRT.scryptParams
  encPass <- liftIO $ Scrypt.encryptPassIO params (Scrypt.Pass $ encodeUtf8 password)
  userId <- newUUID

  bizs <- BRT.pg $ runSelectReturningOne $ select $ do
    bizes <- all_ (Schema._businesses Schema.businessRegistryDB)
    guard_ (biz_gs1_company_prefix bizes ==. val_ companyPrefix)
    pure bizes
  when (isNothing bizs) $ BRT.throwing_ BRT._BusinessDoesNotExistBRE

  -- TODO: use Database.Beam.Backend.SQL.runReturningOne?
  res <- BRT.pg $ runInsertReturningList (Schema._users Schema.businessRegistryDB) $
      insertValues
       [Schema.UserT userId (Schema.BizId companyPrefix) firstName lastName
               phone (Scrypt.getEncryptedPass encPass) email
       ]
  case res of
      [r] -> return $ BRT.UserId $ user_id r
      -- TODO: Have a proper error response
      _   -> BRT.throwing BRT._UserCreationErrorBRE (show res)


getUserByIdQuery :: BRT.UserId -> BRT.DB context err (Maybe Schema.User)
getUserByIdQuery (BRT.UserId uid) = do
  r <- BRT.pg $ runSelectReturningList $ select $ do
          user <- all_ (Schema._users Schema.businessRegistryDB)
          guard_ (user_id user ==. val_ uid)
          pure user
  case r of
    [user] -> return $ Just user
    _      -> return Nothing


-- | Converts a BRT.DB representation of ``User`` to ``AuthUser``
tableToAuthUser :: Schema.User -> BRT.AuthUser
tableToAuthUser tUser = BRT.AuthUser (BRT.UserId $ Schema.user_id tUser)

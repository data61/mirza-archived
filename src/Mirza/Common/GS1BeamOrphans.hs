{-# LANGUAGE DeriveGeneric         #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE PartialTypeSignatures #-}
{-# LANGUAGE TemplateHaskell       #-}
{-# LANGUAGE UndecidableInstances  #-}
{-# OPTIONS_GHC -fno-warn-orphans  #-}

-- | This module includes all of the orphaned instances for GS1 types for use with Beam.
-- | This module contains the
-- Database.Beam.BPostgres.Postgres.Syntax.BMigrate.DataType definitions
-- At the moment, if Database.Beam.BPostgres.Postgres.Syntax is a hidden module
-- So it is not possible to implement the types yet
module Mirza.Common.GS1BeamOrphans
  ( LabelType(..), labelType
  , LocationField(..), locationRefType, locationType
  , srcDestType
  , gs1CompanyPrefixType
  , actionType
  , eventType
  , sglnExtType
  , uomType
  , amountType
  , assetType
  , sgtinFilterValue
  , lotType
  , serialNumType
  , itemRefType
  , emailAddressType
  , locationEPCType
  ) where

import           Mirza.Common.Beam

import qualified Data.GS1.EPC                         as EPC
import qualified Data.GS1.Event                       as Ev

import qualified Database.Beam                        as B
import qualified Database.Beam.Backend.SQL            as BSQL
import qualified Database.Beam.Migrate                as BMigrate
import qualified Database.Beam.Postgres               as BPostgres

import           Database.Beam.Postgres.Syntax        (PgDataTypeSyntax)
import           Database.PostgreSQL.Simple.FromField
import           Database.PostgreSQL.Simple.ToField   (ToField, toField)

import           Data.Text                            (Text)
import           Data.Text.Encoding                   (decodeUtf8, encodeUtf8)

import           GHC.Generics                         (Generic)

import           Control.Lens.Operators               ((&), (.~), (?~))
import           Data.Swagger                         (SwaggerType (SwaggerString),
                                                       ToParamSchema (..))
import           Data.Swagger.Lens                    (pattern, type_)
import           Servant                              (FromHttpApiData (..),
                                                       ToHttpApiData (..))
import           Text.Email.Validate                  (EmailAddress,
                                                       toByteString, validate)


instance ToParamSchema EPC.GS1CompanyPrefix
instance FromHttpApiData EPC.GS1CompanyPrefix where
  -- TODO: Add proper parsing for EPC.GS1CompanyPrefix
  parseUrlPiece = Right . EPC.GS1CompanyPrefix
instance ToHttpApiData EPC.GS1CompanyPrefix where
  toUrlPiece (EPC.GS1CompanyPrefix pfx) = pfx

-- Beam Type definitions

-- ======= Event Type =======

instance BSQL.HasSqlValueSyntax be String =>
  BSQL.HasSqlValueSyntax be Ev.EventType where
    sqlValueSyntax = BSQL.sqlValueSyntax . show
instance (BMigrate.IsSql92ColumnSchemaSyntax be) =>
  BMigrate.HasDefaultSqlDataTypeConstraints be Ev.EventType

instance (BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool,
          BSQL.IsSql92ExpressionSyntax be) =>
          B.HasSqlEqualityCheck be Ev.EventType
instance (BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool,
          BSQL.IsSql92ExpressionSyntax be) =>
          B.HasSqlQuantifiedEqualityCheck be Ev.EventType

instance BSQL.FromBackendRow BPostgres.Postgres Ev.EventType where
  fromBackendRow = defaultFromBackendRow "Ev.EventType"

instance FromField Ev.EventType where
  fromField = defaultFromField "Ev.EventType"

instance ToField Ev.EventType where
  toField = toField . show

eventType :: BMigrate.DataType PgDataTypeSyntax Ev.EventType
eventType = textType

-- ======= EPC.LocationReference =======
instance BSQL.HasSqlValueSyntax be String =>
  BSQL.HasSqlValueSyntax be EPC.LocationReference where
    sqlValueSyntax = BSQL.sqlValueSyntax . show
instance (BMigrate.IsSql92ColumnSchemaSyntax be) =>
  BMigrate.HasDefaultSqlDataTypeConstraints be EPC.LocationReference

instance (BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool,
          BSQL.IsSql92ExpressionSyntax be) =>
          B.HasSqlEqualityCheck be EPC.LocationReference
instance (BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool,
          BSQL.IsSql92ExpressionSyntax be) =>
          B.HasSqlQuantifiedEqualityCheck be EPC.LocationReference

instance BSQL.FromBackendRow BPostgres.Postgres EPC.LocationReference where
  fromBackendRow = defaultFromBackendRow "EPC.LocationReference"

instance FromField EPC.LocationReference where
  fromField = defaultFromField "EPC.LocationReference"

instance ToField EPC.LocationReference where
  toField = toField . show

locationRefType :: BMigrate.DataType PgDataTypeSyntax EPC.LocationReference
locationRefType = textType

-- ======= EPC.SourceDestType =======

instance BSQL.HasSqlValueSyntax be String =>
  BSQL.HasSqlValueSyntax be EPC.SourceDestType where
    sqlValueSyntax = BSQL.sqlValueSyntax . show
instance (BMigrate.IsSql92ColumnSchemaSyntax be) =>
  BMigrate.HasDefaultSqlDataTypeConstraints be EPC.SourceDestType

instance (BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool,
          BSQL.IsSql92ExpressionSyntax be) =>
          B.HasSqlEqualityCheck be EPC.SourceDestType
instance (BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool,
          BSQL.IsSql92ExpressionSyntax be) =>
          B.HasSqlQuantifiedEqualityCheck be EPC.SourceDestType

instance BSQL.FromBackendRow BPostgres.Postgres EPC.SourceDestType where
  fromBackendRow = defaultFromBackendRow "EPC.SourceDestType"

instance FromField EPC.SourceDestType where
  fromField = defaultFromField "EPC.SourceDestType"

instance ToField EPC.SourceDestType where
  toField = toField . show

srcDestType :: BMigrate.DataType PgDataTypeSyntax EPC.SourceDestType
srcDestType = textType

-- ======= EPC.Action =======

instance BSQL.HasSqlValueSyntax be String =>
  BSQL.HasSqlValueSyntax be EPC.Action where
    sqlValueSyntax = BSQL.sqlValueSyntax . show
instance (BMigrate.IsSql92ColumnSchemaSyntax be) =>
  BMigrate.HasDefaultSqlDataTypeConstraints be EPC.Action

instance (BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool,
          BSQL.IsSql92ExpressionSyntax be) =>
          B.HasSqlEqualityCheck be EPC.Action
instance (BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool,
          BSQL.IsSql92ExpressionSyntax be) =>
          B.HasSqlQuantifiedEqualityCheck be EPC.Action

instance BSQL.FromBackendRow BPostgres.Postgres EPC.Action where
  fromBackendRow = defaultFromBackendRow "EPC.Action"

instance FromField EPC.Action where
  fromField = defaultFromField "EPC.Action"

instance ToField EPC.Action where
  toField = toField . show

actionType :: BMigrate.DataType PgDataTypeSyntax EPC.Action
actionType = textType

-- ======= EPC.SGTINFilterValue ========

instance BSQL.HasSqlValueSyntax be String =>
  BSQL.HasSqlValueSyntax be EPC.SGTINFilterValue where
    sqlValueSyntax = BSQL.sqlValueSyntax . show
instance (BMigrate.IsSql92ColumnSchemaSyntax be) =>
  BMigrate.HasDefaultSqlDataTypeConstraints be EPC.SGTINFilterValue

instance FromField EPC.SGTINFilterValue where
  fromField = defaultFromField "SGTINFilterValue"

instance (BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool,
          BSQL.IsSql92ExpressionSyntax be) =>
          B.HasSqlEqualityCheck be EPC.SGTINFilterValue
instance (BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool,
          BSQL.IsSql92ExpressionSyntax be) =>
          B.HasSqlQuantifiedEqualityCheck be EPC.SGTINFilterValue

instance BSQL.FromBackendRow BPostgres.Postgres EPC.SGTINFilterValue where
  fromBackendRow = defaultFromBackendRow "EPC.SGTINFilterValue"

sgtinFilterValue :: BMigrate.DataType PgDataTypeSyntax EPC.SGTINFilterValue
sgtinFilterValue = textType

-- ======= LocationField ========

-- | The record fields in Data.GS1.DWhere for the data type DWhere
data LocationField =
    Src
  | Dest
  | BizLocation
  | ReadPoint deriving (Generic, Show, Eq, Read)

instance BSQL.HasSqlValueSyntax be String =>
  BSQL.HasSqlValueSyntax be LocationField where
    sqlValueSyntax = BSQL.sqlValueSyntax . show
instance (BMigrate.IsSql92ColumnSchemaSyntax be) =>
  BMigrate.HasDefaultSqlDataTypeConstraints be LocationField

instance (BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool,
          BSQL.IsSql92ExpressionSyntax be) =>
          B.HasSqlEqualityCheck be LocationField
instance (BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool,
          BSQL.IsSql92ExpressionSyntax be) =>
          B.HasSqlQuantifiedEqualityCheck be LocationField

instance BSQL.FromBackendRow BPostgres.Postgres LocationField where
  fromBackendRow = defaultFromBackendRow "LocationField"

instance FromField LocationField where
  fromField = defaultFromField "LocationField"

instance ToField LocationField where
  toField = toField . show

locationType :: BMigrate.DataType PgDataTypeSyntax LocationField
locationType = textType


-- ======= EPC.GS1CompanyPrefix =======

instance BSQL.HasSqlValueSyntax be Text =>
  BSQL.HasSqlValueSyntax be EPC.GS1CompanyPrefix where
    sqlValueSyntax (EPC.GS1CompanyPrefix pfx) = BSQL.sqlValueSyntax pfx
instance (BMigrate.IsSql92ColumnSchemaSyntax be) =>
  BMigrate.HasDefaultSqlDataTypeConstraints be EPC.GS1CompanyPrefix

instance (BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool,
          BSQL.IsSql92ExpressionSyntax be) =>
          B.HasSqlEqualityCheck be EPC.GS1CompanyPrefix
instance (BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool,
          BSQL.IsSql92ExpressionSyntax be) =>
          B.HasSqlQuantifiedEqualityCheck be EPC.GS1CompanyPrefix

instance BSQL.FromBackendRow BPostgres.Postgres EPC.GS1CompanyPrefix where
  fromBackendRow = EPC.GS1CompanyPrefix <$> BSQL.fromBackendRow

instance FromField EPC.GS1CompanyPrefix where
  fromField mbs conv = EPC.GS1CompanyPrefix <$> fromField mbs conv

instance ToField EPC.GS1CompanyPrefix where
  toField (EPC.GS1CompanyPrefix pfx) = toField pfx

gs1CompanyPrefixType :: BMigrate.DataType PgDataTypeSyntax EPC.GS1CompanyPrefix
gs1CompanyPrefixType = textType


-- ======= EPC.SGLNExtension =======

instance BSQL.HasSqlValueSyntax be String =>
  BSQL.HasSqlValueSyntax be EPC.SGLNExtension where
    sqlValueSyntax = BSQL.sqlValueSyntax . show
instance (BMigrate.IsSql92ColumnSchemaSyntax be) =>
  BMigrate.HasDefaultSqlDataTypeConstraints be EPC.SGLNExtension

instance (BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool,
          BSQL.IsSql92ExpressionSyntax be) =>
          B.HasSqlEqualityCheck be EPC.SGLNExtension
instance (BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool,
          BSQL.IsSql92ExpressionSyntax be) =>
          B.HasSqlQuantifiedEqualityCheck be EPC.SGLNExtension

instance BSQL.FromBackendRow BPostgres.Postgres EPC.SGLNExtension where
  fromBackendRow = defaultFromBackendRow "EPC.SGLNExtension"

instance FromField EPC.SGLNExtension where
  fromField = defaultFromField "EPC.SGLNExtension"

instance ToField EPC.SGLNExtension where
  toField = toField . show

sglnExtType :: BMigrate.DataType PgDataTypeSyntax EPC.SGLNExtension
sglnExtType = textType


-- ======= EPC.Uom =======

instance BSQL.HasSqlValueSyntax be String =>
  BSQL.HasSqlValueSyntax be EPC.Uom where
    sqlValueSyntax = BSQL.sqlValueSyntax . show
instance (BMigrate.IsSql92ColumnSchemaSyntax be) =>
  BMigrate.HasDefaultSqlDataTypeConstraints be EPC.Uom

instance (BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool,
          BSQL.IsSql92ExpressionSyntax be) =>
          B.HasSqlEqualityCheck be EPC.Uom
instance (BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool,
          BSQL.IsSql92ExpressionSyntax be) =>
          B.HasSqlQuantifiedEqualityCheck be EPC.Uom

instance BSQL.FromBackendRow BPostgres.Postgres EPC.Uom where
  fromBackendRow = defaultFromBackendRow "EPC.Uom"

instance FromField EPC.Uom where
  fromField = defaultFromField "EPC.Uom"

instance ToField EPC.Uom where
  toField = toField . show

uomType :: BMigrate.DataType PgDataTypeSyntax EPC.Uom
uomType = textType



-- ======= EPC.Amount =======

instance BSQL.HasSqlValueSyntax be String =>
  BSQL.HasSqlValueSyntax be EPC.Amount where
    sqlValueSyntax = BSQL.sqlValueSyntax . show
instance (BMigrate.IsSql92ColumnSchemaSyntax be) =>
  BMigrate.HasDefaultSqlDataTypeConstraints be EPC.Amount

instance (BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool,
          BSQL.IsSql92ExpressionSyntax be) =>
          B.HasSqlEqualityCheck be EPC.Amount
instance (BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool,
          BSQL.IsSql92ExpressionSyntax be) =>
          B.HasSqlQuantifiedEqualityCheck be EPC.Amount

instance BSQL.FromBackendRow BPostgres.Postgres EPC.Amount where
  fromBackendRow = defaultFromBackendRow "EPC.Amount"

instance FromField EPC.Amount where
  fromField = defaultFromField "EPC.Amount"

instance ToField EPC.Amount where
  toField = toField . show

amountType :: BMigrate.DataType PgDataTypeSyntax EPC.Amount
amountType = BMigrate.DataType BSQL.doubleType


-- ======= EPC.AssetType =======

instance BSQL.HasSqlValueSyntax be String =>
  BSQL.HasSqlValueSyntax be EPC.AssetType where
    sqlValueSyntax = BSQL.sqlValueSyntax . show
instance (BMigrate.IsSql92ColumnSchemaSyntax be) =>
  BMigrate.HasDefaultSqlDataTypeConstraints be EPC.AssetType

instance (BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool,
          BSQL.IsSql92ExpressionSyntax be) =>
          B.HasSqlEqualityCheck be EPC.AssetType
instance (BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool,
          BSQL.IsSql92ExpressionSyntax be) =>
          B.HasSqlQuantifiedEqualityCheck be EPC.AssetType

instance BSQL.FromBackendRow BPostgres.Postgres EPC.AssetType where
  fromBackendRow = defaultFromBackendRow "EPC.AssetType"

instance FromField EPC.AssetType where
  fromField = defaultFromField "EPC.AssetType"

instance ToField EPC.AssetType where
  toField = toField . show

assetType :: BMigrate.DataType PgDataTypeSyntax EPC.AssetType
assetType = textType



-- ======= EPC.Lot =======

instance BSQL.HasSqlValueSyntax be String =>
  BSQL.HasSqlValueSyntax be EPC.Lot where
    sqlValueSyntax = BSQL.sqlValueSyntax . show
instance (BMigrate.IsSql92ColumnSchemaSyntax be) =>
  BMigrate.HasDefaultSqlDataTypeConstraints be EPC.Lot

instance (BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool,
          BSQL.IsSql92ExpressionSyntax be) =>
          B.HasSqlEqualityCheck be EPC.Lot
instance (BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool,
          BSQL.IsSql92ExpressionSyntax be) =>
          B.HasSqlQuantifiedEqualityCheck be EPC.Lot

instance BSQL.FromBackendRow BPostgres.Postgres EPC.Lot where
  fromBackendRow = defaultFromBackendRow "EPC.Lot"

instance FromField EPC.Lot where
  fromField = defaultFromField "EPC.Lot"

instance ToField EPC.Lot where
  toField = toField . show

lotType :: BMigrate.DataType PgDataTypeSyntax EPC.Lot
lotType = textType


-- ======= EPC.SerialNumber =======

instance BSQL.HasSqlValueSyntax be String =>
  BSQL.HasSqlValueSyntax be EPC.SerialNumber where
    sqlValueSyntax = BSQL.sqlValueSyntax . show
instance (BMigrate.IsSql92ColumnSchemaSyntax be) =>
  BMigrate.HasDefaultSqlDataTypeConstraints be EPC.SerialNumber

instance (BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool,
          BSQL.IsSql92ExpressionSyntax be) =>
          B.HasSqlEqualityCheck be EPC.SerialNumber
instance (BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool,
          BSQL.IsSql92ExpressionSyntax be) =>
          B.HasSqlQuantifiedEqualityCheck be EPC.SerialNumber

instance BSQL.FromBackendRow BPostgres.Postgres EPC.SerialNumber where
  fromBackendRow = defaultFromBackendRow "EPC.SerialNumber"

instance FromField EPC.SerialNumber where
  fromField = defaultFromField "EPC.SerialNumber"

instance ToField EPC.SerialNumber where
  toField = toField . show

serialNumType :: BMigrate.DataType PgDataTypeSyntax EPC.SerialNumber
serialNumType = textType

-- ======= EPC.ItemReference =======

instance BSQL.HasSqlValueSyntax be String =>
  BSQL.HasSqlValueSyntax be EPC.ItemReference where
    sqlValueSyntax = BSQL.sqlValueSyntax . show
instance (BMigrate.IsSql92ColumnSchemaSyntax be) =>
  BMigrate.HasDefaultSqlDataTypeConstraints be EPC.ItemReference

instance (BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool,
          BSQL.IsSql92ExpressionSyntax be) =>
          B.HasSqlEqualityCheck be EPC.ItemReference
instance (BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool,
          BSQL.IsSql92ExpressionSyntax be) =>
          B.HasSqlQuantifiedEqualityCheck be EPC.ItemReference

instance BSQL.FromBackendRow BPostgres.Postgres EPC.ItemReference where
  fromBackendRow = defaultFromBackendRow "EPC.ItemReference"

instance FromField EPC.ItemReference where
  fromField = defaultFromField "EPC.ItemReference"

instance ToField EPC.ItemReference where
  toField = toField . show

itemRefType :: BMigrate.DataType PgDataTypeSyntax EPC.ItemReference
itemRefType = textType


-- ======= LabelType =======

data LabelType
  = Input
  | Output
  | Parent
  deriving (Generic, Show, Eq, Read)


instance BSQL.HasSqlValueSyntax be String =>
  BSQL.HasSqlValueSyntax be LabelType where
    sqlValueSyntax = BSQL.sqlValueSyntax . show
instance (BMigrate.IsSql92ColumnSchemaSyntax be) =>
  BMigrate.HasDefaultSqlDataTypeConstraints be LabelType

instance (BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool,
          BSQL.IsSql92ExpressionSyntax be) =>
          B.HasSqlEqualityCheck be LabelType
instance (BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool,
          BSQL.IsSql92ExpressionSyntax be) =>
          B.HasSqlQuantifiedEqualityCheck be LabelType

instance BSQL.FromBackendRow BPostgres.Postgres LabelType where
  fromBackendRow = defaultFromBackendRow "LabelType"

instance FromField LabelType where
  fromField = defaultFromField "LabelType"

instance ToField LabelType where
  toField = toField . show

labelType :: BMigrate.DataType PgDataTypeSyntax LabelType
labelType = textType

-- ======= EmailAddress =======

instance BSQL.HasSqlValueSyntax be Text =>
  BSQL.HasSqlValueSyntax be EmailAddress where
    sqlValueSyntax = BSQL.sqlValueSyntax . decodeUtf8 . toByteString
instance (BMigrate.IsSql92ColumnSchemaSyntax be) =>
  BMigrate.HasDefaultSqlDataTypeConstraints be EmailAddress

instance (BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool,
          BSQL.IsSql92ExpressionSyntax be) =>
          B.HasSqlEqualityCheck be EmailAddress
instance (BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool,
          BSQL.IsSql92ExpressionSyntax be) =>
          B.HasSqlQuantifiedEqualityCheck be EmailAddress

emailFromBackendRow :: Text -> EmailAddress
emailFromBackendRow emailTxt =
  let emailByte = encodeUtf8 emailTxt in
    case validate emailByte of
      Right userEmail -> userEmail
      Left reason     -> error reason -- shouldn't ever happen

instance BSQL.FromBackendRow BPostgres.Postgres EmailAddress where
  fromBackendRow = emailFromBackendRow <$> BSQL.fromBackendRow

instance FromField EmailAddress where
  fromField mbs conv = emailFromBackendRow <$> fromField mbs conv

instance ToField EmailAddress where
  toField = toField . decodeUtf8 . toByteString

emailAddressType :: BMigrate.DataType PgDataTypeSyntax EmailAddress
emailAddressType = textType

-- *****************************************************************************
--  Location types
-- *****************************************************************************

-- ====== EPC.LocationEPC ======


instance BSQL.HasSqlValueSyntax be Text
      => BSQL.HasSqlValueSyntax be EPC.LocationEPC where
  sqlValueSyntax = BSQL.sqlValueSyntax . EPC.renderURL
instance BMigrate.IsSql92ColumnSchemaSyntax be
      => BMigrate.HasDefaultSqlDataTypeConstraints be EPC.LocationEPC

instance ( BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool
         , BSQL.IsSql92ExpressionSyntax be)
      => B.HasSqlEqualityCheck be EPC.LocationEPC
instance ( BSQL.HasSqlValueSyntax (BSQL.Sql92ExpressionValueSyntax be) Bool
         , BSQL.IsSql92ExpressionSyntax be)
      => B.HasSqlQuantifiedEqualityCheck be EPC.LocationEPC

instance BSQL.FromBackendRow BPostgres.Postgres EPC.LocationEPC where
  fromBackendRow = either (fail . show) pure . EPC.readURI =<< BSQL.fromBackendRow

instance FromField EPC.LocationEPC where
  fromField fld mbs =
    either (fail . show) pure . EPC.readURI =<< fromField fld mbs

instance ToField EPC.LocationEPC where
  toField = toField . EPC.renderURL

locationEPCType :: BMigrate.DataType PgDataTypeSyntax EPC.LocationEPC
locationEPCType = textType

instance ToHttpApiData EPC.LocationEPC where
  toUrlPiece = toUrlPiece . EPC.renderURL

instance FromHttpApiData EPC.LocationEPC where
  parseUrlPiece = either (fail . show) pure . EPC.readURI

instance ToParamSchema EPC.LocationEPC where
  toParamSchema _ = mempty
    & type_ .~ SwaggerString
    & pattern ?~ "urn:epc:id:sgln:\\d+\\.\\d+(\\.\\d+)?"

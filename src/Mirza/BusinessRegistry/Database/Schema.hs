module Mirza.BusinessRegistry.Database.Schema
  ( module Current
  , migration
  , businessRegistryDB
  , checkedBusinessRegistryDB
  , primaryKey
  ) where

import           Control.Arrow                                ((>>>))

import           Database.Beam                                (DatabaseSettings)
import           Database.Beam.Migrate.Types                  hiding
                                                               (migrateScript)
import           Database.Beam.Postgres                       (PgCommandSyntax,
                                                               Postgres)
import           Database.Beam.Schema.Tables                  (primaryKey)

import           Mirza.BusinessRegistry.Database.Schema.V0002 as Current hiding (migration)

import qualified Mirza.BusinessRegistry.Database.Schema.V0001 as V0001 (migration)
import qualified Mirza.BusinessRegistry.Database.Schema.V0002 as V0002 (migration)


migration :: MigrationSteps PgCommandSyntax () (CheckedDatabaseSettings Postgres Current.BusinessRegistryDB)
migration = migrationStep "Initial commit"      V0001.migration
        >>> migrationStep "Add LocationT table" V0002.migration

businessRegistryDB :: DatabaseSettings Postgres Current.BusinessRegistryDB
businessRegistryDB = unCheckDatabase checkedBusinessRegistryDB

checkedBusinessRegistryDB :: CheckedDatabaseSettings Postgres Current.BusinessRegistryDB
checkedBusinessRegistryDB = evaluateDatabase migration

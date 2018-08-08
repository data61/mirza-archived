
module Main where

import           Mirza.SupplyChain.Tests.Settings

import           Mirza.SupplyChain.Main           hiding (main)
import           Mirza.SupplyChain.Migrate
import           Mirza.SupplyChain.Types          as ST

import           Test.Hspec.Core.Spec             (sequential)
import           Test.Tasty                       hiding (withResource)
import           Test.Tasty.Hspec                 (around, testSpec)
import           Test.Tasty.Runners               (NumThreads (..))

import           Mirza.SupplyChain.Tests.Client
import           Mirza.SupplyChain.Tests.Service  (testServiceQueries)

import           Control.Exception                (bracket)
import           Data.Int
import           Database.Beam.Postgres
import           Database.PostgreSQL.Simple

import           Data.Pool                        (Pool, destroyAllResources,
                                                   withResource)
import qualified Data.Pool                        as Pool

import           Katip                            (Severity (DebugS))

-- dbFunc = withDatabaseDebug putStrLn

-- INTERESTING NOTE ON MIGRATION
-- receive this error if the tables already exist (not in tests anymore since delete them beforehand)
--  uncaught exception: ErrorCall (Data.Either.Combinators.fromRight: Argument takes form 'Left _'
--  CallStack (from HasCallStack):
--    error, called at src/Data/Either/Combinators.hs:106:24 in either-4.4.1.1-6PiwKYkn4v6B4KO2R2Fu1b:Data.Either.Combinators)

-- drop all tables created by migration. Equivalent to, at the time of writing;
-- execute_ conn "DROP TABLE IF EXISTS users, keys, businesses, contacts, labels, what_labels, items, transformations, locations, events, whats, \"bizTransactions\", whys, wheres, whens, \"labelEvents\", \"userEvents\", hashes, blockchain;"
dropTables :: Connection -> IO Int64
dropTables conn =
  --https://stackoverflow.com/questions/3327312/drop-all-tables-in-postgresql
  execute_ conn "DO $$ DECLARE                                                                              \
               \     r RECORD;                                                                              \
               \ BEGIN                                                                                      \
               \     FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = current_schema()) LOOP    \
               \         EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE';         \
               \     END LOOP;                                                                              \
               \ END $$;                                                                                    "


defaultPool :: IO (Pool Connection)
defaultPool = Pool.createPool (connectPostgreSQL testDbConnStr) close
                1 -- Number of "sub-pools",
                60 -- How long in seconds to keep a connection open for reuse
                10 -- Max number of connections to have open at any one time



openConnection :: IO SCSContext
openConnection = do
  connpool <- defaultPool
  _ <- withResource connpool dropTables -- drop tables before so if already exist no problems... means tables get overwritten though
  withResource connpool (tryCreateSchema True)
  initSCSContext (ServerOptions Dev False testDbConnStr 8000 14 8 1 DebugS)

closeConnection :: SCSContext -> IO ()
closeConnection = destroyAllResources . ST._scsDbConnPool

withDatabaseConnection :: (SCSContext -> IO ()) -> IO ()
withDatabaseConnection = bracket openConnection closeConnection

main :: IO ()
main = do
  serviceTests <- testSpec "HSpec" (sequential $ around withDatabaseConnection testServiceQueries)
  clientTests <- testSpec "Client HSpec" clientSpec

  defaultMain $ localOption (NumThreads 1) $ testGroup "tests"
    [ serviceTests
    , clientTests
    ]
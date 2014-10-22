-- |
-- An open API for implementation of specific backend drivers.
module Hasql.Backend where

import Hasql.Backend.Prelude


data Error =
  -- |
  -- Cannot connect to a server.
  CantConnect Text |
  -- |
  -- The connection got interrupted.
  ConnectionLost Text |
  UnexpectedResultStructure Text |
  -- | 
  -- Type, input and parser error.
  UnparsableResult TypeRep ByteString Text |
  -- |
  -- A transaction concurrency conflict, 
  -- whic indicates that it should be retried.
  TransactionConflict
  deriving (Show, Typeable)

instance Exception Error


-- |
-- For reference see
-- <https://en.wikipedia.org/wiki/Isolation_(database_systems)#Isolation_levels the Wikipedia info>.
data IsolationLevel =
  Serializable |
  RepeatableReads |
  ReadCommitted |
  ReadUncommitted


-- |
-- An isolation level and a boolean, 
-- defining, whether the transaction will perform the "write" operations.
type TransactionMode =
  (IsolationLevel, Bool)


-- |
-- A width of a row and a stream of serialized values.
type ResultsStream b =
  (Int, ListT IO (Result b))


-- |
-- A template statement with values for placeholders.
type Statement b =
  (ByteString, [StatementArgument b])


class Backend b where
  -- |
  -- An argument prepared for a statement.
  data StatementArgument b
  -- |
  -- A raw value returned from the database.
  data Result b
  data Connection b
  -- |
  -- Open a connection using the backend's settings.
  connect :: b -> IO (Connection b)
  -- |
  -- Close the connection.
  disconnect :: Connection b -> IO ()
  -- |
  -- Execute a statement.
  execute :: Statement b -> Connection b -> IO ()
  -- |
  -- Execute a statement
  -- and stream the results.
  executeAndStream :: Statement b -> Connection b -> IO (ResultsStream b)
  -- |
  -- Execute a statement
  -- and stream the results using a cursor.
  -- This function will only be used from inside of transactions.
  executeAndStreamWithCursor :: Statement b -> Connection b -> IO (ResultsStream b)
  -- |
  -- Execute a statement,
  -- returning the amount of affected rows.
  executeAndCountEffects :: Statement b -> Connection b -> IO Integer
  -- |
  -- Start a transaction in the specified mode.
  beginTransaction :: TransactionMode -> Connection b -> IO ()
  -- |
  -- Finish the transaction, 
  -- while releasing all the resources acquired with 'executeAndStreamWithCursor'.
  --  
  -- The boolean defines whether to commit the updates,
  -- otherwise it rolls back.
  finishTransaction :: Bool -> Connection b -> IO ()


class Backend b => Mapping b v where
  renderValue :: v -> StatementArgument b
  parseResult :: Result b -> Either Text v




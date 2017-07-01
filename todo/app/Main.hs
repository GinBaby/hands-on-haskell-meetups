{-# LANGUAGE OverloadedStrings #-}

module Main where

import Database.MySQL.Simple
import Data.Monoid ((<>))
import Options.Applicative

import Lib

data Command = New TaskTitle
             | List
             | Update TaskId TaskTitle
             | Delete TaskId
             deriving (Eq, Show)

parserNew :: Parser Command
parserNew = New <$> (TaskTitle <$> strArgument (metavar "TASK_TITLE"))

parserList :: Parser Command
parserList = pure List

parserUpdate :: Parser Command
parserUpdate =  Update <$> (TaskId <$> argument auto (metavar "TASK_ID")) <*> (TaskTitle <$> strArgument (metavar "TASK_TITLE"))

parserDelete :: Parser Command
parserDelete = Delete <$> (TaskId <$> argument auto (metavar "TASK_ID"))

parserCommand :: Parser Command
parserCommand = subparser $
    command "new" (parserNew `withInfo` "Add new entry.") <>
    command "list" (parserList `withInfo` "List tasks.") <>
    command "update" (parserUpdate `withInfo` "Update a task.") <>
    command "delete" (parserDelete `withInfo` "Delete a task.")

parserInfoCommand :: ParserInfo Command
parserInfoCommand = info (parserCommand) (progDesc "Manage todo list.")

withInfo :: Parser a -> String -> ParserInfo a
withInfo opts desc = info (helper <*> opts) $ progDesc desc

main :: IO ()
main = do
    -- Replace the MySQl connection information below:
    let connectInfo = defaultConnectInfo
          { connectHost = "localhost"
          , connectUser = "root"
          , connectPassword = "root"
          , connectDatabase = "todo"
          }
    conn <- connect connectInfo
    result <- query_ conn "SELECT id, title FROM todo;" :: IO [(Int, String)]
    print result
    command <- customExecParser (prefs showHelpOnEmpty) parserInfoCommand
    case command of
      New taskTitle -> newTask taskTitle
      List -> listTasks
      Update taskId taskTitle -> updateTask taskId taskTitle
      Delete taskId -> deleteTask taskId

newTask :: TaskTitle -> IO ()
newTask taskTitle = putStrLn $ "Creating a new task: " ++ (unTaskTitle taskTitle)

listTasks :: IO ()
listTasks = putStrLn "Listing tasks"

updateTask :: TaskId -> TaskTitle -> IO ()
updateTask taskId newTaskTitle = putStrLn $ "Updating task " ++ (show $ unTaskId $ taskId) ++ " with title: " ++ (unTaskTitle newTaskTitle)

deleteTask :: TaskId -> IO ()
deleteTask taskId = putStrLn $ "Deleting task " ++ (show $ unTaskId $ taskId)

-- $ stack exec -- todo new "write"
-- New "write"
-- $ stack exec -- todo delete 1
-- Delete 1

-- $ stack exec -- todo new --help



-- in ghci you can do this to play with it:
-- λ> :main new
-- Missing: TASK_NAME
--
-- Usage: <interactive> new TASK_NAME
--   Add new entry.
-- *** Exception: ExitFailure 1
--
-- λ> :main new "make todo list"
-- New "make todo list"
-- it :: ()
--
-- λ> :main new "write"
-- New "write"
-- it :: ()

module Main where

import Control.Applicative
import Data.Char (isSpace, isPunctuation)
import Data.Validation
import System.Environment (getArgs)

stripUsername :: String -> Maybe String
stripUsername "" = Nothing
stripUsername (x:xs) = 
  case (isSpace x || isPunctuation x) of 
    True -> stripUsername xs
    -- is recursive to strip off as many leading
    -- whitespaces/punctuations as there are
    False -> Just (x:xs)

-- only care about stripping whitespace, not punctuation,
-- off password
stripSpacePwd :: String -> Maybe String
stripSpacePwd "" = Nothing
stripSpacePwd (x:xs) =
  case (isSpace x) of 
    True -> stripSpacePwd xs
    False -> Just (x:xs)


validateLength :: Int
               -> String
               -> Maybe String
validateLength maxLen s =
  if (length s) > maxLen
  then Nothing
  else Just s

newtype Username =
  Username String deriving (Eq, Show)
newtype Password =
  Password String deriving (Eq, Show)

mkName :: String -> Maybe Username
mkName name = 
  case stripUsername name of 
    Nothing -> Nothing
    Just name' -> 
      case validateLength 15 name' of
        Nothing -> Nothing
        Just name'' -> Just (Username name'')
    -- wrote this with case statements first,
    -- because we want the input to validateLength to 
    -- depend on the output of stripUsername -- that is,
    -- we only want to check the length *after* it's been stripped


    -- so we have something sequential, where one result *should depend*
    -- on the output of the former. we do want it to short-circuit if
    -- the strip function returns Nothing. so then we realized...
    -- it's a Monad! so we rewrote the above like this:

mkNm :: String -> Maybe Username
mkNm name = fmap Username (stripUsername name >>= validateLength 15)

-- >>= :: m a -> (a -> m b) -> m b
-- stripUsername name :: Maybe Username ~~ m a (m is Maybe)
-- validateLength :: String -> Maybe Username ~~ (a -> m b)

-- and very similar for the mkPasswd function
mkPasswd :: String -> Maybe Password
mkPasswd pwd = fmap Password (stripSpacePwd pwd >>= validateLength 50)


data User = User Username Password deriving (Eq, Show)

-- for this part, we want to accumulate the errors
-- so we will use the AccValidation type and its Applicative
-- instance to do that

validUser :: String -> AccValidation [String] Username
validUser n =
    case mkNm n of
        Nothing -> AccFailure ["Please enter a valid username."]
        Just name -> AccSuccess name

validPwd :: String -> AccValidation [String] Password
validPwd p = 
    case mkPasswd p of
        Nothing -> AccFailure ["Please enter a valid password."]
        Just pwd -> AccSuccess pwd


mkUser :: String -> String -> AccValidation [String] User
mkUser n p = 
    User <$> validUser n <*> validPwd p

display :: AccValidation [String] User -> IO ()
display avUser = 
  case avUser of
    AccFailure err -> putStrLn (unlines err)
    AccSuccess user -> putStrLn "Success!"


main :: IO ()
main = do
  name <- getLine
  pwd <- getLine
  display (mkUser name pwd)
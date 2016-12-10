{-# LANGUAGE BangPatterns, DisambiguateRecordFields, DuplicateRecordFields, NamedFieldPuns #-}
module Data.ByteString.Xml.Types where

import Control.Lens
import Data.ByteString.Char8 (ByteString)
import Data.Sequence
import Data.Word
import GHC.Stack hiding (SrcLoc)
import Foreign.ForeignPtr       (ForeignPtr, withForeignPtr)

-- Alternative design - a shrunk version of ByteString relative to a ForeignPtr
data Str2 =
  Str { offset :: {-# UNPACK #-} !Int, length :: {-# UNPACK #-} !Int }
  deriving (Eq,Show)

type Str = ByteString

data Attribute =
  Attribute
  { nameA :: !Str,
    value :: !Str
  }
  deriving (Eq, Show)

newtype Source = Source ByteString

data Node =
  Node
  { name       :: !Str,
    source     :: !Source,
    start      :: !Int,
    attributes :: !(Seq Attribute),
    contents   :: !(Seq(Either Str Node))
  }

data Document =
  Doc
  { root :: !Node,
    ptr  :: ForeignPtr Word8
  }


instance Show Node where
  show Node{name,attributes,contents} =
    show (name,attributes,contents)

instance Plated Node where
  plate f (Node n s l a nn) = Node n s l a <$> traverse (traverse f) nn

newtype SrcLoc = SrcLoc Int deriving Show

data Error = Error ErrorType CallStack
data ErrorType =
    UnterminatedComment !SrcLoc
  | UnterminatedTag !Str !SrcLoc
  | ClosingTagMismatch !Str !SrcLoc
  | JunkAtTheEnd !Str !SrcLoc
  | UnexpectedEndOfStream
  | BadAttributeForm !SrcLoc
  | UnfinishedComment !SrcLoc
  | Garbage !SrcLoc
   deriving Show

instance Show Error where
  show (Error etype cs) = show etype ++ prettyCallStack cs


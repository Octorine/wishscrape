{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}

import Data.Aeson as Aeson
  ( FromJSON,
    Result (..),
    Value,
    fromJSON,
  )
import Data.Aeson.KeyMap as Keymap ()
import Data.ByteString.Lazy as BS (writeFile)
import Data.Csv as Csv
  ( DefaultOrdered (..),
    ToNamedRecord (..),
    encodeDefaultOrderedByName,
    header,
    namedRecord,
    (.=),
  )
import Data.Map as M (Map, elems)
import Data.Maybe (fromMaybe)
import qualified Data.Vector as V
import GHC.Generics (Generic)
import Network.HTTP.Simple
  ( getResponseBody,
    getResponseHeader,
    getResponseStatusCode,
    httpJSON,
    parseRequest,
  )
import Network.URI.Encode (encode)

main :: IO ()
main = do
  print "Please enter a Steam username:"
  username <- getLine
  request <-
    parseRequest $
      ( "https://store.steampowered.com/wishlist/id/"
          ++ encode username
          ++ "/wishlistdata"
      )
  response <- httpJSON request
  let wl = fromJSON $ getResponseBody response :: Result Wishlist

  case wl of
    Success (Wishlist wl) -> do
      -- for debugging
      -- mapM_ print $ M.elems wl
      print "Wriing Wishlist File."
      BS.writeFile "wishlist.csv" . encodeDefaultOrderedByName $ makeItem <$> M.elems wl
      print "Done."
    Error e -> print e

makeItem :: WishlistItem -> Output
makeItem WishlistItem {name, subs} =
  Output
    { oName = name,
      oPrice = if V.null subs then "No Price" else price (subs V.! 0),
      oDiscount = show $ if V.null subs then 0 else fromMaybe 0 $ discount_pct (subs V.! 0)
    }

data Wishlist = Wishlist (M.Map String WishlistItem) deriving (Generic, Show)

instance FromJSON Wishlist

data WishlistItem = WishlistItem
  { name :: String,
    subs :: V.Vector Subs
  }
  deriving (Generic, Show)

instance FromJSON WishlistItem

data Subs = Subs
  { price :: String,
    discount_pct :: Maybe Int
  }
  deriving (Generic, Show)

instance FromJSON Subs

wlItems (Wishlist wl) = M.elems wl

data Output = Output
  { oName :: String,
    oPrice :: String,
    oDiscount :: String
  }
  deriving (Show)

instance ToNamedRecord Output where
  toNamedRecord o =
    namedRecord
      [ "Name" Csv..= oName o,
        "Price" Csv..= oPrice o,
        "Discount" Csv..= oDiscount o
      ]

instance DefaultOrdered Output where
  headerOrder _ = header ["Name", "Price", "Discount"]

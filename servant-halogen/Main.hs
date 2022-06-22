{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module Main where

import Data.Aeson
import Data.Functor ((<$>))
import Data.Maybe (fromMaybe)
import Data.Proxy
import Data.Text (Text)
import qualified Data.Text as T
import GHC.Generics
import Lucid
  ( Html,
    body_,
    doctype_,
    h2_,
    head_,
    href_,
    html_,
    lang_,
    link_,
    rel_,
    renderBS,
    script_,
    src_,
    title_,
    type_,
    with,
  )
import Lucid.Base
import Network.HTTP.Types hiding (Header)
import Network.Wai
import Network.Wai.Application.Static
import Network.Wai.Handler.Warp
import Network.Wai.Middleware.Gzip
import Network.Wai.Middleware.RequestLogger
import RIO
import Servant
import Servant.HTML.Lucid
import Servant.Server.Internal
import System.Environment (lookupEnv)
import qualified System.IO as IO

main :: IO.IO ()
main = do
  port <- fmap (fromMaybe 8080 . join . fmap readMaybe) $ lookupEnv "PORT"
  staticFilePath <- fromMaybe "/var/www" <$> lookupEnv "STATIC_FILE_PATH"
  IO.hPutStrLn IO.stderr $ "Running on port " <> show port <> "..."
  run port $ logStdout (compress $ app staticFilePath)
  where
    compress = gzip def {gzipFiles = GzipCompress}

-- | API type
type API = ("static" :> Raw) :<|> Get '[HTML] (Html ())

myAPI :: Proxy API
myAPI = Proxy

app :: FilePath -> Application
app path = serve myAPI (static :<|> return renderIndex)
  where
    static = serveDirectoryWith (defaultWebAppSettings path)

handleIndex :: Application
handleIndex _ respond =
  respond $
    responseLBS
      status200
      [("Content-Type", "text/html")]
      $ renderBS renderIndex

-- https://github.com/haskell-servant/servant-lucid/blob/master/example/Main.hs
-- https://github.com/tryhaskell/tryhaskell/blob/d8b59e71d46cb890935f5c0c6c1d723cc9f78d99/src/TryHaskell.hs#L326-L419
renderIndex :: Html ()
renderIndex = do
  doctype_
  html_ [lang_ "en"] $ do
    head_ $ do
      title_ "hello world"
    body_ $ do
      -- div_ []
      script_ [src_ "/static/frontend.js"] ("" :: String)
  where
    jsRef href =
      with
        (script_ mempty)
        [ makeAttribute "src" href,
          makeAttribute "async" mempty,
          makeAttribute "defer" mempty
        ]

{-# LANGUAGE OverloadedStrings #-}

import           Data.Monoid (mappend)
import           Hakyll
import           System.Process (readProcess)
import           System.FilePath (replaceExtension, takeBaseName)
import           Control.Monad (liftM, filterM, forM_)
import           Data.Map (Map)
import qualified Data.Map as M
import           Data.List (stripPrefix, sortBy, nub)
import           Data.Maybe (fromMaybe)
import           Data.Time.Clock (UTCTime)
import           Data.Time.Format (parseTimeM, defaultTimeLocale)
import           Data.Ord (Down(..), comparing)

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

config :: Configuration
config = defaultConfiguration
    { destinationDirectory = "docs"
    , storeDirectory       = "_cache"
    , tmpDirectory         = "_cache/tmp"
    }

--------------------------------------------------------------------------------
-- Pandoc Compiler
--------------------------------------------------------------------------------

pandocTypstCompilerWithMeta :: Compiler (Item String)
pandocTypstCompilerWithMeta = do
    body <- getResourceBody
    let content = itemBody body
    -- Use pandoc to convert from Typst to HTML
    fp <- getResourceFilePath
    html <- unsafeCompiler $ do
        readProcess "pandoc" ["-f", "typst", "-t", "html5", fp] ""
    
    -- Load metadata from .meta file
    let metaPath = replaceExtension fp "meta"
    metaItem <- load (fromFilePath metaPath)
    let metaMap = parseMetadata (itemBody metaItem)
    
    makeItemWithMetadata html metaMap

parseMetadata :: String -> Map String String
parseMetadata content = M.fromList $ map parseLine $ lines content
  where
    parseLine line = case break (== ':') line of
        (key, ':':' ':value) -> (key, value)
        (key, ':':value) -> (key, value)
        _ -> ("", "")

makeItemWithMetadata :: String -> Map String String -> Compiler (Item String)
makeItemWithMetadata html metaMap = do
    identifier <- getUnderlying
    
    -- Create a new context with the metadata
    let item = Item identifier html
        
    -- Store the raw metadata for later use
    _ <- saveSnapshot "raw-metadata" item
    
    return item

-- Helper functions for tags
splitOnComma :: String -> [String]
splitOnComma str = case break (== ',') str of
    (chunk, []) -> [chunk]
    (chunk, _:rest) -> chunk : splitOnComma rest

trimSpaces :: String -> String  
trimSpaces = reverse . dropWhile (== ' ') . reverse . dropWhile (== ' ')

makeTagUrl :: String -> String
makeTagUrl = map (\c -> if c == ' ' then '-' else c)

hasTag :: String -> Item String -> Compiler Bool
hasTag targetTag item = do
    let identifier = itemIdentifier item
        metaPath = replaceExtension (toFilePath identifier) "meta"
    metaItem <- load (fromFilePath metaPath)
    let metaContent = itemBody metaItem
        metaMap = parseMetadata metaContent
    case M.lookup "tags" metaMap of
        Just tagsStr -> return $ targetTag `elem` map trimSpaces (splitOnComma tagsStr)
        Nothing -> return False

-- Extract all unique tags from all metadata files
extractAllTags :: Rules [String]
extractAllTags = do
    metaFiles <- getMatches "posts/*.meta"
    allTagsLists <- preprocess $ mapM extractTagsFromFile metaFiles
    let allTags = nub $ concat allTagsLists
    return allTags
  where
    extractTagsFromFile :: Identifier -> IO [String]
    extractTagsFromFile metaId = do
        content <- readFile (toFilePath metaId)
        let metaMap = parseMetadata content
        case M.lookup "tags" metaMap of
            Just tagsStr -> return $ map trimSpaces (splitOnComma tagsStr)
            Nothing -> return []

--------------------------------------------------------------------------------
-- Main Site Generation
--------------------------------------------------------------------------------

main :: IO ()
main = hakyllWith config $ do
    -- Copy static files
    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "js/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "fonts/**" $ do
        route   idRoute
        compile copyFileCompiler

    -- Process metadata files
    match "posts/*.meta" $ do
        compile getResourceBody

    -- Create individual tag pages for dynamically extracted tags
    allTags <- extractAllTags
    
    forM_ allTags $ \tag -> do
        let tagRoute = "tags/" ++ makeTagUrl tag ++ ".html"
        create [fromFilePath tagRoute] $ do
            route idRoute
            compile $ do
                posts <- loadAll "posts/*.typ"
                taggedPosts <- filterM (hasTag tag) posts
                sortedPosts <- recentFirstFromMetadata taggedPosts
                let ctx = constField "title" ("Posts tagged \"" ++ tag ++ "\"")
                          `mappend` listField "posts" postCtx (return sortedPosts)
                          `mappend` defaultContext
                makeItem ""
                    >>= loadAndApplyTemplate "templates/tag.html" ctx
                    >>= loadAndApplyTemplate "templates/default.html" ctx
                    >>= relativizeUrls

    -- Process Typst blog posts  
    match "posts/*.typ" $ do
        route $ gsubRoute "posts/" (const "") `composeRoutes` setExtension "html"
        compile $ do
            let postCtxWithTags = postCtx
            pandocTypstCompilerWithMeta
                >>= loadAndApplyTemplate "templates/post.html"    postCtxWithTags
                >>= loadAndApplyTemplate "templates/default.html" postCtxWithTags
                >>= relativizeUrls

    -- Create post list
    create ["archive.html"] $ do
        route idRoute
        compile $ do
            posts <- recentFirstFromMetadata =<< loadAll "posts/*.typ"
            let archiveCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Archives"            `mappend`
                    defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls

    -- Index page
    match "index.html" $ do
        route idRoute
        compile $ do
            posts <- recentFirstFromMetadata =<< loadAll "posts/*.typ"
            let indexCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    defaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls

    -- Static pages (About, Reading List)
    match (fromList ["about.html", "reading-list.html"]) $ do
        route idRoute
        compile $ getResourceBody
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls

    -- Templates
    match "templates/*" $ compile templateBodyCompiler

--------------------------------------------------------------------------------
-- Contexts
--------------------------------------------------------------------------------

postCtx :: Context String
postCtx =
    dateFieldFromMetadata "date" "%B %e, %Y" `mappend`
    utcDateFieldFromMetadata `mappend`
    tagsFieldFromMetadata `mappend`
    defaultContext

-- Custom field that provides UTC time from metadata
utcDateFieldFromMetadata :: Context String
utcDateFieldFromMetadata = field "published" $ \item -> do
    let identifier = itemIdentifier item
        metaPath = replaceExtension (toFilePath identifier) "meta"
    metaItem <- load (fromFilePath metaPath)
    let metaContent = itemBody metaItem
        metaMap = parseMetadata metaContent
    case M.lookup "date" metaMap of
        Just dateStr -> return $ dateStr ++ "T00:00:00Z"  -- Add time component for UTC
        Nothing -> return "1900-01-01T00:00:00Z"  -- Default date

dateFieldFromMetadata :: String -> String -> Context String
dateFieldFromMetadata key format = field key $ \item -> do
    let identifier = itemIdentifier item
        metaPath = replaceExtension (toFilePath identifier) "meta"
    metaItem <- load (fromFilePath metaPath)
    let metaContent = itemBody metaItem
        metaMap = parseMetadata metaContent
    case M.lookup "date" metaMap of
        Just dateStr -> do
            -- Parse simple YYYY-MM-DD format and format it nicely
            case parseSimpleDate dateStr of
                Just formattedDate -> return formattedDate
                Nothing -> return dateStr
        Nothing -> return ""
  where
    parseSimpleDate dateStr = 
        case words (map (\c -> if c == '-' then ' ' else c) dateStr) of
            [year, month, day] -> Just $ formatDate (read month) (read day) (read year)
            _ -> Nothing
    
    formatDate :: Int -> Int -> Int -> String
    formatDate month day year = 
        monthNames !! (month - 1) ++ " " ++ show day ++ ", " ++ show year
    
    monthNames = ["January", "February", "March", "April", "May", "June",
                  "July", "August", "September", "October", "November", "December"]

-- Sort posts by date from metadata (most recent first)
recentFirstFromMetadata :: [Item String] -> Compiler [Item String]
recentFirstFromMetadata items = do
    itemsWithDates <- mapM getItemDate items
    return $ map snd $ sortBy (comparing $ Down . fst) (itemsWithDates :: [(UTCTime, Item String)])
  where
    defaultUTCTime = read "1900-01-01 00:00:00 UTC" :: UTCTime
    
    getItemDate :: Item String -> Compiler (UTCTime, Item String)
    getItemDate item = do
        let identifier = itemIdentifier item
            metaPath = replaceExtension (toFilePath identifier) "meta"
        metaItem <- load (fromFilePath metaPath)
        let metaContent = itemBody metaItem
            metaMap = parseMetadata metaContent
        case M.lookup "date" metaMap of
            Just dateStr -> 
                case parseTimeM True defaultTimeLocale "%Y-%m-%d" dateStr :: Maybe UTCTime of
                    Just utcTime -> return (utcTime, item)
                    Nothing -> return (defaultUTCTime, item)
            Nothing -> return (defaultUTCTime, item)
    


tagsFieldFromMetadata :: Context String
tagsFieldFromMetadata = field "tags" $ \item -> do
    let identifier = itemIdentifier item
        metaPath = replaceExtension (toFilePath identifier) "meta"
    metaItem <- load (fromFilePath metaPath)
    let metaContent = itemBody metaItem
        metaMap = parseMetadata metaContent
    case M.lookup "tags" metaMap of
        Just tagsStr -> return $ unwords $ map (\tag -> "<a href=\"/tags/" ++ makeUrl tag ++ "\" class=\"tag\">#" ++ tag ++ "</a>") (splitTags tagsStr)
        Nothing -> return ""
  where
    splitTags tagsStr = map trimSpaces' $ splitOn ',' tagsStr
    splitOn delim str = case break (== delim) str of
        (chunk, []) -> [chunk]
        (chunk, _:rest) -> chunk : splitOn delim rest
    trimSpaces' = reverse . dropWhile (== ' ') . reverse . dropWhile (== ' ')
    makeUrl tag = map (\c -> if c == ' ' then '-' else c) tag

tagCtx :: Context String
tagCtx = 
    field "name" (return . itemBody) `mappend`
    field "url" (\item -> return $ map (\c -> if c == ' ' then '-' else c) (itemBody item))

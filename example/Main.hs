{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE QuasiQuotes #-}

module Main where

import Control.Concurrent
import Data.String.Interpolate
import System.FSNotify
import System.FilePath
import System.IO
import qualified System.PosixCompat as System.Directory
import UnliftIO.Temporary


main :: IO ()
main = do
  withSystemTempDirectory "fsnotify-foo" $ \dir -> do
    putStrLn [i|Starting watch on dir: #{dir}|]

    let conf = defaultConfig

    withManagerConf conf $ \mgr -> do
      stop <- watchDir mgr dir (const True) $ \ev -> do
        putStrLn [i|Got event: #{ev}|]
      threadDelay 3_000_000

      putStrLn [i|Writing to #{dir </> "bar"}|]
      writeFile (dir </> "bar") "asdf"
      threadDelay 3_000_000

      putStrLn [i|Direct write|]
      withFile (dir </> "direct-quux") WriteMode $ \hQuux -> do
        hPutStrLn hQuux "aaaaa" >> threadDelay 300_000
        hPutStrLn hQuux "bbbbb" >> threadDelay 300_000
        hPutStrLn hQuux "ccccc" >> threadDelay 300_000
        hClose hQuux

      putStrLn [i|Atomic mv|]
      withSystemTempFile "atomic-quux" $ \quuxFp quuxH -> do
        hClose quuxH
        System.Directory.rename quuxFp (dir </> "quux.moved-in")
      threadDelay 3_000_000

      putStrLn [i|Stopping|]
      stop
      putStrLn [i|Stopped|]
      threadDelay 3_000_000

    putStrLn [i|Exited withManagerConf|]
    threadDelay 3_000_000

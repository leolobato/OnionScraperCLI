# OnionScraper

A macOS command line tool to scrape game art for your [Onion OS](https://github.com/OnionUI/Onion) roms folder.

If uses the [ScreenScraper API](https://screenscraper.fr/webapi2.php) as source.
 
[ScreenScraper.fr](https://screenscraper.fr) is arguably the most popular and comprehensive database of metadata, images and videos for retro games. 

Using it as a source for scraping source means you'll have all the information and cover art for your ROM collection.

## Not supported yet

- Not all platform folders are supported yet.
- ISO-based games: there's support for `.cue`/`.bin` files but it's not tested for systems that use `.iso` or `.chd` files.
- Choose media type to download. Right it defaults to the game box cover (`box-2D`).

## Installation

Download the latest release and run the signed and notarized installer. It will install `onionscraper` to `/usr/local/bin/`.

Register for an account on [ScreenScraper.fr](https://screenscraper.fr) and use your username and password to run,
passing your SD card as an argument (where your /Roms OnionOS folder is located): 

    onionscraper /Volumes/SDCARD/Roms --username YOUR_USERNAME --password YOUR_PASSWORD

## Building

You'll need your own API key to access the ScreenScraper WebAPI. You can apply for an API key on [the WebAPI Forums](https://www.screenscraper.fr/forumsujets.php?frub=12&numpage=0).

When you do have it, you can open this package on Xcode 15 and run it.

## License

This package is available under the MIT license. See the [LICENSE file](LICENSE) for more info.

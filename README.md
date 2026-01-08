# Wallpaper

Create wallpapers with rounded corners.

Are you annoyed by macOS 26 rounded corners?
Or maybe you embrace them but don't enjoy having a colorful wallpaper peek through?
Are you a sketchybar user and would like to create a consistent look?

This CLI will take a wallpaper and re-create it with black (feel free to issue a PR to support other colors)

## Usage

```
# list available screens
wallpaper screens

# set wallpaper for main screen
wallpaper set /path/to/image.jpg

# set wallpaper for specific screen
wallpaper set --screen <id> path/to/image.jpg

# set wallpaper with radius for all corners
wallpaper set --border-radius 20 image.jpg

# set wallpaper with top margin
wallpaper set --top-margin 32 image.jpg

# set wallpaper with 1px black border at bottom
wallpaper set --border-bottom 1 image.jpg

# set wallpaper with 5px black border at bottom
wallpaper set --border-bottom 5 image.jpg

# combine multiple options
wallpaper set --margin-top 100 --border-radius 20 --border-bottom 2 image.jpg
```

## Installation

**Via Homebrew**

```
brew install oschrenk/made/wallpaper
```

## AI

Claude Code was used to create parts of this tool.

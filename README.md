# Wallpaper

Set wallpaper via CLI. Optionally create rounded corners.

## Usage

```
# list available screens
wallpaper screens

# set wallpaper for main screen
wallpaper set /path/to/image.jpg

# set wallpaper for specific screen
wallpaper set --screen <id> path/to/image.jpg

# set wallpaper with default rounded corners
wallpaper set --border-radius default image.jpg

# set wallpaper with radius for all corners
wallpaper set --border-radius 20px image.jpg

# set wallpaper with radius for each corner
# top-left, top-right, bottom-right, bottom-left
wallpaper set --border-radius 20px,20px,10px,10px image.jpg

# set wallpaper with top margin
wallpaper set --top-margin 20px image.jpg
```

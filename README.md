# WuXing IPTV

This repository automatically scrapes and updates IPTV links for 五星体育 (WuXing Sports) channel.

## About

The repository contains a bash script that scrapes IPTV streaming links for 五星体育 from [tonkiang.us](https://tonkiang.us) and saves them to a M3U playlist file. A GitHub Action runs this script daily to keep the links updated.

## Files

- `WuXingTiYu.m3u` - The M3U playlist containing the latest IPTV links
- `run.sh` - The script that extracts the links from the website

## Usage

You can use the M3U playlist with any compatible IPTV player:

1. Copy the raw URL of the `WuXingTiYu.m3u` file from this repository
2. Paste it into your IPTV player as a playlist URL

## Auto-Updates

The playlist is automatically updated daily via GitHub Actions, ensuring you always have access to working links.

## Manual Update

You can manually trigger an update of the IPTV links by going to the Actions tab and running the "Update WuXing IPTV Links" workflow.

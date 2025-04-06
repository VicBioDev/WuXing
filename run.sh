#!/bin/bash

# Output file
OUTPUT_FILE="WuXingTiYu.m3u"

# Create the header for the m3u file
echo "#EXTM3U" > "$OUTPUT_FILE"

# Extract URLs from the input HTML
# This script extracts lines that contain IPTV URLs from the HTML content
# and formats them as m3u entries without unwanted HTML tags

echo "Extracting IPTV links for 五星体育..."

# Read HTML from the provided URL
curl -s "https://tonkiang.us/?iptv=%E4%BA%94%E6%98%9F%E4%BD%93%E8%82%B2&l=fa5a96d92a" | \
grep -o 'http://[^"<]*' | \
grep -E '\.m3u8|/udp/|/TVOD/|livehttpplay' | \
sort -u | \
while read -r url; do
    # Format as m3u entry with proper EXTINF line including tvg-logo and group-title
    echo "#EXTINF:-1 tvg-logo=\"https://epg.iill.top/logo/五星体育.png\" group-title=\"五星体育\",五星体育" >> "$OUTPUT_FILE"
    echo "$url" >> "$OUTPUT_FILE"
    echo "Added: $url"
done

echo "Done! IPTV links saved to $OUTPUT_FILE"
echo "Total links: $(grep -c "http://" "$OUTPUT_FILE")"
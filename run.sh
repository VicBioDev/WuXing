#!/bin/bash

# Output file
OUTPUT_FILE="WuXingTiYu.m3u"

# Create the header for the m3u file
echo "#EXTM3U" > "$OUTPUT_FILE"

# Extract URLs from the input HTML
# This script extracts lines that contain IPTV URLs from the HTML content
# and formats them as m3u entries without unwanted HTML tags

echo "Extracting IPTV links for 五星体育..."

# Read HTML from the provided URL with a user agent and increased timeout
curl -s -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" \
     --connect-timeout 30 \
     --max-time 60 \
     "https://tonkiang.us/?iptv=%E4%BA%94%E6%98%9F%E4%BD%93%E8%82%B2&l=fa5a96d92a" > temp_html.txt

# Check if we got any content
if [ ! -s temp_html.txt ]; then
    echo "Error: Could not retrieve content from the URL."
    exit 1
fi

# Extract URLs with more flexible pattern matching
cat temp_html.txt | grep -o 'https\?://[^"<>[:space:]]*' | 
grep -E '\.m3u8|/udp/|/TVOD/|livehttpplay|\.ts' | 
sort -u > temp_urls.txt

# If no URLs found with the primary method, try a secondary extraction method
if [ ! -s temp_urls.txt ]; then
    echo "Trying alternative extraction method..."
    cat temp_html.txt | grep -o 'src="https\?://[^"]*"' | sed 's/src="//;s/"$//' | 
    grep -E '\.m3u8|/udp/|/TVOD/|livehttpplay|\.ts' | 
    sort -u > temp_urls.txt
fi

# Process the URLs and add them to the m3u file
if [ -s temp_urls.txt ]; then
    # Initialize counter for channel numbering
    COUNTER=1
    
    while read -r url; do
        # Format as m3u entry with proper EXTINF line including tvg-logo, group-title and auto-iterating number
        echo "#EXTINF:-1 tvg-logo=\"https://epg.iill.top/logo/五星体育.png\" group-title=\"五星体育\",#${COUNTER}:五星体育" >> "$OUTPUT_FILE"
        echo "$url" >> "$OUTPUT_FILE"
        echo "Added: #${COUNTER}:五星体育 - $url"
        
        # Increment counter
        ((COUNTER++))
    done < temp_urls.txt
    
    TOTAL_LINKS=$(grep -c "https\?://" "$OUTPUT_FILE")
    echo "Done! IPTV links saved to $OUTPUT_FILE"
    echo "Total links: $TOTAL_LINKS"
    
    # Check if we actually found any links
    if [ "$TOTAL_LINKS" -eq 0 ]; then
        echo "Warning: No links were found in the extracted content."
        echo "HTML content preview:"
        head -20 temp_html.txt
    fi
else
    echo "Error: No IPTV links found."
    echo "HTML content preview:"
    head -20 temp_html.txt
fi

# Clean up temporary files
rm -f temp_html.txt temp_urls.txt
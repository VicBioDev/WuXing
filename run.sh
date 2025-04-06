#!/bin/bash

# Output file
OUTPUT_FILE="WuXingTiYu.m3u"

# Create the header for the m3u file
echo "#EXTM3U" > "$OUTPUT_FILE"

# Extract URLs from the input HTML
# This script extracts lines that contain IPTV URLs from the HTML content
# and formats them as m3u entries without unwanted HTML tags

echo "Extracting IPTV links for 五星体育..."

# Save the current date for debugging
date > debug_info.txt
echo "Starting curl request to tonkiang.us..." >> debug_info.txt

# URL to search for 五星体育
SEARCH_URL="https://tonkiang.us/?iptv=%E4%BA%94%E6%98%9F%E4%BD%93%E8%82%B2&l=fa5a96d92a"
echo "Using URL: $SEARCH_URL" >> debug_info.txt

# Read HTML from the provided URL with a user agent and increased timeout
curl -s -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" \
     --connect-timeout 30 \
     --max-time 60 \
     -v "$SEARCH_URL" > temp_html.txt 2>> debug_info.txt

# Check if we got any content
if [ ! -s temp_html.txt ]; then
    echo "Error: Could not retrieve content from the URL." | tee -a debug_info.txt
    exit 1
fi

# Save HTML size for debugging
echo "HTML size: $(wc -c < temp_html.txt) bytes" >> debug_info.txt
echo "First 100 bytes of HTML:" >> debug_info.txt
head -c 100 temp_html.txt >> debug_info.txt
echo "" >> debug_info.txt

# Extract URLs with more flexible pattern matching
cat temp_html.txt | grep -o 'https\?://[^"<>[:space:]]*' | 
grep -E '\.m3u8|/udp/|/TVOD/|livehttpplay|\.ts' | 
sort -u > temp_urls.txt

# Count found URLs for debugging
URL_COUNT=$(wc -l < temp_urls.txt)
echo "URLs found with primary method: $URL_COUNT" >> debug_info.txt

# If no URLs found with the primary method, try a secondary extraction method
if [ ! -s temp_urls.txt ]; then
    echo "Trying alternative extraction method..." | tee -a debug_info.txt
    cat temp_html.txt | grep -o 'src="https\?://[^"]*"' | sed 's/src="//;s/"$//' | 
    grep -E '\.m3u8|/udp/|/TVOD/|livehttpplay|\.ts' | 
    sort -u > temp_urls.txt
    
    # Count URLs found with second method
    URL_COUNT=$(wc -l < temp_urls.txt)
    echo "URLs found with secondary method: $URL_COUNT" >> debug_info.txt
fi

# Try a third method if still no URLs found
if [ ! -s temp_urls.txt ]; then
    echo "Trying third extraction method..." | tee -a debug_info.txt
    # Look for any URL pattern in the HTML
    cat temp_html.txt | grep -o 'https\?://[^"]*' > temp_all_urls.txt
    echo "All URLs found: $(wc -l < temp_all_urls.txt)" >> debug_info.txt
    echo "Sample URLs:" >> debug_info.txt
    head -5 temp_all_urls.txt >> debug_info.txt
    
    # Check if the page contains a search form
    if grep -q "form.*action" temp_html.txt; then
        echo "Page contains a search form" >> debug_info.txt
    else
        echo "No search form found in the page" >> debug_info.txt
    fi
    
    # Check if the page contains any mention of 五星体育
    if grep -q "五星体育" temp_html.txt; then
        echo "Page contains the text '五星体育'" >> debug_info.txt
    else
        echo "No mention of '五星体育' in the page" >> debug_info.txt
    fi
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
    echo "Done! IPTV links saved to $OUTPUT_FILE" | tee -a debug_info.txt
    echo "Total links: $TOTAL_LINKS" | tee -a debug_info.txt
    
    # Check if we actually found any links
    if [ "$TOTAL_LINKS" -eq 0 ]; then
        echo "Warning: No links were found in the extracted content." | tee -a debug_info.txt
        echo "HTML content preview:" | tee -a debug_info.txt
        head -20 temp_html.txt >> debug_info.txt
    fi
else
    echo "Error: No IPTV links found." | tee -a debug_info.txt
    echo "HTML content preview:" | tee -a debug_info.txt
    head -20 temp_html.txt >> debug_info.txt
    
    # Save full HTML for offline analysis
    cp temp_html.txt full_html_response.txt
    echo "Full HTML saved to full_html_response.txt" | tee -a debug_info.txt
fi

# Clean up temporary files but keep debug info
rm -f temp_html.txt temp_urls.txt
echo "Script completed at $(date)" >> debug_info.txt
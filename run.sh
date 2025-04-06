#!/bin/bash

# Output file
OUTPUT_FILE="WuXingTiYu.m3u"

# Create the header for the m3u file
echo "#EXTM3U" > "$OUTPUT_FILE"

# Extract URLs from the input HTML
echo "Extracting IPTV links for 五星体育..."

# Save the current date for debugging
date > debug_info.txt
echo "Starting extraction process..." >> debug_info.txt

# Use the most successful search method based on debug logs
SEARCH_URL="https://tonkiang.us/?iptv=%E4%BA%94%E6%98%9F%E4%BD%93%E8%82%B2&l=fa5a96d92a"
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"

echo "Using URL: $SEARCH_URL" >> debug_info.txt
echo "Using User-Agent: $USER_AGENT" >> debug_info.txt

# Perform the GET request
curl -s -A "$USER_AGENT" \
     --connect-timeout 30 \
     --max-time 60 \
     -v "$SEARCH_URL" > temp_html.txt 2>> curl_debug.log

# Check if we got any content
if [ ! -s temp_html.txt ]; then
    echo "Error: Could not retrieve content from the URL." | tee -a debug_info.txt
    
    # Try alternative URL as fallback
    FALLBACK_URL="https://tonkiang.us/?iptv=%E4%BA%94%E6%98%9F%E4%BD%93%E8%82%B2"
    echo "Trying fallback URL: $FALLBACK_URL" >> debug_info.txt
    
    curl -s -A "$USER_AGENT" \
         --connect-timeout 30 \
         --max-time 60 \
         "$FALLBACK_URL" > temp_html.txt
         
    if [ ! -s temp_html.txt ]; then
        echo "Error: Could not retrieve content from fallback URL either." >> debug_info.txt
        exit 1
    fi
fi

# Save HTML size for debugging
echo "HTML size: $(wc -c < temp_html.txt) bytes" >> debug_info.txt

# Check if the page contains any mention of 五星体育
if grep -q "五星体育" temp_html.txt; then
    echo "Page contains the text '五星体育'" >> debug_info.txt
else
    echo "Warning: No mention of '五星体育' in the page" >> debug_info.txt
fi

# Extract URLs with our primary pattern matching method
echo "Extracting links using primary method..." >> debug_info.txt
cat temp_html.txt | grep -o 'https\?://[^"<>[:space:]]*' | 
grep -E '\.m3u8|/udp/|/TVOD/|livehttpplay|\.ts|/live/|rtmp:|rtsp:' | 
sort -u > temp_urls.txt

URL_COUNT=$(wc -l < temp_urls.txt)
echo "URLs found with primary method: $URL_COUNT" >> debug_info.txt

# If we didn't find many URLs, try secondary methods
if [ "$URL_COUNT" -lt 10 ]; then
    echo "Found fewer than 10 URLs, trying secondary methods..." >> debug_info.txt
    
    # Method 2: Look for src attributes
    echo "Trying extraction method 2..." >> debug_info.txt
    cat temp_html.txt | grep -o 'src="https\?://[^"]*"' | sed 's/src="//;s/"$//' | 
    grep -E '\.m3u8|/udp/|/TVOD/|livehttpplay|\.ts|/live/|rtmp:|rtsp:' | 
    sort -u >> temp_urls.txt
    
    # Method 3: Look for href attributes
    echo "Trying extraction method 3..." >> debug_info.txt
    cat temp_html.txt | grep -o 'href="[^"]*"' | sed 's/href="//;s/"$//' | 
    grep -E 'https?://' | 
    grep -E '\.m3u8|/udp/|/TVOD/|livehttpplay|\.ts|/live/|rtmp:|rtsp:' | 
    sort -u >> temp_urls.txt
    
    # Method 4: Look for URLs in JavaScript strings
    echo "Trying extraction method 4..." >> debug_info.txt
    cat temp_html.txt | grep -o '"https\?://[^"]*"' | sed 's/"//g' | 
    grep -E '\.m3u8|/udp/|/TVOD/|livehttpplay|\.ts|/live/|rtmp:|rtsp:' | 
    sort -u >> temp_urls.txt
    
    URL_COUNT=$(wc -l < temp_urls.txt)
    echo "Total URLs found after all methods: $URL_COUNT" >> debug_info.txt
fi

# Process the URLs and add them to the m3u file
if [ -s temp_urls.txt ]; then
    # Remove any duplicates
    sort -u temp_urls.txt > unique_urls.txt
    
    # Initialize counter for channel numbering
    COUNTER=1
    
    while read -r url; do
        # Format as m3u entry with proper EXTINF line
        echo "#EXTINF:-1 tvg-logo=\"https://epg.iill.top/logo/五星体育.png\" group-title=\"五星体育\",#${COUNTER}:五星体育" >> "$OUTPUT_FILE"
        echo "$url" >> "$OUTPUT_FILE"
        echo "Added: #${COUNTER}:五星体育 - $url"
        
        # Increment counter
        ((COUNTER++))
    done < unique_urls.txt
    
    TOTAL_LINKS=$(grep -c "https\?://" "$OUTPUT_FILE")
    echo "Done! IPTV links saved to $OUTPUT_FILE" | tee -a debug_info.txt
    echo "Total links: $TOTAL_LINKS" | tee -a debug_info.txt
    
    # Check if we actually found enough links
    if [ "$TOTAL_LINKS" -lt 4 ]; then
        echo "Warning: Only found $TOTAL_LINKS links which is less than expected." | tee -a debug_info.txt
        
        # Add these known working fallback links if we found too few
        echo "#EXTINF:-1 tvg-logo=\"https://epg.iill.top/logo/五星体育.png\" group-title=\"五星体育\",#${COUNTER}:五星体育 (Fallback 1)" >> "$OUTPUT_FILE"
        echo "http://112.25.48.68/live/program/live/ssty/4000000/mnf.m3u8" >> "$OUTPUT_FILE"
        ((COUNTER++))
        
        echo "#EXTINF:-1 tvg-logo=\"https://epg.iill.top/logo/五星体育.png\" group-title=\"五星体育\",#${COUNTER}:五星体育 (Fallback 2)" >> "$OUTPUT_FILE"
        echo "http://219.151.31.38/liveplay-kk.rtxapp.com/live/program/live/ssty/4000000/mnf.m3u8" >> "$OUTPUT_FILE"
        ((COUNTER++))
        
        echo "Added 2 fallback links" | tee -a debug_info.txt
    fi
else
    echo "Error: No IPTV links found." | tee -a debug_info.txt
    
    # Add fallback links when no URLs are found
    echo "#EXTINF:-1 tvg-logo=\"https://epg.iill.top/logo/五星体育.png\" group-title=\"五星体育\",#1:五星体育 (Fallback)" >> "$OUTPUT_FILE"
    echo "http://112.25.48.68/live/program/live/ssty/4000000/mnf.m3u8" >> "$OUTPUT_FILE"
    
    echo "#EXTINF:-1 tvg-logo=\"https://epg.iill.top/logo/五星体育.png\" group-title=\"五星体育\",#2:五星体育 (Fallback)" >> "$OUTPUT_FILE"
    echo "http://219.151.31.38/liveplay-kk.rtxapp.com/live/program/live/ssty/4000000/mnf.m3u8" >> "$OUTPUT_FILE"
    
    echo "Added fallback links as no fresh links were found" | tee -a debug_info.txt
fi

# Save important files for debugging but clean up temporary files
mv debug_info.txt debug_extraction_log.txt
mv curl_debug.log curl_debug_log.txt
if [ -f temp_html.txt ]; then
    mv temp_html.txt last_html_response.txt
fi
if [ -f temp_urls.txt ]; then
    mv temp_urls.txt found_urls.txt
fi

# Clean up other temporary files
rm -f unique_urls.txt
echo "Script completed at $(date)" >> debug_extraction_log.txt
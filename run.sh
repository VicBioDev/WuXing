#!/bin/bash

# Output file
OUTPUT_FILE="WuXingTiYu.m3u"

# Create the header for the m3u file
echo "#EXTM3U" > "$OUTPUT_FILE"

# Save minimal logs for debugging
echo "Starting extraction at $(date)" > debug_info.txt

# Configuration
SEARCH_TERM="%E4%BA%94%E6%98%9F%E4%BD%93%E8%82%B2" # URL-encoded "五星体育"
BASE_URL="https://tonkiang.us"
SEARCH_URL="${BASE_URL}/?iptv=${SEARCH_TERM}"
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"

echo "Extracting IPTV links for 五星体育..."
echo "Using URL: $SEARCH_URL" >> debug_info.txt

# Create a temporary directory for all pages
mkdir -p temp_pages

# Initialize an empty file for collecting all URLs
> all_urls.txt

# Function to extract URLs from a page
extract_urls() {
    local page_file=$1
    local output_file=$2
    
    # Primary extraction method - most reliable for this site
    cat "$page_file" | grep -o 'onclick="bmjx(&quot;\(http[^&]*\)&quot;)' | sed 's/onclick="bmjx(&quot;\(.*\)&quot;)/\1/' > "$output_file"
    
    # Get count of URLs found
    url_count=$(wc -l < "$output_file")
    
    # Try secondary methods if needed
    if [ "$url_count" -lt 5 ]; then
        # Try alternative extraction methods
        cat "$page_file" | grep -o 'http[s]\?://[^"]*\.m3u8[^"]*' >> "$output_file"
        cat "$page_file" | grep -o 'http[s]\?://[^"]*livehttpplay[^"]*' >> "$output_file"
        cat "$page_file" | grep -o 'http[s]\?://[^"]*TVOD[^"]*' >> "$output_file"
    fi
    
    # Clean up URLs and remove duplicates
    cat "$output_file" | sed 's/<\/tba>$//g' | sed 's/<[^>]*>//g' | sort -u > clean_urls.txt
    mv clean_urls.txt "$output_file"
}

# Process page 1
echo "Processing search results..." | tee -a debug_info.txt

# Fetch the first page
curl -s -A "$USER_AGENT" --connect-timeout 30 --max-time 60 "$SEARCH_URL" > temp_pages/page_1.html 2>/dev/null

# If first page fails, try the fallback URL
if [ ! -s temp_pages/page_1.html ]; then
    echo "Trying fallback URL..." >> debug_info.txt
    curl -s -A "$USER_AGENT" --connect-timeout 30 --max-time 60 \
        "https://tonkiang.us/?iptv=%E4%BA%94%E6%98%9F%E4%BD%93%E8%82%B2" > temp_pages/page_1.html
    
    if [ ! -s temp_pages/page_1.html ]; then
        echo "Error: Could not retrieve content from any URL." >> debug_info.txt
        exit 1
    fi
fi

# Save a copy for debugging
cp temp_pages/page_1.html last_html_response.txt

# Extract URLs from the first page
extract_urls "temp_pages/page_1.html" "temp_pages/urls_1.txt"
cat "temp_pages/urls_1.txt" >> all_urls.txt

# Check for pagination links
PAGE_LINKS=$(grep -o '<a [^>]*class="page-link"[^>]*>[0-9]\+</a>' temp_pages/page_1.html || echo "")

if [ -n "$PAGE_LINKS" ]; then
    # Get max page number
    MAX_PAGE=$(echo "$PAGE_LINKS" | grep -o '>[0-9]\+<' | sed 's/[^0-9]//g' | sort -n | tail -1)
    echo "Processing $MAX_PAGE pages of results..." | tee -a debug_info.txt
    
    # Process additional pages (starting from page 2)
    for ((page=2; page<=$MAX_PAGE; page++)); do
        PAGE_URL="${SEARCH_URL}&page=${page}"
        
        # Fetch the page
        curl -s -A "$USER_AGENT" --connect-timeout 30 --max-time 60 \
             "$PAGE_URL" > "temp_pages/page_${page}.html" 2>/dev/null
             
        # Process if page was retrieved successfully
        if [ -s "temp_pages/page_${page}.html" ]; then
            extract_urls "temp_pages/page_${page}.html" "temp_pages/urls_${page}.txt"
            cat "temp_pages/urls_${page}.txt" >> all_urls.txt
        fi
        
        # Small delay to avoid overwhelming the server
        sleep 1
    done
fi

# Deduplicate all URLs
sort -u all_urls.txt > unique_urls.txt
URL_COUNT=$(wc -l < unique_urls.txt)
echo "Total unique URLs found: $URL_COUNT" >> debug_info.txt

# Process the URLs and add them to the m3u file
if [ -s unique_urls.txt ]; then
    # Initialize counter for channel numbering
    COUNTER=1
    
    while read -r url; do
        # Skip malformed URLs
        if [[ ! "$url" =~ ^http[s]?:// ]]; then
            continue
        fi
        
        # Format as m3u entry
        echo "#EXTINF:-1 tvg-logo=\"https://epg.iill.top/logo/五星体育.png\" group-title=\"五星体育\",#${COUNTER}:五星体育" >> "$OUTPUT_FILE"
        echo "$url" >> "$OUTPUT_FILE"
        echo "Added: #${COUNTER}:五星体育"
        
        # Increment counter
        ((COUNTER++))
    done < unique_urls.txt
    
    TOTAL_LINKS=$((COUNTER - 1))
    echo "Found $TOTAL_LINKS links" | tee -a debug_info.txt
    
    # Add fallback links if we found too few
    if [ "$TOTAL_LINKS" -lt 4 ]; then
        echo "Adding fallback links..." >> debug_info.txt
        
        echo "#EXTINF:-1 tvg-logo=\"https://epg.iill.top/logo/五星体育.png\" group-title=\"五星体育\",#${COUNTER}:五星体育 (Fallback 1)" >> "$OUTPUT_FILE"
        echo "http://112.25.48.68/live/program/live/ssty/4000000/mnf.m3u8" >> "$OUTPUT_FILE"
        ((COUNTER++))
        
        echo "#EXTINF:-1 tvg-logo=\"https://epg.iill.top/logo/五星体育.png\" group-title=\"五星体育\",#${COUNTER}:五星体育 (Fallback 2)" >> "$OUTPUT_FILE"
        echo "http://219.151.31.38/liveplay-kk.rtxapp.com/live/program/live/ssty/4000000/mnf.m3u8" >> "$OUTPUT_FILE"
    fi
else
    # Add fallback links when no URLs are found
    echo "No links found. Adding fallback links..." | tee -a debug_info.txt
    
    echo "#EXTINF:-1 tvg-logo=\"https://epg.iill.top/logo/五星体育.png\" group-title=\"五星体育\",#1:五星体育 (Fallback)" >> "$OUTPUT_FILE"
    echo "http://112.25.48.68/live/program/live/ssty/4000000/mnf.m3u8" >> "$OUTPUT_FILE"
    
    echo "#EXTINF:-1 tvg-logo=\"https://epg.iill.top/logo/五星体育.png\" group-title=\"五星体育\",#2:五星体育 (Fallback)" >> "$OUTPUT_FILE"
    echo "http://219.151.31.38/liveplay-kk.rtxapp.com/live/program/live/ssty/4000000/mnf.m3u8" >> "$OUTPUT_FILE"
fi

# Finalize logs and clean up
mv debug_info.txt debug_extraction_log.txt
echo "Script completed at $(date)" >> debug_extraction_log.txt

# Clean up temporary files
rm -rf temp_pages
rm -f all_urls.txt unique_urls.txt curl_debug.log

echo "Done! IPTV links saved to $OUTPUT_FILE"
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

# Create a log file for curl debug
CURL_DEBUG="curl_debug_log.txt"
echo "" > "$CURL_DEBUG"

# Updated HTTP headers and cookies
USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36"
COOKIES="isp=%E4%B8%8A%E6%B5%B7%E7%94%B5%E4%BF%A1; ip=116.232.31.32; cf_clearance=nCpx0pqeR5bcOgEgKBIHghJDSfv.S4Gh8Lv.KZ87mek-1744029305-1.2.1.1-tVb3_TMCuK4sr48LJ8Hw63HL9FaxFdXKHlzxk_dipd1DDa3qi1MSqPVI1QqvD_VTyzv6JXMo4O5bPOOy3RGvsrtUQuhIyrazbif4Abcd2XQGje864LG3nIS53R.P.4u5ERc9LNjyV1s9z1kpxSWXQ0CU2p2PMEFs00K53na7SwWhdfijs1d7hMKQvZpW5J4Jt1QR_h_NRa2TXQix9x2QQFZ.akgJZUeTfBiSOTogNU7HEdizRc.1Sqf9fNruY4nVJTx5iNgK.zjgwba18e7lUYEAmxwgBvCt6tgLIYEsQP0llAmFhCI.rW.OOkETEr.I9Fsn5badjvwHmhsWA7PO7Q4PyWXM2.eAa1.lxyUOGP4; REFERER2=Game; REFERER1=Over; REFERER=Gameover"
FORM_DATA="seerch=${SEARCH_TERM}&Submit=+&name=NjU1Nzkz&city=c8062a06f1.9129311827724"

echo "Extracting IPTV links for 五星体育..."
echo "Using URL: ${BASE_URL}/" >> debug_info.txt

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

# Fetch the first page using the updated curl command
curl -s \
  "${BASE_URL}/?" \
  -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
  -H 'accept-language: en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7' \
  -H 'cache-control: max-age=0' \
  -H 'content-type: application/x-www-form-urlencoded' \
  -b "$COOKIES" \
  -H 'dnt: 1' \
  -H "origin: ${BASE_URL}" \
  -H 'priority: u=0, i' \
  -H "referer: ${BASE_URL}/?" \
  -H 'sec-ch-ua: "Chromium";v="134", "Not:A-Brand";v="24", "Google Chrome";v="134"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "macOS"' \
  -H 'sec-fetch-dest: document' \
  -H 'sec-fetch-mode: navigate' \
  -H 'sec-fetch-site: same-origin' \
  -H 'sec-fetch-user: ?1' \
  -H 'upgrade-insecure-requests: 1' \
  -H "user-agent: ${USER_AGENT}" \
  --data-raw "$FORM_DATA" \
  --connect-timeout 30 \
  --max-time 60 \
  -o temp_pages/page_1.html \
  -v 2>> "$CURL_DEBUG"

# If first page fails, try a fallback approach
if [ ! -s temp_pages/page_1.html ]; then
    echo "Main request failed. Trying fallback request..." >> debug_info.txt
    
    # Fallback to simpler request
    curl -s \
      "${BASE_URL}/?iptv=${SEARCH_TERM}" \
      -H "user-agent: ${USER_AGENT}" \
      --connect-timeout 30 \
      --max-time 60 \
      -o temp_pages/page_1.html
    
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

# Save found URLs for later inspection
cp all_urls.txt found_urls.txt

# Check for pagination links
PAGE_LINKS=$(grep -o '<a [^>]*class="page-link"[^>]*>[0-9]\+</a>' temp_pages/page_1.html || echo "")

if [ -n "$PAGE_LINKS" ]; then
    # Get max page number
    MAX_PAGE=$(echo "$PAGE_LINKS" | grep -o '>[0-9]\+<' | sed 's/[^0-9]//g' | sort -n | tail -1)
    echo "Processing $MAX_PAGE pages of results..." | tee -a debug_info.txt
    
    # Process additional pages (starting from page 2)
    for ((page=2; page<=$MAX_PAGE; page++)); do
        # For pagination, modify the form data to include page number
        PAGE_FORM_DATA="seerch=${SEARCH_TERM}&Submit=+&name=NjU1Nzkz&city=c8062a06f1.9129311827724&page=${page}"
        
        # Fetch the page with pagination
        curl -s \
          "${BASE_URL}/?" \
          -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
          -H 'accept-language: en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7' \
          -H 'cache-control: max-age=0' \
          -H 'content-type: application/x-www-form-urlencoded' \
          -b "$COOKIES" \
          -H 'dnt: 1' \
          -H "origin: ${BASE_URL}" \
          -H 'priority: u=0, i' \
          -H "referer: ${BASE_URL}/?" \
          -H 'sec-ch-ua: "Chromium";v="134", "Not:A-Brand";v="24", "Google Chrome";v="134"' \
          -H 'sec-ch-ua-mobile: ?0' \
          -H 'sec-ch-ua-platform: "macOS"' \
          -H 'sec-fetch-dest: document' \
          -H 'sec-fetch-mode: navigate' \
          -H 'sec-fetch-site: same-origin' \
          -H 'sec-fetch-user: ?1' \
          -H 'upgrade-insecure-requests: 1' \
          -H "user-agent: ${USER_AGENT}" \
          --data-raw "$PAGE_FORM_DATA" \
          --connect-timeout 30 \
          --max-time 60 \
          -o "temp_pages/page_${page}.html"
             
        # Process if page was retrieved successfully
        if [ -s "temp_pages/page_${page}.html" ]; then
            extract_urls "temp_pages/page_${page}.html" "temp_pages/urls_${page}.txt"
            cat "temp_pages/urls_${page}.txt" >> all_urls.txt
        fi
        
        # Small delay to avoid overwhelming the server
        sleep 1
    done
fi

# Save all extracted URLs for debugging
cp all_urls.txt all_extracted_urls.txt

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
rm -f all_urls.txt unique_urls.txt

echo "Done! IPTV links saved to $OUTPUT_FILE"
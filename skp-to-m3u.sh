#!/bin/bash

parse_input() {
    if [ -z "$1" ]; then
        read -p "Enter the video file: " video_file
    else
        video_file="$1"
    fi

    if [ -z "$2" ]; then
        read -p "Enter the SKP file: " skp_file
    else
        skp_file="$2"
    fi

    echo "Video file: $video_file"
    echo "SKP file: $skp_file"

    return 0
}

check_input() {
    video_input="$1"
    skp_input="$2"
    current_directory=$(pwd)

    # Check if the video file exists
    if [ ! -f "$video_input" ]; then
        video_input="$current_directory/$video_input"
        if [ ! -f "$video_input" ]; then
            echo "$video_input cannot be found."
            exit 1
        fi
    fi

    # Check if the SKP file exists
    if [ ! -f "$skp_input" ]; then
        skp_input="$current_directory/$skp_input"
        if [ ! -f "$skp_input" ]; then
            echo "$skp_input cannot be found."
            exit 1
        fi
    fi

    return 0
}

parse_skp_file() {
    skp_file="$1"
    pattern="^[0-9]{1,2}:[0-9]{2}:[0-9]{2}\.[0-9]{2} --> [0-9]{1,2}:[0-9]{2}:[0-9]{2}\.[0-9]{2}"

    # Read the SKP file line by line
    while IFS= read -r line; do
        if [[ $line =~ $pattern ]]; then
            times=($line)
            for time in "${times[@]}"; do
                IFS=':' read -r -a time_parts <<< "$time"
                if [ $time = "-->" ]; then
                    continue
                fi
                hours=${time_parts[0]}
                minutes=${time_parts[1]}
                seconds=${time_parts[2]%.*}  # Remove the milliseconds

                total_seconds=$((hours * 3600 + minutes * 60 + seconds))
                scenes+=($total_seconds)
            done
        fi
    done < "$skp_file"

    echo "Number of scenes: $(( ${#scenes[@]} / 2 ))"

    return 0
}

create_m3u() {
    video_file="$1"
    skp_file="$2"

    parse_skp_file "$skp_file"

    base_name=$(basename "$video_file")
    filename_without_extension="${base_name%.*}"
    output_path=$(dirname "$video_file")

    m3u_file="$output_path/$filename_without_extension.m3u"

    # Create an M3U playlist file
    m3u_content="#EXTM3U\n"
    m3u_content+="#EXTINF:-1,$base_name\n"
    m3u_content+="#EXTVLCOPT:start-time=1\n"
    for ((i = 0; i < ${#scenes[@]}; i += 2)); do
        stop_second=${scenes[i]}
        start_second=${scenes[i + 1]}

        m3u_content+="#EXTVLCOPT:stop-time=$stop_second\n"
        m3u_content+="$video_file\n"
        m3u_content+="#EXTVLCOPT:start-time=$start_second\n"
    done
    m3u_content+="$video_file"

    echo -e "$m3u_content" > "$m3u_file"

    echo "$base_name M3U file created successfully."
}

parse_input "$1" "$2"
check_input "$video_file" "$skp_file"
create_m3u "$video_file" "$skp_file"

import logging
import os
import re
import sys
from pathlib import Path


def parse_input():
    """
    Parses the command line arguments or prompts the user for input.

    If the command line arguments are provided, the function assigns the first argument to `video_file`
    and the second argument to `skp_file`. If the arguments are not provided, the function prompts the
    user to enter the video file and SKP file.

    Returns:
      video_file: The video file path.
      skp_file: The SKP file path.
    """
    # Get the command line arguments
    if len(sys.argv) < 3:
        # Prompt the user for video_file and skp_file if not provided as arguments
        video_file = input("Enter the video file: ")
        skp_file = input("Enter the SKP file: ")
    else:
        video_file = sys.argv[1]
        skp_file = sys.argv[2]

    logging.info(f"Video file: {video_file}")
    logging.info(f"SKP file: {skp_file}")

    return video_file, skp_file


def check_input(video_input: str, skp_input: str):
    """
    Checks if the input files exist. The input could be just the file name or the full path.

    Returns:
      video_file: The video file path.
      skp_file: The SKP file path.
    """

    current_directory = os.getcwd()
    # Check if the video file exists
    if not os.path.exists(video_input):
        video_input = os.path.join(current_directory, video_input)
        if not os.path.exists(video_input):
            logging.error(f"{video_input} cannot be found.")
            sys.exit(1)

    # Check if the SKP file exists
    if not os.path.exists(skp_input):
        skp_input = os.path.join(current_directory, skp_input)
        if not os.path.exists(skp_input):
            logging.error(f"{skp_input} cannot be found.")
            sys.exit(1)

    return video_input, skp_input


def parse_skp_file(skp_file: str) -> list[int]:
    """
    Parses the SKP file and logs the number of scenes and the scene names.

    Returns:
      scenes: The list of integer times that represent the skipped scenes.
    """

    with open(skp_file, "r") as f:
        lines = f.readlines()

    pattern = r"\d{1,2}:\d{2}:\d{2}\.\d{2} --> \d{1,2}:\d{2}:\d{2}\.\d{2}"
    # the above pattern is used to match the time format in the SKP file
    # H:MM:SS.ss --> H:MM:SS.ss, where H can be one or two digits, MM and SS are always two digits, and ss are two digits.

    scenes = []
    for line in lines:
        match = re.match(pattern, line)
        if match:  # If the line matches the pattern
            times = line.split(" --> ")
            for time in times:
                hours, minutes, seconds = time.split(":")
                seconds = seconds.split(".")[0]  # Remove the milliseconds

                total_seconds = int(hours) * 3600 + int(minutes) * 60 + int(seconds)
                scenes.append(total_seconds)

    logging.info(f"Number of scenes: {len(scenes) / 2}")

    return scenes


def create_m3u(video_file: str, skp_file: str):
    """
    Creates an M3U playlist file with the video file and the SKP file.

    Args:
      video_file: The video file path.
      skp_file: The SKP file path.
    """

    skipped_scenes = parse_skp_file(skp_file)

    base_name = os.path.basename(video_file)
    filename_without_extension = Path(base_name).stem
    output_path = os.path.dirname(video_file)

    m3u_file = os.path.join(output_path, f"{filename_without_extension}.m3u")
    # Create an M3U playlist file
    with open(m3u_file, "w") as f:
        f.write("#EXTM3U\n")
        f.write(f"#EXTINF:-1,{base_name}\n")
        f.write("#EXTVLCOPT:start-time=1")
        # List slicing -> Start_Index:End_Index:Step
        # The first slice [::2] gets every other element starting from the first element
        # The second slice [1::2] gets every other element starting from the second element
        for stop_second, start_second in zip(skipped_scenes[::2], skipped_scenes[1::2]):
            f.write(f"\n#EXTVLCOPT:stop-time={stop_second}\n")
            f.write(f"{video_file}\n")
            f.write(f"#EXTVLCOPT:start-time={start_second}\n")
        f.write(f"{video_file}\n")

    logging.info(f"{base_name} M3U file created successfully.")


def main():
    video_input, skp_input = parse_input()
    video_file, skp_file = check_input(video_input, skp_input)

    create_m3u(video_file, skp_file)


if __name__ == "__main__":
    # Configure logging to log to console and file
    logging.basicConfig(
        filename="skp-to-m3u.log",
        level=logging.INFO,
        format="%(asctime)s - %(levelname)s - %(message)s",
    )
    console = logging.StreamHandler()
    console.setLevel(logging.INFO)
    formatter = logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")
    console.setFormatter(formatter)
    logging.getLogger("").addHandler(console)

    main()

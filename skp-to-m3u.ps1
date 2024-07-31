param(
    [string]$VideoFile,
    [string]$SKPFile
)

function Parse-Input {
    param(
        [string]$video_file,
        [string]$skp_file
    )

    if ($video_file.Length -eq 0) {
      $video_file = Read-Host "Enter the video file"
    }
    if ($skp_file.Length -eq 0) {
      $skp_file = Read-Host "Enter the SKP file"
    }

    Write-Host "Video file: $video_file"
    Write-Host "SKP file: $skp_file"

    return ,$video_file, $skp_file
}

function Check-Input {
    param(
        [string]$video_input,
        [string]$skp_input
    )

    $current_directory = Get-Location

    # Check if the video file exists
    if (-not (Test-Path -LiteralPath $video_input)) {
        $video_input = Join-Path $current_directory $video_input
        if (-not (Test-Path $video_input)) {
            Write-Error "$video_input cannot be found."
            exit 1
        }
    }

    # Check if the SKP file exists
    if (-not (Test-Path -LiteralPath $skp_input)) {
        $skp_input = Join-Path $current_directory $skp_input
        if (-not (Test-Path $skp_input)) {
            Write-Error "$skp_input cannot be found."
            exit 1
        }
    }

    return ,$video_input, $skp_input
}

function Parse-SKP-File {
    param(
        [string]$skp_file
    )

    $lines = Get-Content $skp_file

    $pattern = "\d{1,2}:\d{2}:\d{2}\.\d{2} --> \d{1,2}:\d{2}:\d{2}\.\d{2}"
    # the above pattern is used to match the time format in the SKP file
    # H:MM:SS.ss --> H:MM:SS.ss, where H can be one or two digits, MM and SS are always two digits, and ss are two digits.

    $scenes = @()
    foreach ($line in $lines) {
        if ($line -match $pattern) {
            $times = $line -split " --> "
            foreach ($time in $times) {
                $hours, $minutes, $seconds = $time -split ":"
                $seconds = ($seconds -split "\.")[0]  # Remove the milliseconds

                $total_seconds = [int]$hours * 3600 + [int]$minutes * 60 + [int]$seconds
                $scenes += $total_seconds
            }
        }
    }

    Write-Host "Number of scenes: $($scenes.Count / 2)"

    return ,$scenes
}

function Create-M3U {
    param(
        [string]$video_file,
        [string]$skp_file
    )

    $skipped_scenes = Parse-SKP-File $skp_file

    $base_name = Split-Path -Leaf $video_file
    $filename_without_extension = [System.IO.Path]::GetFileNameWithoutExtension($base_name)
    $output_path = Split-Path $video_file

    $m3u_file = Join-Path $output_path "$filename_without_extension.m3u"
    # Create an M3U playlist file
    $m3u_content = "#EXTM3U`n"
    $m3u_content += "#EXTINF:-1,$base_name`n"
    $m3u_content += "#EXTVLCOPT:start-time=1"
    for ($i = 0; $i -lt $skipped_scenes.Count; $i += 2) {
        $stop_second = $skipped_scenes[$i]
        $start_second = $skipped_scenes[$i + 1]

        $m3u_content += "`n#EXTVLCOPT:stop-time=$stop_second`n"
        $m3u_content += "$video_file`n"
        $m3u_content += "#EXTVLCOPT:start-time=$start_second`n"
    }
    $m3u_content += "$video_file"

    $m3u_content | Out-File -LiteralPath $m3u_file

    Write-Host "$base_name M3U file created successfully."
}


$video_input, $skp_input = Parse-Input -video_file $VideoFile -skp_file $SKPFile
$video_file, $skp_file = Check-Input -video_input $video_input -skp_input $skp_input

Create-M3U -video_file $video_file -skp_file $skp_file


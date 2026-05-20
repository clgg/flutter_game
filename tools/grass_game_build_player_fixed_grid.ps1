Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'

$root = Resolve-Path '.'
$playerDir = Join-Path $root 'assets/game/grass_game/images/player'
$sourceColumns = 6
$targetColumns = 2
$targetRows = 8
$targetCell = 128

function New-TransparentBitmap {
  param(
    [int]$Width,
    [int]$Height
  )
  $bitmap = New-Object System.Drawing.Bitmap $Width, $Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  try {
    $graphics.Clear([System.Drawing.Color]::Transparent)
  } finally {
    $graphics.Dispose()
  }
  return $bitmap
}

function Set-Quality {
  param([System.Drawing.Graphics]$Graphics)
  $Graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
  $Graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
  $Graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $Graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
}

function Save-Png {
  param(
    [System.Drawing.Bitmap]$Bitmap,
    [string]$Path
  )
  $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function Convert-PlayerSheet {
  param(
    [string]$SourcePath,
    [string]$OutputPath
  )
  $image = [System.Drawing.Image]::FromFile($SourcePath)
  try {
    $sourceCell = [int]($image.Width / $sourceColumns)
    $sourceRows = [int][Math]::Round($image.Height / $sourceCell)
    if ($image.Width -ne 1536 -or $image.Height -ne 1024 -or $sourceRows -ne 4) {
      throw "Unexpected player source size: $SourcePath is $($image.Width)x$($image.Height), expected 1536x1024."
    }

    $rowMap = @(0, 3, 3, 3, 1, 2, 2, 2)
    $frameMap = @(0, 3)
    $bitmap = New-TransparentBitmap -Width ($targetColumns * $targetCell) -Height ($targetRows * $targetCell)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
      Set-Quality -Graphics $graphics
      for ($row = 0; $row -lt $targetRows; $row++) {
        $sourceRow = $rowMap[$row]
        for ($column = 0; $column -lt $targetColumns; $column++) {
          $sourceColumn = $frameMap[$column]
          $src = New-Object System.Drawing.Rectangle (
            $sourceColumn * $sourceCell
          ), (
            $sourceRow * $sourceCell
          ), $sourceCell, $sourceCell
          $dst = New-Object System.Drawing.Rectangle (
            $column * $targetCell
          ), (
            $row * $targetCell
          ), $targetCell, $targetCell
          $graphics.DrawImage($image, $dst, $src, [System.Drawing.GraphicsUnit]::Pixel)
        }
      }
      Save-Png -Bitmap $bitmap -Path $OutputPath
    } finally {
      $graphics.Dispose()
      $bitmap.Dispose()
    }
  } finally {
    $image.Dispose()
  }
}

$converted = 0
Get-ChildItem $playerDir -Filter 'player_*_walk_sheet.png' | ForEach-Object {
  $base = $_.Name -replace '_walk_sheet\.png$', ''
  $output = Join-Path $playerDir "$base`_walk_8dir_sheet.png"
  Convert-PlayerSheet -SourcePath $_.FullName -OutputPath $output
  $converted++
}

Write-Host "Converted $converted player walk sheets to 8x2 fixed grid sampling."

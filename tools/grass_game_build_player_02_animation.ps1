Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'

$root = Resolve-Path '.'
$playerDir = Join-Path $root 'assets/game/grass_game/images/player'
$sourcePath = Join-Path $playerDir 'player_02.png'
$sheetPath = Join-Path $playerDir 'player_02_walk_8dir_sheet.png'
$avatarPath = Join-Path $playerDir 'avatar_player_02.png'
$previewPath = Join-Path $playerDir 'preview_player_02_walk.gif'
$previewDir = Join-Path $root 'build/codex_previews/player_02_frames'

$columns = 6
$rows = 8
$targetCell = 128
$cropInset = 3
$targetDrawInset = 5
$targetDrawSize = 118
# Build exact runtime rows: down, down-right, right, up-right, up, up-left,
# left, down-left. The right-facing rows are mirrored from the left-facing
# source rows so each horizontal pair is visually opposite.
$sourceRowByTargetRow = @(0, 1, 2, 3, 4, 3, 2, 1)
$flipTargetRow = @($false, $true, $true, $true, $false, $false, $false, $false)

function New-TransparentBitmap {
  param([int]$Width, [int]$Height)
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

function Remove-GreenBackground {
  param([System.Drawing.Bitmap]$Bitmap)

  for ($y = 0; $y -lt $Bitmap.Height; $y++) {
    for ($x = 0; $x -lt $Bitmap.Width; $x++) {
      $color = $Bitmap.GetPixel($x, $y)
      $r = [int]$color.R
      $g = [int]$color.G
      $b = [int]$color.B
      $greenScore = $g - [Math]::Max($r, $b)
      $isGreenBackground = $g -gt 120 -and $greenScore -gt 42
      $channelSpread = [Math]::Max($r, [Math]::Max($g, $b)) - [Math]::Min($r, [Math]::Min($g, $b))
      $isGridLine = $r -gt 180 -and $g -gt 180 -and $b -gt 180 -and $channelSpread -lt 75
      if ($isGreenBackground -or $isGridLine) {
        $Bitmap.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
        continue
      }

      if ($greenScore -gt 18 -and $g -gt 90) {
        $g = [Math]::Max([Math]::Max($r, $b), $g - [Math]::Min(38, $greenScore))
      }
      $Bitmap.SetPixel(
        $x,
        $y,
        [System.Drawing.Color]::FromArgb($color.A, $r, [Math]::Min(255, $g), $b)
      )
    }
  }

  for ($i = 0; $i -lt $Bitmap.Width; $i++) {
    $Bitmap.SetPixel($i, 0, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
    $Bitmap.SetPixel($i, $Bitmap.Height - 1, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
  }
  for ($i = 0; $i -lt $Bitmap.Height; $i++) {
    $Bitmap.SetPixel(0, $i, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
    $Bitmap.SetPixel($Bitmap.Width - 1, $i, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
  }
}

function Get-VisibleBounds {
  param([System.Drawing.Bitmap]$Bitmap)

  $minX = $Bitmap.Width
  $minY = $Bitmap.Height
  $maxX = -1
  $maxY = -1

  for ($y = 0; $y -lt $Bitmap.Height; $y++) {
    for ($x = 0; $x -lt $Bitmap.Width; $x++) {
      if ($Bitmap.GetPixel($x, $y).A -le 12) {
        continue
      }
      if ($x -lt $minX) { $minX = $x }
      if ($x -gt $maxX) { $maxX = $x }
      if ($y -lt $minY) { $minY = $y }
      if ($y -gt $maxY) { $maxY = $y }
    }
  }

  if ($maxX -lt 0) {
    return $null
  }
  return [PSCustomObject]@{
    MinX = $minX
    MinY = $minY
    MaxX = $maxX
    MaxY = $maxY
    Width = $maxX - $minX + 1
    Height = $maxY - $minY + 1
    CenterX = ($minX + $maxX) / 2.0
    BottomY = $maxY
  }
}

function Convert-Frame {
  param(
    [System.Drawing.Image]$Source,
    [int]$SourceCell,
    [int]$Column,
    [int]$Row,
    [bool]$FlipHorizontal = $false
  )

  $frame = New-TransparentBitmap -Width $targetCell -Height $targetCell
  $graphics = [System.Drawing.Graphics]::FromImage($frame)
  try {
    Set-Quality -Graphics $graphics
    $sourceRect = New-Object System.Drawing.Rectangle (
      $Column * $SourceCell + $cropInset
    ), (
      $Row * $SourceCell + $cropInset
    ), (
      $SourceCell - $cropInset * 2
    ), (
      $SourceCell - $cropInset * 2
    )
    $targetRect = New-Object System.Drawing.Rectangle $targetDrawInset, $targetDrawInset, $targetDrawSize, $targetDrawSize
    $graphics.DrawImage($Source, $targetRect, $sourceRect, [System.Drawing.GraphicsUnit]::Pixel)
  } finally {
    $graphics.Dispose()
  }

  if ($FlipHorizontal) {
    $frame.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX)
  }

  Remove-GreenBackground -Bitmap $frame

  $bounds = Get-VisibleBounds -Bitmap $frame
  if ($null -eq $bounds) {
    return $frame
  }

  $dx = [int][Math]::Round(64 - $bounds.CenterX)
  $dy = [int][Math]::Round(122 - $bounds.BottomY)
  if ($bounds.MinX + $dx -lt 2) {
    $dx = 2 - $bounds.MinX
  }
  if ($bounds.MaxX + $dx -gt 125) {
    $dx = 125 - $bounds.MaxX
  }
  if ($bounds.MinY + $dy -lt 2) {
    $dy = 2 - $bounds.MinY
  }
  if ($bounds.MaxY + $dy -gt 125) {
    $dy = 125 - $bounds.MaxY
  }

  if ($dx -eq 0 -and $dy -eq 0) {
    return $frame
  }

  $aligned = New-TransparentBitmap -Width $targetCell -Height $targetCell
  $alignGraphics = [System.Drawing.Graphics]::FromImage($aligned)
  try {
    Set-Quality -Graphics $alignGraphics
    $alignGraphics.DrawImageUnscaled($frame, $dx, $dy)
  } finally {
    $alignGraphics.Dispose()
    $frame.Dispose()
  }
  return $aligned
}

function Save-GifPreview {
  param(
    [string]$FrameDir,
    [string]$OutputPath
  )

  Add-Type -AssemblyName PresentationCore
  Add-Type -AssemblyName WindowsBase
  $encoder = New-Object System.Windows.Media.Imaging.GifBitmapEncoder
  Get-ChildItem -Path $FrameDir -Filter '*.png' | Sort-Object Name | ForEach-Object {
    $stream = [System.IO.File]::OpenRead($_.FullName)
    try {
      $decoder = [System.Windows.Media.Imaging.BitmapDecoder]::Create(
        $stream,
        [System.Windows.Media.Imaging.BitmapCreateOptions]::PreservePixelFormat,
        [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
      )
      $encoder.Frames.Add($decoder.Frames[0])
    } finally {
      $stream.Dispose()
    }
  }

  $outStream = [System.IO.File]::Create($OutputPath)
  try {
    $encoder.Save($outStream)
  } finally {
    $outStream.Dispose()
  }
}

if (-not (Test-Path $sourcePath)) {
  throw "Missing source image: $sourcePath"
}

$source = [System.Drawing.Image]::FromFile($sourcePath)
try {
  if ($source.Width % $columns -ne 0 -or $source.Height % $rows -ne 0) {
    throw "player_02.png must be an even 6x8 grid, got $($source.Width)x$($source.Height)"
  }
  $sourceCell = [int]($source.Width / $columns)
  if ($sourceCell -ne [int]($source.Height / $rows)) {
    throw "player_02.png cells must be square, got $($source.Width / $columns)x$($source.Height / $rows)"
  }

  $sheet = New-TransparentBitmap -Width ($columns * $targetCell) -Height ($rows * $targetCell)
  $sheetGraphics = [System.Drawing.Graphics]::FromImage($sheet)
  try {
    Set-Quality -Graphics $sheetGraphics
    New-Item -ItemType Directory -Force -Path $previewDir | Out-Null
    Get-ChildItem -Path $previewDir -Filter '*.png' | Remove-Item -Force

    for ($row = 0; $row -lt $rows; $row++) {
      $sourceRow = $sourceRowByTargetRow[$row]
      $flipHorizontal = $flipTargetRow[$row]
      for ($column = 0; $column -lt $columns; $column++) {
        $frame = Convert-Frame -Source $source -SourceCell $sourceCell -Column $column -Row $sourceRow -FlipHorizontal $flipHorizontal
        try {
          $sheetGraphics.DrawImageUnscaled($frame, $column * $targetCell, $row * $targetCell)
          if ($row -eq 0) {
            $frame.Save((Join-Path $previewDir ("frame_{0:D2}.png" -f $column)), [System.Drawing.Imaging.ImageFormat]::Png)
          }
          if ($row -eq 0 -and $column -eq 0) {
            $frame.Save($avatarPath, [System.Drawing.Imaging.ImageFormat]::Png)
          }
        } finally {
          $frame.Dispose()
        }
      }
    }

    $sheet.Save($sheetPath, [System.Drawing.Imaging.ImageFormat]::Png)
  } finally {
    $sheetGraphics.Dispose()
    $sheet.Dispose()
  }
} finally {
  $source.Dispose()
}

Save-GifPreview -FrameDir $previewDir -OutputPath $previewPath

Write-Host "Generated $sheetPath"
Write-Host "Generated $avatarPath"
Write-Host "Generated $previewPath"

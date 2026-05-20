Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'

$root = Resolve-Path '.'
$imageRoot = Join-Path $root 'assets/game/grass_game/images'
$targetCell = 128
$columns = 6
$directions = 8
$alphaThreshold = 8

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
  $directory = Split-Path -Parent $Path
  if (-not (Test-Path $directory)) {
    New-Item -ItemType Directory -Path $directory | Out-Null
  }
  $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function Get-SourceLayout {
  param([System.Drawing.Image]$Image)
  $cellWidth = [int]($Image.Width / $columns)
  $rowCount = [int][Math]::Round($Image.Height / $cellWidth)
  if ($rowCount -lt 1) { $rowCount = 1 }
  $cellHeight = [int]($Image.Height / $rowCount)
  return @{
    CellWidth = $cellWidth
    CellHeight = $cellHeight
    RowCount = $rowCount
  }
}

function Get-AlphaBounds {
  param(
    [System.Drawing.Bitmap]$Bitmap,
    [System.Drawing.Rectangle]$Rect
  )
  $minX = $Rect.Right
  $minY = $Rect.Bottom
  $maxX = $Rect.Left - 1
  $maxY = $Rect.Top - 1
  for ($y = $Rect.Top; $y -lt $Rect.Bottom; $y++) {
    for ($x = $Rect.Left; $x -lt $Rect.Right; $x++) {
      if ($Bitmap.GetPixel($x, $y).A -gt $alphaThreshold) {
        if ($x -lt $minX) { $minX = $x }
        if ($y -lt $minY) { $minY = $y }
        if ($x -gt $maxX) { $maxX = $x }
        if ($y -gt $maxY) { $maxY = $y }
      }
    }
  }
  if ($maxX -lt $minX -or $maxY -lt $minY) {
    return $Rect
  }
  $pad = 3
  $left = [Math]::Max($Rect.Left, $minX - $pad)
  $top = [Math]::Max($Rect.Top, $minY - $pad)
  $right = [Math]::Min($Rect.Right, $maxX + $pad + 1)
  $bottom = [Math]::Min($Rect.Bottom, $maxY + $pad + 1)
  return New-Object System.Drawing.Rectangle $left, $top, ($right - $left), ($bottom - $top)
}

function New-OpacityAttributes {
  param([double]$Opacity)
  $matrix = New-Object System.Drawing.Imaging.ColorMatrix
  $matrix.Matrix00 = 1
  $matrix.Matrix11 = 1
  $matrix.Matrix22 = 1
  $matrix.Matrix33 = [single]$Opacity
  $matrix.Matrix44 = 1
  $attributes = New-Object System.Drawing.Imaging.ImageAttributes
  $attributes.SetColorMatrix($matrix, [System.Drawing.Imaging.ColorMatrixFlag]::Default, [System.Drawing.Imaging.ColorAdjustType]::Bitmap)
  return $attributes
}

function Draw-ImageOpacity {
  param(
    [System.Drawing.Graphics]$Graphics,
    [System.Drawing.Image]$Image,
    [System.Drawing.Rectangle]$Destination,
    [double]$Opacity
  )
  if ($Opacity -ge 0.999) {
    $Graphics.DrawImage($Image, $Destination)
    return
  }
  $attributes = New-OpacityAttributes -Opacity $Opacity
  try {
    $Graphics.DrawImage(
      $Image,
      $Destination,
      0,
      0,
      $Image.Width,
      $Image.Height,
      [System.Drawing.GraphicsUnit]::Pixel,
      $attributes
    )
  } finally {
    $attributes.Dispose()
  }
}

function New-CellFromSource {
  param(
    [System.Drawing.Bitmap]$Source,
    [int]$Column,
    [int]$Row,
    [double]$ScaleMultiplier = 1.0,
    [int]$OffsetX = 0,
    [int]$OffsetY = 0
  )
  $layout = Get-SourceLayout -Image $Source
  $sourceRow = [Math]::Max(0, [Math]::Min($layout.RowCount - 1, $Row))
  $srcCell = New-Object System.Drawing.Rectangle ($Column * $layout.CellWidth), ($sourceRow * $layout.CellHeight), $layout.CellWidth, $layout.CellHeight
  $bounds = Get-AlphaBounds -Bitmap $Source -Rect $srcCell
  $bitmap = New-TransparentBitmap -Width $targetCell -Height $targetCell
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  try {
    Set-Quality -Graphics $graphics
    $maxWidth = 104
    $maxHeight = 108
    $scale = [Math]::Min($maxWidth / $bounds.Width, $maxHeight / $bounds.Height) * $ScaleMultiplier
    if ($scale -gt 1.0) { $scale = 1.0 }
    $drawWidth = [int][Math]::Round($bounds.Width * $scale)
    $drawHeight = [int][Math]::Round($bounds.Height * $scale)
    $left = [int][Math]::Round(($targetCell - $drawWidth) / 2 + $OffsetX)
    $top = [int][Math]::Round(116 - $drawHeight + $OffsetY)
    if ($top -lt 7) { $top = 7 }
    if ($left -lt 4) { $left = 4 }
    if ($left + $drawWidth -gt 124) { $left = 124 - $drawWidth }
    if ($top + $drawHeight -gt 123) { $top = 123 - $drawHeight }
    $dst = New-Object System.Drawing.Rectangle $left, $top, $drawWidth, $drawHeight
    $graphics.DrawImage($Source, $dst, $bounds, [System.Drawing.GraphicsUnit]::Pixel)
  } finally {
    $graphics.Dispose()
  }
  return $bitmap
}

function Draw-Cell {
  param(
    [System.Drawing.Graphics]$Graphics,
    [System.Drawing.Bitmap]$Cell,
    [int]$Column,
    [int]$Row,
    [double]$Opacity = 1.0,
    [int]$OffsetX = 0,
    [int]$OffsetY = 0
  )
  $dst = New-Object System.Drawing.Rectangle ($Column * $targetCell + $OffsetX), ($Row * $targetCell + $OffsetY), $targetCell, $targetCell
  Draw-ImageOpacity -Graphics $Graphics -Image $Cell -Destination $dst -Opacity $Opacity
}

function Get-VectorForRow {
  param([int]$Row)
  $vectors = @(
    @(0, 1),
    @(0.707, 0.707),
    @(1, 0),
    @(0.707, -0.707),
    @(0, -1),
    @(-0.707, -0.707),
    @(-1, 0),
    @(-0.707, 0.707)
  )
  return $vectors[$Row]
}

function Draw-AttackArc {
  param(
    [System.Drawing.Graphics]$Graphics,
    [int]$Column,
    [int]$Row,
    [System.Drawing.Color]$Color
  )
  $vector = Get-VectorForRow -Row $Row
  $dx = [double]$vector[0]
  $dy = [double]$vector[1]
  $progress = ($Column + 1) / $columns
  $alpha = [int](45 + 155 * [Math]::Sin($progress * [Math]::PI))
  if ($alpha -lt 0) { $alpha = 0 }
  $cx = $Column * $targetCell + 64 + [int]($dx * (8 + 13 * $progress))
  $cy = $Row * $targetCell + 68 + [int]($dy * (8 + 13 * $progress))
  $length = 24 + 18 * $progress
  $width = 9 + 8 * $progress
  $angle = [Math]::Atan2($dy, $dx)
  $px = -[Math]::Sin($angle)
  $py = [Math]::Cos($angle)
  $frontX = $cx + $dx * $length
  $frontY = $cy + $dy * $length
  $backX = $cx - $dx * ($length * 0.45)
  $backY = $cy - $dy * ($length * 0.45)
  $points = @(
    (New-Object System.Drawing.PointF ([float]$frontX), ([float]$frontY)),
    (New-Object System.Drawing.PointF ([float]($backX + $px * $width)), ([float]($backY + $py * $width))),
    (New-Object System.Drawing.PointF ([float]($backX - $px * $width)), ([float]($backY - $py * $width)))
  )
  $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb($alpha, $Color.R, $Color.G, $Color.B))
  $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb([Math]::Min(255, $alpha + 35), 255, 255, 255)), 2
  try {
    $Graphics.FillPolygon($brush, $points)
    $Graphics.DrawLine($pen, $backX, $backY, $frontX, $frontY)
  } finally {
    $brush.Dispose()
    $pen.Dispose()
  }
}

function New-8DirectionSheet {
  param(
    [string]$SourcePath,
    [string]$WalkOutputPath,
    [string]$AttackOutputPath,
    [string]$EffectOutputPath,
    [hashtable]$Rows,
    [System.Drawing.Color]$EffectColor
  )
  $sourcePathToOpen = $SourcePath
  $tempSourcePath = $null
  if ([System.IO.Path]::GetFullPath($SourcePath) -eq [System.IO.Path]::GetFullPath($WalkOutputPath)) {
    $tempSourcePath = "$SourcePath.source.tmp.png"
    Copy-Item -LiteralPath $SourcePath -Destination $tempSourcePath -Force
    $sourcePathToOpen = $tempSourcePath
  }
  $source = [System.Drawing.Bitmap]::FromFile($sourcePathToOpen)
  try {
    $walk = New-TransparentBitmap -Width ($columns * $targetCell) -Height ($directions * $targetCell)
    $attack = New-TransparentBitmap -Width ($columns * $targetCell) -Height ($directions * $targetCell)
    $walkGraphics = [System.Drawing.Graphics]::FromImage($walk)
    $attackGraphics = [System.Drawing.Graphics]::FromImage($attack)
    try {
      Set-Quality -Graphics $walkGraphics
      Set-Quality -Graphics $attackGraphics
      $rowPlan = @(
        @{ Primary = 'front'; Secondary = $null; OffsetX = 0; OffsetY = 0 },
        @{ Primary = 'right'; Secondary = 'front'; OffsetX = 4; OffsetY = 2 },
        @{ Primary = 'right'; Secondary = $null; OffsetX = 0; OffsetY = 0 },
        @{ Primary = 'right'; Secondary = 'back'; OffsetX = 4; OffsetY = -2 },
        @{ Primary = 'back'; Secondary = $null; OffsetX = 0; OffsetY = 0 },
        @{ Primary = 'left'; Secondary = 'back'; OffsetX = -4; OffsetY = -2 },
        @{ Primary = 'left'; Secondary = $null; OffsetX = 0; OffsetY = 0 },
        @{ Primary = 'left'; Secondary = 'front'; OffsetX = -4; OffsetY = 2 }
      )
      for ($row = 0; $row -lt $directions; $row++) {
        $plan = $rowPlan[$row]
        $vector = Get-VectorForRow -Row $row
        for ($column = 0; $column -lt $columns; $column++) {
          $primaryCell = New-CellFromSource -Source $source -Column $column -Row $Rows[$plan.Primary] -OffsetX $plan.OffsetX -OffsetY $plan.OffsetY
          try {
            if ($plan.Secondary) {
              $secondaryCell = New-CellFromSource -Source $source -Column $column -Row $Rows[$plan.Secondary] -ScaleMultiplier 0.94 -OffsetX (-$plan.OffsetX) -OffsetY (-$plan.OffsetY)
              try {
                Draw-Cell -Graphics $walkGraphics -Cell $secondaryCell -Column $column -Row $row -Opacity 0.22
              } finally {
                $secondaryCell.Dispose()
              }
            }
            Draw-Cell -Graphics $walkGraphics -Cell $primaryCell -Column $column -Row $row -Opacity 1.0

            $lunge = [Math]::Sin((($column + 1) / $columns) * [Math]::PI)
            $attackOffsetX = [int]([double]$vector[0] * 9 * $lunge)
            $attackOffsetY = [int]([double]$vector[1] * 9 * $lunge)
            Draw-Cell -Graphics $attackGraphics -Cell $primaryCell -Column $column -Row $row -Opacity 1.0 -OffsetX $attackOffsetX -OffsetY $attackOffsetY
            Draw-AttackArc -Graphics $attackGraphics -Column $column -Row $row -Color $EffectColor
          } finally {
            $primaryCell.Dispose()
          }
        }
      }
      Save-Png -Bitmap $walk -Path $WalkOutputPath
      Save-Png -Bitmap $attack -Path $AttackOutputPath
    } finally {
      $walkGraphics.Dispose()
      $attackGraphics.Dispose()
      $walk.Dispose()
      $attack.Dispose()
    }
    New-AttackEffectSheet -OutputPath $EffectOutputPath -Color $EffectColor
  } finally {
    $source.Dispose()
    if ($tempSourcePath -and (Test-Path $tempSourcePath)) {
      Remove-Item -LiteralPath $tempSourcePath -Force
    }
  }
}

function New-AttackEffectSheet {
  param(
    [string]$OutputPath,
    [System.Drawing.Color]$Color
  )
  $bitmap = New-TransparentBitmap -Width ($columns * $targetCell) -Height ($directions * $targetCell)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  try {
    Set-Quality -Graphics $graphics
    for ($row = 0; $row -lt $directions; $row++) {
      for ($frame = 0; $frame -lt $columns; $frame++) {
        Draw-AttackArc -Graphics $graphics -Column $frame -Row $row -Color $Color
      }
    }
    Save-Png -Bitmap $bitmap -Path $OutputPath
  } finally {
    $graphics.Dispose()
    $bitmap.Dispose()
  }
}

function Get-PlayerBaseName {
  param([string]$FileName)
  return $FileName -replace '_walk_sheet\.png$', ''
}

function Get-GuaishouBaseName {
  param([string]$FileName)
  return $FileName -replace '_walk_sheet(?:_runtime|_runtime_128|_8dir)?\.png$', ''
}

function Get-BossBaseName {
  param([string]$FileName)
  return $FileName -replace '_walk(?:_runtime|_8dir_sheet)?\.png$', ''
}

function Select-SourceRows {
  param(
    [string]$SourcePath,
    [hashtable]$FallbackRows
  )
  $image = [System.Drawing.Image]::FromFile($SourcePath)
  try {
    $layout = Get-SourceLayout -Image $image
    if ($layout.RowCount -ge 8) {
      return @{ front = 0; right = 2; back = 4; left = 6 }
    }
    return $FallbackRows
  } finally {
    $image.Dispose()
  }
}

$playerDir = Join-Path $imageRoot 'player'
Get-ChildItem $playerDir -Filter 'player_*_walk_sheet.png' | ForEach-Object {
  $base = Get-PlayerBaseName $_.Name
  $existing8 = Join-Path $playerDir "$base`_walk_8dir_sheet.png"
  $sourcePath = $_.FullName
  $rows = Select-SourceRows -SourcePath $sourcePath -FallbackRows @{ front = 0; back = 1; left = 2; right = 3 }
  New-8DirectionSheet `
    -SourcePath $sourcePath `
    -WalkOutputPath $existing8 `
    -AttackOutputPath (Join-Path $playerDir "$base`_attack_8dir_sheet.png") `
    -EffectOutputPath (Join-Path $playerDir "$base`_attack_effect_8dir_sheet.png") `
    -Rows $rows `
    -EffectColor ([System.Drawing.Color]::FromArgb(39, 214, 255))
}

$guaishouDir = Join-Path $imageRoot 'guaishou'
Get-ChildItem $guaishouDir -Filter 'guaishou_*_walk_sheet.png' | ForEach-Object {
  $base = Get-GuaishouBaseName $_.Name
  $walk8 = Join-Path $guaishouDir "$base`_walk_8dir_sheet.png"
  $sourcePath = $_.FullName
  $rows = Select-SourceRows -SourcePath $sourcePath -FallbackRows @{ front = 0; back = 1; left = 2; right = 3 }
  New-8DirectionSheet `
    -SourcePath $sourcePath `
    -WalkOutputPath $walk8 `
    -AttackOutputPath (Join-Path $guaishouDir "$base`_attack_8dir_sheet.png") `
    -EffectOutputPath (Join-Path $guaishouDir "$base`_attack_effect_8dir_sheet.png") `
    -Rows $rows `
    -EffectColor ([System.Drawing.Color]::FromArgb(255, 91, 111))
  Copy-Item -LiteralPath $walk8 -Destination (Join-Path $guaishouDir "$base`_walk_sheet_runtime_128.png") -Force
}

$bossDir = Join-Path $imageRoot 'bosses'
Get-ChildItem $bossDir -Filter 'boss_*_walk_8dir_sheet.png' | ForEach-Object {
  $base = Get-BossBaseName $_.Name
  $walk8 = $_.FullName
  $rows = Select-SourceRows -SourcePath $walk8 -FallbackRows @{ front = 0; back = 4; left = 6; right = 2 }
  New-8DirectionSheet `
    -SourcePath $walk8 `
    -WalkOutputPath $walk8 `
    -AttackOutputPath (Join-Path $bossDir "$base`_attack_8dir_sheet.png") `
    -EffectOutputPath (Join-Path $bossDir "$base`_attack_effect_8dir_sheet.png") `
    -Rows $rows `
    -EffectColor ([System.Drawing.Color]::FromArgb(255, 200, 87))
  Copy-Item -LiteralPath $walk8 -Destination (Join-Path $bossDir "$base`_walk_runtime.png") -Force
}

Write-Host 'Grass game sprite optimization complete.'

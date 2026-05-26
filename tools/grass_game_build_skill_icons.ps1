Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'

$root = Resolve-Path '.'
$outDir = Join-Path $root 'assets/game/grass_game/images/skills'

function Convert-ChromaIcon {
  param(
    [Parameter(Mandatory = $true)][string]$SourcePath,
    [Parameter(Mandatory = $true)][string]$OutputPath
  )

  $img = [System.Drawing.Bitmap]::FromFile($SourcePath)
  try {
    $width = $img.Width
    $height = $img.Height
    $alpha = New-Object byte[] ($width * $height)
    $minX = $width
    $minY = $height
    $maxX = -1
    $maxY = -1

    for ($y = 0; $y -lt $height; $y++) {
      for ($x = 0; $x -lt $width; $x++) {
        $color = $img.GetPixel($x, $y)
        $greenScore = [int]$color.G - [Math]::Max([int]$color.R, [int]$color.B)
        $magentaScore = (([int]$color.R + [int]$color.B) / 2) - [int]$color.G
        $isKey =
          ([int]$color.G -gt 120 -and $greenScore -gt 45) -or
          ([int]$color.R -gt 150 -and [int]$color.B -gt 150 -and $magentaScore -gt 50)
        $a = if ($isKey) { 0 } else { 255 }
        $alpha[$y * $width + $x] = [byte]$a
        if ($a -gt 0) {
          if ($x -lt $minX) { $minX = $x }
          if ($x -gt $maxX) { $maxX = $x }
          if ($y -lt $minY) { $minY = $y }
          if ($y -gt $maxY) { $maxY = $y }
        }
      }
    }

    if ($maxX -lt 0) {
      throw "No subject after chroma key: $SourcePath"
    }

    $pad = 18
    $minX = [Math]::Max(0, $minX - $pad)
    $minY = [Math]::Max(0, $minY - $pad)
    $maxX = [Math]::Min($width - 1, $maxX + $pad)
    $maxY = [Math]::Min($height - 1, $maxY + $pad)
    $cropWidth = $maxX - $minX + 1
    $cropHeight = $maxY - $minY + 1

    $cropped = New-Object System.Drawing.Bitmap $cropWidth, $cropHeight, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    for ($y = 0; $y -lt $cropHeight; $y++) {
      for ($x = 0; $x -lt $cropWidth; $x++) {
        $sourceX = $minX + $x
        $sourceY = $minY + $y
        $color = $img.GetPixel($sourceX, $sourceY)
        $a = [int]$alpha[$sourceY * $width + $sourceX]
        if ($a -eq 0) {
          $cropped.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
          continue
        }

        $r = [int]$color.R
        $g = [int]$color.G
        $b = [int]$color.B
        if ($g -gt [Math]::Max($r, $b) + 24) {
          $g = [Math]::Max($r, $b) + 24
        }
        if ($r -gt 150 -and $b -gt 150 -and ((($r + $b) / 2) - $g) -gt 50) {
          $r = [Math]::Min($r, [Math]::Max($g, $b) + 22)
          $b = [Math]::Min($b, [Math]::Max($g, $r) + 22)
        }
        $r = [Math]::Max(0, [Math]::Min(255, $r))
        $g = [Math]::Max(0, [Math]::Min(255, $g))
        $b = [Math]::Max(0, [Math]::Min(255, $b))
        $cropped.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($a, $r, $g, $b))
      }
    }

    $size = 128
    $output = New-Object System.Drawing.Bitmap $size, $size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($output)
    try {
      $graphics.Clear([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
      $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
      $scale = [Math]::Min(112.0 / $cropWidth, 112.0 / $cropHeight)
      $drawWidth = [int][Math]::Round($cropWidth * $scale)
      $drawHeight = [int][Math]::Round($cropHeight * $scale)
      $drawX = [int][Math]::Round(($size - $drawWidth) / 2)
      $drawY = [int][Math]::Round(($size - $drawHeight) / 2)
      $graphics.DrawImage(
        $cropped,
        (New-Object System.Drawing.Rectangle $drawX, $drawY, $drawWidth, $drawHeight),
        (New-Object System.Drawing.Rectangle 0, 0, $cropWidth, $cropHeight),
        [System.Drawing.GraphicsUnit]::Pixel
      )
      $output.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
      $graphics.Dispose()
      $output.Dispose()
      $cropped.Dispose()
    }
  } finally {
    $img.Dispose()
  }
}

$generated = @(
  @{ Id = 'star_projectile'; Path = 'C:\Users\Administrator\.codex\generated_images\019e26e0-d909-7921-a64d-7f4f8e839f0a\ig_044743bc11270b01016a14673063b48191a559ace14ed18004.png' },
  @{ Id = 'orbit_blade'; Path = 'C:\Users\Administrator\.codex\generated_images\019e26e0-d909-7921-a64d-7f4f8e839f0a\ig_044743bc11270b01016a146881505c8191af6fa0c40386f093.png' },
  @{ Id = 'thunder_matrix'; Path = 'C:\Users\Administrator\.codex\generated_images\019e26e0-d909-7921-a64d-7f4f8e839f0a\ig_044743bc11270b01016a1468bfa31081919ee58f1a63fe1eb8.png' },
  @{ Id = 'void_magnet'; Path = 'C:\Users\Administrator\.codex\generated_images\019e26e0-d909-7921-a64d-7f4f8e839f0a\ig_044743bc11270b01016a1468f69a048191b69cca894d2b0503.png' },
  @{ Id = 'ice_nova'; Path = 'C:\Users\Administrator\.codex\generated_images\019e26e0-d909-7921-a64d-7f4f8e839f0a\ig_044743bc11270b01016a146934fe348191b0240f47347d6468.png' },
  @{ Id = 'fire_trail'; Path = 'C:\Users\Administrator\.codex\generated_images\019e26e0-d909-7921-a64d-7f4f8e839f0a\ig_044743bc11270b01016a14696cd91081919d62fef7068e9332.png' },
  @{ Id = 'poison_spore'; Path = 'C:\Users\Administrator\.codex\generated_images\019e26e0-d909-7921-a64d-7f4f8e839f0a\ig_044743bc11270b01016a1469a11a748191b7dd8ba37d6e613d.png' },
  @{ Id = 'shadow_guard'; Path = 'C:\Users\Administrator\.codex\generated_images\019e26e0-d909-7921-a64d-7f4f8e839f0a\ig_044743bc11270b01016a1469dcc4b88191a73f386504f75a45.png' }
)

foreach ($item in $generated) {
  Convert-ChromaIcon `
    -SourcePath $item.Path `
    -OutputPath (Join-Path $outDir "skill_$($item.Id).png")
  Write-Host "processed $($item.Id)"
}

$specialGenerated = @(
  @{ Id = 'evolve_star_barrage'; Path = 'C:\Users\Administrator\.codex\generated_images\019e26e0-d909-7921-a64d-7f4f8e839f0a\ig_044743bc11270b01016a146baa4ba88191a58043efb63b7d24.png' },
  @{ Id = 'evolve_moon_wheel'; Path = 'C:\Users\Administrator\.codex\generated_images\019e26e0-d909-7921-a64d-7f4f8e839f0a\ig_044743bc11270b01016a146c18704481918c0a9eb020226648.png' },
  @{ Id = 'evolve_thunder_chain'; Path = 'C:\Users\Administrator\.codex\generated_images\019e26e0-d909-7921-a64d-7f4f8e839f0a\ig_044743bc11270b01016a146c8fdff0819180b39911dfac4e0f.png' },
  @{ Id = 'evolve_black_hole'; Path = 'C:\Users\Administrator\.codex\generated_images\019e26e0-d909-7921-a64d-7f4f8e839f0a\ig_044743bc11270b01016a146ced1f648191b95792470aefedd6.png' },
  @{ Id = 'evolve_permafrost_field'; Path = 'C:\Users\Administrator\.codex\generated_images\019e26e0-d909-7921-a64d-7f4f8e839f0a\ig_044743bc11270b01016a146d83c9b081919603362f53c0655d.png' },
  @{ Id = 'evolve_inferno_path'; Path = 'C:\Users\Administrator\.codex\generated_images\019e26e0-d909-7921-a64d-7f4f8e839f0a\ig_044743bc11270b01016a146de99efc8191a46adab1274a9332.png' },
  @{ Id = 'evolve_corrosive_plague'; Path = 'C:\Users\Administrator\.codex\generated_images\019e26e0-d909-7921-a64d-7f4f8e839f0a\ig_044743bc11270b01016a146e426a108191b78904a7f0c44069.png' },
  @{ Id = 'evolve_twin_shadow'; Path = 'C:\Users\Administrator\.codex\generated_images\019e26e0-d909-7921-a64d-7f4f8e839f0a\ig_044743bc11270b01016a146f386de08191b65ebed87b1b5b9f.png' },
  @{ Id = 'ultimate_star_judgement'; Path = 'C:\Users\Administrator\.codex\generated_images\019e26e0-d909-7921-a64d-7f4f8e839f0a\ig_044743bc11270b01016a146fa57ea48191856efafdf845664e.png' },
  @{ Id = 'ultimate_black_moon'; Path = 'C:\Users\Administrator\.codex\generated_images\019e26e0-d909-7921-a64d-7f4f8e839f0a\ig_044743bc11270b01016a1470143b048191b4a44f8b130b401a.png' },
  @{ Id = 'ultimate_frost_inferno'; Path = 'C:\Users\Administrator\.codex\generated_images\019e26e0-d909-7921-a64d-7f4f8e839f0a\ig_044743bc11270b01016a14709426848191ba369c576a0e017d.png' }
)

foreach ($item in $specialGenerated) {
  Convert-ChromaIcon `
    -SourcePath $item.Path `
    -OutputPath (Join-Path $outDir "skill_$($item.Id).png")
  Write-Host "processed $($item.Id)"
}

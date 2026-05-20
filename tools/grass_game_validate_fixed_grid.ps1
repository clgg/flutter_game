param(
  [string]$Path = 'assets/game/grass_game/images/player',
  [string]$Filter = '*_8dir_sheet.png',
  [int]$SheetWidth = 256,
  [int]$SheetHeight = 1024,
  [int]$Columns = 2,
  [int]$Rows = 8,
  [int]$CellSize = 128,
  [int]$PaddingWarning = 4
)

Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies 'System.Drawing' -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class FixedGridSheetValidator
{
    public static string[] Validate(
        string path,
        int sheetWidth,
        int sheetHeight,
        int columns,
        int rows,
        int cellSize,
        int paddingWarning)
    {
        var messages = new List<string>();
        using (var source = new Bitmap(path))
        {
            if (source.Width != sheetWidth || source.Height != sheetHeight)
            {
                messages.Add("ERROR size " + source.Width + "x" + source.Height +
                    ", expected " + sheetWidth + "x" + sheetHeight);
                return messages.ToArray();
            }

            using (var bitmap = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb))
            using (var graphics = Graphics.FromImage(bitmap))
            {
                graphics.Clear(Color.Transparent);
                graphics.DrawImageUnscaled(source, 0, 0);

                var rect = new Rectangle(0, 0, bitmap.Width, bitmap.Height);
                var data = bitmap.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
                try
                {
                    int stride = Math.Abs(data.Stride);
                    byte[] bytes = new byte[stride * bitmap.Height];
                    Marshal.Copy(data.Scan0, bytes, 0, bytes.Length);

                    for (int row = 0; row < rows; row++)
                    {
                        for (int column = 0; column < columns; column++)
                        {
                            int minX = cellSize;
                            int minY = cellSize;
                            int maxX = -1;
                            int maxY = -1;

                            for (int y = 0; y < cellSize; y++)
                            {
                                int py = row * cellSize + y;
                                int rowOffset = py * stride;
                                for (int x = 0; x < cellSize; x++)
                                {
                                    int px = column * cellSize + x;
                                    byte alpha = bytes[rowOffset + px * 4 + 3];
                                    if (alpha > 8)
                                    {
                                        if (x < minX) minX = x;
                                        if (y < minY) minY = y;
                                        if (x > maxX) maxX = x;
                                        if (y > maxY) maxY = y;
                                    }
                                }
                            }

                            string cellName = "row=" + row + " col=" + column;
                            if (maxX < 0)
                            {
                                messages.Add("ERROR " + cellName + " is empty");
                                continue;
                            }

                            if (minX < paddingWarning || minY < paddingWarning ||
                                maxX >= cellSize - paddingWarning ||
                                maxY >= cellSize - paddingWarning)
                            {
                                messages.Add("WARN " + cellName + " touches padding bounds local=[" +
                                    minX + "," + minY + "]-[" + maxX + "," + maxY + "]");
                            }
                        }
                    }
                }
                finally
                {
                    bitmap.UnlockBits(data);
                }
            }
        }

        return messages.ToArray();
    }
}
'@

$ErrorActionPreference = 'Stop'

$root = (Resolve-Path '.').Path
$assetPath = (Resolve-Path $Path).Path
if (-not $assetPath.StartsWith($root)) {
  throw "Path must be inside workspace: $assetPath"
}

$failed = $false
$files = @(Get-ChildItem -Path $assetPath -Filter $Filter -File | Sort-Object Name)
if ($files.Count -eq 0) {
  throw "No files matched: $Path/$Filter"
}

foreach ($file in $files) {
  $messages = [FixedGridSheetValidator]::Validate(
    $file.FullName,
    $SheetWidth,
    $SheetHeight,
    $Columns,
    $Rows,
    $CellSize,
    $PaddingWarning
  )
  $errors = @($messages | Where-Object { $_.StartsWith('ERROR ') })
  $warnings = @($messages | Where-Object { $_.StartsWith('WARN ') })

  if ($errors.Count -gt 0) {
    $failed = $true
    Write-Host "FAIL $($file.Name)"
    $errors | ForEach-Object { Write-Host "  $_" }
    $warnings | ForEach-Object { Write-Host "  $_" }
  } elseif ($warnings.Count -gt 0) {
    Write-Host "WARN $($file.Name)"
    $warnings | ForEach-Object { Write-Host "  $_" }
  } else {
    Write-Host "OK   $($file.Name)"
  }
}

if ($failed) {
  exit 1
}

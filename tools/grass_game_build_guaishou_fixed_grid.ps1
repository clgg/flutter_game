Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'

Add-Type -ReferencedAssemblies 'System.Drawing' -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class GrassGuaishouFixedGridBuilder
{
    const int SourceColumns = 6;
    const int TargetColumns = 2;
    const int Directions = 8;
    const int Cell = 128;
    static readonly int[] FrameColumns = new [] { 0, 5 };

    public static void Generate(string sourcePath, string outputPath)
    {
        using (var source = new Bitmap(sourcePath))
        using (var output = new Bitmap(TargetColumns * Cell, Directions * Cell, PixelFormat.Format32bppArgb))
        using (var g = Graphics.FromImage(output))
        {
            g.Clear(Color.Transparent);
            Quality(g);

            var sourceCell = source.Width / SourceColumns;
            var sourceRows = Math.Max(1, source.Height / sourceCell);
            if (source.Width != 1536 || (sourceRows != 4 && sourceRows != 8))
            {
                throw new InvalidOperationException(
                    "Unexpected guaishou source size: " + sourcePath + " is " +
                    source.Width + "x" + source.Height + ", expected 1536x1024 or 1536x2048.");
            }

            var alpha = ReadAlpha(source);
            for (var targetRow = 0; targetRow < Directions; targetRow++)
            {
                var sourceRow = SourceRowFor(targetRow, sourceRows);
                for (var targetColumn = 0; targetColumn < TargetColumns; targetColumn++)
                {
                    DrawFrame(g, source, alpha, sourceCell, sourceRow, FrameColumns[targetColumn], targetRow, targetColumn);
                }
            }

            Directory.CreateDirectory(Path.GetDirectoryName(outputPath));
            output.Save(outputPath, ImageFormat.Png);
        }
    }

    static byte[] ReadAlpha(Bitmap source)
    {
        var rect = new Rectangle(0, 0, source.Width, source.Height);
        var data = source.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        try
        {
            var stride = Math.Abs(data.Stride);
            var raw = new byte[stride * source.Height];
            System.Runtime.InteropServices.Marshal.Copy(data.Scan0, raw, 0, raw.Length);
            var alpha = new byte[source.Width * source.Height];
            for (var y = 0; y < source.Height; y++)
            {
                var rowOffset = y * stride;
                var alphaOffset = y * source.Width;
                for (var x = 0; x < source.Width; x++)
                {
                    alpha[alphaOffset + x] = raw[rowOffset + x * 4 + 3];
                }
            }
            return alpha;
        }
        finally
        {
            source.UnlockBits(data);
        }
    }

    static bool HasAlpha(byte[] alpha, int imageWidth, int x, int y)
    {
        return alpha[y * imageWidth + x] > 8;
    }

    static Rectangle FindFrameBounds(Bitmap source, byte[] alpha, int sourceCell, int sourceRow, int sourceColumn)
    {
        var rowTop = sourceRow * sourceCell;
        var rowBottom = Math.Min(source.Height, rowTop + sourceCell);
        var runs = new List<Tuple<int, int>>();
        var inRun = false;
        var runStart = 0;
        var lastAlphaX = 0;
        for (var x = 0; x < source.Width; x++)
        {
            var hasAlpha = false;
            for (var y = rowTop; y < rowBottom; y++)
            {
                if (HasAlpha(alpha, source.Width, x, y))
                {
                    hasAlpha = true;
                    break;
                }
            }
            if (hasAlpha)
            {
                if (!inRun)
                {
                    runStart = x;
                    inRun = true;
                }
                lastAlphaX = x;
            }
            else if (inRun && x - lastAlphaX > 10)
            {
                if (lastAlphaX - runStart > 18) runs.Add(Tuple.Create(runStart, lastAlphaX));
                inRun = false;
            }
        }
        if (inRun && lastAlphaX - runStart > 18) runs.Add(Tuple.Create(runStart, lastAlphaX));

        if (runs.Count < SourceColumns)
        {
            return AlphaBounds(source, alpha, new Rectangle(sourceColumn * sourceCell, rowTop, sourceCell, sourceCell));
        }

        var run = runs[Math.Min(sourceColumn, runs.Count - 1)];
        var left = Math.Max(0, run.Item1 - 8);
        var right = Math.Min(source.Width, run.Item2 + 9);
        return AlphaBounds(source, alpha, new Rectangle(left, rowTop, right - left, rowBottom - rowTop));
    }

    static Rectangle AlphaBounds(Bitmap source, byte[] alpha, Rectangle rect)
    {
        var minX = rect.Right;
        var minY = rect.Bottom;
        var maxX = rect.Left - 1;
        var maxY = rect.Top - 1;
        for (var y = rect.Top; y < rect.Bottom; y++)
        {
            for (var x = rect.Left; x < rect.Right; x++)
            {
                if (!HasAlpha(alpha, source.Width, x, y)) continue;
                minX = Math.Min(minX, x);
                minY = Math.Min(minY, y);
                maxX = Math.Max(maxX, x);
                maxY = Math.Max(maxY, y);
            }
        }
        if (maxX < minX || maxY < minY) return rect;
        return Rectangle.FromLTRB(
            Math.Max(rect.Left, minX - 8),
            Math.Max(rect.Top, minY - 10),
            Math.Min(rect.Right, maxX + 9),
            Math.Min(rect.Bottom, maxY + 6));
    }

    static int SourceRowFor(int targetRow, int sourceRows)
    {
        if (sourceRows >= 8)
        {
            switch (targetRow)
            {
                case 0: return 0;
                case 1:
                case 2:
                case 3: return 2;
                case 4: return 4;
                case 5:
                case 6:
                default: return 6;
            }
        }

        switch (targetRow)
        {
            case 0: return 0;
            case 1:
            case 2:
            case 3: return 3;
            case 4: return 1;
            case 5:
            case 6:
            default: return 2;
        }
    }

    static void DrawFrame(
        Graphics g,
        Bitmap source,
        byte[] alpha,
        int sourceCell,
        int sourceRow,
        int sourceColumn,
        int targetRow,
        int targetColumn)
    {
        var src = FindFrameBounds(source, alpha, sourceCell, sourceRow, sourceColumn);
        var scale = Math.Min(104.0 / src.Width, 106.0 / src.Height);
        var width = Math.Max(1, (int)Math.Round(src.Width * scale));
        var height = Math.Max(1, (int)Math.Round(src.Height * scale));
        var dst = new Rectangle(
            targetColumn * Cell + (Cell - width) / 2,
            targetRow * Cell + Math.Max(10, 118 - height),
            width,
            height);
        using (var cleaned = CleanFrame(source, src))
        {
            g.DrawImage(cleaned, dst, new Rectangle(0, 0, src.Width, src.Height), GraphicsUnit.Pixel);
        }
    }

    static Bitmap CleanFrame(Bitmap source, Rectangle src)
    {
        var frame = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb);
        using (var g = Graphics.FromImage(frame))
        {
            g.Clear(Color.Transparent);
            g.DrawImage(source, new Rectangle(0, 0, src.Width, src.Height), src, GraphicsUnit.Pixel);
        }

        var rect = new Rectangle(0, 0, frame.Width, frame.Height);
        var data = frame.LockBits(rect, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
        try
        {
            var stride = Math.Abs(data.Stride);
            var raw = new byte[stride * frame.Height];
            System.Runtime.InteropServices.Marshal.Copy(data.Scan0, raw, 0, raw.Length);
            for (var y = 0; y < frame.Height; y++)
            {
                var rowOffset = y * stride;
                for (var x = 0; x < frame.Width; x++)
                {
                    var i = rowOffset + x * 4;
                    var b = raw[i];
                    var gr = raw[i + 1];
                    var r = raw[i + 2];
                    var a = raw[i + 3];
                    if (a == 0) continue;

                    var isRedAttackResidue = r > 125 && r > gr * 1.45 && r > b * 1.45 && a < 245;
                    var isGroundShadow = y > frame.Height * 0.72 && a < 235 && r < 65 && gr < 65 && b < 65;
                    if (isRedAttackResidue || isGroundShadow)
                    {
                        raw[i + 3] = 0;
                    }
                }
            }
            System.Runtime.InteropServices.Marshal.Copy(raw, 0, data.Scan0, raw.Length);
        }
        finally
        {
            frame.UnlockBits(data);
        }
        return frame;
    }

    static void Quality(Graphics g)
    {
        g.CompositingMode = CompositingMode.SourceOver;
        g.CompositingQuality = CompositingQuality.HighQuality;
        g.InterpolationMode = InterpolationMode.HighQualityBicubic;
        g.PixelOffsetMode = PixelOffsetMode.HighQuality;
        g.SmoothingMode = SmoothingMode.HighQuality;
    }
}
'@

$root = Resolve-Path '.'
$dir = Join-Path $root 'assets/game/grass_game/images/guaishou'
$converted = 0

Get-ChildItem $dir -Filter 'guaishou_*_walk_sheet.png' | Sort-Object Name | ForEach-Object {
  $base = $_.Name -replace '_walk_sheet\.png$', ''
  $runtimeOutput = Join-Path $dir "$base`_walk_sheet_runtime_128.png"
  $walkOutput = Join-Path $dir "$base`_walk_8dir_sheet.png"
  [GrassGuaishouFixedGridBuilder]::Generate($_.FullName, $runtimeOutput)
  Copy-Item -LiteralPath $runtimeOutput -Destination $walkOutput -Force
  $converted++
}

Write-Host "Converted $converted guaishou walk sheets to clean 8x2 fixed grid sampling."

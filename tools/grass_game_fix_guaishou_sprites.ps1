Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class GrassGuaishouSpriteFixer
{
    const int Columns = 6;
    const int Directions = 8;
    const int Cell = 128;
    const int AlphaThreshold = 8;

    public static void Generate(string sourcePath, string walkPath, string attackPath, string effectPath)
    {
        using (var source = new Bitmap(sourcePath))
        using (var walk = NewSheet())
        using (var attack = NewSheet())
        using (var walkG = Graphics.FromImage(walk))
        using (var attackG = Graphics.FromImage(attack))
        {
            Quality(walkG);
            Quality(attackG);
            var alpha = ReadAlpha(source);
            var rowCount = Math.Max(1, (int)Math.Round(source.Height / (source.Width / (double)Columns)));
            var rows = new Dictionary<string, int>();
            if (rowCount >= 8)
            {
                rows.Add("front", 0);
                rows.Add("right", 2);
                rows.Add("back", 4);
                rows.Add("left", 6);
            }
            else
            {
                rows.Add("front", 0);
                rows.Add("back", 1);
                rows.Add("right", 2);
                rows.Add("left", 3);
            }
            var plan = new [] {
                Tuple.Create("front", (string)null),
                Tuple.Create("right", "front"),
                Tuple.Create("right", (string)null),
                Tuple.Create("right", "back"),
                Tuple.Create("back", (string)null),
                Tuple.Create("left", "back"),
                Tuple.Create("left", (string)null),
                Tuple.Create("left", "front"),
            };
            for (var row = 0; row < Directions; row++)
            {
                for (var col = 0; col < Columns; col++)
                {
                    if (plan[row].Item2 != null)
                    {
                        DrawFrame(walkG, source, alpha, rows[plan[row].Item2], col, row, 0.22f);
                    }
                    DrawFrame(walkG, source, alpha, rows[plan[row].Item1], col, row, 1f);
                    DrawFrame(attackG, source, alpha, rows[plan[row].Item1], col, row, 1f);
                    DrawAttackArc(attackG, col, row, Color.FromArgb(255, 91, 111));
                }
            }
            Save(walk, walkPath);
            Save(attack, attackPath);
        }
        using (var effect = NewSheet())
        using (var g = Graphics.FromImage(effect))
        {
            Quality(g);
            for (var row = 0; row < Directions; row++)
            {
                for (var col = 0; col < Columns; col++)
                {
                    DrawAttackArc(g, col, row, Color.FromArgb(255, 91, 111));
                }
            }
            Save(effect, effectPath);
        }
    }

    static Bitmap NewSheet()
    {
        var bmp = new Bitmap(Columns * Cell, Directions * Cell, PixelFormat.Format32bppArgb);
        using (var g = Graphics.FromImage(bmp))
        {
            g.Clear(Color.Transparent);
        }
        return bmp;
    }

    static void Quality(Graphics g)
    {
        g.CompositingMode = CompositingMode.SourceOver;
        g.CompositingQuality = CompositingQuality.HighQuality;
        g.InterpolationMode = InterpolationMode.HighQualityBicubic;
        g.PixelOffsetMode = PixelOffsetMode.HighQuality;
        g.SmoothingMode = SmoothingMode.HighQuality;
    }

    static byte[] ReadAlpha(Bitmap source)
    {
        var rect = new Rectangle(0, 0, source.Width, source.Height);
        var data = source.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        try
        {
            var raw = new byte[Math.Abs(data.Stride) * source.Height];
            System.Runtime.InteropServices.Marshal.Copy(data.Scan0, raw, 0, raw.Length);
            var alpha = new byte[source.Width * source.Height];
            for (var y = 0; y < source.Height; y++)
            {
                var rowOffset = y * Math.Abs(data.Stride);
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
        return alpha[y * imageWidth + x] > AlphaThreshold;
    }

    static Rectangle FindFrameBounds(Bitmap source, byte[] alpha, int row, int column)
    {
        var cellWidth = source.Width / Columns;
        var rowCount = Math.Max(1, (int)Math.Round(source.Height / (double)cellWidth));
        var cellHeight = source.Height / rowCount;
        var rowTop = row * cellHeight;
        var rowBottom = Math.Min(source.Height, rowTop + cellHeight);
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
        if (runs.Count < Columns)
        {
            var fallback = new Rectangle(column * cellWidth, rowTop, cellWidth, cellHeight);
            return AlphaBounds(source, alpha, fallback);
        }
        var run = runs[Math.Min(column, runs.Count - 1)];
        var left = Math.Max(0, run.Item1 - 4);
        var right = Math.Min(source.Width, run.Item2 + 5);
        var minY = rowBottom;
        var maxY = rowTop - 1;
        for (var y = rowTop; y < rowBottom; y++)
        {
            for (var x = left; x < right; x++)
            {
                if (HasAlpha(alpha, source.Width, x, y))
                {
                    minY = Math.Min(minY, y);
                    maxY = Math.Max(maxY, y);
                }
            }
        }
        if (maxY < minY) return new Rectangle(column * cellWidth, rowTop, cellWidth, cellHeight);
        var top = Math.Max(rowTop, minY - 4);
        var bottom = Math.Min(rowBottom, maxY + 5);
        return new Rectangle(left, top, right - left, bottom - top);
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
            Math.Max(rect.Left, minX - 3),
            Math.Max(rect.Top, minY - 3),
            Math.Min(rect.Right, maxX + 4),
            Math.Min(rect.Bottom, maxY + 4));
    }

    static void DrawFrame(Graphics g, Bitmap source, byte[] alpha, int sourceRow, int sourceColumn, int targetRow, float opacity)
    {
        var src = FindFrameBounds(source, alpha, sourceRow, sourceColumn);
        var scale = Math.Min(106.0 / src.Width, 112.0 / src.Height);
        var width = Math.Max(1, (int)Math.Round(src.Width * scale));
        var height = Math.Max(1, (int)Math.Round(src.Height * scale));
        var left = sourceColumn * Cell + (Cell - width) / 2;
        var top = targetRow * Cell + Math.Max(5, 120 - height);
        if (top + height > targetRow * Cell + 123) top = targetRow * Cell + 123 - height;
        var dst = new Rectangle(left, top, width, height);
        if (opacity >= 0.999f)
        {
            g.DrawImage(source, dst, src, GraphicsUnit.Pixel);
            return;
        }
        using (var attr = new ImageAttributes())
        {
            var matrix = new ColorMatrix();
            matrix.Matrix00 = 1f;
            matrix.Matrix11 = 1f;
            matrix.Matrix22 = 1f;
            matrix.Matrix33 = opacity;
            matrix.Matrix44 = 1f;
            attr.SetColorMatrix(matrix, ColorMatrixFlag.Default, ColorAdjustType.Bitmap);
            g.DrawImage(source, dst, src.X, src.Y, src.Width, src.Height, GraphicsUnit.Pixel, attr);
        }
    }

    static void DrawAttackArc(Graphics g, int col, int row, Color color)
    {
        var vectors = new [] {
            Tuple.Create(0.0, 1.0), Tuple.Create(0.707, 0.707),
            Tuple.Create(1.0, 0.0), Tuple.Create(0.707, -0.707),
            Tuple.Create(0.0, -1.0), Tuple.Create(-0.707, -0.707),
            Tuple.Create(-1.0, 0.0), Tuple.Create(-0.707, 0.707),
        };
        var dx = vectors[row].Item1;
        var dy = vectors[row].Item2;
        var progress = (col + 1.0) / Columns;
        var alpha = Math.Max(0, (int)(45 + 155 * Math.Sin(progress * Math.PI)));
        var cx = col * Cell + 64 + dx * (8 + 13 * progress);
        var cy = row * Cell + 68 + dy * (8 + 13 * progress);
        var length = 24 + 18 * progress;
        var width = 9 + 8 * progress;
        var angle = Math.Atan2(dy, dx);
        var px = -Math.Sin(angle);
        var py = Math.Cos(angle);
        var frontX = cx + dx * length;
        var frontY = cy + dy * length;
        var backX = cx - dx * (length * 0.45);
        var backY = cy - dy * (length * 0.45);
        var points = new [] {
            new PointF((float)frontX, (float)frontY),
            new PointF((float)(backX + px * width), (float)(backY + py * width)),
            new PointF((float)(backX - px * width), (float)(backY - py * width)),
        };
        using (var brush = new SolidBrush(Color.FromArgb(alpha, color.R, color.G, color.B)))
        using (var pen = new Pen(Color.FromArgb(Math.Min(255, alpha + 35), 255, 255, 255), 2f))
        {
            g.FillPolygon(brush, points);
            g.DrawLine(pen, (float)backX, (float)backY, (float)frontX, (float)frontY);
        }
    }

    static void Save(Bitmap bitmap, string path)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(path));
        bitmap.Save(path, ImageFormat.Png);
    }
}
'@

$root = Resolve-Path '.'
$dir = Join-Path $root 'assets/game/grass_game/images/guaishou'
Get-ChildItem $dir -Filter 'guaishou_*_walk_sheet.png' | ForEach-Object {
  $base = $_.Name -replace '_walk_sheet\.png$', ''
  $walk = Join-Path $dir "$base`_walk_8dir_sheet.png"
  $attack = Join-Path $dir "$base`_attack_8dir_sheet.png"
  $effect = Join-Path $dir "$base`_attack_effect_8dir_sheet.png"
  [GrassGuaishouSpriteFixer]::Generate($_.FullName, $walk, $attack, $effect)
  Copy-Item -LiteralPath $walk -Destination (Join-Path $dir "$base`_walk_sheet_runtime_128.png") -Force
}
Write-Host 'Guaishou sprites fixed.'

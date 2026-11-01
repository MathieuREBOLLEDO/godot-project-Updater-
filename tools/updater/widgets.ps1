# Themed controls and the window background.

function New-Label([string]$text, [int]$x, [int]$y, $font, [string]$color = 'sand') {
    $l = New-Object Windows.Forms.Label
    $l.Text = $text; $l.Location = New-Object Drawing.Point($x, $y)
    $l.AutoSize = $true; $l.Font = $font; $l.ForeColor = C $color
    $l.BackColor = [Drawing.Color]::Transparent
    return $l
}

function New-Field([int]$x, [int]$y, [int]$w) {
    $t = New-Object Windows.Forms.TextBox
    $t.Location = New-Object Drawing.Point($x, $y); $t.Width = $w
    $t.Font = $script:Fonts.mono; $t.BorderStyle = 'FixedSingle'
    $t.BackColor = C 'ink_panel'; $t.ForeColor = C 'sand'
    return $t
}

function New-Button([string]$text, [int]$x, [int]$y, [int]$w, [bool]$primary) {
    $b = New-Object Windows.Forms.Button
    $b.Text = $text; $b.Location = New-Object Drawing.Point($x, $y)
    $b.Size = New-Object Drawing.Size($w, 34); $b.Font = $script:Fonts.ui
    $b.FlatStyle = 'Flat'; $b.Cursor = 'Hand'
    $b.FlatAppearance.BorderSize = if ($primary) { 0 } else { 1 }
    $b.FlatAppearance.BorderColor = C 'ink_line'
    $b.BackColor = if ($primary) { C 'accent' } else { C 'ink_raised' }
    $b.ForeColor = if ($primary) { C 'ink' } else { C 'sand' }
    $b.FlatAppearance.MouseOverBackColor = if ($primary) { [Drawing.Color]::FromArgb(255, 150, 205, 252) } else { C 'ink_line' }
    return $b
}

# Diagonal hatching, header and footer bands, soft vignette.
function Draw-Background($form, $e) {
    $g = $e.Graphics
    $w = $form.ClientSize.Width; $h = $form.ClientSize.Height
    $g.Clear((C 'ink'))
    $pen = New-Object Drawing.Pen((C 'ink_panel' 140), 1)
    $step = [int](18 * $form.DeviceDpi / 96)
    for ($i = -$h; $i -lt $w; $i += $step) { $g.DrawLine($pen, $i, $h, $i + $h, 0) }
    $pen.Dispose()

    $header = $script:Layout.header * $form.DeviceDpi / 96
    $footer = $h - $script:Layout.footer * $form.DeviceDpi / 96
    $band = New-Object Drawing.SolidBrush((C 'ink_panel' 235))
    $g.FillRectangle($band, 0, 0, $w, $header)
    $g.FillRectangle($band, 0, $footer, $w, $h - $footer)
    $band.Dispose()
    $line = New-Object Drawing.Pen((C 'ink_line'), 1)
    $g.DrawLine($line, 0, $header, $w, $header)
    $g.DrawLine($line, 0, $footer, $w, $footer)
    $line.Dispose()

    $path = New-Object Drawing.Drawing2D.GraphicsPath
    $path.AddEllipse(-$w * 0.25, -$h * 0.3, $w * 1.5, $h * 1.6)
    $glow = New-Object Drawing.Drawing2D.PathGradientBrush($path)
    $glow.CenterColor = [Drawing.Color]::FromArgb(0, 0, 0, 0)
    $glow.SurroundColors = @([Drawing.Color]::FromArgb(110, 0, 0, 0))
    $g.FillRectangle($glow, 0, 0, $w, $h)
    $glow.Dispose(); $path.Dispose()
}

function Write-LogLine($box, [string]$kind, [string]$text) {
    $colors = @{ step = 'sand'; good = 'good'; bad = 'bad'; info = 'info'; raw = 'sand_dim' }
    $prefix = @{ step = '> '; good = '  + '; bad = '  ! '; info = '  · '; raw = '' }
    if ($kind -eq 'step' -and $box.TextLength) { $box.AppendText("`n") }
    $box.SelectionStart = $box.TextLength
    $box.SelectionColor = C $colors[$kind]
    $box.AppendText($prefix[$kind] + $text + "`n")
    $box.ScrollToCaret()
}

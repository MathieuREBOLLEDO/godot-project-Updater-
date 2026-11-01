# Window theme: every color, font and size lives here. A design_tokens.cfg at
# the project root overrides the colors ([colors] section, same keys).

Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$script:Theme = @{
    colors = @{
        ink        = '1d2229'   # background
        ink_panel  = '252b34'   # fields, header band
        ink_raised = '363d4a'   # secondary button
        ink_line   = '414957'   # separators, borders
        sand       = 'e0e0e0'   # text
        sand_dim   = '8b929c'   # secondary text
        accent     = '70bbfa'   # the one thing you press
        good       = '45d17c'
        bad        = 'ff786b'
        info       = 'a5b6cc'
    }
    font_ui      = @('Bahnschrift', 'Segoe UI')
    font_title   = @('Bahnschrift SemiBold SemiConden', 'Bahnschrift', 'Segoe UI Semibold')
    font_mono    = @('JetBrains Mono', 'Cascadia Mono', 'Consolas')
    size_text    = 10
    size_title   = 17
    size_small   = 9
}

function Import-DesignTokens {
    $path = Join-Path $script:Root 'design_tokens.cfg'
    if (-not (Test-Path $path)) { return }
    $section = ''
    foreach ($line in [IO.File]::ReadAllLines($path)) {
        if ($line -match '^\[(\w+)\]') { $section = $Matches[1]; continue }
        if ($section -eq 'colors' -and $line -match '^(\w+)\s*=\s*"?([0-9a-fA-F]{6})"?') {
            if ($script:Theme.colors.ContainsKey($Matches[1])) { $script:Theme.colors[$Matches[1]] = $Matches[2] }
        }
    }
}

function C([string]$name, [int]$alpha = 255) {
    $hex = $script:Theme.colors[$name]
    return [Drawing.Color]::FromArgb($alpha, [Convert]::ToInt32($hex.Substring(0, 2), 16),
        [Convert]::ToInt32($hex.Substring(2, 2), 16), [Convert]::ToInt32($hex.Substring(4, 2), 16))
}

function New-ThemeFont([string[]]$families, [float]$size, [Drawing.FontStyle]$style = 'Regular') {
    $installed = (New-Object Drawing.Text.InstalledFontCollection).Families.Name
    $name = $families | Where-Object { $installed -contains $_ } | Select-Object -First 1
    if (-not $name) { $name = 'Segoe UI' }
    return New-Object Drawing.Font($name, $size, $style)
}

Import-DesignTokens
$script:Fonts = @{
    ui    = New-ThemeFont $script:Theme.font_ui $script:Theme.size_text
    title = New-ThemeFont $script:Theme.font_title $script:Theme.size_title
    small = New-ThemeFont $script:Theme.font_ui $script:Theme.size_small
    mono  = New-ThemeFont $script:Theme.font_mono $script:Theme.size_small
    label = New-ThemeFont $script:Theme.font_title $script:Theme.size_small
}

# The window: header (title, project, state), body (remote, identity, log),
# footer (language, Close, Update project).

. (Join-Path $PSScriptRoot 'widgets.ps1')

$script:Layout = @{ width = 760; height = 600; header = 92; footer = 66; pad = 24 }

Add-Type -Namespace Updater -Name Dpi -MemberDefinition '[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();'

function Get-StateText {
    if (-not (Test-Repo)) { return T 'state_none' }
    $branch = Get-CurrentBranch
    if ($branch) { return T 'state_repo' $branch }
    return T 'state_detached'
}

function Show-UpdaterWindow {
    [Updater.Dpi]::SetProcessDPIAware() | Out-Null
    [Windows.Forms.Application]::EnableVisualStyles()
    $L = $script:Layout; $p = $L.pad; $inner = $L.width - 2 * $p

    $form = New-Object Windows.Forms.Form
    $form.SuspendLayout()
    $form.AutoScaleDimensions = New-Object Drawing.SizeF(96, 96)
    $form.AutoScaleMode = 'Dpi'
    $form.ClientSize = New-Object Drawing.Size($L.width, $L.height)
    $form.FormBorderStyle = 'FixedSingle'; $form.MaximizeBox = $false
    $form.StartPosition = 'CenterScreen'; $form.BackColor = C 'ink'
    $form.Font = $script:Fonts.ui
    $form.GetType().GetProperty('DoubleBuffered', [Reflection.BindingFlags]'NonPublic,Instance').SetValue($form, $true)
    $form.Add_Paint({ param($s, $e) Draw-Background $s $e })
    $tips = New-Object Windows.Forms.ToolTip
    $tips.AutoPopDelay = 15000

    # Header
    $title = New-Label '' $p 16 $script:Fonts.title
    $path = New-Label $script:Root ($p + 2) 54 $script:Fonts.mono 'sand_dim'
    $path.AutoSize = $false; $path.AutoEllipsis = $true
    $path.SetBounds($p + 2, 54, $inner - 2, 20)
    $state = New-Label '' 0 24 $script:Fonts.small 'info'
    $state.AutoSize = $false; $state.TextAlign = 'MiddleRight'
    $state.SetBounds($L.width - $p - 360, 22, 360, 22)

    # Body
    $y = $L.header + 18
    $lblRemote = New-Label '' $p $y $script:Fonts.label 'sand_dim'
    $remote = New-Field $p ($y + 20) $inner
    $remote.Text = Get-RemoteUrl
    $remote.ReadOnly = [bool](Get-Origin)
    $y += 64
    $half = [int](($inner - 16) / 2)
    $lblName = New-Label '' $p $y $script:Fonts.label 'sand_dim'
    $lblEmail = New-Label '' ($p + $half + 16) $y $script:Fonts.label 'sand_dim'
    $name = New-Field $p ($y + 20) $half
    $email = New-Field ($p + $half + 16) ($y + 20) $half
    $id = if ($script:Git) { Get-Identity } else { @{ name = ''; email = '' } }
    $name.Text = $id.name; $email.Text = $id.email
    $y += 68

    $frame = New-Object Windows.Forms.Panel
    $frame.SetBounds($p, $y, $inner, $L.height - $L.footer - $y - 18)
    $frame.BackColor = C 'ink_line'; $frame.Padding = New-Object Windows.Forms.Padding(1)
    $log = New-Object Windows.Forms.RichTextBox
    $log.Dock = 'Fill'; $log.ReadOnly = $true; $log.BorderStyle = 'None'
    $log.BackColor = [Drawing.Color]::FromArgb(255, 22, 26, 32); $log.ForeColor = C 'sand_dim'
    $log.Font = $script:Fonts.mono; $log.DetectUrls = $false
    $frame.Controls.Add($log)

    # Footer
    $fy = $L.height - $L.footer + 16
    $lblLang = New-Label '' $p ($fy + 8) $script:Fonts.small 'sand_dim'
    # One small toggle per language; the selected one gets the accent border.
    $langButtons = @()
    $lx = $p + 80
    foreach ($code in $script:LanguageNames.Keys) {
        $b = New-Button $code.ToUpper() $lx ($fy + 3) 44 $false
        $b.Height = 28; $b.Font = $script:Fonts.small; $b.Tag = $code
        $tips.SetToolTip($b, $script:LanguageNames[$code])
        $b.Add_Click({
                param($sender)
                $script:Lang = $sender.Tag
                $script:Config.language = $script:Lang
                Save-UpdaterConfig
                & $applyTexts
            })
        $langButtons += $b; $lx += 48
    }
    $btnUpdate = New-Button '' ($L.width - $p - 170) $fy 170 $true
    $btnClose = New-Button '' ($L.width - $p - 170 - 12 - 110) $fy 110 $false
    $form.AcceptButton = $btnUpdate; $form.CancelButton = $btnClose

    $form.Controls.AddRange(@($title, $path, $state, $lblRemote, $remote, $lblName, $lblEmail,
            $name, $email, $frame, $lblLang, $btnClose, $btnUpdate) + $langButtons)
    $form.ActiveControl = if ($remote.Text) { $btnUpdate } else { $remote }

    $script:Log = { param($kind, $text) Write-LogLine $log $kind $text }
    $applyTexts = {
        $form.Text = T 'title'; $title.Text = T 'title'
        $state.Text = if ($script:Git) { Get-StateText } else { T 'err_no_git' }
        $state.ForeColor = if ($script:Git) { C 'info' } else { C 'bad' }
        $lblRemote.Text = (T 'lbl_remote').ToUpper()
        $lblName.Text = (T 'lbl_name').ToUpper(); $lblEmail.Text = (T 'lbl_email').ToUpper()
        $lblLang.Text = T 'lbl_language'
        $btnUpdate.Text = T 'btn_update'; $btnClose.Text = T 'btn_close'
        $tips.SetToolTip($remote, (T 'tip_remote')); $tips.SetToolTip($lblRemote, (T 'tip_remote'))
        foreach ($c in @($name, $email, $lblName, $lblEmail)) { $tips.SetToolTip($c, (T 'tip_identity')) }
        $tips.SetToolTip($btnUpdate, (T 'tip_update')); $tips.SetToolTip($path, (T 'subtitle'))
        if (-not $script:Ran) {
            $log.Clear()
            if ($script:UpdatedTo) { Write-LogLine $log 'good' (T 'msg_tool_updated' $script:UpdatedTo) }
            $log.AppendText((T 'log_empty'))
        }
        foreach ($b in $langButtons) {
            $on = $b.Tag -eq $script:Lang
            $b.FlatAppearance.BorderColor = if ($on) { C 'accent' } else { C 'ink_line' }
            $b.ForeColor = if ($on) { C 'sand' } else { C 'sand_dim' }
        }
    }
    & $applyTexts

    $btnClose.Add_Click({ $form.Close() })
    $btnUpdate.Add_Click({
            if (-not $script:Git) { return }
            $script:Ran = $true; $log.Clear()
            $btnUpdate.Enabled = $false; $btnUpdate.BackColor = C 'ink_line'
            $form.Cursor = 'WaitCursor'
            $script:Pump = { [Windows.Forms.Application]::DoEvents() }
            try {
                Set-Identity $name.Text.Trim() $email.Text.Trim()
                $script:Config.remote_url = $remote.Text.Trim()
                $ok = Update-Project $script:Config.remote_url
                $state.Text = Get-StateText
                $state.ForeColor = if ($ok) { C 'good' } else { C 'bad' }
                $remote.Text = Get-RemoteUrl; $remote.ReadOnly = [bool](Get-Origin)
            } catch {
                & $script:Log 'bad' (T 'msg_failed' $_.Exception.Message)
            } finally {
                $script:Pump = $null; $form.Cursor = 'Default'
                $btnUpdate.Enabled = $true; $btnUpdate.BackColor = C 'accent'
            }
        })

    $form.ResumeLayout()
    [void]$form.ShowDialog()
}

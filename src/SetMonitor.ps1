




function Get-Monitors {
    [CmdletBinding(SupportsShouldProcess)]
    param()


    $CsCode = @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

    public struct RECT
    {
        public int Left, Top, Right, Bottom;
    }
}
"@

    Register-Assemblies
    
    if([Win32] -as [type]){
        Write-Host "already registered"
    }else{
        Add-Type $CsCode
    }
    
    # Get all screens, pick the second one
    $screens = [System.Windows.Forms.Screen]::AllScreens
    $i = 0
    Write-Host "$($screens.Count) Monitors Detected" -f DarkCyan
    ForEach($s in $screens){
        Write-Host "  $i) $($s.WorkingArea.Size.Width)x$($s.WorkingArea.Size.Height)" -f MAgenta -n
        Write-Host "  Set-TerminalMonitor $i" -f DarkGray
        $i++
    }
}



function Set-TerminalMonitor {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateRange(0, 1)]
        [int]$Id = 1
    )


    $CsCode = @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

    public struct RECT
    {
        public int Left, Top, Right, Bottom;
    }
}
"@

    Register-Assemblies
    
    if([Win32] -as [type]){
        Write-Host "already registered"
    }else{
        Add-Type $CsCode
    }
    
    # Get all screens, pick the second one
    $screens = [System.Windows.Forms.Screen]::AllScreens
    if ($screens.Count -lt 2) { return }
    $targetScreen = $screens[$Id] # 0=primary, 1=second

    Start-Sleep -Milliseconds 500 # Wait for window to fully initialize

    $hwnd = [Win32]::GetForegroundWindow()
    $rect = New-Object Win32+RECT
    [Win32]::GetWindowRect($hwnd, [ref]$rect) | Out-Null
    $width = $rect.Right - $rect.Left
    $height = $rect.Bottom - $rect.Top

    # Move to second monitor (top-left corner)
    [Win32]::SetWindowPos($hwnd, [IntPtr]::Zero, $targetScreen.WorkingArea.Left, $targetScreen.WorkingArea.Top, $width, $height, 0)
}

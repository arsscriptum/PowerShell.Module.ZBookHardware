#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   MsgBox.ps1                                                                   ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝



#===============================================================================
# Profile VARIABLES
#===============================================================================

function Register-ScriptAssemblies {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $WindowsAssemblyReferences = [System.Collections.ArrayList]::new()
    [void]$WindowsAssemblyReferences.Add('System')
    [void]$WindowsAssemblyReferences.Add('System.Drawing')
    [void]$WindowsAssemblyReferences.Add('System.Xml')
    [void]$WindowsAssemblyReferences.Add('WindowsBase')
    [void]$WindowsAssemblyReferences.Add('System.Windows.Forms')
    [void]$WindowsAssemblyReferences.Add('PresentationFramework')
    [void]$WindowsAssemblyReferences.Add('PresentationCore')
    Write-Verbose "================================================================="
    Write-Verbose "MESSAGEBOX INIT ==> Register-ScriptAssemblies "
    Write-Verbose "================================================================="

    try {
        foreach ($Ref in $WindowsAssemblyReferences) {
            Write-Verbose " [Add-Type -AssemblyName]  ==>  $Ref "
            Add-Type -AssemblyName $Ref
        }
    } catch {
        Write-Warning "[ERRIR with Assembly]  ==>  $Ref "
    }
}

function Get-ScriptDirectory { # NOEXPORT
    [CmdletBinding(SupportsShouldProcess)]
    param()
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    if ($Invocation.PSScriptRoot) {
        $Invocation.PSScriptRoot
    }
    elseif ($Invocation.MyCommand.Path) {
        Split-Path $Invocation.MyCommand.Path
    } else {
        $Invocation.InvocationName.Substring(0, $Invocation.InvocationName.LastIndexOf(""))
    }
}



function Show-UserInfo {
    Add-Type -AssemblyName System.Windows.Forms

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "USER INFO"
    $form.Size = New-Object System.Drawing.Size (250, 220)
    $form.StartPosition = "CenterScreen"
    $form.TopMost = $True
    $form.Add_Shown({ $form.Activate() })

    $okButton = New-Object System.Windows.Forms.Button
    $form.Controls.Add($okButton)
    $listButton = New-Object System.Windows.Forms.Button
    $form.Controls.Add($listButton)
    $okButton.Location = New-Object System.Drawing.Size (120, 120)
    $okButton.Size = New-Object System.Drawing.Size (80, 23)
    $okButton.Text = "Submit"
    $okButton.add_Click({
            if ($($textbox.Text)) {
                $t = $($textbox.Text)
                $Data = & 'net' 'user' "$t"
                if ($Data) {
                    [System.Windows.MessageBox]::Show($Data, 'SUCCESS', 'Ok', 'Information')
                } else {
                    [System.Windows.MessageBox]::Show('User ID could not be found', 'Error', 'Ok', 'Error')
                }
            }
        })

    $listButton.Location = New-Object System.Drawing.Size (30, 120)
    $listButton.Size = New-Object System.Drawing.Size (80, 23)
    $listButton.Text = "List"
    $listButton.add_Click({
            $Data = & 'net' 'user'
            if ($Data) {
                [System.Windows.MessageBox]::Show($Data, 'SUCCESS', 'Ok', 'Information')
            } else {
                [System.Windows.MessageBox]::Show('CANNOT LIST USERS', 'Error', 'Ok', 'Error')
            }
        })



    $label = New-Object System.Windows.Forms.Label
    $form.Controls.Add($label)
    $label.Location = New-Object System.Drawing.Size (30, 20)
    $label.Size = New-Object System.Drawing.Size (250, 20)
    $label.Text = "Please enter the user id:"

    $textbox = New-Object System.Windows.Forms.TextBox
    $form.Controls.Add($textbox)
    $textbox.Location = New-Object System.Drawing.Size (40, 40)
    $textbox.Size = New-Object System.Drawing.Size (150, 20)

    #THE FOLLOWING CODE NEEDS TO BE IN AN EVENT
    $User = try {
        "$($textbox.Text)"
    }
    catch {
        throw $_
    }

    $form.ShowDialog()
}

function Get-MessageBoxResult {
    $Result = Get-Variable -Name PWSHMessageBoxOutput -ValueOnly -ErrorAction Ignore
    return $Result
}


function Show-Popup {
    # Define Parameters
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        # The popup Content
        [Parameter(Mandatory = $True)]
        [string]$Title,
        [Parameter(Mandatory = $True)]
        [string]$Message,
        [Parameter(Mandatory = $False)]
        [ValidateSet('OK', 'OKCancel', 'AbortRetryIgnore', 'YesNoCancel', 'YesNo', 'RetryCancel')]
        [string]$Type = "OK",
        [Parameter(Mandatory = $False)]
        [ValidateSet('None', 'Hand', 'Error', 'Stop', 'Question', 'Exclamation', 'Warning', 'Asterisk', 'Information')]
        [string]$Icon = "None",
        [ValidateSet('Button1', 'Button2', 'Button3')]
        [string]$DefaultButton = "Button1",
        [ValidateSet('DefaultDesktopOnly', 'RightAlign', 'RtlReading', 'ServiceNotification')]
        [string]$Option = "DefaultDesktopOnly"


    )
    $Null = [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    return [Windows.Forms.MessageBox]::Show($Message, $Title, $Type, $Icon, $DefaultButton, $Option)
}

function Show-SimpleMessageBox {

    [CmdletBinding()]
    param
    ([Parameter(Mandatory = $True, Position = 0)] [Object]$Content,
        [Parameter(Mandatory = $false, Position = 1)] [string]$Title,
        [Parameter(Mandatory = $false, Position = 2)][ValidateSet('OK', 'OK-Cancel', 'Abort-Retry-Ignore', 'Yes-No-Cancel', 'Yes-No', 'Retry-Cancel', 'Cancel-Continue', 'Cancel-TryAgain-Continue', 'None')] [array]$ButtonType = 'OK',
        [Parameter(Mandatory = $false, Position = 3)] [array]$CustomButtons,
        [Parameter(Mandatory = $false, Position = 4)] [int]$ContentFontSize = 14,
        [Parameter(Mandatory = $false, Position = 5)] [int]$TitleFontSize = 14,
        [Parameter(Mandatory = $false, Position = 6)] [int]$BorderThickness = 0,
        [Parameter(Mandatory = $false, Position = 7)] [int]$CornerRadius = 8,
        [Parameter(Mandatory = $false, Position = 8)] [int]$ShadowDepth = 3,
        [Parameter(Mandatory = $false, Position = 9)] [int]$BlurRadius = 20,
        [Parameter(Mandatory = $false, Position = 10)] [object]$WindowHost,
        [Parameter(Mandatory = $false, Position = 11)] [int]$Timeout,
        [Parameter(Mandatory = $false, Position = 12)] [scriptblock]$OnLoaded,
        [Parameter(Mandatory = $false, Position = 13)] [scriptblock]$OnClosed
    )


    dynamicparam { Add-Type -AssemblyName System.Drawing, PresentationCore
        $ContentBackground = 'ContentBackground'; $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]; $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute; $ParameterAttribute.Mandatory = $False; $AttributeCollection.Add($ParameterAttribute); $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary; $arrSet = [System.Drawing.Brushes] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name; $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute ($arrSet); $AttributeCollection.Add($ValidateSetAttribute); $PSBoundParameters.ContentBackground = "White"; $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter ($ContentBackground, [string], $AttributeCollection); $RuntimeParameterDictionary.Add($ContentBackground, $RuntimeParameter); $FontFamily = 'FontFamily'; $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]; $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute; $ParameterAttribute.Mandatory = $False; $AttributeCollection.Add($ParameterAttribute); $arrSet = [System.Drawing.FontFamily]::Families.Name | Select -Skip 1; $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute ($arrSet); $AttributeCollection.Add($ValidateSetAttribute); $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter ($FontFamily, [string], $AttributeCollection); $RuntimeParameterDictionary.Add($FontFamily, $RuntimeParameter); $PSBoundParameters.FontFamily = "Segoe UI"; $TitleFontWeight = 'TitleFontWeight'; $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]; $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute; $ParameterAttribute.Mandatory = $False; $AttributeCollection.Add($ParameterAttribute); $arrSet = [System.Windows.FontWeights] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name; $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute ($arrSet); $AttributeCollection.Add($ValidateSetAttribute); $PSBoundParameters.TitleFontWeight = "Normal"; $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter ($TitleFontWeight, [string], $AttributeCollection); $RuntimeParameterDictionary.Add($TitleFontWeight, $RuntimeParameter); $ContentFontWeight = 'ContentFontWeight'; $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]; $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute; $ParameterAttribute.Mandatory = $False; $AttributeCollection.Add($ParameterAttribute); $arrSet = [System.Windows.FontWeights] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name; $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute ($arrSet); $AttributeCollection.Add($ValidateSetAttribute); $PSBoundParameters.ContentFontWeight = "Normal"; $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter ($ContentFontWeight, [string], $AttributeCollection); $RuntimeParameterDictionary.Add($ContentFontWeight, $RuntimeParameter); $ContentTextForeground = 'ContentTextForeground'; $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]; $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute; $ParameterAttribute.Mandatory = $False; $AttributeCollection.Add($ParameterAttribute); $arrSet = [System.Drawing.Brushes] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name; $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute ($arrSet); $AttributeCollection.Add($ValidateSetAttribute); $PSBoundParameters.ContentTextForeground = "Black"; $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter ($ContentTextForeground, [string], $AttributeCollection); $RuntimeParameterDictionary.Add($ContentTextForeground, $RuntimeParameter); $TitleTextForeground = 'TitleTextForeground'; $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]; $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute; $ParameterAttribute.Mandatory = $False; $AttributeCollection.Add($ParameterAttribute); $arrSet = [System.Drawing.Brushes] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name; $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute ($arrSet); $AttributeCollection.Add($ValidateSetAttribute); $PSBoundParameters.TitleTextForeground = "Black"; $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter ($TitleTextForeground, [string], $AttributeCollection); $RuntimeParameterDictionary.Add($TitleTextForeground, $RuntimeParameter); $BorderBrush = 'BorderBrush'; $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]; $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute; $ParameterAttribute.Mandatory = $False; $AttributeCollection.Add($ParameterAttribute); $arrSet = [System.Drawing.Brushes] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name; $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute ($arrSet); $AttributeCollection.Add($ValidateSetAttribute); $PSBoundParameters.BorderBrush = "Black"; $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter ($BorderBrush, [string], $AttributeCollection); $RuntimeParameterDictionary.Add($BorderBrush, $RuntimeParameter); $TitleBackground = 'TitleBackground'; $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]; $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute; $ParameterAttribute.Mandatory = $False; $AttributeCollection.Add($ParameterAttribute); $arrSet = [System.Drawing.Brushes] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name; $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute ($arrSet); $AttributeCollection.Add($ValidateSetAttribute); $PSBoundParameters.TitleBackground = "White"; $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter ($TitleBackground, [string], $AttributeCollection); $RuntimeParameterDictionary.Add($TitleBackground, $RuntimeParameter); $ButtonTextForeground = 'ButtonTextForeground'; $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]; $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute; $ParameterAttribute.Mandatory = $False; $AttributeCollection.Add($ParameterAttribute); $arrSet = [System.Drawing.Brushes] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name; $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute ($arrSet); $AttributeCollection.Add($ValidateSetAttribute); $PSBoundParameters.ButtonTextForeground = "Black"; $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter ($ButtonTextForeground, [string], $AttributeCollection); $RuntimeParameterDictionary.Add($ButtonTextForeground, $RuntimeParameter); return $RuntimeParameterDictionary }; begin { Add-Type -AssemblyName PresentationFramework }; process {


        Write-Host "Add-Type PresentationFramework" -f DarkYellow
        Write-Host "Add-Type PresentationCore" -f DarkYellow
        Write-Host "Add-Type WindowsBase" -f DarkYellow
        Write-Host "Add-Type System.Windows.Forms" -f DarkYellow
        Write-Host "Add-Type System.Drawing" -f DarkYellow
        Write-Host "Add-Type System" -f DarkYellow
        Write-Host "Add-Type System.Xml" -f DarkYellow
        Write-Host "Add-Type System.Windows" -f DarkYellow
        Add-Type -AssemblyName PresentationFramework
        Add-Type -AssemblyName PresentationCore
        Add-Type -AssemblyName WindowsBase
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        Add-Type -AssemblyName System
        Add-Type -AssemblyName System.Xml
        Add-Type -AssemblyName System.Windows


        # Define the XAML markup
        [xml]$Xaml = @"
<Window 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        x:Name="Window" Title="" SizeToContent="WidthAndHeight" WindowStartupLocation="CenterScreen" WindowStyle="None" ResizeMode="NoResize" AllowsTransparency="True" Background="Transparent" Opacity="1">
    <Window.Resources>
        <Style TargetType="{x:Type Button}">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border>
                            <Grid Background="{TemplateBinding Background}">
                                <ContentPresenter />
                            </Grid>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>
    <Border x:Name="MainBorder" Margin="10" CornerRadius="$CornerRadius" BorderThickness="$BorderThickness" BorderBrush="$($PSBoundParameters.BorderBrush)" Padding="0" >
        <Border.Effect>
            <DropShadowEffect x:Name="DSE" Color="Black" Direction="270" BlurRadius="$BlurRadius" ShadowDepth="$ShadowDepth" Opacity="0.6" />
        </Border.Effect>
        <Border.Triggers>
            <EventTrigger RoutedEvent="Window.Loaded">
                <BeginStoryboard>
                    <Storyboard>
                        <DoubleAnimation Storyboard.TargetName="DSE" Storyboard.TargetProperty="ShadowDepth" From="0" To="$ShadowDepth" Duration="0:0:1" AutoReverse="False" />
                        <DoubleAnimation Storyboard.TargetName="DSE" Storyboard.TargetProperty="BlurRadius" From="0" To="$BlurRadius" Duration="0:0:1" AutoReverse="False" />
                    </Storyboard>
                </BeginStoryboard>
            </EventTrigger>
        </Border.Triggers>
        <Grid >
            <Border Name="Mask" CornerRadius="$CornerRadius" Background="$($PSBoundParameters.ContentBackground)" />
            <Grid x:Name="Grid" Background="$($PSBoundParameters.ContentBackground)">
                <Grid.OpacityMask>
                    <VisualBrush Visual="{Binding ElementName=Mask}"/>
                </Grid.OpacityMask>
                <StackPanel Name="StackPanel" >                   
                    <TextBox Name="TitleBar" IsReadOnly="True" IsHitTestVisible="False" Text="$Title" Padding="10" FontFamily="$($PSBoundParameters.FontFamily)" FontSize="$TitleFontSize" Foreground="$($PSBoundParameters.TitleTextForeground)" FontWeight="$($PSBoundParameters.TitleFontWeight)" Background="$($PSBoundParameters.TitleBackground)" HorizontalAlignment="Stretch" VerticalAlignment="Center" Width="Auto" HorizontalContentAlignment="Center" BorderThickness="0" TextWrapping="Wrap" AcceptsReturn="True" />
                    <DockPanel Name="ContentHost" Margin="0,10,0,10"  >
                    </DockPanel>
                    <DockPanel Name="ButtonHost" LastChildFill="False" HorizontalAlignment="Center" >
                    </DockPanel>
                </StackPanel>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

        [xml]$ButtonXaml = @"
<Button xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Width="Auto" Height="30" FontFamily="Segui" FontSize="16" Background="Transparent" Foreground="White" BorderThickness="1" Margin="10" Padding="20,0,20,0" HorizontalAlignment="Right" Cursor="Hand"/>
"@

        [xml]$ButtonTextXaml = @"
<TextBlock xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" FontFamily="$($PSBoundParameters.FontFamily)" FontSize="16" Background="Transparent" Foreground="$($PSBoundParameters.ButtonTextForeground)" Padding="20,5,20,5" HorizontalAlignment="Center" VerticalAlignment="Center"/>
"@

        [xml]$ContentTextXaml = @"
<TextBlock xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" TextWrapping="WrapWithOverflow" Foreground="$($PSBoundParameters.ContentTextForeground)" DockPanel.Dock="Right" HorizontalAlignment="Center" VerticalAlignment="Center" FontFamily="$($PSBoundParameters.FontFamily)" FontSize="$ContentFontSize" FontWeight="$($PSBoundParameters.ContentFontWeight)" Height="Auto" MaxWidth="400" MinWidth="350" Padding="10">$Content</TextBlock>
"@



        $Window = [Windows.Markup.XamlReader]::Load((New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $xaml)); function Add-Button { param($Content); $Button = [Windows.Markup.XamlReader]::Load((New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $ButtonXaml)); $ButtonText = [Windows.Markup.XamlReader]::Load((New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $ButtonTextXaml)); $ButtonText.Text = "$Content"; $Button.Content = $ButtonText; $Button.Add_MouseEnter({; $This.Content.FontSize = "17"; }); $Button.Add_MouseLeave({; $This.Content.FontSize = "16"; }); $Button.add_Click({; New-Variable -Name WPFMessageBoxOutput -Value $($This.Content.Text) -Option ReadOnly -Scope global -Force; $Window.Close(); }); $Window.FindName('ButtonHost').AddChild($Button) }; if ($ButtonType -eq "None" -and $CustomButtons) { foreach ($CustomButton in $CustomButtons) { Add-Button -Content "$CustomButton" } }; if ($Content -is [string]) { if ($Content -match '"') { $Content = $Content.Replace('"', "'"); }; $ContentTextBox = [Windows.Markup.XamlReader]::Load((New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $ContentTextXaml)); $Window.FindName('ContentHost').AddChild($ContentTextBox) } else { try { $Window.FindName('ContentHost').AddChild($Content); } catch { $_; } }; $Window.FindName('Grid').Add_MouseLeftButtonDown({; $Window.DragMove() }); if ($OnLoaded) { $Window.Add_Loaded({ $This.Activate(); Invoke-Command $OnLoaded; }) } else { $Window.Add_Loaded({ $This.Activate() }) }; if ($WindowHost) {; $Window.Owner = $WindowHost; $Window.WindowStartupLocation = "CenterOwner"; }; $null = $window.Dispatcher.InvokeAsync{ $window.ShowDialog() }.Wait()
    }
}

function Test-SimpleMsgBox {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $false)] [int]$ContentFontSize = 14,
        [Parameter(Mandatory = $false)] [int]$TitleFontSize = 14,
        [Parameter(Mandatory = $false)] [int]$BorderThickness = 0,
        [Parameter(Mandatory = $false)] [int]$CornerRadius = 8,
        [Parameter(Mandatory = $false)] [int]$ShadowDepth = 3,
        [Parameter(Mandatory = $false)] [int]$BlurRadius = 20
    )

    $s = "`$Params = @{
        Content = `"`"
        Title = `"Are you on a public or private PC?`"
        TitleFontSize = 20
        TitleBackground = 'Green'
        TitleTextForeground = 'White'
        ButtonType = 'None'
        CornerRadius = $CornerRadius
        ShadowDepth = $ShadowDepth
        CustomButtons = `"PUBLIC`",`"PRIVATE`", `"EXIT`"

    };
    Show-SimpleMessageBox `@Params"
    $sb = [scriptblock]::Create($s)
    Invoke-Command -ScriptBlock $sb
}
function Test-SimpleMsgBox2 {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $True, Position = 0)] [string]$Title,
        [Parameter(Mandatory = $false)] [int]$ContentFontSize = 24,
        [Parameter(Mandatory = $false)] [int]$TitleFontSize = 42,
        [Parameter(Mandatory = $false)] [int]$BorderThickness = 0,
        [Parameter(Mandatory = $false)] [int]$CornerRadius = 20,
        [Parameter(Mandatory = $false)] [int]$ShadowDepth = 3,
        [Parameter(Mandatory = $false)] [int]$BlurRadius = 20

    )

    $s = "`$Params = @{
        Content = `"`"
        Title = `"$Title`"
        TitleFontSize = $TitleFontSize
        TitleBackground = 'Red'
        TitleTextForeground = 'White'
        ButtonType = 'None'
        CustomButtons = `"OK`",`"CANCEL`"
        CornerRadius = $CornerRadius
        ShadowDepth = $ShadowDepth

    };
    Show-SimpleMessageBox `@Params -Content 'test'"
    $sb = [scriptblock]::Create($s)
    Invoke-Command -ScriptBlock $sb
}

function Show-MessageBox {
    # Define Parameters
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        # The popup Content
        [Parameter(Mandatory = $True)]
        [Object]$Content,

        # The window title
        [Parameter(Mandatory = $false)]
        [string]$Title,

        # The buttons to add
        [Parameter(Mandatory = $false)]
        [ValidateSet('OK', 'OK-Cancel', 'Abort-Retry-Ignore', 'Yes-No-Cancel', 'Yes-No', 'Retry-Cancel', 'Cancel-Continue', 'Cancel-TryAgain-Continue', 'None')]
        [array]$ButtonType = 'OK',

        # The buttons to add
        [Parameter(Mandatory = $false)]
        [array]$CustomButtons,

        # Content font size
        [Parameter(Mandatory = $false)]
        [int]$ContentFontSize = 14,

        # Title font size
        [Parameter(Mandatory = $false)]
        [int]$TitleFontSize = 14,

        # BorderThickness
        [Parameter(Mandatory = $false)]
        [int]$BorderThickness = 0,

        # CornerRadius
        [Parameter(Mandatory = $false)]
        [int]$CornerRadius = 8,

        # ShadowDepth
        [Parameter(Mandatory = $false)]
        [int]$ShadowDepth = 3,

        # BlurRadius
        [Parameter(Mandatory = $false)]
        [int]$BlurRadius = 20,


        # BlurRadius
        [Parameter(Mandatory = $false)]
        [int]$WindowWidth = 0,
        # WindowHost
        [Parameter(Mandatory = $false)]
        [object]$WindowHost,

        # Timeout in seconds,
        [Parameter(Mandatory = $false)]
        [int]$Timeout,
        [Parameter(Mandatory = $false)]
        [ValidateSet('center', 'left', 'right', 'stretch')]
        [Object]$TitleAlign = 'center',
        [Parameter(Mandatory = $false)]
        [ValidateSet('center', 'left', 'right', 'stretch')]
        [Object]$ContentAlign = 'center',
        # Code for Window Loaded event,
        [Parameter(Mandatory = $false)]
        [scriptblock]$OnLoaded,

        # Code for Window Closed event,
        [Parameter(Mandatory = $false)]
        [scriptblock]$OnClosed

    )


    # Dynamically Populated parameters
    dynamicparam {

        # ContentBackground
        $ContentBackground = 'ContentBackground'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute)
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $arrSet = [System.Drawing.Brushes] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute ($arrSet)
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.ContentBackground = "White"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter ($ContentBackground, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ContentBackground, $RuntimeParameter)


        # FontFamily
        $FontFamily = 'FontFamily'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute)
        $arrSet = [System.Drawing.FontFamily]::Families.Name | Select -Skip 1
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute ($arrSet)
        $AttributeCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter ($FontFamily, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($FontFamily, $RuntimeParameter)
        $PSBoundParameters.FontFamily = "Consolas"

        # TitleFontWeight
        $TitleFontWeight = 'TitleFontWeight'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute)
        $arrSet = [System.Windows.FontWeights] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute ($arrSet)
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.TitleFontWeight = "Normal"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter ($TitleFontWeight, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($TitleFontWeight, $RuntimeParameter)

        # ContentFontWeight
        $ContentFontWeight = 'ContentFontWeight'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute)
        $arrSet = [System.Windows.FontWeights] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute ($arrSet)
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.ContentFontWeight = "Normal"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter ($ContentFontWeight, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ContentFontWeight, $RuntimeParameter)


        # ContentTextForeground
        $ContentTextForeground = 'ContentTextForeground'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute)
        $arrSet = [System.Drawing.Brushes] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute ($arrSet)
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.ContentTextForeground = "Black"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter ($ContentTextForeground, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ContentTextForeground, $RuntimeParameter)

        # TitleTextForeground
        $TitleTextForeground = 'TitleTextForeground'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute)
        $arrSet = [System.Drawing.Brushes] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute ($arrSet)
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.TitleTextForeground = "Black"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter ($TitleTextForeground, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($TitleTextForeground, $RuntimeParameter)

        # BorderBrush
        $BorderBrush = 'BorderBrush'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute)
        $arrSet = [System.Drawing.Brushes] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute ($arrSet)
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.BorderBrush = "Black"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter ($BorderBrush, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($BorderBrush, $RuntimeParameter)


        # TitleBackground
        $TitleBackground = 'TitleBackground'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute)
        $arrSet = [System.Drawing.Brushes] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute ($arrSet)
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.TitleBackground = "White"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter ($TitleBackground, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($TitleBackground, $RuntimeParameter)

        # ButtonTextForeground
        $ButtonTextForeground = 'ButtonTextForeground'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute)
        $arrSet = [System.Drawing.Brushes] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute ($arrSet)
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.ButtonTextForeground = "Black"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter ($ButtonTextForeground, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ButtonTextForeground, $RuntimeParameter)

        #$ButtonTextBackground = 'ButtonTextBackground'
        #$AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        #$ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        #$ParameterAttribute.Mandatory = $False
        #$AttributeCollection.Add($ParameterAttribute) 
        #$arrSet = [System.Drawing.Brushes] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name 
        #$ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        #$AttributeCollection.Add($ValidateSetAttribute)
        #$PSBoundParameters.ButtonTextBackground = "White"
        #$RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ButtonTextBackground, [string], $AttributeCollection)
        #$RuntimeParameterDictionary.Add($ButtonTextBackground, $RuntimeParameter)


        # Sound
        $Sound = 'Sound'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        #$ParameterAttribute.Position = 14
        $AttributeCollection.Add($ParameterAttribute)
        $arrSet = (Get-ChildItem "$env:SystemDrive\Windows\Media" -Filter Windows* | Select -ExpandProperty Name).Replace('.wav', '')
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute ($arrSet)
        $AttributeCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter ($Sound, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($Sound, $RuntimeParameter)

        return $RuntimeParameterDictionary
    }

    begin {
        Register-ScriptAssemblies
    }

    process {
        $WidthDefine = ""
        if ($WindowWidth -gt 0) {
            $WidthDefine = "Width=`"$WindowWidth`""
        }


        # Define the XAML markup

        [string]$XamlString = @"
<Window 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        x:Name="Window" Title="" SizeToContent="WidthAndHeight" WindowStartupLocation="CenterScreen" WindowStyle="None" ResizeMode="NoResize" AllowsTransparency="True" Background="Transparent" Opacity="1" $WidthDefine>
    <Window.Resources>
        <Style TargetType="{x:Type Button}">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border>
                            <Grid Background="{TemplateBinding Background}">
                                <ContentPresenter />
                            </Grid>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>
    <Border x:Name="MainBorder" Margin="10" CornerRadius="$CornerRadius" BorderThickness="$BorderThickness" BorderBrush="$($PSBoundParameters.BorderBrush)" Padding="0" >
        <Border.Effect>
            <DropShadowEffect x:Name="DSE" Color="Black" Direction="270" BlurRadius="$BlurRadius" ShadowDepth="$ShadowDepth" Opacity="0.6" />
        </Border.Effect>
        <Border.Triggers>
            <EventTrigger RoutedEvent="Window.Loaded">
                <BeginStoryboard>
                    <Storyboard>
                        <DoubleAnimation Storyboard.TargetName="DSE" Storyboard.TargetProperty="ShadowDepth" From="0" To="$ShadowDepth" Duration="0:0:1" AutoReverse="False" />
                        <DoubleAnimation Storyboard.TargetName="DSE" Storyboard.TargetProperty="BlurRadius" From="0" To="$BlurRadius" Duration="0:0:1" AutoReverse="False" />
                    </Storyboard>
                </BeginStoryboard>
            </EventTrigger>
        </Border.Triggers>
        <Grid >
            <Border Name="Mask" CornerRadius="$CornerRadius" Background="$($PSBoundParameters.ContentBackground)" />
            <Grid x:Name="Grid" Background="$($PSBoundParameters.ContentBackground)" $WidthDefine>
                <Grid.OpacityMask>
                    <VisualBrush Visual="{Binding ElementName=Mask}"/>
                </Grid.OpacityMask>
                <StackPanel Name="StackPanel" >                   
                    <TextBox Name="TitleBar" IsReadOnly="True" IsHitTestVisible="False" Text="$Title" Padding="10" FontFamily="$($PSBoundParameters.FontFamily)" FontSize="$TitleFontSize" Foreground="$($PSBoundParameters.TitleTextForeground)"
                     FontWeight="$($PSBoundParameters.TitleFontWeight)" Background="$($PSBoundParameters.TitleBackground)" HorizontalAlignment="$TitleAlign" 
                     VerticalAlignment="Center" Width="Auto" HorizontalContentAlignment="$ContentAlign" BorderThickness="0" TextWrapping="Wrap" AcceptsReturn="True" />
                    <DockPanel Name="ContentHost" Margin="0,10,0,10"  >
                    </DockPanel>
                    <DockPanel Name="ButtonHost" LastChildFill="False" HorizontalAlignment="Center" >
                    </DockPanel>
                </StackPanel>
            </Grid>
        </Grid>
    </Border>
</Window>
"@       
        [xml]$Xaml = $XamlString -as [xml]

        [string]$ButtonXamlString = @"
<Button xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Width="Auto" Height="30" FontFamily="Segui" FontSize="16" Background="Transparent" Foreground="White" BorderThickness="1" Margin="10" Padding="20,0,20,0" HorizontalAlignment="Right" Cursor="Hand"/>
"@
        [xml]$ButtonXaml = $ButtonXamlString -as [xml]

        [string]$ButtonTextXamlString = @"
<TextBlock xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" FontFamily="$($PSBoundParameters.FontFamily)" FontSize="16" Background="Transparent" Foreground="$($PSBoundParameters.ButtonTextForeground)" Padding="20,5,20,5" HorizontalAlignment="Center" VerticalAlignment="Center"/>
"@
        [xml]$ButtonTextXaml = $ButtonTextXamlString -as [xml]

        [string]$ContentTextXamlString = @"
<TextBlock xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" TextWrapping="WrapWithOverflow" Foreground="$($PSBoundParameters.ContentTextForeground)" 
DockPanel.Dock="Right" HorizontalAlignment="$ContentAlign" VerticalAlignment="Center" FontFamily="$($PSBoundParameters.FontFamily)" FontSize="$ContentFontSize" FontWeight="$($PSBoundParameters.ContentFontWeight)" 
Height="Auto" MaxWidth="400" MinWidth="350" Padding="10">$Content</TextBlock>
"@
         [xml]$ContentTextXaml = $ContentTextXamlString -as [xml]

        # Load the window from XAML
        $Window = [Windows.Markup.XamlReader]::Load((New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $Xaml))
        $DispatcherTimer = New-Object -TypeName System.Windows.Threading.DispatcherTimer
        # Custom  to add a button
        function Script:Add-Button {
            param($Content)
            $Button = [Windows.Markup.XamlReader]::Load((New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $ButtonXaml))
            $ButtonText = [Windows.Markup.XamlReader]::Load((New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $ButtonTextXaml))
            $ButtonText.Text = "$Content"
            $Button.Content = $ButtonText
            $Button.Add_MouseEnter({
                    $This.Content.FontSize = "17"
                })
            $Button.Add_MouseLeave({
                    $This.Content.FontSize = "16"
                })
            $Button.add_Click({
                    New-Variable -Name PWSHMessageBoxOutput -Value $($This.Content.Text) -Option ReadOnly -Scope Global -Force
                    Write-Verbose "New-Variable -Name PWSHMessageBoxOutput -Value $($This.Content.Text)"
                    $Window.Close()
                })
            $Window.FindName('ButtonHost').AddChild($Button)

            Set-Content "c:\tmp\ButtonXaml.xaml" -Value "$ButtonXamlString"
            Set-Content "c:\tmp\ButtonTextXaml.xaml" -Value "$ButtonTextXamlString"

        }
Set-Content "c:\tmp\Window.xaml" -Value "$XamlString"
        # Add buttons
        if ($ButtonType -eq "OK")
        {
            Add-Button -Content "OK"
        }

        if ($ButtonType -eq "OK-Cancel")
        {
            Add-Button -Content "OK"
            Add-Button -Content "Cancel"
        }

        if ($ButtonType -eq "Abort-Retry-Ignore")
        {
            Add-Button -Content "Abort"
            Add-Button -Content "Retry"
            Add-Button -Content "Ignore"
        }

        if ($ButtonType -eq "Yes-No-Cancel")
        {
            Add-Button -Content "Yes"
            Add-Button -Content "No"
            Add-Button -Content "Cancel"
        }

        if ($ButtonType -eq "Yes-No")
        {
            Add-Button -Content "Yes"
            Add-Button -Content "No"
        }

        if ($ButtonType -eq "Retry-Cancel")
        {
            Add-Button -Content "Retry"
            Add-Button -Content "Cancel"
        }
        if ($ButtonType -eq "Cancel-Continue")
        {
            Add-Button -Content "Cancel Checks"
            Add-Button -Content "Continue Checking"
        }
        if ($ButtonType -eq "Cancel-TryAgain-Continue")
        {
            Add-Button -Content "Cancel"
            Add-Button -Content "TryAgain"
            Add-Button -Content "Continue"
        }

        if ($ButtonType -eq "None" -and $CustomButtons)
        {
            foreach ($CustomButton in $CustomButtons)
            {
                Add-Button -Content "$CustomButton"
            }
        }

        # Remove the title bar if no title is provided
        if ($Title -eq "")
        {
            $TitleBar = $Window.FindName('TitleBar')
            $Window.FindName('StackPanel').Children.Remove($TitleBar)
        }

        # Add the Content
        if ($Content -is [string])
        {
            # Replace double quotes with single to avoid quote issues in strings
            if ($Content -match '"')
            {
                $Content = $Content.Replace('"', "'")
            }

            # Use a text box for a string value...
            $ContentTextBox = [Windows.Markup.XamlReader]::Load((New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $ContentTextXaml))
            $Window.FindName('ContentHost').AddChild($ContentTextBox)
        }
        else
        {
            # ...or add a WPF element as a child
            try
            {
                $Window.FindName('ContentHost').AddChild($Content)
            }
            catch
            {
                $_
            }
        }

        # Enable window to move when dragged
        $Window.FindName('Grid').Add_MouseLeftButtonDown({
                $Window.DragMove()
            })

        # Activate the window on loading
        if ($OnLoaded)
        {
            $Window.Add_Loaded({
                    $This.Activate()
                    Invoke-Command $OnLoaded
                })
        }
        else
        {
            $Window.Add_Loaded({
                    $This.Activate()
                })
        }


        # Stop the dispatcher timer if exists
        if ($OnClosed)
        {
            $Window.Add_Closed({
                    if ($DispatcherTimer -ne $null)
                    {
                        $DispatcherTimer.Stop()
                    }
                    Invoke-Command $OnClosed
                })
        }
        else
        {
            $Window.Add_Closed({
                    if ($DispatcherTimer -ne $null)
                    {
                        $DispatcherTimer.Stop()
                    }
                })
        }


        # If a window host is provided assign it as the owner
        if ($WindowHost)
        {
            $Window.Owner = $WindowHost
            $Window.WindowStartupLocation = "CenterOwner"
        }

        # If a timeout value is provided, use a dispatcher timer to close the window when timeout is reached
        if ($Timeout)
        {
            $Stopwatch = New-object System.Diagnostics.Stopwatch
            $TimerCode = {
                if ($Stopwatch.Elapsed.TotalSeconds -ge $Timeout)
                {
                    $Stopwatch.Stop()
                    $Window.Close()
                }
            }

            $DispatcherTimer.interval = [timespan]::FromSeconds(1)
            $DispatcherTimer.Add_Tick($TimerCode)
            $Stopwatch.Start()
            $DispatcherTimer.Start()
        }

        <# Play a sound
    If ($($PSBoundParameters.Sound))
    {
        $SoundFile = "$env:SystemDrive\Windows\Media\$($PSBoundParameters.Sound).wav"
        $SoundPlayer = New-Object System.Media.SoundPlayer -ArgumentList $SoundFile
        $SoundPlayer.Add_LoadCompleted({
            $This.Play()
            $This.Dispose()
        })
        $SoundPlayer.LoadAsync()
    }
    #>
        # Display the window
        $null = $window.Dispatcher.InvokeAsync{ $window.ShowDialog() }.Wait()

    }

}





function Test-Popupcolors {
    [CmdletBinding(SupportsShouldProcess)]

    $colors = @("AliceBlue", "AntiqueWhite", "Aqua", "Aquamarine", "Azure", "Beige", "Bisque", "Black", "BlanchedAlmond", "Blue", "BlueViolet", "Brown", "BurlyWood", "CadetBlue", "Chartreuse", "Chocolate", "Coral", "CornflowerBlue", "Cornsilk", "Crimson", "Cyan", "DarkBlue", "DarkCyan", "DarkGoldenrod", "DarkGray", "DarkGreen", "DarkKhaki", "DarkMagenta", "DarkOliveGreen", "DarkOrange", "DarkOrchid", "DarkRed", "DarkSalmon", "DarkSeaGreen", "DarkSlateBlue", "DarkSlateGray", "DarkTurquoise", "DarkViolet", "DeepPink", "DeepSkyBlue", "DimGray", "DodgerBlue", "Firebrick", "FloralWhite", "ForestGreen", "Fuchsia", "Gainsboro", "GhostWhite", "Gold", "Goldenrod", "Gray", "Green", "GreenYellow", "Honeydew", "HotPink", "IndianRed", "Indigo", "Ivory", "Khaki", "Lavender", "LavenderBlush", "LawnGreen", "LemonChiffon", "LightBlue", "LightCoral", "LightCyan", "LightGoldenrodYellow", "LightGray", "LightGreen", "LightPink", "LightSalmon", "LightSeaGreen", "LightSkyBlue", "LightSlateGray", "LightSteelBlue", "LightYellow", "Lime", "LimeGreen", "Linen", "Magenta", "Maroon", "MediumAquamarine", "MediumBlue", "MediumOrchid", "MediumPurple", "MediumSeaGreen", "MediumSlateBlue", "MediumSpringGreen", "MediumTurquoise", "MediumVioletRed", "MidnightBlue", "MintCream", "MistyRose", "Moccasin", "NavajoWhite", "Navy", "OldLace", "Olive", "OliveDrab", "Orange", "OrangeRed", "Orchid", "PaleGoldenrod", "PaleGreen", "PaleTurquoise", "PaleVioletRed", "PapayaWhip", "PeachPuff", "Peru", "Pink", "Plum", "PowderBlue", "Purple", "Red", "RosyBrown", "RoyalBlue", "SaddleBrown", "Salmon", "SandyBrown", "SeaGreen", "SeaShell", "Sienna", "Silver", "SkyBlue", "SlateBlue", "SlateGray", "Snow", "SpringGreen", "SteelBlue", "Tan", "Teal", "Thistle", "Tomato", "Transparent", "Turquoise", "Violet", "Wheat", "White", "WhiteSmoke", "Yellow", "YellowGreen")
    $colorscount = $colors.Count

    Write-Host "$colorscount colors to test"

    Register-ScriptAssemblies


    foreach ($c in $colors) {
        $Color = $c
        $FontSize = 22
        Show-MessageBox -Timeout 2 -Content "$c" -Title "$c" -TitleFontWeight "Bold" -TitleBackground "$Color" -TitleTextForeground Black -TitleFontSize $FontSize -ContentBackground "$Color" -ContentFontSize ($FontSize - 10) -ButtonTextForeground 'Black' -ContentTextForeground 'White'
    }
}



function Show-MessageBoxException {
    <#
    .SYNOPSIS
    Display a mesage box with colors to highlight a ERROR message
    .DESCRIPTION
    Display a mesage box with colors to highlight a WARNING message
    .PARAMETER Text
    String to display
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True, Position = 0)]
        [string]$ErrorString,
        [Parameter(Mandatory = $True, Position = 1)]
        [string[]]$Stack,
        [Parameter(Mandatory = $false)]
        [string]$FontSize = 16,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Black", "Bold", "DemiBold", "ExtraBlack", "ExtraBold", "ExtraLight", "Heavy", "Light", "Medium", "Normal", "Regular", "SemiBold", "Thin", "UltraBlack", "UltraBold", "UltraLight")]
        [string]$FontWeight = "Bold",
        [Parameter(Mandatory = $false)]
        [string]$Timeout = 0
    )


    $ExcptMsg = $ErrorString
    if ($Except -ne $null) {
        $ExcptMsg = $Except.Message
        while ($Except.InnerException) {
            $e = $Except.InnerException
            $ExcptMsg += "`n" + $Except.Message
        }
    }

    # Create a text box
    $TextBox = New-Object System.Windows.Controls.TextBox
    $TextBox.Text = $ErrorString
    $TextBox.Padding = 5
    $TextBox.Margin = 5
    $TextBox.BorderThickness = 1
    $TextBox.FontSize = $FontSize
    $TextBox.FontWeight = $FontWeight
    $TextBox.Width = "NaN"
    $TextBox.IsReadOnly = $True

    # Create an exander
    $Expander = New-Object System.Windows.Controls.Expander
    $Expander.Header = "Stack Trace"
    $Expander.FontSize = 12
    $Expander.FontWeight = "ExtraLight"
    $Expander.Padding = 5
    $Expander.Margin = "5,5,5,0"
    $Expander.FontSize = 14
    $Expander.FontWeight = "Regular"
    # Bind the expander width to the text box width, so the message box width does not change when expanded
    $Binding = New-Object System.Windows.Data.Binding
    $Binding.Path = [System.Windows.Controls.TextBox]::ActualWidthProperty
    $Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
    $Binding.Source = $TextBox
    [void]$Expander.SetBinding([System.Windows.Controls.Expander]::WidthProperty, $Binding)

    [string]$StackLog = $ExcptMsg
    foreach ($Line in $Stack) {
        $StackLog += $Line
        $StackLog += "`n"
    }
    # Create a textbox for the expander
    $ExpanderTextBox = New-Object System.Windows.Controls.TextBox
    $ExpanderTextBox.Text = $StackLog
    $ExpanderTextBox.Padding = 5
    $ExpanderTextBox.BorderThickness = 0
    $Expander.FontSize = 12
    $Expander.FontWeight = "ExtraLight"
    $ExpanderTextBox.TextWrapping = "Wrap"
    $ExpanderTextBox.IsReadOnly = $True
    $Expander.Content = $ExpanderTextBox

    # Assemble controls into a stackpanel
    $StackPanel = New-Object System.Windows.Controls.StackPanel
    $StackPanel.AddChild($TextBox)
    $StackPanel.AddChild($Expander)

    if ($Timeout -gt 0) {
        Show-MessageBox -Content $StackPanel -Title "Powershell Exception Error" -TitleBackground Red -TitleFontSize 16 -Sound 'Windows Unlock' -CornerRadius 0 -TitleTextForeground Yellow -Timeout $Timeout
    } else {
        Show-MessageBox -Content $StackPanel -Title "Powershell Exception Error" -TitleBackground Red -TitleFontSize 16 -Sound 'Windows Unlock' -CornerRadius 0 -TitleTextForeground Yellow
    }

}



function Show-MessageBoxVoice {
    <#
    .SYNOPSIS
    Display a mesage box with colors to highlight a ERROR message
    .DESCRIPTION
    Display a mesage box with colors to highlight a WARNING message
    .PARAMETER Text
    String to display
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)][AllowEmptyString()] $Text
    )
    $Content = $Text

    $Code = {
        try {
            Add-Type -AssemblyName System.speech
            $Synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
            $Synth.Speak($Text)
        } catch {}
    }

    $Params = @{
        Content = "$Content"
        Title = "BE ADVISED - NSFW - SYDNEY"
        ContentTextForeground = "White"
        ContentBackground = "Red"
        TitleBackground = "Red"
        TitleTextForeground = "Yellow"
        TitleFontWeight = "UltraBold"
        FontFamily = "Verdana"
        TitleFontSize = 20
        Sound = 'Windows Message Nudge'
        ButtonType = 'OK'
        OnLoaded = $Code
    }

    Show-MessageBox @Params
}


function Show-MessageBoxError {
    <#
    .SYNOPSIS
    Display a mesage box with colors to highlight a ERROR message
    .DESCRIPTION
    Display a mesage box with colors to highlight a WARNING message
    .PARAMETER Text
    String to display
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True, Position = 0)]
        [string]$Text,
        [Parameter(Mandatory = $False)]
        [string]$Title = "ERROR"
    )

    $ErrorMsgParams = @{
        Title = "$Title"
        ContentTextForeground = "White"
        ContentBackground = "Red"
        TitleBackground = "Red"
        TitleTextForeground = "Yellow"
        TitleFontWeight = "UltraBold"
        FontFamily = "Verdana"
        TitleFontSize = 20
    }
    Show-MessageBox @ErrorMsgParams -Content $Text
}


function Show-BeAdvisedSydney {
    <#
    .SYNOPSIS
    Display a mesage box with colors to highlight a ERROR message
    .DESCRIPTION
    Display a mesage box with colors to highlight a WARNING message
    .PARAMETER Text
    String to display
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)][AllowEmptyString()] $Text
    )
    $Content = $Text

    $Code = {
        try {
            Add-Type -AssemblyName System.speech
            $Synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
            $Synth.Speak($Text)
        } catch {}
    }

    $Params = @{
        Content = "$Content"
        Title = "BE ADVISED - NSFW - SYDNEY"
        ContentTextForeground = "White"
        ContentBackground = "Red"
        TitleBackground = "Red"
        TitleTextForeground = "Yellow"
        TitleFontWeight = "UltraBold"
        FontFamily = "Verdana"
        TitleFontSize = 20
        Sound = 'Windows Message Nudge'
        ButtonType = 'OK'
        OnLoaded = $Code
    }

    Show-MessageBox @Params
}

function Show-MessageBoxInfo {
    <#
    .SYNOPSIS
    Display a mesage box with colors to highlight a ERROR message
    .DESCRIPTION
    Display a mesage box with colors to highlight a WARNING message
    .PARAMETER Text
    String to display
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)][AllowEmptyString()] $Text,
        [Parameter(Mandatory = $false, Position = 1, ValueFromPipeline = $True)][AllowEmptyString()] $Title = 'Info'

    )

    $MsgParams = @{
        Title = $Title
        TitleBackground = "Blue"
        TitleTextForeground = "Black"
        TitleFontWeight = "Bold"
        TitleFontSize = 20
    }

    Show-MessageBox @MsgParams -Content $Text
}


function Show-MessageBoxStandby {
    <#
    .SYNOPSIS
    Display a mesage box
    .DESCRIPTION
    Display a mesage box
    .PARAMETER Text
    String to display
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $True)][AllowEmptyString()] $Title = 'STAND BY'

    )
    Register-ScriptAssemblies
    $SourceUrl = "https://arsscriptum.github.io/files/hiatus.jpg"
    $SourceMyPictures = Get-KnownFolderPath Pictures
    $SourceLocal = Join-Path "$SourceMyPictures" "hiatus.jpg"
    if (-not (Test-Path "$SourceLocal")) {
        Get-OnlineFileNoCache -Url "$SourceUrl" -Path "$SourceLocal"
    }
    [int]$FontSize = 16
    [string]$Color = 'Red'
    $Image = New-Object System.Windows.Controls.Image
    $Image.Source = $SourceLocal
    $Image.Height = [System.Drawing.Image]::FromFile($SourceLocal).Height
    $Image.Width = [System.Drawing.Image]::FromFile($SourceLocal).Width

    Show-MessageBox -Content $Image -Title "$Title" -TitleFontWeight "Bold" -TitleBackground "$Color" -TitleTextForeground Black -TitleFontSize $FontSize -ContentBackground "$Color" -ContentFontSize ($FontSize - 10) -ButtonTextForeground 'Black' -ContentTextForeground 'White'


}




function Show-MessageBoxRestart {
    <#
    .SYNOPSIS
    Display a mesage box with colors to highlight a ERROR message
    .DESCRIPTION
    Display a mesage box with colors to highlight a WARNING message
    .PARAMETER Text
    String to display
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [string]$Text,
        [Parameter(Mandatory = $False, Position = 1, ValueFromPipeline = $True)]
        [string]$Title = "Computer Restart Requested"
    )
    $Content = $Text

    $Params = @{
        Content = "$Content"
        Title = $Title
        ContentBackground = "SteelBlue"
        FontFamily = "Tahoma"
        TitleFontWeight = "Heavy"
        TitleBackground = "SteelBlue"
        TitleTextForeground = "White"
        ContentTextForeground = "White"
        ButtonTextForeground = "White"
        ButtonType = 'OK'
        TitleAlign = "left"
    }

    Show-MessageBox @Params
}



function Show-MessageBoxVideoUrl {
    <#
    .SYNOPSIS
    Display a mesage box with colors to highlight a ERROR message
    .DESCRIPTION
    Display a mesage box with colors to highlight a WARNING message
    .PARAMETER Text
    String to display
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $False, Position = 0, ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$Url,
        [Parameter(Mandatory = $False, Position = 1, ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$Title
    )
    $MediaPlayer = New-Object System.Windows.Controls.MediaElement
    $MediaPlayer.Height = "360"
    $MediaPlayer.Width = "640"
    $MediaPlayer.Source = $Url

    Show-MessageBox -Content $MediaPlayer -Title $Title -ContentBackground "Gray" -ContentTextForeground "Black" -TitleTextForeground "Black" -TitleBackground "Gray" -ButtonTextForeground "Red"


    $MediaPlayer.LoadedBehavior = "Manual"
    $MediaPlayer.Stop()
}


function Show-MessageBoxVideoSydney {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $False, Position = 0, ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$Title
    )
    [string]$Url = "https://arsscriptum.github.io/files/sydney.mp4"
    $MediaPlayer = New-Object System.Windows.Controls.MediaElement
    $MediaPlayer.Height = "636"
    $MediaPlayer.Width = "480"
    $MediaPlayer.Source = $Url

    Show-MessageBox -Content $MediaPlayer -Title $Title -ContentBackground "Gray" -ContentTextForeground "Black" -TitleTextForeground "Black" -TitleBackground "Gray" -ButtonTextForeground "Red"


    $MediaPlayer.LoadedBehavior = "Manual"
    $MediaPlayer.Stop()
}

function Show-MessageBoxVideoUrlExtended {
    <#
    .SYNOPSIS
    Display a mesage box with colors to highlight a ERROR message
    .DESCRIPTION
    Display a mesage box with colors to highlight a WARNING message
    .PARAMETER Text
    String to display
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $False, Position = 0, ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$Url,
        [Parameter(Mandatory = $False, Position = 1, ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$Title
    )
    # Create a Media Element
    $MediaPlayer = New-Object System.Windows.Controls.MediaElement
    $MediaPlayer.Height = "360"
    $MediaPlayer.Width = "640"
    $MediaPlayer.LoadedBehavior = "Manual"
    $MediaPlayer.Source = $Url

    # Add a start button
    $StartButton = New-Object System.Windows.Controls.Button
    $StartButton.Content = "Start"
    $StartButton.FontSize = 22
    $StartButton.Width = "NaN"
    $StartButton.Height = "NaN"
    $StartButton.VerticalContentAlignment = "Center"
    $StartButton.HorizontalContentAlignment = "Center"
    $StartButton.HorizontalAlignment = "Center"
    $StartButton.VerticalAlignment = "Center"
    $StartButton.Background = "Transparent"
    $StartButton.Margin = "0,5,15,0"
    $StartButton.Padding = 10
    $StartButton.Cursor = "Hand"
    $StartButton.add_Click({
            $MediaPlayer.Play()
        })

    # Add a stop button
    $StopButton = New-Object System.Windows.Controls.Button
    $StopButton.Content = "Stop"
    $StopButton.FontSize = 22
    $StopButton.Width = "NaN"
    $StopButton.Height = "NaN"
    $StopButton.VerticalContentAlignment = "Center"
    $StopButton.HorizontalContentAlignment = "Center"
    $StopButton.HorizontalAlignment = "Center"
    $StopButton.VerticalAlignment = "Center"
    $StopButton.Background = "Transparent"
    $StopButton.Margin = "15,5,0,0"
    $StopButton.Padding = 10
    $StopButton.Cursor = "Hand"
    $StopButton.add_Click({
            $MediaPlayer.Stop()
        })

    # Add a pause button
    $PauseButton = New-Object System.Windows.Controls.Button
    $PauseButton.Content = "Pause"
    $PauseButton.FontSize = 22
    $PauseButton.Width = "NaN"
    $PauseButton.Height = "NaN"
    $PauseButton.VerticalContentAlignment = "Center"
    $PauseButton.HorizontalContentAlignment = "Center"
    $PauseButton.HorizontalAlignment = "Center"
    $PauseButton.VerticalAlignment = "Center"
    $PauseButton.Background = "Transparent"
    $PauseButton.Margin = "15,5,15,0"
    $PauseButton.Padding = 10
    $PauseButton.Cursor = "Hand"
    $PauseButton.add_Click({
            $MediaPlayer.Pause()
        })

    # Add buttons to a dock panel
    $DockPanel = New-object System.Windows.Controls.DockPanel
    $DockPanel.LastChildFill = $False
    $DockPanel.HorizontalAlignment = "Center"
    $DockPanel.Width = "NaN"
    $DockPanel.AddChild($StartButton)
    $DockPanel.AddChild($PauseButton)
    $DockPanel.AddChild($StopButton)

    # Add dock panel and media player to a stackpanel
    $StackPanel = New-object System.Windows.Controls.StackPanel
    $StackPanel.AddChild($MediaPlayer)
    $StackPanel.AddChild($DockPanel)

    Show-MessageBox -Content $StackPanel -Title $title

}


function Show-MessageBoxScriptError {
    <#
    .SYNOPSIS
    Display a mesage box with colors to highlight a ERROR message
    .DESCRIPTION
    Display a mesage box with colors to highlight a WARNING message
    .PARAMETER Text
    String to display
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [string]$Text,
        [Parameter(Mandatory = $False, Position = 1, ValueFromPipeline = $True)]
        [string]$Title = ":("
    )
    $Params = @{
        FontFamily = 'Verdana'
        Title = $Title
        TitleFontSize = 80
        TitleTextForeground = 'White'
        TitleBackground = 'SteelBlue'
        ButtonType = 'OK'
        ContentFontSize = 16
        ContentTextForeground = 'White'
        ContentBackground = 'SteelBlue'
        ButtonTextForeground = 'White'
        BorderThickness = 0
    }
    Show-MessageBox @Params -Content $Text -TitleAlign "left"

}


function Show-MessageBoxServices {
    <#
    .SYNOPSIS
    Display a mesage box with colors to highlight a ERROR message
    .DESCRIPTION
    Display a mesage box with colors to highlight a WARNING message
    .PARAMETER Text
    String to display
#>
    [CmdletBinding()]
    param()
    # Get Services
    $Fields = @(
        'Status'
        'DisplayName'
        'ServiceName'
    )
    $ServicesAll = try{Get-Service -EA Stop}catch{}
    $Services = $ServicesAll | Select $Fields

    # Add Services to a datatable
    $Datatable = New-Object System.Data.DataTable
    [void]$Datatable.Columns.AddRange($Fields)
    foreach ($Service in $Services)
    {
        $Array = @()
        foreach ($Field in $Fields)
        {
            $array += $Service.$Field
        }
        [void]$Datatable.Rows.Add($array)
    }

    # Create a datagrid object and populate with datatable
    $DataGrid = New-Object System.Windows.Controls.DataGrid
    $DataGrid.ItemsSource = $Datatable.DefaultView
    $DataGrid.MaxHeight = 500
    $DataGrid.MaxWidth = 500
    $DataGrid.CanUserAddRows = $False
    $DataGrid.IsReadOnly = $True
    $DataGrid.GridLinesVisibility = "None"

    $Params = @{
        Content = $DataGrid
        Title = "Services on $Env:COMPUTERNAME"
        ContentBackground = "WhiteSmoke"
        FontFamily = "Tahoma"
        TitleFontWeight = "Heavy"
        TitleBackground = "LightSteelBlue"
        TitleTextForeground = "Black"
        Sound = 'Windows Message Nudge'
        ContentTextForeground = "DarkSlateGray"
    }
    Show-MessageBox @Params
}


function Show-MessageBoxAsyncPing {

    # XAML code
    [xml]$Xaml = @"
    <StackPanel xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" >
        <TextBox ScrollViewer.VerticalScrollBarVisibility="Auto" ScrollViewer.HorizontalScrollBarVisibility="Auto" Name="TextBox" Width="400" Height="200" Text="" BorderThickness="0" FontSize="18" TextWrapping="Wrap" FontFamily="Arial" IsReadOnly="True" Padding="5"/>
        <Button Name="Button" Content="Begin" Background="White" FontSize="24" HorizontalAlignment="Center" Cursor="Hand" />
    </StackPanel>
"@

    # Create the WPF object from the XAML code
    $ChildElement = [Windows.Markup.XamlReader]::Load((New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $xaml))

    # Create a synchronised hashtable and add elements to it
    $UI = [System.Collections.Hashtable]::Synchronized(@{})
    $UI.ChildElement = $ChildElement
    $UI.TextBox = $ChildElement.FindName('TextBox')
    $UI.Button = $ChildElement.FindName('Button')

    # Define the code to run in a background job
    $Code = {
        param($UI)

        # Disable the button during run
        $UI.TextBox.Dispatcher.Invoke({
                $UI.Button.IsEnabled = $False
                $UI.Button.Foreground = "Gray"
            })

        # Ping IP addresses
        1..255 | foreach {
            $Index = $_
            $IPaddress = "10.0.0.$Index"
            if (Test-Connection -ComputerName $IPaddress -Count 1 -Quiet)
            {
                $UI.TextBox.Dispatcher.Invoke({
                        $UI.TextBox.Text = $UI.TextBox.Text + "`n" + "$IPAddress is online"
                        $UI.TextBox.ScrollToEnd()
                    })
            }
            else
            {
                $UI.TextBox.Dispatcher.Invoke({
                        $UI.TextBox.Text = $UI.TextBox.Text + "`n" + "$IPAddress could not be contacted"
                        $UI.TextBox.ScrollToEnd()
                    })
            }
        }

        # Re-enable button
        $UI.TextBox.Dispatcher.Invoke({
                $UI.Button.IsEnabled = $True
                $UI.Button.Foreground = "Black"
            })
    }

    # Define the code to run when the button is clicked
    $UI.Button.add_Click({

            # Spin up a powershell instance and run the code
            $PowerShell = [powershell]::Create()
            $PowerShell.AddScript($Code)
            $PowerShell.AddArgument($UI)
            $PowerShell.BeginInvoke()

        })

    Show-MessageBox -Title "Test-Connection Log Window" -Content $ChildElement

}


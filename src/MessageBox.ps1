#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   MsgBox.ps1                                                                   ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝



function Show-ZbookSimpleMessageBox {
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


function Show-TemperatureWarning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True, Position = 0)] [int]$Temperature
    )
    [int]$ContentFontSize = 24
    [int]$TitleFontSize = 36
    [int]$BorderThickness = 0
    [int]$CornerRadius = 20
    [int]$ShadowDepth = 3
    [int]$BlurRadius = 20
    $Text = "Current Temperature has reached $Temperature C"

    $Params = @{
        Content = "$Text"
        Title = "TEMPERATURE WARNING"
        TitleFontSize = $TitleFontSize
        TitleBackground = 'Red'
        TitleTextForeground = 'Yellow'
        ButtonType = 'None'
        CustomButtons = "Close"
        CornerRadius = $CornerRadius
        ShadowDepth = $ShadowDepth

    };
    Show-ZbookSimpleMessageBox @Params

}



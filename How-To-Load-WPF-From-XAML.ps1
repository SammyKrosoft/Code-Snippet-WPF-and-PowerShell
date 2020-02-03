
# Load a WPF GUI from a XAML file build with Visual Studio
Add-Type -AssemblyName presentationframework, presentationcore
$wpf = @{ }
# NOTE: Either load from a XAML file or paste the XAML file content in a "Here String"
#$inputXML = Get-Content -Path ".\WPFGUIinTenLines\MainWindow.xaml"
$inputXML = @"

Here-String pasted from XAML

"@

$inputXMLClean = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace 'x:Class=".*?"','' -replace 'd:DesignHeight="\d*?"','' -replace 'd:DesignWidth="\d*?"',''
[xml]$xaml = $inputXMLClean

# Read the XAML code
$reader = New-Object System.Xml.XmlNodeReader $xaml
$tempform = [Windows.Markup.XamlReader]::Load($reader)

# Populate the Hash table $wpf with the Names / Values pairs using the form control names
# Form control objects will be available as $wpf.<Form control name> like $wpf.RunButton for example...
# Adding an event like Click or MouseOver will be with $wpf.RunButton.addClick({Code})
$namedNodes = $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]")
$namedNodes | ForEach-Object {$wpf.Add($_.Name, $tempform.FindName($_.Name))}

# Seen another method where the developper creates variables for each control instead of using a hash table
# $wpf {Key name, Value}, he uses Set-Variable "var_$($_.Name)" with value $TempForm.FindName($_.Name) instead of $HashTable.Add($_.Name,$tempForm.FindName($_.Name)):
#
#       $NamedNodes = $xaml.SelectNodes("//*[@Name]") 
#       $NamedNodes | Foreach-Object {Set-Variable -Name "var_$($.Name)" -Value $tempform.FindName($_.Name) -ErrorAction Stop}
#
# that way, each control will be accessible with the variable name named $var_<control name> like $var_btnQuery
# we would add events like Click or MouseOver using $var_btnQuery.addClick({Code})
# more info there: https://adamtheautomator.com/build-powershell-gui/

#Get the form name to be used as parameter in functions external to form...
$FormName = $NamedNodes[0].Name


#Define events functions
#region Load, Draw (render) and closing form events
#Things to load when the WPF form is loaded aka in memory
$wpf.$FormName.Add_Loaded({
    #Update-Cmd
})
#Things to load when the WPF form is rendered aka drawn on screen
$wpf.$FormName.Add_ContentRendered({
    #Update-Cmd
})
$wpf.$FormName.add_Closing({
    $msg = "bye bye !"
    write-host $msg
})

#endregion Load, Draw and closing form events
#End of load, draw and closing form events

#HINT: to update progress bar and/or label during WPF Form treatment, add the following:
# ... to re-draw the form and then show updated controls in realtime ...
$wpf.$FormName.Dispatcher.Invoke("Render",[action][scriptblock]{})


# Load the form:
# Older way >>>>> $wpf.MyFormName.ShowDialog() | Out-Null >>>>> generates crash if run multiple times
# Newer way >>>>> avoiding crashes after a couple of launches in PowerShell...
# USing method from https://gist.github.com/altrive/6227237 to avoid crashing Powershell after we re-run the script after some inactivity time or if we run it several times consecutively...
$async = $wpf.$FormName.Dispatcher.InvokeAsync({
    $wpf.$FormName.ShowDialog() | Out-Null
})
$async.Wait() | Out-Null
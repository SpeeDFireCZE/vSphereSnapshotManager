#--------------------------------------Sdílené proměnné-----------------------------------------------#
    $server= "******"
#---------------------------------kontrola dostupnosti--------------------------------------#
$vcaccess = ping $server -n 1
if($vcaccess -match "Received = 1"){

    #---------------------------------načtení popup modulu--------------------------------------#
[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')

    #---------------------------------ověření VMpowercli--------------------------------------#
    if ($null -eq (Get-Module VMware.VimAutomation.Cis.Core -ListAvailable | Select-Object -expand Name)){
        Write-Host "Probíhá instalace VM powerCLI, aplikace se poté automaticky spustí"
        Install-Module VMware.VimAutomation.Core -Scope CurrentUser -Confirm:$False -Force
    }
    else{

    }
#--------------------------------------viditelné jen GUI-----------------------------------------------#
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
$consolePtr = [Console.Window]::GetConsoleWindow()
[Console.Window]::ShowWindow($consolePtr, 0)



#---------------------------------okno--------------------------------------#
Add-Type -assembly System.Windows.Forms
$main_form = New-Object System.Windows.Forms.Form
$main_form.Toplevel = $true
$main_form.Text ='VM snapshot management'
$main_form.BackColor = “black”
$main_form.ForeColor = “white”
#$main_form.Width = 410
#$main_form.Height = 400
$main_form.AutoSize = $true
$main_form.FormBorderStyle = 'FixedToolWindow'
$main_form.StartPosition = 'CenterScreen'



#==============================================================================================================================================================================#
#==============================================================================================================================================================================#
#                                                                             Admin Login                                                                                      #
#==============================================================================================================================================================================#
#==============================================================================================================================================================================#
$Buttonlogin = New-Object System.Windows.Forms.Button
$Buttonlogin.BackColor =”LightGray”
$Buttonlogin.ForeColor = “black”
$Buttonlogin.Location = New-Object System.Drawing.Size(700,5)

$Buttonlogin.Size = New-Object System.Drawing.Size(90,20)

$Buttonlogin.Text = "VM login"
$Buttonlogin.Cursor="Hand"
$main_form.Controls.Add($Buttonlogin)

$Buttonlogin.Add_Click(
{
if ($Buttonlogin.Text -eq "VM login"){
Do {
$Script:Cred = Get-Credential -Message "Váš VM účet"
$main_form.Toplevel = $true

if($null -ne $Cred){
   #Get-ADUser -Credential $Cred -Properties LockedOut
   Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false  
   Connect-VIServer -Server $server -Credential $Cred   
   $exitcodelogin=get-vm |Select-Object -expand name  
}
else{
$credexit="False"
}
}
Until ($null -ne $exitcodelogin -or $credexit -eq "False")

$loggedinname= $cred | select-object -expand UserName
if($null -ne $exitcodelogin){
    $Buttonlogin.Text = $loggedinname
}
}
else{
$Buttonlogin.Text = "VM login"
$Cred > $null
Disconnect-VIServer -Confirm:$False -Force
}
}
)

#==============================================================================================================================================================================#
#==============================================================================================================================================================================#
#                                                                             Default menu/menu1                                                                               #
#==============================================================================================================================================================================#
#==============================================================================================================================================================================#

#=========================================================================Funkce na $infotextBoxmenu1 a $findtextboxmenu1========================================================#
function get-textinfo{
    $infotextBoxmenu1.Text=""
    $findtextboxmenu1.Items.Clear()
    $findtextboxmenu1.Text=""
if($Buttonlogin.Text -ne "VM login"){
    foreach ($line in (Get-View -ViewType VirtualMachine -Property Name,Snapshot -Filter @{Snapshot = ''} | select-object -expand Name)){
        $snapshot = Get-Snapshot -VM $line
        $snaptime= Get-Snapshot -VM $line | select-object -expand created
        foreach ($snap in $snaptime){
        $finishtime= $snap.AddMinutes(5).ToString("dd/MM/yyyy HH:mm:ss")
        $finishtimedatetime= [datetime]::ParseExact("$finishtime", "dd/MM/yyyy h:mm:ss", $null)
        $starttime= $snap.AddMinutes(-59).ToString("dd/MM/yyyy HH:mm:ss")
        $starttimedatetime= [datetime]::ParseExact("$starttime", "dd/MM/yyyy h:mm:ss", $null)
        $exit= Get-VIEvent -Entity $line -Types Info -start $starttimedatetime -finish $finishtimedatetime| Where-Object {$_.FullFormattedMessage -imatch 'Task: Create virtual machine snapshot'} | Select-Object -expand UserName | Out-String
        $vysledek = ($exit -split "`n")
    }
        foreach ($snapname in $snapshot){
        if($null -ne $snapshot){    
        $infotextBoxmenu1.AppendText( "'VM: "+ "||$line||" + " Snapshot: '" + "||$snapname||" + "' created on: " + $snapname.Created.DateTime + " by " + $vysledek[0] + "`r`n")
        $findtextboxmenu1.Items.Add("'VM: "+ "||$line||" + " Snapshot: '" + "||$snapname||," + "' created on: " + $snapname.Created.DateTime + " by " + $vysledek[0] + "`r`n")
        }
        
        else {
        }
        }
    
    }
    }
    else{
        (New-Object -ComObject Wscript.Shell -ErrorAction Stop).Popup("Pro tuto funkci je vyžadován AD login",0,"Chyba",64)
    }

    $findtextboxmenu1.AutoCompleteSource = 'ListItems'
    $findtextboxmenu1.AutoCompleteMode = 'Append'


}


#=========================================================================zjištění snapshotů===========================================================================================#
$infotextBoxmenu1 = New-Object System.Windows.Forms.TextBox
$infotextBoxmenu1.Multiline=$true 
$infotextBoxmenu1.ReadOnly=$true
$infotextBoxmenu1.ScrollBars="vertical"
$infotextBoxmenu1.Location = New-Object System.Drawing.Point(5,170)
$infotextBoxmenu1.Size = New-Object System.Drawing.Size(800,200)
$main_form.Controls.Add($infotextBoxmenu1)

$infotextBoxmenu1.Add_KeyDown({
    if (($_.Control) -and ($_.KeyCode -eq 'A')) {
       $infotextBoxmenu1.SelectAll()
    }
  })

$Buttonmenu1 = New-Object System.Windows.Forms.Button
$Buttonmenu1.BackColor =”LightGray”
$Buttonmenu1.ForeColor = “black”
$Buttonmenu1.Location = New-Object System.Drawing.Size(310,35)

$Buttonmenu1.Size = New-Object System.Drawing.Size(160,23)

$Buttonmenu1.Text = "Zkontrolovat Snapshoty"
$Buttonmenu1.Cursor="Hand"
$main_form.Controls.Add($Buttonmenu1)

$Buttonmenu1.Add_Click(

{
get-textinfo
}

)

#=========================================================================delete-menu1===========================================================================================#



$findtextboxmenu1 = New-Object System.Windows.Forms.ComboBox
$findtextboxmenu1.Location = New-Object System.Drawing.Point(5,110)
$findtextboxmenu1.Size = New-Object System.Drawing.Size(800,20)

$main_form.Controls.Add($findtextboxmenu1)

$findtextboxmenu1.Add_KeyDown({
    if (($_.Control) -and ($_.KeyCode -eq 'A')) {
       $findtextboxmenu1.SelectAll()
    }
  })

$button4menu1 = New-Object System.Windows.Forms.Button
$button4menu1.BackColor =”LightGray”
$button4menu1.ForeColor = “black”
$button4menu1.Location = New-Object System.Drawing.Size(310,135)

$button4menu1.Size = New-Object System.Drawing.Size(160,23)

$button4menu1.Text = "odstranit snapshot"
$button4menu1.Cursor="Hand"
$main_form.Controls.Add($button4menu1)

$button4menu1.Add_Click(

{   
    $delsnapshot= $findtextboxmenu1.Text.split("||")
    $delname= $delsnapshot[6]
    $hostname= $delsnapshot[2]
    Get-Snapshot -VM $delsnapshot[2] | Where-Object { $_.Name -like $delsnapshot[6] } | remove-snapshot -Confirm:$false
            (New-Object -ComObject Wscript.Shell -ErrorAction Stop).Popup("Snapshot $delname na $hostname byl smazát",0,"Chyba",64)

    get-textinfo

            
}
)

    $main_form.ShowDialog()

}
else{
(New-Object -ComObject Wscript.Shell -ErrorAction Stop).Popup("Vcenter Server je nedostupný. Prosím zkontrolujte jeho dostupnost.",0,"Chyba",16)
}

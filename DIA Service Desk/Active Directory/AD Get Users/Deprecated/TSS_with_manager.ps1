# Update this with the file path and name where you want to save the output
$CSVPath = "C:\Users\sa-mortimki\Documents\Scripts\AD Get Department Members\Exported Member Lists\TSS_with_manager.csv"
 
# Search for users in AD with the specified Department field
$Users = Get-ADUser -Filter "Department -like 'Technology Services and Solutions'" -Properties *
 
# Initialize an array to store the results
$Results = @()
 
# Loop through each user
foreach ($User in $Users) {
   # Initialize an object to store the user's information
   $UserObj = [PSCustomObject]@{
       "Name" = $User.Name
 "Department" = $User.Department
  "Business Unit" = $User.Description
 "Email Address" = $User.EmailAddress
 "Manager" = if ($User.Manager) { (Get-ADUser -Identity $User.Manager).Name } else { "" }
  "Direct Reports" = ""
   }
 
   # If the user has direct reports, get their names and add them to the object
   $DirectReports = Get-ADUser -Filter {Manager -eq $User.DistinguishedName} -Properties Manager | Select-Object -ExpandProperty Name
   if ($DirectReports) {
       $UserObj."Direct Reports" = $DirectReports -join ","
   }
 
   # Add the object to the results array
   $Results += $UserObj
}
 
# Export the results to a CSV file
$Results | Export-Csv -Path $CSVPath -NoTypeInformation
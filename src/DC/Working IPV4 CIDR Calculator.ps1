$CIDRAddress = "10.20.30.5/24"

 # Separate our IP address, from subnet bit count
 $IPAddress, [int32]$SubnetMaskBits =  $CIDRAddress.Split('/')

 Write-Output ("subnetmaskbits" +$SubnetMaskBits)
 # Create array to hold our output mask
 $CIDRMask = @()
 # Loop each octet,
 for($i = 0; $i -lt 4; $i++)
 {
     # Looking for 255 in place
     if($SubnetMaskBits -gt 7)
     {
         # Add 255, then minus 8  
         $CIDRMask += [byte]255
         $SubnetMaskBits -= 8
     }
     else
     {
         # Not 255 so calculate octet bits and
         # zero out our SubnetMaskBits.
         $CIDRMask += [byte]255 -shl (8 - $SubnetMaskBits)
         $SubnetMaskBits = 0
     }
 }
 # Assign mask to the SubnetMask variable
 $SubnetMask = $CIDRMask -join '.'
 Write-Output($IPAddress + "," + $SubnetMask)

 
# Get Arrays of [Byte] objects,  for each octet in our IP and Mask
$IPAddressBytes = ([ipaddress]::Parse($IPAddress)).GetAddressBytes()
$SubnetMaskBytes = ([ipaddress]::Parse($SubnetMask)).GetAddressBytes()
# Declare empty arrays to hold output
$NetworkAddressBytes   = @()
$BroadcastAddressBytes = @()
$WildcardMaskBytes     = @()

# Determine Broadcast / Network Addresses, as well as Wildcard Mask
for($j = 0; $j -lt 4; $j++)
{
    # Compare each Octet in the host IP to the Mask using bitwise
    # to obtain our Network Address
    $NetworkAddressBytes +=  $IPAddressBytes[$j] -band $SubnetMaskBytes[$j]

    # Compare each Octet in the subnet mask to 255 to get our wildcard mask
    $WildcardMaskBytes +=  $SubnetMaskBytes[$j] -bxor 255

    # Compare each octet in network address to wildcard mask to get broadcast.
    $BroadcastAddressBytes += $NetworkAddressBytes[$j] -bxor $WildcardMaskBytes[$j] 
}
# Create variables to hold NetworkAddress, WildcardMask, BroadcastAddress
$NetworkAddress   = $NetworkAddressBytes -join '.'
$BroadcastAddress = $BroadcastAddressBytes -join '.'
$WildcardMask     = $WildcardMaskBytes -join '.'
# We need to reverse the byte order in our Network, Broadcast addresses and convert IP Address
[array]::Reverse($NetworkAddressBytes)
[array]::Reverse($BroadcastAddressBytes)
[array]::Reverse($IPAddressBytes)

# Convert them both to 32-bit integers
$NetworkAddressInt   = [System.BitConverter]::ToUInt32($NetworkAddressBytes,0)
$BroadcastAddressInt = [System.BitConverter]::ToUInt32($BroadcastAddressBytes,0)
$IPAddressInt        = [System.BitConverter]::ToUInt32($IPAddressBytes,0)

#Calculate the number of hosts in subnet, subtracting one to account for network address.
$NumberOfHosts = ($BroadcastAddressInt - $NetworkAddressInt) - 1

   # Declare an empty array to hold our range of usable IPs.
   $IPRange = @()

   # If -IncludeIPRange specified, calculate it
   if ($IncludeIPRange)
   {
       # Now run through our IP range and figure out the IP address for each.
       For ($k = 1; $k -le $NumberOfHosts; $k++)
       {
           # Increment Network Address by our counter variable, then convert back
           # lto an IP address and extract as string, add to IPRange output array.
           $IPRange +=[ipaddress]([convert]::ToDouble($NetworkAddressInt + $k)) | Select-Object -ExpandProperty IPAddressToString
       }
    }
    # Create our output object
    $obj = New-Object -TypeName psobject

    # Add our properties to it
    Add-Member -InputObject $obj -MemberType NoteProperty -Name "IPAddress"           -Value $IPAddress
    Add-Member -InputObject $obj -MemberType NoteProperty -Name "SubnetMask"          -Value $SubnetMask
    Add-Member -InputObject $obj -MemberType NoteProperty -Name "NetworkAddress"      -Value $NetworkAddress
    Add-Member -InputObject $obj -MemberType NoteProperty -Name "BroadcastAddress"    -Value $BroadcastAddress
    Add-Member -InputObject $obj -MemberType NoteProperty -Name "WildcardMask"        -Value $WildcardMask
    Add-Member -InputObject $obj -MemberType NoteProperty -Name "NumberOfHostIPs"     -Value $NumberOfHosts
    Add-Member -InputObject $obj -MemberType NoteProperty -Name "IPRange"             -Value $IPRange
    # Return the object
    return $obj

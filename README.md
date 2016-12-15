# makeCDN

## Overview
This script allows to create a valid RPM tree to be used with a Satellite 6 
without internet connection. This is useful in laboratorio/testing environments
where Satellite may be destroyed and recreated quickly.

**Warning**: Do not use this script in production environments to _feed_ 
Satellite. **Use Content ISOs provided by Red Hat instead for production**.

**Warning**: This procedure is not supported in any way by Red Hat as a method
to provide content to a disconnected Satellite. **Use Content ISOs provided by 
Red Hat instead for production**.

**Warning**: You may get in troubles if use this method in production 
environments . **Use Content ISOs provided by Red Hat instead for production**.

Did you notice my warnings?

## Preparation
* Clone this repo in your computer
* Move its content to your source directory, __/var/www/html/cdn__ or edit the 
  script to use a different directory
* Subscribe your CDN server to Red Hat with a valid entitlement
* Enable your desired repos
* Make sure that **hostname -f** is resolved by DNS or edit the script to use a
  different hostname

## Usage
* Modify **repos.txt** file to set which repositories should be synchronized and
  exported as CDN (previously enabled with your valid entitlement)
* Run this script and let it finish
* Set your Satellite to use your server as CDN: __http://yourserver.yourdomain.tld/cdn__

## Contact
Reach me in [Twitter] or email in soukron _at_ gmbros.net

## References
 - Simple Script to create 'listing' files as required by Satellite 6 to import
   Content ISOs https://github.com/sideangleside/makeCDNListingFiles
 - How to create a local mirror of the latest update for Red Hat Enterprise Linux 5, 6, 7 
   without using Satellite server? https://access.redhat.com/solutions/23016

## License
Nothing to be licensed, but just in case, everything in this repo is licensed under GNU GPLv3 
license. You can read the document [here].

[Twitter]:http://twitter.com/soukron
[here]:http://gnu.org/licenses/gpl.html


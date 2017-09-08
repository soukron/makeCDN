#!/bin/bash

function log() {
  echo "$( date ) -- $@"
}

# FQDN of server which serves cdn files
fqdn=$( hostname -f )
#fqdn=cdn.t440s.local

# Where this script is located
SCRIPTDIR="$(dirname "$(readlink -f "$0")")"

# Where cdn files are served (http://<fqdn>/<contentroot>)
if [ -z ${1} ]; then
  contentroot=/var/www/html
else
  contentroot=/var/www/html/$1
fi
log "Selecting $contentroot directory as contentroot"

# Where cdn files are located
cdnroot=$contentroot/files
log "Selecting $cdnroot directory as cdnroot"

# Try to copy source if any and it exists 
if [ ! -z ${2} ] && [ -d /var/www/html/${2} ]; then
  log "Provided ${2} as source for contentroot"
  [ -d $contentroot ] && log "Deleting previous contentroot directory" && rm -fr $contentroot
  
  log "Copying ${2} as contentroot"
  cp -al /var/www/html/${2} $contentroot
fi

# Create content root and cdn directories if don't exist
for dir in $contentroot $cdnroot; do
  ( [ -d $dir ] && log "Use existing $dir directory" ) || ( mkdir -p $dir && log "Creating $dir" ) 
done

# Delete .repo file if exists
[ -f $contentroot/cdn.repo ] && log "Removing existing cdn.repo file" && rm -f $contentroot/cdn.repo

# Loop over required repos to be synch'ed
cd $cdnroot
for repo in `cat $SCRIPTDIR/repos.txt | grep -v ^#`; do
  log "Synchronizing $repo"

  # Get URL for each repo and replace cdn.redhat.com and extract directory hierarchy
  baseurl=`yum-config-manager $repo | grep baseurl | cut -d " " -f 3 | sed "s/cdn\.redhat\.com/$fqdn\/$1/" | sed 's/https/http/'`
  basedir=`echo $baseurl | cut -d / -f 5- | rev | cut -d / -f 2- | rev`
  dir=`echo $baseurl | rev | cut -d / -f 1 | rev`

  # Synchronize and generate local repo metadata
  reposync -l --repoid=$repo --downloadcomps --download-metadata --delete &> /dev/null
  createrepo $repo/ -g comps.xml &> /dev/null

  # Create directory hierarchy and symlink repository
  rm -fr $contentroot/$basedir/$dir $contentroot/$basedir
  mkdir -p $contentroot/$basedir
  ln -fs $cdnroot/$repo $contentroot/$basedir/$dir

  # Create repository entry for yum repo file
  cat >> $contentroot/cdn.repo <<EOF
[$repo]
name=$repo
baseurl=$baseurl
enabled=1
gpgcheck=0

EOF
done

# Clean up previous listing files and create new ones
log "Creating listing files"
find $contentroot -iname listing -delete
$SCRIPTDIR/makeCDNListingFiles.py -c $contentroot/content

# Restore context and ownership in cdn root and content directories
log "Restoring SELinux and ownership in files"
for dir in $contentroot $cdnroot; do
  restorecon -RF $dir &> /dev/null
  chown -R apache.apache $dir
done

# Run hardlink to save disk
[ -f `which hardlink` ] && log "Running hardlink to save disk" && hardlink /var/www/html

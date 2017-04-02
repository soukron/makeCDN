#!/bin/bash

# FQDN of server which serves cdn files
fqdn=cdn.t440s.local

# Where this script is located
SCRIPTDIR="$(dirname "$(readlink -f "$0")")"

# Where cdn files are served (http://<fqdn>/<contentroot>)
if [ -z ${1} ]; then
  contentroot=/var/www/html
else
  contentroot=/var/www/html/$1
fi

# Where cdn files are located
cdnroot=$contentroot/files

# Create content root and cdn directories if don't exist
for dir in $contentroot $cdnroot; do
  [ -d $dir ] || mkdir -p $dir
done

# Delete .repo file if exists
[ -f $contentroot/cdn.repo ] && rm -f $contentroot/cdn.repo

# Loop over required repos to be synch'ed
cd $cdnroot
for repo in `cat $SCRIPTDIR/repos.txt | grep -v ^#`; do
  echo "Synchronizing $repo..."

  # Get URL for each repo and replace cdn.redhat.com and extract directory hierarchy
  baseurl=`yum-config-manager $repo | grep baseurl | cut -d " " -f 3 | sed "s/cdn\.redhat\.com/$fqdn\/$1/" | sed 's/https/http/'`
  basedir=`echo $baseurl | cut -d / -f 5- | rev | cut -d / -f 2- | rev`
  dir=`echo $baseurl | rev | cut -d / -f 1 | rev`

  # Synchronize and generate local repo metadata
  reposync -l --repoid=$repo --downloadcomps --download-metadata
  createrepo $repo/ -g comps.xml

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
find $contentroot -iname listing -delete
$SCRIPTDIR/makeCDNListingFiles.py -c $contentroot/content

# Restore context and ownership in cdn root and content directories
for dir in $contentroot $cdnroot; do
  restorecon -RF $dir &> /dev/null
  chown -R apache.apache $dir
done

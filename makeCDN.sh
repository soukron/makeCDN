#!/bin/bash

# Where cdn files reside
cdnroot=/var/www/html/cdn
# Where cdn files are served
contentroot=/var/www/html
# FQDN of server which serves cdn files
fqdn=`hostname -f`

# Create content root if doesn't exist
[ ! -d $contentroot ] || mkdir -p $contentroot

# Delete .repo file if exists
[ -f $contentroot/cdn.repo ] && rm -f $contentroot/cdn.repo

# Loop over required repos to be synch'ed
cd $cdnroot
for repo in `cat repos.txt | grep -v ^#`; do
  echo $repo

  # Get URL for each repo and replace cdn.redhat.com and extract directory hierarchy
  baseurl=`yum-config-manager $repo | grep baseurl | cut -d " " -f 3 | sed "s/cdn\.redhat\.com/$fqdn/" | sed 's/https/http/'`
  basedir=`echo $baseurl | cut -d / -f 4- | rev | cut -d / -f 2- | rev`
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
./makeCDNListingFiles.py -c $contentroot/content

# Restore context and ownership
restorecon -vRF $contentroot
chown -R apache.apache $contentroot

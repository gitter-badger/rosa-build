#!/usr/bin/env bash
# import_srpm.sh: Import SRPM packages to git repo

# Input data
srpm_path=$1
git_path=$2
git_branch=$3
tmp_dir=/tmp/$RANDOM
version=$(rpm -q --qf '[%{Version}]' -p $srpm_path)

# Clone destination repo
mkdir -p $tmp_dir
git clone $git_path $tmp_dir

# Switch to import branch
cd $tmp_dir
git branch --track $git_branch origin/$git_branch # Try track remote
git branch $git_branch # Try create local
git checkout $git_branch

# Remove all files except .git
rm -rf $tmp_dir/*
mv $tmp_dir/.git $tmp_dir/git
rm -rf $tmp_dir/.*
mv $tmp_dir/git $tmp_dir/.git

# Unpack srpm
rpm2cpio $srpm_path > srpm.cpio
cpio -idv < srpm.cpio
rm -f srpm.cpio

# Commit and push changes
git add -A .
git commit -m "Automatic import for version $version" 
git push origin HEAD

# Cleanup
rm -rf $tmp_dir

#!/bin/bash
#
# Script to create Mini Project web server through Chef
#
# Environment Variables
CHEFHOME=$HOME/chef-repo
COOKBOOK=mini-project
THISNODE=node1
CHEFSERVER="ec2-52-10-6-29.us-west-2.compute.amazonaws.com"

USAGE="$0 [-h|--help] [-n|--node=nodename] [-s|--server=chefServer]\n \
         -h|--help:  print help message\n \
         -n=|--node=nodename:  The Chef Node name, nodename, for this node\n \
         -s|--server=servername:  The Chef Server, servername, for this Chef Client"

# Parse command line arguments
for key in "$@"
do
  case $key in
    -h|--help)
      echo "help found"
      echo -e "$USAGE"
      exit 0
      ;;
    -n=*|--node=*)
      THISNODE=`echo $key | sed 's/[-a-zA-Z0-9]*=//'`
      ;;
    -s=*|--server=*)
      CHEFSERVER=`echo $key | sed 's/[-a-zA-Z0-9]*=//'`
      ;;
    *)
      echo "Unknow Argument"
      echo -e "$USAGE"
      exit 1
      ;;
  esac
done

# Check Parameters
while ! [ -d "$CHEFHOME" ]
do
  echo "Chef Local Cookbooks directory $CHEFHOME does not exist!"
  echo "Please enter the Chef local cookbooks parent directory"
  read CHEFHOME
done

while ! [ "`knife node list | grep $THISNODE`" ]
do
  echo "Nodename $THISNODE is not known by Chef Server!"
  echo "Please enter the Chef Server Nodename for this node"
  read THISNODE
done

# Create Chef Cookbook
cd $CHEFHOME
knife cookbook create mini-project

# Create Chef Recipe
cd $CHEFHOME/cookbooks/$COOKBOOK/recipes
cat << E-O-F >>$CHEFHOME/cookbooks/$COOKBOOK/recipes/default.rb
package 'httpd' do
  action :install
end

service 'httpd' do
  action [ :enable, :start ]
end

cookbook_file '/var/www/html/index.html' do
  source 'index.html'
  mode '0644'
end

cookbook_file '/var/www/index.html' do
  source 'index.html'
  mode '0644'
end
E-O-F

# Create the defult display file
cat << E-O-F >$CHEFHOME/cookbooks/$COOKBOOK/files/default/index.html
<html>
<body>
  <font size="+4"><font color="#7F5DAE">
    <h1>Automation for the People!</h1>
  </font></font>
</body>
</html>
E-O-F

# Upload Cookbook to Chef Server
cd $CHEFHOME
knife cookbook upload mini-project

# Load Cookbook into this node
knife node run_list add node 'mini-project'
ssh sudo chef-client

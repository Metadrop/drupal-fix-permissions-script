# Script to fix permissions in a Drupal installation

This script sets the permissions and ownership of the files of a Drupal
installation.

This is loosely based on the information provided by Drupal documentation page
"[Securing file permissions and ownership](https://www.drupal.org/node/244924)".

## Details

For security reasons, the code files of a website should not be writable. At the
same time, the website should be able to create files (for example, when a user
uploads an image). This means that there two types of files and folders: content
and code.

There will be two users involved: a regular UNIX user, we'll call they the
deploy user, that is in charge of managing the code (typically deploying new
releases), and the user under which the web server process is running.

This scripts tries to secure the site using the following scheme:

  - Code is owned by the deploy user and by the web server's
    group. Deploy user can write, web server group only read.

  - Content is owned using the same scheme but the web server can write as well.


## Installation

Clone or donwload the repository content to your server.

Link to `drupal_fix_permissions.sh` in the `/usr/local/bin` or another folder present in users's PATH.

If you are using `autofix-drupal-perms.sh`, link it as well. Because it expects `drupal_fix_permissions.sh` to be at `/usr/local/bin` make sure that path exists or edit the autofix script.

If required, edit your sudo configuration to allow users to run `drupal_fix_permissions.sh` as root.


## Usage

Check the script help for details in usage:

```
drupal_fix_permissions.sh -h
```

The script should be run as root because it needs to change ownership and only
root can do this freely.

Example:
```
drupal_fix_permissions.sh -u=deploy
```

This will fix the permissions of a Drupal installation located in the current
folder and using `deploy` as the deploy user.


## Strategy

The scripts checks if the target folder is a Drupal installation and stops if
it is not detected.

Once checked, it fixes the ownership of all folder and files (because it is the
same for content and code). Then, it fixes the code and later the content.

The script assumes that `files` and `private` folders under `sites` are content
folders.

If there are content folders outside the Drupal root folder you can use the
`--files-path` option and the script will take care of it.

## Performance

The script only changes the files and folder with the wrong permissions or
ownership, making it very fast when only a few files or folders need a fix. For
really big installations this is very important as other scripts apply the
permissions and ownership regardless are needed o not.

## Root permissions

Giving root permissions to regular user is dangerous. Luckily, there's a simple
script, `autofix-drupal-perms.sh`, to allow regular users fix their sites
without risking the security.

This script has no parameters, so it can be easily added to the sudoers. When
run, it calls the main script with predefined parameters:

  - deploy user: the owner of the current folder
  - additional content folders: ../private and ../private-files

The script is an example, you can customize it for your hosting needs.

This repository also includes a sudoers file example to allow user to run the
script using sudo.

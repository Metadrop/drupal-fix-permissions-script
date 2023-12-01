# Script to fix permissions in a Drupal installation

This script sets the permissions and ownership of the files of a Drupal
installation.

This is loosely based on the information provided by the Drupal documentation page
"[Securing file permissions and ownership](https://www.drupal.org/node/244924)".

## Details

For security reasons, the code files of a website should not be writable. At the
same time, the website should be able to create files (for example, when a user
uploads an image). This means that there are two types of files and folders: content
and code.

There will be two users involved: a regular UNIX user, we'll call them the
deploy user, that is in charge of managing the code (typically deploying new
releases), and the user under which the web server process is running.

This script tries to secure the site using the following scheme:

  - Code is owned by the deploy user and by the web server's
    group. Deploy user can write, web server group only read.

  - Content is owned using the same scheme but the web server can write as well.

  - Other users have no permissions on content or code.


In UNIX terms:

|                     |  Symbolic notation |  Numeric notation | ls notation  |
|-------------------- |------------------- |------------------ |------------- |
| **Code folders**    |    `u=rwx,g=rx,o=` |            `0750` |  `rwxr-x---` |
| **Code files**      |      `u=rw,g=r,o=` |            `0640` |  `rw-r-----` |
| **Content folders** |   `u=rwx,g=rwx,o=` |            `0770` |  `rwxrwx---` |
| **Content files**   |         `ug=rw,o=` |            `0660` |  `rw-rw----` |



## Installation

Clone or download the repository content to your server.

Link to `drupal_fix_permissions.sh` in the `/usr/local/bin` or another folder present in the user's PATH.

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

The script checks if the target folder is a Drupal installation and stops if
it is not detected.

Once checked, it fixes the ownership of all folders and files (because it is the
same for content and code). Then, it fixes the code and later the content.

The script assumes that `files` and `private` folders under `sites` are content
folders.

If there are content folders outside the Drupal root folder you can use the
`--files-path` option and the script will take care of it.

## Vendor folder

If a `vendor` folder and a `composer.json` file are detected in the parent
folder of the Drupal root the script assumes the `vendor` folder is a code
folder and fixes permissions accordingly: it fixes ownership (owner: deploy
user, group: web server) and removes any permissions for other users.

It doesn't apply standard permissions of code files because in `vendor` folders
some files need to be executable. It would be hard to detect all
the cases that need executable permissions so the script doesn't handle
permissions for the owner or the group and just removes all permissions for
other users.

In case of issues in the `vendor` folder, because the the script fixes ownership
on the `vendor` folder, the deploy user should able to run `composer
install` and let composer set the correct permissions. Later, the script can be
run again to remove all permissions on other users.

## Performance

The script only changes the files and folders with the wrong permissions or
ownership, making it very fast when only a few files or folders need a fix. For
really big installations this is very important as other scripts apply the
permissions and ownership regardless are needed o not.

## Root permissions

Giving root permissions to regular users is dangerous. Luckily, there's a simple
script, `autofix-drupal-perms.sh`, to allow regular users to fix their sites
without risking the security.

This script has no parameters, so it can be easily added to the sudoers. When
run, it calls the main script with predefined parameters:

  - deploy user: the owner of the current folder
  - additional content folders: ../private and ../private-files

The script is an example, you can customize it for your hosting needs.

This repository also includes a sudoers file example to allow users to run the
script using sudo.

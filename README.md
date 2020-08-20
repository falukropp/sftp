# SFTP
| ![OpenSSH logo](https://github.com/satyadeep/sftp/blob/alpine/openssh.png?raw=true "Powered by OpenSSH") | ![mysecureshell logo](https://mysecureshell.readthedocs.io/en/latest/_images/logo_mss_large.png "Powered by mysecureshell")  |  ![rsyslog logo](https://avatars3.githubusercontent.com/u/6178456?s=200&v=4 "Powered by rsyslog") |
|---|---|---|

**Note:** Please use the branches as per your requirements

>***mss-logging***  :   Use this branch if you require the additional configuration options of mysecureshell as well as access logs using rsyslog.   **<-------- You are now looking at this branch**
>
>***alpine***                             :            Use this branch if you just need the SFTP functionality powered by OpenSSH.
>
>***logging***                           :            Use this branch if you need all access logs of users and directories along with SFTP functionality.
>
>***mysecureshell***              :            Use this branch of you need the additional configuration provided by mysecureshell but don't need the access logs.

---

Forked from [atmoz/sftp](https://github.com/atmoz/sftp) to support user-owned base directories.

This image changes the ownership of the directories under each user's home directory to be the SFTP user whose home directory they are in. In the atmoz/sftp image, the first created SFTP user (when there are multiple users) is the owner of all the directories under all users' home directories, which makes it unusable when not using a volume.

It also includes MySecureShell which allows more control over the user access and shared directories through a configuration file.

Another addition to this image is rsyslog for logging the access events of SFTP like, user login and logout as well as other events like directory creation, deletion etc.

# Securely share your files

Easy to use SFTP ([SSH File Transfer Protocol](https://en.wikipedia.org/wiki/SSH_File_Transfer_Protocol)) server with [OpenSSH](https://en.wikipedia.org/wiki/OpenSSH).

# MySecureShell for more control
MySecureShell is a solution which has been made to bring more features to sftp/scp protocol given by OpenSSH. By default, OpenSSH brings a lot of liberty to connected users which imply to trust in your users. The goal of MySecureShell is to offer the power and security of OpenSSH, with enhanced features (like ACL) to restrict connected users.

# Rsyslog for event logging
Rsyslog is a **r**ocket-fast **sys**tem for **log** processing.

It offers high-performance, great security features and a modular design. While it started as a regular syslogd, rsyslog has evolved into a kind of swiss army knife of logging, being able to accept inputs from a wide variety of sources, transform them, and output to the results to diverse destinations.

# Usage

- Define users in (1) command arguments, (2) `SFTP_USERS` environment variable
  or (3) in file mounted as `/etc/sftp/users.conf` (syntax:
  `user:pass[:e][:uid[:gid[:dir1[,dir2]...]]] ...`, see below for examples)
  - Set UID/GID manually for your users if you want them to make changes to
    your mounted volumes with permissions matching your host filesystem.
  - Directory names at the end will be created under user's home directory with
    write permission, if they aren't already present.
- Mount volumes
  - The users are chrooted to their home directory, so you can mount the
    volumes in separate directories inside the user's home directory
    (/home/user/**mounted-directory**) or just mount the whole **/home** directory.
    Just remember that the users can't create new files directly under their
    own home directory, so make sure there are at least one subdirectory if you
    want them to upload files.
  - For consistent server fingerprint, mount your own host keys (i.e. `/etc/ssh/ssh_host_*`)

# Examples

## Simplest docker run example

```
docker run -p 22:22 -d satyadeep/sftp foo:pass:::upload
```

User "foo" with password "pass" can login with sftp and upload files to a folder called "upload". No mounted directories or custom UID/GID. Later you can inspect the files and use `--volumes-from` to mount them somewhere else (or see next example).

## Sharing a directory from your computer

Let's mount a directory and set UID:

```
docker run \
    -v /host/upload:/home/foo/upload \
    -p 2222:22 -d satyadeep/sftp \
    foo:pass:1001
```

### Using Docker Compose:

```
sftp:
    image: satyadeep/sftp
    volumes:
        - /host/upload:/home/foo/upload
    ports:
        - "2222:22"
    command: foo:pass:1001
```

### Logging in

The OpenSSH server runs by default on port 22, and in this example, we are forwarding the container's port 22 to the host's port 2222. To log in with the OpenSSH client, run: `sftp -P 2222 foo@<host-ip>`

## Store users in config

```
docker run \
    -v /host/users.conf:/etc/sftp/users.conf:ro \
    -v mySftpVolume:/home \
    -p 2222:22 -d satyadeep/sftp
```

/host/users.conf:

```
foo:123:1001:100
bar:abc:1002:100
baz:xyz:1003:100
```

Another Example (Using bind mounts):

```
docker run \
    -v /host/users.conf:/etc/sftp/users.conf:ro \
    -v /host/keys/key_sftp_one.pub:/home/sftpuserone/.ssh/keys/key_sftp_one.pub
    -v /host/webroot/sftppassone:/home/sftpuserwithpasswordone/testpassone/sftppassone
    -p 2222:22 -d satyadeep/sftp
```

/host/users.conf:

```
sftpuserone::::sshuserone
sftpuserwithpasswordone:$1$LKnsymeQ$iwJOMs4P0/jifynOKyK0E/:e:::passworduserone
```

## Example Configuration File for mysecureshell

***Note*** This configuration file is optional and can be used if you'd like to configure various additional rules for the users and directory access, as shown below.

/host/sftp_config:

```
#Default rules for everybody
<Default>
	GlobalDownload			5m	#total speed download for all clients
							# o -> bytes   k -> kilo bytes   m -> mega bytes
	GlobalUpload			0	#total speed download for all clients (0 for unlimited)
	Download 				500k	#limit speed download for each connection
	Upload 					0	#unlimit speed upload for each connection
	StayAtHome				true	#limit client to his home
	VirtualChroot			true	#fake a chroot to the home account
	LimitConnection			10	#max connection for the server sftp
	LimitConnectionByUser	1	#max connection for the account
	LimitConnectionByIP		6	#max connection by ip for the account
#	LogLevel				5
	LogSyslog				true
	Home					/home/$USER	#overwrite home of the user but if you want you can use
							#	environment variable (ie: Home /home/$USER)
	IdleTimeOut				5m	#(in second) deconnect client is idle too long time
	ResolveIP				true	#resolve ip to dns
	IgnoreHidden			true	#treat all hidden files as if they don't exist
	DirFakeUser				true	#Hide real file/directory owner (just change displayed permissions)
	DirFakeGroup			true	#Hide real file/directory group (just change displayed permissions)
#	DirFakeMode				0400	#Hide real file/directory rights (just change displayed permissions)
							#Add execution right for directory if read right is set
	HideNoAccess			true	#Hide file/directory which user has no access
#	MaxOpenFilesForUser		20	#limit user to open x files on same time
#	MaxWriteFilesForUser	10	#limit user to x upload on same time
#	MaxReadFilesForUser		10	#limit user to x download on same time
	DefaultRights			0640 0775	#Set default rights for new file and new directory
#	MinimumRights			0400 0700	#Set minimum rights for files and dirs

	ShowLinksAsLinks		false	#show links as their destinations
#	ConnectionMaxLife		1d	#limits connection lifetime to 1 day

#	Charset					"ISO-8859-15"	#set charset of computer
</Default>

<Group group_1010>      # This will apply to only users of grop 1010
	CanChangeRights 		true		#able to make changes on files and directories
	Shell 					/bin/sh
	LogSyslog				true
	IsAdmin					true		#can admin the server
	Home					/home
	VirtualChroot			true
	StayAtHome				false
</Group>
```

Refer to the [official documentation](https://mysecureshell.readthedocs.io/en/latest/configuration_detailed.html)  for more configuration options.

To use the *mysecureshell* configuration, mount the configuration file to /etc/ssh/sftp_config as shown below.
```
docker run \
    -v <host-dir>/sftp_config.conf:/etc/ssh/sftp_config:ro \
    -v <host-dir>/users.conf:/etc/sftp/users.conf:ro \
    -v <host-dir>/keys/key_sftp_one.pub:/home/sftpuserone/.ssh/keys/key_sftp_one.pub
    -v <host-dir>/webroot/sftppassone:/home/sftpuserwithpasswordone/testpassone/sftppassone
    -p 2222:22 -d satyadeep/sftp
```

## Encrypted password

Add `:e` behind password to mark it as encrypted. Use single quotes if using terminal.

```
docker run \
    -v <host-dir>/share:/home/foo/share \
    -p 2222:22 -d satyadeep/sftp \
    'foo:$1$0G2g0GSt$ewU0t6GXG15.0hWoOX8X9.:e:1001'
```

Tip: you can use [atmoz/makepasswd](https://hub.docker.com/r/atmoz/makepasswd/) to generate encrypted passwords:  
`echo -n "your-password" | docker run -i --rm atmoz/makepasswd --crypt-md5 --clearfrom=-`

## Logging in with SSH keys

Mount public keys in the user's `.ssh/keys/` directory. All keys are automatically appended to `.ssh/authorized_keys` (you can't mount this file directly, because OpenSSH requires limited file permissions). In this example, we do not provide any password, so the user `foo` can only login with his SSH key.

```
docker run \
    -v <host-dir>/id_rsa.pub:/home/foo/.ssh/keys/id_rsa.pub:ro \
    -v <host-dir>/id_other.pub:/home/foo/.ssh/keys/id_other.pub:ro \
    -v <host-dir>/share:/home/foo/share \
    -p 2222:22 -d satyadeep/sftp \
    foo::1001
```

## Providing your own SSH host key (recommended)

This container will generate new SSH host keys at first run. To avoid that your users get a MITM warning when you recreate your container (and the host keys changes), you can mount your own host keys.

**NOTE:** Be sure to generate keys with no passphrase, or they will not be loaded properly when the container starts.

```
docker run \
    -v <host-dir>/ssh_host_ed25519_key:/etc/ssh/ssh_host_ed25519_key \
    -v <host-dir>/ssh_host_rsa_key:/etc/ssh/ssh_host_rsa_key \
    -v <host-dir>/share:/home/foo/share \
    -p 2222:22 -d satyadeep/sftp \
    foo::1001
```

Tip: you can generate your keys with these commands:

```
ssh-keygen -t ed25519 -f ssh_host_ed25519_key < /dev/null
ssh-keygen -t rsa -b 4096 -f ssh_host_rsa_key < /dev/null
```

## See user access logs
All the user logs (User login/logout and directory/file operations like creation/deletion/renaming of files) will be added to the container logs and can be checked using

```docker container logs sftp-container-name```

## Execute custom scripts or applications

Put your programs in `/etc/sftp.d/` and it will automatically run when the container starts.
See next section for an example.

## Bindmount dirs from another location

If you are using `--volumes-from` or just want to make a custom directory available in user's home directory, you can add a script to `/etc/sftp.d/` that bindmounts after container starts.

```
#!/bin/bash
# File mounted as: /etc/sftp.d/bindmount.sh
# Just an example (make your own)

function bindmount() {
    if [ -d "$1" ]; then
        mkdir -p "$2"
    fi
    mount --bind $3 "$1" "$2"
}

# Remember permissions, you may have to fix them:
# chown -R :users /data/common

bindmount /data/admin-tools /home/admin/tools
bindmount /data/common /home/dave/common
bindmount /data/common /home/peter/common
bindmount /data/docs /home/peter/docs --read-only
```

**NOTE:** Using `mount` requires that your container runs with the `CAP_SYS_ADMIN` capability turned on. [See this answer for more information](https://github.com/atmoz/sftp/issues/60#issuecomment-332909232).


# What version of OpenSSH do I get?

You can see what version you get by checking the Alpine's packages online:

- [List of `openssh` packages on Alpine releases](https://pkgs.alpinelinux.org/packages?name=openssh&branch=&repo=main&arch=x86_64)

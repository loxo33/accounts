# Shell accounts IRC users. 
define accounts::user (
  $ensure 	 = present,
  $username 	 = $title, 
  $password 	 = undef, 
  $shell 	 = '/bin/bash', 
  $home_dir 	 = "/home/${title}", 
  $create_group  = false, 
  $system 	 = false, 
  $uid 		 = undef,
  $gid 		 = undef,
  $ssh_key 	 = undef, 
  $ssh_key_type  = 'ssh-rsa', 
  $groups 	 = [], 
  $comment 	 = undef, 
  $sudo_priority = undef, 
  $sudo_content  = undef,
  $custom_vimrc  = false,
  $custom_bashrc = false,
) {
# Realize user and corresponding files.
  User <| title == $username |> -> File <| tag == 'userdata' |>

  @user {
    $title:
      ensure     	=> $ensure,
      name       	=> $username,
      password   	=> $password,
      shell      	=> $shell,
      comment	   	=> $comment,
      uid        	=> $uid,
      gid        	=> $gid,
      groups     	=> $groups,
      home       	=> $home_dir,
      managehome 	=> true,
      system     	=> $system,
      purge_ssh_keys	=> true,
    }
# If a user hasn't set a password, we expire the password and delete the default password.
# This will prompt the user to set a password the next time they log in (ssh key required).
    if $password == undef {
	exec { "passwd -ed $username":
		path	=> ["/usr/bin", "/usr/sbin", "/bin"],
		onlyif	=> "grep '[^!]![^!]' /etc/shadow | grep ${username}"
	}
    }
## file logic to delete user files if the user has been deleted from the system
  case $ensure {
    present:  {$home_enabled = "present" }
    disabled: {$home_enabled = "present" }
    absent:   {$home_enabled = "absent" }
  }

## Home Directory
  @file { "$home_dir":
    ensure      => directory,
    force	=> 'true',
    owner       => "$username",
    group       => "$username",
    mode        => "0750",
    tag		=> "userdata",
  }
## Manage SSH keys in hiera. 
  $ssh_key_array = hiera_hash("accounts::${username}::sshkeys")
  create_resources(ssh_authorized_key, $ssh_key_array)

## .vimrc file
  if $custom_vimrc == true {
    @file { "$home_dir/.vimrc":
	ensure	=> $home_enabled,
        owner   => "$username",
        group   => "$username",
        mode    => "0644",
        content => template("accounts/${username}_vimrc.erb"),
        tag	=> "userdata",
    }
  }

## .bashrc file.
  if $custom_bashrc == 'true' {
    $bashrc_template = "${username}_bashrc.erb"
  }
  else {
    $bashrc_template = "default_bashrc.erb"
  }

  @file { "$home_dir/.bashrc":
    ensure      => $home_enabled,
    owner       => "$username",
    group       => "$username",
    mode        => "0644",
    content     => template("accounts/$bashrc_template"),
    tag		=> "userdata",
  }
}

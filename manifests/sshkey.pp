class accounts::sshkey {


 #   ssh_authorized_key {
 #     $title:
 #       ensure  => $home_enabled,
 #       type    => $ssh_key_type,
 #       name    => "${username} SSH Key",
 #       user    => $username,
 #       key     => $ssh_key,
 #       require => File[$home_dir],
 #       tag    => "userdata",
 #   }


    $ssh_key_array = hiera_array("accounts::${username}::sshkeys")
    create_resources(ssh_authorized_key, $ssh_key_array)
}

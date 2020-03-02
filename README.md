# Rails Service Tasks
Make it easy to install and run your rails app as linux service.

Supported platforms:
- systemd (Ubuntu)

## Integrate into your rails app
Copy the files inside of `lib/taks/*` into the same folder of your rails project.

Then apply your custom settings in its `rails_service_tasks_config.yml`.

That's it! Integration in your rails app is done!

## Install as service or run manually
You can install your rails app as service, so it will be restarted automatically after reboot.

Otherwise you will have to restart your app manually after reboot.

### Install as service
Run as root (prefix the command with `rvmsudo` instead of `sudo` if using rvm)
```
rake install_service
```

## Commands
```
rake start              # start server"
rake stop               # stop server"
rake restart            # run stop and start"
rake status             # check if server is running"
rake install_service    # install as systemd service"
rake uninstall_service  # uninstall as systemd service"
```

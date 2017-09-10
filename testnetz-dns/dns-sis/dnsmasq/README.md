# docker-dnsmasq

This project permit to use dnsmasq under a docker container.
The dnsmasq configuration could be update after container.
The container is base on [docker-base](https://github.com/fferriere/docker-base) container.

## Installation

To install this container clone the repository run `dnsmasq.sh build` to build container.
You can customize image's name with `FFERRIERE_DNSMASQ_IMAGE` variable.
Example :
```
$ FFERRIERE_DNSMASQ_IMAGE='prefix/dnsmasq' ./dnsmasqh.sh build
```

You can edit dnsmasq config after run container. You do run `dnsmasq.sh reload` or `touch path_dnsmasq/reload` file. By default `path_dnsmasq` is `dnsmasq` folder of this project. You can change it with `-s|--src option` of `dnsmasq.sh`

For systemd user it's possible to run `sudo dnsmasq.sh install`. Run `sudo systemctl enable docker-dnsmasq` for run container at boot.

## Use

The `dnsmask.sh` script permit to run,stop,... container or reload configuration.
You can customize container's name with `FFERRIERE_DNSMASQ_NAME` variable.
Example:
```
$ FFERRIERE_DNSMASQ_NAME='prefix-dnsmasq' ./dnsmasq.sh run
```

Read the `./dnsmasq.sh help` content to use the script :
```
$ ./dnsmasq.sh help
run.sh [CMD] [OPTIONS]
      use FFERRIERE_DNSMASQ_IMAGE to customize container image's name
      use FFERRIERE_DNSMASQ_NAME to customize container's name
      use FFERRIERE_DNSMASQ_CNF to customize dnsmasq configuration directory
CMD:
  build   to build container (you can use docker build options after --)
  stop    to stop container
  rm      to remove container
  stop-rm to stop and remove contaier
  resolv  to modify resolv.conf file with ip address of dnsmasq container
  help    to show this message
  install to install container at boot with systemd, you must to run this command with root or with sudo
  uninstall to uninstall container at boot, you must to run this command with root or sudo
  run     to start the container
    [OPTIONS]:
      -f | --fg   to run container on foreground (default is deamon run)
      -s | --src  to give the dnsmasq folder link with /etc/dnsmasq on container (this option override FFERRIERE_DNSMASQ_CNF)
  dry-run generate the docker run command and show it
  reload  to reload the dnsmasq configuration
    you can use -s | --src option with this command as with run command
```

## Thanks

Thanks to creator of dnsmasq and to Pascal Martin (@pmartin (on github) and @pascal_martin (on twitter)) with his [presentation](http://blog.pascal-martin.fr/public/slides-tea-dnsmasq/)

## Magic examples

```
$ export FFERRIERE_DNSMASQ_IMAGE='my-company/dnsmasq-for-containers'
$ ./dnsmasq.sh build # not run each time, only first time
$ export FFERRIERE_DNSMASQ_NAME='my-company-dnsmasq-for-containers'
$ export FFERRIERE_DNSMASQ_CNF='/path/of/config/for/containers'
$ ./dnsmasq.sh run
$ docker run --rm -ti --dns=$(docker inspect -f "{{.NetworkSettings.IPAddress}}" $FFERRIERE_DNSMASQ_NAME) fferriere/base /bin/bash
```

This example run a dnsmasq container with particular informations. Run a second container with dnsmasq IP on dns for the new container.

# Host Status

This project does a few things to visually represent host statuses.
- Takes in a phpipam text hostdump file as an command line argument
- Processes the file and performs an ansible ping, checks ssh, and checks ping on all hosts in a 10.40.0.0/8 range (hard coded, could later be parameterized)
- Writes those results to an html for viewing
- Starts a very light weight python BaseHTTPServer to serve the html file

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for use, development, and or testing purposes.

### Prerequisites

You will want fping if you have a lot of servers. It will ping much faster.

Use your OS's package manager:
```
yum install fping

#OR

apt install fping
```

### Installing

First clone the repository to a directory of your choice:

```
git clone https://github.com/histamineblkr/HostStatus.git
```

Prepare a hostfile dump from phpipam. Go to:

```
Administration -> phpIPAM settings -> Import / Export
```

and then click the "Prepare hostfile dump" button. Save the file to the `files/` directory.

Run the host-status script. This can take a very long time depending on how many hosts you have.
```
bash host-status file/phpipam_hosts_<date>
```

Next, start the python BaseHTTPServer.

```
python bin/host-serve.py
```

Access the server from the url: `localhost:8080`.

If you would like to control the python BaseHTTPServer with systemd, create this file in `/usr/lib/systemd/system/py-http-server.service`:

```
[Unit]
Description = Creates a small python http server to serve up host statuses
After = network.target
[Service]
ExecStart = <path_to>/host_status/bin/host-serve.py
[Install]
WantedBy = multi-user.target
```
make sure to change "ExecStart" to the absolute path to the host-serve.py file in the repo you cloned earlier.

If you want the service enabled at boot:

```
systemctl enable py-http-server
```

Start the service:

```
systemctl start py-http-server
```

Access the server from the url: `localhost:8080`.

## Testing or Debugging

Run with the following flags

```
bash host-status -d files/phpipam_hosts_<date>
```

The following structure and files are created with debug on (logging):
```
BASE_DIR/
├── bin
│   ├── host-serve.py
│   └── it-host-status.sh
├── files
│   └── phpipam_hosts_<date>
├── host-status
├── host-status.html
├── log
│   ├── found-ansible.log
│   ├── ipam-10.40-display.txt
│   ├── ipam-10.40-work.txt
│   ├── ips.txt
│   ├── notfound-ansible.log
│   ├── ping-out.log
│   ├── successful-ansible-hosts.log
│   └── successful-ssh-hosts.log
└── scripts
    ├── clean-host-output.awk
    └── host-html.awk
```

## Authors

- **Brandon Authier** - *Initial work* - [HostStatus](https://github.com/histamineblkr/HostStatus.git)

See also the list of [contributors](https://github.com/histamineblkr/HostStatus/graphs/contributors) who participated in this project.

## License

This project is licensed under the GPLv3 License.

## Acknowledgments

* Open source
* Morris Bernstein - [email](mailto:morris@systems-deployment.com): idea of a python http server came from his timeserver example he had for UW CSS 390 course
* 42

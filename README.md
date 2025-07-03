# Slurm-Development-Environment
  
Development Environment (noun)
1. A workspace with a set of processes and programming tools used to develop software
  

---
### Design
My development environment is designed with the objectives of reducing the time and complexity of managing multiple Slurm versions on a local machine. It relies heavily upon `make` as an interface for interacting with and managing a local Slurm environment.
  
### Structure
This repository contains a `Makefile`, as well as a series of templates that are used to manage and construct Slurm environments.
  
The environment itself resides in `$HOME/slurm/` follows the following structure for each version:
```
25.05
├── $hostname
│   ├── bin
│   ├── build
│   ├── etc
│   ├── include
│   ├── lib
│   ├── log
│   ├── run
│   ├── sbin
│   ├── share
│   ├── spool
│   └── state
└── slurm
    ├── auxdir
    ├── CHANGELOG
    ├── contribs
    ├── debian
    ├── doc
    ├── etc
    ├── slurm
    ├── src
    ├── testsuite
    └── tools
```
Of note:
* `25.05/slurm` - Source directory, contains the Slurm repository checked out to the proper version
* `25.05/$hostname` - host-specific directory, where Slurm is built and installed for this specific host
* `25.05/$hostname/build` - Where Slurm is built
* `25.05/hostname/bin`, `etc`, `log`, `run`, etc. - Where this version of Slurm is installed and configured
  
### Use
The `Makefile` provides many targets identified by verbs with which to interact with the Slurm environments. These are generally self explanatory. For most commands you will need to specify `version=XX.XX`, and for configuration commands you may also need to also specify `dbdpass=`.
  
Before running `create`, `build`, or other verbs associated with building Slurm, your system should be up to date and have the proper versions of [Slurm's dependencies](https://slurm.schedmd.com/quickstart_admin.html#prereqs) installed. Reference the official document linked above for the most up-to-date, system-agnostic requirements, or the provided `requirements` for the requirements for compiling for Fedora 42 with cgroups support.
  
Verbs that act on environments:
* create
* clone
* build
* install
* configure_env
  
Verbs that act on Slurm installations within an environment:
* start
* stop
* slurmctld_log
* slurmdbd_log
* scontrol_reconfigure
* ping
* restart
* reconfigure
* clean
* configure_slurm
  
Verbs related to tests:
* test
* globals
* regression
* configure_tests
  
The use pattern is:
```
make <TARGET> version=25.05 dbdpass=$dbdpass nodecnt=5
```
Where version is usually specified and dbdpass or nodecnt are specified only as needed.

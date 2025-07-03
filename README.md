# Slurm-Development-Environment
  
Development Environment (noun)
1. A workspace with a set of processes and programming tools used to develop software
  

---
### Design
My development environment is designed with the objectives of reducing the time and complexity of managing multiple Slurm versions on a local machine. It relies heavily upon `make` as an interface for interacting with and managing a local Slurm environment.
  
### Structure
This repository contains a `Makefile`, as well as a series of templates that are used to manage and construct Slurm environments.
  
### Use
The `Makefile` provides many targets identified by verbs with which to interact with the Slurm environments. These are generally self explanatory. For most commands you will need to specify `version=XX.XX`, and for configuration commands you may also need to also specify `dbdpass=`.
  
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

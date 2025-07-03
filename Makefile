# Makefile for managing a local Slurm Development Environment
# Currently this will only run when executed out of /home/user/slurm
.PHONY: create start configure_env configure_slurm configure_tests clone build install stop slurmctld_log slurmdbd_log ping restart reconfigure test globals regression

# If a nodecount is not provide for the start command, default to 5 nodes
ifndef nodecnt
nodecnt := 5
endif

# If a dbd password is not provided, try "password"
ifndef dbdpass
dbdpass := "password"
endif

# If version is not specified, warn
ifndef version
$(warning "WARNING: Version not specified")
endif

port:=$(shell echo $$((16999 + $(nodecnt) )))

# Create a folder structure for a new release
create: clone build install configure_env configure_slurm configure_tests

# Stop current environment, remove /spool and /log, and reconfigure
reconfigure: stop clean configure_slurm start scontrol_reconfigure

# Restart the cluster with a clean environment
restart: stop clean start

# Run all tests
test: globals regression

# Clone Slurm into the local environment
clone:
	# Create a directory for the version
	mkdir $(version)
	# Clone the SchedMD slurm repo into the version dir
	cd $(version) && git clone git@github.com:SchedMD/slurm.git
	# Checkout the proper branch for that version
	cd $(version)/slurm && git checkout slurm-$(version)
	# Make working directories for the current host
	mkdir $(version)/${HOSTNAME}
	mkdir $(version)/${HOSTNAME}/build

# Build Slurm in the local environment
build:
	cd $(version)/${HOSTNAME}/build && ../../slurm/configure --prefix=${HOME}/slurm/$(version)/${HOSTNAME} --enable-developer --enable-multiple-slurmd > /dev/null

# Install Slurm in the local environment
install:
	cd $(version)/${HOSTNAME}/build &&  make -j install >/dev/null
	cd $(version)/${HOSTNAME} && mkdir log run state etc spool

# Drop the environment file in place, filling in proper values
configure_env:
	cp templates/env $(version)
	sed -i 's|HOME|${HOME}|g' $(version)/env
	sed -i 's/VERSION/$(version)/g' $(version)/env
	sed -i 's/HOSTNAME/${HOSTNAME}/g' $(version)/env
	# Print a nice message for the user
	echo "$(version) initialized! Run 'source $(version)/env' to enter the environment"

# Template slurm.conf and slurmdbd.conf for the specified version
configure_slurm:
	# Set up Slurm.conf and slurmdbd.conf
	cp templates/slurm.conf $(version)/${HOSTNAME}/etc
	sed -i 's|HOME|${HOME}|g' $(version)/${HOSTNAME}/etc/slurm.conf
	sed -i 's/VERSION/$(version)/g' $(version)/${HOSTNAME}/etc/slurm.conf
	sed -i 's/HOSTNAME/${HOSTNAME}/g' $(version)/${HOSTNAME}/etc/slurm.conf
	sed -i 's/USER/${USER}/g' $(version)/${HOSTNAME}/etc/slurm.conf
	sed -i 's/NODECNT/$(nodecnt)/g' $(version)/${HOSTNAME}/etc/slurm.conf
	sed -i 's/PORT/$(port)/g' $(version)/${HOSTNAME}/etc/slurm.conf
	cp templates/slurmdbd.conf $(version)/${HOSTNAME}/etc
	sed -i 's|HOME|${HOME}|g' $(version)/${HOSTNAME}/etc/slurmdbd.conf
	sed -i 's/VERSION/$(version)/g' $(version)/${HOSTNAME}/etc/slurmdbd.conf
	sed -i 's/HOSTNAME/${HOSTNAME}/g' $(version)/${HOSTNAME}/etc/slurmdbd.conf
	sed -i 's/USER/${USER}/g' $(version)/${HOSTNAME}/etc/slurmdbd.conf
	sed -i 's/PASSWORD/$(dbdpass)/g' $(version)/${HOSTNAME}/etc/slurmdbd.conf
	-for i in `seq 1 $(nodecnt)`; do mkdir $(version)/${HOSTNAME}/spool/slurmd.n$$i; done;
	cp templates/cgroup.conf $(version)/${HOSTNAME}/etc

# Configure globals.local and globals.hostname
configure_tests:
	# Drop in globals.local and globals.hostname
	cp templates/globals.local $(version)/slurm/testsuite/expect
	cp templates/globals.hostname $(version)/slurm/testsuite/expect/globals.${HOSTNAME}
	sed -i 's/VERSION/$(version)/g' $(version)/slurm/testsuite/expect/globals.local
	sed -i 's|HOME|${HOME}|g' $(version)/slurm/testsuite/expect/globals.local
	sed -i 's/HOSTNAME/${HOSTNAME}/g' $(version)/slurm/testsuite/expect/globals.${HOSTNAME}
	cp templates/testsuite.conf $(version)/slurm/testsuite
	sed -i 's|HOME|${HOME}|g' $(version)/slurm/testsuite/testsuite.conf
	sed -i 's/VERSION/$(version)/g' $(version)/slurm/testsuite/testsuite.conf
	sed -i 's/HOSTNAME/${HOSTNAME}/g' $(version)/slurm/testsuite/testsuite.conf

# Start a cluster # TODO What if I did this with systemd?
#
# Usage: 
# make start version=24.05
start:
	# Start slurmdbd
	slurmdbd && sleep 1
	# Start slurmctld
	slurmctld && sleep 1
	# Start the nodes
	for i in `seq 1 $(nodecnt)`; do slurmd -N n$$i; done;
	# Check status
	scontrol ping

# Stop a cluster # TODO There is probably a cleaner way to do this
stop:
	# Stop the nodes
	pkill slurmd && sleep 2
	# Stop slurmctld
	pkill slurmctld && sleep 2
	# Stop slurmdbd
	-pkill slurmdbd && sleep 2

# Clear out /spool and /log directories
clean:
	rm -rf $(version)/${HOSTNAME}/spool/slurmd*
	rm -rf $(version)/${HOSTNAME}/spool/slurmctld/*
	rm -rf $(version)/${HOSTNAME}/log/*
	

# Display the slurmctld log for a specific version
slurmctld_log:
	tail -f $(version)/${HOSTNAME}/log/slurmctld.log

# Display the slurmdbd log for a specific version
slurmdbd_log:
	tail -f $(version)/${HOSTNAME}/log/slurmdbd.log

# Check scontrol status
ping:
	scontrol ping

# Reconfigure slurmctld
scontrol_reconfigure:
	scontrol reconfigure

# Run globals expect tests
globals:
	./$(version)/slurm/testsuite/expect/globals

# Run regression.py expect tests
regression:
	cd $(version)/slurm/testsuite/expect && ./regression.py

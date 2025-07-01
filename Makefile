# Makefile for managing a local Slurm Development Environment
# Currently this will only run when executed out of /home/user/slurm
.PHONY: create start

# If a nodecount is not provide for the start command, default to 5 nodes
ifndef nodecnt
nodecnt := 5
endif

# Create a folder structure for a new release
#
# Usage:
# make create version=24.05
create:
	# Create a directory for the version
	mkdir $(version)
	# Clone the SchedMD slurm repo into the version dir
	cd $(version) && git clone git@github.com:SchedMD/slurm.git
	# Checkout the proper branch for that version
	cd $(version)/slurm && git checkout slurm-$(version)
	# Make working directories for the current host
	mkdir $(version)/${HOSTNAME}
	mkdir $(version)/${HOSTNAME}/build
	# Build Slurm in the build directory
	cd $(version)/${HOSTNAME}/build && ../../slurm/configure --prefix=${HOME}/slurm/$(version)/${HOSTNAME} --enable-developer --enable-multiple-slurmd > /dev/null
	# Install slurm into the build directory
	cd $(version)/${HOSTNAME}/build &&  make -j install >/dev/null
	cd $(version)/${HOSTNAME} && mkdir log run state etc spool
	# Drop the environment file in place, filling in proper values
	cp env $(version)
	sed -i 's|HOME|${HOME}|g' $(version)/env
	sed -i 's/VERSION/$(version)/g' $(version)/env
	sed -i 's/HOSTNAME/${HOSTNAME}/g' $(version)/env
	# Set up Slurm.conf and slurmdbd.conf
	cp slurm.conf $(version)/${HOSTNAME}/etc
	sed -i 's|HOME|${HOME}|g' $(version)/${HOSTNAME}/etc/slurm.conf
	sed -i 's/VERSION/$(version)/g' $(version)/${HOSTNAME}/etc/slurm.conf
	sed -i 's/HOSTNAME/${HOSTNAME}/g' $(version)/${HOSTNAME}/etc/slurm.conf
	sed -i 's/USER/${USER}/g' $(version)/${HOSTNAME}/etc/slurm.conf
	cp slurmdbd.conf $(version)/${HOSTNAME}/etc
	sed -i 's|HOME|${HOME}|g' $(version)/${HOSTNAME}/etc/slurmdbd.conf
	sed -i 's/VERSION/$(version)/g' $(version)/${HOSTNAME}/etc/slurmdbd.conf
	sed -i 's/HOSTNAME/${HOSTNAME}/g' $(version)/${HOSTNAME}/etc/slurmdbd.conf
	sed -i 's/USER/${USER}/g' $(version)/${HOSTNAME}/etc/slurmdbd.conf
	# Drop in globals.local and globals.hostname
	cp globals.local $(version)/slurm/testsuite/expect
	cp globals.hostname $(version)/slurm/testsuite/expect/globals.${HOSTNAME}
	sed -i 's/VERSION/$(version)/g' $(version)/slurm/testsuite/expect/globals.local
	sed -i 's|HOME|${HOME}|g' $(version)/slurm/testsuite/expect/globals.local
	sed -i 's/HOSTNAME/${HOSTNAME}/g' $(version)/slurm/testsuite/expect/globals.${HOSTNAME}
	# Print a nice message for the user
	echo "$(version) initialized! Run 'source $(version)/env' to enter the environment"

# Start a cluster for a version of Slurm
#
# Usage: 
# make start version=24.05
start:
	# Start slurmdbd
	${HOME}/slurm/$(version)/${HOSTNAME}/sbin/slurmdb && sleep 1
	# Start slurmctld
	${HOME}/slurm/$(version)/${HOSTNAME}/sbin/slurmctld && sleep 1
	# Start the nodes
	for i in `seq 1 $(nodecnt)`; do ${HOME}/slurm/$(version)/${HOSTNAME}/sbin/slurmd -N n$$i; done;

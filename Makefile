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
	mkdir $(version)
	cd $(version) && git clone git@github.com:SchedMD/slurm.git
	cd $(version)/slurm && git checkout slurm-$(version)
	mkdir $(version)/${HOSTNAME}
	mkdir $(version)/${HOSTNAME}/build
	cd $(version)/${HOSTNAME}/build && ../../slurm/configure --prefix=${HOME}/slurm/$(version)/${HOSTNAME} --enable-developer --enable-multiple-slurmd > /dev/null
	cd $(version)/${HOSTNAME}/build &&  make -j install >/dev/null
	cd $(version)/${HOSTNAME} && mkdir log run state etc spool
	cp env $(version)
	sed -i 's|HOME|${HOME}|g' $(version)/env
	sed -i 's/VERSION/$(version)/g' $(version)/env
	sed -i 's/HOSTNAME/${HOSTNAME}/g' $(version)/env
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

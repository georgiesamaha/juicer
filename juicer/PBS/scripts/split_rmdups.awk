#!/usr/bin/awk -f
##########
#The MIT License (MIT)
#
# Copyright (c) 2015 Aiden Lab
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
##########

# Dedup script that submits deduping jobs after splitting at known
# non-duplicates
# Juicer version 1.5
echo "entering split_rmdups.awk"
BEGIN{
	print "entering begin split_rmdups.awk";
	tot=0;
	name=0;
}
{
	if (tot >= 1000000) {
		if (p1 != $1 || p2 != $2 || p4 != $4 || p5 != $5 || p8 != $8) {
			print "this is the beginging part of split rmdups awk";
			cmd=sprintf("qstat | grep osplit%s |cut -c 1-8 | cut -d '.' -f 1", groupname);
			print "weird stuff from here:";
			print cmd;
			cmd |& getline jID_osplit;
			sname=sprintf("%s_msplit%04d_", groupname, name);
			print sname;
			sysstring1=sprintf("qsub -A %s -l %s -o %s_%s.log -j oe -q %s -N DDuP%s%s -l select=1:ncpus=1:mem=4gb -W depend=afterok:%s <<-EOF\nawk -f  %s/scripts/dups.awk -v name=%s/%s %s/split%04d;\nEOF\n", project, walltime, outfile, sname, queue, name, groupname, jID_osplit ,juicedir, dir, sname, dir, name, dir, name);
			print sysstring1;
                        system(sysstring1);
			print "This is the command to cut:";
			cmd1echo=sprintf("qstat | grep DDuP%s%s ", name, groupname);
			print cmd1echo;
			cmd1=sprintf("qstat | grep DDuP%s%s | cut -d '.' -f 1 ",name,groupname);
			print cmd1;
			cmd1 |& getline jID;

			close(cmd1);
			if (name==0){
				waitstring=sprintf("%s",jID );
				waitstring2=sprintf("%s",jID)
			}
		  else {
				waitstring=sprintf("%s:%s",waitstring,jID);
				waitstring2=sprintf("%s %s",waitstring2,jID)
		  }

		  name++;
			tot=0;
		}
	}
	outname = sprintf("%s/split%04d", dir, name);
	print > outname;
	p1=$1;p2=$2;p4=$4;p5=$5;p6=$6;p8=$8;
	tot++;
}
END {
   	sname=sprintf("%s_msplit%04d_", groupname, name);
    print "This is the begining of END step, submitting _dedup job in END step";
	sysstring2=sprintf("qsub -A %s -l %s -l select=1:ncpus=1:mem=50gb -o %s_%s_dedup%s.log -j oe -q %s -N DDuP%s%s -W depend=afterok:%s <<-EOF\nawk -f %s/scripts/dups.awk -v name=%s/%s %s/split%04d;\nEOF\n", project, walltime, outfile, sname, name, queue, name, groupname, jID_osplit ,juicedir, dir, sname, dir, name, dir, name);
    	print sysstring2;
	system(sysstring2);

	#sname=sprintf("%s_msplit%04d_", groupname, name);
	#system(sysstring2);

	cmd2=sprintf("qstat | grep DDuP%s%s | cut -d '.' -f 1 ",name,groupname);
	print cmd2;
	cmd2 |& getline jID;
	close(cmd2);
	if ( name==0 ){
		waitstring=sprintf("%s",jID );
		waitstring2=sprintf("%s",jID);
	}
	else {
		waitstring=sprintf("%s:%s",waitstring,jID);
		waitstring2=sprintf("%s %s",waitstring2,jID);
	}
	cmd3=sprintf("qstat %s",waitstring2);
	print cmd3;
	cmd3 |& getline waitedjobstatus;
	close(cmd3)
	print "below is the waitingstring1 and waitingstring2";
	print waitstring;
	sysstring = sprintf("qsub -A %s -l %s -l select=1:ncpus=1:mem=50gb -o %s_catsplit.log -j oe -q %s -N CtSplt%s -W depend=afterok:%s <<-EOF\ncat %s/%s_msplit*_optdups.txt > %s/opt_dups.txt;  cat %s/%s_msplit*_dups.txt > %s/dups.txt; cat %s/%s_msplit*_merged_nodups.txt > %s/merged_nodups.txt; \nEOF\n", project, walltime, outfile, queue, groupname, waitstring, dir, groupname, dir, dir, groupname, dir, dir, groupname, dir, dir);
	print waitstring2;
	print "below is the waited job status before qsub"
	print waitedjobstatus;
	print "submitting _catsplit jobs";
	print sysstring;
	system(sysstring);
	cmd4=sprintf("qstat | grep CtSplt%s | cut -d '.' -f 1 ",groupname);
	print cmd4;
	cmd4 |& getline jID_catsplit;
	close(cmd4);
	print "below is the _catsplit id";
	print jID_catsplit;
	sysstring=sprintf("qsub -A %s -l %s -l select=1:ncpus=1:mem=50gb -o %s_rmsplit.log -j oe -q %s -N RmSplt%s -W depend=afterok:%s <<-EOF\n rm %s/*_msplit*_optdups.txt; rm %s/*_msplit*_dups.txt; rm %s/*_msplit*_merged_nodups.txt; rm %s/split*;\nEOF", project, walltime, outfile, queue, groupname,jID_catsplit, dir, dir, dir, dir);
	print "submitting _rmsplit jobs";
	print sysstring;
	system(sysstring);
	cmd=sprintf("qstat | grep RmSplt%s | cut -d '.' -f 1 ",groupname);
	print cmd;
	cmd |& getline jID_rmsplit;
	print "below is the jID_rmsplit:";
	print jID_rmsplit;
}
echo "Exiting split_rmdups.awk"

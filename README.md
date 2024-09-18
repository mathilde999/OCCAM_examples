This is a sum-up of different documents on how to use OCCAM and run snakemake pipelines. That's what worked in my case. If in doubt, I did it wrong
The aim is fully practical, if you are interested in the theorics of "Why are we doing that" please go to the original documents listed
OCCAM how to : https://c3s.unito.it/index.php/super-computer/occam-howto


# Before anything else: 
# 1. request an OCCAM account
use the following form, should be quite fast
https://c3s.unito.it/helpdesk/
# 2. Store your ssh key to gitlab
In order to log in to occam, it need to recognize the machine you are using to log in. 
First check if you already have a ["/home/{USER}/.ssh/id_rsa.pub"] file in your local machine. If not follow these instructions: 
https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent
Copy the ssh-key from:
```shell
cat /home/{USER}/.ssh/id_rsa.pub
```
go to https://gitlab.c3s.unito.it/ then from the personal menu, click on "Edit Profile" and then on "SSH Keys" on the lateral menubar

# 3. login to OCCAM
You should now be able to login to occam
```shell
ssh {USER}@occam.c3s.unito.it # running occam-login is not necessary anymore
```

# I. Create an image locally on push it to your gitlab repository
### 1. Build a dockerfile
For training purpose I suggest to clone the following git repo and used the dockerfile from there
```shell
git clone git@gitlab.c3s.unito.it:bagnasco/docker-example.git
cd docker-example/
```
You can also write your own dockerfile. You can see an example of mine in the Dockerfiles folder of this repo (to be updated)
### 2. Build the image from a dockerfile
You have to use a tag that includes the final gitlab repository
```shell
docker build -t gitlab.c3s.unito.it:5000/{USER}/{PROJECT}/{image_name}:{tag} . # the tag is not mandatory. It can be the version number for example
```
You can also define the specific dockerfile to use that way 
```shell
docker build -t gitlab.c3s.unito.it:5000/mandre/{USER}/{image_name}:{tag}  - < Dockerfile
```
### 3. Run the container on your desktop/laptop to see docker in action:
```shell
docker run -ti --rm --volume ${PWD}:${PWD} --workdir ${PWD} gitlab.c3s.unito.it:5000/mandre/{USER}/{image_name}:{tag}
```
### 4. Upload the image to your gitlab repository
**A.** Login to the GitLab repository, using your OCCAM username and password. If that's the first 
time you are accessing your gitlab remotely and that you didn't receive a password when getting your occam account
(you only logged in using the c3s authentification protocol through your unito email) you'll first have to set up a 
password in your gitlab -> edit profile -> password -> I forgot my password -> reset password
```shell
docker login gitlab.c3s.unito.it:5000
```
**B.** Push the newly created image to the gitlab registry tag and push it:
```shell
docker push gitlab.c3s.unito.it:5000/{USER}/{PROJECT}/{image_name}:{tag}
```
You can access your image entry in the remote repo here : https://gitlab.c3s.unito.it/{USER}/{PROJECT}/container_registry/

# II. Running on OCCAM
For the full list of commands accessible on occam check:
https://c3s.unito.it/index.php/super-computer/occam-reference
### 1. Login to OCCAM
```shell
ssh {USER}@occam.c3s.unito.it # running occam-login is not necessary anymore
```
### 2. Create a example directory 
```shell
mkdir docker-example
cd docker-example/
```
#### 3. Run the container on occam using the image you have previously pushed
```shell
occam-run {USER}/{PROJECT}/{image_name}:{tag} # this container path format is also the one you should use in the docker parameter of your snakefile
```
# III. A mix of tips
### 1. Run interactive - Training purpose only 
Create a dockerfile with CMD ["/bin/bash"] (like https://gitlab.c3s.unito.it/egrassi/bwa_example/Dockerfile) and use  occam-run -i 
-i = interactive mode (will substitute entrypoint or cmd with a call to /bin/bash) ** use only for testing purposes
You will then be inside the container, in an interactive, responsive shell
NB: To exit the interactive session press ctrl+d  or type "exit"

### 2. Copy files to your occam home folder  
```shell
rsync -azvP /{PATH}/{TO}/{FILE} {USER}@occam.c3s.unito.it:/archive/home/{USER}/{FILE}
```
You can ofc also use scp, but I personnaly prefer rsync because it will skip all the files that are already there (matching timestamp and size)
and when you use -P, if the transfer is interrupted, you can resume it where it stopped by reissuing the command. 
### 3. Or the other way around, from occam to your local computer

```shell
rsync -azvP {USER}@occam.c3s.unito.it:/archive/home/{USER}/{FILE} /{PATH}/{TO}/{FILE} 
```

### 4. Mount your occam home folder when running a container
Note actually certain when to use it
```shell
occam-run -v $(PWD):$(PWD) {USER}/{PROJECT}/{image_name}:{tag}
```

# IV. How I submit a snakemake pipeline (BAD but works)
### 1. Create your image
See above. But basically write your dockerfile (you can find an example in Dockerfiles/ML_dockerfile_all), build the image and push it to gitlab

### 2. Run your image interactively 
open a screen https://linuxize.com/post/how-to-use-linux-screen/

```shell
screen -S a_new_screen
```

```shell
occam-run -n [booked_node] -i {USER}/{PROJECT}/{image_name}:{tag}
```
booked_node = node22 for example or any other node you have booked 

Run your snakemake pipeline as usual. Don't forget to set the snakemake resources depedning on the ressources you have booked. 
```shell
snakemake -s my_snakefile.smk -c [booked_threads] --resources mem_mb=[booked_memory]
```


# V. Set up your snakemake env to use docker with your snakemake pipeline (GOOD but hard to make it works)
That should be thre right solution but didn't work for me 
See Elena Grassi workaround to use snakemake with docker: https://gitlab.c3s.unito.it/egrassi/bwa_example/-/blob/main/occamsnakes.pdf?ref_type=heads

### 1. Install miniconda and mamba
https://docs.anaconda.com/free/miniconda/#quick-command-line-install
```shell
mkdir -p ~/miniconda3
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
rm -rf ~/miniconda3/miniconda.sh
~/miniconda3/bin/conda init bash
conda install -c conda-forge mamba
```

This step is updating your ~/.bashrc file. This ~/.bashrc file is used when you are login to the login node but also 
every time you are running a docker image. This creates conflicts between the conda environment you have created in your 
home folder and the one you are creating inside a container. In order to avoid these conflicts we will ask that this part 
of the ~/.bashrc is only used when on the login node. The following is an example that you will have to adapt in function 
of you own ~/.bashrc and the conda initialize blocks that is already present. 

```shell
if [ $HOSTNAME = "occam.c3s.unito.it" ]; then
	# >>> conda initialize >>>
	# !! Contents within this block are managed by 'conda init' !!
	__conda_setup="$('/archive/home/mandre/src/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
	if [ $? -eq 0 ]; then
	    eval "$__conda_setup"
	else
	    if [ -f "/archive/home/mandre/src/miniconda3/etc/profile.d/conda.sh" ]; then
	        . "/archive/home/mandre/src/miniconda3/etc/profile.d/conda.sh"
	    else
	        export PATH="/archive/home/mandre/src/miniconda3/bin:$PATH"
	    fi
	fi
	unset __conda_setup
	# <<< conda initialize <<<
fi
```
Alternatively you could also include this block inside a function that you call manually when you need to use a conda environment on the login node
```shell
aconda () {
	# >>> conda initialize >>>
	# !! Contents within this block are managed by 'conda init' !!
	__conda_setup="$('/archive/home/mandre/src/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
	if [ $? -eq 0 ]; then
	    eval "$__conda_setup"
	else
	    if [ -f "/archive/home/mandre/src/miniconda3/etc/profile.d/conda.sh" ]; then
	        . "/archive/home/mandre/src/miniconda3/etc/profile.d/conda.sh"
	    else
	        export PATH="/archive/home/mandre/src/miniconda3/bin:$PATH"
	    fi
	fi
	unset __conda_setup
	# <<< conda initialize <<<
}
```

### 2. install docker snakemake
```shell
mamba install anaconda::git
git clone https://github.com/vodkatad/snakemake_docker
cd snakemake_docker/
mamba env create -f environment.yml -n snakemake
conda activate snakemake
pip install -e .
```

For snakemake to be able to use the docker option on occam, you should set the RUN_ENV env variable to occam, in the login node:
```shell
export RUN_ENV=occam
```
You can do so at every login via .bashrc.

### 3. Build and push a dockerfile
See I.4
I won't elaborate on that but we had to solve different issue with running snakemake on occam specificities 
The solution we found with Elena are included in the Dockerfiles/ML_dockerfile_all that you can adapt to your own needs 

### 4. Create you snakefile
The version of this modified snakemake is v5.5.4. which requires some adjustement. You will have to state the following
lines at the beginning of your snakefile:

```python
# To be able to run with snakemake v5, don't ask me
# Check which path to use using 'echo $BASH'
shell.executable('/bin/bash')
# To be able to run with snakemake v5i, don't ask me either
# https://github.com/Biochemistry1-FFM/uORF-Tools/issues/12
import collections
collections.Iterable = collections.abc.Iterable
```
Example of rule with docker from Elena bwa_example
```python
rule align:
	input: fq="fastq/{sample}.fastq.gz", genome=GENOME
	output: "align/{sample}.sorted.bam"
	log: "align/{sample}.sorted.bam.log"
	docker: "egrassi/bwa_example"
	shell: 
		"""
		mkdir -p align;
		bwa mem -t 6 {input.genome} {input.fq} 2> {log} | samtools sort -@1 -O BAM -o {output};
		"""
```
**NB:** You can not use a 'run' rule when using the docker option. You will have to put your python comman in a python 
script that you will run from the shell. See the example below: 

```python
rule make_geno_matrices_discovery:  #add the eqtl info as pheno
    input:
        vcf="vcf_genes/{chr}_{start}_{end}.{gene}.{qtl}.FILTERED.vcf.gz"
    output:
        geno="geno_matrices_genes/{qtl}/{chr}_{start}_{end}.{gene}.{qtl}.FILTERED.geno.gz"
    params:
        script="geno_matrix_script.py"
    docker: "{USER}/{PROJECT}/{image_name}:{tag}"
    shell:
        """
        python {params.script} --vcf {input.vcf} --out {output.geno}
        """
```

### 4. Run the snakefile pipeline
```shell
conda activate snakemake # activate the environment with the docker snakemake
export RUN_NODE=node22 && snakemake -s snakefile --use-docker # running on the training node
```


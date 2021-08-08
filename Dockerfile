FROM centos:7

# Install some basic dependencies.
RUN yum install -y epel-release && \
	yum install -y git openssl-devel wget \
	openblas-devel python2-pip python2-devel \
	python2-Cython glog-devel boost-devel gflags-devel && \
	yum group install -y "Development Tools"

# Install a newer version of CMake since CentOS uses quite an old
# version.
RUN git clone https://github.com/Kitware/CMake.git && \
	cd CMake && ./bootstrap --prefix=$HOME/usr && \
	make -j8 && make install

# Install Torch7 (nagadomi's version supports CUDA 10).
RUN mkdir -p $HOME/usr/local/ && \
	cd $HOME/usr/local && git clone https://github.com/nagadomi/distro.git torch --recursive && \
	cd $HOME/usr/local/torch && sed -i 's/sudo //' install-deps && \
	cd $HOME/usr/local/torch && ./install-deps && \
	cd $HOME/usr/local/torch && ./install.sh -b

# Install some python deps for processing the generated volume
RUN pip2.7 install six==1.8.0 && \
	pip2.7 install trimesh pillow \
	numpy==1.14.6 scipy==1.0.1 \
	scikit-learn==0.20 scikit-image==0.10 PyMCubes==0.0.9 && \
	pip2.7 install https://files.pythonhosted.org/packages/1e/62/aacb236d21fbd08148b1d517d58a9d80ea31bdcd386d26f21f8b23b1eb28/dlib-19.18.0.tar.gz

# Set up some Torch dependencies for Adrian's landmark localisation
RUN git clone https://github.com/1adrianb/thpp.git && \
	cd thpp/thpp && \
	source /root/usr/local/torch/install/bin/torch-activate && \
	THPP_NOFB=1 ./build.sh && \
	cd /root && \
	git clone https://github.com/facebookarchive/fblualib.git && \
	cd fblualib/fblualib/python && \
	source /root/usr/local/torch/install/bin/torch-activate && \
	luarocks make rockspec/*

COPY runner /runner

RUN cd /runner && \
    wget https://asjackson.s3.fr-par.scw.cloud/vrn/vrn-unguided.t7 && \
    cd face-alignment && \
    wget https://asjackson.s3.fr-par.scw.cloud/vrn/2D-FAN-300W.t7

ENTRYPOINT ["/runner/run.sh"]

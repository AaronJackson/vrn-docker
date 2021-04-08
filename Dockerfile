FROM centos:7

# Install some basic dependencies.
RUN yum install -y epel-release
RUN yum install -y git openssl-devel wget openblas-devel
RUN yum group install -y "Development Tools"

# Install a newer version of CMake since CentOS uses quite an old
# version.
RUN git clone https://github.com/Kitware/CMake.git
RUN cd CMake && ./bootstrap --prefix=$HOME/usr && make -j8 && make install

# Add our local bin to PATH so we can find `cmake`.
RUN echo "export PATH=$HOME/usr/bin" >> $HOME/.bashrc

# Install Torch7 (nagadomi's version supports CUDA 10).
RUN mkdir -p $HOME/usr/local/
RUN cd $HOME/usr/local && git clone https://github.com/nagadomi/distro.git torch --recursive
RUN cd $HOME/usr/local/torch && sed -i 's/sudo //' install-deps # Remove sudo usage
RUN cd $HOME/usr/local/torch && ./install-deps
RUN cd $HOME/usr/local/torch && ./install.sh -b

RUN yum install -y python2-pip python2-devel

RUN pip2.7 install six==1.8.0

RUN pip2.7 install trimesh pillow \
	numpy==1.14.6 scipy==1.0.1 \
	scikit-learn==0.20 scikit-image==0.10

RUN pip2.7 install https://files.pythonhosted.org/packages/1e/62/aacb236d21fbd08148b1d517d58a9d80ea31bdcd386d26f21f8b23b1eb28/dlib-19.18.0.tar.gz

RUN yum install -y glog-devel boost-devel gflags-devel

RUN git clone https://github.com/1adrianb/thpp.git
RUN cd thpp/thpp && \
	source /root/usr/local/torch/install/bin/torch-activate && \
	THPP_NOFB=1 ./build.sh

RUN git clone https://github.com/facebookarchive/fblualib.git
RUN cd fblualib/fblualib/python && \
	source /root/usr/local/torch/install/bin/torch-activate && \
	luarocks make rockspec/*

RUN yum install -y python2-Cython
RUN pip2.7 install PyMCubes==0.0.9

COPY runner /runner

ENTRYPOINT ["/runner/run.sh"]

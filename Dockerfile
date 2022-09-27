FROM nvidia/cuda:11.2.2-runtime-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /install

RUN apt-get update && \
    apt-get install -y libglib2.0-0 wget vim libsm6 libxext6 libxrender1 libfontconfig1 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install miniconda
ENV CONDA_DIR /opt/conda
RUN wget -O ~/miniconda.sh -q --show-progress --progress=bar:force https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    /bin/bash ~/miniconda.sh -b -p $CONDA_DIR && \
    rm ~/miniconda.sh
ENV PATH=$CONDA_DIR/bin:$PATH

# Install font for prompt matrix
COPY /data/DejaVuSans.ttf /usr/share/fonts/truetype/

# Set Conda config and Pip config and Git config
COPY /data/condarc /root/.condarc
COPY /data/pip.conf /root/.config/pip/pip.conf
COPY /data/gitconfig /root/.gitconfig

# create conda env
# https://pythonspeed.com/articles/activate-conda-dockerfile/
RUN conda create -n ldm -y python=3.8.5 && conda init bash && echo "conda activate ldm" >> ~/.bashrc
SHELL ["conda", "run", "--no-capture-output", "-n", "ldm", "/bin/bash", "-c"]

# install basic dep
RUN conda install git pip pytorch-gpu torchvision numpy && conda config --show-sources && git config --list && pip config list

# install required deps
COPY ./sd_requirements.txt /install/
RUN pip install -r /install/sd_requirements.txt

COPY ./ext_requirements.txt /install
RUN pip install -r /install/ext_requirements.txt

COPY ./ui_requirements.txt /install/
RUN pip install -r /install/ui_requirements.txt

COPY ./requirements.txt /install/
RUN pip install -r /install/requirements.txt

# workaround, reinstall
RUN conda list | grep torch && conda install pytorch-gpu torchvision && conda list | grep torch

COPY ./entrypoint.sh /sd/
ENTRYPOINT /sd/entrypoint.sh


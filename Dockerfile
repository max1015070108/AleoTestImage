# 使用Ubuntu 22.04作为基础镜像
FROM ubuntu:22.04

# 避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive

# 更新包列表并安装必要的工具
RUN apt-get update && apt-get install -y \
    build-essential \
    wget \
    curl \
    git \
    vim \
    openssh-server \
    sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 安装NVIDIA CUDA工具包
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb \
    && dpkg -i cuda-keyring_1.0-1_all.deb \
    && apt-get update \
    && apt-get install -y cuda \
    && rm cuda-keyring_1.0-1_all.deb

# 创建用户harry并设置sudo权限
RUN useradd -m harry -s /bin/bash && \
    echo "harry ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 设置SSH
RUN mkdir /var/run/sshd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH登录修复
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# 设置环境变量
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# 添加SSH公钥
RUN mkdir -p /home/harry/.ssh
RUN echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCxQiQDUzIAW/f4LxeO/TVKYF2dfpiOB5WmCR/5J+c3vDpqPpmJvSLSSJS9fxQmZ/WbD0eqnmfBFXJtFcnzQzdGmQfhpUYrnemxrtJpojDgd/XxTg9w0MP1hUsl3GDr+gGk7+WPi6FEg5He8jh89+mlfejGLq9DTxDPabAvE492Y8mo5M2DGTDrnBFmTHoMfft5XBz+0SmVblKn+TT5Tt07wjufTCJKNJqqW8Z8fSsMkXvoYAoKCJ+ZyvpeGhcBv+ms4/x19NKFzKf1+aVtgAno+rvQKTB8oMGIk0PmpOiU/rSpEUX+u3ypbD0ZAIkgi2/97z2Z4NAD8ewHG8CWKv+Vapa6wEfOpgApYgnxJT2M/udsCaTdVg2qsvf2qwzI8LVZ/slYbrXJAwLavUEvQw1RIofV+juyHA9ilf4cOCI0KkBJ10mMfVDMwKEg/4kEc02U6VcIfTu+au7/XhygjKZO/ubs/Z8IrQANTARoAASyNFK/yKJZmQutGp9SWz+zP0k= harry@HarrydeMacBook-Pro.local" > /home/harry/.ssh/authorized_keys
RUN chown -R harry:harry /home/harry/.ssh
RUN chmod 700 /home/harry/.ssh
RUN chmod 600 /home/harry/.ssh/authorized_keys

# 下载并安装Aleo Prover
WORKDIR /home/harry
RUN wget https://github.com/6block/zkwork_aleo_gpu_worker/releases/download/v0.1.0/aleo_prover-v0.1.0.tar.gz \
    && tar -xzvf aleo_prover-v0.1.0.tar.gz \
    && chmod +x aleo_prover \
    && rm aleo_prover-v0.1.0.tar.gz

# 创建启动脚本
RUN echo '#!/bin/bash\n\
/usr/sbin/sshd\n\
su - harry -c "/home/harry/aleo_prover --pool aleo.hk.zk.work:10003 --address aleo1hrld628dyskmn5pta6erxq23jnpsfucuxpn836xqqrlgrfmyncgsjhqv08 --custom_name harryprover"\n\
' > /start.sh \
    && chmod +x /start.sh

# 暴露SSH端口
EXPOSE 22

# 设置启动命令
CMD ["/start.sh"]
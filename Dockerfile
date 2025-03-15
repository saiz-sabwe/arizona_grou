FROM python:3.11-slim-bullseye

LABEL org.opencontainers.image.authors="aziona_group"
LABEL "Vendor"="aziona_group"
LABEL version="0.4"

ENV PYTHONUNBUFFERED=1
WORKDIR /aziona_group

RUN apt-get update -y
# Production config (https)
RUN apt-get install apt-transport-https
# Install necessary package for django runtime
RUN apt-get install -y default-libmysqlclient-dev \
        pkg-config \
        libpango-1.0-0  \
        libharfbuzz0b \
        libpangoft2-1.0-0 \
        libpangocairo-1.0-0 \
        libxml2-dev \
        libxslt-dev \
        libffi-dev \
        libcairo2-dev \
        libpango1.0-dev --fix-missing

# Install gcc
RUN #apt-get install -y build-essential


# RUN pip3 install --upgrade setuptools

COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt

# Comment this Line on production Image
# RUN pip3 install django_dump_die

# Create the erp rootless user
ARG USERNAME=aziona_usr
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
# [Optional] Add sudo support. Omit if you don't need to install software after connecting.
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME



#COPY others.requirements.txt others.requirements.txt
#RUN pip3 install -r others.requirements.txt

RUN apt-get install unixodbc -y

# [Optional] Set the default user. Omit if you want to keep the default as root.
# USER $USERNAME

RUN apt-get install curl -y

# Security Packages
RUN pip3 install python-dotenv
RUN pip3 install whitenoise
RUN pip3 install werkzeug
RUN pip3 install pyOpenSSL
RUN pip3 install watchdog
RUN pip3 install django-csp==3.7
RUN pip3 install django-csp-nonce==1.0.0

# Asynchronous system Packages
RUN pip3 install gunicorn
RUN pip3 install uvicorn==0.23.1
RUN pip3 install asgiref==3.7.2
RUN pip3 install 'uvicorn[standard]'


# Remove Unused packages
RUN  apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
   && rm -rf /var/lib/apt/lists/*

# Copy erp files in Container
COPY ./ ./

CMD [ "gunicorn", "aziona_group.wsgi:application", "--bind", "0.0.0.0:8000" ]

EXPOSE 8000


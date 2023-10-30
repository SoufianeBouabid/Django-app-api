# Use the official Python 3.9 image based on Alpine Linux
FROM python:3.9-alpine3.13

# Set environment variables
ENV PYTHONUNBUFFERED 1

# Install necessary packages, including CA certificates
RUN apk update && \
    apk add --no-cache openssl ca-certificates && \
    update-ca-certificates

# Define an environment variable to disable SSL verification (for the duration of the image build)
ENV PIP_NO_CACHE_DIR=off

# Copy project requirements into the container
COPY ./requirements.txt /tmp/requirements.txt
COPY ./requirements.dev.txt /tmp/requirements.dev.txt

# Set the working directory to the application directory
WORKDIR /app

# Create the user 'django-user' and the '/py' directory for the ownership change
RUN adduser --disabled-password --no-create-home django-user && \
    mkdir /py && chown -R django-user /py

# Switch to the 'django-user' to perform further operations
USER django-user

# Create a virtual environment and install Python packages with trusted hosts
RUN python -m venv /py && \
    /py/bin/pip install --upgrade pip && \
    /py/bin/pip install -r /tmp/requirements.txt --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host=files.pythonhosted.org && \
    /py/bin/pip install flake8

# Create the Django project inside the container
RUN /py/bin/django-admin startproject app .

# Clean up temporary files
RUN rm -rf /tmp

# Use the official Python 3.9 image based on Alpine Linux
FROM python:3.9-alpine3.13

# Set environment variables
ENV PYTHONUNBUFFERED 1

# Switch to root user for system-level operations
USER root

# Install necessary packages, including CA certificates
RUN apk update && \
    apk add --no-cache openssl ca-certificates && \
    update-ca-certificates

# Define an environment variable to disable SSL verification (for the duration of the image build)
ENV PIP_NO_CACHE_DIR=off

# Copy project requirements and application code into the container
COPY ./requirements.txt /tmp/requirements.txt
COPY ./requirements.dev.txt /tmp/requirements.dev.txt
COPY ./app /app_code

# Set the working directory to the application directory
WORKDIR /app

# Expose port 8000 (adjust as needed)
EXPOSE 8000

# Define the ARG for conditional package installation
ARG DEV=false

# Create a virtual environment and install Python packages with trusted hosts
RUN set -ex && \
    python -m venv /py && \
    /py/bin/pip install --upgrade pip && \
    /py/bin/pip install -r /tmp/requirements.txt --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host=files.pythonhosted.org && \
    /py/bin/pip install flake8 && \
    /py/bin/django-admin startproject app .

# Add /py/bin and /usr/local/bin to the PATH environment variable
RUN echo 'export PATH="/py/bin:$PATH:/usr/local/bin"' >> /etc/profile

# Conditionally install development requirements
RUN if [ "$DEV" = "true" ]; then /py/bin/pip install -r /tmp/requirements.dev.txt; fi

# Clean up temporary files and create a non-root user
RUN rm -rf /tmp && \
    adduser --disabled-password --no-create-home django-user && \
    chown -R django-user /app

# Set the PATH to include the virtual environment
ENV PATH="/py/bin:$PATH"

# Switch to the non-root user
USER django-user

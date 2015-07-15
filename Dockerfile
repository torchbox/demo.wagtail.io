FROM python:2.7

# Apt-get dependencies
RUN apt-get update -y && \
    apt-get install -y postgresql && \
    apt-get clean

# Install requirements first (so they get cached between builds)
ADD /wagtail-torchbox/requirements.txt requirements.txt
RUN pip install -r requirements.txt
RUN pip install whitenoise uwsgi

# These requirements are required by the project but not in requirements.txt
RUN pip install django-celery gunicorn

# Add code into container
ADD wagtail-torchbox /app/
ADD conf/settings.py /app/tbx/settings/docker.py
ADD conf/wsgi.py /app/tbx/wsgi_docker.py
ADD conf/uwsgi.ini /app/uwsgi.ini
WORKDIR /app/

# Environment variables
ENV PYTHONPATH=/app/
ENV DJANGO_SETTINGS_MODULE=tbx.settings.docker

# Use postgres user for database access
RUN perl -pi -e "s/^(local\s+all\s+postgres\s+)peer$/\1trust/" /etc/postgresql/9.4/main/pg_hba.conf
ENV PGUSER=postgres

# Create database and compress static files
# All this needs to happen with postgres running
RUN /etc/init.d/postgresql start && \
    # Sleep for a bit to make sure postgres is running
    sleep 3 && \

    # Setup database
    createdb torchbox && \
    django-admin.py migrate --noinput && \
    django-admin.py createcachetable && \
#   django-admin.py load_initial_data && \

    # Collect and compress static files
    django-admin.py collectstatic --noinput && \
    django-admin.py compress --force && \
    python -m whitenoise.gzip /app/static/

CMD /etc/init.d/postgresql start && uwsgi --ini uwsgi.ini
EXPOSE 5000

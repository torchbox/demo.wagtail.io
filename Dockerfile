FROM python:2.7

# Apt-get dependencies
RUN apt-get update -y && \
    apt-get install -y postgresql && \
    apt-get install -y sudo && \
    apt-get clean

# Install requirements first (so they get cached between builds)
ADD /wagtail-torchbox/requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir whitenoise uwsgi

# These requirements are required by the project but not in requirements.txt
RUN pip install --no-cache-dir django-celery gunicorn

# Add code into container
ADD wagtail-torchbox /app/
ADD conf/settings.py /app/tbx/settings/docker.py
ADD conf/wsgi.py /app/tbx/wsgi_docker.py
ADD conf/uwsgi.ini /app/uwsgi.ini
ADD data/data.json /app/data.json
ADD data/superuser.json /app/superuser.json
ADD data/media/ /app/media/
WORKDIR /app/

# Environment variables
ENV PYTHONPATH=/app/
ENV DJANGO_SETTINGS_MODULE=tbx.settings.docker

# Add unix user for app
RUN adduser --disabled-password --gecos "" torchbox
RUN chown -R torchbox:torchbox /app
RUN echo "torchbox ALL=NOPASSWD: /etc/init.d/postgresql" >> /etc/sudoers

# Add database user for app
RUN /etc/init.d/postgresql start && su - postgres -c "createuser -s torchbox"

USER torchbox

# Create database and compress static files
# All this needs to happen with postgres running
RUN sudo /etc/init.d/postgresql start && \
    # Sleep for a bit to make sure postgres is running
    sleep 3 && \

    # Setup database
    createdb torchbox && \
    django-admin.py migrate --noinput && \
    django-admin.py createcachetable && \
    psql torchbox -c "DELETE FROM wagtailcore_site;" && \
    psql torchbox -c "DELETE FROM wagtailcore_page WHERE id=2;" && \
    django-admin.py loaddata data.json && \
    django-admin.py loaddata superuser.json && \

    # Collect and compress static files
    django-admin.py collectstatic --noinput && \
    django-admin.py compress --force && \
    python -m whitenoise.gzip /app/static/

CMD sudo /etc/init.d/postgresql start && uwsgi --ini uwsgi.ini
EXPOSE 5000

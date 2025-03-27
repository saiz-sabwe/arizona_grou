FROM python:3.11-slim-bullseye AS builder

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt \
    && pip install gunicorn uvicorn

FROM python:3.11-slim-bullseye

LABEL authors="saiz"
LABEL version="0.1"

WORKDIR /app

RUN groupadd -r -g 1000 django_group && \
    useradd -r -u 1000 -g django_group django_user

COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

COPY . .

RUN chown -R django_user:django_group /app

USER django_user

# Exposer le port 8000 pour que Gunicorn puisse l'utiliser
EXPOSE 8000

# Lancer Gunicorn en liant à 0.0.0.0:8000
CMD ["gunicorn", "arizona_group.wsgi:application", "--bind", "0.0.0.0:8000"]